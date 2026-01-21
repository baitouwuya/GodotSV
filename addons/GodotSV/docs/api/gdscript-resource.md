# GDSVResource (GDScript)

解析后的数据资源，支持按字段类型访问。

## 常用属性

- `headers`：表头
- `rows`：行数据（Dictionary）
- `raw_data`：原始字符串数据（PackedStringArray）
- `errors` / `warnings`
- `total_rows` / `successful_rows` / `failed_rows`
- `has_header` / `delimiter`
- `source_gdsv_path`

## 常用方法

| 方法 | 说明 |
| --- | --- |
| `add_row(row)` / `add_raw_row(raw_row)` | 写入行数据（解析器内部使用） |
| `add_error` / `add_warning` | 记录错误或警告 |
| `get_value(row, field)` | 获取原始值 |
| `get_int` / `get_float` / `get_bool` / `get_string` / `get_string_name` | 类型安全读取 |
| `get_row_count()` / `get_column_count()` | 行列统计 |
| `find_row` / `find_rows` | 按字段查找 |
| `has_errors` / `has_warnings` | 错误/警告判断 |
| `get_errors` / `get_warnings` | 读取日志 |
| `clear()` | 清空所有数据 |
| `get_statistics()` | 统计摘要字符串 |

```gdscript
var name := resource.get_string(0, "name")
```

