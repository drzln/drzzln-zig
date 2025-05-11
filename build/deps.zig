const std = @import("std");

/// yaml package (declared in build.zig.zon)
pub fn yaml(b: *std.Build) *std.Build.Module {
    return b.dependency("yaml", .{}).module("yaml");
}

/// src/config/root.zig as a named module
pub fn configModule(b: *std.Build, yaml_pkg: *std.Build.Module) *std.Build.Module {
    return b.createModule(.{
        .root_source_file = b.path("src/config/root.zig"),
        .dependencies = &.{yaml_pkg},
    });
}
