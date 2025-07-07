const std = @import("std");

// Point struct
pub const KKPoint = struct {
    x: f32 = 0,
    y: f32 = 0,
};

// limitation struct
pub const KKSizeLimit = struct {
    minWidth: f32 = -1,
    maxWidth: f32 = -1,
    minHeight: f32 = -1,
    maxHeight: f32 = -1,
};

pub const KKPosEventInf = struct {
    x: i32 = 0,
    y: i32 = 0,
};
pub const KKSizeEventInf = struct {
    width: i32 = 0,
    height: i32 = 0,
};

pub const KKMouseEventInf = struct {
    x: i32 = 0,
    y: i32 = 0,
    button: u32 = 0,
    delta: i32 = 0,
};
pub const KKKeyEventInf = struct {
    keyCode: u32 = 0, // VK_CODE
    ctrl: bool = false,
    alt: bool = false,
    shift: bool = false,
};
// rect struct
pub const KKRect = struct {
    x: f32 = 0,
    y: f32 = 0,
    width: f32 = 0,
    height: f32 = 0,

    const Self = @This();

    pub fn fromPositon(x1: f32, y1: f32, x2: f32, y2: f32) KKRect {
        return .{ .x = x1, .y = y1, .width = x2 - x1, .height = y2 - y1 };
    }
    pub fn getRBPoint(self: Self) KKPoint {
        return .{ .x = self.x + self.width, .y = self.y + self.height };
    }
    pub fn getTLPoint(self: Self) KKPoint {
        return .{ .x = self.x, .y = self.y };
    }
    pub fn offset(self: Self, x: f32, y: f32) void {
        self.x += x;
        self.y += y;
    }
    pub fn resize(self: Self, width: f32, height: f32) void {
        self.width = width;
        self.height = height;
    }
    pub fn isInside(self: Self, x: f32, y: f32) bool {
        return x >= self.x and x <= self.x + self.width and y >= self.y and y <= self.y + self.height;
    }
};

// border rect struct
pub const KKBorderRect = struct {
    left: f32 = 0,
    top: f32 = 0,
    right: f32 = 0,
    bottom: f32 = 0,

    pub fn fromAll(value: f32) KKBorderRect {
        return .{ .left = value, .top = value, .right = value, .bottom = value };
    }
};

// color struct
pub const KKColor = struct {
    r: u8 = 0,
    g: u8 = 0,
    b: u8 = 0,
    a: u8 = 255,

    const Self = @This();

    pub fn fromUint(value: u32) KKColor {
        return .{
            .r = @truncate((value >> 24) & 0xFF),
            .g = @truncate((value >> 16) & 0xFF),
            .b = @truncate((value >> 8) & 0xFF),
            .a = @truncate(value & 0xFF),
        };
    }
    pub fn toUint(self: Self) u32 {
        const value: u32 = (self.r << 24) | (self.g << 16) | (self.b << 8) | self.a;
        return value;
    }

    // from hsl
    // h: 0-360
    // s: 0-100
    // v: 0-100
    // a: 0-255
    pub fn fromHSLA(h: u16, s: u8, v: u8, a: u8) KKColor {
        const hf: f32 = @intCast(h);
        hf = hf / 360.0;
        const sf: f32 = @intCast(s);
        sf = sf / 100.0;
        const vf: f32 = @intCast(v);
        vf = vf / 100.0;
        const c = vf * sf;
        const x = c * (1 - std.math.abs(hf * 2 - 1));
        const m = vf - c;
        const r = if (hf >= 0 and hf < 1) c + m else if (hf >= 1 and hf < 2) x + m else m;
        const g = if (hf >= 0 and hf < 1) x + m else if (hf >= 1 and hf < 2) c + m else m;
        const b = if (hf >= 0 and hf < 1) m else if (hf >= 1 and hf < 2) x + m else c + m;
        return .{
            .r = @truncate(r * 255),
            .g = @truncate(g * 255),
            .b = @truncate(b * 255),
            .a = a,
        };
    }
    pub fn fromHSL(h: u16, s: u8, v: u8) KKColor {
        return fromHSLA(h, s, v, 255);
    }
};

// define css for yoga
//     Align,
//     BoxSizing,
//     Dimension,
//     Direction,
//     Display,
//     Edge,
//     FlexDirection,
//     Gutter,
//     Justify,
//     MeasureMode,
//     NOdeType,
//     Overflow,
//     PositionType,
//     Unit,
//     Wrap,

pub const KKLayoutAlign = enum(u8) {
    Auto = 0,
    FlexStart = 1,
    Center = 2,
    FlexEnd = 3,
    Stretch = 4,
    Baseline = 5,
    SpaceBetween = 6,
    SpaceAround = 7,
    SpaceEvenly = 8,
};

pub const KKLayoutBoxSizing = enum(u8) {
    BorderBox = 0,
    ContentBox = 1,
};

pub const KKLayoutDimension = enum(u8) {
    Width = 0,
    Height = 1,
};

pub const KKLayoutDirection = enum(u8) {
    Inherit = 0,
    LTR = 1,
    RTL = 2,
};

pub const KKLayoutDisplay = enum(u8) {
    Flex = 0,
    None = 1,
    Contents = 2,
};

pub const KKLayoutEdge = enum(u8) {
    Left = 0,
    Top = 1,
    Right = 2,
    Bottom = 3,
    Start = 4,
    End = 5,
    Horizontal = 6,
    Vertical = 7,
    All = 8,
};

pub const KKLayoutFlexDirection = enum(u8) {
    Column = 0,
    ColumnReverse = 1,
    Row = 2,
    RowReverse = 3,
};

pub const KKLayoutGutter = enum(u8) {
    Column = 0,
    Row = 1,
    All = 2,
};

pub const KKLayoutJustify = enum(u8) {
    FlexStart = 0,
    Center = 1,
    FlexEnd = 2,
    SpaceBetween = 3,
    SpaceAround = 4,
    SpaceEvenly = 5,
};

pub const KKLayoutMeasureMode = enum(u8) {
    Undefined = 0,
    Exactly = 1,
    AtMost = 2,
};

pub const KKLayoutNodeType = enum(u8) {
    Default = 0,
    Text = 1,
};

pub const KKLayoutOverflow = enum(u8) {
    Visible = 0,
    Hidden = 1,
    Scroll = 2,
};

pub const KKLayoutPositionType = enum(u8) {
    Static = 0,
    Relative = 1,
    Absolute = 2,
};

pub const KKLayoutUnit = enum(u8) {
    Undefined = 0,
    Point = 1,
    Percent = 2,
    Auto = 3,
    MaxContent = 4,
    FitContent = 5,
    Stretch = 6,
};

pub const KKLayoutWrap = enum(u8) {
    NoWrap = 0,
    Wrap = 1,
    WrapReverse = 2,
};

pub const KKLayoutComputedStyle = struct {
    left: f32 = 0,
    top: f32 = 0,
    right: f32 = 0,
    bottom: f32 = 0,
    width: f32 = 0,
    height: f32 = 0,
    direction: KKLayoutDirection = .Inherit,
    hadOverflow: bool = false,
    margin: KKBorderRect = .{},
    padding: KKBorderRect = .{},
    border: KKBorderRect = .{},
    rawHeight: f32 = 0,
    rawWidth: f32 = 0,

    pub fn toJson(self: *const KKLayoutComputedStyle) ![]const u8 {
        var buffer = std.ArrayList(u8).init(std.heap.page_allocator);
        defer buffer.deinit();
        try std.json.stringify(self, .{
            .whitespace = .indent_2,
        }, buffer.writer());
        return try buffer.toOwnedSlice();
    }
};

pub const KKLayoutUnitValue = struct {
    unit: KKLayoutUnit = KKLayoutUnit.Undefined,
    value: f32 = 0,

    pub fn isUndefined(self: KKLayoutUnitValue) bool {
        return self.unit == KKLayoutUnit.Undefined;
    }
    // 0-N
    pub fn fromFixed(value: f32) KKLayoutUnitValue {
        return .{
            .unit = KKLayoutUnit.Point,
            .value = value,
        };
    }
    // 0-100
    pub fn fromPercent(value: f32) KKLayoutUnitValue {
        return .{
            .unit = KKLayoutUnit.Percent,
            .value = value,
        };
    }
    // auto
    pub fn fromAuto() KKLayoutUnitValue {
        return .{
            .unit = KKLayoutUnit.Auto,
            .value = 0,
        };
    }
};

// parse css value to unit and value
pub fn parseUnit(value: []const u8) KKLayoutUnitValue {
    var tmp = std.mem.trim(u8, value, " ");
    if (std.mem.endsWith(u8, tmp, "%")) {
        const v = std.fmt.parseInt(i32, tmp[0 .. tmp.len - 1], 10) catch 0;
        return .{
            .unit = KKLayoutUnit.Percent,
            .value = @intCast(v),
        };
    }
    if (std.mem.endsWith(u8, tmp, "px") || std.mem.endsWith(u8, tmp, "pt")) {
        const v = std.fmt.parseInt(i32, tmp[0 .. tmp.len - 2], 10) catch 0;
        return .{
            .unit = KKLayoutUnit.Point,
            .value = @intCast(v),
        };
    }
    if (std.mem.eql(u8, tmp, "auto")) {
        return .{
            .unit = KKLayoutUnit.Auto,
            .value = 0,
        };
    }
    if (std.mem.eql(u8, tmp, "max-content")) {
        return .{
            .unit = KKLayoutUnit.MaxContent,
            .value = 0,
        };
    }
    if (std.mem.eql(u8, tmp, "fit-content")) {
        return .{
            .unit = KKLayoutUnit.FitContent,
            .value = 0,
        };
    }
    if (std.mem.eql(u8, tmp, "stretch")) {
        return .{
            .unit = KKLayoutUnit.Stretch,
            .value = 0,
        };
    }
    // no unit
    const v = std.fmt.parseInt(i32, tmp, 10) catch 0;
    return .{
        .unit = KKLayoutUnit.Point,
        .value = @intCast(v),
    };
}

pub fn parseUnitList(value: []const u8) []KKLayoutUnitValue {
    const tmp = std.mem.trim(u8, value, " ");
    var values = std.ArrayList(KKLayoutUnitValue).init(std.heap.page_allocator);
    var split = std.mem.split(u8, tmp, " ");
    while (split.next()) |v| {
        const unitValue = parseUnit(v);
        values.append(unitValue) catch {};
    }
    return values.toOwnedSlice();
}
