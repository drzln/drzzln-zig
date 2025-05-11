const std = @import("std");

pub fn yaml(b: *std.Build) *std.Build.Module {
    return b.dependency("yaml", .{}).module("yaml");
}

pub fn configModule(
    b: *std.Build,
    yaml_pkg: *std.Build.Module,
) *std.Build.Module {
    return b.createModule(.{
        .root_source_file = b.path("src/config/root.zig"),
        .imports = &.{
            .{ .name = "yaml", .module = yaml_pkg },
        },
    });
}
