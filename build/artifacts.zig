// build/artifacts.zig
const std = @import("std");

pub fn wire(
    mod: *std.Build.Step.Compile,
    cfg: *std.Build.Module,
    yaml: *std.Build.Module,
) void {
    mod.addModule("config", cfg);
    mod.addModule("yaml", yaml);
}

pub fn makeLibrary(
    b: *std.Build,
    target: std.zig.CrossTarget,
    optimize: std.builtin.OptimizeMode,
    cfg: *std.Build.Module,
    y: *std.Build.Module,
) void {
    const lib = b.addStaticLibrary(.{
        .name = "drzzln-zig",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    wire(lib, cfg, y);
    b.installArtifact(lib);
}

pub fn makeExecutable(
    b: *std.Build,
    target: std.zig.CrossTarget,
    optimize: std.builtin.OptimizeMode,
    cfg: *std.Build.Module,
    y: *std.Build.Module,
) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = "drzzln-zig",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    wire(exe, cfg, y);
    b.installArtifact(exe);
    return exe;
}

pub fn makeRunStep(b: *std.Build, exe: *std.Build.Step.Compile) void {
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
    b.step("run", "Run the app").dependOn(&run_cmd.step);
}
