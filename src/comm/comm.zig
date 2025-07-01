pub const define = @import("define.zig");

// Events
pub const Events = union(enum) {
    Create,
    Destroy,
    Close,
    Show,
    Hide,
    Active: bool,
    Move: define.KKPoint,
    Resize: define.KKRect,
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
    ContextMenu: define.KKPoint,
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
