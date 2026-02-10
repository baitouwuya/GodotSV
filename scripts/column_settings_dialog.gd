class_name ColumnSettingsDialog
extends AcceptDialog

## 列设置对话框
## 用于编辑列名与类型/约束等属性（保存时由外部负责落盘到 Schema）

signal column_settings_applied(column_index: int, type_definition: Dictionary)

const TYPE_VALUES: PackedStringArray = [
	"string",
	"int",
	"float",
	"bool",
	"stringname",
	"enum",
	"array",
	"resource",
	"json"
]

const TYPE_LABELS: PackedStringArray = [
	"字符串",
	"整数",
	"浮点",
	"布尔",
	"StringName",
	"枚举",
	"数组",
	"资源",
	"JSON"
]

const ARRAY_ELEMENT_TYPE_VALUES: PackedStringArray = [
	"string",
	"int",
	"float",
	"bool",
	"stringname",
	"resource",
	"json"
]

const ARRAY_ELEMENT_TYPE_LABELS: PackedStringArray = [
	"字符串",
	"整数",
	"浮点",
	"布尔",
	"StringName",
	"资源",
	"JSON"
]

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

	var data_type := str(type_definition.get("type", "string")).to_lower()
	_set_option_by_value(_type_option, TYPE_VALUES, data_type)

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

	var array_type := str(type_definition.get("array_element_type", "string")).to_lower()
	_set_option_by_value(_array_element_type_option, ARRAY_ELEMENT_TYPE_VALUES, array_type)

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
	for i in range(TYPE_VALUES.size()):
		option.add_item("%s (%s)" % [TYPE_LABELS[i], TYPE_VALUES[i]], i)
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
	for i in range(ARRAY_ELEMENT_TYPE_VALUES.size()):
		option.add_item("%s (%s)" % [ARRAY_ELEMENT_TYPE_LABELS[i], ARRAY_ELEMENT_TYPE_VALUES[i]], i)
	hbox.add_child(option)

	parent.add_child(hbox)
	return option


func _on_type_selected(_index: int) -> void:
	_update_type_dependent_ui(_get_selected_type())


func _update_type_dependent_ui(data_type: String) -> void:
	_enum_container.visible = data_type == "enum"
	_array_container.visible = data_type == "array"


func _get_selected_type() -> String:
	var id := _type_option.get_selected_id()
	if id < 0 or id >= TYPE_VALUES.size():
		return "string"
	return TYPE_VALUES[id]


func _get_selected_array_element_type() -> String:
	var id := _array_element_type_option.get_selected_id()
	if id < 0 or id >= ARRAY_ELEMENT_TYPE_VALUES.size():
		return "string"
	return ARRAY_ELEMENT_TYPE_VALUES[id]


func _set_option_by_value(option: OptionButton, values: PackedStringArray, value: String) -> void:
	var idx := values.find(value)
	if idx < 0:
		idx = 0
	option.select(idx)


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
