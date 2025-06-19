const std = @import("std");
const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xutil.h");
});

var gDisplay: ?*c.Display = undefined;
var gScreen: c_ulong = 0;
var gWinMap = std.AutoHashMap(usize, *Window).init(std.heap.page_allocator);

pub fn appInit() void {
    gDisplay = c.XOpenDisplay(null);
    if (gDisplay == null) {
        std.log.err("Open Display error!", .{});
        return;
    }

    gScreen = @intCast(c.DefaultScreen(gDisplay));
}
pub fn appDeinit() void {
    _ = c.XCloseDisplay(gDisplay);
}

pub fn appQuit() void {}

pub fn appRun() void {
    var event: c.XEvent = undefined;
    var isRuning = true;
    while (isRuning) {
        _ = c.XNextEvent(gDisplay, &event);
        const win = gWinMap.get(event.xany.window) orelse continue;
        switch (event.type) {
            c.ClientMessage => {
                if (event.xclient.data.l[0] == win.wmDelMsg) {
                    std.log.warn("Delete win {d}", .{win.hWnd});
                    _ = gWinMap.remove(event.xany.window);
                    _ = c.XUnmapWindow(gDisplay, win.hWnd);
                    _ = c.XDestroyWindow(gDisplay, win.hWnd);
                    if (gWinMap.count() == 0) {
                        isRuning = false;
                    }
                }
            },
            c.ButtonPress => {
                std.log.debug("{d} ({d},{d})", .{ event.xbutton.button, event.xbutton.x, event.xbutton.y });
            },
            c.ButtonRelease => {},
            c.MotionNotify => {},
            else => {},
        }
        win.onMessage(event.type);
    }
}

pub const Window = struct {
    hWnd: c.Window,
    width: u32,
    height: u32,
    allocator: std.mem.Allocator,
    wmDelMsg: c.Atom,

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
        // events
        var flags = c.ButtonPressMask | c.ButtonReleaseMask | c.ButtonMotionMask;
        flags |= c.PointerMotionMask | c.PointerMotionHintMask;
        flags |= c.EnterWindowMask | c.LeaveWindowMask;
        flags |= c.StructureNotifyMask | c.ExposureMask;
        _ = c.XSelectInput(gDisplay, hWnd, flags);
        _ = c.XMapWindow(gDisplay, hWnd);

        const win = allocator.create(Self) catch return null;
        // close event
        const wmDelMsg = c.XInternAtom(gDisplay, "WM_DELETE_WINDOW", 0);
        _ = c.XSetWMProtocols(gDisplay, hWnd, @constCast(&wmDelMsg), 1);
        win.* = Self{
            .hWnd = hWnd,
            .width = width,
            .height = height,
            .allocator = allocator,
            .wmDelMsg = wmDelMsg,
        };

        gWinMap.put(hWnd, win) catch return null;
        return win;
    }
    pub fn deinit(self: *Self) void {
        self.allocator.destroy(self);
    }
    pub fn setTitle(self: *Self, title: []const u8) void {
        const title_ptr: [*c]const u8 = @ptrCast(title.ptr);
        _ = c.XStoreName(gDisplay, self.hWnd, title_ptr);
    }
    pub fn onMessage(self: *Self, ev: anytype) void {
        std.log.debug("onMessage: {d} {any}", .{ self.hWnd, ev });
    }
};
