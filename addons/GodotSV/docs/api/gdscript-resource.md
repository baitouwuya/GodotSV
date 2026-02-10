# GDSVResource (GDScript)

解析后的数据资源，继承 `Resource`。支持按行索引和字段名类型安全地访问数据。

## 属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `headers` | `PackedStringArray` | 表头字段名 |
| `rows` | `Array[Dictionary]` | 行数据（字段名 → 值） |
| `raw_data` | `Array[PackedStringArray]` | 原始字符串数据 |
| `errors` | `Array[String]` | 错误列表 |
| `warnings` | `Array[String]` | 警告列表 |
| `total_rows` | `int` | 总行数 |
| `successful_rows` | `int` | 成功行数 |
| `failed_rows` | `int` | 失败行数 |
| `has_header` | `bool` | 是否有表头 |
| `delimiter` | `String` | 分隔符 |
| `source_gdsv_path` | `String` | 源文件路径 |

## 方法

### 类型安全读取

| 方法 | 参数 | 返回类型 |
|------|------|----------|
| `get_value` | `row_index: int, field_name: StringName` | `Variant` |
| `get_int` | `row_index: int, field_name: StringName, default_value: int = 0` | `int` |
| `get_float` | `row_index: int, field_name: StringName, default_value: float = 0.0` | `float` |
| `get_bool` | `row_index: int, field_name: StringName, default_value: bool = false` | `bool` |
| `get_string` | `row_index: int, field_name: StringName, default_value: String = ""` | `String` |
| `get_string_name` | `row_index: int, field_name: StringName, default_value: StringName = &""` | `StringName` |

### 查询与统计

| 方法 | 参数 | 返回类型 |
|------|------|----------|
| `get_row_count` | — | `int` |
| `get_column_count` | — | `int` |
| `find_row` | `field_name: StringName, value: Variant` | `Dictionary` |
| `find_rows` | `field_name: StringName, value: Variant` | `Array[Dictionary]` |
| `get_statistics` | — | `String` |

### 错误与警告

| 方法 | 返回类型 |
|------|----------|
| `has_errors` | `bool` |
| `has_warnings` | `bool` |
| `get_errors` | `Array[String]` |
| `get_warnings` | `Array[String]` |

### 写入与清理

| 方法 | 参数 | 说明 |
|------|------|------|
| `add_row` | `row_data: Dictionary` | 添加行（解析器内部使用） |
| `add_raw_row` | `raw_row: PackedStringArray` | 添加原始行 |
| `add_error` | `error_msg: String` | 记录错误 |
| `add_warning` | `warning_msg: String` | 记录警告 |
| `clear` | — | 清空所有数据 |

## 示例

```gdscript
var res := GDSVLoader.new().load_file("res://data/items.gdsv").parse_all()

# 遍历
for i in res.get_row_count():
    var name: String = res.get_string(i, "name")
    var price: float = res.get_float(i, "price", 0.0)
    print("%s: %.1f" % [name, price])

# 查找
var hero: Dictionary = res.find_row("name", "Alice")
var rare_items: Array = res.find_rows("rarity", "epic")
```
