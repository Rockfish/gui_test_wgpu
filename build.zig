const std = @import("std");

const content_dir = "gui_test_content/";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zglfw = b.dependency("zglfw", .{
        .target = target,
        .optimize = optimize,
    });

    const zstbi = b.dependency("zstbi", .{
        .target = target,
        .optimize = optimize,
    });

    //
    // Build Imgui with OpenGL backend
    //

    const zopengl = b.dependency("zopengl", .{
        .target = target,
        .optimize = optimize,
    });

    const zgui_opengl = b.dependency("zgui", .{
        .target = target,
        .optimize = optimize,
        .backend = .glfw_opengl3,
        .with_te = true,
        .shared = false,
    });

    const exe = b.addExecutable(.{
        .name = "gui_test_opengl",
        .root_source_file = b.path("src/gui_test_opengl3.zig"),
        .target = target,
        .optimize = optimize,
    });

    @import("system_sdk").addLibraryPathsTo(exe);

    exe.root_module.addImport("zopengl", zopengl.module("root"));
    exe.root_module.addImport("zgui", zgui_opengl.module("root"));
    exe.root_module.addImport("zglfw", zglfw.module("root"));
    exe.root_module.addImport("zstbi", zstbi.module("root"));

    exe.linkLibrary(zgui_opengl.artifact("imgui"));
    exe.linkLibrary(zglfw.artifact("glfw"));
    exe.linkLibrary(zstbi.artifact("zstbi"));

    const exe_options = b.addOptions();
    exe.root_module.addOptions("build_options", exe_options);
    exe_options.addOption([]const u8, "content_dir", content_dir);

    const install_content_step = b.addInstallDirectory(.{
        .source_dir = b.path(content_dir),
        .install_dir = .{ .custom = "" },
        .install_subdir = "bin/" ++ content_dir,
    });

    exe.step.dependOn(&install_content_step.step);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run_opengl", "Run the app");
    run_step.dependOn(&run_cmd.step);

    //
    // Build Imgui with the WGPU backend
    //

    const zgpu = b.dependency("zgpu", .{
        .target = target,
        .optimize = optimize,
    });

    const zgui_wgpu = b.dependency("zgui", .{
        .target = target,
        .optimize = optimize,
        .backend = .glfw_wgpu,
        .with_te = true,
        .shared = false,
    });

    const exe_wgpu = b.addExecutable(.{
        .name = "gui_test_wgpu",
        .root_source_file = b.path("src/gui_test_wgpu.zig"),
        .target = target,
        .optimize = optimize,
    });

    @import("system_sdk").addLibraryPathsTo(exe_wgpu);
    @import("zgpu").addLibraryPathsTo(exe_wgpu);

    exe_wgpu.root_module.addImport("zgpu", zgpu.module("root"));
    exe_wgpu.root_module.addImport("zgui", zgui_wgpu.module("root"));
    exe_wgpu.root_module.addImport("zglfw", zglfw.module("root"));
    exe_wgpu.root_module.addImport("zstbi", zstbi.module("root"));

    exe_wgpu.linkLibrary(zgpu.artifact("dawn"));
    exe_wgpu.linkLibrary(zgui_wgpu.artifact("imgui"));
    exe_wgpu.linkLibrary(zglfw.artifact("glfw"));
    exe_wgpu.linkLibrary(zstbi.artifact("zstbi"));

    const exe_wgpu_options = b.addOptions();
    exe_wgpu.root_module.addOptions("build_options", exe_wgpu_options);
    exe_wgpu_options.addOption([]const u8, "content_dir", content_dir);

    b.installArtifact(exe_wgpu);

    const run_cmd_wgpu = b.addRunArtifact(exe_wgpu);
    run_cmd_wgpu.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd_wgpu.addArgs(args);
    }

    const run_step_wgpu = b.step("run_wgpu", "Run the app");
    run_step_wgpu.dependOn(&run_cmd_wgpu.step);
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
