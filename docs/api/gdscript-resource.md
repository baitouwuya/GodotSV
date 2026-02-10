# GDSVResource (GDScript)

解析后的数据资源，支持按字段类型访问。

## 常用属性

- `headers`：表头
- `rows`：行数据（Dictionary）
- `raw_data`：原始字符串数据
- `errors` / `warnings`

## 常用方法

| 方法 | 说明 |
| --- | --- |
| `get_value(row, field)` | 获取原始值 |
| `get_int` / `get_float` / `get_bool` | 类型安全读取 |
| `find_row` / `find_rows` | 按字段查找 |
| `has_errors` / `get_errors` | 错误处理 |

```gdscript
var name := resource.get_string(0, "name")
```

