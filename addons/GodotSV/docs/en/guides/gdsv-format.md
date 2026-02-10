> [中文版](../../guides/gdsv-format.md)

# GDSV Format & Type Annotations

## Basic Format

GDSV uses **Tab-delimited** format by default, with the first row as the header. It is compatible with the RFC 4180 CSV specification.

```
*id:int	name:string	active:bool=false	health:float=100
1	Alice	true	85.5
2	Bob	false	72.3
```

## Comments & Blank Lines

- Lines starting with `#` are treated as comments and ignored
- Blank lines are skipped and not parsed

```
# Character data table
# Last updated: 2024-01

*id:int	name:string	health:float
1	Alice	85.5

# Bob has been retired
2	Bob	72.3
```

## Type Annotation Syntax

Use the `field:type` syntax in the header to specify field types:

| Syntax | Description | Example |
|--------|-------------|---------|
| `field:type` | Specify type | `health:float` |
| `*field:type` | Required field | `*id:int` |
| `field:type=value` | Default value | `active:bool=false` |
| `field:enum(v1,v2,v3)` | Enum constraint | `rarity:enum(common,rare,epic)` |
| `field:Array[Type]` | Array element type | `tags:Array[string]` |
| `field` | No annotation (defaults to string) | `name` |

## Value Formats

GDSV supports two value formats, which can be mixed:

### GDSV Compact Format (Recommended)

Comma-separated numeric sequences without type names:

```
1,2,3          -> Vector3(1, 2, 3)
255,0,0,255    -> Color(1, 0, 0, 1)
0,0,100,50     -> Rect2(0, 0, 100, 50)
```

### Godot Native Format (Compatible)

Full Godot constructor syntax:

```
Vector3(1, 2, 3)
Color(1, 0, 0, 1)
Rect2(0, 0, 100, 50)
```

## Supported Types

### Basic Types

| Type Identifier | Godot Type | Example Values |
|-----------------|-----------|----------------|
| `int` | `int` | `42`, `-1` |
| `float` | `float` | `3.14`, `-0.5` |
| `bool` | `bool` | `true`, `false`, `1`, `0` |
| `string` | `String` | `hello world` |
| `StringName` | `StringName` | `my_name` |
| `enum` | `String` | Enum values (requires `enum(...)` constraint) |

### Vectors & Rectangles

| Type Identifier | Value Format |
|-----------------|-------------|
| `Vector2` | `x,y` |
| `Vector3` | `x,y,z` |
| `Vector4` | `x,y,z,w` |
| `Vector2i` | `x,y` (integers) |
| `Vector3i` | `x,y,z` (integers) |
| `Vector4i` | `x,y,z,w` (integers) |
| `Rect2` | `x,y,w,h` |
| `Rect2i` | `x,y,w,h` (integers) |

### Color

| Type Identifier | Value Format |
|-----------------|-------------|
| `Color` | `r,g,b,a` (0-255 integers or 0.0-1.0 floats) |

### Geometry Types

| Type Identifier | Value Format |
|-----------------|-------------|
| `Quaternion` | `x,y,z,w` |
| `Plane` | `nx,ny,nz,d` |
| `AABB` | `px,py,pz,sx,sy,sz` |
| `Basis` | 9 floats |
| `Transform2D` | 6 floats |
| `Transform3D` | 12 floats |
| `Projection` | 16 floats |

### Containers & Resources

| Type Identifier | Value Format |
|-----------------|-------------|
| `Array` | `a,b,c` (comma-separated) |
| `NodePath` | `path/to/node` |
| `Resource` | `res://path/to/resource.tres` |

### PackedArray

| Type Identifier | Value Format |
|-----------------|-------------|
| `PackedByteArray` | `1,2,3` |
| `PackedInt32Array` / `PackedInt64Array` | `1,2,3` |
| `PackedFloat32Array` / `PackedFloat64Array` | `1.0,2.0` |
| `PackedStringArray` | `a,b,c` |
| `PackedVector2Array` | `x,y;x,y` (semicolon-separated elements) |
| `PackedVector3Array` | `x,y,z;x,y,z` |
| `PackedVector4Array` | `x,y,z,w;x,y,z,w` |
| `PackedColorArray` | `r,g,b,a;r,g,b,a` |

## Quoting & Escaping

- Fields containing delimiters, newlines, or double quotes must be enclosed in double quotes
- Double quotes within quoted fields are escaped with `""` (doubled)

```
id	name	desc
1	Alice	"She said ""hello"""
2	Bob	"Line 1
Line 2"
```

## Full Example

```
# RPG item database
# Format: GDSV (Tab-delimited)

*id:int	name:string	type:enum(weapon,armor,potion)	price:float=0	damage:Vector2=0,0	color:Color	tags:Array[string]
1	Iron Sword	weapon	150.0	10,25	200,200,200,255	melee,basic
2	Fire Staff	weapon	500.0	20,40	255,100,0,255	magic,fire
3	Health Potion	potion	50.0	0,0	0,255,0,255	consumable
```

## Next Steps

- [Custom Type Handlers](./custom-type-handler.md) -- Add custom types (e.g., duration, percentage)
- [API Overview](../api/index.md) -- View parser and type converter interfaces
- [Type System API](../api/type-system.md) -- Detailed list of 35 built-in type handlers
