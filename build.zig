const std = @import("std");
const build_yoga = @import("build-yoga.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const yoga_lib = build_yoga.BuildLibrary(b, target, optimize);

    const demo_basic_mod = b.createModule(.{
        .root_source_file = b.path("src/test_basic.zig"),
        .target = target,
        .optimize = optimize,
    });
    demo_basic_mod.linkLibrary(yoga_lib);
    demo_basic_mod.addIncludePath(b.path("third-parts/yoga/"));

    const demo_basic = b.addExecutable(.{
        .name = "demo_basic",
        .root_module = demo_basic_mod,
    });
    b.installArtifact(demo_basic);

    const demo_basic_run = b.addRunArtifact(demo_basic);
    const demo_basic_step = b.step("demo_basic", "Run the demo_basic example");
    demo_basic_step.dependOn(&demo_basic_run.step);
}
