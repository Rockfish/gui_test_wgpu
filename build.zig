const std = @import("std");

const demo_name = "gui_test_wgpu";
const content_dir = demo_name ++ "_content/";

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "gui_test_wgpu",
        .root_source_file = b.path("src/gui_test_wgpu.zig"),
        .target = target,
        .optimize = optimize,
    });

    const zgpu = b.dependency("zgpu", .{
        .target = target,
        .optimize = optimize,
    });

    const zgui = b.dependency("zgui", .{
        .target = target,
        .optimize = optimize,
        .backend = .glfw_wgpu,
        .with_te = true,
        .shared = false,
    });

    const zglfw = b.dependency("zglfw", .{
        .target = target,
        .optimize = optimize,
    });

    const zstbi = b.dependency("zstbi", .{
        .target = target,
        .optimize = optimize,
    });

    @import("system_sdk").addLibraryPathsTo(exe);

    @import("zgpu").addLibraryPathsTo(exe);

    exe.root_module.addImport("zgpu", zgpu.module("root"));
    exe.root_module.addImport("zgui", zgui.module("root"));
    exe.root_module.addImport("zglfw", zglfw.module("root"));
    exe.root_module.addImport("zstbi", zstbi.module("root"));

    exe.linkLibrary(zgpu.artifact("dawn"));
    exe.linkLibrary(zgui.artifact("imgui"));
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

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

inline fn thisDir() []const u8 {
    return comptime std.fs.path.dirname(@src().file) orelse ".";
}
