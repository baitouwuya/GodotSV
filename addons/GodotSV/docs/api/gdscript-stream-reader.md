# GDSVStreamReaderGD (GDScript)

流式读取大文件，避免一次性加载。

## 常用方法

| 方法 | 说明 |
| --- | --- |
| `has_next()` | 是否还有下一行 |
| `next()` | 读取下一行 |
| `close()` | 关闭读取器 |
| `set_field_type(name, type)` | 设置字段类型 |
| `set_default_value(name, value)` | 设置字段默认值 |
| `set_schema(schema)` | 设置 Schema |
| `get_headers()` | 获取表头 |
| `get_current_line_index()` | 获取当前行号 |
| `get_errors()` / `get_warnings()` | 获取日志 |
| `has_errors()` / `has_warnings()` | 检查解析状态 |

## 示例

```gdscript
var reader := GDSVLoader.new().load_file(path).with_header(true).stream()
while reader.has_next():
	var row = reader.next()
```

