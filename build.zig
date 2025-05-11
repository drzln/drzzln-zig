const std = @import("std");

pub fn build(b: *std.Build) void {
    // -------------------------------------------------------------
    // Common build options
    // -------------------------------------------------------------
    const target   = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // -------------------------------------------------------------
    // External yaml package (declared in build.zig.zon dependencies)
    // -------------------------------------------------------------
    const yaml_pkg = b.dependency("yaml", .{}).module("yaml");

    // -------------------------------------------------------------
    // config module (src/config/root.zig)
    // -------------------------------------------------------------
    const cfg_mod = b.createModule(.{
        .source_file = b.path("src/config/root.zig"),
        .dependencies = &.{ yaml_pkg },
    });

    // -------------------------------------------------------------
    // Static library
    // -------------------------------------------------------------
    const lib = b.addStaticLibrary(.{
        .name             = "drzzln-zig",
        .root_source_file = b.path("src/root.zig"),
        .target           = target,
        .optimize         = optimize,
    });
    lib.addModule("config", cfg_mod);
    lib.addModule("yaml",   yaml_pkg);
    b.installArtifact(lib);

    // -------------------------------------------------------------
    // Executable
    // -------------------------------------------------------------
    const exe = b.addExecutable(.{
        .name             = "drzzln-zig",
        .root_source_file = b.path("src/main.zig"),
        .target           = target,
        .optimize         = optimize,
    });
    exe.addModule("config", cfg_mod);
    exe.addModule("yaml",   yaml_pkg);
    b.installArtifact(exe);

    // Run step (`zig build run -- arg1 arg2`)
    const run_cmd  = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| run_cmd.addArgs(args);
    b.step("run", "Run the app").dependOn(&run_cmd.step);

    // -------------------------------------------------------------
    // Unit-test targets
    // -------------------------------------------------------------
    const root_tests = b.addTest(.{
        .root_source_file = b.path("src/root.zig"),
        .target           = target,
        .optimize         = optimize,
    });
    root_tests.addModule("config", cfg_mod);
    root_tests.addModule("yaml",   yaml_pkg);

    const main_tests = b.addTest(.{
        .root_source_file = b.path("src/main.zig"),
        .target           = target,
        .optimize         = optimize,
    });
    main_tests.addModule("config", cfg_mod);
    main_tests.addModule("yaml",   yaml_pkg);

    const cfg_tests = b.addTest(.{
        .root_source_file = b.path("src/config/config_test.zig"),
        .target           = target,
        .optimize         = optimize,
    });
    cfg_tests.addModule("config", cfg_mod);
    cfg_tests.addModule("yaml",   yaml_pkg);

    // run all three test binaries
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&b.addRunArtifact(root_tests).step);
    test_step.dependOn(&b.addRunArtifact(main_tests).step);
    test_step.dependOn(&b.addRunArtifact(cfg_tests).step);
}

