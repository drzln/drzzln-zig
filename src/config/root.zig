// src/config/root.zig
const std = @import("std");
/// External YAML parser package (e.g. https://github.com/kristoff-it/zig-yaml)
const yaml = @import("yaml");

/// Application name used for config search paths.
/// Overwrite at comptime from build.zig if necessary.
pub const app_name: []const u8 = "whiterun";

/// -----------------------------
/// Public API
/// -----------------------------

/// Lazily‑loaded, in‑memory singleton.
/// Call `config()` anywhere to obtain an **immutable** view.
pub fn config() *const Config {
    // Safety: first call wins. No race in single‑threaded init because Zig
    //   runs global constructors sequentially. For multithread, wrap in
    //   `std.atomic.Once`.
    if (g_config == null) {
        g_config = loadConfig() catch |err| {
            std.debug.panic("Failed to load config: {}", .{err});
        };
    }
    return &g_config.?; // non‑null now
}

/// -----------------------------
/// DTO & helpers
/// -----------------------------

/// Dynamic tree of YAML values.  Each lookup allocates **no memory** because
/// it borrows slices from the backing arena.
const Config = struct {
    root: yaml.Document,

    /// Access chain helper: `try config().get("database").get("host")`
    pub fn get(self: *const Config, key: []const u8) !*const yaml.Node {
        return self.root.lookup(key);
    }
};

/// -----------------------------
/// Implementation details
/// -----------------------------

var g_config: ?Config = null; // global singleton

/// Load & reverse‑merge YAML files in precedence order.
fn loadConfig() !Config {
    const gpa = std.heap.c_allocator;
    var arena_allocator = std.heap.ArenaAllocator.init(gpa);
    const arena = &arena_allocator.allocator;

    var doc = yaml.Document.init(arena);

    // iterate candidate paths high → low priority, reversing at merge time
    var paths = buildPathList();
    while (paths.pop()) |p| {
        if (try fileExists(p)) {
            const bytes = try std.fs.cwd().readFileAlloc(arena, p, 1 << 20);
            var sub_doc = yaml.Document.init(arena);
            try sub_doc.parse(bytes);
            try doc.merge(&sub_doc); // reverse merge (fields only fill when missing)
        }
    }

    return Config{ .root = doc };
}

/// Build the precedence list: lowest priority first so we can pop() for reverse.
fn buildPathList() std.ArrayListUnmanaged([]const u8) {
    var list: std.ArrayListUnmanaged([]const u8) = .{};
    const cwd = std.fs.cwd();
    // 1. /etc/<app>/config.yml
    list.appendAssumeCapacity("/etc/" ++ app_name ++ "/config.yml");
    // 2. $HOME/.config/<app>/config.yml
    if (std.os.getenv("HOME")) |home| {
        list.appendAssumeCapacity(home ++ "/.config/" ++ app_name ++ "/config.yml");
        // 3. $HOME/.<app>.yml
        list.appendAssumeCapacity(home ++ "/." ++ app_name ++ ".yml");
    }
    // 4. ./<app>.yml
    list.appendAssumeCapacity((cwd.realpathAlloc(std.heap.page_allocator, ".") catch ".") ++ "/" ++ app_name ++ ".yml");
    return list;
}

/// Small utility: true if file exists and is regular.
fn fileExists(path: []const u8) !bool {
    return std.fs.cwd().access(path, .{}) catch |err| switch (err) {
        error.FileNotFound => false,
        else => |e| return e,
    };
}

