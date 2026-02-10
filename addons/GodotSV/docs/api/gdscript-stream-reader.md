# GDSVStreamReaderGD (GDScript)

GDScript 流式读取器封装，逐行读取大文件，避免一次性加载全部数据到内存。

## 构造

通过 `GDSVLoader.stream()` 创建，不要直接实例化。

```gdscript
var reader := GDSVLoader.new() \
    .load_file("res://data/huge.gdsv") \
    .with_header(true) \
    .stream()
```

## 方法

| 方法 | 参数 | 返回类型 | 说明 |
|------|------|----------|------|
| `has_next` | — | `bool` | 是否还有数据行 |
| `next` | — | `Dictionary` | 读取下一行，返回字段名 → 值字典 |
| `close` | — | `void` | 关闭读取器 |
| `set_field_type` | `field_name: StringName, type: FieldType` | `void` | 设置字段类型 |
| `set_default_value` | `field_name: StringName, default_value: Variant` | `void` | 设置默认值 |
| `set_required_fields` | `fields: Array[StringName]` | `void` | 设置必需字段 |
| `set_schema` | `schema: GDSVSchema` | `void` | 设置 Schema |
| `get_headers` | — | `PackedStringArray` | 获取表头 |
| `get_current_line_index` | — | `int` | 当前行号 |
| `get_errors` | — | `Array[String]` | 获取错误列表 |
| `get_warnings` | — | `Array[String]` | 获取警告列表 |
| `has_errors` | — | `bool` | 是否有错误 |
| `has_warnings` | — | `bool` | 是否有警告 |

## 示例

```gdscript
# 基本遍历
var reader := GDSVLoader.new().load_file(path).with_header(true).stream()
while reader.has_next():
    var row: Dictionary = reader.next()
    print(row)
reader.close()

# 带 Schema 验证
var reader := GDSVLoader.new() \
    .load_file(path) \
    .with_schema(my_schema) \
    .stream()

while reader.has_next():
    var row: Dictionary = reader.next()
    if reader.has_warnings():
        push_warning(str(reader.get_warnings()))
```
