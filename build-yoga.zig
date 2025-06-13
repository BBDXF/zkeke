const std = @import("std");

const yoga_cpps = [_][]const u8{
    "yoga/algorithm/Baseline.cpp",
    "yoga/algorithm/AbsoluteLayout.cpp",
    "yoga/algorithm/PixelGrid.cpp",
    "yoga/algorithm/CalculateLayout.cpp",
    "yoga/algorithm/Cache.cpp",
    "yoga/algorithm/FlexLine.cpp",
    "yoga/YGNodeLayout.cpp",
    "yoga/debug/AssertFatal.cpp",
    "yoga/debug/Log.cpp",
    "yoga/YGNodeStyle.cpp",
    "yoga/config/Config.cpp",
    "yoga/YGValue.cpp",
    "yoga/YGNode.cpp",
    "yoga/event/event.cpp",
    "yoga/YGConfig.cpp",
    "yoga/YGEnums.cpp",
    "yoga/node/Node.cpp",
    "yoga/node/LayoutResults.cpp",
    "yoga/YGPixelGrid.cpp",
};

pub fn BuildLibrary(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const yoga_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });
    yoga_mod.link_libcpp = true;
    yoga_mod.addIncludePath(b.path("third-parts/yoga/"));
    yoga_mod.addCSourceFiles(.{
        .root = b.path("third-parts/yoga"),
        .files = &yoga_cpps,
        .flags = &.{
            "-std=c++20",
        },
    });
    const yoga_lib = b.addLibrary(.{
        .name = "zyoga",
        .root_module = yoga_mod,
    });
    return yoga_lib;
}
