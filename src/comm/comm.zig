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

    // UI
    Property: Property, // css property change
};

// Properties
pub const Property = union(enum) {
    Title: []const u8,
    Icon: []const u8,
    Size: define.KKSizeEventInf,
    Position: define.KKPoint,
    MinSize: define.KKSizeEventInf,
    MaxSize: define.KKSizeEventInf,
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
