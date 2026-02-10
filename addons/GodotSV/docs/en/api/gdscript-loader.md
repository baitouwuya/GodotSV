> [Chinese Version](../../api/gdscript-loader.md)

# GDSVLoader (GDScript)

A chainable loader that provides a fluent configuration API.

## Methods

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `load_file` | `path: String` | `GDSVLoader` | Load a file |
| `with_header` | `has_header: bool` | `GDSVLoader` | Enable or disable header row |
| `with_delimiter` | `delimiter: String` | `GDSVLoader` | Set the delimiter |
| `with_type` | `field: StringName, type: GDSVFieldDefinition.FieldType` | `GDSVLoader` | Specify a field type |
| `with_default` | `field: StringName, value: Variant` | `GDSVLoader` | Set a default value |
| `with_required_fields` | `fields: Array[StringName]` | `GDSVLoader` | Set required fields |
| `with_schema` | `schema: GDSVSchema` | `GDSVLoader` | Bind a Schema |
| `parse_all` | — | `GDSVResource` | Parse all data at once |
| `stream` | — | `GDSVStreamReaderGD` | Create a streaming reader |
| `get_errors` | — | `Array[String]` | Get the error list |
| `get_warnings` | — | `Array[String]` | Get the warning list |
| `has_errors` | — | `bool` | Whether there are errors |
| `has_warnings` | — | `bool` | Whether there are warnings |
| `clear_cache` | — | `void` | Clear the global cache (static method) |

## Cache

The result of `parse_all()` is automatically cached (LRU, default limit of 10 files). Use `GDSVLoader.clear_cache()` to clear the cache manually.

## Example

```gdscript
# Basic loading
var resource := GDSVLoader.new() \
    .load_file("res://data/items.gdsv") \
    .with_header(true) \
    .parse_all()

# With Schema
var resource := GDSVLoader.new() \
    .load_file("res://data/items.csv") \
    .with_delimiter(",") \
    .with_schema(preload("res://schemas/items_schema.tres")) \
    .parse_all()

# Streaming
var reader := GDSVLoader.new() \
    .load_file("res://data/huge.gdsv") \
    .stream()

while reader.has_next():
    var row: Dictionary = reader.next()
```
