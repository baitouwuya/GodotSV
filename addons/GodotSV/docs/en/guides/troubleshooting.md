# Troubleshooting

> [中文版](../../guides/troubleshooting.md)

## Plugin Not Showing

**Symptom**: GodotSV is not visible under "Project -> Project Settings -> Plugins".

**Diagnosis**:
1. Confirm that the `addons/GodotSV/plugin.cfg` file exists
2. Confirm the directory structure is correct: `addons/GodotSV/bin/` contains the DLL/so files for the target platform
3. Restart the Godot editor

## GDExtension DLL Fails to Load

**Symptom**: Console shows errors like `Can't resolve symbol` or `entry point not found`.

**Diagnosis**:
1. Confirm that `addons/GodotSV/godotsv.gdextension` contains `entry_symbol = "godotsv_library_init"`
2. Confirm there are no extra `.gdextension` files under `bin/` (e.g., `example.gdextension` left over from a template)
3. Confirm the DLL is compatible with the current Godot version (4.5+)
4. If there are multiple `.gdextension` files, keep only `addons/GodotSV/godotsv.gdextension`

## Parsing Failure

**Symptom**: `resource.has_errors()` returns `true`, data is empty.

**Diagnosis**:
1. Check the file encoding -- GDSV requires UTF-8 (BOM is supported)
2. Check the delimiter -- `.gdsv` defaults to Tab, `.csv` defaults to comma
3. Use `.with_header(false)` when there is no header row
4. Inspect the specific error messages: `print(resource.get_errors())`

## Delimiter Errors

**Symptom**: All data is crammed into a single column, or columns are misaligned.

**Diagnosis**:
1. `.gdsv` files default to Tab separation; confirm your editor has not converted Tabs to spaces
2. Explicitly specify the delimiter: `.with_delimiter("\t")` or `.with_delimiter(",")`
3. Confirm the file extension is correct -- the delimiter is inferred automatically from the extension

## Type Conversion Issues

**Symptom**: Field values are `null` or have the wrong type.

**Diagnosis**:
1. Check type annotation spelling (case-sensitive): `Vector2` not `vector2`
2. Check value format -- vectors use comma-separated values `1,2,3`, do not add spaces
3. Set default values for empty fields: `health:float=100`
4. Use `*_result` methods to get detailed error information

## Custom Type Not Visible

**Symptom**: The custom type does not appear in the type picker.

**Diagnosis**:
1. Confirm the script has the `@tool` annotation (not inherited; must be explicitly declared)
2. Confirm a `class_name` is declared
3. Confirm it extends `GDSVTypeHandler`
4. Restart the editor or call `GDSVTypeHandlerRegistry.get_singleton().scan_script_types()`

## Custom Editor Does Not Save Values

**Symptom**: The custom editor widget displays correctly, but edited values are not saved.

**Diagnosis**:
1. Confirm the widget has `signal value_changed`
2. Confirm the widget has a `get_value() -> String` method
3. Confirm `value_changed.emit()` is called when the value changes

## High Memory Usage with Large Files

**Symptom**: Memory usage spikes when loading large files.

**Solution**:
Use `.stream()` for streaming reads instead of `.parse_all()`:

```gdscript
var reader := GDSVLoader.new() \
    .load_file("res://data/huge.gdsv") \
    .stream()

while reader.has_next():
    var row: Dictionary = reader.next()
    process_row(row)

reader.close()
```

## File Not Found After Export

**Symptom**: Loading a GDSV file after exporting the game results in a "file not found" error.

**Diagnosis**:
1. Confirm file paths use the `res://` prefix
2. In the export settings, check that `.gdsv` / `.csv` / `.tsv` files are included
3. In the "Resources" tab of the export settings, add `*.gdsv` to the non-resource export filter

## Getting More Help

- [GitHub Issues](https://github.com/baitouwuya/better-godot-csv/issues) -- Report issues
- [API Overview](../api/index.md) -- View the complete API documentation
