const std = @import("std");
const c = @cImport({
    @cDefine("WIN32_LEAN_AND_MEAN", "1");
    @cDefine("_WIN32_WINNT", "0x0601");
    @cInclude("windows.h");
    @cInclude("windowsx.h");

    //cairo
    @cInclude("cairo/cairo.h");
    @cInclude("cairo/cairo-win32.h");
});

const Events = @import("comm").Events;

const ZKEKE_CLASS_NAME = "ZkekeWindowClass";
var gInstance: c.HINSTANCE = undefined;
var gWinMap = std.AutoHashMap(usize, *Window).init(std.heap.page_allocator);

fn myNativeMouseEvent(uMsg: u32, wParam: c.WPARAM, lParam: c.LPARAM) Events {
    const x: i32 = @as(i16, @bitCast(@as(u16, @intCast(0xFFFF & (lParam))))); //@intCast(0xFFFF & lParam);
    const y: i32 = @as(i16, @bitCast(@as(u16, @intCast(0xFFFF & (lParam >> 16))))); //@intCast(lParam >> 16);
    const btn: u32 = @intCast(0xFFFF & wParam);
    const delta: i32 = @as(i16, @bitCast(@as(u16, @intCast(0xFFFF & (wParam >> 16)))));
    switch (uMsg) {
        c.WM_RBUTTONDOWN, c.WM_LBUTTONDOWN, c.WM_MBUTTONDOWN => {
            return Events{ .MouseDown = .{ .x = x, .y = y, .button = btn } };
        },
        c.WM_RBUTTONUP, c.WM_LBUTTONUP, c.WM_MBUTTONUP => {
            return Events{ .MouseUp = .{ .x = x, .y = y, .button = btn } };
        },
        c.WM_MOUSEMOVE => {
            return Events{ .MouseMove = .{ .x = x, .y = y } };
        },
        c.WM_MOUSEWHEEL => {
            return Events{ .MouseWheel = .{ .x = x, .y = y, .button = btn, .delta = delta } };
        },
        c.WM_LBUTTONDBLCLK, c.WM_RBUTTONDBLCLK, c.WM_MBUTTONDBLCLK => {
            return Events{ .MouseDblClick = .{ .x = x, .y = y, .button = btn } };
        },
        else => {
            unreachable;
        },
    }
}

fn myWndProc(hWnd: c.HWND, uMsg: u32, wParam: c.WPARAM, lParam: c.LPARAM) callconv(.winapi) c.LRESULT {
    const ptr = @intFromPtr(hWnd);
    if (gWinMap.get(ptr)) |win| {
        // std.log.info("myWndProc: {d}", .{uMsg});
        // check quit and translate message
        switch (uMsg) {
            c.WM_DESTROY => {
                const ev = Events{ .Destroy = {} };
                _ = win.onMessage(ev);
                _ = gWinMap.remove(ptr);
                if (gWinMap.count() == 0) {
                    appQuit();
                    return 1;
                }
            },
            c.WM_CLOSE => {
                const ev = Events{ .Close = {} };
                _ = win.onMessage(ev);
            },
            c.WM_LBUTTONDBLCLK, c.WM_RBUTTONDBLCLK, c.WM_MBUTTONDBLCLK, c.WM_RBUTTONDOWN, c.WM_LBUTTONDOWN, c.WM_MBUTTONDOWN, c.WM_RBUTTONUP, c.WM_LBUTTONUP, c.WM_MBUTTONUP, c.WM_MOUSEWHEEL, c.WM_MOUSEMOVE => {
                const ev = myNativeMouseEvent(uMsg, wParam, lParam);
                _ = win.onMessage(ev);
            },
            c.WM_ERASEBKGND => {
                return 1;
            },
            c.WM_PAINT => {
                const ev = Events{ .Draw = {} };
                _ = win.onMessage(ev);
            },
            c.WM_MOVE => {
                const ev = Events{ .Move = .{ .x = @intCast(0xFFFF & lParam), .y = @intCast(0xFFFF & (lParam >> 16)) } };
                _ = win.onMessage(ev);
            },
            c.WM_SIZE => {
                const ev = Events{ .Resize = .{ .width = @intCast(0xFFFF & lParam), .height = @intCast(0xFFFF & (lParam >> 16)) } };
                _ = win.onMessage(ev);
            },
            c.WM_CHAR, c.WM_SYSCHAR, c.WM_IME_CHAR => {
                const ev = Events{ .Char = @intCast(0xFFFF & wParam) };
                _ = win.onMessage(ev);
            },

            c.WM_KEYDOWN, c.WM_SYSKEYDOWN => {
                const ctrl = @as(c_int, c.GetKeyState(c.VK_SHIFT)) & 0x8000 != 0;
                const shift = @as(c_int, c.GetKeyState(c.VK_CONTROL)) & 0x8000 != 0;
                const alt = @as(c_int, c.GetKeyState(c.VK_MENU)) & 0x8000 != 0;
                const ev = Events{ .KeyDown = .{ .keyCode = @intCast(0xFFFF & wParam), .ctrl = ctrl, .shift = shift, .alt = alt } };
                _ = win.onMessage(ev);
            },
            c.WM_KEYUP, c.WM_SYSKEYUP => {
                const ctrl = @as(c_int, c.GetKeyState(c.VK_SHIFT)) & 0x8000 != 0;
                const shift = @as(c_int, c.GetKeyState(c.VK_CONTROL)) & 0x8000 != 0;
                const alt = @as(c_int, c.GetKeyState(c.VK_MENU)) & 0x8000 != 0;
                const ev = Events{ .KeyUp = .{ .keyCode = @intCast(0xFFFF & wParam), .ctrl = ctrl, .shift = shift, .alt = alt } };
                _ = win.onMessage(ev);
            },
            else => {},
        }
    }
    return c.DefWindowProcA(hWnd, uMsg, wParam, lParam);
}
pub fn appInit() void {
    gInstance = c.GetModuleHandleA(null);
    // register window class
    const wc = c.WNDCLASSEXA{
        .cbSize = @sizeOf(c.WNDCLASSEXA),
        .style = c.CS_HREDRAW | c.CS_VREDRAW | c.CS_DBLCLKS,
        .lpfnWndProc = myWndProc,
        .hInstance = gInstance,
        .hIcon = null, //c.LoadIconA(null, 32512),
        .hCursor = null, // c.LoadCursorA(null, 32512),
        .hbrBackground = c.GetSysColorBrush(c.COLOR_WINDOW),
        .lpszClassName = ZKEKE_CLASS_NAME,
    };
    _ = c.RegisterClassExA(&wc);
}
pub fn appDeinit() void {}

pub fn appQuit() void {
    c.PostQuitMessage(0);
}

pub fn appRun() void {
    var msg: c.MSG = undefined;
    while (c.GetMessageA(&msg, null, 0, 0) != 0) {
        _ = c.TranslateMessage(&msg);
        _ = c.DispatchMessageA(&msg);
    }
}

// Window
pub const Window = struct {
    hWnd: c.HWND,
    width: i32,
    height: i32,
    allocator: std.mem.Allocator,

    const Self = @This();
    pub fn init(allocator: std.mem.Allocator, width: i32, height: i32) ?*Self {
        // create window
        const hWnd = c.CreateWindowExA(
            0,
            ZKEKE_CLASS_NAME,
            "Zkeke",
            c.WS_OVERLAPPEDWINDOW,
            c.CW_USEDEFAULT,
            c.CW_USEDEFAULT,
            width,
            height,
            null,
            null,
            gInstance,
            null,
        );
        if (hWnd == null) {
            return null;
        }

        _ = c.ShowWindow(hWnd, c.SW_SHOW);
        _ = c.UpdateWindow(hWnd);

        const win = allocator.create(Self) catch return null;
        win.* = Self{
            .hWnd = hWnd,
            .width = width,
            .height = height,
            .allocator = allocator,
        };

        // set window user data
        const ptr: usize = @intFromPtr(hWnd);
        gWinMap.put(ptr, win) catch {};

        // call create event
        const ev: Events = .{ .Create = {} };
        _ = win.onMessage(ev);

        return win;
    }

    pub fn deinit(self: *Self) void {
        _ = c.DestroyWindow(self.hWnd);
        self.allocator.destroy(self);
    }
    pub fn setTitle(self: *Self, title: []const u8) void {
        const title_c: [*c]const u8 = @ptrCast(title.ptr);
        _ = c.SetWindowTextA(self.hWnd, title_c);
    }
    pub fn setFocus(self: *Self) void {
        _ = c.SetFocus(self.hWnd);
    }
    pub fn getDrawableSize(self: *Self) [2]i32 {
        var rect: c.RECT = undefined;
        _ = c.GetClientRect(self.hWnd, &rect);
        return [2]i32{ rect.right, rect.bottom };
    }
    pub fn newSurface(self: *Self) ?*anyopaque {
        // const sz = self.getDrawableSize();
        const hdc = c.GetDC(self.hWnd);
        const surf = c.cairo_win32_surface_create(hdc);
        return surf;
    }

    pub fn onMessage(self: *Self, ev: Events) bool {
        const ptr: usize = @intFromPtr(self.hWnd);
        switch (ev) {
            .Create => {
                std.log.info("win: {d}, create", .{ptr});
            },
            .Destroy => {
                std.log.info("win: {d}, destroy", .{ptr});
            },
            .MouseDown => |info| {
                std.log.info("win: {d}, mouse down: {d}, {d}, button: {d}", .{ ptr, info.x, info.y, info.button });
            },
            else => {
                std.log.info("win: {d}, {any}", .{ ptr, ev });
            },
        }
        return true;
    }
};
