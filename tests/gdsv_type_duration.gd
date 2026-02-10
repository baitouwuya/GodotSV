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
	## 唯一类型标识，用于 CSV 类型注解（如 value:duration）
	return "duration"


# ============================================================
# 建议重写：元数据
# ============================================================

func _get_variant_type() -> int:
	## 存储的 Godot Variant 类型
	return TYPE_FLOAT


func _get_display_name() -> String:
	## 编辑器中显示的名称
	return "持续时间"


func _get_category() -> int:
	## 分类，决定在类型选择器中的位置
	return GDSVTypeHandler.TYPE_CATEGORY_CUSTOM


func _get_description() -> String:
	return "时间持续量，支持 1h30m、90s 等格式，存储为秒数"


func _get_type_default_value() -> Variant:
	## 默认值
	return 0.0


# ============================================================
# 必须重写：字符串 ↔ Variant 转换
# ============================================================

func _string_to_variant(input: String) -> Dictionary:
	## CSV 字符串 → Variant（解析）
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

	# 末尾无单位的数字当秒数
	if not current.is_empty():
		if not current.is_valid_float():
			return _error("无效的时间格式: '%s'" % input)
		seconds += current.to_float()

	return _ok(seconds)


func _variant_to_string(value: Variant) -> Dictionary:
	## Variant → CSV 字符串（序列化）
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		return _error("值必须是数值类型")

	var total_seconds: float = float(value)
	if total_seconds < 0:
		return _error("持续时间不能为负数")

	var hours := int(total_seconds / 3600.0)
	var remaining := total_seconds - hours * 3600.0
	var minutes := int(remaining / 60.0)
	var seconds := remaining - minutes * 60.0

	var parts := PackedStringArray()
	if hours > 0:
		parts.append("%dh" % hours)
	if minutes > 0:
		parts.append("%dm" % minutes)
	if seconds > 0 or parts.is_empty():
		# 整数秒省略小数点
		if seconds == int(seconds):
			parts.append("%ds" % int(seconds))
		else:
			parts.append("%.1fs" % seconds)

	return _ok("".join(parts))


# ============================================================
# 可选重写：验证
# ============================================================

func _validate(value: Variant, constraints: Dictionary) -> Dictionary:
	## 验证值是否满足约束条件
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		return _error("持续时间必须是数值类型")

	var val: float = float(value)
	if val < 0:
		return _error("持续时间不能为负数")

	# 支持 min/max 约束（单位：秒）
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
# 自定义编辑器 UI：时:分:秒 三栏输入
# ============================================================

func _init() -> void:
	## 自动注册自定义编辑器到 GDSVEditorRegistry
	GDSVEditorRegistry.register_editor("duration", func(row: int, column: int, config: Dictionary) -> Control:
		return GDSVTypeDuration._create_duration_editor(row, column, config)
	)


static func _create_duration_editor(row: int, column: int, config: Dictionary) -> Control:
	## 工厂函数：创建 时:分:秒 编辑器
	var editor := DurationEditor.new()
	var initial: String = config.get("initial_value", "0")
	editor.set_from_seconds(initial.to_float() if initial.is_valid_float() else 0.0)
	return editor


## 持续时间编辑器控件（时:分:秒 三栏 SpinBox）
## TableView 通过 get_value() 获取编辑结果
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

	## TableView 调用此方法获取编辑后的值（总秒数字符串）
	func get_value() -> String:
		var total: float = _h_spin.value * 3600.0 + _m_spin.value * 60.0 + _s_spin.value
		return str(total)

	## 从秒数设置初始值
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
