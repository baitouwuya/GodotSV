# GDSV 格式与类型注解

## 基本格式

GDSV 默认使用 **Tab 分隔**，第一行为表头。兼容 RFC 4180 CSV 规范。

```
*id:int	name:string	active:bool=false	health:float=100
1	Alice	true	85.5
2	Bob	false	72.3
```

## 注释与空行

- `#` 开头的行视为注释，被忽略
- 空行被跳过，不参与解析

```
# 角色数据表
# 最后更新：2024-01

*id:int	name:string	health:float
1	Alice	85.5

# Bob 已退役
2	Bob	72.3
```

## 类型注解语法

在表头中使用 `field:type` 语法指定字段类型：

| 语法 | 说明 | 示例 |
|------|------|------|
| `field:type` | 指定类型 | `health:float` |
| `*field:type` | 必需字段 | `*id:int` |
| `field:type=value` | 默认值 | `active:bool=false` |
| `field:enum(v1,v2,v3)` | 枚举约束 | `rarity:enum(common,rare,epic)` |
| `field:Array[Type]` | 数组元素类型 | `tags:Array[string]` |
| `field` | 无注解（默认 string） | `name` |

## 值格式

GDSV 支持两种值格式，可以混用：

### GDSV 紧凑格式（推荐）

逗号分隔的数值序列，不含类型名：

```
1,2,3          → Vector3(1, 2, 3)
255,0,0,255    → Color(1, 0, 0, 1)
0,0,100,50     → Rect2(0, 0, 100, 50)
```

### Godot 原生格式（兼容）

完整的 Godot 构造语法：

```
Vector3(1, 2, 3)
Color(1, 0, 0, 1)
Rect2(0, 0, 100, 50)
```

## 支持的类型

### 基础类型

| 类型标识 | Godot 类型 | 值示例 |
|----------|-----------|--------|
| `int` | `int` | `42`, `-1` |
| `float` | `float` | `3.14`, `-0.5` |
| `bool` | `bool` | `true`, `false`, `1`, `0` |
| `string` | `String` | `hello world` |
| `StringName` | `StringName` | `my_name` |
| `enum` | `String` | 枚举值（需配合 `enum(...)` 约束） |

### 向量与矩形

| 类型标识 | 值格式 |
|----------|--------|
| `Vector2` | `x,y` |
| `Vector3` | `x,y,z` |
| `Vector4` | `x,y,z,w` |
| `Vector2i` | `x,y`（整数） |
| `Vector3i` | `x,y,z`（整数） |
| `Vector4i` | `x,y,z,w`（整数） |
| `Rect2` | `x,y,w,h` |
| `Rect2i` | `x,y,w,h`（整数） |

### 颜色

| 类型标识 | 值格式 |
|----------|--------|
| `Color` | `r,g,b,a`（0-255 整数或 0.0-1.0 浮点） |

### 几何类型

| 类型标识 | 值格式 |
|----------|--------|
| `Quaternion` | `x,y,z,w` |
| `Plane` | `nx,ny,nz,d` |
| `AABB` | `px,py,pz,sx,sy,sz` |
| `Basis` | 9 个浮点数 |
| `Transform2D` | 6 个浮点数 |
| `Transform3D` | 12 个浮点数 |
| `Projection` | 16 个浮点数 |

### 容器与资源

| 类型标识 | 值格式 |
|----------|--------|
| `Array` | `a,b,c`（逗号分隔） |
| `NodePath` | `path/to/node` |
| `Resource` | `res://path/to/resource.tres` |

### PackedArray

| 类型标识 | 值格式 |
|----------|--------|
| `PackedByteArray` | `1,2,3` |
| `PackedInt32Array` / `PackedInt64Array` | `1,2,3` |
| `PackedFloat32Array` / `PackedFloat64Array` | `1.0,2.0` |
| `PackedStringArray` | `a,b,c` |
| `PackedVector2Array` | `x,y;x,y`（分号分隔元素） |
| `PackedVector3Array` | `x,y,z;x,y,z` |
| `PackedVector4Array` | `x,y,z,w;x,y,z,w` |
| `PackedColorArray` | `r,g,b,a;r,g,b,a` |

## 引号与转义

- 包含分隔符、换行或双引号的字段用双引号包裹
- 双引号内的双引号用 `""` 转义

```
id	name	desc
1	Alice	"She said ""hello"""
2	Bob	"Line 1
Line 2"
```

## 完整示例

```
# RPG 道具数据库
# 格式：GDSV (Tab 分隔)

*id:int	name:string	type:enum(weapon,armor,potion)	price:float=0	damage:Vector2=0,0	color:Color	tags:Array[string]
1	Iron Sword	weapon	150.0	10,25	200,200,200,255	melee,basic
2	Fire Staff	weapon	500.0	20,40	255,100,0,255	magic,fire
3	Health Potion	potion	50.0	0,0	0,255,0,255	consumable
```

## 下一步

- [自定义类型处理器](./custom-type-handler.md) — 添加自定义类型（如持续时间、百分比）
- [API 总览](../api/index.md) — 查看解析器和类型转换器接口
- [类型系统 API](../api/type-system.md) — 35 种内置类型处理器详细列表
