// src/config/root.zig
const std  = @import("std");
const yaml = @import("yaml");

/// Compile-time constant used for search paths
pub const app_name = "drzzln";

// ─────────────────────────────────────────────────────────────
// Strictly-typed DTO
// ─────────────────────────────────────────────────────────────

/// YAML schema ⇒ Zig struct.
/// Every field has a default so missing keys don’t crash the loader.
pub const AppConfig = struct {
    /// Human-readable application name (`name:` in YAML)
    name: []const u8 = "drzzln",

    /// Parse a merged YAML document into an `AppConfig`.
    /// Unknown keys are ignored; wrong types raise an error.
    pub fn fromYaml(doc: *const yaml.Document, arena: std.mem.Allocator) !AppConfig {
        var cfg: AppConfig = .{}; // start with defaults

        if (doc.lookup("name")) |node| switch (node.tag) {
            .scalar => cfg.name = try node.scalarString(arena),
            else     => return error.InvalidType,
        };

        return cfg;
    }
};

// ─────────────────────────────────────────────────────────────
// Public API – immutable singleton
// ─────────────────────────────────────────────────────────────

var g_cfg: ?AppConfig = null;

/// Access the lazily-loaded, in-memory config.
pub fn config() *const AppConfig {
    if (g_cfg == null) {
        g_cfg = loadConfig() catch |err| {
            std.debug.panic("config load failure: {}", .{err});
        };
    }
    return &g_cfg.?;
}

// ─────────────────────────────────────────────────────────────
// Loader: reverse-merge YAML → AppConfig
// ─────────────────────────────────────────────────────────────

fn loadConfig() !AppConfig {
    const arena_alloc = std.heap.ArenaAllocator.init(std.heap.c_allocator);
    const arena       = &arena_alloc.allocator;
    defer arena_alloc.deinit();

    var merged = yaml.Document.init(arena);

    var paths = buildPathList();
    while (paths.pop()) |p| {
        if (try fileExists(p)) {
            const bytes = try std.fs.cwd().readFileAlloc(arena, p, 1 << 20);
            var doc = yaml.Document.init(arena);
            try doc.parse(bytes);
            try merged.merge(&doc); // reverse merge (higher priority overwrites)
        }
    }

    return AppConfig.fromYaml(&merged, arena);
}

// ─────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────

/// Build precedence list (lowest priority first so we can pop()).
fn buildPathList() std.ArrayListUnmanaged([]const u8) {
    var list: std.ArrayListUnmanaged([]const u8) = .{};

    const cwd = std.fs.cwd();
    list.appendAssumeCapacity(
        (cwd.realpathAlloc(std.heap.page_allocator, ".") catch ".") ++
        "/" ++ app_name ++ ".yml",
    );

    if (std.os.getenv("HOME")) |home| {
        list.appendAssumeCapacity(home ++ "/." ++ app_name ++ ".yml");
        list.appendAssumeCapacity(home ++ "/.config/" ++ app_name ++ "/config.yml");
    }

    list.appendAssumeCapacity("/etc/" ++ app_name ++ "/config.yml");
    return list;
}

/// Return `true` if file exists, else `false`.
fn fileExists(path: []const u8) !bool {
    return std.fs.cwd().access(path, .{}) catch |err| switch (err) {
        error.FileNotFound => false,
        else               => |e| return e,
    };
}

