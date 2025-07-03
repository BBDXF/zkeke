const std = @import("std");
const build_cpp = @import("build-cpp.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // c/cpp library
    const yoga_lib = build_cpp.BuildYogaLibrary(b, target, optimize);
    const qjs_lib = build_cpp.BuildQuickjsLibrary(b, target, optimize, true);

    // output module
    const zkk_lib_mod = b.createModule(.{
        .root_source_file = b.path("src/zkeke.zig"),
        .target = target,
        .optimize = optimize,
    });

    // internal use modules
    // comm
    const zkk_comm_mod = b.createModule(.{
        .root_source_file = b.path("src/comm/comm.zig"),
        .target = target,
        .optimize = optimize,
    });
    zkk_lib_mod.addImport("comm", zkk_comm_mod);
    // yoga
    const zkk_yoga_mod = b.createModule(.{
        .root_source_file = b.path("src/yoga.zig"),
        .target = target,
        .optimize = optimize,
    });
    zkk_yoga_mod.linkLibrary(yoga_lib);
    zkk_yoga_mod.addIncludePath(b.path("third-parts/yoga/"));
    zkk_yoga_mod.addImport("comm", zkk_comm_mod);
    zkk_lib_mod.addImport("yoga", zkk_yoga_mod);
    // quickjs
    const zkk_quickjs_mod = b.createModule(.{
        .root_source_file = b.path("src/quickjs.zig"),
        .target = target,
        .optimize = optimize,
    });
    zkk_quickjs_mod.linkLibrary(qjs_lib);
    zkk_quickjs_mod.addIncludePath(b.path("third-parts/quickjs/"));
    zkk_lib_mod.addImport("quickjs", zkk_quickjs_mod);
    // window
    const zkk_window_mod = b.createModule(.{
        // .root_source_file = b.path("src/window.zig"),
        .target = target,
        .optimize = optimize,
    });
    if (target.result.os.tag == .windows) {
        zkk_window_mod.root_source_file = b.path("src/window/win32.zig");
        zkk_window_mod.addIncludePath(b.path("third-parts/cairo/include"));
    } else {
        zkk_window_mod.root_source_file = b.path("src/window/linux.zig");
    }
    zkk_window_mod.addImport("comm", zkk_comm_mod);
    zkk_lib_mod.addImport("window", zkk_window_mod);
    // cairo
    const zkk_cairo_mod = b.createModule(.{
        .root_source_file = b.path("src/cairo.zig"),
        .target = target,
        .optimize = optimize,
    });
    if (target.result.os.tag == .windows) {
        // downlaod pre-compiled cairo from https://github.com/BBDXF/cairo-win32/releases
        zkk_cairo_mod.addIncludePath(b.path("third-parts/cairo/include"));
        zkk_cairo_mod.addLibraryPath(b.path("third-parts/cairo/lib"));
        zkk_cairo_mod.linkSystemLibrary("cairo", .{
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
        zkk_cairo_mod.linkSystemLibrary("cairo", .{
            .needed = true,
            .use_pkg_config = .force,
        });
        // sudo apt install libX11-dev
        zkk_cairo_mod.linkSystemLibrary("X11", .{
            .needed = true,
            .use_pkg_config = .yes,
        });
    }
    zkk_lib_mod.addImport("cairo", zkk_cairo_mod);
    // ui
    const zkk_ui_mod = b.createModule(.{
        .root_source_file = b.path("src/ui/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    zkk_ui_mod.addImport("comm", zkk_comm_mod);
    zkk_ui_mod.addImport("cairo", zkk_cairo_mod);
    zkk_ui_mod.addImport("window", zkk_window_mod);
    zkk_lib_mod.addImport("ui", zkk_ui_mod);

    // output zkk_lib
    const zkk_lib_output = b.addSharedLibrary(.{
        .name = "zkeke",
        .root_module = zkk_lib_mod,
    });
    b.installArtifact(zkk_lib_output);

    // ---------------------------------------
    // tests 1
    const tests_hello_mod = b.createModule(.{
        .root_source_file = b.path("tests/hello.zig"),
        .target = target,
        .optimize = optimize,
    });
    tests_hello_mod.addImport("zkeke", zkk_lib_mod);
    const tests_hello_exe = b.addExecutable(.{
        .name = "tests_hello",
        .root_module = tests_hello_mod,
    });
    b.installArtifact(tests_hello_exe);
    // tests 2
    const tests_basic_mod = b.createModule(.{
        .root_source_file = b.path("tests/basic.zig"),
        .target = target,
        .optimize = optimize,
    });
    tests_basic_mod.addImport("zkeke", zkk_lib_mod);
    const tests_basic_exe = b.addExecutable(.{
        .name = "tests_basic",
        .root_module = tests_basic_mod,
    });
    b.installArtifact(tests_basic_exe);
}
