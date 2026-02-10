> [Chinese Version](../../api/gdscript-schema.md)

# GDSVSchema (GDScript)

A Schema used to define field structures and validation rules. Extends `Resource`.

## Properties

| Property | Type | Description |
|----------|------|-------------|
| `field_definitions` | `Dictionary` | Field name -> `GDSVFieldDefinition` mapping |
| `has_header` | `bool` | Whether the data has a header row (default: `true`) |
| `delimiter` | `String` | Delimiter character (default: `","`) |

## Methods

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `add_field` | `field_name: StringName, field_type: FieldType = TYPE_STRING` | `GDSVFieldDefinition` | Add a field (returns the definition object for chaining) |
| `get_field_definition` | `field_name: StringName` | `GDSVFieldDefinition` | Get a field definition |
| `get_field_names` | — | `Array` | All field names |
| `has_field` | `field_name: StringName` | `bool` | Whether the field exists |
| `get_field_count` | — | `int` | Number of fields |
| `get_required_fields` | — | `Array` | List of required fields |
| `get_unique_fields` | — | `Array` | List of fields with unique constraints |
| `validate_header` | `header_row: PackedStringArray` | `Array[String]` | Validate the header row; returns a list of errors |
| `validate_row` | `row_data: Dictionary, row_index: int` | `Array[String]` | Validate row data |
| `get_header_indices` | `header_row: PackedStringArray` | `Dictionary` | Field name -> column index mapping |

## Example

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

# Use with the loader
var resource := GDSVLoader.new() \
    .load_file("res://data/items.gdsv") \
    .with_schema(schema) \
    .parse_all()
```
