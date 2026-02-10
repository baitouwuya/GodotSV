<p align="center">
  <img src="./GodotSV.png" width="128" alt="GodotSV">
</p>

# GodotSV

High-performance structured data plugin for Godot 4.5+.

Parse, validate, and edit GDSV / CSV / TSV files with a C++ core and a GDScript chain-style API.

> **[English Documentation](./docs/en/index.md)** | **[中文文档](./docs/index.md)**

## Quick Start

```gdscript
var resource := GDSVLoader.new() \
    .load_file("res://data/items.gdsv") \
    .with_header(true) \
    .parse_all()

for i in resource.get_row_count():
    print(resource.get_string(i, "name"))
```

## Features

- **Multi-format** — `.gdsv` / `.csv` / `.tsv` / `.tab` / `.psv` / `.asc`
- **35 built-in types** — int, float, bool, Vector2/3/4, Color, Rect2, Transform, PackedArrays, etc.
- **Extensible** — add custom types in GDScript (`@tool` + `class_name` + `extends GDSVTypeHandler`)
- **Schema validation** — required fields, ranges, enums, patterns
- **Streaming** — row-by-row reading for large files
- **Editor integration** — built-in table editor with undo/redo, search/replace

## GDSV Format

Tab-separated with optional type annotations in headers:

```
# Item database
*id:int	name:string	price:float=0	rare:bool=false
1	Sword	150.0	false
2	Shield	200.0	true
```

- `field:type` — type annotation
- `*field` — required
- `field:type=default` — default value
- `field:enum(a,b,c)` — enum constraint
- `# comment` — ignored lines

## Installation

1. Copy `addons/GodotSV/` into your Godot project
2. Enable: **Project → Project Settings → Plugins → GodotSV**

## Documentation

| Topic | Chinese | English |
|-------|---------|---------|
| Getting Started | [guides/getting-started.md](./docs/guides/getting-started.md) | [en/guides/getting-started.md](./docs/en/guides/getting-started.md) |
| GDSV Format | [guides/gdsv-format.md](./docs/guides/gdsv-format.md) | [en/guides/gdsv-format.md](./docs/en/guides/gdsv-format.md) |
| Custom Types | [guides/custom-type-handler.md](./docs/guides/custom-type-handler.md) | [en/guides/custom-type-handler.md](./docs/en/guides/custom-type-handler.md) |
| Editor Integration | [guides/editor-integration.md](./docs/guides/editor-integration.md) | [en/guides/editor-integration.md](./docs/en/guides/editor-integration.md) |
| API Reference | [api/index.md](./docs/api/index.md) | [en/api/index.md](./docs/en/api/index.md) |
| Troubleshooting | [guides/troubleshooting.md](./docs/guides/troubleshooting.md) | [en/guides/troubleshooting.md](./docs/en/guides/troubleshooting.md) |

## Changelog

### 0.2.0-alpha (2025-01)

**Architecture**: Refactored type system to extensible handler pattern.

- 25 new built-in type handlers (Vector4, Rect2, Quaternion, Transform, PackedArrays, etc.) — total 35
- GDScript custom type handler support (`@tool` + `class_name` + `extends GDSVTypeHandler`)
- Automatic script type scanning via `GDSVTypeHandlerRegistry.scan_script_types()`
- Custom type editor UI support via `GDSVEditorRegistry`
- Type icons in editor column headers
- Standalone GDSV table editor panel
- Thread safety for `GDSVTypeHandlerRegistry`
- macOS / iOS build support, release DLL for export
- Bilingual documentation (Chinese + English)
- Removed `GDSVColumnParser`; unified into `GDSVTypeAnnotationParser`
- 9 bug fixes including 4 critical-level issues

### 0.1.0-alpha (2024-12)

- Initial release
- GDSV/CSV/TSV parsing (RFC 4180 compatible)
- 10 basic type handlers (int, float, bool, String, Vector2/3, Color, Array, etc.)
- GDScript high-level API: `GDSVLoader`, `GDSVResource`, `GDSVSchema`
- Godot editor integration with import plugin
- Streaming reader for large files

## Version

- **Current**: 0.2.0-alpha
- **Author**: Project Aetherflow
- **License**: [Unlicense](../../LICENSE) (public domain)
- **Minimum Godot**: 4.5
