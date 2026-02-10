# C++ 核心类 API

本页概述核心 C++ GDExtension 类的职责与接口。方法名为 GDScript 可调用的 `snake_case` 形式。

> 所有 `*_result` 方法返回统一的结果字典：`{"success": bool, "value": Variant, "error_message": String}`

---

## GDSVParser

GDSV/CSV 文本解析器，将字符串或文件解析为二维字符串数组。

| 方法 | 参数 | 返回类型 | 说明 |
|------|------|----------|------|
| `parse_from_string` | `content: String, has_header: bool, delimiter: String` | `Array[PackedStringArray]` | 从字符串解析 |
| `parse_from_file` | `file_path: String, has_header: bool, delimiter: String` | `Array[PackedStringArray]` | 从文件解析 |
| `get_header` | — | `PackedStringArray` | 获取表头 |
| `get_row_count` | — | `int` | 数据行数 |
| `get_column_count` | — | `int` | 列数 |
| `get_last_error` | — | `String` | 最后一个错误信息 |
| `has_error` | — | `bool` | 是否有错误 |

---

## GDSVTableData

表格数据存储与操作，支持行列 CRUD、搜索、过滤。

### 匹配模式常量

| 常量 | 值 | 说明 |
|------|----|------|
| `MATCH_CONTAINS` | 0 | 包含 |
| `MATCH_NOT_CONTAINS` | 1 | 不包含 |
| `MATCH_EQUALS` | 2 | 等于 |
| `MATCH_NOT_EQUALS` | 3 | 不等于 |
| `MATCH_STARTS_WITH` | 4 | 前缀匹配 |
| `MATCH_ENDS_WITH` | 5 | 后缀匹配 |

### 数据操作

| 方法 | 参数 | 返回类型 |
|------|------|----------|
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

### 内嵌搜索

| 方法 | 参数 | 返回类型 |
|------|------|----------|
| `search_in_table` | `search_text: String, case_sensitive: bool = false, match_mode: int = 0, search_columns: PackedInt32Array = []` | `Array[Dictionary]` |
| `search_regex_in_table` | `regex_pattern: String, search_columns: PackedInt32Array = []` | `Array[Dictionary]` |
| `filter_rows_in_table` | `filter_text: String, case_sensitive: bool = false, match_mode: int = 0, filter_column: int = -1` | `PackedInt32Array` |
| `find_rows_by_column_value` | `column: int, value: String, case_sensitive: bool = false` | `PackedInt32Array` |

---

## GDSVTypeConverter

字符串与 Variant 类型之间的转换。每个方法都有对应的 `*_result` 版本，返回包含错误信息的结果字典。

### 通用转换

| 方法 | 参数 | 返回类型 | 说明 |
|------|------|----------|------|
| `convert_string` | `value: String, type: String, extra_param: Variant = null` | `Variant` | 按类型名转换，失败返回空 |
| `convert_string_result` | `value: String, type: String, extra_param: Variant = null` | `Dictionary` | 同上，带错误信息 |
| `convert_value` | `value: String, type_definition: Dictionary` | `Variant` | 按类型定义转换 |
| `convert_value_result` | `value: String, type_definition: Dictionary` | `Dictionary` | 同上，带错误信息 |
| `convert_row` | `row: PackedStringArray, types: PackedStringArray, extra_params: Array` | `Array` | 批量转换整行 |
| `convert_row_result` | `row: PackedStringArray, types: PackedStringArray, extra_params: Array` | `Array` | 同上，每个元素为结果字典 |

### 快捷转换

| 方法 | `*_result` 版本 | 参数 | 返回类型 |
|------|-----------------|------|----------|
| `to_int` | `to_int_result` | `value: String, range: String = ""` | `int` / `Dictionary` |
| `to_float` | `to_float_result` | `value: String, range: String = ""` | `float` / `Dictionary` |
| `to_bool` | `to_bool_result` | `value: String` | `bool` / `Dictionary` |
| `to_string_name` | — | `value: String` | `StringName` |
| `to_array` | `to_array_result` | `value: String, element_type: String` | `Array` / `Dictionary` |
| `to_enum` | `to_enum_result` | `value: String, enum_values: PackedStringArray` | `String` / `Dictionary` |
| `to_resource` | `to_resource_result` | `value: String, resource_type: String` | `Resource` / `Dictionary` |

### 错误查询

| 方法 | 返回类型 | 说明 |
|------|----------|------|
| `get_last_error` | `String` | 最近一次转换的错误信息 |
| `has_error` | `bool` | 最近一次转换是否有错误 |

---

## GDSVSearchEngine

独立搜索引擎，在外部行数组上执行搜索、替换和过滤。

匹配模式常量与 `GDSVTableData` 相同（`MATCH_CONTAINS` ... `MATCH_ENDS_WITH`）。

| 方法 | 参数 | 返回类型 |
|------|------|----------|
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

数据校验器，验证单元格、行和表级数据。

| 方法 | 参数 | 返回类型 |
|------|------|----------|
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

C++ 流式读取器，逐行读取大文件，支持暂停/恢复和进度查询。

| 方法 | 参数 | 返回类型 |
|------|------|----------|
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

解析 GDSV 表头中的内联类型注解。

| 方法 | 参数 | 返回类型 |
|------|------|----------|
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
