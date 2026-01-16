@tool
class_name GDSVEditorPlugin
extends EditorPlugin

## CSV 编辑器插件入口，负责管理 CSV 文件的编辑和面板显示

#region 常量 Constants
## 面板当前使用纯代码构建（GDSVEditorPanel.new()），不依赖.tscn文件
const CSV_EDITOR_PANEL_PATH = ""
const CSV_FILE_EXTENSION = ".csv"
const GDSV_FILE_EXTENSION = ".gdsv"
const DEFAULT_BOTTOM_PANEL_HEIGHT: float = 320.0
#endregion

#region 公共变量 Public Variables
## CSV 编辑器面板实例
var editor_panel: GDSVEditorPanel

## 当前编辑的文件路径
var current_file_path: String = ""

## 是否已加载面板
var is_panel_loaded: bool = false
#endregion

#region 私有变量 Private Variables
var _bottom_panel_button: Button
var _tab_container: TabContainer
var _file_tabs: Dictionary = {}  # {file_path: GDSVEditorTab}
#endregion

#region 生命周期方法 Lifecycle Methods
func _enter_tree() -> void:
	_load_editor_panel()
	_setup_bottom_panel()


func _exit_tree() -> void:
	_cleanup_bottom_panel()
	if editor_panel:
		editor_panel.queue_free()
		editor_panel = null
#endregion

#region 插件生命周期 Plugin Lifecycle
## 加载编辑器面板
func _load_editor_panel() -> void:
	# 当前实现使用纯代码构建面板，避免对.tscn文件的强依赖
	editor_panel = GDSVEditorPanel.new()
	editor_panel.custom_minimum_size = Vector2(0.0, DEFAULT_BOTTOM_PANEL_HEIGHT)
	editor_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	is_panel_loaded = true


## 设置底部面板
func _setup_bottom_panel() -> void:
	if not editor_panel:
		return
	
	_bottom_panel_button = add_control_to_bottom_panel(editor_panel, "GDSV 编辑器")
	_make_visible(false)


## 清理底部面板
func _cleanup_bottom_panel() -> void:
	if _bottom_panel_button:
		remove_control_from_bottom_panel(editor_panel)
		_bottom_panel_button = null
#endregion

#region 文件处理功能 File Handling Features
## 检查是否处理该文件
func _handles(object: Object) -> bool:
	if object is GDSVResource:
		return true
	if object is Resource:
		var path: String = (object as Resource).resource_path
		# 只处理 .gdsv 文件，不处理 .csv 文件
		return path.ends_with(GDSV_FILE_EXTENSION)
	return false


## 编辑文件
func _edit(object: Object) -> void:
	if not object or not editor_panel:
		return

	var csv_path := ""
	if object is GDSVResource:
		csv_path = (object as GDSVResource).source_csv_path
		if csv_path.is_empty() and object is Resource:
			# 兼容旧版本导入产物：GDSVResource 里可能还没保存 source_csv_path。
			# 同时支持直接编辑 .gdsv。
			var rp := (object as Resource).resource_path
			if rp.ends_with(GDSV_FILE_EXTENSION):
				csv_path = rp
			else:
				csv_path = _guess_source_csv_from_imported_resource_path(rp)
	elif object is Resource:
		var resource_path := (object as Resource).resource_path
		# 如果是 .csv 文件，显示提示对话框
		if resource_path.ends_with(CSV_FILE_EXTENSION):
			_show_csv_import_dialog()
			return
		if resource_path.ends_with(GDSV_FILE_EXTENSION):
			csv_path = resource_path

	if csv_path.is_empty():
		return
	current_file_path = csv_path

	# 显示面板并加载文件
	_make_visible(true)
	editor_panel.load_file(csv_path)


## 显示 CSV 导入提示对话框
func _show_csv_import_dialog() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "GDSV 文件编辑"
	dialog.dialog_text = "CSV files cannot be directly edited. Please use 'Import CSV' from the menu to convert to GDSV format first."

	# 添加到编辑器
	EditorInterface.get_base_control().add_child(dialog)
	dialog.popup_centered()

	# 自动关闭对话框
	dialog.confirmed.connect(func(): dialog.queue_free())
	dialog.canceled.connect(func(): dialog.queue_free())
	dialog.close_requested.connect(func(): dialog.queue_free())


func _guess_source_csv_from_imported_resource_path(imported_resource_path: String) -> String:
	if imported_resource_path.is_empty():
		return ""
	var file_name := imported_resource_path.get_file()
	var marker_index := file_name.find(".csv-")
	if marker_index < 0:
		return ""
	var csv_file_name := file_name.substr(0, marker_index + 4)
	return _find_file_in_project("res://", csv_file_name)


func _find_file_in_project(dir_path: String, target_file_name: String) -> String:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return ""

	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		if entry.begins_with("."):
			entry = dir.get_next()
			continue

		var full_path := dir_path.path_join(entry)
		if dir.current_is_dir():
			var found := _find_file_in_project(full_path, target_file_name)
			if not found.is_empty():
				dir.list_dir_end()
				return found
		else:
			if entry == target_file_name:
				dir.list_dir_end()
				return full_path

		entry = dir.get_next()
	dir.list_dir_end()
	return ""


## 设置面板可见性
func _make_visible(visible: bool) -> void:
	if not editor_panel:
		return
	
	if visible:
		# EditorPlugin API：确保底部面板显示我们的控件（不使用 pressed.emit 避免误触发 toggle）
		make_bottom_panel_item_visible(editor_panel)


## 获取主控件
func _get_plugin_name() -> String:
	return "GDSV 编辑器"


## 获取插件图标
func _get_plugin_icon() -> Texture2D:
	return EditorInterface.get_editor_theme().get_icon("File", "EditorIcons")
#endregion

#region 文件监控功能 File Monitoring Features
## 应用文件更改
func _apply_changes() -> void:
	if editor_panel:
		editor_panel.save_current_file()


## 获取编辑器状态
func _get_state() -> Dictionary:
	var state := {
		"visible": is_panel_loaded and editor_panel != null,
		"bottom_panel_visible": _bottom_panel_button != null and _bottom_panel_button.button_pressed
	}
	
	if editor_panel:
		state["current_file"] = current_file_path
	
	return state


## 恢复编辑器状态
func _set_state(state: Dictionary) -> void:
	if not state:
		return
	
	if state.get("visible", false):
		_make_visible(true)
	
	if state.get("bottom_panel_visible", false) and _bottom_panel_button:
		_bottom_panel_button.pressed.emit()
#endregion

#region 多文件管理功能 Multi-file Management Features
## 打开文件（新标签页）
func open_file(file_path: String) -> void:
	if not editor_panel:
		return
	
	editor_panel.load_file(file_path)


## 关闭文件
func close_file(file_path: String) -> void:
	if not editor_panel:
		return
	
	editor_panel.close_file(file_path)


## 获取所有打开的文件
func get_open_files() -> PackedStringArray:
	if editor_panel and editor_panel._tab_container:
		var files := PackedStringArray()
		for i in range(editor_panel._tab_container.get_tab_count()):
			var tab_control := editor_panel._tab_container.get_tab_control(i)
			if tab_control.has_method("get_file_path"):
				files.append(tab_control.get_file_path())
		return files
	return PackedStringArray()


## 切换到指定文件
func switch_to_file(file_path: String) -> void:
	if not editor_panel or not editor_panel._tab_container:
		return
	
	for i in range(editor_panel._tab_container.get_tab_count()):
		var tab_control := editor_panel._tab_container.get_tab_control(i)
		if tab_control.has_method("get_file_path") and tab_control.get_file_path() == file_path:
			editor_panel._tab_container.current_tab = i
			break


## 检查文件是否已打开
func is_file_open(file_path: String) -> bool:
	if editor_panel and editor_panel._tab_container:
		for i in range(editor_panel._tab_container.get_tab_count()):
			var tab_control := editor_panel._tab_container.get_tab_control(i)
			if tab_control.has_method("get_file_path") and tab_control.get_file_path() == file_path:
				return true
	return false
#endregion

#region 工具方法 Utility Methods
## 获取当前编辑器面板
func get_editor_panel() -> GDSVEditorPanel:
	return editor_panel


## 检查面板是否可用
func is_panel_available() -> bool:
	return is_panel_loaded and editor_panel != null


## 刷新编辑器
func refresh_editor() -> void:
	if editor_panel and not current_file_path.is_empty():
		editor_panel.load_file(current_file_path)
#endregion
