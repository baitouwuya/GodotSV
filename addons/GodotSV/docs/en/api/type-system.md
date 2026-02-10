# Type System API

> [中文版](../../api/type-system.md)

The GodotSV extensible type system consists of three components: `GDSVTypeHandler` (type handler base class), `GDSVTypeHandlerRegistry` (registry singleton), and `GDSVEditorRegistry` (editor factory registry).

---

## GDSVTypeHandler

Base class for all type handlers (C++ `RefCounted`). Includes 35 built-in type handlers and supports extension via GDScript inheritance.

### Type Category Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `TYPE_CATEGORY_BASIC` | 0 | Basic types (int, float, bool, string) |
| `TYPE_CATEGORY_VECTOR` | 1 | Vector types (Vector2, Vector3, Vector4) |
| `TYPE_CATEGORY_COLOR` | 2 | Color |
| `TYPE_CATEGORY_ARRAY` | 3 | Array |
| `TYPE_CATEGORY_CONTAINER` | 4 | Container |
| `TYPE_CATEGORY_RESOURCE` | 5 | Resource |
| `TYPE_CATEGORY_GEOMETRY` | 6 | Geometry (Rect2, AABB, Transform) |
| `TYPE_CATEGORY_CUSTOM` | 7 | Custom types |
| `TYPE_CATEGORY_OTHER` | 8 | Other |

### Public Methods

| Method | Return Type | Description |
|--------|-------------|-------------|
| `get_metadata_dictionary` | `Dictionary` | Returns type metadata (type_name, variant_type, display_name, category, description) |

### GDScript Virtual Methods (Override When Inheriting)

Method names must start with `_`, otherwise the C++ side will not invoke them.

#### Required Overrides

| Method | Return Type | Description |
|--------|-------------|-------------|
| `_get_type_name` | `StringName` | Unique type identifier (e.g., `"duration"`) |
| `_string_to_variant` | `Dictionary` | String to Variant conversion |
| `_variant_to_string` | `Dictionary` | Variant to String conversion |

#### Recommended Overrides

| Method | Return Type | Default | Description |
|--------|-------------|---------|-------------|
| `_get_variant_type` | `int` | `TYPE_STRING` | Godot Variant type enum |
| `_get_display_name` | `String` | Same as type_name | Display name in the editor |
| `_get_category` | `int` | `TYPE_CATEGORY_OTHER` | Type category |
| `_get_description` | `String` | `""` | Type description |
| `_get_type_default_value` | `Variant` | `null` | Default value |

#### Optional Overrides

| Method | Return Type | Description |
|--------|-------------|-------------|
| `_validate` | `Dictionary` | Validate whether a value satisfies constraints |
| `_supports_inline_editing` | `bool` | Whether inline editing is supported (default `true`) |
| `_get_inline_editor_type` | `String` | Editor control type |
| `_get_editor_config` | `Dictionary` | Editor configuration |

### Return Value Format

All conversion/validation methods return a unified `Dictionary`:

```gdscript
# Success
{"success": true, "value": <converted value>, "error_message": ""}

# Failure
{"success": false, "value": null, "error_message": "Error description"}
```

---

## GDSVTypeHandlerRegistry

Type handler registry (`Object` singleton) that manages the registration and lookup of all type handlers. Thread-safe.

### Getting the Singleton

```gdscript
var registry := GDSVTypeHandlerRegistry.get_singleton()
```

### Methods

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `get_singleton` | — | `GDSVTypeHandlerRegistry` | Get the singleton instance (static method) |
| `get_type` | `type_name: StringName` | `GDSVTypeHandler` | Get a type handler by name |
| `has_type` | `type_name: StringName` | `bool` | Whether a type is registered |
| `get_all_types` | — | `Array[StringName]` | All registered type names |
| `get_types_by_category` | `category: String` | `Array[StringName]` | Query types by category |
| `register_type` | `type: GDSVTypeHandler` | `void` | Register a type handler instance |
| `register_type_by_name` | `type_name: StringName, class_name: StringName` | `void` | Register by class name |
| `register_script` | `class_name: StringName, type_name: StringName` | `void` | Register a GDScript type |
| `unregister_type` | `type_name: StringName` | `void` | Unregister a type |
| `scan_script_types` | — | `void` | Scan and register all GDScript classes inheriting GDSVTypeHandler |

### Auto-Discovery

C++ type handlers are automatically discovered via `ClassDB` at startup. GDScript types are auto-scanned and registered if they meet three conditions:

1. Include the `@tool` annotation
2. Declare a `class_name`
3. Extend `GDSVTypeHandler`

---

## GDSVEditorRegistry

Editor factory registry (GDScript singleton) that manages the creation of custom cell editors.

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `get_singleton` | — | `GDSVEditorRegistry` | Get the singleton instance (static method) |
| `register_editor` | `type_name: String, factory: Callable` | `void` | Register an editor factory |
| `unregister_editor` | `type_name: String` | `void` | Unregister an editor |
| `has_editor` | `type_name: String` | `bool` | Whether an editor is registered |
| `create_editor` | `type_name: String, row: int, column: int, config: Dictionary` | `Control` | Create an editor instance |
| `get_registered_types` | — | `PackedStringArray` | All registered types |
| `clear` | — | `void` | Clear all registrations |

### Factory Function Signature

```gdscript
func(row: int, column: int, config: Dictionary) -> Control
```

### Editor Control Requirements

| Requirement | Description |
|-------------|-------------|
| `get_value() -> String` | Must be implemented; returns the current value as a string |
| `signal value_changed` | Must be declared; triggers auto-save when the value changes |
| Extends `Control` | Base class requirement for editor controls |

---

## Built-in Type Handler Reference

| Category | Type Identifier | Variant Type | Example Value Format |
|----------|-----------------|--------------|----------------------|
| Basic | `int` | `TYPE_INT` | `42` |
| Basic | `float` | `TYPE_FLOAT` | `3.14` |
| Basic | `bool` | `TYPE_BOOL` | `true` / `false` / `1` / `0` |
| Basic | `string` | `TYPE_STRING` | `hello` |
| Basic | `StringName` | `TYPE_STRING_NAME` | `hello` |
| Basic | `enum` | `TYPE_STRING` | Enum value string |
| Vector | `Vector2` | `TYPE_VECTOR2` | `1,2` or `Vector2(1, 2)` |
| Vector | `Vector3` | `TYPE_VECTOR3` | `1,2,3` or `Vector3(1, 2, 3)` |
| Vector | `Vector4` | `TYPE_VECTOR4` | `1,2,3,4` |
| Vector | `Vector2i` | `TYPE_VECTOR2I` | `1,2` |
| Vector | `Vector3i` | `TYPE_VECTOR3I` | `1,2,3` |
| Vector | `Vector4i` | `TYPE_VECTOR4I` | `1,2,3,4` |
| Rect | `Rect2` | `TYPE_RECT2` | `0,0,100,50` |
| Rect | `Rect2i` | `TYPE_RECT2I` | `0,0,100,50` |
| Color | `Color` | `TYPE_COLOR` | `255,0,0,255` or `Color(1, 0, 0, 1)` |
| Geometry | `Quaternion` | `TYPE_QUATERNION` | `0,0,0,1` |
| Geometry | `Plane` | `TYPE_PLANE` | `0,1,0,0` |
| Geometry | `AABB` | `TYPE_AABB` | `0,0,0,1,1,1` |
| Geometry | `Basis` | `TYPE_BASIS` | 9 floats |
| Geometry | `Transform2D` | `TYPE_TRANSFORM2D` | 6 floats |
| Geometry | `Transform3D` | `TYPE_TRANSFORM3D` | 12 floats |
| Geometry | `Projection` | `TYPE_PROJECTION` | 16 floats |
| Container | `Array` | `TYPE_ARRAY` | `a,b,c` |
| Container | `NodePath` | `TYPE_NODE_PATH` | `path/to/node` |
| Resource | `Resource` | `TYPE_OBJECT` | `res://path.tres` |
| PackedArray | `PackedByteArray` | `TYPE_PACKED_BYTE_ARRAY` | `1,2,3` |
| PackedArray | `PackedInt32Array` | `TYPE_PACKED_INT32_ARRAY` | `1,2,3` |
| PackedArray | `PackedInt64Array` | `TYPE_PACKED_INT64_ARRAY` | `1,2,3` |
| PackedArray | `PackedFloat32Array` | `TYPE_PACKED_FLOAT32_ARRAY` | `1.0,2.0` |
| PackedArray | `PackedFloat64Array` | `TYPE_PACKED_FLOAT64_ARRAY` | `1.0,2.0` |
| PackedArray | `PackedStringArray` | `TYPE_PACKED_STRING_ARRAY` | `a,b,c` |
| PackedArray | `PackedVector2Array` | `TYPE_PACKED_VECTOR2_ARRAY` | `1,2;3,4` |
| PackedArray | `PackedVector3Array` | `TYPE_PACKED_VECTOR3_ARRAY` | `1,2,3;4,5,6` |
| PackedArray | `PackedVector4Array` | `TYPE_PACKED_VECTOR4_ARRAY` | `1,2,3,4;5,6,7,8` |
| PackedArray | `PackedColorArray` | `TYPE_PACKED_COLOR_ARRAY` | `1,0,0,1;0,1,0,1` |
