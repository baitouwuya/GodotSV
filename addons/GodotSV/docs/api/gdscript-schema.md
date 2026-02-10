# GDSVSchema (GDScript)

Schema 用于定义字段结构与验证规则，继承 `Resource`。

## 属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `field_definitions` | `Dictionary` | 字段名 → `GDSVFieldDefinition` 映射 |
| `has_header` | `bool` | 是否有表头（默认 `true`） |
| `delimiter` | `String` | 分隔符（默认 `","`） |

## 方法

| 方法 | 参数 | 返回类型 | 说明 |
|------|------|----------|------|
| `add_field` | `field_name: StringName, field_type: FieldType = TYPE_STRING` | `GDSVFieldDefinition` | 添加字段（返回定义对象，支持链式调用） |
| `get_field_definition` | `field_name: StringName` | `GDSVFieldDefinition` | 获取字段定义 |
| `get_field_names` | — | `Array` | 所有字段名 |
| `has_field` | `field_name: StringName` | `bool` | 字段是否存在 |
| `get_field_count` | — | `int` | 字段数量 |
| `get_required_fields` | — | `Array` | 必需字段列表 |
| `get_unique_fields` | — | `Array` | 唯一约束字段列表 |
| `validate_header` | `header_row: PackedStringArray` | `Array[String]` | 校验表头，返回错误列表 |
| `validate_row` | `row_data: Dictionary, row_index: int` | `Array[String]` | 校验行数据 |
| `get_header_indices` | `header_row: PackedStringArray` | `Dictionary` | 字段名 → 列索引映射 |

## 示例

```gdscript
var schema := GDSVSchema.new()

schema.add_field("id", GDSVFieldDefinition.FieldType.TYPE_INT) \
    .with_required(true) \
    .with_unique(true)

schema.add_field("name", GDSVFieldDefinition.FieldType.TYPE_STRING) \
    .with_required(true)

schema.add_field("rarity", GDSVFieldDefinition.FieldType.TYPE_STRING) \
    .with_enum(["common", "rare", "epic", "legendary"])

schema.add_field("price", GDSVFieldDefinition.FieldType.TYPE_FLOAT) \
    .with_range(0, 99999) \
    .with_default(0.0)

# 配合加载器使用
var resource := GDSVLoader.new() \
    .load_file("res://data/items.gdsv") \
    .with_schema(schema) \
    .parse_all()
```
