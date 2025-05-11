// build/options.zig
const std = @import("std");

/// Standard cross-target option
pub inline fn target(b: *std.Build) std.zig.CrossTarget {
    return b.standardTargetOptions(.{});
}

/// Standard optimize option
pub inline fn optimize(b: *std.Build) std.builtin.OptimizeMode {
    return b.standardOptimizeOption(.{});
}
