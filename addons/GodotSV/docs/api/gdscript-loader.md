# GDSVLoader (GDScript)

链式加载器，提供流畅的配置 API。

## 方法

| 方法 | 参数 | 返回类型 | 说明 |
|------|------|----------|------|
| `load_file` | `path: String` | `GDSVLoader` | 加载文件 |
| `with_header` | `has_header: bool` | `GDSVLoader` | 设置表头开关 |
| `with_delimiter` | `delimiter: String` | `GDSVLoader` | 设置分隔符 |
| `with_type` | `field: StringName, type: GDSVFieldDefinition.FieldType` | `GDSVLoader` | 指定字段类型 |
| `with_default` | `field: StringName, value: Variant` | `GDSVLoader` | 设置默认值 |
| `with_required_fields` | `fields: Array[StringName]` | `GDSVLoader` | 设置必需字段 |
| `with_schema` | `schema: GDSVSchema` | `GDSVLoader` | 绑定 Schema |
| `parse_all` | — | `GDSVResource` | 一次性解析全部数据 |
| `stream` | — | `GDSVStreamReaderGD` | 创建流式读取器 |
| `get_errors` | — | `Array[String]` | 获取错误列表 |
| `get_warnings` | — | `Array[String]` | 获取警告列表 |
| `has_errors` | — | `bool` | 是否有错误 |
| `has_warnings` | — | `bool` | 是否有警告 |
| `clear_cache` | — | `void` | 清理全局缓存（静态方法） |

## 缓存

`parse_all()` 的结果会被自动缓存（LRU，默认上限 10 个文件）。使用 `GDSVLoader.clear_cache()` 手动清理。

## 示例

```gdscript
# 基本加载
var resource := GDSVLoader.new() \
    .load_file("res://data/items.gdsv") \
    .with_header(true) \
    .parse_all()

# 带 Schema
var resource := GDSVLoader.new() \
    .load_file("res://data/items.csv") \
    .with_delimiter(",") \
    .with_schema(preload("res://schemas/items_schema.tres")) \
    .parse_all()

# 流式读取
var reader := GDSVLoader.new() \
    .load_file("res://data/huge.gdsv") \
    .stream()

while reader.has_next():
    var row: Dictionary = reader.next()
```
