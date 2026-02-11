class_name ColumnSettingsDialog
extends AcceptDialog

## 列设置对话框
## 用于编辑列名与类型/约束等属性（保存时由外部负责落盘到 Schema）

signal column_settings_applied(column_index: int, type_definition: Dictionary)

var _column_index: int = -1
var _original_name: String = ""

var _name_edit: LineEdit
var _type_option: OptionButton
var _required_checkbox: CheckBox
var _default_edit: LineEdit

var _min_edit: LineEdit
var _max_edit: LineEdit
var _min_length_edit: LineEdit
var _max_length_edit: LineEdit
var _pattern_edit: LineEdit

var _enum_container: Control
var _enum_values_edit: TextEdit

var _array_container: Control
var _array_element_type_option: OptionButton


func _ready() -> void:
	title = "字段设置"
	size = Vector2(520, 560)
	_setup_ui()
	confirmed.connect(_on_confirmed)


func edit_column(column_index: int, type_definition: Dictionary) -> void:
	_column_index = column_index
	_original_name = str(type_definition.get("name", "")).strip_edges()
	_name_edit.text = _original_name

	# 每次打开时刷新类型选项（确保新注册的 GDScript 类型可见）
	_refresh_type_options()

	var data_type := str(type_definition.get("type", "string"))
	_select_option_by_meta(_type_option, data_type)

	_required_checkbox.button_pressed = bool(type_definition.get("required", false))

	if type_definition.has("default"):
		_default_edit.text = str(type_definition.get("default", ""))
	else:
		_default_edit.text = ""

	_min_edit.text = "" if not type_definition.has("min") else str(type_definition.get("min"))
	_max_edit.text = "" if not type_definition.has("max") else str(type_definition.get("max"))
	_min_length_edit.text = "" if not type_definition.has("min_length") else str(type_definition.get("min_length"))
	_max_length_edit.text = "" if not type_definition.has("max_length") else str(type_definition.get("max_length"))
	_pattern_edit.text = "" if not type_definition.has("pattern") else str(type_definition.get("pattern"))

	_enum_values_edit.text = ""
	if type_definition.has("enum_values") and type_definition.enum_values is Array:
		var values: Array = type_definition.enum_values as Array
		var lines := PackedStringArray()
		for v in values:
			var s := str(v).strip_edges()
			if not s.is_empty():
				lines.append(s)
		_enum_values_edit.text = "\n".join(lines)

	var array_type := str(type_definition.get("array_element_type", "string"))
	_select_option_by_meta(_array_element_type_option, array_type)

	_update_type_dependent_ui(data_type)


func _setup_ui() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	scroll.add_child(root)

	# 基本设置
	var basic := _create_section("基本", root)
	_name_edit = _create_line_setting(basic, "列名：", "ColumnName")
	_type_option = _create_type_setting(basic)
	_required_checkbox = _create_checkbox_setting(basic, "必填（required）", "Required")
	_default_edit = _create_line_setting(basic, "默认值：", "DefaultValue")

	# 约束
	var constraints := _create_section("约束", root)
	_min_edit = _create_line_setting(constraints, "最小值（min）：", "Min")
	_max_edit = _create_line_setting(constraints, "最大值（max）：", "Max")
	_min_length_edit = _create_line_setting(constraints, "最小长度（min_length）：", "MinLength")
	_max_length_edit = _create_line_setting(constraints, "最大长度（max_length）：", "MaxLength")
	_pattern_edit = _create_line_setting(constraints, "正则（pattern）：", "Pattern")

	# 枚举
	_enum_container = VBoxContainer.new()
	_enum_container.visible = false
	root.add_child(_enum_container)
	var enum_section := _create_section("枚举值（enum）", _enum_container as VBoxContainer)
	_enum_values_edit = TextEdit.new()
	_enum_values_edit.name = "EnumValues"
	_enum_values_edit.custom_minimum_size = Vector2(0, 120)
	enum_section.add_child(_enum_values_edit)

	# 数组
	_array_container = VBoxContainer.new()
	_array_container.visible = false
	root.add_child(_array_container)
	var array_section := _create_section("数组（array）", _array_container as VBoxContainer)
	_array_element_type_option = _create_array_element_type_setting(array_section)


func _create_section(section_title: String, parent: VBoxContainer) -> VBoxContainer:
	var label := Label.new()
	label.text = section_title
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	parent.add_child(label)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_child(vbox)
	parent.add_child(margin)

	return vbox


func _create_line_setting(parent: VBoxContainer, label_text: String, node_name: String) -> LineEdit:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 160
	hbox.add_child(label)

	var edit := LineEdit.new()
	edit.name = node_name
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(edit)

	parent.add_child(hbox)
	return edit


func _create_checkbox_setting(parent: VBoxContainer, text: String, node_name: String) -> CheckBox:
	var checkbox := CheckBox.new()
	checkbox.name = node_name
	checkbox.text = text
	parent.add_child(checkbox)
	return checkbox


func _create_type_setting(parent: VBoxContainer) -> OptionButton:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = "类型："
	label.custom_minimum_size.x = 160
	hbox.add_child(label)

	var option := OptionButton.new()
	option.name = "ColumnType"
	_populate_type_options(option)
	option.item_selected.connect(_on_type_selected)
	hbox.add_child(option)

	parent.add_child(hbox)
	return option


func _create_array_element_type_setting(parent: VBoxContainer) -> OptionButton:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = "元素类型："
	label.custom_minimum_size.x = 160
	hbox.add_child(label)

	var option := OptionButton.new()
	option.name = "ArrayElementType"
	_populate_type_options(option)
	hbox.add_child(option)

	parent.add_child(hbox)
	return option


## 每次打开对话框时刷新所有类型下拉框（确保新注册的 GDScript 类型可见）
func _refresh_type_options() -> void:
	if _type_option:
		_type_option.clear()
		_populate_type_options(_type_option)
	if _array_element_type_option:
		_array_element_type_option.clear()
		_populate_type_options(_array_element_type_option)


## 从 GDSVTypeHandlerRegistry 动态填充类型选项到 OptionButton
func _populate_type_options(option: OptionButton) -> void:
	var registry := GDSVTypeHandlerRegistry.get_singleton()
	if not registry:
		return

	# 强制重新扫描 GDScript 类型（编辑器启动早期可能尚未加载）
	registry.scan_script_types()

	var all_types := registry.get_all_types()
	var sorted_types := PackedStringArray()
	for t in all_types:
		sorted_types.append(str(t))
	sorted_types.sort()

	for type_name in sorted_types:
		var handler: GDSVTypeHandler = registry.get_type(type_name)
		var display_text := type_name
		if handler:
			var meta: Dictionary = handler.get_metadata_dictionary()
			var display_name: String = str(meta.get("display_name", type_name))
			if not display_name.is_empty() and display_name != type_name:
				display_text = "%s (%s)" % [display_name, type_name]
		option.add_item(display_text)
		var idx := option.get_item_count() - 1
		var popup := option.get_popup()
		if popup:
			popup.set_item_metadata(idx, type_name)
		# 设置类型图标
		var icon: Texture2D = _get_editor_type_icon(type_name)
		if icon:
			option.set_item_icon(idx, icon)


func _on_type_selected(_index: int) -> void:
	_update_type_dependent_ui(_get_selected_type())


func _update_type_dependent_ui(data_type: String) -> void:
	_enum_container.visible = data_type == "enum"
	_array_container.visible = data_type == "array"


func _get_selected_type() -> String:
	return _get_option_meta(_type_option)


func _get_selected_array_element_type() -> String:
	return _get_option_meta(_array_element_type_option)


## 通过 popup metadata 获取当前选中项的类型标识
func _get_option_meta(option: OptionButton) -> String:
	var idx := option.selected
	if idx < 0:
		return "string"
	var popup := option.get_popup()
	if not popup:
		return "string"
	var meta := popup.get_item_metadata(idx)
	if meta == null:
		return "string"
	return str(meta)


## 通过 metadata 选中匹配的项
func _select_option_by_meta(option: OptionButton, value: String) -> void:
	var target := str(value).strip_edges()
	if target.is_empty():
		target = "string"
	var popup := option.get_popup()
	if not popup:
		if option.get_item_count() > 0:
			option.select(0)
		return
	# 精确匹配
	for i in range(option.get_item_count()):
		var meta := popup.get_item_metadata(i)
		if meta != null and str(meta) == target:
			option.select(i)
			return
	# 不区分大小写匹配
	var target_lower := target.to_lower()
	for i in range(option.get_item_count()):
		var meta := popup.get_item_metadata(i)
		if meta != null and str(meta).to_lower() == target_lower:
			option.select(i)
			return
	# 无匹配，选第一项
	if option.get_item_count() > 0:
		option.select(0)


func _on_confirmed() -> void:
	var type_definition := _build_type_definition()
	column_settings_applied.emit(_column_index, type_definition)
	hide()


func _build_type_definition() -> Dictionary:
	var name := _name_edit.text.strip_edges()
	if name.is_empty():
		name = _original_name

	var definition: Dictionary = {
		"name": name,
		"type": _get_selected_type(),
		"required": _required_checkbox.button_pressed,
	}

	var default_text := _default_edit.text.strip_edges()
	if not default_text.is_empty():
		definition["default"] = default_text

	var min_text := _min_edit.text.strip_edges()
	if not min_text.is_empty() and min_text.is_valid_float():
		definition["min"] = min_text.to_float()

	var max_text := _max_edit.text.strip_edges()
	if not max_text.is_empty() and max_text.is_valid_float():
		definition["max"] = max_text.to_float()

	var min_len_text := _min_length_edit.text.strip_edges()
	if not min_len_text.is_empty() and min_len_text.is_valid_int():
		definition["min_length"] = min_len_text.to_int()

	var max_len_text := _max_length_edit.text.strip_edges()
	if not max_len_text.is_empty() and max_len_text.is_valid_int():
		definition["max_length"] = max_len_text.to_int()

	var pattern_text := _pattern_edit.text.strip_edges()
	if not pattern_text.is_empty():
		definition["pattern"] = pattern_text

	var data_type := str(definition.get("type", "string"))
	if data_type == "enum":
		var values := _parse_list_values(_enum_values_edit.text)
		if not values.is_empty():
			definition["enum_values"] = values

	if data_type == "array":
		definition["array_element_type"] = _get_selected_array_element_type()

	return definition


func _parse_list_values(text: String) -> PackedStringArray:
	var results := PackedStringArray()
	var lines := text.split("\n", false)
	for line in lines:
		for part in str(line).split(",", false):
			var s := str(part).strip_edges()
			if not s.is_empty():
				results.append(s)
	return results


## 获取 Godot 编辑器内置的类型图标
func _get_editor_type_icon(type_name: String) -> Texture2D:
	if not Engine.is_editor_hint():
		return null
	var ei: Object = Engine.get_singleton("EditorInterface")
	if not ei:
		return null
	var theme: Theme = ei.get_editor_theme()
	if not theme:
		return null
	if theme.has_icon(type_name, "EditorIcons"):
		return theme.get_icon(type_name, "EditorIcons")
	var registry := GDSVTypeHandlerRegistry.get_singleton()
	if registry:
		var handler: GDSVTypeHandler = registry.get_type(type_name)
		if handler:
			var canonical: String = str(handler.get_type_name())
			if canonical != type_name and theme.has_icon(canonical, "EditorIcons"):
				return theme.get_icon(canonical, "EditorIcons")
	return null
