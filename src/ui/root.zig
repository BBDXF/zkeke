const std = @import("std");
const cairo = @import("cairo");
const win = @import("window");
const comm = @import("comm");
const uibase = @import("base.zig");
pub const UIBase = uibase.UIBase;
pub const UiInterface = uibase.UiInterface;
pub const UiInterfaceWrapper = uibase.UiInterfaceWrapper;

pub const UILookupInf = struct {
    // root: ?UiInterface = null,
    // offset_x: i32 = 0, // root relative
    // offset_y: i32 = 0,
    x: f32 = 0, // x relative
    y: f32 = 0,
};

pub const UiRoot = struct {
    // surface: cairo.Surface,
    w: *win.Window,
    uiBase: uibase.UIBase,
    uiRoot: uibase.UiInterface,

    const Self = @This();
    pub fn init(w: *win.Window) Self {
        var ui = uibase.UIBase.init(w.width, w.height);
        return Self{
            // .surface = surf,
            .w = w,
            .uiBase = ui,
            .uiRoot = uibase.UiInterfaceWrapper(uibase.UIBase, &ui),
        };
    }
    pub fn deinit(self: *Self) void {
        _ = self;
    }

    pub fn render(self: *Self) void {
        const w_surf = self.w.getSurface() orelse return;
        var surf = cairo.Surface.initFromSurface(w_surf);
        // defer surf.deinit();
        // root
        self.uiRoot.render(&surf);
        // child
        const count: usize = @intCast(self.uiRoot.getChildrenCount());
        for (0..count) |i| {
            if (self.uiRoot.getChildren(@intCast(i))) |item| {
                item.render(&surf);
            }
        }

        std.log.info("rendering", .{});
    }

    pub fn cbHandleEvent(ptr: *anyopaque, ev: comm.Events) void {
        const self: *UiRoot = @ptrCast(@alignCast(ptr));
        self.handleEvent(ev);
    }

    fn lookupUIByPos(root: uibase.UiInterface, inf: UILookupInf) ?uibase.UiInterface {
        var i = root.getChildrenCount();
        while (i > 0) : (i -= 1) {
            if (root.getChildren(i - 1)) |item| {
                if (item.getRect().isInside(inf.x, inf.y)) {
                    if (item.getChildrenCount() > 0) {
                        return lookupUIByPos(item, .{
                            .x = inf.x - item.getRect().x,
                            .y = inf.y - item.getRect().y,
                        });
                    } else {
                        return item;
                    }
                }
            }
        }
        return null;
    }

    pub fn handleEvent(self: *Self, ev: comm.Events) void {
        // std.log.info("handle event: {any}", .{ev});
        switch (ev) {
            .MouseDown, .MouseUp, .MouseMove, .MouseWheel, .MouseDblClick => |mev| {
                // std.log.info("mouse event: {any}", .{mev});
                if (lookupUIByPos(self.uiRoot, .{
                    .x = @floatFromInt(mev.x),
                    .y = @floatFromInt(mev.y),
                })) |item| {
                    item.onUpdate(ev);
                }
            },
            .Draw => {
                self.render();
            },
            else => {},
        }
    }
};
