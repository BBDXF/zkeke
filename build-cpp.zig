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

pub fn BuildYogaLibrary(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode) *std.Build.Step.Compile {
    const cpp_dir = "third-parts/yoga/";
    const src_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });
    src_mod.link_libcpp = true;
    src_mod.addIncludePath(b.path(cpp_dir));
    src_mod.addCSourceFiles(.{
        .root = b.path(cpp_dir),
        .files = &yoga_cpps,
        .flags = &.{
            "-std=c++20",
        },
    });
    const src_lib = b.addLibrary(.{
        .name = "zyoga",
        .root_module = src_mod,
    });
    return src_lib;
}

const qjs_cpps = [_][]const u8{
    "cutils.c",
    "libregexp.c",
    "libunicode.c",
    "quickjs.c",
    "xsum.c",
    "quickjs-libc.c",
};

pub fn BuildQuickjsLibrary(b: *std.Build, target: std.Build.ResolvedTarget, optimize: std.builtin.OptimizeMode, need_qjsc: bool) *std.Build.Step.Compile {
    const cpp_dir = "third-parts/quickjs/";
    var cflags = std.ArrayList([]const u8).init(b.allocator);
    defer cflags.deinit();
    if (target.result.abi == .msvc) {
        cflags.appendSlice(&.{
            "/std:c11",
            "/D_GNU_SOURCE",
            "/DWIN32_LEAN_AND_MEAN",
            "/D_CRT_SECURE_NO_WARNINGS",
            "/D_WIN32_WINNT=0x0602",
            // "/STACK:8388608",
        }) catch unreachable;
    } else {
        cflags.appendSlice(&.{
            "-std=c11",
            "-D_GNU_SOURCE",
            // "-Wl,--stack,8388608",
        }) catch unreachable;
    }

    const src_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
    });
    src_mod.link_libc = true;
    src_mod.addIncludePath(b.path(cpp_dir));
    src_mod.addCSourceFiles(.{
        .root = b.path(cpp_dir),
        .files = &qjs_cpps,
        .flags = cflags.items,
    });
    if (target.result.os.tag == .linux) {
        src_mod.linkSystemLibrary("pthread", .{ .needed = true });
    }
    const src_lib = b.addLibrary(.{
        .name = "zquickjs",
        .root_module = src_mod,
    });

    // qjsc and qjs
    if (need_qjsc) {
        // qjsc
        const qjsc_mod = b.createModule(.{
            .target = target,
            .optimize = optimize,
        });
        qjsc_mod.link_libc = true;
        qjsc_mod.addIncludePath(b.path(cpp_dir));
        qjsc_mod.addCSourceFiles(.{
            .root = b.path(cpp_dir),
            .files = &.{
                "qjsc.c",
            },
            .flags = cflags.items,
        });
        qjsc_mod.linkLibrary(src_lib);
        const qjsc_exe = b.addExecutable(.{
            .name = "qjsc",
            .root_module = qjsc_mod,
        });
        b.installArtifact(qjsc_exe);

        // qjs
        const qjs_mod = b.createModule(.{
            .target = target,
            .optimize = optimize,
        });
        qjs_mod.link_libc = true;
        qjs_mod.addIncludePath(b.path(cpp_dir));
        qjs_mod.addCSourceFiles(.{
            .root = b.path(cpp_dir),
            .files = &.{
                "qjs.c",
                "gen/repl.c",
                "gen/standalone.c",
            },
            .flags = cflags.items,
        });
        qjs_mod.linkLibrary(src_lib);
        const qjs_exe = b.addExecutable(.{
            .name = "qjs",
            .root_module = qjs_mod,
        });
        b.installArtifact(qjs_exe);
    }

    return src_lib;
}
