# 类型系统 API

GodotSV 的可扩展类型系统由三部分组成：`GDSVTypeHandler`（类型处理器基类）、`GDSVTypeHandlerRegistry`（注册表单例）和 `GDSVEditorRegistry`（编辑器工厂注册表）。

---

## GDSVTypeHandler

所有类型处理器的基类（C++ `RefCounted`）。内置 35 个类型处理器，支持 GDScript 继承扩展。

### 类型分类常量

| 常量 | 值 | 说明 |
|------|----|------|
| `TYPE_CATEGORY_BASIC` | 0 | 基本类型（int, float, bool, string） |
| `TYPE_CATEGORY_VECTOR` | 1 | 向量类型（Vector2, Vector3, Vector4） |
| `TYPE_CATEGORY_COLOR` | 2 | 颜色 |
| `TYPE_CATEGORY_ARRAY` | 3 | 数组 |
| `TYPE_CATEGORY_CONTAINER` | 4 | 容器 |
| `TYPE_CATEGORY_RESOURCE` | 5 | 资源 |
| `TYPE_CATEGORY_GEOMETRY` | 6 | 几何（Rect2, AABB, Transform） |
| `TYPE_CATEGORY_CUSTOM` | 7 | 自定义类型 |
| `TYPE_CATEGORY_OTHER` | 8 | 其他 |

### 公共方法

| 方法 | 返回类型 | 说明 |
|------|----------|------|
| `get_metadata_dictionary` | `Dictionary` | 返回类型元数据（type_name, variant_type, display_name, category, description） |

### GDScript 虚方法（继承重写）

方法名必须以 `_` 开头，否则 C++ 端不会调用。

#### 必须重写

| 方法 | 返回类型 | 说明 |
|------|----------|------|
| `_get_type_name` | `StringName` | 唯一类型标识（如 `"duration"`） |
| `_string_to_variant` | `Dictionary` | 字符串 → Variant 转换 |
| `_variant_to_string` | `Dictionary` | Variant → 字符串转换 |

#### 建议重写

| 方法 | 返回类型 | 默认值 | 说明 |
|------|----------|--------|------|
| `_get_variant_type` | `int` | `TYPE_STRING` | Godot Variant 类型枚举 |
| `_get_display_name` | `String` | 同 type_name | 编辑器显示名称 |
| `_get_category` | `int` | `TYPE_CATEGORY_OTHER` | 类型分类 |
| `_get_description` | `String` | `""` | 类型描述 |
| `_get_type_default_value` | `Variant` | `null` | 默认值 |

#### 可选重写

| 方法 | 返回类型 | 说明 |
|------|----------|------|
| `_validate` | `Dictionary` | 验证值是否满足约束 |
| `_supports_inline_editing` | `bool` | 是否支持行内编辑（默认 `true`） |
| `_get_inline_editor_type` | `String` | 编辑器控件类型 |
| `_get_editor_config` | `Dictionary` | 编辑器配置 |

### 返回值格式

所有转换/验证方法返回统一的 `Dictionary`：

```gdscript
# 成功
{"success": true, "value": <转换后的值>, "error_message": ""}

# 失败
{"success": false, "value": null, "error_message": "错误描述"}
```

---

## GDSVTypeHandlerRegistry

类型处理器注册表（`Object` 单例），管理所有类型处理器的注册和查询。线程安全。

### 获取单例

```gdscript
var registry := GDSVTypeHandlerRegistry.get_singleton()
```

### 方法

| 方法 | 参数 | 返回类型 | 说明 |
|------|------|----------|------|
| `get_singleton` | — | `GDSVTypeHandlerRegistry` | 获取单例（静态方法） |
| `get_type` | `type_name: StringName` | `GDSVTypeHandler` | 按名称获取类型处理器 |
| `has_type` | `type_name: StringName` | `bool` | 类型是否已注册 |
| `get_all_types` | — | `Array[StringName]` | 所有已注册类型名 |
| `get_types_by_category` | `category: String` | `Array[StringName]` | 按分类查询类型 |
| `register_type` | `type: GDSVTypeHandler` | `void` | 注册类型处理器实例 |
| `register_type_by_name` | `type_name: StringName, class_name: StringName` | `void` | 按类名注册 |
| `register_script` | `class_name: StringName, type_name: StringName` | `void` | 注册 GDScript 类型 |
| `unregister_type` | `type_name: StringName` | `void` | 注销类型 |
| `scan_script_types` | — | `void` | 扫描并注册所有继承 GDSVTypeHandler 的 GDScript |

### 自动发现

启动时自动通过 `ClassDB` 发现 C++ 类型处理器。GDScript 类型需满足三个条件即可自动扫描注册：

1. 添加 `@tool` 注解
2. 声明 `class_name`
3. 继承 `GDSVTypeHandler`

---

## GDSVEditorRegistry

编辑器工厂注册表（GDScript 单例），管理自定义单元格编辑器的创建。

| 方法 | 参数 | 返回类型 | 说明 |
|------|------|----------|------|
| `get_singleton` | — | `GDSVEditorRegistry` | 获取单例（静态方法） |
| `register_editor` | `type_name: String, factory: Callable` | `void` | 注册编辑器工厂 |
| `unregister_editor` | `type_name: String` | `void` | 注销编辑器 |
| `has_editor` | `type_name: String` | `bool` | 是否已注册 |
| `create_editor` | `type_name: String, row: int, column: int, config: Dictionary` | `Control` | 创建编辑器实例 |
| `get_registered_types` | — | `PackedStringArray` | 所有已注册类型 |
| `clear` | — | `void` | 清空所有注册 |

### 工厂函数签名

```gdscript
func(row: int, column: int, config: Dictionary) -> Control
```

### 编辑器控件约定

| 要求 | 说明 |
|------|------|
| `get_value() -> String` | 必须实现，返回当前值的字符串形式 |
| `signal value_changed` | 必须声明，值变化时触发自动保存 |
| 继承 `Control` | 控件基类要求 |

---

## 内置类型处理器一览

| 分类 | 类型标识 | Variant 类型 | 值格式示例 |
|------|----------|-------------|-----------|
| 基础 | `int` | `TYPE_INT` | `42` |
| 基础 | `float` | `TYPE_FLOAT` | `3.14` |
| 基础 | `bool` | `TYPE_BOOL` | `true` / `false` / `1` / `0` |
| 基础 | `string` | `TYPE_STRING` | `hello` |
| 基础 | `StringName` | `TYPE_STRING_NAME` | `hello` |
| 基础 | `enum` | `TYPE_STRING` | 枚举值字符串 |
| 向量 | `Vector2` | `TYPE_VECTOR2` | `1,2` 或 `Vector2(1, 2)` |
| 向量 | `Vector3` | `TYPE_VECTOR3` | `1,2,3` 或 `Vector3(1, 2, 3)` |
| 向量 | `Vector4` | `TYPE_VECTOR4` | `1,2,3,4` |
| 向量 | `Vector2i` | `TYPE_VECTOR2I` | `1,2` |
| 向量 | `Vector3i` | `TYPE_VECTOR3I` | `1,2,3` |
| 向量 | `Vector4i` | `TYPE_VECTOR4I` | `1,2,3,4` |
| 矩形 | `Rect2` | `TYPE_RECT2` | `0,0,100,50` |
| 矩形 | `Rect2i` | `TYPE_RECT2I` | `0,0,100,50` |
| 颜色 | `Color` | `TYPE_COLOR` | `255,0,0,255` 或 `Color(1, 0, 0, 1)` |
| 几何 | `Quaternion` | `TYPE_QUATERNION` | `0,0,0,1` |
| 几何 | `Plane` | `TYPE_PLANE` | `0,1,0,0` |
| 几何 | `AABB` | `TYPE_AABB` | `0,0,0,1,1,1` |
| 几何 | `Basis` | `TYPE_BASIS` | 9 个浮点数 |
| 几何 | `Transform2D` | `TYPE_TRANSFORM2D` | 6 个浮点数 |
| 几何 | `Transform3D` | `TYPE_TRANSFORM3D` | 12 个浮点数 |
| 几何 | `Projection` | `TYPE_PROJECTION` | 16 个浮点数 |
| 容器 | `Array` | `TYPE_ARRAY` | `a,b,c` |
| 容器 | `NodePath` | `TYPE_NODE_PATH` | `path/to/node` |
| 资源 | `Resource` | `TYPE_OBJECT` | `res://path.tres` |
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
