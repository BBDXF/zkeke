const std = @import("std");
const Property = struct {};

// 对 UI 公共接口进行抽象
const UiInterface = struct {
    object: *anyopaque,
    fnRender: *const fn (*anyopaque) void,
    fnUpdate: *const fn (*anyopaque, Property) void,

    const Self = @This();

    pub fn render(self: Self) void {
        self.fnRender(self.object);
    }

    pub fn update(self: Self, p: Property) void {
        self.fnUpdate(self.object, p);
    }
};

// 对 UI 方法的拆包和封装，避免签名不一样的问题
pub fn UiInterfaceWrapper(comptime T: type, ptr: *T) UiInterface {
    const renderCB = struct {
        fn render(p: *anyopaque) void {
            var ctx: *T = @ptrCast(@alignCast(p));
            ctx.draw();
        }
    }.render;
    const updateCB = struct {
        fn update(p: *anyopaque, property: Property) void {
            var ctx: *T = @ptrCast(@alignCast(p));
            ctx.update(property);
        }
    }.update;
    return UiInterface{
        .object = @ptrCast(ptr),
        .fnRender = &renderCB,
        .fnUpdate = &updateCB,
    };
}

const UIBase = struct {
    const Self = @This();
    pub fn init() Self {
        return .{};
    }
    pub fn deinit(self: *Self) void {
        _ = self;
    }
    pub fn update(self: *Self, p: Property) void {
        _ = self;
        _ = p;
        std.debug.print("update\n", .{});
    }
    pub fn draw(self: *Self) void {
        _ = self;
        std.debug.print("drawing\n", .{});
    }
};
