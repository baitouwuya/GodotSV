class_name TypePickerDialog
extends PopupPanel

signal type_picked(type_name: String)
signal cancelled()

## 分类显示名映射（category 标识 → 中文显示）
const _CATEGORY_DISPLAY_NAMES: Dictionary = {
	"basic": "基础",
	"vector": "向量",
	"color": "颜色",
	"array": "数组",
	"container": "容器",
	"resource": "资源",
	"geometry": "几何/变换",
	"custom": "自定义",
	"other": "其它",
}

## 分类图标映射（category 标识 → EditorIcons 图标名）
const _CATEGORY_ICONS: Dictionary = {
	"basic": "int",
	"vector": "Vector2",
	"color": "Color",
	"array": "Array",
	"container": "Dictionary",
	"resource": "Resource",
	"geometry": "Transform3D",
	"custom": "GDScript",
	"other": "Variant",
}

## 分类显示顺序
const _CATEGORY_ORDER: PackedStringArray = [
	"basic", "vector", "color", "array", "geometry", "container", "resource", "custom", "other"
]

var _search: LineEdit
var _tree: Tree
var _ok_button: Button
var _cancel_button: Button
var _panel: PanelContainer
var _selected_type: String = ""
var _current_type: String = ""
var _is_picking: bool = false
var _confirmed_this_time: bool = false

## 缓存：type_name → { display_name, category, description }
var _type_metadata_cache: Dictionary = {}
## 缓存：category → PackedStringArray（该分类下的 type_name 列表）
var _category_types_cache: Dictionary = {}


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
	# 可能在 _ready 之前被调用（例如从 OptionButton 选择"更多..."立即触发）。
	if not _search or not _tree or not _ok_button:
		call_deferred("pick", current_type)
		return
	_is_picking = true
	_confirmed_this_time = false
	_current_type = str(current_type).strip_edges()
	_selected_type = ""
	_ok_button.disabled = true
	_search.text = ""
	_refresh_type_cache()
	_rebuild_tree("")
	popup_centered()
	_search.call_deferred("grab_focus")


func _refresh_type_cache() -> void:
	_type_metadata_cache.clear()
	_category_types_cache.clear()

	var registry := GDSVTypeHandlerRegistry.get_singleton()
	if not registry:
		return

	# 强制重新扫描 GDScript 类型（编辑器启动早期可能尚未加载）
	registry.scan_script_types()

	var all_types := registry.get_all_types()
	for type_name in all_types:
		var handler: GDSVTypeHandler = registry.get_type(str(type_name))
		if not handler:
			continue
		var meta: Dictionary = handler.get_metadata_dictionary()
		var category: String = str(meta.get("category", "other"))
		var display_name: String = str(meta.get("display_name", str(type_name)))

		_type_metadata_cache[str(type_name)] = {
			"display_name": display_name,
			"category": category,
			"description": str(meta.get("description", "")),
		}

		if not _category_types_cache.has(category):
			_category_types_cache[category] = PackedStringArray()
		var arr: PackedStringArray = _category_types_cache[category]
		arr.append(str(type_name))
		_category_types_cache[category] = arr

	# 每个分类内按名称排序
	for cat_key in _category_types_cache:
		var arr: PackedStringArray = _category_types_cache[cat_key]
		arr.sort()
		_category_types_cache[cat_key] = arr


func _on_search_changed(text: String) -> void:
	_rebuild_tree(text)


func _rebuild_tree(filter_text: String) -> void:
	_tree.clear()
	var root := _tree.create_item()

	var q := str(filter_text).strip_edges().to_lower()

	# 按预定义顺序添加分类
	for cat_key in _CATEGORY_ORDER:
		if not _category_types_cache.has(cat_key):
			continue
		var display: String = _CATEGORY_DISPLAY_NAMES.get(cat_key, cat_key)
		_add_category(root, display, _category_types_cache[cat_key], q, cat_key)

	# 追加不在预定义顺序中的分类
	for cat_key in _category_types_cache:
		if cat_key in _CATEGORY_ORDER:
			continue
		var display: String = _CATEGORY_DISPLAY_NAMES.get(cat_key, cat_key)
		_add_category(root, display, _category_types_cache[cat_key], q, cat_key)

	_tree.queue_redraw()

	if not _current_type.is_empty():
		_select_type_in_tree(_current_type)


func _add_category(root: TreeItem, title: String, values: PackedStringArray, query: String, category_key: String = "") -> void:
	var filtered := PackedStringArray()
	for v in values:
		if query.is_empty():
			filtered.append(v)
			continue
		# 搜索类型名和显示名
		if str(v).to_lower().find(query) >= 0:
			filtered.append(v)
			continue
		if _type_metadata_cache.has(v):
			var display: String = _type_metadata_cache[v].get("display_name", "")
			if display.to_lower().find(query) >= 0:
				filtered.append(v)

	if filtered.is_empty():
		return

	var cat := _tree.create_item(root)
	cat.set_text(0, title)
	cat.set_selectable(0, false)
	# 设置分类图标
	var cat_icon_name: String = _CATEGORY_ICONS.get(category_key, "")
	if not cat_icon_name.is_empty():
		var cat_icon: Texture2D = _get_editor_type_icon(cat_icon_name)
		if cat_icon:
			cat.set_icon(0, cat_icon)

	for v in filtered:
		var item := _tree.create_item(cat)
		# 如果有不同于类型名的显示名，则同时展示
		var display_name: String = ""
		if _type_metadata_cache.has(v):
			display_name = _type_metadata_cache[v].get("display_name", "")
		if not display_name.is_empty() and display_name != v:
			item.set_text(0, "%s (%s)" % [display_name, v])
		else:
			item.set_text(0, str(v))
		item.set_metadata(0, str(v))
		# 设置类型图标
		var icon: Texture2D = _get_editor_type_icon(str(v))
		if icon:
			item.set_icon(0, icon)


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


## 获取 Godot 编辑器内置的类型图标
func _get_editor_type_icon(type_name: String) -> Texture2D:
	if not Engine.is_editor_hint():
		return null
	var theme: Theme = EditorInterface.get_editor_theme()
	if not theme:
		return null
	# 直接匹配
	if theme.has_icon(type_name, "EditorIcons"):
		return theme.get_icon(type_name, "EditorIcons")
	# 通过 Registry 获取规范类型名（如 "string" → "String"）
	var registry := GDSVTypeHandlerRegistry.get_singleton()
	if registry:
		var handler: GDSVTypeHandler = registry.get_type(type_name)
		if handler:
			var canonical: String = str(handler.get_type_name())
			if canonical != type_name and theme.has_icon(canonical, "EditorIcons"):
				return theme.get_icon(canonical, "EditorIcons")
	return null
