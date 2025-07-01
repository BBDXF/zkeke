const std = @import("std");
pub const quickjs = @import("quickjs");
pub const yoga = @import("yoga");
pub const win = @import("window");
pub const cairo = @import("cairo");
pub const comm = @import("comm");

pub const ZkkApp = struct {
    qjs: quickjs.Quickjs,
    allocator: std.mem.Allocator,
};

pub export fn zkk_init() *ZkkApp {
    const pZkkApp = std.heap.c_allocator.create(ZkkApp) catch unreachable;
    // window init
    win.appInit();
    pZkkApp.* = .{
        .qjs = quickjs.Quickjs.init(),
        .allocator = std.heap.c_allocator,
    };

    return pZkkApp;
}

pub export fn zkk_deinit(app: *ZkkApp) void {
    win.appDeinit();
    app.qjs.deinit();
    std.heap.c_allocator.destroy(app);
}

pub export fn zkk_run() void {
    win.appRun();
}

pub export fn zkk_quit() void {
    win.appQuit();
}

pub export fn zkk_win_create(app: *ZkkApp, width: i32, height: i32) *win.Window {
    win.Window.init(app.allocator, width, height);
}
pub export fn zkk_win_destroy(app: *ZkkApp, w: *win.Window) void {
    _ = app;
    w.deinit();
}
