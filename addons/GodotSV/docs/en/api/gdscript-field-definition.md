> [Chinese Version](../../api/gdscript-field-definition.md)

# GDSVFieldDefinition (GDScript)

Field definition and validation rule configuration. Extends `Resource`. Supports a chainable API for configuring constraints.

## FieldType Enum

| Constant | Description |
|----------|-------------|
| `TYPE_STRING` | String |
| `TYPE_INT` | Integer |
| `TYPE_FLOAT` | Float |
| `TYPE_BOOL` | Boolean |
| `TYPE_STRING_NAME` | StringName |
| `TYPE_JSON` | JSON (parsed as Dictionary or Array) |
| `TYPE_ARRAY` | Array (comma-separated string) |
| `TYPE_TEXTURE` | Texture2D resource |
| `TYPE_SCENE` | PackedScene resource |
| `TYPE_RESOURCE` | Generic Resource |

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `field_name` | `StringName` | — | Field name |
| `type` | `FieldType` | `TYPE_STRING` | Field type |
| `default_value` | `Variant` | — | Default value |
| `required` | `bool` | `false` | Whether the field is required |
| `min_value` | `Variant` | — | Minimum value |
| `max_value` | `Variant` | — | Maximum value |
| `enum_values` | `Array` | `[]` | List of allowed enum values |
| `unique` | `bool` | `false` | Unique constraint |
| `resource_base_path` | `String` | `""` | Resource base path |
| `description` | `String` | `""` | Field description |

## Chaining Configuration Methods

All methods return the `GDSVFieldDefinition` itself, enabling method chaining.

| Method | Parameters | Description |
|--------|------------|-------------|
| `with_type` | `p_type: FieldType` | Set the type |
| `with_default` | `p_default_value: Variant` | Set the default value |
| `with_required` | `p_required: bool = true` | Set whether the field is required |
| `with_range` | `p_min: Variant, p_max: Variant` | Set the numeric range |
| `with_enum` | `p_enum_values: Array` | Set the enum constraint |
| `with_unique` | `p_unique: bool = true` | Set the unique constraint |
| `with_resource_base_path` | `p_path: String` | Set the resource path prefix |
| `with_description` | `p_desc: String` | Set the field description |

## Validation Methods

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `validate_value` | `value: Variant, row_index: int` | `bool` | Validate a value |
| `get_validation_error` | `value: Variant, row_index: int` | `String` | Get the validation error message |
| `is_value_empty` | `value: Variant` | `bool` | Whether the value is empty |
| `get_type_default` | — | `Variant` | Get the type's default value |

## Example

```gdscript
schema.add_field("health", GDSVFieldDefinition.FieldType.TYPE_FLOAT) \
    .with_required(true) \
    .with_range(0.0, 9999.0) \
    .with_default(100.0) \
    .with_description("Character health points")
```
