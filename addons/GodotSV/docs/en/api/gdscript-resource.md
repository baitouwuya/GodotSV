> [Chinese Version](../../api/gdscript-resource.md)

# GDSVResource (GDScript)

A parsed data resource that extends `Resource`. Provides type-safe access to data by row index and field name.

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `headers` | `PackedStringArray` | Header field names |
| `rows` | `Array[Dictionary]` | Row data (field name -> value) |
| `raw_data` | `Array[PackedStringArray]` | Raw string data |
| `errors` | `Array[String]` | Error list |
| `warnings` | `Array[String]` | Warning list |
| `total_rows` | `int` | Total number of rows |
| `successful_rows` | `int` | Number of successfully parsed rows |
| `failed_rows` | `int` | Number of failed rows |
| `has_header` | `bool` | Whether the data has a header row |
| `delimiter` | `String` | Delimiter character |
| `source_gdsv_path` | `String` | Source file path |

## Methods

### Type-Safe Reading

| Method | Parameters | Return Type |
|--------|------------|-------------|
| `get_value` | `row_index: int, field_name: StringName` | `Variant` |
| `get_int` | `row_index: int, field_name: StringName, default_value: int = 0` | `int` |
| `get_float` | `row_index: int, field_name: StringName, default_value: float = 0.0` | `float` |
| `get_bool` | `row_index: int, field_name: StringName, default_value: bool = false` | `bool` |
| `get_string` | `row_index: int, field_name: StringName, default_value: String = ""` | `String` |
| `get_string_name` | `row_index: int, field_name: StringName, default_value: StringName = &""` | `StringName` |

### Query and Statistics

| Method | Parameters | Return Type |
|--------|------------|-------------|
| `get_row_count` | — | `int` |
| `get_column_count` | — | `int` |
| `find_row` | `field_name: StringName, value: Variant` | `Dictionary` |
| `find_rows` | `field_name: StringName, value: Variant` | `Array[Dictionary]` |
| `get_statistics` | — | `String` |

### Errors and Warnings

| Method | Return Type |
|--------|-------------|
| `has_errors` | `bool` |
| `has_warnings` | `bool` |
| `get_errors` | `Array[String]` |
| `get_warnings` | `Array[String]` |

### Writing and Clearing

| Method | Parameters | Description |
|--------|------------|-------------|
| `add_row` | `row_data: Dictionary` | Add a row (used internally by the parser) |
| `add_raw_row` | `raw_row: PackedStringArray` | Add a raw row |
| `add_error` | `error_msg: String` | Record an error |
| `add_warning` | `warning_msg: String` | Record a warning |
| `clear` | — | Clear all data |

## Example

```gdscript
var res := GDSVLoader.new().load_file("res://data/items.gdsv").parse_all()

# Iterate
for i in res.get_row_count():
    var name: String = res.get_string(i, "name")
    var price: float = res.get_float(i, "price", 0.0)
    print("%s: %.1f" % [name, price])

# Search
var hero: Dictionary = res.find_row("name", "Alice")
var rare_items: Array = res.find_rows("rarity", "epic")
```
