# GDSVLoader (GDScript)

高级加载器，提供链式配置 API。

## 常用方法

| 方法 | 说明 |
| --- | --- |
| `load_file(path)` | 加载文件并准备解析 |
| `with_header(has_header)` | 设置表头开关 |
| `with_delimiter(delimiter)` | 设置分隔符 |
| `with_type(field, type)` | 指定字段类型 |
| `with_default(field, value)` | 设置字段默认值 |
| `with_required_fields(fields)` | 设置必需字段列表 |
| `with_schema(schema)` | 绑定 Schema |
| `parse_all()` | 解析为 `GDSVResource` |
| `stream()` | 返回 `GDSVStreamReaderGD` |
| `get_errors()` / `get_warnings()` | 获取解析日志 |
| `has_errors()` / `has_warnings()` | 检查解析状态 |
| `clear_cache()` | 清理全局缓存 |

## 示例

```gdscript
var resource := GDSVLoader.new()
	.load_file("res://data/items.gdsv")
	.with_header(true)
	.parse_all()
```

