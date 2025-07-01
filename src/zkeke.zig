const std = @import("std");
pub const quickjs = @import("quickjs");
pub const yoga = @import("yoga");
pub const window = @import("window");
pub const cairo = @import("cairo");
pub const comm = yoga.comm;

pub const ZkkApp = struct {
    qjs: quickjs.Quickjs,
};

pub export fn zkk_init() *ZkkApp {
    const pZkkApp = std.heap.c_allocator.create(ZkkApp) catch unreachable;
    pZkkApp.* = .{
        .qjs = quickjs.Quickjs.init(),
    };
    return pZkkApp;
}

pub export fn zkk_deinit(app: *ZkkApp) void {
    app.qjs.deinit();
    std.heap.c_allocator.destroy(app);
}

pub export fn zkk_run() void {}

pub export fn zkk_stop() void {}
