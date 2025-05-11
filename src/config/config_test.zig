// src/config/config_test.zig
const std  = @import("std");    
const yaml = @import("yaml");
const cfgm = @import("config");

const expect     = std.testing.expect;
const expectStr  = std.testing.expectEqualStrings;

fn parseYaml(arena: std.mem.Allocator, text: []const u8) !yaml.Document {
    var doc = yaml.Document.init(arena);
    try doc.parse(text);
    return doc;
}

test "AppConfig defaults when YAML is empty" {
    var arena_alloc = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_alloc.deinit();
    const arena = arena_alloc.allocator;
    const doc  = try parseYaml(arena, "");
    const conf = try cfgm.AppConfig.fromYaml(&doc, arena);
    try expectStr("drzzln", conf.name);
}

test "AppConfig parses 'name' override" {
    var arena_alloc = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_alloc.deinit();
    const arena = arena_alloc.allocator;

    const yaml_text =
        \\name: My Awesome Service
    ;
    const doc  = try parseYaml(arena, yaml_text);
    const conf = try cfgm.AppConfig.fromYaml(&doc, arena);

    try expectStr("My Awesome Service", conf.name);
}

test "AppConfig invalid type raises error" {
    var arena_alloc = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_alloc.deinit();
    const arena = arena_alloc.allocator;

    const yaml_text =
        \\name:
        \\  nested: true
    ;
    const doc = try parseYaml(arena, yaml_text);

    try std.testing.expectError(error.InvalidType,
        cfgm.AppConfig.fromYaml(&doc, arena));
}

test "config() memoises singleton" {
    const first  = cfgm.config();
    const second = cfgm.config();
    try expect(first == second);
}

