// build/tests.zig
const std = @import("std");
const art = @import("build/artifacts.zig");

fn addTest(
    b: *std.Build,
    path: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    cfg: *std.Build.Module,
    yaml: *std.Build.Module,
) *std.Build.Step.Run {
    const t = b.addTest(.{
        .root_source_file = b.path(path),
        .target = target,
        .optimize = optimize,
    });
    art.wire(t, cfg, yaml);
    return b.addRunArtifact(t);
}

pub fn addAllTests(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    cfg: *std.Build.Module,
    yaml: *std.Build.Module,
) void {
    const step = b.step("test", "Run unit tests");
    for ([_][]const u8{
        "src/root.zig",
        "src/main.zig",
        "src/config/config_test.zig",
    }) |p| {
        step.dependOn(&addTest(b, p, target, optimize, cfg, yaml).step);
    }
}
