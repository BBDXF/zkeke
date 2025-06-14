const std = @import("std");
const qjs_lib = @cImport({
    @cInclude("quickjs.h");
});

pub const Quickjs = struct {
    ctx: ?*qjs_lib.JSContext,
    rt: ?*qjs_lib.JSRuntime,
    pub fn init() Quickjs {
        const rt = qjs_lib.JS_NewRuntime();
        const ctx = qjs_lib.JS_NewContext(rt);
        return Quickjs{
            .ctx = ctx,
            .rt = rt,
        };
    }
    pub fn deinit(self: Quickjs) void {
        qjs_lib.JS_FreeContext(self.ctx);
        qjs_lib.JS_FreeRuntime(self.rt);
    }
};
