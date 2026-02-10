> [中文版](../../guides/getting-started.md)

# Installation & Quick Start

## Installation

### Option 1: Install from Release

1. Download the latest version from [Releases](https://github.com/baitouwuya/better-godot-csv/releases)
2. Copy the `addons/GodotSV/` folder into your project directory
3. Enable in Godot: **Project > Project Settings > Plugins > GodotSV**

### Option 2: Build from Source

```bash
git clone --recurse-submodules https://github.com/baitouwuya/better-godot-csv.git
cd better-godot-csv
scons                           # debug build
scons target=template_release   # release build
```

Build artifacts are automatically output to `GodotSV/addons/GodotSV/bin/` under the corresponding platform directory.

## Minimal Example

Create a `.gdsv` file (Tab-delimited):

```
*id:int	name:string	health:float=100
1	Alice	85.5
2	Bob	72.3
```

Load it in GDScript:

```gdscript
func _ready() -> void:
    var resource := GDSVLoader.new() \
        .load_file("res://data/characters.gdsv") \
        .with_header(true) \
        .parse_all()

    if resource.has_errors():
        push_error(str(resource.get_errors()))
        return

    # Iterate all rows
    for i in resource.get_row_count():
        var name: String = resource.get_string(i, "name")
        var hp: float = resource.get_float(i, "health")
        print("%s: %.1f HP" % [name, hp])

    # Find by field
    var alice: Dictionary = resource.find_row("name", "Alice")
    print("Alice's HP: ", alice.get("health", "N/A"))
```

## Supported File Formats

| Extension | Default Delimiter | Description |
|-----------|-------------------|-------------|
| `.gdsv` | Tab (`\t`) | GodotSV native format |
| `.tsv` / `.tab` | Tab (`\t`) | Standard Tab-separated |
| `.csv` | Comma (`,`) | Standard CSV |
| `.psv` | Pipe (`\|`) | Pipe-separated |
| `.asc` | Tab (`\t`) | ASCII data file |

The delimiter is automatically inferred from the file extension, but can also be explicitly specified via `.with_delimiter()`.

## Streaming Large Files

For large files, use `stream()` instead of `parse_all()` to read row by row:

```gdscript
var reader := GDSVLoader.new() \
    .load_file("res://data/huge_table.gdsv") \
    .with_header(true) \
    .stream()

while reader.has_next():
    var row: Dictionary = reader.next()
    process_row(row)

reader.close()
```

## Next Steps

- [GDSV Format & Type Annotations](./gdsv-format.md) -- Learn about type annotation syntax
- [Editor Integration](./editor-integration.md) -- Edit data directly in the Godot editor
- [API Overview](../api/index.md) -- View the complete API reference
