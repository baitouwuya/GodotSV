# Custom Type Handlers

> [中文版](../../guides/custom-type-handler.md)

This guide explains how to create custom type handlers (`GDSVTypeHandler`) using GDScript, enabling the GDSV editor to support your own data types.

## Overview

GodotSV's type system is extensible. You can inherit from `GDSVTypeHandler` in GDScript to implement custom data parsing, serialization, validation logic, and even custom editor UI.

**Typical use cases**:
- Duration (`1h30m15s` -> seconds)
- Percentage (`75%` -> `0.75`)
- Coordinates (`A3` -> chess board coordinates)
- Custom enums (`Rarity.SSR` -> integer ID)
- Any data requiring special parsing/display logic

## Quick Start: Minimal Implementation

Create a GDScript file that extends `GDSVTypeHandler`:

```gdscript
@tool
class_name GDSVTypePercent
extends GDSVTypeHandler
## Percentage type: converts "75%" to 0.75

func _get_type_name() -> StringName:
    return "percent"

func _get_variant_type() -> int:
    return TYPE_FLOAT

func _get_display_name() -> String:
    return "Percentage"

func _get_category() -> int:
    return GDSVTypeHandler.TYPE_CATEGORY_CUSTOM

func _string_to_variant(input: String) -> Dictionary:
    var trimmed := input.strip_edges()
    if trimmed.is_empty():
        return _ok(0.0)
    if trimmed.ends_with("%"):
        trimmed = trimmed.left(-1)
    if not trimmed.is_valid_float():
        return _error("Invalid percentage: '%s'" % input)
    return _ok(trimmed.to_float() / 100.0)

func _variant_to_string(value: Variant) -> Dictionary:
    if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
        return _error("Value must be a numeric type")
    return _ok("%.0f%%" % (float(value) * 100.0))

func _ok(value: Variant) -> Dictionary:
    return {"success": true, "value": value, "error_message": ""}

func _error(message: String) -> Dictionary:
    return {"success": false, "value": null, "error_message": message}
```

Save the file anywhere in your project (e.g., `res://custom_types/gdsv_type_percent.gd`). GDSV will automatically discover it through scanning.

## Complete API Reference

### Methods That Must Be Overridden

| Method | Return Type | Description |
|--------|-------------|-------------|
| `_get_type_name()` | `StringName` | Unique type identifier, used in CSV type annotations (e.g., `value:duration`) |
| `_string_to_variant(input)` | `Dictionary` | CSV string -> Variant value |
| `_variant_to_string(value)` | `Dictionary` | Variant value -> CSV string |

### Methods Recommended to Override

| Method | Return Type | Default | Description |
|--------|-------------|---------|-------------|
| `_get_variant_type()` | `int` | `TYPE_STRING` | The Godot Variant type used for storage |
| `_get_display_name()` | `String` | Same as type_name | Name displayed in the editor |
| `_get_category()` | `int` | `TYPE_CATEGORY_OTHER` | Type category |
| `_get_description()` | `String` | `""` | Type description text |
| `_get_type_default_value()` | `Variant` | `null` | Default value for this type |

### Optional Methods to Override

| Method | Return Type | Description |
|--------|-------------|-------------|
| `_validate(value, constraints)` | `Dictionary` | Validate whether a value satisfies constraints |
| `_supports_inline_editing()` | `bool` | Whether inline editing is supported (default `true`) |
| `_get_inline_editor_type()` | `String` | Custom inline editor type |
| `_get_editor_config()` | `Dictionary` | Editor configuration parameters |

### Return Value Format

All conversion/validation methods return a unified `Dictionary` format:

```gdscript
# Success
{"success": true, "value": <converted value>, "error_message": ""}

# Failure
{"success": false, "value": null, "error_message": "Error description"}
```

It is recommended to wrap these as helper methods:

```gdscript
func _ok(value: Variant) -> Dictionary:
    return {"success": true, "value": value, "error_message": ""}

func _error(message: String) -> Dictionary:
    return {"success": false, "value": null, "error_message": message}
```

### Type Category Constants

```gdscript
GDSVTypeHandler.TYPE_CATEGORY_BASIC       # Basic types (int, float, bool, string)
GDSVTypeHandler.TYPE_CATEGORY_VECTOR      # Vector types (Vector2, Vector3)
GDSVTypeHandler.TYPE_CATEGORY_COLOR       # Color
GDSVTypeHandler.TYPE_CATEGORY_ARRAY       # Array
GDSVTypeHandler.TYPE_CATEGORY_CONTAINER   # Container (Dictionary)
GDSVTypeHandler.TYPE_CATEGORY_RESOURCE    # Resource (Resource, Node)
GDSVTypeHandler.TYPE_CATEGORY_GEOMETRY    # Geometry (Rect2, AABB)
GDSVTypeHandler.TYPE_CATEGORY_CUSTOM      # Custom types (recommended)
GDSVTypeHandler.TYPE_CATEGORY_OTHER       # Other
```

## Automatic Registration Mechanism

GodotSV automatically discovers and registers type handlers through `GDSVTypeHandlerRegistry`.

**Registration flow**:

1. When the editor starts or `scan_script_types()` is called, it scans all GDScript files that inherit `GDSVTypeHandler` and have a `class_name` declaration.
2. The script is instantiated (triggering `_init()`), and `_get_type_name()` is called to obtain the type identifier.
3. The type handler is registered in the global registry.

**You do not need to register manually**, as long as the following conditions are met:
- The script declares a `class_name`
- The script extends `GDSVTypeHandler`
- The script has the `@tool` annotation

### Manual Registration (Optional)

If you need manual control over registration:

```gdscript
var registry := GDSVTypeHandlerRegistry.get_singleton()
registry.register_script("GDSVTypePercent", "percent")
```

## Custom Editor UI

By default, custom types use a plain text input field in the editor. You can register custom editor widgets through `GDSVEditorRegistry` to provide a better editing experience.

### Editor Factory Registration

Register a custom editor factory in `_init()`:

```gdscript
func _init() -> void:
    GDSVEditorRegistry.register_editor("duration", func(row: int, column: int, config: Dictionary) -> Control:
        return GDSVTypeDuration._create_duration_editor(row, column, config)
    )

static func _create_duration_editor(row: int, column: int, config: Dictionary) -> Control:
    var editor := DurationEditor.new()
    var initial: String = config.get("initial_value", "0")
    editor.set_from_seconds(initial.to_float() if initial.is_valid_float() else 0.0)
    return editor
```

### Editor Widget Conventions

Custom editor widgets must follow these conventions:

| Requirement | Description |
|-------------|-------------|
| `get_value() -> String` | **Must implement**. Returns the current edit value as a string |
| `signal value_changed` | **Must declare**. Emitted when the value changes; the editor uses this signal to auto-save |
| Extends `Control` | Base class requirement for the widget |

### Complete Editor Example

Below is a three-column SpinBox editor for the duration type:

```gdscript
class DurationEditor extends HBoxContainer:
    signal value_changed

    var _h_spin: SpinBox
    var _m_spin: SpinBox
    var _s_spin: SpinBox

    func _init() -> void:
        add_theme_constant_override("separation", 2)
        _h_spin = _make_spin(0, 999, 1, "h")
        _m_spin = _make_spin(0, 59, 1, "m")
        _s_spin = _make_spin(0, 59, 1, "s")

    func get_value() -> String:
        var total: float = _h_spin.value * 3600.0 + _m_spin.value * 60.0 + _s_spin.value
        return str(total)

    func set_from_seconds(total: float) -> void:
        var t: float = absf(total)
        _h_spin.value = int(t / 3600.0)
        t -= _h_spin.value * 3600.0
        _m_spin.value = int(t / 60.0)
        t -= _m_spin.value * 60.0
        _s_spin.value = t

    func _make_spin(min_val: float, max_val: float, step: float, suffix: String) -> SpinBox:
        var spin := SpinBox.new()
        spin.min_value = min_val
        spin.max_value = max_val
        spin.step = step
        spin.suffix = suffix
        spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        spin.custom_minimum_size.x = 70
        spin.value_changed.connect(func(_v: float) -> void: value_changed.emit())
        add_child(spin)
        return spin
```

### Config Parameter Reference

The `config` dictionary received by the factory function contains the following fields:

| Key | Type | Description |
|-----|------|-------------|
| `initial_value` | `String` | Current cell value (as a string) |
| `row` | `int` | Current row number (`-1` in field settings) |
| `column` | `int` | Current column number |

Additionally, `config` includes the complete type definition fields for the column (`type`, `name`, `required`, etc.).

## Complete Example: Duration Type

Below is a complete custom type handler, including type conversion, validation, and custom editor UI:

```gdscript
@tool
class_name GDSVTypeDuration
extends GDSVTypeHandler
## Duration type handler
##
## Converts time strings to seconds (float).
## Supported formats:
##   "90"      -> 90.0 seconds
##   "90s"     -> 90.0 seconds
##   "1.5m"    -> 90.0 seconds
##   "2h"      -> 7200.0 seconds
##   "1h30m"   -> 5400.0 seconds
##   "1h30m15s" -> 5415.0 seconds


# ============================================================
# Must override: Type identifier
# ============================================================

func _get_type_name() -> StringName:
    return "duration"


# ============================================================
# Recommended to override: Metadata
# ============================================================

func _get_variant_type() -> int:
    return TYPE_FLOAT

func _get_display_name() -> String:
    return "Duration"

func _get_category() -> int:
    return GDSVTypeHandler.TYPE_CATEGORY_CUSTOM

func _get_description() -> String:
    return "Time duration, supports formats like 1h30m, 90s, etc. Stored as seconds"

func _get_type_default_value() -> Variant:
    return 0.0


# ============================================================
# Must override: String <-> Variant conversion
# ============================================================

func _string_to_variant(input: String) -> Dictionary:
    var trimmed := input.strip_edges()
    if trimmed.is_empty():
        return _ok(0.0)

    # Pure number: treat directly as seconds
    if trimmed.is_valid_float():
        return _ok(trimmed.to_float())

    # Parse XhYmZs format
    var seconds := 0.0
    var current := ""

    for c in trimmed:
        match c:
            "h", "H":
                if not current.is_valid_float():
                    return _error("Invalid hours value: '%s'" % current)
                seconds += current.to_float() * 3600.0
                current = ""
            "m", "M":
                if not current.is_valid_float():
                    return _error("Invalid minutes value: '%s'" % current)
                seconds += current.to_float() * 60.0
                current = ""
            "s", "S":
                if not current.is_valid_float():
                    return _error("Invalid seconds value: '%s'" % current)
                seconds += current.to_float()
                current = ""
            _:
                current += c

    if not current.is_empty():
        if not current.is_valid_float():
            return _error("Invalid time format: '%s'" % input)
        seconds += current.to_float()

    return _ok(seconds)


func _variant_to_string(value: Variant) -> Dictionary:
    if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
        return _error("Value must be a numeric type")

    var total_seconds: float = float(value)
    if total_seconds < 0:
        return _error("Duration cannot be negative")

    var hours := int(total_seconds / 3600.0)
    var remaining := total_seconds - hours * 3600.0
    var minutes := int(remaining / 60.0)
    var secs := remaining - minutes * 60.0

    var parts := PackedStringArray()
    if hours > 0:
        parts.append("%dh" % hours)
    if minutes > 0:
        parts.append("%dm" % minutes)
    if secs > 0 or parts.is_empty():
        if secs == int(secs):
            parts.append("%ds" % int(secs))
        else:
            parts.append("%.1fs" % secs)

    return _ok("".join(parts))


# ============================================================
# Optional override: Validation
# ============================================================

func _validate(value: Variant, constraints: Dictionary) -> Dictionary:
    if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
        return _error("Duration must be a numeric type")

    var val: float = float(value)
    if val < 0:
        return _error("Duration cannot be negative")

    if constraints.has("min"):
        var min_val: float = float(constraints["min"])
        if val < min_val:
            return _error("Duration %.0fs is below the minimum of %.0fs" % [val, min_val])

    if constraints.has("max"):
        var max_val: float = float(constraints["max"])
        if val > max_val:
            return _error("Duration %.0fs exceeds the maximum of %.0fs" % [val, max_val])

    return _ok(value)


# ============================================================
# Custom editor UI
# ============================================================

func _init() -> void:
    GDSVEditorRegistry.register_editor("duration", func(row: int, column: int, config: Dictionary) -> Control:
        return GDSVTypeDuration._create_duration_editor(row, column, config)
    )


static func _create_duration_editor(row: int, column: int, config: Dictionary) -> Control:
    var editor := DurationEditor.new()
    var initial: String = config.get("initial_value", "0")
    editor.set_from_seconds(initial.to_float() if initial.is_valid_float() else 0.0)
    return editor


class DurationEditor extends HBoxContainer:
    signal value_changed

    var _h_spin: SpinBox
    var _m_spin: SpinBox
    var _s_spin: SpinBox

    func _init() -> void:
        add_theme_constant_override("separation", 2)
        _h_spin = _make_spin(0, 999, 1, "h")
        _m_spin = _make_spin(0, 59, 1, "m")
        _s_spin = _make_spin(0, 59, 1, "s")

    func get_value() -> String:
        var total: float = _h_spin.value * 3600.0 + _m_spin.value * 60.0 + _s_spin.value
        return str(total)

    func set_from_seconds(total: float) -> void:
        var t: float = absf(total)
        _h_spin.value = int(t / 3600.0)
        t -= _h_spin.value * 3600.0
        _m_spin.value = int(t / 60.0)
        t -= _m_spin.value * 60.0
        _s_spin.value = t

    func _make_spin(min_val: float, max_val: float, step: float, suffix: String) -> SpinBox:
        var spin := SpinBox.new()
        spin.min_value = min_val
        spin.max_value = max_val
        spin.step = step
        spin.suffix = suffix
        spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        spin.custom_minimum_size.x = 70
        spin.value_changed.connect(func(_v: float) -> void: value_changed.emit())
        add_child(spin)
        return spin


# ============================================================
# Internal utility methods
# ============================================================

func _ok(value: Variant) -> Dictionary:
    return {"success": true, "value": value, "error_message": ""}

func _error(message: String) -> Dictionary:
    return {"success": false, "value": null, "error_message": message}
```

When using it, annotate the type in the CSV/GDSV header:

```
*id:int	name:string	cooldown:duration
1	Fireball	1h30m
2	Heal	45s
3	Resurrect	2h15m30s
```

## Common Issues and Pitfalls

### 1. The `@tool` Annotation is Required

**Problem**: The custom type handler does not appear in the editor; it cannot be found in the type picker.

**Cause**: GDScript's `@tool` annotation is **not inherited**. Even though the `GDSVTypeHandler` base class is in `@tool` mode on the C++ side, your GDScript subclass must explicitly add `@tool`.

```gdscript
# Correct
@tool
class_name GDSVTypeDuration
extends GDSVTypeHandler

# Wrong: missing @tool, invisible in the editor
class_name GDSVTypeDuration
extends GDSVTypeHandler
```

### 2. A `class_name` Declaration is Required

**Problem**: The type handler is not automatically discovered.

**Cause**: `scan_script_types()` scans for scripts that inherit `GDSVTypeHandler` through Godot's global class registry. Scripts without a `class_name` do not appear in the global class registry.

```gdscript
# Correct
class_name GDSVTypeDuration

# Wrong: no class_name, cannot be auto-scanned
# (the file name does not substitute for class_name)
```

### 3. Method Names Must Start with an Underscore `_`

**Problem**: Overridden methods do not take effect; the type handler behaves unexpectedly.

**Cause**: The C++ base class declares virtual methods via the `GDVIRTUAL` macro, and the GDScript override points are named with a `_` prefix. If you write `get_type_name()` instead of `_get_type_name()`, the C++ side will not call your implementation.

```gdscript
# Correct: with underscore prefix
func _get_type_name() -> StringName:
    return "duration"

func _string_to_variant(input: String) -> Dictionary:
    # ...

# Wrong: no underscore, C++ side will not call this
func get_type_name() -> StringName:
    return "duration"
```

### 4. Return Values Must Be in Dictionary Format

**Problem**: Type conversion throws errors or returns `null`.

**Cause**: `_string_to_variant()`, `_variant_to_string()`, and `_validate()` must return a specifically formatted Dictionary, not a direct value.

```gdscript
# Correct: returns a Dictionary
func _string_to_variant(input: String) -> Dictionary:
    return {"success": true, "value": input.to_float(), "error_message": ""}

# Wrong: returns a value directly
func _string_to_variant(input: String) -> float:
    return input.to_float()
```

### 5. Custom Editors Must Have `get_value()` and a `value_changed` Signal

**Problem**: The custom editor displays correctly, but edited values are not saved to the cell.

**Cause**: The GDSV editor reads and monitors custom editor values through the following conventions:
- `get_value() -> String`: reads the current edit value
- `signal value_changed`: triggers auto-save when the value changes

Missing either convention will result in data loss.

```gdscript
class MyEditor extends HBoxContainer:
    # Must declare this signal
    signal value_changed

    # Must implement this method
    func get_value() -> String:
        return str(_spin.value)

    func _init() -> void:
        var spin := SpinBox.new()
        # Must connect the signal
        spin.value_changed.connect(func(_v: float) -> void:
            value_changed.emit()
        )
        add_child(spin)
```

### 6. Do Not Pass Static Method References Directly to Editor Factories

**Problem**: Crashes or `Invalid callable` errors when registering a custom editor.

**Cause**: In some GDScript versions, passing `GDSVTypeDuration._create_duration_editor` as a Callable may be unstable. Use a lambda wrapper instead.

```gdscript
# Correct: wrapped with a lambda
func _init() -> void:
    GDSVEditorRegistry.register_editor("duration",
        func(row: int, column: int, config: Dictionary) -> Control:
            return GDSVTypeDuration._create_duration_editor(row, column, config)
    )

# Potentially unstable: passing a static method reference directly
func _init() -> void:
    GDSVEditorRegistry.register_editor("duration",
        GDSVTypeDuration._create_duration_editor
    )
```

### 7. `_get_variant_type()` Must Return a `TYPE_*` Constant

**Problem**: The editor cannot recognize the type; the field settings dialog displays incorrectly.

**Cause**: `_get_variant_type()` should return a Godot built-in `TYPE_*` enum value (`TYPE_INT`, `TYPE_FLOAT`, `TYPE_STRING`, etc.), not a custom integer.

```gdscript
# Correct
func _get_variant_type() -> int:
    return TYPE_FLOAT

# Wrong: returning an arbitrary number
func _get_variant_type() -> int:
    return 42
```

### 8. `_get_type_name()` Must Not Conflict with Built-in Type Names

**Problem**: The custom type overrides a built-in type, causing int/float/bool and other basic types to behave unexpectedly.

**Cause**: Type names are globally unique. If your custom type name matches a built-in type (e.g., `"int"`, `"float"`, `"string"`), it will replace the built-in handler.

```gdscript
# Correct: use a unique type name
func _get_type_name() -> StringName:
    return "duration"

# Wrong: conflicts with a built-in type name
func _get_type_name() -> StringName:
    return "float"
```

## Recommended File Placement

```
your_project/
├── custom_types/                    # Custom type handlers directory
│   ├── gdsv_type_duration.gd       # Duration type
│   ├── gdsv_type_percent.gd        # Percentage type
│   └── gdsv_type_coordinate.gd     # Coordinate type
├── addons/
│   └── GodotSV/                    # GodotSV plugin
└── ...
```

Custom type files can be placed anywhere in your project. As long as they satisfy the three conditions -- `@tool` + `class_name` + `extends GDSVTypeHandler` -- they will be automatically scanned and registered.

## Next Steps

- [GDSV Format and Type Annotations](./gdsv-format.md): Learn how to use custom types in GDSV files
- [Editor Integration](./editor-integration.md): Learn about the built-in GDSV editor
- [API Overview](../api/index.md): View the complete API documentation
