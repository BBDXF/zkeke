const std = @import("std");
const comm = @import("comm");
const cairo = @import("cairo");

// 对 UI 公共接口进行抽象
pub const UiInterface = struct {
    object: *anyopaque,
    // public interfaces
    fnRender: *const fn (*anyopaque, *cairo.Surface) void,
    fnOnUpdate: *const fn (*anyopaque, comm.Events) void,
    fnGetRect: *const fn (*anyopaque) comm.define.KKRect,
    // fnAddChildren: *const fn (*anyopaque, UiInterface, i32) void,
    // fnRemoveChildren: *const fn (*anyopaque, i32) void,
    // fnGetChildren: *const fn (*anyopaque, i32) ?UiInterface,
    // fnGetChildrenCount: *const fn (*anyopaque) i32,
    childrens: std.ArrayList(UiInterface),

    const Self = @This();

    pub fn getObject(self: Self) *anyopaque {
        return self.object;
    }

    // public interfaces
    pub fn render(self: Self, surf: *cairo.Surface) void {
        self.fnRender(self.object, surf);
    }

    pub fn onUpdate(self: Self, p: comm.Events) void {
        self.fnOnUpdate(self.object, p);
    }

    pub fn getRect(self: Self) comm.define.KKRect {
        return self.fnGetRect(self.object);
    }
    // children
    pub fn addChildren(self: *Self, p: UiInterface, index: usize) void {
        _ = index;
        self.childrens.append(p) catch unreachable;
    }
    pub fn removeChildren(self: *Self, index: usize) void {
        _ = self.childrens.orderedRemove(index);
    }
    pub fn getChildren(self: Self, index: usize) ?UiInterface {
        return self.childrens.items[index];
    }
    pub fn getChildrenCount(self: Self) usize {
        return self.childrens.items.len;
    }
};

// 对 UI 方法的拆包和封装，避免签名不一样的问题
pub fn UiInterfaceWrapper(comptime T: type, ptr: *T) UiInterface {
    const renderCB = struct {
        fn render(p: *anyopaque, surf: *cairo.Surface) void {
            var ctx: *T = @ptrCast(@alignCast(p));
            ctx.render(surf);
        }
    }.render;
    const updateCB = struct {
        fn update(p: *anyopaque, property: comm.Events) void {
            var ctx: *T = @ptrCast(@alignCast(p));
            ctx.onUpdate(property);
        }
    }.update;
    const getRectCB = struct {
        fn getRect(p: *anyopaque) comm.define.KKRect {
            var ctx: *T = @ptrCast(@alignCast(p));
            return ctx.getRect();
        }
    }.getRect;
    // const addChildrenCB = struct {
    //     fn addChildren(p: *anyopaque, child: UiInterface, index: i32) void {
    //         var ctx: *T = @ptrCast(@alignCast(p));
    //         ctx.addChildren(child, index);
    //     }
    // }.addChildren;
    // const removeChildrenCB = struct {
    //     fn removeChildren(p: *anyopaque, index: i32) void {
    //         var ctx: *T = @ptrCast(@alignCast(p));
    //         ctx.removeChildren(index);
    //     }
    // }.removeChildren;
    // const getChildrenCB = struct {
    //     fn getChildren(p: *anyopaque, index: i32) ?UiInterface {
    //         var ctx: *T = @ptrCast(@alignCast(p));
    //         return ctx.getChildren(index);
    //     }
    // }.getChildren;
    // const getChildrenCountCB = struct {
    //     fn getChildrenCount(p: *anyopaque) i32 {
    //         var ctx: *T = @ptrCast(@alignCast(p));
    //         return ctx.getChildrenCount();
    //     }
    // }.getChildrenCount;
    return UiInterface{
        .object = @ptrCast(ptr),
        .fnRender = &renderCB,
        .fnOnUpdate = &updateCB,
        .fnGetRect = &getRectCB,
        // .fnAddChildren = &addChildrenCB,
        // .fnRemoveChildren = &removeChildrenCB,
        // .fnGetChildren = &getChildrenCB,
        // .fnGetChildrenCount = &getChildrenCountCB,
        .childrens = std.ArrayList(UiInterface).init(std.heap.page_allocator),
    };
}

pub const UIBase = struct {
    width: i32 = 0,
    height: i32 = 0,

    const Self = @This();
    pub fn init(w: i32, h: i32) Self {
        return .{
            .width = w,
            .height = h,
        };
    }
    pub fn deinit(self: *Self) void {
        _ = self;
    }
    pub fn onUpdate(self: *Self, ev: comm.Events) void {
        _ = self;
        std.debug.print("onUpdate {any}\n", .{ev});
    }
    pub fn render(self: *Self, surf: *cairo.Surface) void {
        var ctx = cairo.Context.init(surf);
        defer ctx.deinit();
        ctx.setSourceRGB(0.5, 0.5, 0.5);
        ctx.rectangle(0, 0, @floatFromInt(self.width), @floatFromInt(self.height));
        ctx.fill();
        std.debug.print("rendering\n", .{});
    }
    pub fn getRect(self: *Self) comm.define.KKRect {
        std.debug.print("getRect\n", .{});
        return .{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(self.width),
            .height = @floatFromInt(self.height),
        };
    }
    // pub fn addChildren(self: *Self, child: UiInterface, index: i32) void {
    //     _ = self;
    //     _ = child;
    //     _ = index;
    //     std.debug.print("addChildren\n", .{});
    // }
    // pub fn removeChildren(self: *Self, index: i32) void {
    //     _ = self;
    //     _ = index;
    //     std.debug.print("removeChildren\n", .{});
    // }
    // pub fn getChildren(self: *Self, index: i32) ?UiInterface {
    //     _ = self;
    //     _ = index;
    //     std.debug.print("getChildren\n", .{});
    //     return null;
    // }
    // pub fn getChildrenCount(self: *Self) i32 {
    //     _ = self;
    //     std.debug.print("getChildrenCount\n", .{});
    //     return 0;
    // }
};

// pub fn main() !void {
//     var ui1 = UIBase.init();
//     const ui = UiInterfaceWrapper(UIBase, &ui1);
//     ui.render();
// }
