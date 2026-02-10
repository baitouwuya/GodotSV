# GDSVFieldDefinition (GDScript)

字段定义与验证规则配置。

## FieldType 常量

- `TYPE_STRING` / `TYPE_INT` / `TYPE_FLOAT` / `TYPE_BOOL`
- `TYPE_STRING_NAME` / `TYPE_JSON` / `TYPE_ARRAY`
- `TYPE_TEXTURE` / `TYPE_SCENE` / `TYPE_RESOURCE`

## 链式配置

| 方法 | 说明 |
| --- | --- |
| `with_default(value)` | 默认值 |
| `with_required(required=true)` | 是否必需 |
| `with_range(min, max)` | 数值范围 |
| `with_enum(values)` | 枚举值 |
| `with_unique(unique=true)` | 唯一约束 |

```gdscript
schema.add_field("rarity", GDSVFieldDefinition.FieldType.TYPE_STRING)
	.with_enum(["common", "rare", "epic"])
```

