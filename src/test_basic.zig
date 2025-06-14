const std = @import("std");
const comm = @import("comm.zig");
const yoga = @import("yoga.zig");
const qjs = @import("quickjs.zig");

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer _ = gpa.deinit();
    // const allocator = gpa.allocator();

    std.log.debug("Select the run case:", .{});
    std.log.debug("1. yoga basic", .{});
    std.log.debug("2. quickjs basic", .{});
    std.log.debug("3. cairo basic", .{});
    std.log.debug("4. windows basic", .{});
    std.log.debug("----------------------------------\nInput your select: ", .{});
    var select_id: [8]u8 = undefined;
    _ = try std.io.getStdIn().reader().read(&select_id);
    // std.log.debug("select id: {any}", .{select_id});

    switch (select_id[0]) {
        '1' => try testYogaBasic(),
        '2' => try testQuickjsBasic(),
        // '3' => try testCairoBasic(),
        // '4' => try testWindowsBasic(),
        else => {
            std.log.debug("nothing...", .{});
        },
    }
}

fn testYogaBasic() !void {
    var node = yoga.Node.init();
    defer node.freeAll();

    node.setWidth(comm.KKLayoutUnitValue.fromPercent(100));
    node.setHeight(comm.KKLayoutUnitValue.fromFixed(100));
    node.setFlexDirection(.Row);

    var child1 = yoga.Node.init();
    node.addChild(&child1);
    child1.setWidth(comm.KKLayoutUnitValue.fromPercent(50));
    child1.setHeight(comm.KKLayoutUnitValue.fromFixed(50));
    child1.setPadding(comm.KKLayoutEdge.All, comm.KKLayoutUnitValue.fromFixed(10));
    child1.setBorder(comm.KKLayoutEdge.All, comm.KKLayoutUnitValue.fromFixed(1));

    var child2 = yoga.Node.init();
    node.addChild(&child2);
    child1.setWidth(comm.KKLayoutUnitValue.fromPercent(50));
    child1.setHeight(comm.KKLayoutUnitValue.fromFixed(60));

    // absolute
    var node2 = yoga.Node.init();
    node.addChild(&node2);
    node2.setPositionType(.Relative);
    // node2.setPosition(.Left, comm.KKLayoutUnitValue.fromFixed(10));
    // node2.setPosition(.Top, comm.KKLayoutUnitValue.fromFixed(12));
    node2.setWidth(comm.KKLayoutUnitValue.fromFixed(111));
    node2.setHeight(comm.KKLayoutUnitValue.fromFixed(88));
    node2.setPosition(.Right, comm.KKLayoutUnitValue.fromFixed(20));
    node2.setPosition(.Bottom, comm.KKLayoutUnitValue.fromFixed(22));

    node.calculateLayout(400, 200, .LTR);

    const style = node.getComputedLayout();
    std.debug.print("node: {s}\n", .{try style.toJson()});

    const style1 = child1.getComputedLayout();
    std.debug.print("child1: {s}\n", .{try style1.toJson()});

    const style2 = child2.getComputedLayout();
    std.debug.print("child2: {s}\n", .{try style2.toJson()});

    // node2.calculateLayout(200, 200, .LTR);
    const style3 = node2.getComputedLayout();
    std.debug.print("node2: {s}\n", .{try style3.toJson()});
}

fn testQuickjsBasic() !void {
    const app = qjs.Quickjs.init();
    defer app.deinit();
    std.log.debug("qjs app: {any}", .{app});
}
