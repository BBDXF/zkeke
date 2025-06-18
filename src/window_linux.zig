const std = @import("std");
const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xutil.h");
});

const gDisplay: ?*c.Display = undefined;
const gScreen: ?*c.Screen = undefined;
var gWinMap = std.AutoHashMap(usize, *Window).init(std.heap.page_allocator);

pub fn appInit() void {
    gDisplay = c.XOpenDisplay(null);
    if (gDisplay == null) {
        std.log.err("Open Display error!", .{});
        return;
    }
    gScreen = c.DefaultScreen(gDisplay);
}
pub fn appDeinit() void {}

pub fn appQuit() void {}

pub fn appRun() void {
    var event: c.XEvent = undefined;
    while (1) {
        c.XNextEvent(gDisplay, &event);
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
    width: i32,
    height: i32,
    allocator: std.mem.Allocator,

    const Self = @This();
    pub fn init(allocator: std.mem.Allocator, width: i32, height: i32) ?*Self {
        const fw = c.DisplayWidth(gDisplay, gScreen);
        const fh = c.DisplayHeight(gDisplay, gScreen);
        const hWnd = c.XCreateSimpleWindow(
            gDisplay,
            c.DefaultRootWindow(gDisplay),
            (fw - width) / 2,
            (fh - height) / 2,
            width,
            height,
            2,
            c.BlackPixel(gDisplay, gScreen),
            c.WhitePixel(gDisplay, gScreen),
        );
        c.XStoreName(gDisplay, hWnd, "Zkeke window");
        var flags = c.ButtonPressMask | c.ButtonReleaseMask | c.ButtonMotionMask;
        flags |= c.PointerMotionMask | c.PointerMotionHintMask;
        flags |= c.EnterWindowMask | c.LeaveWindowMask;
        flags |= c.StructureNotifyMask | c.ExposureMask;
        c.XSelectInput(gDisplay, hWnd, flags);
        c.XMapWindow(gDisplay, hWnd);

        const win = allocator.create(Self) catch return null;
        win.* = Self{
            .hWnd = hWnd,
            .width = width,
            .height = height,
            .allocator = allocator,
        };

        gWinMap.put(hWnd, win);
    }
    pub fn deinit() void {}
};
