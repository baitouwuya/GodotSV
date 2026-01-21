class_name TypePickerDialog
extends PopupPanel

signal type_picked(type_name: String)
signal cancelled()

# 分组尽量贴近 Godot 的常见类型心智：基础 / Vector / PackedArray / 资源等
const BASIC_TYPES: PackedStringArray = [
	"string",
	"int",
	"float",
	"bool",
	"stringname",
	"enum",
	"array",
	"resource",
	"json",
]

const VECTOR_TYPES: PackedStringArray = [
	"Vector2",
	"Vector2i",
	"Vector3",
	"Vector3i",
	"Vector4",
	"Vector4i",
]

const COLOR_TYPES: PackedStringArray = [
	"Color",
]

const PACKED_ARRAY_TYPES: PackedStringArray = [
	"PackedByteArray",
	"PackedInt32Array",
	"PackedInt64Array",
	"PackedFloat32Array",
	"PackedFloat64Array",
	"PackedStringArray",
	"PackedVector2Array",
	"PackedVector3Array",
	"PackedColorArray",
]

const GEOMETRY_TYPES: PackedStringArray = [
	"Rect2",
	"Rect2i",
	"Transform2D",
	"Transform3D",
	"Basis",
	"Quaternion",
	"AABB",
	"Plane",
]

const CONTAINER_TYPES: PackedStringArray = [
	"Array",
	"Dictionary",
]

const OTHER_TYPES: PackedStringArray = []

# 资源细分类型：用于在“字段类型”层面提供更明确的语义。
# 默认值输入仍建议使用资源/UID（字段设置里会提供“...”按钮选择资源文件）。
const RESOURCE_TYPES: PackedStringArray = [
	"Texture2D",
	"PackedScene",
	"AudioStream",
	"Material",
	"Shader",
	"Font",
	"Theme",
]

#

var _search: LineEdit
var _tree: Tree
var _ok_button: Button
var _cancel_button: Button
var _panel: PanelContainer
var _selected_type: String = ""
var _current_type: String = ""
var _is_picking: bool = false
var _confirmed_this_time: bool = false


func _ready() -> void:
	hide()
	visibility_changed.connect(_on_visibility_changed)

	min_size = Vector2(520, 520)
	size = Vector2(560, 600)

	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	_search = LineEdit.new()
	_search.placeholder_text = "搜索类型..."
	_search.text_changed.connect(_on_search_changed)
	vbox.add_child(_search)

	_tree = Tree.new()
	_tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tree.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tree.hide_root = true
	_tree.item_selected.connect(_on_tree_item_selected)
	_tree.item_activated.connect(_on_tree_item_activated)
	vbox.add_child(_tree)

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 8)
	vbox.add_child(button_row)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_row.add_child(spacer)

	_cancel_button = Button.new()
	_cancel_button.text = "取消"
	_cancel_button.pressed.connect(_on_cancelled)
	button_row.add_child(_cancel_button)

	_ok_button = Button.new()
	_ok_button.text = "选择"
	_ok_button.disabled = true
	_ok_button.pressed.connect(_on_confirmed)
	button_row.add_child(_ok_button)

	_rebuild_tree("")


func pick(current_type: String) -> void:
	# 可能在 _ready 之前被调用（例如从 OptionButton 选择“更多...”立即触发）。
	if not _search or not _tree or not _ok_button:
		call_deferred("pick", current_type)
		return
	_is_picking = true
	_confirmed_this_time = false
	_current_type = str(current_type).strip_edges()
	_selected_type = ""
	_ok_button.disabled = true
	_search.text = ""
	_rebuild_tree("")
	popup_centered()
	_search.call_deferred("grab_focus")


func _on_search_changed(text: String) -> void:
	_rebuild_tree(text)


func _rebuild_tree(filter_text: String) -> void:
	_tree.clear()
	var root := _tree.create_item()

	var q := str(filter_text).strip_edges().to_lower()

	_add_category(root, "基础", BASIC_TYPES, q)
	_add_category(root, "Vector", VECTOR_TYPES, q)
	_add_category(root, "颜色", COLOR_TYPES, q)
	_add_category(root, "PackedArray", PACKED_ARRAY_TYPES, q)
	_add_category(root, "几何/变换", GEOMETRY_TYPES, q)
	_add_category(root, "容器", CONTAINER_TYPES, q)
	_add_category(root, "资源", RESOURCE_TYPES, q)
	_add_category(root, "其它", OTHER_TYPES, q)
	_tree.queue_redraw()

	if not _current_type.is_empty():
		_select_type_in_tree(_current_type)


func _add_category(root: TreeItem, title: String, values: PackedStringArray, query: String) -> void:
	var filtered := PackedStringArray()
	for v in values:
		if query.is_empty() or str(v).to_lower().find(query) >= 0:
			filtered.append(v)

	if filtered.is_empty():
		return

	var cat := _tree.create_item(root)
	cat.set_text(0, title)
	cat.set_selectable(0, false)

	for v in filtered:
		var item := _tree.create_item(cat)
		item.set_text(0, str(v))
		item.set_metadata(0, str(v))


func _select_type_in_tree(type_name: String) -> void:
	var target := str(type_name).strip_edges()
	if target.is_empty():
		return

	var item := _tree.get_root()
	if not item:
		return

	var found := _find_item_by_metadata(item, target)
	if found:
		found.select(0)
		_tree.scroll_to_item(found, true)


func _find_item_by_metadata(item: TreeItem, target: String) -> TreeItem:
	var child := item.get_first_child()
	while child:
		var meta := child.get_metadata(0)
		if meta != null and str(meta) == target:
			return child

		var nested := _find_item_by_metadata(child, target)
		if nested:
			return nested

		child = child.get_next()
	return null


func _on_tree_item_selected() -> void:
	var item := _tree.get_selected()
	if not item:
		return

	var meta := item.get_metadata(0)
	var type_name := str(meta) if meta != null else ""
	type_name = type_name.strip_edges()

	if type_name.is_empty():
		_selected_type = ""
		_ok_button.disabled = true
		return

	_selected_type = type_name
	_ok_button.disabled = false


func _on_tree_item_activated() -> void:
	_on_tree_item_selected()
	if not _selected_type.is_empty():
		_on_confirmed()


func _on_confirmed() -> void:
	if _selected_type.is_empty():
		return
	_confirmed_this_time = true
	type_picked.emit(_selected_type)
	hide()


func _on_cancelled() -> void:
	hide()


func _on_visibility_changed() -> void:
	if visible:
		return
	_selected_type = ""
	if _ok_button:
		_ok_button.disabled = true
	if _is_picking:
		_is_picking = false
		if not _confirmed_this_time:
			cancelled.emit()
		_confirmed_this_time = false
