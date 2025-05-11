// build/options.zig
const std = @import("std");

/// Common cross-target flag
pub inline fn target(b: *std.Build) std.Build.ResolvedTarget {
    return b.standardTargetOptions(.{});
}

/// Common optimization flag
pub inline fn optimize(b: *std.Build) std.builtin.OptimizeMode {
    return b.standardOptimizeOption(.{});
}
