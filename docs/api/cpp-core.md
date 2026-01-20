# C++ 核心类 API

本页概述核心 C++ GDExtension 类的职责与常用接口（方法名为 GDScript 可调用的 snake_case）。

## GDSVParser

- 解析 GDSV/CSV 字符串或文件为二维数组。
- 常用：`parse_from_string` / `parse_from_file` / `get_header` / `get_row_count` / `get_column_count` / `has_error` / `get_last_error`。

## GDSVTableData

- 表格数据增删改查与批量操作。
- 常用：`get_rows` / `get_header` / `get_cell_value` / `set_cell_value` / `insert_row` / `remove_row` / `append_row` / `insert_column` / `remove_column` / `get_column` / `set_column` / `move_row` / `move_column` / `batch_set_cells` / `trim_all_cells` / `clear` / `resize` / `is_valid_index`。
- 内嵌搜索：`search_in_table` / `search_regex_in_table` / `filter_rows_in_table` / `find_rows_by_column_value`。
- 匹配模式常量：`MATCH_CONTAINS` / `MATCH_NOT_CONTAINS` / `MATCH_EQUALS` / `MATCH_NOT_EQUALS` / `MATCH_STARTS_WITH` / `MATCH_ENDS_WITH`。

## GDSVTypeConverter

- 字符串 -> Variant 类型转换。
- 常用：`convert_string` / `convert_row` / `to_int` / `to_float` / `to_bool` / `to_string_name` / `to_array` / `to_enum` / `to_resource` / `has_error` / `get_last_error`。

## GDSVSearchEngine

- 搜索、替换与过滤（旧版外部搜索接口）。
- 常用：`search` / `search_regex` / `replace` / `filter_rows` / `find_next` / `find_previous` / `get_match_count` / `get_search_time` / `has_error` / `get_last_error`。
- 匹配模式常量：`MATCH_CONTAINS` / `MATCH_NOT_CONTAINS` / `MATCH_EQUALS` / `MATCH_NOT_EQUALS` / `MATCH_STARTS_WITH` / `MATCH_ENDS_WITH`。

## GDSVDataValidator

- 校验单元格/行/表数据。
- 常用：`validate_cell` / `validate_row` / `validate_table` / `get_errors` / `get_error_count` / `clear_errors` / `has_errors` / `get_last_error`。

## GDSVStreamReader

- 大文件流式读取。
- 常用：`open_file` / `close_file` / `read_next_line` / `read_lines` / `read_all` / `pause` / `resume` / `is_paused` / `is_eof` / `is_open` / `get_header` / `get_current_line_number` / `get_read_line_count` / `get_total_line_count` / `get_progress` / `seek_to_line` / `reset` / `has_error` / `get_last_error`。

## GDSVTypeAnnotationParser

- 解析表头内联类型注解。
- 常用：`parse_header` / `get_field_type` / `is_field_required` / `get_field_default` / `get_field_range` / `get_field_enum_values` / `get_array_element_type` / `is_annotation_valid` / `has_error` / `get_last_error`。

## GDSVColumnParser

- 解析 GDSV 表头列定义。
- 常用：`parse_column_definition` / `parse_header` / `has_gdsv_syntax` / `apply_default` / `has_error` / `get_last_error`。

详细方法签名请参考本目录下的 API 文档与源码绑定注释。
