const std = @import("std");
const qjs_lib = @cImport({
    @cInclude("quickjs.h");
    @cInclude("quickjs-libc.h");
});

pub const Quickjs = struct {
    ctx: ?*qjs_lib.JSContext,
    rt: ?*qjs_lib.JSRuntime,

    const Self = @This();

    pub fn init() Self {
        const rt = qjs_lib.JS_NewRuntime();
        qjs_lib.js_std_set_worker_new_context_func(qjs_my_context);
        qjs_lib.js_std_init_handlers(rt);
        const ctx = qjs_my_context(rt);

        // es6
        qjs_lib.JS_SetModuleLoaderFunc(rt, null, qjs_lib.js_module_loader, null);
        // exit on unhandled promise rejections
        qjs_lib.JS_SetHostPromiseRejectionTracker(rt, qjs_lib.js_std_promise_rejection_tracker, null);

        return Self{
            .ctx = ctx,
            .rt = rt,
        };
    }
    pub fn deinit(self: Self) void {
        qjs_lib.js_std_free_handlers(self.rt);
        qjs_lib.JS_FreeContext(self.ctx);
        qjs_lib.JS_FreeRuntime(self.rt);
    }

    pub fn eval_js_code(self: Self, code: []const u8, isModule: bool) i32 {
        const flags = if (isModule) qjs_lib.JS_EVAL_TYPE_MODULE else qjs_lib.JS_EVAL_TYPE_GLOBAL;
        return eval_buf(self.ctx, code, "<run-code>", flags);
    }

    pub fn eval_js_file(self: Self, filename: []const u8) i32 {
        // -1 auto, 0 global, 1 module
        return self.eval_file(self.ctx, filename, -1);
    }

    pub fn eval_js_binary(self: Self, data: []const u8) void {
        const c_data: [*c]const u8 = @ptrCast(data);
        qjs_lib.js_std_eval_binary(self.ctx, c_data, data.len, 0);
    }

    pub fn loop(self: Self) i32 {
        return qjs_lib.js_std_loop(self.ctx);
    }

    // custom context
    fn qjs_my_context(rt: ?*qjs_lib.JSRuntime) callconv(.C) ?*qjs_lib.JSContext {
        const ctx = qjs_lib.JS_NewContext(rt);
        if (ctx == null) {
            return null;
        }
        _ = qjs_lib.js_init_module_std(ctx, "qjs:std");
        _ = qjs_lib.js_init_module_os(ctx, "qjs:os");
        _ = qjs_lib.js_init_module_bjson(ctx, "qjs:bjson");

        // console.log and args
        qjs_lib.js_std_add_helpers(ctx, 0, null);

        // add pre
        const pre_load_str =
            \\import * as bjson from 'qjs:bjson';
            \\import * as std from 'qjs:std';
            \\import * as os from 'qjs:os';
            \\globalThis.bjson = bjson;
            \\globalThis.std = std;
            \\globalThis.os = os;
        ;
        _ = eval_buf(ctx, pre_load_str, "<preload>", qjs_lib.JS_EVAL_TYPE_MODULE);

        return ctx;
    }

    fn eval_buf(ctx: ?*qjs_lib.JSContext, buf: []const u8, filename: []const u8, flags: i32) i32 {
        if (ctx == null) {
            return -1;
        }
        var val: qjs_lib.JSValue = undefined;
        var ret: i32 = 0;
        const c_buf: [*c]const u8 = @ptrCast(buf);
        const c_filename: [*c]const u8 = @ptrCast(filename);
        if ((flags & qjs_lib.JS_EVAL_TYPE_MASK) == qjs_lib.JS_EVAL_TYPE_MODULE) {
            val = qjs_lib.JS_Eval(ctx, c_buf, buf.len, c_filename, flags | qjs_lib.JS_EVAL_FLAG_COMPILE_ONLY);
            if (!qjs_lib.JS_IsException(val)) {
                const realPath = false;
                // if (std.mem.startsWith(u8, filename, "<") || std.mem.startsWith(u8, filename, "/dev/")) {
                //     realPath = false;
                // }
                if (qjs_lib.js_module_set_import_meta(ctx, val, realPath, true) < 0) {
                    qjs_lib.js_std_dump_error(ctx);
                    ret = -1;
                } else {
                    val = qjs_lib.JS_EvalFunction(ctx, val);
                }
            }
            // wait run
            val = qjs_lib.js_std_await(ctx, val);
        } else {
            val = qjs_lib.JS_Eval(ctx, c_buf, buf.len, c_filename, flags);
        }
        defer qjs_lib.JS_FreeValue(ctx, val);

        // exception
        if (qjs_lib.JS_IsException(val)) {
            qjs_lib.js_std_dump_error(ctx);
            ret = -1;
        }
        return ret;
    }

    fn eval_file(ctx: ?*qjs_lib.JSContext, filename: []const u8, module: i32) i32 {
        if (ctx == null) {
            return -1;
        }
        var buf_len: c_int = 0;
        const c_filename: [*c]const u8 = @ptrCast(filename);
        const buf = qjs_lib.js_load_file(ctx, &buf_len, c_filename);
        if (buf == null) {
            std.log.warn("load file {} failed", .{filename});
            return -1;
        }
        defer qjs_lib.js_free(ctx, buf);

        // module
        if (module < 0) {
            if (std.mem.endsWith(u8, c_filename, ".mjs") || qjs_lib.JS_DetectModule(buf, buf_len)) {
                module = 1;
            }
        }

        const flags = if (module > 0) qjs_lib.JS_EVAL_TYPE_MODULE else qjs_lib.JS_EVAL_TYPE_GLOBAL;

        return eval_buf(buf, filename, flags);
    }
};
