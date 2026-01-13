class_name FieldsSettingsDialog
extends AcceptDialog

## 字段设置对话框（字段列表 + 单字段编辑）
## 字段顺序通过拖拽左侧握把调整；编辑会即时应用到数据模型。

const TYPE_VALUES: PackedStringArray = [
	"string",
	"int",
	"float",
	"bool",
	"stringname",
	"Vector2",
	"Vector2i",
	"Vector3",
	"Vector3i",
	"Vector4",
	"Vector4i",
	"Rect2",
	"Rect2i",
	"Color",
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
	"Vector2",
	"Vector2i",
	"Vector3",
	"Vector3i",
	"Vector4",
	"Vector4i",
	"Rect2",
	"Rect2i",
	"颜色",
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
	"Vector2",
	"Vector2i",
	"Vector3",
	"Vector3i",
	"Vector4",
	"Vector4i",
	"Rect2",
	"Rect2i",
	"Color",
	"resource",
	"json"
]

const ARRAY_ELEMENT_TYPE_LABELS: PackedStringArray = [
	"字符串",
	"整数",
	"浮点",
	"布尔",
	"StringName",
	"Vector2",
	"Vector2i",
	"Vector3",
	"Vector3i",
	"Vector4",
	"Vector4i",
	"Rect2",
	"Rect2i",
	"颜色",
	"资源",
	"JSON"
]

const _OPTION_META_MORE: String = "__more__"
const _MORE_ITEM_PREFIX: String = "更多: "
const _MORE_ITEM_DEFAULT_TEXT: String = "更多: （选择类型...）"

var data_model: CSVDataModel
var schema_manager: SchemaManager
var config_manager: ConfigManager
var commit_changes: Callable

var _split: HSplitContainer
var _field_list: ReorderableItemList
var _grip_icon: Texture2D
var _add_field_btn: Button
var _remove_field_btn: Button
var _constraints_root: VBoxContainer
var _constraints_enable_checkbox: CheckBox
var _right_spacer: Control

var _current_column: int = -1
var _schema_dirty: bool = false
var _suppress_item_selected_signal: bool = false
var _suppress_field_selection: bool = false

var _name_edit: LineEdit
var _type_option: OptionButton
var _type_picker_dialog: TypePickerDialog
var _type_picker_target: String = ""
var _last_field_type_value: String = "string"
var _last_array_element_type_value: String = "string"
var _field_type_custom_index: int = -1
var _field_type_more_index: int = -1
var _array_type_custom_index: int = -1
var _array_type_more_index: int = -1
var _default_browse_btn: Button
var _required_checkbox: CheckBox
var _default_edit: LineEdit
var _default_uid_label: Label
var _default_editor_root: Control
var _default_text_container: HBoxContainer
var _default_bool_container: HBoxContainer
var _default_bool_checkbox: CheckBox
var _default_bool_clear_btn: Button
var _default_int_container: HBoxContainer
var _default_int_spin: SpinBox
var _default_int_clear_btn: Button
var _default_float_container: HBoxContainer
var _default_float_spin: SpinBox
var _default_float_clear_btn: Button
var _default_vec2_container: HBoxContainer
var _default_vec2_x: SpinBox
var _default_vec2_y: SpinBox
var _default_vec2_clear_btn: Button
var _default_vec3_container: HBoxContainer
var _default_vec3_x: SpinBox
var _default_vec3_y: SpinBox
var _default_vec3_z: SpinBox
var _default_vec3_clear_btn: Button
var _default_color_container: HBoxContainer
var _default_color_picker: ColorPickerButton
var _default_color_clear_btn: Button
var _default_enum_container: HBoxContainer
var _default_enum_option: OptionButton
var _default_multi_value_container: HBoxContainer
var _default_multi_value_spins: Array[SpinBox] = []
var _default_multi_value_clear_btn: Button
var _suppress_default_sync: bool = false

# 多值类型配置：[组件数量, 是否整数, 标签数组]
const MULTI_VALUE_TYPE_CONFIG := {
	"vector2i": [2, true, ["X", "Y"]],
	"vector3i": [3, true, ["X", "Y", "Z"]],
	"vector4": [4, false, ["X", "Y", "Z", "W"]],
	"vector4i": [4, true, ["X", "Y", "Z", "W"]],
	"rect2": [4, false, ["X", "Y", "W", "H"]],
	"rect2i": [4, true, ["X", "Y", "W", "H"]],
	"quaternion": [4, false, ["X", "Y", "Z", "W"]],
	"plane": [4, false, ["A", "B", "C", "D"]],
	"transform2d": [6, false, ["X.x", "X.y", "Y.x", "Y.y", "O.x", "O.y"]],
}
var _min_edit: LineEdit
var _max_edit: LineEdit
var _min_length_edit: LineEdit
var _max_length_edit: LineEdit
var _pattern_edit: LineEdit
var _enum_container: Control
var _enum_values_edit: TextEdit
var _array_container: Control
var _array_element_type_option: OptionButton
var _apply_field_btn: Button
var _default_file_dialog: FileDialog
var _default_resource_uid: String = ""
var _suppress_type_callbacks: bool = false
var _type_picker_opening: bool = false
var _type_picker_prev_field_type_value: String = "string"
var _type_picker_prev_array_element_type_value: String = "string"


func _ready() -> void:
	title = "字段设置"
	size = Vector2(1000, 800) # 增加宽度避免内容被遮挡
	min_size = Vector2(900, 650)
	_grip_icon = _get_grip_icon()
	_setup_ui()
	confirmed.connect(_on_confirmed)
	visibility_changed.connect(_on_visibility_changed)


func _get_popup_host() -> Node:
	# 在编辑器里，Window 类型的弹窗更稳妥的做法是挂到根 Window 下，
	# 避免作为另一个弹窗的子节点导致无法弹出/被遮挡。
	var tree := get_tree()
	if tree and tree.root:
		return tree.root
	return self


func _attach_popup_to_host(popup: Node) -> void:
	if not popup:
		return
	var host := _get_popup_host()
	if not host:
		host = self
	if popup.get_parent() == host:
		return
	if popup.get_parent():
		popup.get_parent().remove_child(popup)
	host.add_child(popup)


func open_for_column(column_index: int = -1) -> void:
	_hide_type_picker()
	_cleanup_default_file_dialog()
	_refresh_from_model()

	var target := column_index
	if target < 0:
		target = 0

	if _field_list.get_item_count() > 0:
		target = clampi(target, 0, _field_list.get_item_count() - 1)
		_field_list.select(target)
		_on_field_selected(target)

	# 初始状态：若没有任何约束值，则隐藏约束区
	_update_type_dependent_ui(_get_selected_type())

	popup_centered()


func _ensure_type_picker_dialog() -> void:
	if _type_picker_dialog and is_instance_valid(_type_picker_dialog):
		_attach_popup_to_host(_type_picker_dialog)
		return
	_type_picker_dialog = TypePickerDialog.new()
	_type_picker_dialog.type_picked.connect(_on_type_picked)
	_type_picker_dialog.cancelled.connect(_on_type_pick_cancelled)
	_attach_popup_to_host(_type_picker_dialog)
	_type_picker_dialog.hide()


func _hide_type_picker() -> void:
	if _type_picker_dialog and is_instance_valid(_type_picker_dialog):
		_type_picker_dialog.hide()


func _open_type_picker(target: String, current_value: String) -> void:
	if _type_picker_opening:
		return
	_type_picker_opening = true
	call_deferred("_reset_type_picker_opening")
	_type_picker_target = target
	_ensure_type_picker_dialog()
	# 避免在 OptionButton 的 PopupMenu 关闭过程中弹出新窗口导致无响应。
	_type_picker_dialog.call_deferred("pick", current_value)


func _reset_type_picker_opening() -> void:
	_type_picker_opening = false


func _on_type_picked(type_name: String) -> void:
	var picked := str(type_name).strip_edges()
	if picked.is_empty():
		_type_picker_target = ""
		return

	if _type_picker_target == "field_type":
		_last_field_type_value = _select_option_value(_type_option, picked, _field_type_custom_index)
		if _constraints_enable_checkbox:
			_constraints_enable_checkbox.disabled = not _is_constraints_supported_for_type(_last_field_type_value)
			if _constraints_enable_checkbox.disabled:
				_constraints_enable_checkbox.button_pressed = false
		_update_type_dependent_ui(_last_field_type_value)
	elif _type_picker_target == "array_element_type":
		_last_array_element_type_value = picked

	_type_picker_target = ""


func _on_type_pick_cancelled() -> void:
	# 取消选择：恢复到弹出前的类型（避免“更多”被选中后无法再次打开）
	var prev_suppress := _suppress_type_callbacks
	_suppress_type_callbacks = true
	if _type_picker_target == "field_type":
		_last_field_type_value = _select_option_value(_type_option, _type_picker_prev_field_type_value, _field_type_custom_index)
		_update_type_dependent_ui(_last_field_type_value)
	elif _type_picker_target == "array_element_type":
		_last_array_element_type_value = _type_picker_prev_array_element_type_value
	_suppress_type_callbacks = prev_suppress
	_type_picker_target = ""

func _setup_ui() -> void:
	_split = HSplitContainer.new()
	_split.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_split)

	# 左侧：字段列表
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	left.custom_minimum_size = Vector2(260, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_split.add_child(left)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 6)
	left.add_child(header_row)

	var hint := Label.new()
	hint.text = "字段列表（拖动左侧握把排序）"
	hint.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	header_row.add_child(hint)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(spacer)

	_add_field_btn = Button.new()
	_add_field_btn.text = ""
	_add_field_btn.tooltip_text = "在末尾追加字段"
	_add_field_btn.custom_minimum_size = Vector2(28, 0)
	_add_field_btn.add_theme_stylebox_override("normal", get_theme_stylebox("panel", "Panel"))
	_add_field_btn.add_theme_stylebox_override("hover", get_theme_stylebox("panel", "Panel"))
	_add_field_btn.add_theme_stylebox_override("pressed", get_theme_stylebox("panel", "Panel"))
	if has_theme_icon("Add", "EditorIcons"):
		_add_field_btn.icon = get_theme_icon("Add", "EditorIcons")
	else:
		_add_field_btn.text = "+"
	_add_field_btn.pressed.connect(_on_add_field_pressed)
	header_row.add_child(_add_field_btn)

	_remove_field_btn = Button.new()
	_remove_field_btn.text = ""
	_remove_field_btn.tooltip_text = "移除选中字段"
	_remove_field_btn.custom_minimum_size = Vector2(28, 0)
	_remove_field_btn.add_theme_stylebox_override("normal", get_theme_stylebox("panel", "Panel"))
	_remove_field_btn.add_theme_stylebox_override("hover", get_theme_stylebox("panel", "Panel"))
	_remove_field_btn.add_theme_stylebox_override("pressed", get_theme_stylebox("panel", "Panel"))
	if has_theme_icon("Remove", "EditorIcons"):
		_remove_field_btn.icon = get_theme_icon("Remove", "EditorIcons")
	else:
		_remove_field_btn.text = "-"
	_remove_field_btn.pressed.connect(_on_remove_field_pressed)
	header_row.add_child(_remove_field_btn)

	_field_list = ReorderableItemList.new()
	_field_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_field_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_field_list.drag_handle_width = 28.0
	_field_list.allow_rmb_select = true
	_field_list.item_selected.connect(_on_field_selected)
	_field_list.reorder_requested.connect(_on_reorder_requested)
	left.add_child(_field_list)

	# 右侧：字段编辑
	var right_scroll := ScrollContainer.new()
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_split.add_child(right_scroll)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(right)

	var basic := _create_section("基本", right)
	_name_edit = _create_line_setting(basic, "字段名：", "FieldName")
	_type_option = _create_type_setting(basic)
	_constraints_enable_checkbox = _create_checkbox_setting(basic, "启用约束", "EnableConstraints")
	_constraints_enable_checkbox.toggled.connect(_on_constraints_toggled)
	_required_checkbox = _create_checkbox_setting(basic, "必填（required）", "Required")
	_default_edit = _create_default_setting(basic)

	_constraints_root = VBoxContainer.new()
	right.add_child(_constraints_root)
	var constraints := _create_section("约束", _constraints_root)
	_min_edit = _create_line_setting(constraints, "最小值（min）：", "Min")
	_max_edit = _create_line_setting(constraints, "最大值（max）：", "Max")
	_min_length_edit = _create_line_setting(constraints, "最小长度（min_length）：", "MinLength")
	_max_length_edit = _create_line_setting(constraints, "最大长度（max_length）：", "MaxLength")
	_pattern_edit = _create_line_setting(constraints, "正则（pattern）：", "Pattern")

	_enum_container = VBoxContainer.new()
	_enum_container.visible = false
	right.add_child(_enum_container)
	var enum_section := _create_section("枚举值（enum）", _enum_container as VBoxContainer)
	_enum_values_edit = TextEdit.new()
	_enum_values_edit.custom_minimum_size = Vector2(0, 120)
	_enum_values_edit.text_changed.connect(_on_enum_values_text_changed)
	enum_section.add_child(_enum_values_edit)

	# Array 的元素类型选择并入“默认值”一行（以下拉框形式），
	# 这里不再额外创建一个分区容器，避免覆盖 _create_default_setting() 创建的下拉框引用。
	# （默认值行中的下拉框节点引用：_array_container / _array_element_type_option）

	_right_spacer = Control.new()
	_right_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_right_spacer)

	var actions := CenterContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(actions)
	_apply_field_btn = Button.new()
	_apply_field_btn.text = "应用到当前字段"
	_apply_field_btn.pressed.connect(_apply_current_field_changes)
	actions.add_child(_apply_field_btn)


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
	label.custom_minimum_size.x = 170
	hbox.add_child(label)

	var edit := LineEdit.new()
	edit.name = node_name
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(edit)

	parent.add_child(hbox)
	return edit


func _create_default_setting(parent: VBoxContainer) -> LineEdit:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = "默认值："
	label.custom_minimum_size.x = 170
	hbox.add_child(label)

	# 使用 VBoxContainer 以支持同时显示文本输入和专用输入控件
	_default_editor_root = VBoxContainer.new()
	_default_editor_root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_default_editor_root.add_theme_constant_override("separation", 4)
	hbox.add_child(_default_editor_root)

	# 1) 文本（string / stringname / resource / json 等）
	_default_text_container = HBoxContainer.new()
	_default_text_container.add_theme_constant_override("separation", 8)
	_default_editor_root.add_child(_default_text_container)

	_default_edit = LineEdit.new()
	_default_edit.name = "DefaultValue"
	_default_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_default_edit.text_changed.connect(_on_default_text_changed)
	_default_text_container.add_child(_default_edit)

	# 1.1) Array：默认值=元素类型（下拉选择），不再额外显示“数组元素类型”分区
	var default_array_type_container := HBoxContainer.new()
	default_array_type_container.name = "DefaultArrayTypeContainer"
	default_array_type_container.add_theme_constant_override("separation", 8)
	default_array_type_container.visible = false
	_default_editor_root.add_child(default_array_type_container)

	var default_array_type_option := OptionButton.new()
	default_array_type_option.name = "DefaultArrayElementType"
	default_array_type_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for i in range(ARRAY_ELEMENT_TYPE_VALUES.size()):
		_add_option_item_with_meta(default_array_type_option, "%s (%s)" % [ARRAY_ELEMENT_TYPE_LABELS[i], ARRAY_ELEMENT_TYPE_VALUES[i]], ARRAY_ELEMENT_TYPE_VALUES[i])
	default_array_type_option.item_selected.connect(_on_default_array_element_type_selected)
	default_array_type_container.add_child(default_array_type_option)

	# 复用既有字段（避免新增一堆成员变量）
	_array_container = default_array_type_container
	_array_element_type_option = default_array_type_option

	_default_browse_btn = Button.new()
	_default_browse_btn.text = "..."
	_default_browse_btn.tooltip_text = "选择资源"
	_default_browse_btn.custom_minimum_size = Vector2(32, 0)
	_default_browse_btn.visible = false
	_default_browse_btn.pressed.connect(_on_browse_default_pressed)
	_default_text_container.add_child(_default_browse_btn)

	_default_uid_label = Label.new()
	_default_uid_label.name = "DefaultUIDLabel"
	_default_uid_label.text = "UID：-"
	_default_uid_label.visible = false
	_default_uid_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	_default_uid_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_default_editor_root.add_child(_default_uid_label)

	# 2) bool：CheckBox + 清空按钮
	_default_bool_container = HBoxContainer.new()
	_default_bool_container.add_theme_constant_override("separation", 8)
	_default_bool_container.visible = false
	_default_editor_root.add_child(_default_bool_container)

	_default_bool_checkbox = CheckBox.new()
	_default_bool_checkbox.text = "默认值"
	_default_bool_checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_default_bool_checkbox.toggled.connect(_on_default_bool_toggled)
	_default_bool_container.add_child(_default_bool_checkbox)

	_default_bool_clear_btn = Button.new()
	_default_bool_clear_btn.text = "清空"
	_default_bool_clear_btn.tooltip_text = "清空默认值（使用类型默认值）"
	_default_bool_clear_btn.pressed.connect(_on_default_bool_clear_pressed)
	_default_bool_container.add_child(_default_bool_clear_btn)

	# 3) int
	_default_int_container = HBoxContainer.new()
	_default_int_container.add_theme_constant_override("separation", 8)
	_default_int_container.visible = false
	_default_editor_root.add_child(_default_int_container)
	_default_int_spin = SpinBox.new()
	_default_int_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_default_int_spin.step = 1.0
	_default_int_spin.allow_greater = true
	_default_int_spin.allow_lesser = true
	_default_int_spin.value_changed.connect(_on_default_int_value_changed)
	_default_int_container.add_child(_default_int_spin)
	_default_int_clear_btn = Button.new()
	_default_int_clear_btn.text = "清空"
	_default_int_clear_btn.tooltip_text = "清空默认值（使用类型默认值）"
	_default_int_clear_btn.pressed.connect(_on_default_int_clear_pressed)
	_default_int_container.add_child(_default_int_clear_btn)

	# 4) float
	_default_float_container = HBoxContainer.new()
	_default_float_container.add_theme_constant_override("separation", 8)
	_default_float_container.visible = false
	_default_editor_root.add_child(_default_float_container)
	_default_float_spin = SpinBox.new()
	_default_float_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_default_float_spin.step = 0.01
	_default_float_spin.allow_greater = true
	_default_float_spin.allow_lesser = true
	_default_float_spin.value_changed.connect(_on_default_float_value_changed)
	_default_float_container.add_child(_default_float_spin)
	_default_float_clear_btn = Button.new()
	_default_float_clear_btn.text = "清空"
	_default_float_clear_btn.tooltip_text = "清空默认值（使用类型默认值）"
	_default_float_clear_btn.pressed.connect(_on_default_float_clear_pressed)
	_default_float_container.add_child(_default_float_clear_btn)

	# 5) Vector2
	_default_vec2_container = HBoxContainer.new()
	_default_vec2_container.add_theme_constant_override("separation", 8)
	_default_vec2_container.visible = false
	_default_editor_root.add_child(_default_vec2_container)
	_default_vec2_x = SpinBox.new()
	_default_vec2_x.step = 0.01
	_default_vec2_x.allow_greater = true
	_default_vec2_x.allow_lesser = true
	_default_vec2_x.value_changed.connect(_on_default_vec2_changed)
	_default_vec2_container.add_child(_default_vec2_x)
	_default_vec2_y = SpinBox.new()
	_default_vec2_y.step = 0.01
	_default_vec2_y.allow_greater = true
	_default_vec2_y.allow_lesser = true
	_default_vec2_y.value_changed.connect(_on_default_vec2_changed)
	_default_vec2_container.add_child(_default_vec2_y)
	_default_vec2_clear_btn = Button.new()
	_default_vec2_clear_btn.text = "清空"
	_default_vec2_clear_btn.tooltip_text = "清空默认值（使用类型默认值）"
	_default_vec2_clear_btn.pressed.connect(_on_default_vec2_clear_pressed)
	_default_vec2_container.add_child(_default_vec2_clear_btn)

	# 6) Vector3
	_default_vec3_container = HBoxContainer.new()
	_default_vec3_container.add_theme_constant_override("separation", 8)
	_default_vec3_container.visible = false
	_default_editor_root.add_child(_default_vec3_container)
	_default_vec3_x = SpinBox.new()
	_default_vec3_x.step = 0.01
	_default_vec3_x.allow_greater = true
	_default_vec3_x.allow_lesser = true
	_default_vec3_x.value_changed.connect(_on_default_vec3_changed)
	_default_vec3_container.add_child(_default_vec3_x)
	_default_vec3_y = SpinBox.new()
	_default_vec3_y.step = 0.01
	_default_vec3_y.allow_greater = true
	_default_vec3_y.allow_lesser = true
	_default_vec3_y.value_changed.connect(_on_default_vec3_changed)
	_default_vec3_container.add_child(_default_vec3_y)
	_default_vec3_z = SpinBox.new()
	_default_vec3_z.step = 0.01
	_default_vec3_z.allow_greater = true
	_default_vec3_z.allow_lesser = true
	_default_vec3_z.value_changed.connect(_on_default_vec3_changed)
	_default_vec3_container.add_child(_default_vec3_z)
	_default_vec3_clear_btn = Button.new()
	_default_vec3_clear_btn.text = "清空"
	_default_vec3_clear_btn.tooltip_text = "清空默认值（使用类型默认值）"
	_default_vec3_clear_btn.pressed.connect(_on_default_vec3_clear_pressed)
	_default_vec3_container.add_child(_default_vec3_clear_btn)

	# 7) Color
	_default_color_container = HBoxContainer.new()
	_default_color_container.add_theme_constant_override("separation", 8)
	_default_color_container.visible = false
	_default_editor_root.add_child(_default_color_container)
	_default_color_picker = ColorPickerButton.new()
	_default_color_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_default_color_picker.color_changed.connect(_on_default_color_changed)
	_default_color_container.add_child(_default_color_picker)
	_default_color_clear_btn = Button.new()
	_default_color_clear_btn.text = "清空"
	_default_color_clear_btn.tooltip_text = "清空默认值（使用类型默认值）"
	_default_color_clear_btn.pressed.connect(_on_default_color_clear_pressed)
	_default_color_container.add_child(_default_color_clear_btn)

	# 8) enum：下拉选择
	_default_enum_container = HBoxContainer.new()
	_default_enum_container.add_theme_constant_override("separation", 8)
	_default_enum_container.visible = false
	_default_editor_root.add_child(_default_enum_container)
	_default_enum_option = OptionButton.new()
	_default_enum_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_default_enum_option.item_selected.connect(_on_default_enum_selected)
	_default_enum_container.add_child(_default_enum_option)
	_rebuild_default_enum_options()

	# 9) 通用多值输入（Vector2i, Vector3i, Vector4, Vector4i, Rect2, Rect2i 等）
	_default_multi_value_container = HBoxContainer.new()
	_default_multi_value_container.add_theme_constant_override("separation", 4)
	_default_multi_value_container.visible = false
	_default_editor_root.add_child(_default_multi_value_container)

	_default_multi_value_clear_btn = Button.new()
	_default_multi_value_clear_btn.text = "清空"
	_default_multi_value_clear_btn.tooltip_text = "清空默认值（使用类型默认值）"
	_default_multi_value_clear_btn.pressed.connect(_on_default_multi_value_clear_pressed)
	_default_multi_value_container.add_child(_default_multi_value_clear_btn)

	parent.add_child(hbox)
	return _default_edit


func _show_default_editor_for_type(data_type: String) -> void:
	var t := str(data_type).to_lower()

	# 隐藏所有专用输入控件
	if _default_bool_container:
		_default_bool_container.visible = false
	if _default_int_container:
		_default_int_container.visible = false
	if _default_float_container:
		_default_float_container.visible = false
	if _default_vec2_container:
		_default_vec2_container.visible = false
	if _default_vec3_container:
		_default_vec3_container.visible = false
	if _default_color_container:
		_default_color_container.visible = false
	if _default_enum_container:
		_default_enum_container.visible = false
	if _default_multi_value_container:
		_default_multi_value_container.visible = false

	# Array / PackedArray：
	# - Array：默认值下拉=元素类型（同时保存 array_element_type；字段默认值由元素类型默认值推导）
	# - PackedArray：不支持字段默认值（避免 schema 默认值影响 packed 的空值策略）
	if t.begins_with("array") or t.begins_with("packed"):
		# 从资源类切换到 Array 时，必须确保 UID 文本行被隐藏。
		if _default_uid_label:
			_default_uid_label.visible = false

		if t.begins_with("packed"):
			if _default_text_container:
				_default_text_container.visible = true
			if _array_container:
				_array_container.visible = false
			if _default_edit:
				_default_edit.editable = false
				_default_edit.placeholder_text = "PackedArray 不支持默认值设置"
				_default_edit.text = ""
			return

		# Array
		# 默认值以下拉框形式选择元素类型即可。
		# 注意：不要把 _default_text_container 隐藏（它承载默认值行的基础布局/高度），
		# 仅隐藏 LineEdit 自身，避免出现“整块区域高度为0，看起来空白”的情况。
		if _default_text_container:
			_default_text_container.visible = true
		if _default_edit:
			_default_edit.visible = false
		if _default_browse_btn:
			_default_browse_btn.visible = false
		if _array_container:
			_array_container.visible = true
		if _array_element_type_option:
			_last_array_element_type_value = _select_option_value(_array_element_type_option, _get_selected_array_element_type(), -1)
		return

	# 默认显示文本输入框
	if _default_text_container:
		_default_text_container.visible = true
	if _default_edit:
		_default_edit.visible = true
		_default_edit.editable = true
		_default_edit.placeholder_text = "在此输入默认值"
	if _default_uid_label:
		_default_uid_label.visible = false

	# 检查是否是多值类型
	if MULTI_VALUE_TYPE_CONFIG.has(t):
		_default_text_container.visible = false
		_setup_multi_value_editor(t)
		_default_multi_value_container.visible = true
		return

	match t:
		"bool":
			_default_text_container.visible = false
			_default_bool_container.visible = true
		"int":
			_default_text_container.visible = false
			_default_int_container.visible = true
		"float":
			_default_text_container.visible = false
			_default_float_container.visible = true
		"vector2":
			_default_text_container.visible = false
			_default_vec2_container.visible = true
		"vector3":
			_default_text_container.visible = false
			_default_vec3_container.visible = true
		"color":
			_default_text_container.visible = false
			_default_color_container.visible = true
		"enum":
			_default_text_container.visible = false
			_default_enum_container.visible = true
		_:
			# 其他类型只显示文本输入框
			_default_text_container.visible = true

	# 资源类型：显示 UID 行
	if _default_uid_label:
		var is_resource := t == "resource" or t.begins_with("resource")
		is_resource = is_resource or t in ["texture2d", "packedscene", "audiostream", "material", "shader", "font", "theme"]
		_default_uid_label.visible = is_resource

	_sync_default_editor_from_text(t)
	_update_default_uid_label_from_text()


func _sync_default_editor_from_text(data_type_lower: String) -> void:
	if _suppress_default_sync:
		return
	_suppress_default_sync = true
	var text := _default_edit.text.strip_edges() if _default_edit else ""

	# 检查是否是多值类型
	if MULTI_VALUE_TYPE_CONFIG.has(data_type_lower):
		var parts := _parse_number_list(text)
		var config: Array = MULTI_VALUE_TYPE_CONFIG[data_type_lower]
		var component_count: int = config[0]

		for i in range(min(_default_multi_value_spins.size(), component_count)):
			if i < parts.size():
				_default_multi_value_spins[i].value = parts[i]
			else:
				_default_multi_value_spins[i].value = 0

		_suppress_default_sync = false
		_update_default_clear_buttons()
		return

	match data_type_lower:
		"bool":
			if _default_bool_checkbox:
				var v := text.to_lower()
				if v == "true" or v == "1":
					_default_bool_checkbox.button_pressed = true
				elif v == "false" or v == "0":
					_default_bool_checkbox.button_pressed = false
				else:
					_default_bool_checkbox.button_pressed = false
		"int":
			if _default_int_spin:
				if text.is_valid_int():
					_default_int_spin.value = text.to_int()
				else:
					_default_int_spin.value = 0
		"float":
			if _default_float_spin:
				if text.is_valid_float():
					_default_float_spin.value = text.to_float()
				else:
					_default_float_spin.value = 0.0
		"vector2":
			var parts := _parse_number_list(text)
			if parts.size() >= 2:
				_default_vec2_x.value = parts[0]
				_default_vec2_y.value = parts[1]
			else:
				_default_vec2_x.value = 0.0
				_default_vec2_y.value = 0.0
		"vector3":
			var parts := _parse_number_list(text)
			if parts.size() >= 3:
				_default_vec3_x.value = parts[0]
				_default_vec3_y.value = parts[1]
				_default_vec3_z.value = parts[2]
			else:
				_default_vec3_x.value = 0.0
				_default_vec3_y.value = 0.0
				_default_vec3_z.value = 0.0
		"color":
			if _default_color_picker:
				_default_color_picker.disabled = false
				_default_color_picker.color = _parse_color(text) if not text.is_empty() else Color(1, 1, 1, 1)
		"enum":
			_rebuild_default_enum_options()
			if _default_enum_option:
				var idx := _find_option_text_index(_default_enum_option, text)
				_default_enum_option.select(idx if idx >= 0 else 0)
		_:
			# 文本类型不需要同步
			pass

	_suppress_default_sync = false
	_update_default_clear_buttons()


func _set_vec_spin_enabled(spin: SpinBox, enabled: bool) -> void:
	if not spin:
		return
	spin.editable = enabled


func _parse_number_list(text: String) -> Array[float]:
	var cleaned := str(text).strip_edges()
	cleaned = cleaned.replace("(", "").replace(")", "")
	cleaned = cleaned.replace("[", "").replace("]", "")
	var parts := cleaned.split(",", false)
	var out: Array[float] = []
	for p in parts:
		var s := str(p).strip_edges()
		if s.is_valid_float():
			out.append(s.to_float())
	return out


func _parse_color(text: String) -> Color:
	var s := str(text).strip_edges()
	if s.begins_with("#"):
		var hex := s.substr(1)
		if hex.length() == 6 or hex.length() == 8:
			var r := hex.substr(0, 2).hex_to_int()
			var g := hex.substr(2, 2).hex_to_int()
			var b := hex.substr(4, 2).hex_to_int()
			var a := 255
			if hex.length() == 8:
				a = hex.substr(6, 2).hex_to_int()
			return Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0)
	# 兜底：尝试解析 r,g,b,a
	var parts := _parse_number_list(s)
	if parts.size() >= 3:
		var a := parts[3] if parts.size() >= 4 else 1.0
		return Color(parts[0], parts[1], parts[2], a)
	return Color(1, 1, 1, 1)


func _color_to_hex(c: Color) -> String:
	var r := clampi(int(round(c.r * 255.0)), 0, 255)
	var g := clampi(int(round(c.g * 255.0)), 0, 255)
	var b := clampi(int(round(c.b * 255.0)), 0, 255)
	var a := clampi(int(round(c.a * 255.0)), 0, 255)
	return "#%02X%02X%02X%02X" % [r, g, b, a]


func _find_option_text_index(option: OptionButton, text: String) -> int:
	var t := str(text).strip_edges()
	if t.is_empty():
		return 0
	for i in range(option.get_item_count()):
		if str(option.get_item_text(i)).strip_edges() == t:
			return i
	return -1


func _rebuild_default_enum_options() -> void:
	if not _default_enum_option:
		return
	var prev := _default_edit.text.strip_edges() if _default_edit else ""
	_default_enum_option.clear()
	_default_enum_option.add_item("（无）")
	var values := _parse_list_values(_enum_values_edit.text if _enum_values_edit else "")
	for v in values:
		_default_enum_option.add_item(v)
	var idx := _find_option_text_index(_default_enum_option, prev)
	_default_enum_option.select(idx if idx >= 0 else 0)


func _on_enum_values_text_changed() -> void:
	# 枚举值变化时，刷新默认值下拉（仅在 enum 类型时可见）
	_rebuild_default_enum_options()


func _on_default_bool_toggled(pressed: bool) -> void:
	if _suppress_default_sync:
		return
	if not _default_edit:
		return
	_default_edit.text = "true" if pressed else "false"
	_update_default_clear_buttons()


func _on_default_bool_clear_pressed() -> void:
	if _default_edit:
		_default_edit.text = ""
	if _default_bool_checkbox:
		_suppress_default_sync = true
		_default_bool_checkbox.button_pressed = false
		_suppress_default_sync = false
	_update_default_clear_buttons()


func _on_default_int_value_changed(_value: float) -> void:
	if _suppress_default_sync:
		return
	if _default_edit and _default_int_spin:
		_default_edit.text = str(int(_default_int_spin.value))
	_update_default_clear_buttons()


func _on_default_float_value_changed(_value: float) -> void:
	if _suppress_default_sync:
		return
	if _default_edit and _default_float_spin:
		_default_edit.text = str(_default_float_spin.value)
	_update_default_clear_buttons()


func _on_default_vec2_changed(_value: float) -> void:
	if _suppress_default_sync:
		return
	if _default_edit and _default_vec2_x and _default_vec2_y:
		_default_edit.text = "%s,%s" % [str(_default_vec2_x.value), str(_default_vec2_y.value)]
	_update_default_clear_buttons()


func _on_default_vec3_changed(_value: float) -> void:
	if _suppress_default_sync:
		return
	if _default_edit and _default_vec3_x and _default_vec3_y and _default_vec3_z:
		_default_edit.text = "%s,%s,%s" % [str(_default_vec3_x.value), str(_default_vec3_y.value), str(_default_vec3_z.value)]
	_update_default_clear_buttons()


func _on_default_color_changed(c: Color) -> void:
	if _suppress_default_sync:
		return
	if _default_edit:
		_default_edit.text = _color_to_hex(c)
	_update_default_clear_buttons()


func _on_default_enum_selected(index: int) -> void:
	if _suppress_default_sync:
		return
	if not _default_edit or not _default_enum_option:
		return
	if index <= 0:
		_default_edit.text = ""
	else:
		_default_edit.text = str(_default_enum_option.get_item_text(index)).strip_edges()
	_update_default_clear_buttons()


func _update_default_clear_buttons() -> void:
	var has := false
	if _default_edit:
		has = not _default_edit.text.strip_edges().is_empty()
	if _default_int_clear_btn:
		_default_int_clear_btn.disabled = not has
	if _default_float_clear_btn:
		_default_float_clear_btn.disabled = not has
	if _default_vec2_clear_btn:
		_default_vec2_clear_btn.disabled = not has
	if _default_vec3_clear_btn:
		_default_vec3_clear_btn.disabled = not has
	if _default_color_clear_btn:
		_default_color_clear_btn.disabled = not has
	if _default_multi_value_clear_btn:
		_default_multi_value_clear_btn.disabled = not has


func _setup_multi_value_editor(data_type: String) -> void:
	"""动态创建多值输入控件（Vector2i, Vector3i, Vector4, Vector4i, Rect2, Rect2i 等）"""
	if not MULTI_VALUE_TYPE_CONFIG.has(data_type):
		return

	var config: Array = MULTI_VALUE_TYPE_CONFIG[data_type]
	var component_count: int = config[0]
	var is_integer: bool = config[1]
	var labels: Array = config[2]

	# 清空现有的 SpinBox
	for spin in _default_multi_value_spins:
		if spin and is_instance_valid(spin):
			spin.queue_free()
	_default_multi_value_spins.clear()

	# 移除清空按钮（稍后重新添加到末尾）
	if _default_multi_value_clear_btn and _default_multi_value_clear_btn.get_parent():
		_default_multi_value_container.remove_child(_default_multi_value_clear_btn)

	# 创建新的 SpinBox
	for i in range(component_count):
		var spin := SpinBox.new()
		spin.step = 1.0 if is_integer else 0.01
		spin.allow_greater = true
		spin.allow_lesser = true
		spin.custom_minimum_size = Vector2(60, 0)
		spin.value_changed.connect(_on_default_multi_value_changed)

		# 添加标签（如果有）
		if i < labels.size():
			spin.prefix = labels[i] + ": "

		_default_multi_value_container.add_child(spin)
		_default_multi_value_spins.append(spin)

	# 重新添加清空按钮到末尾
	if _default_multi_value_clear_btn:
		_default_multi_value_container.add_child(_default_multi_value_clear_btn)


func _on_default_multi_value_changed(_value: float) -> void:
	"""多值输入控件值变化时同步到文本编辑器"""
	if _suppress_default_sync:
		return
	if not _default_edit:
		return

	var values: PackedStringArray = []
	for spin in _default_multi_value_spins:
		if spin and is_instance_valid(spin):
			values.append(str(spin.value))

	_default_edit.text = ",".join(values)
	_update_default_clear_buttons()


func _on_default_array_element_type_selected(index: int) -> void:
	if _suppress_type_callbacks:
		return
	if not _array_element_type_option:
		return
	var meta := _get_option_meta(_array_element_type_option, index)
	if meta.is_empty():
		return
	_last_array_element_type_value = meta
	# Array 默认值 UI 为“元素类型下拉”，无需同步 _default_edit。


func _on_default_multi_value_clear_pressed() -> void:
	"""清空多值输入控件"""
	if _default_edit:
		_default_edit.text = ""

	_suppress_default_sync = true
	for spin in _default_multi_value_spins:
		if spin and is_instance_valid(spin):
			spin.value = 0
	_suppress_default_sync = false

	_update_default_clear_buttons()


func _on_default_int_clear_pressed() -> void:
	if _default_edit:
		_default_edit.text = ""
	_sync_default_editor_from_text("int")


func _on_default_float_clear_pressed() -> void:
	if _default_edit:
		_default_edit.text = ""
	_sync_default_editor_from_text("float")


func _on_default_vec2_clear_pressed() -> void:
	if _default_edit:
		_default_edit.text = ""
	_sync_default_editor_from_text("vector2")


func _on_default_vec3_clear_pressed() -> void:
	if _default_edit:
		_default_edit.text = ""
	_sync_default_editor_from_text("vector3")


func _on_default_color_clear_pressed() -> void:
	if _default_edit:
		_default_edit.text = ""
	_sync_default_editor_from_text("color")


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
	label.custom_minimum_size.x = 170
	hbox.add_child(label)

	var option := OptionButton.new()
	option.name = "FieldType"
	for i in range(TYPE_VALUES.size()):
		_add_option_item_with_meta(option, "%s (%s)" % [TYPE_LABELS[i], TYPE_VALUES[i]], TYPE_VALUES[i])
	# 仅保留一个“更多”入口：用于弹出类型选择弹窗；更多类型默认按字符串处理。
	_field_type_more_index = _add_option_item_with_meta(option, _MORE_ITEM_DEFAULT_TEXT, _OPTION_META_MORE)
	_field_type_custom_index = _field_type_more_index
	option.item_selected.connect(_on_type_selected)
	var popup := option.get_popup()
	if popup:
		if popup.has_signal("index_pressed"):
			popup.connect("index_pressed", Callable(self, "_on_field_type_popup_index_pressed"))
		if popup.has_signal("id_pressed"):
			popup.connect("id_pressed", Callable(self, "_on_field_type_popup_id_pressed"))
	hbox.add_child(option)

	parent.add_child(hbox)
	return option


func _create_array_element_type_setting(parent: VBoxContainer) -> OptionButton:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = "元素类型："
	label.custom_minimum_size.x = 170
	hbox.add_child(label)

	var option := OptionButton.new()
	option.name = "ArrayElementType"
	for i in range(ARRAY_ELEMENT_TYPE_VALUES.size()):
		_add_option_item_with_meta(option, "%s (%s)" % [ARRAY_ELEMENT_TYPE_LABELS[i], ARRAY_ELEMENT_TYPE_VALUES[i]], ARRAY_ELEMENT_TYPE_VALUES[i])
	# 仅保留一个“更多”入口：用于弹出类型选择弹窗；更多类型默认按字符串处理。
	_array_type_more_index = _add_option_item_with_meta(option, _MORE_ITEM_DEFAULT_TEXT, _OPTION_META_MORE)
	_array_type_custom_index = _array_type_more_index
	option.item_selected.connect(_on_array_element_type_selected)
	var popup := option.get_popup()
	if popup:
		if popup.has_signal("index_pressed"):
			popup.connect("index_pressed", Callable(self, "_on_array_type_popup_index_pressed"))
		if popup.has_signal("id_pressed"):
			popup.connect("id_pressed", Callable(self, "_on_array_type_popup_id_pressed"))
	hbox.add_child(option)

	parent.add_child(hbox)
	return option


func _add_option_item_with_meta(option: OptionButton, text: String, meta: String) -> int:
	option.add_item(text)
	var idx := option.get_item_count() - 1
	var popup := option.get_popup()
	if popup:
		popup.set_item_metadata(idx, meta)
	return idx


func _get_option_meta(option: OptionButton, index: int) -> String:
	var popup := option.get_popup()
	if not popup:
		return ""
	var meta := popup.get_item_metadata(index)
	return str(meta) if meta != null else ""


func _select_option_value(option: OptionButton, value: String, custom_index: int) -> String:
	var target := str(value).strip_edges()
	if target.is_empty():
		target = "string"

	var target_lower := target.to_lower()
	var prefer_custom := target != target_lower
	for i in range(option.get_item_count()):
		var meta := _get_option_meta(option, i)
		if meta.is_empty() or meta == _OPTION_META_MORE:
			continue
		if meta == target:
			option.select(i)
			if custom_index >= 0:
				option.set_item_text(custom_index, _MORE_ITEM_DEFAULT_TEXT)
			return meta
		if not prefer_custom and meta.to_lower() == target_lower:
			option.select(i)
			if custom_index >= 0:
				option.set_item_text(custom_index, _MORE_ITEM_DEFAULT_TEXT)
			return meta

	if custom_index >= 0:
		# 支持自定义类型：更多类型（如 Vector2i, Color 等）需要正确返回。
		# 保持 metadata 为 _OPTION_META_MORE，这样再次选择时仍能打开类型选择弹窗。
		option.set_item_text(custom_index, _MORE_ITEM_PREFIX + target)
		option.select(custom_index)
	return target

func _refresh_from_model() -> void:
	var saved_column := _current_column
	_field_list.clear()
	_current_column = -1

	if not data_model:
		_apply_field_btn.disabled = true
		if _add_field_btn:
			_add_field_btn.disabled = true
		if _remove_field_btn:
			_remove_field_btn.disabled = true
		return

	var header := data_model.get_header()
	for i in range(header.size()):
		_field_list.add_item(header[i], _grip_icon)

	_apply_field_btn.disabled = header.is_empty()
	if _add_field_btn:
		_add_field_btn.disabled = false
	if _remove_field_btn:
		_remove_field_btn.disabled = header.is_empty() or _field_list.get_selected_items().is_empty()

	# 恢复之前选中的字段（如果有效）
	if saved_column >= 0 and saved_column < header.size():
		_field_list.select(saved_column)
		_on_field_selected(saved_column)


func _on_field_selected(index: int) -> void:
	# 如果正在恢复选中状态，不处理
	if _suppress_field_selection:
		return
	_current_column = index
	if _remove_field_btn:
		_remove_field_btn.disabled = false
	_load_field_from_model(index)


func _on_reorder_requested(from_index: int, to_index: int) -> void:
	if not data_model:
		return
	if from_index == to_index:
		return
	data_model.move_column(from_index, to_index)
	_schema_dirty = true
	_refresh_from_model()
	var target := clampi(to_index, 0, _field_list.get_item_count() - 1)
	_field_list.select(target)
	_on_field_selected(target)


func _load_field_from_model(column_index: int) -> void:
	if not data_model:
		return

	var header := data_model.get_header()
	if column_index < 0 or column_index >= header.size():
		return

	var definition := data_model.get_column_type_definition(column_index)
	definition = definition.duplicate()
	definition["name"] = header[column_index]

	var prev_suppress := _suppress_type_callbacks
	_suppress_type_callbacks = true

	_name_edit.text = str(definition.get("name", ""))

	var data_type := str(definition.get("type", "string")).strip_edges()
	_last_field_type_value = _select_option_value(_type_option, data_type, _field_type_custom_index)

	_required_checkbox.button_pressed = bool(definition.get("required", false))

	# Array/PackedArray 的默认值不使用文本框表示（Array 使用元素类型下拉；PackedArray 禁用默认值）
	# 注意：从 Array 切换到其它类型（或新建字段）时，必须把 Array 的下拉容器显式隐藏，
	# 否则会出现“默认值区域永远残留一个类型下拉”的错觉。
	var data_type_lower := str(definition.get("type", "string")).to_lower()
	if data_type_lower.begins_with("array") or data_type_lower.begins_with("packed"):
		_default_edit.text = ""
		_default_resource_uid = ""
	else:
		# 非 array：确保恢复为文本默认值编辑模式
		if _array_container:
			_array_container.visible = false
		if _default_edit:
			_default_edit.visible = true
			_default_edit.editable = true
			_default_edit.placeholder_text = "在此输入默认值"

		_default_resource_uid = "" if not definition.has("default_uid") else str(definition.get("default_uid", "")).strip_edges()
		if not _default_resource_uid.is_empty():
			var path := ResourceUID.get_id_path(ResourceUID.text_to_id(_default_resource_uid))
			_default_edit.text = path if not path.is_empty() else ""
		else:
			_default_edit.text = "" if not definition.has("default") else str(definition.get("default", ""))
	_min_edit.text = "" if not definition.has("min") else str(definition.get("min"))
	_max_edit.text = "" if not definition.has("max") else str(definition.get("max"))
	_min_length_edit.text = "" if not definition.has("min_length") else str(definition.get("min_length"))
	_max_length_edit.text = "" if not definition.has("max_length") else str(definition.get("max_length"))
	_pattern_edit.text = "" if not definition.has("pattern") else str(definition.get("pattern"))

	if _constraints_enable_checkbox:
		_constraints_enable_checkbox.disabled = not _is_constraints_supported_for_type(_last_field_type_value)
		_constraints_enable_checkbox.button_pressed = _has_any_constraints_set() and _is_constraints_supported_for_type(_last_field_type_value)

	_enum_values_edit.text = ""
	if definition.has("enum_values") and definition.enum_values is Array:
		var values: Array = definition.enum_values as Array
		var lines := PackedStringArray()
		for v in values:
			var s := str(v).strip_edges()
			if not s.is_empty():
				lines.append(s)
		_enum_values_edit.text = "\n".join(lines)

	var array_type := str(definition.get("array_element_type", "string")).strip_edges()
	_last_array_element_type_value = array_type if not array_type.is_empty() else "string"

	_update_type_dependent_ui(_last_field_type_value)
	_update_default_uid_label_from_text()
	_suppress_type_callbacks = prev_suppress


func _apply_current_field_changes() -> void:
	if not data_model:
		return
	if _current_column < 0:
		return

	var header := data_model.get_header()
	if _current_column >= header.size():
		return

	var old_definition := data_model.get_column_type_definition(_current_column).duplicate(true)
	var old_type := str(old_definition.get("type", "string")).strip_edges()

	var old_name := header[_current_column]
	var new_name := _name_edit.text.strip_edges()
	if new_name.is_empty():
		new_name = old_name

	if new_name != old_name:
		data_model.rename_column(_current_column, new_name)
		_schema_dirty = true

	var definition := _build_type_definition()
	definition["name"] = new_name

	var new_type := str(definition.get("type", "string")).strip_edges()
	if old_type != new_type:
		var on_failure := "default"
		var empty_policy := "use_default"
		if config_manager and is_instance_valid(config_manager):
			on_failure = str(config_manager.get_type_change_failure_policy()).strip_edges()
			empty_policy = str(config_manager.get_type_change_empty_policy()).strip_edges()
		data_model.convert_column_values(_current_column, definition, {
			"on_failure": on_failure,
			"empty_policy": empty_policy,
		})

	data_model.update_column_type(_current_column, definition)
	_schema_dirty = true

	if schema_manager and is_instance_valid(schema_manager):
		schema_manager.apply_type_definition_in_memory(_current_column, definition)

	# _refresh_from_model() 会自动恢复当前选择的字段，无需重复调用
	_refresh_from_model()


func _on_add_field_pressed() -> void:
	if not data_model:
		return

	var col_count := data_model.get_column_count()
	var new_name := _generate_new_field_name(col_count)
	data_model.insert_column(col_count, new_name, "")
	_schema_dirty = true

	_refresh_from_model()
	if _field_list.get_item_count() > 0:
		var target := clampi(col_count, 0, _field_list.get_item_count() - 1)
		_field_list.select(target)
		_on_field_selected(target)


func _on_remove_field_pressed() -> void:
	if not data_model:
		return

	var selected := _field_list.get_selected_items()
	if selected.is_empty():
		return

	var index := int(selected[0])
	if index < 0 or index >= data_model.get_column_count():
		return

	data_model.remove_column(index)
	_schema_dirty = true

	_refresh_from_model()
	var count := _field_list.get_item_count()
	if count <= 0:
		if _remove_field_btn:
			_remove_field_btn.disabled = true
		return

	var target := clampi(index, 0, count - 1)
	_field_list.select(target)
	_on_field_selected(target)


func _generate_new_field_name(preferred_index: int) -> String:
	var header := data_model.get_header() if data_model else PackedStringArray()

	var base := "Column_" + str(preferred_index + 1)
	if not (base in header):
		return base

	var i := preferred_index + 2
	while i < 100000:
		var name := "Column_" + str(i)
		if not (name in header):
			return name
		i += 1

	return "Column_" + str(Time.get_ticks_msec())


func _build_type_definition() -> Dictionary:
	var definition: Dictionary = {
		"type": _get_selected_type(),
		"required": _required_checkbox.button_pressed,
	}

	var default_text := _default_edit.text.strip_edges()
	var data_type_lower := str(definition.get("type", "string")).to_lower()

	# 默认值规则：
	# - PackedArray：不写入默认值
	# - Array：字段设置中默认值 UI 为“元素类型下拉”，不写入 definition.default（避免文本默认值与 UI 不一致）
	if data_type_lower.begins_with("packed"):
		pass
	elif data_type_lower == "array":
		pass
	else:
		var is_resource := data_type_lower == "resource" or data_type_lower.begins_with("resource")
		is_resource = is_resource or data_type_lower in ["texture2d", "packedscene", "audiostream", "material", "shader", "font", "theme"]

		if is_resource:
			# 资源默认值：优先保存 UID，读取时也优先 UID。
			# 同时保留 default 为路径（可读性/兼容旧版本）。
			_update_default_uid_label_from_text()
			if not _default_resource_uid.is_empty():
				definition["default_uid"] = _default_resource_uid
			if not default_text.is_empty():
				definition["default"] = default_text
		else:
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

	var data_type := str(definition.get("type", "string")).to_lower()
	if data_type == "enum":
		var values := _parse_list_values(_enum_values_edit.text)
		if not values.is_empty():
			definition["enum_values"] = values

	if data_type == "array":
		definition["array_element_type"] = _get_selected_array_element_type()

	return definition


func _on_type_selected(index: int) -> void:
	if _suppress_type_callbacks:
		return
	if _type_picker_opening:
		return
	var selected_index := _type_option.selected if _type_option else index
	if selected_index < 0:
		selected_index = index
	var meta := _get_option_meta(_type_option, selected_index)
	if meta == _OPTION_META_MORE or selected_index == _field_type_more_index:
		_type_picker_prev_field_type_value = _last_field_type_value
		var current_display := _get_more_display(_type_option, _field_type_more_index)
		var current := current_display if not current_display.is_empty() else _last_field_type_value
		_open_type_picker("field_type", current)
		return

	var t := meta
	if t.is_empty():
		t = _last_field_type_value
	_last_field_type_value = t

	if _constraints_enable_checkbox:
		_constraints_enable_checkbox.disabled = not _is_constraints_supported_for_type(t)
		if _constraints_enable_checkbox.disabled:
			_constraints_enable_checkbox.button_pressed = false
	_update_type_dependent_ui(t)


func _on_array_element_type_selected(index: int) -> void:
	# 已废弃：数组元素类型已并入“默认值”行的下拉框，不再使用单独的 OptionButton。
	# 保留空实现避免旧信号绑定导致报错。
	pass


func _get_more_display(option: OptionButton, more_index: int) -> String:
	if not option:
		return ""
	if more_index < 0 or more_index >= option.get_item_count():
		return ""
	var text := str(option.get_item_text(more_index)).strip_edges()
	if text.begins_with(_MORE_ITEM_PREFIX):
		var rest := text.substr(_MORE_ITEM_PREFIX.length()).strip_edges()
		return rest
	return ""


func _on_field_type_popup_index_pressed(idx: int) -> void:
	if idx == _field_type_more_index:
		_type_picker_prev_field_type_value = _last_field_type_value
		var current_display := _get_more_display(_type_option, _field_type_more_index)
		var current := current_display if not current_display.is_empty() else _last_field_type_value
		_open_type_picker("field_type", current)


func _on_field_type_popup_id_pressed(id: int) -> void:
	if not _type_option:
		return
	var idx := _type_option.get_item_index(id)
	if idx == _field_type_more_index:
		_on_field_type_popup_index_pressed(idx)


func _on_array_type_popup_index_pressed(_idx: int) -> void:
	# 已废弃：数组元素类型已并入“默认值”行的下拉框。
	pass


func _on_array_type_popup_id_pressed(_id: int) -> void:
	# 已废弃：数组元素类型已并入“默认值”行的下拉框。
	pass


func _update_type_dependent_ui(data_type: String) -> void:
	var original := str(data_type).strip_edges()
	var lower := original.to_lower()
	_enum_container.visible = lower == "enum"
	# Array 的元素类型选择已并入默认值行，这里不再切换额外分区可见性
	_update_constraints_visibility(lower)
	_update_default_browse_visibility(original)
	_show_default_editor_for_type(lower)


func _update_constraints_visibility(data_type: String) -> void:
	var t := str(data_type).to_lower()

	var is_number := t == "int" or t == "float"
	var is_text := t == "string" or t == "stringname" or t == "resource"
	var enabled := _constraints_enable_checkbox and _constraints_enable_checkbox.button_pressed and _is_constraints_supported_for_type(t)

	if _constraints_root:
		_constraints_root.visible = enabled

	_set_row_visible(_min_edit, enabled and is_number)
	_set_row_visible(_max_edit, enabled and is_number)

	_set_row_visible(_min_length_edit, enabled and is_text)
	_set_row_visible(_max_length_edit, enabled and is_text)
	_set_row_visible(_pattern_edit, enabled and is_text)


func _on_constraints_toggled(_pressed: bool) -> void:
	_update_type_dependent_ui(_get_selected_type())


func _update_default_browse_visibility(data_type: String) -> void:
	if not _default_browse_btn:
		return
	var original := str(data_type).strip_edges()
	var lower := original.to_lower()
	var show := false

	# 常见：资源/资源类型
	show = show or lower == "resource"
	show = show or lower.begins_with("resource")
	show = show or lower in ["texture2d", "packedscene", "audiostream", "material", "shader", "font", "theme"]
	_default_browse_btn.visible = show


func _on_browse_default_pressed() -> void:
	_cleanup_default_file_dialog()
	var dialog := FileDialog.new()
	dialog.title = "选择资源"
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_RESOURCES

	var type_lower := _get_selected_type().to_lower()
	var filters := PackedStringArray()

	match type_lower:
		"texture2d":
			filters.append("*.png, *.jpg, *.jpeg, *.webp ; 图片")
			filters.append("*.svg ; SVG")
		"packedscene":
			filters.append("*.tscn, *.scn ; 场景")
		"shader":
			filters.append("*.gdshader, *.shader ; Shader")
		"material":
			filters.append("*.tres, *.res ; 资源")
		"audiostream":
			filters.append("*.ogg, *.wav, *.mp3 ; 音频")
		"font":
			filters.append("*.ttf, *.otf, *.woff, *.woff2 ; 字体")
		"theme":
			filters.append("*.tres, *.res ; 资源")
		"resource":
			filters.append("*.tres, *.res ; 资源")
		_:
			# 兜底：资源类细分可能在未来扩展，这里保持一个通用资源选择
			filters.append("*.tres, *.res ; 资源")

	# 通用补充：允许手动选择其它资源文件（例如自定义 Resource、材质依赖、外部导入等）
	filters.append("*.* ; 所有文件")
	dialog.filters = filters

	dialog.file_selected.connect(_on_default_resource_selected.bind(dialog))
	dialog.canceled.connect(_on_default_resource_canceled.bind(dialog))
	_attach_popup_to_host(dialog)
	dialog.popup_centered()
	_default_file_dialog = dialog


func _on_default_resource_selected(path: String, dialog: FileDialog) -> void:
	if _default_edit:
		_default_edit.text = path
		_set_default_resource_uid(_get_resource_uid_from_res_path(path))
		_update_default_uid_label_from_text()
	if dialog:
		dialog.hide()
		dialog.queue_free()


func _on_default_resource_canceled(dialog: FileDialog) -> void:
	if dialog:
		dialog.hide()
		dialog.queue_free()


func _cleanup_default_file_dialog() -> void:
	if _default_file_dialog and is_instance_valid(_default_file_dialog):
		_default_file_dialog.hide()
		_default_file_dialog.queue_free()
	_default_file_dialog = null


func _on_default_text_changed(_new_text: String) -> void:
	_update_default_uid_label_from_text()


func _set_default_resource_uid(uid: String) -> void:
	_default_resource_uid = str(uid).strip_edges()
	_update_default_uid_label_from_text()


func _update_default_uid_label_from_text() -> void:
	if not _default_uid_label or not _default_edit:
		return

	var text := _default_edit.text.strip_edges()

	# 如果文本是 uid://，优先用 uid 解析路径并回填
	if text.begins_with("uid://"):
		_default_resource_uid = text
		var path := ResourceUID.get_id_path(ResourceUID.text_to_id(text))
		if not path.is_empty():
			_default_edit.text = path
			_default_resource_uid = _get_resource_uid_from_res_path(path)

	# 如果文本是 res:// 路径（或为空），尽力更新 uid
	elif text.begins_with("res://"):
		_default_resource_uid = _get_resource_uid_from_res_path(text)
	elif text.is_empty():
		_default_resource_uid = ""

	_default_uid_label.text = "UID：%s" % (_default_resource_uid if not _default_resource_uid.is_empty() else "-")


func _get_resource_uid_from_res_path(path: String) -> String:
	var p := str(path).strip_edges()
	if p.is_empty() or not p.begins_with("res://"):
		return ""

	# 兼容性策略：避免使用不存在的 ResourceUID.id_from_path()
	# 通过加载资源拿到 UID（编辑器侧操作，性能可接受）
	if not ResourceLoader.exists(p):
		return ""

	var res: Resource = ResourceLoader.load(p)
	if not res:
		return ""

	var uid_id: int = int(res.resource_uid)
	if uid_id == 0:
		return ""
	return ResourceUID.id_to_text(uid_id)


func _is_constraints_supported_for_type(data_type: String) -> bool:
	var t := str(data_type).to_lower()
	return t == "int" or t == "float" or t == "string" or t == "stringname" or t == "resource"


func _has_any_constraints_set() -> bool:
	if _min_edit and not _min_edit.text.strip_edges().is_empty():
		return true
	if _max_edit and not _max_edit.text.strip_edges().is_empty():
		return true
	if _min_length_edit and not _min_length_edit.text.strip_edges().is_empty():
		return true
	if _max_length_edit and not _max_length_edit.text.strip_edges().is_empty():
		return true
	if _pattern_edit and not _pattern_edit.text.strip_edges().is_empty():
		return true
	return false


func _set_row_visible(edit: LineEdit, visible: bool) -> void:
	if not edit:
		return
	var row := edit.get_parent()
	if row and row is Control:
		(row as Control).visible = visible


func _get_selected_type() -> String:
	if _last_field_type_value.is_empty():
		_last_field_type_value = "string"
	return _last_field_type_value


func _get_selected_array_element_type() -> String:
	if _last_array_element_type_value.is_empty():
		_last_array_element_type_value = "string"
	return _last_array_element_type_value


func _get_default_value_for_type(type_str: String) -> String:
	"""获取类型的默认值（用于字段设置里的 Array 默认值推导）"""
	match str(type_str).to_lower():
		"int":
			return "0"
		"float":
			return "0.0"
		"bool":
			return "false"
		"string", "stringname", "resource", "json":
			return ""
		"vector2", "vector2i":
			return "0,0"
		"vector3", "vector3i":
			return "0,0,0"
		"vector4", "vector4i":
			return "0,0,0,0"
		"rect2", "rect2i":
			return "0,0,0,0"
		"quaternion":
			return "0,0,0,1"
		"plane":
			return "0,0,0,0"
		"transform2d":
			return "1,0,0,1,0,0"
		"color":
			return "#ffffff"
		_:
			return ""


func _parse_list_values(text: String) -> PackedStringArray:
	var results := PackedStringArray()
	var lines := text.split("\n", false)
	for line in lines:
		for part in str(line).split(",", false):
			var s := str(part).strip_edges()
			if not s.is_empty():
				results.append(s)
	return results


func _on_confirmed() -> void:
	_apply_current_field_changes()
	_commit_if_dirty()
	_hide_type_picker()
	_cleanup_default_file_dialog()
	hide()


func _on_visibility_changed() -> void:
	if visible:
		return
	_hide_type_picker()
	_cleanup_default_file_dialog()
	_commit_if_dirty()


func _commit_if_dirty() -> void:
	if not _schema_dirty:
		return
	_schema_dirty = false
	if commit_changes and commit_changes.is_valid():
		commit_changes.call()


func _get_grip_icon() -> Texture2D:
	# 优先使用 Godot 编辑器内置的拖动图标
	# 按优先级尝试多个可能的图标名称
	var icon_names := [
		"TripleBar", # 三条横线图标（最常用的拖动握把）
		"GuiTreeArrowDown", # 备选：树形箭头
		"Move", # 备选：移动图标
		"GuiGrip" # 备选：握把图标
	]
	
	for icon_name in icon_names:
		if has_theme_icon(icon_name, "EditorIcons"):
			return get_theme_icon(icon_name, "EditorIcons")
	
	# Fallback: 生成一个简单的三条横线纹理
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var c := Color(0.6, 0.6, 0.6, 0.8)
	# 绘制三条横线
	for y in [5, 8, 11]:
		for x in range(4, 12):
			image.set_pixel(x, y, c)
	var tex := ImageTexture.create_from_image(image)
	return tex
