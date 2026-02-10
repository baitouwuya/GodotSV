class_name StandaloneEditor
extends VBoxContainer
## 外部 GDSV 编辑器主控制器
##
## 提供独立于 Godot 编辑器的 GDSV 文件编辑功能。
## 支持菜单栏、文件操作、快捷键、拖放打开、命令行参数等。

#region 菜单 ID 枚举
enum FileMenuID {
	NEW,
	OPEN,
	RECENT_FILES,
	SAVE,
	SAVE_AS,
	IMPORT,
	EXPORT,
	LOAD_SCHEMA,
	CLOSE_TAB,
	CLOSE_ALL,
	EXIT,
}

enum EditMenuID {
	UNDO,
	REDO,
	SEARCH,
	REPLACE,
	FIELD_SETTINGS,
	SETTINGS,
}

enum ViewMenuID {
	VALIDATE,
	REFRESH,
}

enum HelpMenuID {
	ABOUT,
}
#endregion

#region 常量
const MAX_RECENT_FILES: int = 15
const RECENT_FILES_PATH: String = "user://gdsv_recent_files.json"
const WINDOW_TITLE_BASE: String = "GodotSV 编辑器"

const SUPPORTED_EXTENSIONS: Array = [
	"gdsv", "csv", "tsv", "tab", "psv", "asc"
]

const FILE_FILTERS: Array = [
	"*.gdsv;GDSV 文件",
	"*.csv;CSV 文件",
	"*.tsv;TSV 文件",
	"*.tab;Tab 文件",
	"*.psv;PSV 文件",
	"*.asc;ASC 文件",
]

const DEFAULT_HEADER: String = "*id:int\tname:string\tvalue:float\n"
#endregion

#region 私有变量
## 编辑器面板（复用 GDSVEditorPanel）
var _editor_panel: GDSVEditorPanel

## 菜单栏
var _menu_bar: MenuBar
var _file_menu: PopupMenu
var _edit_menu: PopupMenu
var _view_menu: PopupMenu
var _help_menu: PopupMenu
var _recent_files_menu: PopupMenu

## 对话框
var _open_dialog: FileDialog
var _save_dialog: FileDialog
var _unsaved_dialog: ConfirmationDialog
var _about_dialog: AcceptDialog

## 最近文件列表
var _recent_files: PackedStringArray = PackedStringArray()

## 待执行操作（用于未保存确认后的回调）
var _pending_action: Callable

## 新建文件计数器
var _new_file_counter: int = 0

## 最近文件菜单中"清除"按钮的索引
var _recent_clear_idx: int = -1
#endregion

#region 生命周期
func _ready() -> void:
	# 窗口基本设置
	get_window().min_size = Vector2i(960, 640)
	get_tree().auto_accept_quit = false

	# 填充整个窗口
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)

	# 初始化类型系统
	_init_type_system()

	# 构建 UI
	_build_menu_bar()
	_build_editor_panel()
	_build_dialogs()

	# 加载配置
	_load_recent_files()
	_update_recent_files_menu()

	# 连接信号
	_connect_signals()

	# 处理命令行参数
	_handle_cli_arguments()

	# 更新窗口标题
	_update_window_title()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_try_exit()
#endregion

#region 初始化
## 初始化类型系统
func _init_type_system() -> void:
	var registry: GDSVTypeHandlerRegistry = GDSVTypeHandlerRegistry.get_singleton()
	if registry:
		# C++ 类型在 GDExtension 初始化时已自动注册
		# 此处仅扫描 GDScript 自定义类型处理器
		registry.scan_script_types()


## 构建菜单栏
func _build_menu_bar() -> void:
	_menu_bar = MenuBar.new()
	add_child(_menu_bar)

	_build_file_menu()
	_build_edit_menu()
	_build_view_menu()
	_build_help_menu()


## 构建文件菜单
func _build_file_menu() -> void:
	_file_menu = PopupMenu.new()
	_file_menu.name = "文件"

	_file_menu.add_item("新建", FileMenuID.NEW)
	_file_menu.set_item_accelerator(0, KEY_N | KEY_MASK_CTRL as Key)
	_file_menu.add_item("打开...", FileMenuID.OPEN)
	_file_menu.set_item_accelerator(1, KEY_O | KEY_MASK_CTRL as Key)

	# 最近文件子菜单
	_recent_files_menu = PopupMenu.new()
	_recent_files_menu.name = "RecentFiles"
	_recent_files_menu.index_pressed.connect(_on_recent_file_pressed)
	_file_menu.add_child(_recent_files_menu)
	_file_menu.add_submenu_node_item("最近文件", _recent_files_menu)

	_file_menu.add_separator()
	_file_menu.add_item("保存", FileMenuID.SAVE)
	_file_menu.set_item_accelerator(_file_menu.get_item_index(FileMenuID.SAVE), KEY_S | KEY_MASK_CTRL as Key)
	_file_menu.add_item("另存为...", FileMenuID.SAVE_AS)
	_file_menu.set_item_accelerator(_file_menu.get_item_index(FileMenuID.SAVE_AS), KEY_S | KEY_MASK_CTRL | KEY_MASK_SHIFT as Key)
	_file_menu.add_separator()
	_file_menu.add_item("导入...", FileMenuID.IMPORT)
	_file_menu.add_item("导出...", FileMenuID.EXPORT)
	_file_menu.add_separator()
	_file_menu.add_item("加载 Schema...", FileMenuID.LOAD_SCHEMA)
	_file_menu.add_separator()
	_file_menu.add_item("关闭标签页", FileMenuID.CLOSE_TAB)
	_file_menu.set_item_accelerator(_file_menu.get_item_index(FileMenuID.CLOSE_TAB), KEY_W | KEY_MASK_CTRL as Key)
	_file_menu.add_item("关闭全部", FileMenuID.CLOSE_ALL)
	_file_menu.add_separator()
	_file_menu.add_item("退出", FileMenuID.EXIT)
	_file_menu.set_item_accelerator(_file_menu.get_item_index(FileMenuID.EXIT), KEY_Q | KEY_MASK_CTRL as Key)

	_file_menu.id_pressed.connect(_on_file_menu_pressed)
	_menu_bar.add_child(_file_menu)


## 构建编辑菜单
func _build_edit_menu() -> void:
	_edit_menu = PopupMenu.new()
	_edit_menu.name = "编辑"

	_edit_menu.add_item("撤销", EditMenuID.UNDO)
	_edit_menu.set_item_accelerator(0, KEY_Z | KEY_MASK_CTRL as Key)
	_edit_menu.add_item("重做", EditMenuID.REDO)
	_edit_menu.set_item_accelerator(1, KEY_Y | KEY_MASK_CTRL as Key)
	_edit_menu.add_separator()
	_edit_menu.add_item("搜索", EditMenuID.SEARCH)
	_edit_menu.set_item_accelerator(_edit_menu.get_item_index(EditMenuID.SEARCH), KEY_F | KEY_MASK_CTRL as Key)
	_edit_menu.add_item("替换", EditMenuID.REPLACE)
	_edit_menu.set_item_accelerator(_edit_menu.get_item_index(EditMenuID.REPLACE), KEY_H | KEY_MASK_CTRL as Key)
	_edit_menu.add_separator()
	_edit_menu.add_item("字段设置...", EditMenuID.FIELD_SETTINGS)
	_edit_menu.add_item("编辑器设置...", EditMenuID.SETTINGS)

	_edit_menu.id_pressed.connect(_on_edit_menu_pressed)
	_menu_bar.add_child(_edit_menu)


## 构建视图菜单
func _build_view_menu() -> void:
	_view_menu = PopupMenu.new()
	_view_menu.name = "视图"

	_view_menu.add_item("验证数据", ViewMenuID.VALIDATE)
	_view_menu.add_item("从磁盘重新加载", ViewMenuID.REFRESH)

	_view_menu.id_pressed.connect(_on_view_menu_pressed)
	_menu_bar.add_child(_view_menu)


## 构建帮助菜单
func _build_help_menu() -> void:
	_help_menu = PopupMenu.new()
	_help_menu.name = "帮助"

	_help_menu.add_item("关于 GodotSV", HelpMenuID.ABOUT)

	_help_menu.id_pressed.connect(_on_help_menu_pressed)
	_menu_bar.add_child(_help_menu)


## 构建编辑器面板
func _build_editor_panel() -> void:
	_editor_panel = GDSVEditorPanel.new()
	_editor_panel.size_flags_vertical = SIZE_EXPAND_FILL
	_editor_panel.size_flags_horizontal = SIZE_EXPAND_FILL
	add_child(_editor_panel)

	# 隐藏编辑器面板自带的工具栏，功能已由菜单栏提供
	if _editor_panel.toolbar:
		_editor_panel.toolbar.visible = false


## 构建对话框
func _build_dialogs() -> void:
	# 打开文件对话框
	_open_dialog = FileDialog.new()
	_open_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILES
	_open_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_open_dialog.title = "打开文件"
	_open_dialog.filters = PackedStringArray(FILE_FILTERS)
	_open_dialog.files_selected.connect(_on_open_files_selected)
	add_child(_open_dialog)

	# 另存为对话框
	_save_dialog = FileDialog.new()
	_save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_save_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_save_dialog.title = "另存为"
	_save_dialog.filters = PackedStringArray(FILE_FILTERS)
	_save_dialog.file_selected.connect(_on_save_file_selected)
	add_child(_save_dialog)

	# 未保存更改确认对话框
	_unsaved_dialog = ConfirmationDialog.new()
	_unsaved_dialog.title = "未保存的更改"
	_unsaved_dialog.dialog_text = "当前文件有未保存的更改。\n是否在关闭前保存？"
	_unsaved_dialog.ok_button_text = "保存"
	_unsaved_dialog.add_button("不保存", true, "discard")
	_unsaved_dialog.confirmed.connect(_on_unsaved_confirmed)
	_unsaved_dialog.custom_action.connect(_on_unsaved_custom_action)
	_unsaved_dialog.canceled.connect(_on_unsaved_canceled)
	add_child(_unsaved_dialog)

	# 关于对话框
	_about_dialog = AcceptDialog.new()
	_about_dialog.title = "关于 GodotSV"
	_about_dialog.dialog_text = (
		"GodotSV 编辑器\n\n"
		+ "高性能 GDSV/CSV 数据表编辑工具\n\n"
		+ "支持格式：GDSV, CSV, TSV, TAB, PSV, ASC\n\n"
		+ "许可：MIT License"
	)
	add_child(_about_dialog)


## 连接信号
func _connect_signals() -> void:
	# 编辑器面板信号
	_editor_panel.file_loaded.connect(_on_file_loaded)
	_editor_panel.file_saved.connect(_on_file_saved)
	_editor_panel.file_closed.connect(_on_file_closed)

	# 标签页切换信号
	if _editor_panel._tab_container:
		_editor_panel._tab_container.tab_changed.connect(_on_tab_changed)

	# 拖放文件
	get_window().files_dropped.connect(_on_files_dropped)
#endregion

#region 菜单回调
## 文件菜单回调
func _on_file_menu_pressed(id: int) -> void:
	match id:
		FileMenuID.NEW:
			_new_file()
		FileMenuID.OPEN:
			_open_file()
		FileMenuID.SAVE:
			_save_file()
		FileMenuID.SAVE_AS:
			_save_file_as()
		FileMenuID.IMPORT:
			_import_file()
		FileMenuID.EXPORT:
			_export_file()
		FileMenuID.LOAD_SCHEMA:
			_load_schema()
		FileMenuID.CLOSE_TAB:
			_close_current_tab()
		FileMenuID.CLOSE_ALL:
			_close_all_tabs()
		FileMenuID.EXIT:
			_try_exit()


## 编辑菜单回调
func _on_edit_menu_pressed(id: int) -> void:
	match id:
		EditMenuID.UNDO:
			_undo()
		EditMenuID.REDO:
			_redo()
		EditMenuID.SEARCH:
			_show_search()
		EditMenuID.REPLACE:
			_show_replace()
		EditMenuID.FIELD_SETTINGS:
			_show_field_settings()
		EditMenuID.SETTINGS:
			_show_settings()


## 视图菜单回调
func _on_view_menu_pressed(id: int) -> void:
	match id:
		ViewMenuID.VALIDATE:
			_validate()
		ViewMenuID.REFRESH:
			_refresh_from_disk()


## 帮助菜单回调
func _on_help_menu_pressed(id: int) -> void:
	match id:
		HelpMenuID.ABOUT:
			_about_dialog.popup_centered()


## 最近文件菜单回调
func _on_recent_file_pressed(index: int) -> void:
	# 点击"清除最近文件"按钮
	if index == _recent_clear_idx:
		_recent_files = PackedStringArray()
		_save_recent_files()
		_update_recent_files_menu()
		return

	if index < 0 or index >= _recent_files.size():
		return
	var file_path: String = _recent_files[index]
	if FileAccess.file_exists(file_path):
		_editor_panel.load_file(file_path)
	else:
		# 文件不存在，从列表中移除
		_recent_files.remove_at(index)
		_save_recent_files()
		_update_recent_files_menu()
		push_warning("文件不存在: %s" % file_path)
#endregion

#region 文件操作
## 新建文件
func _new_file() -> void:
	_new_file_counter += 1
	var temp_path: String = "user://untitled_%d.gdsv" % _new_file_counter
	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file:
		file.store_string(DEFAULT_HEADER)
		file.close()
		_editor_panel.load_file(temp_path)
		_update_window_title()


## 打开文件对话框
func _open_file() -> void:
	_open_dialog.popup_centered(Vector2i(900, 600))


## 保存当前文件
func _save_file() -> void:
	if not _has_active_tab():
		return

	var file_path: String = _get_current_file_path()
	# 如果是 user:// 临时文件，改为另存为
	if file_path.begins_with("user://untitled_"):
		_save_file_as()
		return

	_editor_panel.save_current_file()


## 另存为
func _save_file_as() -> void:
	if not _has_active_tab():
		return
	_save_dialog.popup_centered(Vector2i(900, 600))


## 导入文件
func _import_file() -> void:
	_editor_panel._on_import_pressed()


## 导出文件
func _export_file() -> void:
	if not _has_active_tab():
		return
	_editor_panel._on_export_pressed()


## 加载 Schema
func _load_schema() -> void:
	_editor_panel._on_load_schema_pressed()


## 关闭当前标签页
func _close_current_tab() -> void:
	if not _has_active_tab():
		return

	var file_path: String = _get_current_file_path()
	if file_path.is_empty():
		return

	if _is_current_file_modified():
		_pending_action = func() -> void:
			_editor_panel.close_file(file_path)
			_cleanup_temp_file(file_path)
			_update_window_title()
		_unsaved_dialog.popup_centered()
	else:
		_editor_panel.close_file(file_path)
		_cleanup_temp_file(file_path)
		_update_window_title()


## 关闭全部标签页
func _close_all_tabs() -> void:
	if _has_any_unsaved():
		_pending_action = func() -> void:
			_force_close_all()
		_unsaved_dialog.popup_centered()
	else:
		_force_close_all()


## 强制关闭全部（无确认）
func _force_close_all() -> void:
	_editor_panel.close_all_files()
	_update_window_title()


## 尝试退出
func _try_exit() -> void:
	if _has_any_unsaved():
		_pending_action = func() -> void:
			get_tree().quit()
		_unsaved_dialog.popup_centered()
	else:
		get_tree().quit()
#endregion

#region 编辑操作
## 撤销
func _undo() -> void:
	if not _has_active_tab():
		return
	var state_manager: GDSVStateManager = _editor_panel.get_state_manager()
	if state_manager and state_manager.undo_redo:
		state_manager.undo_redo.undo()


## 重做
func _redo() -> void:
	if not _has_active_tab():
		return
	var state_manager: GDSVStateManager = _editor_panel.get_state_manager()
	if state_manager and state_manager.undo_redo:
		state_manager.undo_redo.redo()


## 显示搜索栏
func _show_search() -> void:
	if not _has_active_tab():
		return
	# 触发编辑器面板的搜索功能
	_editor_panel.search_text("")


## 显示替换栏
func _show_replace() -> void:
	if not _has_active_tab():
		return
	_editor_panel.replace_text("", "")


## 显示字段设置
func _show_field_settings() -> void:
	if not _has_active_tab():
		return
	# 触发表格视图的字段设置请求
	var tab_container: TabContainer = _editor_panel._tab_container
	if not tab_container:
		return
	var idx: int = tab_container.current_tab
	var tab_control: Control = tab_container.get_tab_control(idx)
	if tab_control and tab_control.has_method("get_table_view"):
		var table_view: Control = tab_control.get_table_view()
		if table_view and table_view.has_signal("fields_settings_requested"):
			table_view.fields_settings_requested.emit()


## 显示编辑器设置
func _show_settings() -> void:
	_editor_panel._on_settings_pressed()


## 验证数据
func _validate() -> void:
	if not _has_active_tab():
		return
	_editor_panel.validate_current_file()


## 从磁盘重新加载
func _refresh_from_disk() -> void:
	if not _has_active_tab():
		return
	var file_path: String = _get_current_file_path()
	if not file_path.is_empty() and FileAccess.file_exists(file_path):
		_editor_panel.load_file(file_path)
#endregion

#region 文件对话框回调
## 打开文件选中回调（支持多选）
func _on_open_files_selected(paths: PackedStringArray) -> void:
	for path in paths:
		_editor_panel.load_file(path)
		_add_recent_file(path)
	_update_window_title()


## 另存为文件选中回调
func _on_save_file_selected(path: String) -> void:
	if not _has_active_tab():
		return

	var old_path: String = _get_current_file_path()
	var processor: GDSVDataProcessor = _editor_panel.get_data_processor()
	if processor:
		var success: bool = processor.save_gdsv_file(path)
		if success:
			# 如果旧路径是临时文件，清理它
			_cleanup_temp_file(old_path)
			# 重新加载到新路径
			_editor_panel.close_file(old_path)
			_editor_panel.load_file(path)
			_add_recent_file(path)
			_update_window_title()
#endregion

#region 未保存更改处理
## 确认保存后回调
func _on_unsaved_confirmed() -> void:
	# 用户选择"保存"
	_save_file()
	if _pending_action.is_valid():
		_pending_action.call()
		_pending_action = Callable()


## 自定义操作回调（不保存）
func _on_unsaved_custom_action(action: StringName) -> void:
	if action == &"discard":
		# 用户选择"不保存"
		if _pending_action.is_valid():
			_pending_action.call()
			_pending_action = Callable()


## 取消回调
func _on_unsaved_canceled() -> void:
	_pending_action = Callable()
#endregion

#region 编辑器面板信号回调
## 文件加载完成
func _on_file_loaded(file_path: String) -> void:
	if not file_path.begins_with("user://untitled_"):
		_add_recent_file(file_path)
	_update_window_title()


## 文件保存完成
func _on_file_saved(_file_path: String) -> void:
	_update_window_title()


## 文件关闭
func _on_file_closed(_file_path: String) -> void:
	_update_window_title()


## 标签页切换
func _on_tab_changed(_tab_index: int) -> void:
	_update_window_title()
#endregion

#region 拖放和命令行
## 文件拖放回调
func _on_files_dropped(files: PackedStringArray) -> void:
	for file_path in files:
		var ext: String = file_path.get_extension().to_lower()
		if ext in SUPPORTED_EXTENSIONS:
			_editor_panel.load_file(file_path)
			_add_recent_file(file_path)
	_update_window_title()


## 处理命令行参数
func _handle_cli_arguments() -> void:
	# 优先使用用户参数（-- 后面的参数）
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		args = OS.get_cmdline_args()

	for arg in args:
		# 跳过 Godot 内部参数
		if arg.begins_with("-") or arg.begins_with("--"):
			continue
		# 跳过 res:// 路径（Godot 内部使用）
		if arg.begins_with("res://"):
			continue

		var ext: String = arg.get_extension().to_lower()
		if ext in SUPPORTED_EXTENSIONS:
			# 如果是相对路径，转为绝对路径
			var abs_path: String = arg
			if not abs_path.is_absolute_path():
				abs_path = OS.get_executable_path().get_base_dir().path_join(arg)
			if FileAccess.file_exists(abs_path):
				_editor_panel.load_file(abs_path)
				_add_recent_file(abs_path)

	_update_window_title()
#endregion

#region 最近文件管理
## 添加到最近文件列表
func _add_recent_file(file_path: String) -> void:
	# 移除已有的相同路径
	var idx: int = _recent_files.find(file_path)
	if idx >= 0:
		_recent_files.remove_at(idx)

	# 插入到最前面
	_recent_files.insert(0, file_path)

	# 限制数量
	while _recent_files.size() > MAX_RECENT_FILES:
		_recent_files.remove_at(_recent_files.size() - 1)

	_save_recent_files()
	_update_recent_files_menu()


## 加载最近文件列表
func _load_recent_files() -> void:
	if not FileAccess.file_exists(RECENT_FILES_PATH):
		return

	var file: FileAccess = FileAccess.open(RECENT_FILES_PATH, FileAccess.READ)
	if not file:
		return

	var json_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var err: Error = json.parse(json_text)
	if err != OK:
		return

	var data: Variant = json.data
	if data is Dictionary and data.has("recent_files"):
		var files: Variant = data["recent_files"]
		if files is Array:
			_recent_files = PackedStringArray()
			for f in files:
				if f is String and not f.is_empty():
					_recent_files.append(f)


## 保存最近文件列表
func _save_recent_files() -> void:
	var file: FileAccess = FileAccess.open(RECENT_FILES_PATH, FileAccess.WRITE)
	if not file:
		return

	var data: Dictionary = {"recent_files": Array(_recent_files)}
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


## 更新最近文件子菜单
func _update_recent_files_menu() -> void:
	_recent_files_menu.clear()
	_recent_clear_idx = -1

	if _recent_files.is_empty():
		_recent_files_menu.add_item("（无最近文件）")
		_recent_files_menu.set_item_disabled(0, true)
		return

	for i in range(_recent_files.size()):
		var path: String = _recent_files[i]
		var label: String = path.get_file()
		# 如果文件名重复，显示父目录
		var count: int = 0
		for other_path in _recent_files:
			if other_path.get_file() == label:
				count += 1
		if count > 1:
			label = path.get_base_dir().get_file().path_join(label)
		_recent_files_menu.add_item(label)
		_recent_files_menu.set_item_tooltip(i, path)

	_recent_files_menu.add_separator()
	_recent_files_menu.add_item("清除最近文件")
	_recent_clear_idx = _recent_files_menu.item_count - 1
#endregion

#region 窗口管理
## 更新窗口标题
func _update_window_title() -> void:
	var title: String = WINDOW_TITLE_BASE

	if _has_active_tab():
		var file_path: String = _get_current_file_path()
		var file_name: String = file_path.get_file() if not file_path.is_empty() else "untitled"

		# 如果是临时文件，显示 "untitled"
		if file_path.begins_with("user://untitled_"):
			file_name = "untitled"

		title = "%s - %s" % [WINDOW_TITLE_BASE, file_name]

		# 修改标记
		if _is_current_file_modified():
			title += " *"

	get_window().title = title
#endregion

#region 工具方法
## 检查是否有活跃标签页
func _has_active_tab() -> bool:
	if not _editor_panel or not _editor_panel._tab_container:
		return false
	return _editor_panel._tab_container.get_tab_count() > 0


## 获取当前文件路径
func _get_current_file_path() -> String:
	if not _has_active_tab():
		return ""
	var tab_container: TabContainer = _editor_panel._tab_container
	var idx: int = tab_container.current_tab
	if idx < 0 or idx >= tab_container.get_tab_count():
		return ""
	var tab_control: Control = tab_container.get_tab_control(idx)
	if tab_control and tab_control.has_method("get_file_path"):
		return tab_control.get_file_path()
	return ""


## 检查当前文件是否已修改
func _is_current_file_modified() -> bool:
	if not _has_active_tab():
		return false
	var tab_container: TabContainer = _editor_panel._tab_container
	var idx: int = tab_container.current_tab
	var tab_title: String = tab_container.get_tab_title(idx)
	# 编辑器面板用 * 后缀标记已修改的标签页
	return tab_title.ends_with("*")


## 检查是否有任何未保存的文件
func _has_any_unsaved() -> bool:
	if not _editor_panel or not _editor_panel._tab_container:
		return false
	var tab_container: TabContainer = _editor_panel._tab_container
	for i in range(tab_container.get_tab_count()):
		var title: String = tab_container.get_tab_title(i)
		if title.ends_with("*"):
			return true
	return false


## 清理临时文件
func _cleanup_temp_file(file_path: String) -> void:
	if file_path.begins_with("user://untitled_"):
		if FileAccess.file_exists(file_path):
			DirAccess.remove_absolute(file_path)


## 获取文件过滤器
func _get_file_filters() -> PackedStringArray:
	return PackedStringArray(FILE_FILTERS)
#endregion
