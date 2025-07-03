const std = @import("std");
const c = @cImport({
    @cInclude("X11/Xlib.h");
    @cInclude("X11/Xutil.h");

    // cairo
    @cInclude("cairo/cairo.h");
    @cInclude("cairo/cairo-xlib.h");
});

const comm = @import("comm");

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
                    const ev = comm.Events{ .Destroy = {} };
                    win.onMessage(ev);

                    _ = gWinMap.remove(event.xany.window);
                    _ = c.XUnmapWindow(gDisplay, win.hWnd);
                    _ = c.XDestroyWindow(gDisplay, win.hWnd);
                    if (gWinMap.count() == 0) {
                        isRuning = false;
                    }
                }
            },
            // c.Button4, c.Button5,
            // c.Button4, c.Button5,
            c.MotionNotify, c.ButtonRelease, c.ButtonPress => {
                var ev: ?comm.Events = null;
                if (event.type == c.MotionNotify) {
                    ev = comm.Events{ .MouseMove = .{
                        .x = @intCast(event.xmotion.x),
                        .y = @intCast(event.xmotion.y),
                        .button = 0,
                    } };
                } else if (event.type == c.ButtonRelease) {
                    if (event.xbutton.button < 4) { // ignore wheel event
                        ev = comm.Events{ .MouseUp = .{
                            .x = @intCast(event.xbutton.x),
                            .y = @intCast(event.xbutton.y),
                            .button = event.xbutton.button,
                        } };
                    }
                } else {
                    if (event.xbutton.button < 4) {
                        ev = comm.Events{ .MouseDown = .{
                            .x = @intCast(event.xbutton.x),
                            .y = @intCast(event.xbutton.y),
                            .button = event.xbutton.button,
                        } };
                    } else {
                        ev = comm.Events{ .MouseWheel = .{
                            .x = @intCast(event.xbutton.x),
                            .y = @intCast(event.xbutton.y),
                            .button = event.xbutton.button,
                            .delta = if (event.xbutton.button == 4) 1 else -1,
                        } };
                    }
                }
                if (ev) |e| win.onMessage(e);
            },
            c.KeyPress, c.KeyRelease => {
                const ev = switch (event.type) {
                    c.KeyPress => comm.Events{ .KeyDown = .{
                        .keyCode = event.xkey.keycode,
                        .ctrl = (@as(c_uint, c.ControlMask) & event.xkey.state) != 0,
                        .shift = (@as(c_uint, c.ShiftMask) & event.xkey.state) != 0,
                        .alt = (@as(c_uint, c.Mod1Mask) & event.xkey.state) != 0,
                    } },
                    c.KeyRelease => comm.Events{ .KeyUp = .{
                        .keyCode = event.xkey.keycode,
                        .ctrl = (@as(c_uint, c.ControlMask) & event.xkey.state) != 0,
                        .shift = (@as(c_uint, c.ShiftMask) & event.xkey.state) != 0,
                        .alt = (@as(c_uint, c.Mod1Mask) & event.xkey.state) != 0,
                    } },
                    else => unreachable,
                };
                win.onMessage(ev);
            },
            c.ConfigureNotify => {
                const ev = comm.Events{ .Resize = .{
                    .width = @intCast(event.xconfigure.width),
                    .height = @intCast(event.xconfigure.height),
                } };
                win.onMessage(ev);
                const ev2 = comm.Events{ .Move = .{
                    .x = @intCast(event.xconfigure.x),
                    .y = @intCast(event.xconfigure.y),
                } };
                win.onMessage(ev2);
            },
            c.Expose => {
                const ev = comm.Events{ .Draw = {} };
                win.onMessage(ev);
            },
            c.MapNotify => {
                _ = c.XSetInputFocus(gDisplay, win.hWnd, c.RevertToParent, c.CurrentTime);
                const ev = comm.Events{ .Show = {} };
                win.onMessage(ev);
            },
            c.UnmapNotify => {
                const ev = comm.Events{ .Hide = {} };
                win.onMessage(ev);
            },
            // c.FocusIn => {
            //     const ev = comm.Events{ .Focus = {} };
            //     win.onMessage(ev);
            // },
            else => {},
        }
    }
}

pub const Window = struct {
    hWnd: c.Window,
    width: i32,
    height: i32,
    allocator: std.mem.Allocator,
    wmDelMsg: c.Atom,
    uiRootInt: ?comm.UiRootInterface, // UIRoot 事件回调

    const Self = @This();
    pub fn init(allocator: std.mem.Allocator, width: i32, height: i32) ?*Self {
        const fw: i32 = 100; // c.DisplayWidth(gDisplay, gScreen);
        const fh: i32 = 100; //c.DisplayHeight(gDisplay, gScreen);
        const hWnd = c.XCreateSimpleWindow(
            gDisplay,
            c.DefaultRootWindow(gDisplay),
            fw,
            fh,
            @intCast(width),
            @intCast(height),
            2,
            0,
            0,
        );
        _ = c.XStoreName(gDisplay, hWnd, "Zkeke window");
        // events
        var flags = c.ButtonPressMask | c.ButtonReleaseMask | c.ButtonMotionMask;
        flags |= c.PointerMotionMask;
        // flags |= c.EnterWindowMask | c.LeaveWindowMask;
        flags |= c.StructureNotifyMask | c.ExposureMask;
        _ = c.XSelectInput(gDisplay, hWnd, flags);
        _ = c.XMapWindow(gDisplay, hWnd);

        // flush amd focus
        _ = c.XFlush(gDisplay);

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
            .uiRootInt = null,
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
    pub fn getDrawableSize(self: *Self) [2]i32 {
        var attrs: c.XWindowAttributes = undefined;
        _ = c.XGetWindowAttributes(gDisplay, self.hWnd, &attrs);
        return [2]i32{ @intCast(attrs.width), @intCast(attrs.height) };
    }
    pub fn newSurface(self: *Self) *anyopaque {
        const sz = self.getDrawableSize();
        const gVisual = c.DefaultVisual(gDisplay, gScreen);
        const surf = c.cairo_xlib_surface_create(gDisplay, self.hWnd, gVisual, sz[0], sz[1]);
        return @ptrCast(surf);
    }
    pub fn onMessage(self: *Self, ev: comm.Events) void {
        // std.log.info("onMessage: {d} {any}", .{ self.hWnd, ev });
        if (self.uiRootInt) |cb| {
            cb.eventCB(cb.object, ev);
        }
    }
    pub fn setUiRoot(self: *Self, interface: comm.UiRootInterface) void {
        self.uiRootInt = interface;
    }
};
