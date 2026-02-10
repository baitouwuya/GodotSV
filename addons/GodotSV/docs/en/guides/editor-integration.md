> [中文版](../../guides/editor-integration.md)

# Editor Integration & Import

## Opening GDSV Files

Double-click a `.gdsv` file in Godot's FileSystem panel to automatically open the built-in table editor.

## Table Editor Features

### Basic Editing

- **Cell Editing** -- Double-click a cell to edit directly; supports custom type editors
- **Row Operations** -- Insert rows, delete rows, move rows (drag-and-drop reordering)
- **Column Operations** -- Insert columns, delete columns, move columns, rename columns
- **Undo/Redo** -- Full Ctrl+Z / Ctrl+Y support

### Search & Replace

- **Search** -- Search across the entire table or by column; supports case sensitivity and regular expressions
- **Replace** -- Replace individually or replace all
- **Filter** -- Filter displayed rows by conditions

### Data Validation

- **Real-time Validation** -- Automatically checks type constraints while editing
- **Batch Validation** -- Validates the entire table and highlights error cells
- **Type Annotations** -- Headers display field type information

### Column Settings

Right-click on a header to open the column settings dialog, where you can configure:

- Column name
- Data type (choose from 35 built-in types + custom types)
- Required flag
- Default value
- Constraints (min/max values, length limits, regex patterns, enum values)
- Array element type

## CSV/TSV Import

Drag a `.csv` or `.tsv` file into the project, and the import plugin handles it automatically:

1. Infers the delimiter from the file extension (`.csv` -> `,`, `.tsv` -> `\t`)
2. Parses the file contents
3. Imports as a Godot Resource, which can be loaded in code via `GDSVLoader`

### Import Settings

The following can be configured in the import panel:

- Whether the file has a header
- Delimiter override
- Schema binding

## Schema Management

### Creating a Schema in Code

```gdscript
var schema := GDSVSchema.new()

schema.add_field("id", GDSVFieldDefinition.FieldType.TYPE_INT) \
    .with_required(true) \
    .with_unique(true)

schema.add_field("name", GDSVFieldDefinition.FieldType.TYPE_STRING) \
    .with_required(true)

schema.add_field("price", GDSVFieldDefinition.FieldType.TYPE_FLOAT) \
    .with_range(0, 99999)
```

### Inline Header Annotations (No Schema Required)

A more lightweight approach -- annotate types directly in the GDSV header:

```
*id:int	name:string	price:float=0	rarity:enum(common,rare,epic)
```

These two approaches can be combined -- header annotations provide basic type information, while schemas provide more complex validation rules.

## Custom Type Editors

Custom types can register dedicated editor controls. For example, a three-column SpinBox editor for a `duration` type:

```gdscript
GDSVEditorRegistry.register_editor("duration",
    func(row: int, column: int, config: Dictionary) -> Control:
        return MyDurationEditor.new()
)
```

See: [Custom Type Handlers](./custom-type-handler.md)

## Next Steps

- [Best Practices](./best-practices.md) -- Data organization and performance tips
- [Custom Type Handlers](./custom-type-handler.md) -- Extend the type system
