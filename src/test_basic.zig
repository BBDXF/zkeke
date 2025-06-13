const std = @import("std");
const comm = @import("comm.zig");
const yoga = @import("yoga.zig");

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // defer _ = gpa.deinit();
    // const allocator = gpa.allocator();
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
