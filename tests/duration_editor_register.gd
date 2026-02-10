@tool
extends Node
## Duration 类型自定义编辑器注册器
##
## 使用方法：
##   1. 将此脚本添加到 Autoload（项目设置 → 自动加载）
##   2. 在 CSV schema 中设置列类型为 "duration"
##   3. 双击单元格时会显示 时:分:秒 编辑器


func _ready() -> void:
	GDSVEditorRegistry.register_editor("duration", _create_duration_editor)


## 工厂函数：创建编辑器实例
## @param row: 当前行
## @param column: 当前列
## @param config: 包含 initial_value、row、column 及 type_def 全部字段
static func _create_duration_editor(row: int, column: int, config: Dictionary) -> Control:
	var editor := DurationEditor.new()
	var initial: String = config.get("initial_value", "0")
	editor.set_from_seconds(initial.to_float() if initial.is_valid_float() else 0.0)
	return editor


## 持续时间编辑器控件
## TableView 通过 get_value() 获取编辑结果
class DurationEditor extends HBoxContainer:
	var _h_spin: SpinBox
	var _m_spin: SpinBox
	var _s_spin: SpinBox

	func _init() -> void:
		add_theme_constant_override("separation", 2)

		_h_spin = _make_spin(0, 999, 1, "h")
		_m_spin = _make_spin(0, 59, 1, "m")
		_s_spin = _make_spin(0, 59, 1, "s")

	## TableView 调用此方法获取编辑后的值（字符串）
	func get_value() -> String:
		var total := _h_spin.value * 3600.0 + _m_spin.value * 60.0 + _s_spin.value
		return str(total)

	## 从秒数设置初始值
	func set_from_seconds(total: float) -> void:
		var t := absf(total)
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
		add_child(spin)
		return spin
