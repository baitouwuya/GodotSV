# 自定义类型处理器

本指南介绍如何通过 GDScript 创建自定义类型处理器（`GDSVTypeHandler`），让 GDSV 编辑器支持你自己的数据类型。

## 概述

GodotSV 的类型系统是可扩展的。你可以用 GDScript 继承 `GDSVTypeHandler`，实现自定义的数据解析、序列化、验证逻辑，甚至自定义编辑器 UI。

**典型用例**：
- 持续时间（`1h30m15s` → 秒数）
- 百分比（`75%` → `0.75`）
- 坐标（`A3` → 棋盘格坐标）
- 自定义枚举（`稀有度.SSR` → 整数 ID）
- 任何需要特殊解析/展示逻辑的数据

## 快速开始：最小实现

创建一个 GDScript 文件，继承 `GDSVTypeHandler`：

```gdscript
@tool
class_name GDSVTypePercent
extends GDSVTypeHandler
## 百分比类型：将 "75%" 转换为 0.75

func _get_type_name() -> StringName:
    return "percent"

func _get_variant_type() -> int:
    return TYPE_FLOAT

func _get_display_name() -> String:
    return "百分比"

func _get_category() -> int:
    return GDSVTypeHandler.TYPE_CATEGORY_CUSTOM

func _string_to_variant(input: String) -> Dictionary:
    var trimmed := input.strip_edges()
    if trimmed.is_empty():
        return _ok(0.0)
    if trimmed.ends_with("%"):
        trimmed = trimmed.left(-1)
    if not trimmed.is_valid_float():
        return _error("无效的百分比: '%s'" % input)
    return _ok(trimmed.to_float() / 100.0)

func _variant_to_string(value: Variant) -> Dictionary:
    if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
        return _error("值必须是数值类型")
    return _ok("%.0f%%" % (float(value) * 100.0))

func _ok(value: Variant) -> Dictionary:
    return {"success": true, "value": value, "error_message": ""}

func _error(message: String) -> Dictionary:
    return {"success": false, "value": null, "error_message": message}
```

将文件保存到项目中任意位置（如 `res://custom_types/gdsv_type_percent.gd`），GDSV 会自动扫描发现它。

## 完整 API 参考

### 必须重写的方法

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `_get_type_name()` | `StringName` | 唯一类型标识，用于 CSV 类型注解（如 `value:duration`） |
| `_string_to_variant(input)` | `Dictionary` | CSV 字符串 → Variant 值 |
| `_variant_to_string(value)` | `Dictionary` | Variant 值 → CSV 字符串 |

### 建议重写的方法

| 方法 | 返回类型 | 默认值 | 说明 |
|------|---------|--------|------|
| `_get_variant_type()` | `int` | `TYPE_STRING` | 存储的 Godot Variant 类型 |
| `_get_display_name()` | `String` | 同 type_name | 编辑器中显示的名称 |
| `_get_category()` | `int` | `TYPE_CATEGORY_OTHER` | 类型分类 |
| `_get_description()` | `String` | `""` | 类型描述文字 |
| `_get_type_default_value()` | `Variant` | `null` | 该类型的默认值 |

### 可选重写的方法

| 方法 | 返回类型 | 说明 |
|------|---------|------|
| `_validate(value, constraints)` | `Dictionary` | 验证值是否满足约束条件 |
| `_supports_inline_editing()` | `bool` | 是否支持行内编辑（默认 `true`） |
| `_get_inline_editor_type()` | `String` | 自定义行内编辑器类型 |
| `_get_editor_config()` | `Dictionary` | 编辑器配置参数 |

### 返回值格式

所有转换/验证方法都返回统一的 `Dictionary` 格式：

```gdscript
# 成功
{"success": true, "value": <转换后的值>, "error_message": ""}

# 失败
{"success": false, "value": null, "error_message": "错误描述"}
```

建议封装为辅助方法：

```gdscript
func _ok(value: Variant) -> Dictionary:
    return {"success": true, "value": value, "error_message": ""}

func _error(message: String) -> Dictionary:
    return {"success": false, "value": null, "error_message": message}
```

### 类型分类常量

```gdscript
GDSVTypeHandler.TYPE_CATEGORY_BASIC       # 基本类型（int, float, bool, string）
GDSVTypeHandler.TYPE_CATEGORY_VECTOR      # 向量类型（Vector2, Vector3）
GDSVTypeHandler.TYPE_CATEGORY_COLOR       # 颜色
GDSVTypeHandler.TYPE_CATEGORY_ARRAY       # 数组
GDSVTypeHandler.TYPE_CATEGORY_CONTAINER   # 容器（Dictionary）
GDSVTypeHandler.TYPE_CATEGORY_RESOURCE    # 资源（Resource, Node）
GDSVTypeHandler.TYPE_CATEGORY_GEOMETRY    # 几何（Rect2, AABB）
GDSVTypeHandler.TYPE_CATEGORY_CUSTOM      # 自定义类型（推荐使用）
GDSVTypeHandler.TYPE_CATEGORY_OTHER       # 其他
```

## 自动注册机制

GodotSV 通过 `GDSVTypeHandlerRegistry` 自动发现和注册类型处理器。

**注册流程**：

1. 编辑器启动或调用 `scan_script_types()` 时，扫描所有继承 `GDSVTypeHandler` 且带有 `class_name` 的 GDScript。
2. 实例化脚本（触发 `_init()`），调用 `_get_type_name()` 获取类型标识。
3. 将类型处理器注册到全局 registry。

**你不需要手动注册**，只要满足以下条件：
- 脚本声明了 `class_name`
- 脚本继承 `GDSVTypeHandler`
- 脚本添加了 `@tool` 注解

### 手动注册（可选）

如果需要手动控制注册：

```gdscript
var registry := GDSVTypeHandlerRegistry.get_singleton()
registry.register_script("GDSVTypePercent", "percent")
```

## 自定义编辑器 UI

默认情况下，自定义类型在编辑器中使用纯文本输入框。你可以通过 `GDSVEditorRegistry` 注册自定义编辑器控件，提供更好的编辑体验。

### 编辑器工厂注册

在 `_init()` 中注册自定义编辑器工厂：

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

### 编辑器控件约定

自定义编辑器控件必须遵循以下约定：

| 要求 | 说明 |
|------|------|
| `get_value() -> String` | **必须实现**。返回当前编辑值的字符串形式 |
| `signal value_changed` | **必须声明**。值变化时触发，编辑器通过此信号自动保存 |
| 继承 `Control` | 控件的基类要求 |

### 完整编辑器示例

以下是持续时间类型的三栏 SpinBox 编辑器：

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

### config 参数说明

工厂函数接收的 `config` 字典包含以下字段：

| 键 | 类型 | 说明 |
|----|------|------|
| `initial_value` | `String` | 当前单元格的值（字符串形式） |
| `row` | `int` | 当前行号（字段设置中为 `-1`） |
| `column` | `int` | 当前列号 |

此外，`config` 还包含该列的完整类型定义字段（`type`、`name`、`required` 等）。

## 完整实例：持续时间类型

以下是一个完整的自定义类型处理器，包含类型转换、验证和自定义编辑器 UI：

```gdscript
@tool
class_name GDSVTypeDuration
extends GDSVTypeHandler
## 持续时间类型处理器
##
## 将时间字符串转换为秒数（float）。
## 支持格式：
##   "90"      → 90.0 秒
##   "90s"     → 90.0 秒
##   "1.5m"    → 90.0 秒
##   "2h"      → 7200.0 秒
##   "1h30m"   → 5400.0 秒
##   "1h30m15s" → 5415.0 秒


# ============================================================
# 必须重写：类型标识
# ============================================================

func _get_type_name() -> StringName:
    return "duration"


# ============================================================
# 建议重写：元数据
# ============================================================

func _get_variant_type() -> int:
    return TYPE_FLOAT

func _get_display_name() -> String:
    return "持续时间"

func _get_category() -> int:
    return GDSVTypeHandler.TYPE_CATEGORY_CUSTOM

func _get_description() -> String:
    return "时间持续量，支持 1h30m、90s 等格式，存储为秒数"

func _get_type_default_value() -> Variant:
    return 0.0


# ============================================================
# 必须重写：字符串 ↔ Variant 转换
# ============================================================

func _string_to_variant(input: String) -> Dictionary:
    var trimmed := input.strip_edges()
    if trimmed.is_empty():
        return _ok(0.0)

    # 纯数字：直接当秒数
    if trimmed.is_valid_float():
        return _ok(trimmed.to_float())

    # 解析 XhYmZs 格式
    var seconds := 0.0
    var current := ""

    for c in trimmed:
        match c:
            "h", "H":
                if not current.is_valid_float():
                    return _error("无效的小时数: '%s'" % current)
                seconds += current.to_float() * 3600.0
                current = ""
            "m", "M":
                if not current.is_valid_float():
                    return _error("无效的分钟数: '%s'" % current)
                seconds += current.to_float() * 60.0
                current = ""
            "s", "S":
                if not current.is_valid_float():
                    return _error("无效的秒数: '%s'" % current)
                seconds += current.to_float()
                current = ""
            _:
                current += c

    if not current.is_empty():
        if not current.is_valid_float():
            return _error("无效的时间格式: '%s'" % input)
        seconds += current.to_float()

    return _ok(seconds)


func _variant_to_string(value: Variant) -> Dictionary:
    if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
        return _error("值必须是数值类型")

    var total_seconds: float = float(value)
    if total_seconds < 0:
        return _error("持续时间不能为负数")

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
# 可选重写：验证
# ============================================================

func _validate(value: Variant, constraints: Dictionary) -> Dictionary:
    if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
        return _error("持续时间必须是数值类型")

    var val: float = float(value)
    if val < 0:
        return _error("持续时间不能为负数")

    if constraints.has("min"):
        var min_val: float = float(constraints["min"])
        if val < min_val:
            return _error("持续时间 %.0fs 低于最小值 %.0fs" % [val, min_val])

    if constraints.has("max"):
        var max_val: float = float(constraints["max"])
        if val > max_val:
            return _error("持续时间 %.0fs 超过最大值 %.0fs" % [val, max_val])

    return _ok(value)


# ============================================================
# 自定义编辑器 UI
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
# 内部工具方法
# ============================================================

func _ok(value: Variant) -> Dictionary:
    return {"success": true, "value": value, "error_message": ""}

func _error(message: String) -> Dictionary:
    return {"success": false, "value": null, "error_message": message}
```

使用时在 CSV/GDSV 表头中标注类型：

```
*id:int	name:string	cooldown:duration
1	火球术	1h30m
2	治疗术	45s
3	复活术	2h15m30s
```

## 常见问题与踩坑记录

### 1. 必须添加 `@tool` 注解

**问题**：自定义类型处理器在编辑器中不出现，类型选择器里找不到。

**原因**：GDScript 的 `@tool` 注解**不可继承**。即使 `GDSVTypeHandler` 基类在 C++ 中是 `@tool` 模式，你的 GDScript 子类也必须显式添加 `@tool`。

```gdscript
# ✅ 正确
@tool
class_name GDSVTypeDuration
extends GDSVTypeHandler

# ❌ 错误：缺少 @tool，编辑器中不可见
class_name GDSVTypeDuration
extends GDSVTypeHandler
```

### 2. 必须声明 `class_name`

**问题**：类型处理器不被自动发现。

**原因**：`scan_script_types()` 通过 Godot 的全局类注册表来扫描继承 `GDSVTypeHandler` 的脚本。没有 `class_name` 的脚本不会出现在全局类注册表中。

```gdscript
# ✅ 正确
class_name GDSVTypeDuration

# ❌ 错误：没有 class_name，无法被自动扫描
# （文件名不等于 class_name）
```

### 3. 方法名必须以下划线 `_` 开头

**问题**：重写的方法不生效，类型处理器行为异常。

**原因**：C++ 基类通过 `GDVIRTUAL` 宏声明虚方法，GDScript 的重写点以 `_` 前缀命名。如果你写成 `get_type_name()` 而非 `_get_type_name()`，C++ 端不会调用你的实现。

```gdscript
# ✅ 正确：带下划线前缀
func _get_type_name() -> StringName:
    return "duration"

func _string_to_variant(input: String) -> Dictionary:
    # ...

# ❌ 错误：不带下划线，C++ 端不会调用
func get_type_name() -> StringName:
    return "duration"
```

### 4. 返回值必须是 Dictionary 格式

**问题**：类型转换报错或返回 `null`。

**原因**：`_string_to_variant()`、`_variant_to_string()` 和 `_validate()` 必须返回特定格式的 Dictionary，而不是直接返回值。

```gdscript
# ✅ 正确：返回 Dictionary
func _string_to_variant(input: String) -> Dictionary:
    return {"success": true, "value": input.to_float(), "error_message": ""}

# ❌ 错误：直接返回值
func _string_to_variant(input: String) -> float:
    return input.to_float()
```

### 5. 自定义编辑器必须有 `get_value()` 和 `value_changed` 信号

**问题**：自定义编辑器显示正常，但编辑后的值不保存到单元格。

**原因**：GDSV 编辑器通过以下约定读取和监听自定义编辑器的值：
- `get_value() -> String`：读取当前编辑值
- `signal value_changed`：值变化时触发自动保存

缺少任一约定都会导致数据丢失。

```gdscript
class MyEditor extends HBoxContainer:
    # ✅ 必须声明此信号
    signal value_changed

    # ✅ 必须实现此方法
    func get_value() -> String:
        return str(_spin.value)

    func _init() -> void:
        var spin := SpinBox.new()
        # ✅ 必须连接信号
        spin.value_changed.connect(func(_v: float) -> void:
            value_changed.emit()
        )
        add_child(spin)
```

### 6. 编辑器工厂不要直接传静态方法引用

**问题**：注册自定义编辑器时崩溃或报 `Invalid callable`。

**原因**：在某些 GDScript 版本中，`GDSVTypeDuration._create_duration_editor` 作为 Callable 传递可能不稳定。应使用 lambda 包装。

```gdscript
# ✅ 正确：用 lambda 包装
func _init() -> void:
    GDSVEditorRegistry.register_editor("duration",
        func(row: int, column: int, config: Dictionary) -> Control:
            return GDSVTypeDuration._create_duration_editor(row, column, config)
    )

# ❌ 可能不稳定：直接传静态方法引用
func _init() -> void:
    GDSVEditorRegistry.register_editor("duration",
        GDSVTypeDuration._create_duration_editor
    )
```

### 7. `_get_variant_type()` 返回值必须是 `TYPE_*` 常量

**问题**：编辑器无法识别类型，字段设置对话框显示异常。

**原因**：`_get_variant_type()` 应返回 Godot 内置的 `TYPE_*` 枚举值（`TYPE_INT`、`TYPE_FLOAT`、`TYPE_STRING` 等），而不是自定义整数。

```gdscript
# ✅ 正确
func _get_variant_type() -> int:
    return TYPE_FLOAT

# ❌ 错误：随意返回数字
func _get_variant_type() -> int:
    return 42
```

### 8. `_get_type_name()` 不要与内置类型重名

**问题**：自定义类型覆盖了内置类型，导致 int/float/bool 等基础类型行为异常。

**原因**：类型名是全局唯一的。如果你的自定义类型名与内置类型相同（如 `"int"`、`"float"`、`"string"`），会替换掉内置处理器。

```gdscript
# ✅ 正确：使用独特的类型名
func _get_type_name() -> StringName:
    return "duration"

# ❌ 错误：与内置类型重名
func _get_type_name() -> StringName:
    return "float"
```

## 文件放置建议

```
your_project/
├── custom_types/                    # 自定义类型处理器目录
│   ├── gdsv_type_duration.gd       # 持续时间类型
│   ├── gdsv_type_percent.gd        # 百分比类型
│   └── gdsv_type_coordinate.gd     # 坐标类型
├── addons/
│   └── GodotSV/                    # GodotSV 插件
└── ...
```

自定义类型文件可以放在项目中任意位置，只要满足 `@tool` + `class_name` + `extends GDSVTypeHandler` 三个条件，就会被自动扫描注册。

## 下一步

- [GDSV 格式与类型注解](./gdsv-format.md)：了解如何在 GDSV 文件中使用自定义类型
- [编辑器集成](./editor-integration.md)：了解 GDSV 内置编辑器的使用
- [API 总览](../api/index.md)：查看完整 API 文档
