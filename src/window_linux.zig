const std = @import("std");
const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xutil.h");
});

var gDisplay: ?*c.Display = undefined;
var gScreen: ?*c.Screen = undefined;
var gWinMap = std.AutoHashMap(usize, *Window).init(std.heap.page_allocator);

pub fn appInit() void {
    gDisplay = c.XOpenDisplay(null);
    if (gDisplay == null) {
        std.log.err("Open Display error!", .{});
        return;
    }
    const ptr: usize = @intCast(c.DefaultScreen(gDisplay));
    gScreen = @ptrFromInt(ptr);
}
pub fn appDeinit() void {}

pub fn appQuit() void {}

pub fn appRun() void {
    var event: c.XEvent = undefined;
    while (true) {
        _ = c.XNextEvent(gDisplay, &event);
        switch (event.type) {
            c.ButtonPress => {
                std.log.debug("{d} ({d},{d})", .{ event.xbutton.button, event.xbutton.x, event.xbutton.y });
            },
            c.ButtonRelease => {},
            c.MotionNotify => {},
            else => {},
        }
    }
}

pub const Window = struct {
    hWnd: c.Window,
    width: u32,
    height: u32,
    allocator: std.mem.Allocator,

    const Self = @This();
    pub fn init(allocator: std.mem.Allocator, width: u32, height: u32) ?*Self {
        const fw: i32 = 100; // c.DisplayWidth(gDisplay, gScreen);
        const fh: i32 = 100; //c.DisplayHeight(gDisplay, gScreen);
        const hWnd = c.XCreateSimpleWindow(
            gDisplay,
            c.DefaultRootWindow(gDisplay),
            fw,
            fh,
            width,
            height,
            2,
            0,
            0,
        );
        _ = c.XStoreName(gDisplay, hWnd, "Zkeke window");
        var flags = c.ButtonPressMask | c.ButtonReleaseMask | c.ButtonMotionMask;
        flags |= c.PointerMotionMask | c.PointerMotionHintMask;
        flags |= c.EnterWindowMask | c.LeaveWindowMask;
        flags |= c.StructureNotifyMask | c.ExposureMask;
        _ = c.XSelectInput(gDisplay, hWnd, flags);
        _ = c.XMapWindow(gDisplay, hWnd);

        const win = allocator.create(Self) catch return null;
        win.* = Self{
            .hWnd = hWnd,
            .width = width,
            .height = height,
            .allocator = allocator,
        };

        gWinMap.put(hWnd, win) catch return null;
        return win;
    }
    pub fn deinit(self: *Self) void {
        _ = self;
    }
};
