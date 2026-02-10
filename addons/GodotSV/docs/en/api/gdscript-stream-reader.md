> [Chinese Version](../../api/gdscript-stream-reader.md)

# GDSVStreamReaderGD (GDScript)

A GDScript streaming reader wrapper that reads large files row by row, avoiding loading all data into memory at once.

## Construction

Created via `GDSVLoader.stream()`. Do not instantiate directly.

```gdscript
var reader := GDSVLoader.new() \
    .load_file("res://data/huge.gdsv") \
    .with_header(true) \
    .stream()
```

## Methods

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `has_next` | — | `bool` | Whether there are more data rows |
| `next` | — | `Dictionary` | Read the next row; returns a field name -> value dictionary |
| `close` | — | `void` | Close the reader |
| `set_field_type` | `field_name: StringName, type: FieldType` | `void` | Set a field type |
| `set_default_value` | `field_name: StringName, default_value: Variant` | `void` | Set a default value |
| `set_required_fields` | `fields: Array[StringName]` | `void` | Set required fields |
| `set_schema` | `schema: GDSVSchema` | `void` | Set a Schema |
| `get_headers` | — | `PackedStringArray` | Get the headers |
| `get_current_line_index` | — | `int` | Get the current line index |
| `get_errors` | — | `Array[String]` | Get the error list |
| `get_warnings` | — | `Array[String]` | Get the warning list |
| `has_errors` | — | `bool` | Whether there are errors |
| `has_warnings` | — | `bool` | Whether there are warnings |

## Example

```gdscript
# Basic iteration
var reader := GDSVLoader.new().load_file(path).with_header(true).stream()
while reader.has_next():
    var row: Dictionary = reader.next()
    print(row)
reader.close()

# With Schema validation
var reader := GDSVLoader.new() \
    .load_file(path) \
    .with_schema(my_schema) \
    .stream()

while reader.has_next():
    var row: Dictionary = reader.next()
    if reader.has_warnings():
        push_warning(str(reader.get_warnings()))
```
