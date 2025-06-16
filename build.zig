const std = @import("std");
const build_cpp = @import("build-cpp.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // yoga
    const yoga_lib = build_cpp.BuildYogaLibrary(b, target, optimize);
    // quickjs
    const qjs_lib = build_cpp.BuildQuickjsLibrary(b, target, optimize, true);

    const demo_basic_mod = b.createModule(.{
        .root_source_file = b.path("src/test_basic.zig"),
        .target = target,
        .optimize = optimize,
    });
    demo_basic_mod.linkLibrary(yoga_lib);
    demo_basic_mod.linkLibrary(qjs_lib);
    demo_basic_mod.addIncludePath(b.path("third-parts/yoga/"));
    demo_basic_mod.addIncludePath(b.path("third-parts/quickjs/"));

    // cairo
    if (target.result.os.tag == .windows) {
        // downlaod pre-compiled cairo from https://github.com/BBDXF/cairo-win32/releases
        demo_basic_mod.addIncludePath(b.path("third-parts/cairo/include"));
        demo_basic_mod.addLibraryPath(b.path("third-parts/cairo/lib"));
        demo_basic_mod.linkSystemLibrary("cairo-2", .{
            .needed = true,
            .use_pkg_config = .no,
        });
    } else {
        // linux need install cairo: sudo apt install libcairo2-dev
        demo_basic_mod.linkSystemLibrary("cairo", .{
            .needed = true,
            .use_pkg_config = .force,
        });
    }

    const demo_basic = b.addExecutable(.{
        .name = "demo_basic",
        .root_module = demo_basic_mod,
    });
    b.installArtifact(demo_basic);

    const demo_basic_run = b.addRunArtifact(demo_basic);
    const demo_basic_step = b.step("demo_basic", "Run the demo_basic example");
    demo_basic_step.dependOn(&demo_basic_run.step);
}
