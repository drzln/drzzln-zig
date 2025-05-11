// build/options.zig
const std = @import("std");

pub inline fn target(b: *std.Build) std.Build.ResolvedTarget {
    return b.standardTargetOptions(.{});
}

pub inline fn optimize(b: *std.Build) std.builtin.OptimizeMode {
    return b.standardOptimizeOption(.{});
}
