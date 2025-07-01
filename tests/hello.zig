const std = @import("std");
const qjs = @import("zkeke").quickjs;

pub fn main() !void {
    const app = qjs.Quickjs.init();
    defer app.deinit();
    _ = app.eval_js_code("console.log('hello world');", false);
    _ = app.loop();

    const a1: u32 = 0xA234B678;
    const a2: u16 = a1 >> 16;
    const a3: i32 = @as(i16, @bitCast(@as(u16, @intCast(0xFFFF & (a1 >> 16)))));
    std.debug.print("{x} {d}\n", .{ a2, a3 });
}
