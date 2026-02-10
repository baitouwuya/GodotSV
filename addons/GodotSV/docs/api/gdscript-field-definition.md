# GDSVFieldDefinition (GDScript)

字段定义与验证规则配置，继承 `Resource`。通过链式 API 配置约束。

## FieldType 枚举

| 常量 | 说明 |
|------|------|
| `TYPE_STRING` | 字符串 |
| `TYPE_INT` | 整数 |
| `TYPE_FLOAT` | 浮点数 |
| `TYPE_BOOL` | 布尔值 |
| `TYPE_STRING_NAME` | StringName |
| `TYPE_JSON` | JSON（解析为 Dictionary 或 Array） |
| `TYPE_ARRAY` | 数组（逗号分隔字符串） |
| `TYPE_TEXTURE` | Texture2D 资源 |
| `TYPE_SCENE` | PackedScene 资源 |
| `TYPE_RESOURCE` | 通用 Resource |

## 属性

| 属性 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `field_name` | `StringName` | — | 字段名 |
| `type` | `FieldType` | `TYPE_STRING` | 字段类型 |
| `default_value` | `Variant` | — | 默认值 |
| `required` | `bool` | `false` | 是否必填 |
| `min_value` | `Variant` | — | 最小值 |
| `max_value` | `Variant` | — | 最大值 |
| `enum_values` | `Array` | `[]` | 枚举值列表 |
| `unique` | `bool` | `false` | 唯一约束 |
| `resource_base_path` | `String` | `""` | 资源基础路径 |
| `description` | `String` | `""` | 字段描述 |

## 链式配置方法

所有方法返回 `GDSVFieldDefinition` 自身，支持链式调用。

| 方法 | 参数 | 说明 |
|------|------|------|
| `with_type` | `p_type: FieldType` | 设置类型 |
| `with_default` | `p_default_value: Variant` | 默认值 |
| `with_required` | `p_required: bool = true` | 是否必填 |
| `with_range` | `p_min: Variant, p_max: Variant` | 数值范围 |
| `with_enum` | `p_enum_values: Array` | 枚举约束 |
| `with_unique` | `p_unique: bool = true` | 唯一约束 |
| `with_resource_base_path` | `p_path: String` | 资源路径前缀 |
| `with_description` | `p_desc: String` | 字段描述 |

## 验证方法

| 方法 | 参数 | 返回类型 | 说明 |
|------|------|----------|------|
| `validate_value` | `value: Variant, row_index: int` | `bool` | 验证值 |
| `get_validation_error` | `value: Variant, row_index: int` | `String` | 获取验证错误信息 |
| `is_value_empty` | `value: Variant` | `bool` | 值是否为空 |
| `get_type_default` | — | `Variant` | 获取类型默认值 |

## 示例

```gdscript
schema.add_field("health", GDSVFieldDefinition.FieldType.TYPE_FLOAT) \
    .with_required(true) \
    .with_range(0.0, 9999.0) \
    .with_default(100.0) \
    .with_description("角色生命值")
```
