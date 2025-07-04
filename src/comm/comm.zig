pub const define = @import("define.zig");

// Events
pub const Events = union(enum) {
    Create,
    Destroy,
    Close,
    Show,
    Hide,
    Active: bool,
    Move: define.KKPosEventInf,
    Resize: define.KKSizeEventInf,
    Draw,
    // keyboard
    KeyDown: define.KKKeyEventInf,
    KeyUp: define.KKKeyEventInf,
    Char: u32,
    // mouse
    MouseDown: define.KKMouseEventInf,
    MouseUp: define.KKMouseEventInf,
    MouseMove: define.KKMouseEventInf,
    MouseDblClick: define.KKMouseEventInf,
    MouseWheel: define.KKMouseEventInf,
    // other
    ContextMenu: define.KKPosEventInf,
    CopyData: void,
    Drops: void,
};

// Properties
pub const Property = union(enum) {
    Title: []const u8,
    Icon: []const u8,
    Size: define.KKSize,
    Position: define.KKPoint,
    MinSize: define.KKSize,
    MaxSize: define.KKSize,
    Resizable: bool,
    Fullscreen: bool,
    Visible: bool,
    AlwaysOnTop: bool,
    Decorated: bool,
    Transparent: bool,
};

pub const UiRootInterface = struct {
    object: *anyopaque,
    eventCB: *const fn (ptr: *anyopaque, ev: Events) void,
};
