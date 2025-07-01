const std = @import("std");
const qjs = @import("zkeke").quickjs;

pub fn main() !void {
    const app = qjs.Quickjs.init();
    defer app.deinit();
    _ = app.eval_js_code("console.log('hello world');", false);
    _ = app.loop();
}
