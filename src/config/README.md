# Whiterun Config Library

_Immutable in‑memory · Lazy singleton · YAML reverse‑merge · Strictly typed_

This library exposes a single **public** call:

```zig
const cfg = @import("config").config();   // *const AppConfig
```

The first call parses YAML from four locations (lowest → highest priority):

1. `./whiterun.yml`
2. `$HOME/.whiterun.yml`
3. `$HOME/.config/whiterun/config.yml`
4. `/etc/whiterun/config.yml`

Files are **reverse‑merged** so that higher‑priority values overwrite but never delete lower ones. The merged document is converted into a strongly‑typed **`AppConfig`** instance and memoised; subsequent calls return a pointer to the immutable singleton with _zero_ runtime allocation.

---

## Default `AppConfig` schema

```zig
pub const AppConfig = struct {
    name: []const u8 = "whiterun",
};
```

_YAML example:_

```yaml
name: My Awesome Service
```

---

## Extending `AppConfig`

You’ll typically outgrow a single `name` field. Follow these steps to add your own strongly‑typed keys — including nested structs, enums, and lists.

### 1. Add fields with sensible defaults

```zig
pub const Database = struct {
    host: []const u8 = "localhost",
    port: u16       = 5432,
};

pub const Features = struct {
    dark_mode: bool = false,
};

pub const AppConfig = struct {
    name: []const u8 = "whiterun",
    database: Database = .{},   // ← default initialiser uses defaults above
    features: Features = .{},
    allowed_ips: []const []const u8 = &.{}, // list example
    // … add more
};
```

### 2. Update `fromYaml`

In `src/config/root.zig` locate `AppConfig.fromYaml` and extend the switch table:

```zig
pub fn fromYaml(doc: *const yaml.Document, arena: std.mem.Allocator) !AppConfig {
    var cfg: AppConfig = .{};

    inline for (.{ // array literal lets us iterate compile‑time tuples
        .{ "name",     &cfg.name,     NodeType.ScalarString },
        .{ "database", &cfg.database, NodeType.NestedStruct  },
        .{ "features", &cfg.features, NodeType.NestedStruct  },
        .{ "allowed_ips", &cfg.allowed_ips, NodeType.StringList },
    }) |field| {
        try parseField(doc, arena, field);
    }
    return cfg;
}
```

_(The helper `parseField` already handles scalars, nested structs via recursion, and lists. If you generated this file from the template you’ll find it under the Helpers section — extend its `switch` to recognise any new enum or custom parsing you need.)_

### 3. Write the YAML

```yaml
name: Production Whiterun

database:
  host: db.internal
  port: 5432

features:
  dark_mode: true

allowed_ips:
  - 10.0.0.0/8
  - 192.168.0.0/16
```

### 4. Use it in code

```zig
const cfg = config();

std.debug.print("DB → {s}:{d}\n", .{ cfg.database.host, cfg.database.port });

if (cfg.features.dark_mode) {
    // …
}
```

All look‑ups are **compile‑time checked**; if you typo a field name the compiler tells you.

---

## Tips

- **Nested structs = nested YAML tables** — easy mapping.
- **Enums**: declare a Zig `enum` and parse with `node.scalarEnum(Enum)`. Provide a default variant in `AppConfig` so missing keys don’t fail.
- **Lists**: use `[]T` or `[]const T`. For strings call `node.scalarStringSlice(arena)` inside a loop over the YAML sequence.
- **Validation**: after building `cfg`, add runtime checks (e.g. port range) and return `error.InvalidValue` to abort compilation/run.
- **Hot reload**: expose `reload()` that repeats `loadConfig()` and swaps `g_cfg` atomically.

With these patterns you can scale the schema from a single string to a deeply‑nested, strictly‑typed configuration without giving up ergonomics. 🎉
