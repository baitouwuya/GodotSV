# GDSVSchema (GDScript)

Schema 用于定义字段与验证规则。

## 常用方法

| 方法 | 说明 |
| --- | --- |
| `add_field(name, type)` | 添加字段定义 |
| `validate_header(header)` | 校验表头 |
| `validate_row(data, index)` | 校验行数据 |

## 示例

```gdscript
var schema := GDSVSchema.new()
schema.add_field("id", GDSVFieldDefinition.FieldType.TYPE_INT)
	.with_required(true)
```

