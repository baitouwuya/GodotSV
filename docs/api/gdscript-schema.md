# GDSVSchema (GDScript)

Schema 用于定义字段与验证规则。

## 常用方法

| 方法 | 说明 |
| --- | --- |
| `add_field(name, type)` | 添加字段定义 |
| `get_field_definition(name)` | 获取字段定义 |
| `get_field_names()` | 获取全部字段名 |
| `has_field(name)` | 检查字段是否存在 |
| `get_field_count()` | 字段数量 |
| `get_required_fields()` | 必需字段列表 |
| `get_unique_fields()` | 唯一约束字段列表 |
| `validate_header(header)` | 校验表头 |
| `validate_row(data, index)` | 校验行数据 |
| `get_header_indices(header)` | 字段名到列索引映射 |

## 示例

```gdscript
var schema := GDSVSchema.new()
schema.add_field("id", GDSVFieldDefinition.FieldType.TYPE_INT)
	.with_required(true)
```

