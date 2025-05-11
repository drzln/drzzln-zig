// build/tests.zig
const std = @import("std");
const art = @import("artifacts.zig"); // for wire()

fn addTest(
    b: *std.Build,
    src: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    cfg: *std.Build.Module,
    yaml: *std.Build.Module,
) *std.Build.Step.Run {
    const t = b.addTest(.{
        .root_source_file = b.path(src),
        .target = target,
        .optimize = optimize,
    });
    art.wire(t, cfg, yaml);
    return b.addRunArtifact(t);
}

/// … (rest of the file unchanged)
/// Register root, main, and config tests under one `zig build test` step
pub fn addAllTests(
    b: *std.Build,
    target: std.zig.CrossTarget,
    optimize: std.builtin.OptimizeMode,
    cfg: *std.Build.Module,
    y: *std.Build.Module,
) void {
    const step = b.step("test", "Run unit tests");
    for ([_][]const u8{
        "src/root.zig",
        "src/main.zig",
        "src/config/config_test.zig",
    }) |path| {
        step.dependOn(&addTest(b, path, target, optimize, cfg, y).step);
    }
}
