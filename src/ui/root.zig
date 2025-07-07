const std = @import("std");
const cairo = @import("cairo");
const win = @import("window");
const comm = @import("comm");

pub const UiRoot = struct {
    // surface: cairo.Surface,
    w: *win.Window,

    var ptList = std.ArrayList(comm.define.KKPoint).init(std.heap.page_allocator);

    const Self = @This();
    pub fn init(w: *win.Window) Self {
        // const surf = cairo.Surface.initFromSurface(w.getSurface());
        return Self{
            // .surface = surf,
            .w = w,
        };
    }
    pub fn deinit(self: *Self) void {
        self.surface.deinit();
    }

    pub fn render(self: *Self) void {
        const w_surf = self.w.getSurface() orelse return;
        const surf = cairo.Surface.initFromSurface(w_surf);
        // defer surf.deinit();
        var ctx = cairo.Context.init(&surf);
        defer ctx.deinit();
        ctx.setSourceRGB(0.5, 0.5, 0.5);
        ctx.paint();
        ctx.setLineWidth(2);
        ctx.setSourceRGB(1.0, 0.0, 0.0);
        for (ptList.items) |pt| {
            // ctx.moveTo(pt.x, pt.y);
            ctx.lineTo(pt.x, pt.y);
            // std.log.info("pt: {d}, {d}", .{ pt.x, pt.y });
        }
        ctx.stroke();

        std.log.info("rendering", .{});
    }

    pub fn cbHandleEvent(ptr: *anyopaque, ev: comm.Events) void {
        const self: *UiRoot = @ptrCast(@alignCast(ptr));
        self.handleEvent(ev);
    }

    pub fn handleEvent(self: *Self, ev: comm.Events) void {
        // std.log.info("handle event: {any}", .{ev});
        switch (ev) {
            .MouseDown => {
                ptList.append(comm.define.KKPoint{
                    .x = @floatFromInt(ev.MouseDown.x),
                    .y = @floatFromInt(ev.MouseDown.y),
                }) catch unreachable;

                std.log.info("MouseDown: {d}, {d}", .{ ev.MouseDown.x, ev.MouseDown.y });
                self.w.invalidate();
            },
            .Draw => {
                self.render();
            },
            else => {},
        }
    }
};
