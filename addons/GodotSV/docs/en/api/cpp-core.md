# C++ Core Class API

> [中文版](../../api/cpp-core.md)

This page provides an overview of the core C++ GDExtension classes, their responsibilities, and interfaces. Method names are shown in `snake_case` form as callable from GDScript.

> All `*_result` methods return a unified result dictionary: `{"success": bool, "value": Variant, "error_message": String}`

---

## GDSVParser

GDSV/CSV text parser that converts strings or files into two-dimensional string arrays.

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `parse_from_string` | `content: String, has_header: bool, delimiter: String` | `Array[PackedStringArray]` | Parse from a string |
| `parse_from_file` | `file_path: String, has_header: bool, delimiter: String` | `Array[PackedStringArray]` | Parse from a file |
| `get_header` | — | `PackedStringArray` | Get the header row |
| `get_row_count` | — | `int` | Number of data rows |
| `get_column_count` | — | `int` | Number of columns |
| `get_last_error` | — | `String` | Last error message |
| `has_error` | — | `bool` | Whether an error occurred |

---

## GDSVTableData

Table data storage and manipulation with row/column CRUD, search, and filtering support.

### Match Mode Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `MATCH_CONTAINS` | 0 | Contains |
| `MATCH_NOT_CONTAINS` | 1 | Does not contain |
| `MATCH_EQUALS` | 2 | Equals |
| `MATCH_NOT_EQUALS` | 3 | Does not equal |
| `MATCH_STARTS_WITH` | 4 | Starts with |
| `MATCH_ENDS_WITH` | 5 | Ends with |

### Data Operations

| Method | Parameters | Return Type |
|--------|------------|-------------|
| `initialize` | `rows: Array[PackedStringArray], header: PackedStringArray` | `void` |
| `get_rows` | — | `Array[PackedStringArray]` |
| `get_header` | — | `PackedStringArray` |
| `get_row_count` | — | `int` |
| `get_column_count` | — | `int` |
| `get_cell_value` | `row: int, column: int` | `String` |
| `set_cell_value` | `row: int, column: int, value: String` | `bool` |
| `get_row` | `row: int` | `PackedStringArray` |
| `set_row` | `row: int, row_data: PackedStringArray` | `bool` |
| `insert_row` | `row: int, row_data: PackedStringArray` | `bool` |
| `remove_row` | `row: int` | `bool` |
| `append_row` | `row_data: PackedStringArray` | `void` |
| `insert_column` | `column: int, column_name: String, default_value: String = ""` | `bool` |
| `remove_column` | `column: int` | `bool` |
| `get_column` | `column: int` | `PackedStringArray` |
| `set_column` | `column: int, column_data: PackedStringArray` | `bool` |
| `move_row` | `from_row: int, to_row: int` | `bool` |
| `move_column` | `from_column: int, to_column: int` | `bool` |
| `batch_set_cells` | `cells: Array[Dictionary]` | `int` |
| `trim_all_cells` | — | `void` |
| `clear` | — | `void` |
| `resize` | `row_count: int, column_count: int, default_value: String = ""` | `void` |
| `is_valid_index` | `row: int, column: int` | `bool` |

### Built-in Search

| Method | Parameters | Return Type |
|--------|------------|-------------|
| `search_in_table` | `search_text: String, case_sensitive: bool = false, match_mode: int = 0, search_columns: PackedInt32Array = []` | `Array[Dictionary]` |
| `search_regex_in_table` | `regex_pattern: String, search_columns: PackedInt32Array = []` | `Array[Dictionary]` |
| `filter_rows_in_table` | `filter_text: String, case_sensitive: bool = false, match_mode: int = 0, filter_column: int = -1` | `PackedInt32Array` |
| `find_rows_by_column_value` | `column: int, value: String, case_sensitive: bool = false` | `PackedInt32Array` |

---

## GDSVTypeConverter

Converts between strings and Variant types. Each method has a corresponding `*_result` version that returns a result dictionary with error information.

### General Conversion

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `convert_string` | `value: String, type: String, extra_param: Variant = null` | `Variant` | Convert by type name; returns null on failure |
| `convert_string_result` | `value: String, type: String, extra_param: Variant = null` | `Dictionary` | Same as above, with error information |
| `convert_value` | `value: String, type_definition: Dictionary` | `Variant` | Convert by type definition |
| `convert_value_result` | `value: String, type_definition: Dictionary` | `Dictionary` | Same as above, with error information |
| `convert_row` | `row: PackedStringArray, types: PackedStringArray, extra_params: Array` | `Array` | Batch convert an entire row |
| `convert_row_result` | `row: PackedStringArray, types: PackedStringArray, extra_params: Array` | `Array` | Same as above; each element is a result dictionary |

### Shortcut Conversions

| Method | `*_result` Version | Parameters | Return Type |
|--------|---------------------|------------|-------------|
| `to_int` | `to_int_result` | `value: String, range: String = ""` | `int` / `Dictionary` |
| `to_float` | `to_float_result` | `value: String, range: String = ""` | `float` / `Dictionary` |
| `to_bool` | `to_bool_result` | `value: String` | `bool` / `Dictionary` |
| `to_string_name` | — | `value: String` | `StringName` |
| `to_array` | `to_array_result` | `value: String, element_type: String` | `Array` / `Dictionary` |
| `to_enum` | `to_enum_result` | `value: String, enum_values: PackedStringArray` | `String` / `Dictionary` |
| `to_resource` | `to_resource_result` | `value: String, resource_type: String` | `Resource` / `Dictionary` |

### Error Queries

| Method | Return Type | Description |
|--------|-------------|-------------|
| `get_last_error` | `String` | Error message from the most recent conversion |
| `has_error` | `bool` | Whether the most recent conversion had an error |

---

## GDSVSearchEngine

Standalone search engine that performs search, replace, and filter operations on external row arrays.

Match mode constants are the same as `GDSVTableData` (`MATCH_CONTAINS` ... `MATCH_ENDS_WITH`).

| Method | Parameters | Return Type |
|--------|------------|-------------|
| `search` | `rows, search_text, case_sensitive = false, match_mode = 0, search_columns = []` | `Array[Dictionary]` |
| `search_regex` | `rows, regex_pattern, search_columns = []` | `Array[Dictionary]` |
| `replace` | `rows, search_text, replace_text, case_sensitive = false, match_mode = 0, search_columns = []` | `Array[PackedStringArray]` |
| `filter_rows` | `rows, filter_text, case_sensitive = false, match_mode = 0, filter_column = -1` | `PackedInt32Array` |
| `find_next` | `rows, search_text, start_row = 0, start_column = 0, case_sensitive = false, search_columns = []` | `Dictionary` |
| `find_previous` | `rows, search_text, start_row = 0, start_column = 0, case_sensitive = false, search_columns = []` | `Dictionary` |
| `get_match_count` | — | `int` |
| `get_search_time` | — | `float` |
| `get_last_error` | — | `String` |
| `has_error` | — | `bool` |

---

## GDSVDataValidator

Data validator that validates cell-level, row-level, and table-level data.

| Method | Parameters | Return Type |
|--------|------------|-------------|
| `validate_cell` | `value: String, field_name: String, field_info: Dictionary` | `bool` |
| `validate_row` | `row: PackedStringArray, header: PackedStringArray, field_map: Dictionary` | `bool` |
| `validate_table` | `rows: Array[PackedStringArray], header: PackedStringArray, field_map: Dictionary` | `bool` |
| `get_errors` | — | `Array[Dictionary]` |
| `get_error_count` | — | `int` |
| `clear_errors` | — | `void` |
| `has_errors` | — | `bool` |
| `get_last_error` | — | `Dictionary` |

---

## GDSVStreamReader

C++ streaming reader for reading large files line by line, with support for pause/resume and progress queries.

| Method | Parameters | Return Type |
|--------|------------|-------------|
| `open_file` | `file_path: String, has_header: bool = true, delimiter: String = ","` | `bool` |
| `close_file` | — | `void` |
| `read_next_line` | — | `PackedStringArray` |
| `read_lines` | `count: int` | `Array[PackedStringArray]` |
| `read_all` | — | `Array[PackedStringArray]` |
| `pause` | — | `void` |
| `resume` | — | `void` |
| `is_paused` | — | `bool` |
| `is_eof` | — | `bool` |
| `is_open` | — | `bool` |
| `get_header` | — | `PackedStringArray` |
| `get_current_line_number` | — | `int` |
| `get_read_line_count` | — | `int` |
| `get_total_line_count` | — | `int` |
| `get_progress` | — | `float` |
| `seek_to_line` | `line_number: int` | `bool` |
| `reset` | — | `void` |
| `get_last_error` | — | `String` |
| `has_error` | — | `bool` |

---

## GDSVTypeAnnotationParser

Parses inline type annotations in GDSV headers.

| Method | Parameters | Return Type |
|--------|------------|-------------|
| `parse_header` | `header: PackedStringArray` | `Array` |
| `get_field_type` | `field_name: String` | `String` |
| `is_field_required` | `field_name: String` | `bool` |
| `get_field_default` | `field_name: String` | `Variant` |
| `get_field_range` | `field_name: String` | `Dictionary` |
| `get_field_enum_values` | `field_name: String` | `PackedStringArray` |
| `get_array_element_type` | `field_name: String` | `String` |
| `is_annotation_valid` | `annotation: String` | `bool` |
| `get_last_error` | — | `String` |
| `has_error` | — | `bool` |
