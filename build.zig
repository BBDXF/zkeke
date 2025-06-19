const std = @import("std");
const build_cpp = @import("build-cpp.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // yoga
    const yoga_lib = build_cpp.BuildYogaLibrary(b, target, optimize);
    // quickjs
    const qjs_lib = build_cpp.BuildQuickjsLibrary(b, target, optimize, true);

    const tests_basic_mod = b.createModule(.{
        .root_source_file = b.path("src/tests_basic.zig"),
        .target = target,
        .optimize = optimize,
    });
    tests_basic_mod.linkLibrary(yoga_lib);
    tests_basic_mod.linkLibrary(qjs_lib);
    tests_basic_mod.addIncludePath(b.path("third-parts/yoga/"));
    tests_basic_mod.addIncludePath(b.path("third-parts/quickjs/"));

    // cairo
    if (target.result.os.tag == .windows) {
        // downlaod pre-compiled cairo from https://github.com/BBDXF/cairo-win32/releases
        tests_basic_mod.addIncludePath(b.path("third-parts/cairo/include"));
        tests_basic_mod.addLibraryPath(b.path("third-parts/cairo/lib"));
        tests_basic_mod.linkSystemLibrary("cairo", .{
            .needed = true,
            .use_pkg_config = .no,
        });
        // copy dll to output
        const dlls = [_][]const u8{
            "cairo-2.dll",
            "pixman-1-0.dll",
            "png16-16.dll",
            "z-1.dll",
            "cairo-script-interpreter-2.dll",
        };
        for (dlls) |dll| {
            const dll_path = std.fmt.allocPrint(b.allocator, "third-parts/cairo/bin/{s}", .{dll}) catch {
                std.log.err("alloc dll_path failed", .{});
                break;
            };
            defer b.allocator.free(dll_path);
            const dll_out = dll;
            b.installBinFile(dll_path, dll_out);
        }
    } else {
        // linux need install cairo: sudo apt install libcairo2-dev
        tests_basic_mod.linkSystemLibrary("cairo", .{
            .needed = true,
            .use_pkg_config = .force,
        });
        // sudo apt install libX11-dev
        tests_basic_mod.linkSystemLibrary("X11", .{
            .needed = true,
            .use_pkg_config = .yes,
        });
    }

    const tests_basic = b.addExecutable(.{
        .name = "tests_basic",
        .root_module = tests_basic_mod,
    });
    b.installArtifact(tests_basic);

    // uncomment to run if you need
    const tests_basic_run = b.addRunArtifact(tests_basic);
    tests_basic_run.setCwd(b.path("zig-out/bin"));
    const tests_basic_step = b.step("tests_basic", "Run the tests_basic example");
    tests_basic_step.dependOn(&tests_basic_run.step);
}
