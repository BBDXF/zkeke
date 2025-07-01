const std = @import("std");
const builtin = @import("builtin");
const comm = @import("zkeke").comm.define;
const yoga = @import("zkeke").yoga;
const qjs = @import("zkeke").quickjs;
const cairo = @import("zkeke").cairo;
const wm = @import("zkeke").win;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.log.info("Select the run case:", .{});
    std.log.info("1. yoga basic", .{});
    std.log.info("2. quickjs basic", .{});
    std.log.info("3. cairo basic", .{});
    std.log.info("4. windows basic", .{});
    std.log.info("----------------------------------\nInput your select: ", .{});
    var select_id: [8]u8 = undefined;
    _ = try std.io.getStdIn().reader().read(&select_id);
    // std.log.info("select id: {any}", .{select_id});

    switch (select_id[0]) {
        '1' => try testYogaBasic(allocator),
        '2' => try testQuickjsBasic(allocator),
        '3' => try testCairoBasic(allocator),
        '4' => try testWindowsBasic(allocator),
        else => {
            std.log.info("nothing...", .{});
        },
    }
}

fn testYogaBasic(allocator: std.mem.Allocator) !void {
    _ = allocator;
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
    std.log.info("node: {s}\n", .{try style.toJson()});

    const style1 = child1.getComputedLayout();
    std.log.info("child1: {s}\n", .{try style1.toJson()});

    const style2 = child2.getComputedLayout();
    std.log.info("child2: {s}\n", .{try style2.toJson()});

    // node2.calculateLayout(200, 200, .LTR);
    const style3 = node2.getComputedLayout();
    std.log.info("node2: {s}\n", .{try style3.toJson()});
}

fn testQuickjsBasic(allocator: std.mem.Allocator) !void {
    _ = allocator;
    const app = qjs.Quickjs.init();
    defer app.deinit();

    // run
    _ = app.eval_js_code("console.log('hello world');", false);
    _ = app.loop();
    std.log.info("-------------------------", .{});

    // run file
    const js_demo = @embedFile("basic.js");
    _ = app.eval_js_code(js_demo, false);
    _ = app.loop();

    std.log.info("---------------------------", .{});
    std.log.info("tests_basic run finished.", .{});
}

fn testCairoBasic(allocator: std.mem.Allocator) !void {
    _ = allocator;
    const sf = cairo.Surface.init(600, 400);
    defer sf.deinit();
    var cr = cairo.Context.init(&sf);
    defer cr.deinit();
    // quality
    cr.setAntialias(6);
    // background
    cr.setSourceRGB(1.0, 1.0, 1.0);
    cr.paint();
    // line gradient
    var grad = cairo.Gradient.initLinear(300.0, 0.0, 0.0, 300.0);
    grad.addColorStop(0.0, 0.6, 0.0, 0.0, 1.0);
    grad.addColorStop(1.0, 0.0, 1.0, 0.0, 1.0);
    grad.rotate(std.math.pi * 2.0);
    cr.setSource(&grad);
    cr.paint();

    // rect
    cr.rectangle(50, 50, 100, 100);
    cr.setSourceRGB(0.5, 0.5, 0.0);
    cr.fillPreserve();
    cr.setSourceRGB(1.0, 0.0, 0.0);
    cr.setLineWidth(2.0);
    cr.stroke();
    // path
    cr.setSourceRGB(0.0, 0.0, 1.0);
    cr.setLineWidth(2.0);
    cr.moveTo(200, 50);
    cr.lineTo(250, 150);
    cr.lineTo(50, 190);
    cr.closePath();
    cr.stroke();

    // font
    cr.setSourceRGB(0.8, 0.0, 0.6);
    cr.moveTo(50, 220);
    // cr.selectFontFace("Sans", 0, 0);
    cr.setFontSize(18);
    cr.showText("Hello World!");

    // write
    _ = sf.writeToPng("test.png");
    std.log.info("Wrote test.png\n", .{});
}

fn testWindowsBasic(allocator: std.mem.Allocator) !void {
    wm.appInit();
    defer wm.appDeinit();

    var wnd = wm.Window.init(allocator, 600, 400) orelse return;
    defer wnd.deinit();
    wnd.setTitle("window 1");

    var wnd2 = wm.Window.init(allocator, 600, 400) orelse return;
    defer wnd2.deinit();
    wnd2.setTitle("window 2");

    wm.appRun();
}
