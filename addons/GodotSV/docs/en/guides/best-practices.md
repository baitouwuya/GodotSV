# Best Practices

> [中文版](../../guides/best-practices.md)

## Data Format

### Prefer the GDSV Format

- Use the `.gdsv` extension with Tab-separated values by default
- Tab separation avoids ambiguity with commas in vector/color values
- Add type annotations in headers to let the parser handle type conversion automatically

```
*id:int	name:string	active:bool=false	pos:Vector2=0,0
1	Alice	true	100,200
2	Bob	false	300,400
```

### Header Design Principles

- Mark required fields with a `*` prefix
- Set reasonable default values to reduce data redundancy
- Use `enum()` constraints to restrict allowed values

## Schema First

For critical data, it is recommended to define a Schema rather than relying solely on header annotations:

```gdscript
var schema := GDSVSchema.new()
schema.add_field("id", GDSVFieldDefinition.FieldType.TYPE_INT) \
    .with_required(true) \
    .with_unique(true)

schema.add_field("name", GDSVFieldDefinition.FieldType.TYPE_STRING) \
    .with_required(true)

var resource := GDSVLoader.new() \
    .load_file("res://data/items.gdsv") \
    .with_schema(schema) \
    .parse_all()
```

Schemas provide functionality that header annotations cannot: unique constraints, regex pattern validation, and cross-row checks.

## Large File Handling

### Streaming

For files exceeding 1000 rows, it is recommended to use `stream()` instead of `parse_all()`:

```gdscript
var reader := GDSVLoader.new() \
    .load_file("res://data/huge.gdsv") \
    .with_header(true) \
    .stream()

while reader.has_next():
    var row: Dictionary = reader.next()
    process_row(row)

reader.close()
```

### Cache Management

Results from `parse_all()` are automatically cached (LRU, up to 10 files). To free memory when needed:

```gdscript
GDSVLoader.clear_cache()
```

## Error Handling

Always check the load result:

```gdscript
var resource := GDSVLoader.new() \
    .load_file(path) \
    .parse_all()

if resource.has_errors():
    for error in resource.get_errors():
        push_error("GDSV: " + error)
    return

if resource.has_warnings():
    for warning in resource.get_warnings():
        push_warning("GDSV: " + warning)
```

## Recommended Project Structure

```
your_project/
├── data/                           # Data files
│   ├── characters.gdsv
│   ├── items.gdsv
│   └── levels.gdsv
├── schemas/                        # Schema resources
│   ├── character_schema.tres
│   └── item_schema.tres
├── custom_types/                   # Custom type handlers
│   ├── gdsv_type_duration.gd
│   └── gdsv_type_percent.gd
└── addons/
    └── GodotSV/                    # Plugin
```

## Type-Safe Reading

Prefer type-safe getter methods to avoid manual type conversion:

```gdscript
# Recommended: type-safe
var hp: int = resource.get_int(i, "health", 100)
var name: String = resource.get_string(i, "name", "Unknown")

# Not recommended: manual conversion
var hp: int = int(resource.get_value(i, "health"))
```

## Export Considerations

- Ensure `.gdsv` / `.csv` / `.tsv` files are not excluded by the export settings
- The GDExtension DLL must be included in the export
- Custom type handler scripts (`.gd`) must also be included in the export
