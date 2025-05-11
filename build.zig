const std = @import("std");
const opts = @import("build/options.zig");
const deps = @import("build/deps.zig");
const art = @import("build/artifacts.zig");
const t = @import("build/tests.zig");

pub fn build(b: *std.Build) void {
    const target = opts.target(b);
    const optimize = opts.optimize(b);

    const yaml_pkg = deps.yaml(b);
    const cfg_mod = deps.configModule(b, yaml_pkg);

    art.makeLibrary(b, target, optimize, cfg_mod, yaml_pkg);
    const exe = art.makeExecutable(b, target, optimize, cfg_mod, yaml_pkg);
    art.makeRunStep(b, exe);

    t.addAllTests(b, target, optimize, cfg_mod, yaml_pkg);
}
