const std = @import("std");
const c = @cImport({
    @cDefine("WIN32_LEAN_AND_MEAN", "1");
    @cDefine("_WIN32_WINNT", "0x0601");
    @cInclude("windows.h");
});

const ZKEKE_CLASS_NAME = "ZkekeWindowClass";
var gInstance: c.HINSTANCE = undefined;
var gWinMap = std.AutoHashMap(usize, *Window).init(std.heap.page_allocator);

fn myWndProc(hWnd: c.HWND, uMsg: u32, wParam: c.WPARAM, lParam: c.LPARAM) callconv(.winapi) c.LRESULT {
    const ptr = @intFromPtr(hWnd);
    if (gWinMap.get(ptr)) |win| {
        // check quit and translate message
        switch (uMsg) {
            c.WM_DESTROY => {},
            else => {},
        }
        // call onMessage
        const ev: Events = .{ .Create = {} };
        _ = win.onMessage(ev);
    }
    return c.DefWindowProcA(hWnd, uMsg, wParam, lParam);
}
pub fn appInit() void {
    gInstance = c.GetModuleHandleA(null);
    // register window class
    const wc = c.WNDCLASSEXA{
        .cbSize = @sizeOf(c.WNDCLASSEXA),
        .style = c.CS_HREDRAW | c.CS_VREDRAW,
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

// Events
pub const Events = union(enum) {
    Create,
    Destroy,
    Close,
    Show,
    Hide,
    Move: struct {
        x: i32,
        y: i32,
    },
    Resize: struct {
        width: i32,
        height: i32,
        clientWidth: i32,
        clientHeight: i32,
    },
    KeyDown: struct {
        keyCode: u32,
        ctrl: bool,
        alt: bool,
        shift: bool,
    },
    KeyUp,
    Char: u32,
    MouseDown: struct {
        x: i32,
        y: i32,
        button: u32,
    },
    MouseUp,
    MouseMove,
    MouseWheel: struct {
        delta: i32,
    },
};

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
        const ptr: usize = @intFromPtr(win);
        gWinMap.put(ptr, win) catch {};
        _ = c.SetWindowLongPtrA(hWnd, c.GWLP_USERDATA, @intCast(ptr));

        return win;
    }

    pub fn deinit(self: *Self) void {
        _ = c.DestroyWindow(self.hWnd);
        self.allocator.destroy(self);
    }

    pub fn onMessage(self: *Self, ev: Events) bool {
        _ = self;
        _ = ev;
        return true;
    }
};
