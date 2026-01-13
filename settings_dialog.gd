class_name SettingsDialog
extends AcceptDialog

## 设置对话框
## 提供用户偏好设置的UI界面

signal settings_changed()

#region 公共变量 Public Variables
## 配置管理器引用
var config_manager: ConfigManager

#endregion

#region 生命周期方法 Lifecycle Methods
func _ready() -> void:
	title = "设置"
	size = Vector2(500, 600)
	_setup_ui()
	confirmed.connect(_on_confirmed)
	_load_current_settings()


## 对话框确认
func _on_confirmed() -> void:
	_save_settings()
	settings_changed.emit()
	hide()
#endregion

#region UI构建 UI Building
## 设置UI
func _setup_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)
	
	# 通用设置
	var general_section := _create_section("通用设置", vbox)
	_create_auto_save_setting(general_section)
	_create_auto_trim_spaces_setting(general_section)
	
	# 显示设置
	var display_section := _create_section("显示设置", vbox)
	_create_row_numbers_setting(display_section)
	_create_virtual_scroll_setting(display_section)
	_create_theme_setting(display_section)
	_create_font_size_setting(display_section)
	_create_cell_text_overflow_setting(display_section)
	_create_wrap_auto_row_height_setting(display_section)
	_create_wrap_max_lines_setting(display_section)
	
	# 编辑设置
	var edit_section := _create_section("编辑设置", vbox)
	_create_delimiter_setting(edit_section)
	_create_encoding_setting(edit_section)
	_create_max_undo_history_setting(edit_section)
	_create_type_change_failure_policy_setting(edit_section)
	_create_type_change_empty_policy_setting(edit_section)


## 创建设置区域
func _create_section(section_title: String, parent: VBoxContainer) -> VBoxContainer:
	var label := Label.new()
	label.text = section_title
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	parent.add_child(label)
	
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.add_theme_constant_override("separation", 8)
	
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 5)
	margin.add_child(vbox)
	parent.add_child(margin)
	
	return vbox


## 创建自动保存设置
func _create_auto_save_setting(parent: VBoxContainer) -> void:
	var hbox := HBoxContainer.new()
	
	var checkbox := CheckBox.new()
	checkbox.name = "AutoSaveEnabled"
	checkbox.text = "启用自动保存"
	hbox.add_child(checkbox)
	
	var spin_box := SpinBox.new()
	spin_box.name = "AutoSaveInterval"
	spin_box.min_value = 10
	spin_box.max_value = 600
	spin_box.value = 60
	spin_box.step = 10
	spin_box.suffix = " 秒"
	spin_box.custom_minimum_size.x = 100
	hbox.add_child(spin_box)
	
	parent.add_child(hbox)


## 创建自动去除空格设置
func _create_auto_trim_spaces_setting(parent: VBoxContainer) -> void:
	var checkbox := CheckBox.new()
	checkbox.name = "AutoTrimSpaces"
	checkbox.text = "自动去除单元格空格"
	parent.add_child(checkbox)


## 创建显示行号设置
func _create_row_numbers_setting(parent: VBoxContainer) -> void:
	var checkbox := CheckBox.new()
	checkbox.name = "ShowRowNumbers"
	checkbox.text = "显示行号"
	parent.add_child(checkbox)


## 创建启用虚拟滚动设置
func _create_virtual_scroll_setting(parent: VBoxContainer) -> void:
	var checkbox := CheckBox.new()
	checkbox.name = "EnableVirtualScroll"
	checkbox.text = "启用虚拟滚动（大文件性能优化）"
	parent.add_child(checkbox)


## 创建主题设置
func _create_theme_setting(parent: VBoxContainer) -> void:
	var hbox := HBoxContainer.new()
	
	var label := Label.new()
	label.text = "主题："
	label.custom_minimum_size.x = 80
	hbox.add_child(label)
	
	var option_button := OptionButton.new()
	option_button.name = "Theme"
	option_button.add_item("自动", 0)
	option_button.add_item("亮色", 1)
	option_button.add_item("暗色", 2)
	hbox.add_child(option_button)
	
	parent.add_child(hbox)


## 创建字体大小设置
func _create_font_size_setting(parent: VBoxContainer) -> void:
	var hbox := HBoxContainer.new()
	
	var label := Label.new()
	label.text = "字体大小："
	label.custom_minimum_size.x = 80
	hbox.add_child(label)
	
	var spin_box := SpinBox.new()
	spin_box.name = "FontSize"
	spin_box.min_value = 10
	spin_box.max_value = 24
	spin_box.value = 14
	spin_box.step = 1
	spin_box.custom_minimum_size.x = 100
	hbox.add_child(spin_box)
	
	parent.add_child(hbox)


## 创建单元格文本溢出设置
func _create_cell_text_overflow_setting(parent: VBoxContainer) -> void:
	var hbox := HBoxContainer.new()
	
	var label := Label.new()
	label.text = "单元格内容："
	label.custom_minimum_size.x = 120
	hbox.add_child(label)
	
	var option_button := OptionButton.new()
	option_button.name = "CellTextOverflow"
	option_button.add_item("截断", 0)
	option_button.add_item("省略号", 1)
	option_button.add_item("换行", 2)
	hbox.add_child(option_button)
	
	parent.add_child(hbox)


## 创建换行自动行高设置
func _create_wrap_auto_row_height_setting(parent: VBoxContainer) -> void:
	var checkbox := CheckBox.new()
	checkbox.name = "WrapAutoRowHeight"
	checkbox.text = "换行时自动调整行高"
	parent.add_child(checkbox)


## 创建换行最大行数设置
func _create_wrap_max_lines_setting(parent: VBoxContainer) -> void:
	var hbox := HBoxContainer.new()
	
	var label := Label.new()
	label.text = "换行最大行数："
	label.custom_minimum_size.x = 120
	hbox.add_child(label)
	
	var spin_box := SpinBox.new()
	spin_box.name = "WrapMaxLines"
	spin_box.min_value = 1
	spin_box.max_value = 20
	spin_box.value = 6
	spin_box.step = 1
	spin_box.custom_minimum_size.x = 100
	hbox.add_child(spin_box)
	
	parent.add_child(hbox)


## 创建分隔符设置
func _create_delimiter_setting(parent: VBoxContainer) -> void:
	var hbox := HBoxContainer.new()
	
	var label := Label.new()
	label.text = "默认分隔符："
	label.custom_minimum_size.x = 120
	hbox.add_child(label)
	
	var line_edit := LineEdit.new()
	line_edit.name = "DefaultDelimiter"
	line_edit.placeholder_text = ","
	line_edit.custom_minimum_size.x = 100
	line_edit.max_length = 1
	hbox.add_child(line_edit)
	
	parent.add_child(hbox)


## 创建编码设置
func _create_encoding_setting(parent: VBoxContainer) -> void:
	var hbox := HBoxContainer.new()
	
	var label := Label.new()
	label.text = "默认编码："
	label.custom_minimum_size.x = 120
	hbox.add_child(label)
	
	var option_button := OptionButton.new()
	option_button.name = "DefaultEncoding"
	option_button.add_item("UTF-8", 0)
	option_button.add_item("UTF-16", 1)
	option_button.add_item("GBK", 2)
	hbox.add_child(option_button)
	
	parent.add_child(hbox)


## 创建最大撤销历史设置
func _create_max_undo_history_setting(parent: VBoxContainer) -> void:
	var hbox := HBoxContainer.new()
	
	var label := Label.new()
	label.text = "最大撤销历史："
	label.custom_minimum_size.x = 120
	hbox.add_child(label)
	
	var spin_box := SpinBox.new()
	spin_box.name = "MaxUndoHistory"
	spin_box.min_value = 10
	spin_box.max_value = 500
	spin_box.value = 100
	spin_box.step = 10
	spin_box.custom_minimum_size.x = 100
	hbox.add_child(spin_box)
	
	parent.add_child(hbox)


## 创建类型变更失败策略设置
func _create_type_change_failure_policy_setting(parent: VBoxContainer) -> void:
	var hbox := HBoxContainer.new()
	
	var label := Label.new()
	label.text = "类型转换失败："
	label.custom_minimum_size.x = 120
	hbox.add_child(label)
	
	var option_button := OptionButton.new()
	option_button.name = "TypeChangeFailurePolicy"
	option_button.add_item("显示错误（保留原值）", 0)
	option_button.add_item("强制默认值（覆盖原值）", 1)
	hbox.add_child(option_button)
	
	parent.add_child(hbox)


## 创建类型变更空值处理设置
func _create_type_change_empty_policy_setting(parent: VBoxContainer) -> void:
	var hbox := HBoxContainer.new()
	
	var label := Label.new()
	label.text = "空值处理："
	label.custom_minimum_size.x = 120
	hbox.add_child(label)
	
	var option_button := OptionButton.new()
	option_button.name = "TypeChangeEmptyPolicy"
	option_button.add_item("保持为空", 0)
	option_button.add_item("填充默认值", 1)
	hbox.add_child(option_button)
	
	parent.add_child(hbox)
#endregion

#region 设置加载保存 Settings Load/Save
func _find_setting_node(setting_name: String) -> Node:
	return find_child(setting_name, true, false)


func _find_setting_control(setting_name: String) -> Control:
	var node := _find_setting_node(setting_name)
	return node as Control


## 加载当前设置
func _load_current_settings() -> void:
	if not config_manager:
		return
	
	# 自动保存
	var auto_save_enabled := _find_setting_control("AutoSaveEnabled") as CheckBox
	var auto_save_interval := _find_setting_control("AutoSaveInterval") as SpinBox
	
	if auto_save_enabled:
		auto_save_enabled.button_pressed = config_manager.get_auto_save_enabled()
	if auto_save_interval:
		auto_save_interval.value = config_manager.get_auto_save_interval()
	
	# 自动去除空格
	var auto_trim_spaces := _find_setting_control("AutoTrimSpaces") as CheckBox
	if auto_trim_spaces:
		auto_trim_spaces.button_pressed = config_manager.get_auto_trim_spaces()
	
	# 显示行号
	var show_row_numbers := _find_setting_control("ShowRowNumbers") as CheckBox
	if show_row_numbers:
		show_row_numbers.button_pressed = config_manager.get_show_row_numbers()
	
	# 启用虚拟滚动
	var enable_virtual_scroll := _find_setting_control("EnableVirtualScroll") as CheckBox
	if enable_virtual_scroll:
		enable_virtual_scroll.button_pressed = config_manager.get_enable_virtual_scroll()
	
	# 主题
	var theme_option := _find_setting_control("Theme") as OptionButton
	if theme_option:
		var theme := config_manager.get_theme()
		match theme:
			"light": theme_option.selected = 1
			"dark": theme_option.selected = 2
			_: theme_option.selected = 0
	
	# 字体大小
	var font_size := _find_setting_control("FontSize") as SpinBox
	if font_size:
		font_size.value = config_manager.get_font_size()
	
	# 单元格文本溢出
	var cell_text_overflow := _find_setting_control("CellTextOverflow") as OptionButton
	if cell_text_overflow:
		match config_manager.get_cell_text_overflow():
			"clip":
				cell_text_overflow.selected = 0
			"wrap":
				cell_text_overflow.selected = 2
			_:
				cell_text_overflow.selected = 1

	# 换行自动行高
	var wrap_auto_row_height := _find_setting_control("WrapAutoRowHeight") as CheckBox
	if wrap_auto_row_height:
		wrap_auto_row_height.button_pressed = config_manager.get_wrap_auto_row_height()

	# 换行最大行数
	var wrap_max_lines := _find_setting_control("WrapMaxLines") as SpinBox
	if wrap_max_lines:
		wrap_max_lines.value = config_manager.get_wrap_max_lines()
	
	# 分隔符
	var delimiter := _find_setting_control("DefaultDelimiter") as LineEdit
	if delimiter:
		delimiter.text = config_manager.get_default_delimiter()
	
	# 编码
	var encoding_option := _find_setting_control("DefaultEncoding") as OptionButton
	if encoding_option:
		var encoding := config_manager.get_default_encoding()
		match encoding:
			"utf-16": encoding_option.selected = 1
			"gbk": encoding_option.selected = 2
			_: encoding_option.selected = 0
	
	# 最大撤销历史
	var max_undo_history := _find_setting_control("MaxUndoHistory") as SpinBox
	if max_undo_history:
		max_undo_history.value = config_manager.get_max_undo_history()

	# 类型转换失败策略
	var failure_policy := _find_setting_control("TypeChangeFailurePolicy") as OptionButton
	if failure_policy:
		match config_manager.get_type_change_failure_policy():
			"default":
				failure_policy.selected = 1
			_:
				failure_policy.selected = 0

	# 空值处理策略
	var empty_policy := _find_setting_control("TypeChangeEmptyPolicy") as OptionButton
	if empty_policy:
		match config_manager.get_type_change_empty_policy():
			"use_default":
				empty_policy.selected = 1
			_:
				empty_policy.selected = 0


## 保存设置
func _save_settings() -> void:
	if not config_manager:
		return
	
	# 自动保存
	var auto_save_enabled := _find_setting_control("AutoSaveEnabled") as CheckBox
	var auto_save_interval := _find_setting_control("AutoSaveInterval") as SpinBox
	
	if auto_save_enabled:
		config_manager.set_auto_save_enabled(auto_save_enabled.button_pressed)
	if auto_save_interval:
		config_manager.set_auto_save_interval(int(auto_save_interval.value))
	
	# 自动去除空格
	var auto_trim_spaces := _find_setting_control("AutoTrimSpaces") as CheckBox
	if auto_trim_spaces:
		config_manager.set_auto_trim_spaces(auto_trim_spaces.button_pressed)
	
	# 显示行号
	var show_row_numbers := _find_setting_control("ShowRowNumbers") as CheckBox
	if show_row_numbers:
		config_manager.set_show_row_numbers(show_row_numbers.button_pressed)
	
	# 启用虚拟滚动
	var enable_virtual_scroll := _find_setting_control("EnableVirtualScroll") as CheckBox
	if enable_virtual_scroll:
		config_manager.set_enable_virtual_scroll(enable_virtual_scroll.button_pressed)
	
	# 主题
	var theme_option := _find_setting_control("Theme") as OptionButton
	if theme_option:
		match theme_option.selected:
			1: config_manager.set_theme("light")
			2: config_manager.set_theme("dark")
			_: config_manager.set_theme("auto")
	
	# 字体大小
	var font_size := _find_setting_control("FontSize") as SpinBox
	if font_size:
		config_manager.set_font_size(int(font_size.value))
	
	# 单元格文本溢出
	var cell_text_overflow := _find_setting_control("CellTextOverflow") as OptionButton
	if cell_text_overflow:
		match cell_text_overflow.selected:
			0:
				config_manager.set_cell_text_overflow("clip")
			2:
				config_manager.set_cell_text_overflow("wrap")
			_:
				config_manager.set_cell_text_overflow("ellipsis")

	# 换行自动行高
	var wrap_auto_row_height := _find_setting_control("WrapAutoRowHeight") as CheckBox
	if wrap_auto_row_height:
		config_manager.set_wrap_auto_row_height(wrap_auto_row_height.button_pressed)

	# 换行最大行数
	var wrap_max_lines := _find_setting_control("WrapMaxLines") as SpinBox
	if wrap_max_lines:
		config_manager.set_wrap_max_lines(int(wrap_max_lines.value))
	
	# 分隔符
	var delimiter := _find_setting_control("DefaultDelimiter") as LineEdit
	if delimiter:
		config_manager.set_default_delimiter(delimiter.text)
	
	# 编码
	var encoding_option := _find_setting_control("DefaultEncoding") as OptionButton
	if encoding_option:
		match encoding_option.selected:
			1: config_manager.set_default_encoding("utf-16")
			2: config_manager.set_default_encoding("gbk")
			_: config_manager.set_default_encoding("utf-8")
	
	# 最大撤销历史
	var max_undo_history := _find_setting_control("MaxUndoHistory") as SpinBox
	if max_undo_history:
		config_manager.set_max_undo_history(int(max_undo_history.value))

	# 类型转换失败策略
	var failure_policy := _find_setting_control("TypeChangeFailurePolicy") as OptionButton
	if failure_policy:
		match failure_policy.selected:
			1:
				config_manager.set_type_change_failure_policy("default")
			_:
				config_manager.set_type_change_failure_policy("error")

	# 空值处理策略
	var empty_policy := _find_setting_control("TypeChangeEmptyPolicy") as OptionButton
	if empty_policy:
		match empty_policy.selected:
			1:
				config_manager.set_type_change_empty_policy("use_default")
			_:
				config_manager.set_type_change_empty_policy("keep_empty")
	
	# 保存配置文件
	config_manager.save_config()
