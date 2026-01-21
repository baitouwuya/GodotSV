class_name GDSVEditorPanel
extends Control

## GDSV 编辑器面板，包含工具栏、表格视图和状态栏
## 提供完整的 GDSV 文件编辑功能

#region 信号 Signals
signal file_loaded(file_path: String)
signal file_saved(file_path: String)
signal file_closed(file_path: String)
signal validation_started()
signal validation_finished(error_count: int)
#endregion

#region 多值类型配置
## 多值类型配置：[组件数量, 是否整数, [标签数组]]
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
#endregion

#region 导出变量 Export Variables
## 是否显示行号
@export var show_line_numbers: bool = true

## 是否启用虚拟滚动
@export var enable_virtual_scrolling: bool = true

## 自动保存间隔（秒）
@export var auto_save_interval: float = 300.0
#endregion

#region 公共变量 Public Variables
## 标签页容器（公开给插件访问）
var _tab_container: TabContainer

## 工具栏
var toolbar: HBoxContainer

## 状态栏
var status_bar: HBoxContainer
#endregion

#region 私有变量 Private Variables
## 数据处理器
var _data_processor: GDSVDataProcessor

## 数据模型
var _data_model: GDSVDataModel

## 状态管理器
var _state_manager: GDSVStateManager

## Schema 管理器
var _schema_manager: SchemaManager

## UI样式管理器
var _ui_style_manager: UIStyleManager

## 错误处理器
var _error_handler: ErrorHandler

## 配置管理器
var _config_manager: ConfigManager

## 底部输入区（用于编辑选中单元格）
var _cell_input_panel: PanelContainer
var _cell_pos_label: Label
var _cell_type_label: Label
var _cell_input_line: LineEdit
var _cell_input_text: TextEdit
var _cell_input_bool: CheckBox
var _cell_input_enum: OptionButton
var _cell_input_number: SpinBox
var _cell_input_number_is_int: bool = false
var _cell_input_vec_container: HBoxContainer
var _cell_input_vec_spins: Array[SpinBox] = [] # 动态 SpinBox 数组（最多 6 个）
var _cell_input_vec_labels: Array[Label] = [] # 对应的标签数组
var _cell_input_color: ColorPickerButton
var _cell_input_array_btn: Button # Array 编辑按钮
var _cell_input_resource_btn: Button # 资源选择按钮
var _cell_apply_btn: Button
var _cell_default_btn: Button
var _active_cell: Vector2i = Vector2i(-1, -1)
var _cell_input_debounce_timer: Timer
var _suppress_cell_input_callbacks: bool = false
var _cell_input_live_applying: bool = false

## Array 编辑弹窗
var _array_editor_dialog: AcceptDialog
var _array_editor_scroll: ScrollContainer
var _array_editor_vbox: VBoxContainer
var _array_editor_current_value: String = ""
var _array_editor_items: Array[Dictionary] = [] # 存储每个元素 {"type": "string", "value": "hello", "row": HBoxContainer}

## 搜索栏
var _search_bar: Control

## 搜索框
var _search_line_edit: LineEdit

## 替换框
var _replace_line_edit: LineEdit

## 搜索对话框
var _search_dialog: AcceptDialog
var _search_dialog_line_edit: LineEdit
var _search_dialog_case_checkbox: CheckBox
var _search_dialog_regex_checkbox: CheckBox
var _search_dialog_status_label: Label


## 搜索结果列表
var _search_results: Array[Dictionary] = []

## 当前搜索索引
var _current_search_index: int = -1

## 是否区分大小写
var _case_sensitive: bool = false

## 剪贴板数据
var _clipboard: Dictionary = {"rows": [], "cols": 0}

## 是否有剪贴板数据
var _has_clipboard_data: bool = false

## 选区信息
var _selection: Dictionary = {"start_row": - 1, "start_col": - 1, "end_row": - 1, "end_col": - 1}

## 是否有选区
var _has_selection: bool = false

## 是否使用正则表达式
var _use_regex: bool = false

## 是否展开替换框
var _show_replace: bool = false

## 验证管理器
var _validation_manager: ValidationManager

## 当前打开的文件映射 {binding_key(uid优先): tab_control}
## 注意：binding_key = uid://...（可用时）否则为 file_path
var _open_files: Dictionary = {}

## 当前活动的标签页索引
var _current_tab_index: int = -1

## 状态栏控件引用
var _file_status_label: Label
var _validation_label: Label
var _row_count_label: Label
var _col_count_label: Label

## 列设置对话框
var _fields_settings_dialog: FieldsSettingsDialog
#endregion

#region 生命周期方法 Lifecycle Methods
func _init() -> void:
	_initialize_data_components()


func _ready() -> void:
	_build_ui()
	_connect_signals()
	_configure_auto_save()


func _exit_tree() -> void:
	_cleanup_open_files()
#endregion

#region 初始化功能 Initialization Features
func _initialize_data_components() -> void:
	_data_processor = GDSVDataProcessor.new()
	_data_model = GDSVDataModel.new()
	_state_manager = GDSVStateManager.new()
	_schema_manager = SchemaManager.new()
	_validation_manager = ValidationManager.new()
	_ui_style_manager = UIStyleManager.new()
	_error_handler = ErrorHandler.new()
	_config_manager = ConfigManager.new()

	_data_model.set_data_processor(_data_processor)
	_state_manager.set_data_model(_data_model)
	_schema_manager.set_data_processor(_data_processor)
	_schema_manager.set_state_manager(_state_manager)
	_validation_manager.set_data_processor(_data_processor)
	_validation_manager.set_schema_manager(_schema_manager)
	_validation_manager.set_state_manager(_state_manager)

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 添加管理器到场景树
	add_child(_schema_manager)
	add_child(_validation_manager)

	# 创建主容器
	var main_container := VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(main_container)

	# 创建工具栏
	toolbar = _create_toolbar()
	main_container.add_child(toolbar)

	# 创建搜索弹窗
	_ensure_search_dialog()


	# 创建标签页容器
	_tab_container = TabContainer.new()
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_container.tab_changed.connect(_on_tab_changed)
	_tab_container.tabs_visible = true
	_tab_container.tabs_rearrange_group = 1
	var tab_bar := _tab_container.get_tab_bar()
	if tab_bar:
		# 兼容不同 Godot 版本：优先用方法设置关闭按钮策略
		if tab_bar.has_method("set_tab_close_display_policy"):
			tab_bar.set_tab_close_display_policy(TabBar.CLOSE_BUTTON_SHOW_ACTIVE_ONLY)
		else:
			tab_bar.tab_close_display_policy = TabBar.CLOSE_BUTTON_SHOW_ACTIVE_ONLY
		if not tab_bar.tab_close_pressed.is_connected(_on_tab_close_pressed):
			tab_bar.tab_close_pressed.connect(_on_tab_close_pressed)
	main_container.add_child(_tab_container)

	# 分割线：表格区 / 输入区
	var input_sep := HSeparator.new()
	input_sep.custom_minimum_size.y = 2
	main_container.add_child(input_sep)

	# 创建底部输入区
	_cell_input_panel = _create_cell_input_panel()
	main_container.add_child(_cell_input_panel)

	# 分割线：输入区 / 状态栏
	var status_sep := HSeparator.new()
	status_sep.custom_minimum_size.y = 2
	main_container.add_child(status_sep)

	# 创建状态栏
	status_bar = _create_status_bar()
	main_container.add_child(status_bar)


func _connect_signals() -> void:
	_data_processor.file_loaded.connect(_on_file_loaded)
	_data_processor.file_saved.connect(_on_file_saved)
	_data_processor.validation_completed.connect(_on_validation_completed)
	_state_manager.state_changed.connect(_on_state_changed)
	_state_manager.file_saved.connect(_on_state_manager_file_saved)

	# 错误处理信号
	_error_handler.error_occurred.connect(_on_error_occurred)
	_error_handler.warning_occurred.connect(_on_warning_occurred)

	# 配置变化信号
	_config_manager.config_changed.connect(_on_config_changed)
	_config_manager.config_loaded.connect(_on_config_loaded)
	_config_manager.config_saved.connect(_on_config_saved)


## 配置自动保存
func _configure_auto_save() -> void:
	if auto_save_interval > 0:
		_state_manager.set_auto_save_interval(auto_save_interval)
#endregion

#region UI构建功能 UI Building Features
## 创建工具栏
func _create_toolbar() -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 5)

	# 保存按钮
	var save_btn := Button.new()
	save_btn.text = "保存"
	save_btn.tooltip_text = "保存当前文件 (Ctrl+S)"
	save_btn.pressed.connect(_on_save_pressed)
	hbox.add_child(save_btn)

	# 分隔符（字段/Schema 分组）
	hbox.add_child(VSeparator.new())

	# 加载Schema按钮
	var schema_btn := Button.new()
	schema_btn.text = "加载Schema"
	schema_btn.tooltip_text = "加载Schema文件"
	schema_btn.pressed.connect(_on_load_schema_pressed)
	hbox.add_child(schema_btn)
	hbox.add_child(VSeparator.new())

	# 搜索按钮
	var search_btn := Button.new()
	search_btn.text = "搜索"
	search_btn.tooltip_text = "搜索内容 (Ctrl+F)"
	search_btn.pressed.connect(_on_search_pressed)
	hbox.add_child(search_btn)

	# 分隔符
	var separator1 := VSeparator.new()
	hbox.add_child(separator1)

	# 撤销按钮
	var undo_btn := Button.new()
	undo_btn.text = "撤销"
	undo_btn.tooltip_text = "撤销 (Ctrl+Z)"
	undo_btn.pressed.connect(_on_undo_pressed)
	hbox.add_child(undo_btn)

	# 重做按钮
	var redo_btn := Button.new()
	redo_btn.text = "重做"
	redo_btn.tooltip_text = "重做 (Ctrl+Y)"
	redo_btn.pressed.connect(_on_redo_pressed)
	hbox.add_child(redo_btn)

	# 分隔符
	var separator2 := VSeparator.new()
	hbox.add_child(separator2)

	# 导入按钮
	var import_btn := Button.new()
	import_btn.text = "导入"
	import_btn.tooltip_text = "导入文件 (TSV, JSON)"
	import_btn.pressed.connect(_on_import_pressed)
	hbox.add_child(import_btn)

	# 导出按钮
	var export_btn := Button.new()
	export_btn.text = "导出"
	export_btn.tooltip_text = "导出文件 (TSV, JSON)"
	export_btn.pressed.connect(_on_export_pressed)
	hbox.add_child(export_btn)

	# 设置按钮
	var settings_btn := Button.new()
	settings_btn.text = "设置"
	settings_btn.tooltip_text = "打开设置"
	settings_btn.pressed.connect(_on_settings_pressed)
	hbox.add_child(settings_btn)

	# 分隔符
	var separator3 := VSeparator.new()
	hbox.add_child(separator3)

	# 验证按钮
	var validate_btn := Button.new()
	validate_btn.text = "验证"
	validate_btn.tooltip_text = "验证数据"
	validate_btn.pressed.connect(_on_validate_pressed)
	hbox.add_child(validate_btn)

	# 弹性空间
	hbox.add_child(Control.new())

	return hbox


## 创建状态栏
func _create_status_bar() -> HBoxContainer:
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	hbox.custom_minimum_size.y = 30

	# 文件状态容器
	var file_status_container := _create_status_item()
	var file_status_icon := TextureRect.new()
	file_status_icon.name = "FileStatusIcon"
	file_status_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	file_status_icon.custom_minimum_size = Vector2(16, 16)
	file_status_container.add_child(file_status_icon)

	_file_status_label = Label.new()
	_file_status_label.name = "FileStatusLabel"
	_file_status_label.text = "未打开文件"
	file_status_container.add_child(_file_status_label)

	hbox.add_child(file_status_container)

	# 分隔符
	hbox.add_child(VSeparator.new())

	# 验证状态容器
	var validation_container := _create_status_item()
	var validation_icon := TextureRect.new()
	validation_icon.name = "ValidationIcon"
	validation_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	validation_icon.custom_minimum_size = Vector2(16, 16)
	validation_container.add_child(validation_icon)

	_validation_label = Label.new()
	_validation_label.name = "ValidationLabel"
	_validation_label.text = "验证状态: 未验证"
	validation_container.add_child(_validation_label)

	hbox.add_child(validation_container)

	# 弹性空间
	hbox.add_child(Control.new())

	# 行数统计标签
	_row_count_label = Label.new()
	_row_count_label.name = "RowCountLabel"
	_row_count_label.text = "行数: 0"
	hbox.add_child(_row_count_label)

	# 列数统计标签
	_col_count_label = Label.new()
	_col_count_label.name = "ColCountLabel"
	_col_count_label.text = "列数: 0"
	hbox.add_child(_col_count_label)

	return hbox


## 创建状态栏项
func _create_status_item() -> HBoxContainer:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 5)
	return container
#endregion

#region Cell Input Panel
func _create_cell_input_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 44
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_cell_input_debounce_timer = Timer.new()
	_cell_input_debounce_timer.one_shot = true
	_cell_input_debounce_timer.wait_time = 0.05
	_cell_input_debounce_timer.timeout.connect(func() -> void:
		_cell_input_live_applying=true
		_apply_cell_input_value()
		_cell_input_live_applying=false
	)
	panel.add_child(_cell_input_debounce_timer)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	panel.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	margin.add_child(hbox)

	var title := Label.new()
	title.text = "输入"
	title.custom_minimum_size.x = 36
	hbox.add_child(title)

	_cell_pos_label = Label.new()
	_cell_pos_label.text = "未选择单元格"
	_cell_pos_label.custom_minimum_size.x = 180
	hbox.add_child(_cell_pos_label)

	_cell_type_label = Label.new()
	_cell_type_label.text = ""
	_cell_type_label.custom_minimum_size.x = 140
	hbox.add_child(_cell_type_label)

	_cell_input_line = LineEdit.new()
	_cell_input_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cell_input_line.placeholder_text = "在此输入值（按 Enter 应用）"
	_cell_input_line.text_submitted.connect(func(_t: String) -> void:
		_apply_cell_input_value()
	)
	_cell_input_line.text_changed.connect(func(_t: String) -> void:
		_schedule_apply_cell_input()
	)
	hbox.add_child(_cell_input_line)

	_cell_input_text = TextEdit.new()
	_cell_input_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cell_input_text.size_flags_vertical = Control.SIZE_FILL
	_cell_input_text.custom_minimum_size = Vector2(0, 90)
	_cell_input_text.visible = false
	_cell_input_text.text_changed.connect(func() -> void:
		_schedule_apply_cell_input()
	)
	hbox.add_child(_cell_input_text)

	_cell_input_number = SpinBox.new()
	_cell_input_number.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cell_input_number.step = 1.0
	_cell_input_number.allow_greater = true
	_cell_input_number.allow_lesser = true
	_cell_input_number.visible = false
	_cell_input_number.value_changed.connect(func(_v: float) -> void:
		_cell_input_live_applying=true
		_apply_cell_input_value()
		_cell_input_live_applying=false
	)
	hbox.add_child(_cell_input_number)

	_cell_input_bool = CheckBox.new()
	_cell_input_bool.text = "True"
	_cell_input_bool.visible = false
	_cell_input_bool.toggled.connect(func(_p: bool) -> void:
		_cell_input_live_applying=true
		_apply_cell_input_value()
		_cell_input_live_applying=false
	)
	hbox.add_child(_cell_input_bool)

	_cell_input_enum = OptionButton.new()
	_cell_input_enum.visible = false
	_cell_input_enum.item_selected.connect(func(_idx: int) -> void:
		_cell_input_live_applying=true
		_apply_cell_input_value()
		_cell_input_live_applying=false
	)
	hbox.add_child(_cell_input_enum)

	_cell_input_vec_container = HBoxContainer.new()
	_cell_input_vec_container.add_theme_constant_override("separation", 6)
	_cell_input_vec_container.visible = false

	# 动态创建最多 6 个 SpinBox（支持 Transform2D）
	var component_labels := ["X", "Y", "Z", "W", "A", "B"]
	for i in range(6):
		var label := Label.new()
		label.text = component_labels[i]
		label.custom_minimum_size.x = 14
		_cell_input_vec_container.add_child(label)
		_cell_input_vec_labels.append(label)

		var spin := SpinBox.new()
		spin.step = 0.01
		spin.allow_greater = true
		spin.allow_lesser = true
		spin.custom_minimum_size.x = 90
		spin.value_changed.connect(func(_v: float) -> void:
			_cell_input_live_applying=true
			_apply_cell_input_value()
			_cell_input_live_applying=false
		)
		_cell_input_vec_container.add_child(spin)
		_cell_input_vec_spins.append(spin)

	hbox.add_child(_cell_input_vec_container)

	_cell_input_color = ColorPickerButton.new()
	_cell_input_color.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cell_input_color.visible = false
	_cell_input_color.color_changed.connect(func(_c: Color) -> void:
		_cell_input_live_applying=true
		_apply_cell_input_value()
		_cell_input_live_applying=false
	)
	hbox.add_child(_cell_input_color)

	_cell_input_array_btn = Button.new()
	_cell_input_array_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cell_input_array_btn.visible = false
	_cell_input_array_btn.pressed.connect(func() -> void:
		_open_array_editor()
	)
	hbox.add_child(_cell_input_array_btn)

	_cell_input_resource_btn = Button.new()
	_cell_input_resource_btn.text = "..."
	if has_theme_icon("Load", "EditorIcons"):
		_cell_input_resource_btn.icon = get_theme_icon("Load", "EditorIcons")
		_cell_input_resource_btn.text = ""
	_cell_input_resource_btn.tooltip_text = "打开资源选择器"
	_cell_input_resource_btn.visible = false
	_cell_input_resource_btn.pressed.connect(func() -> void:
		_open_cell_resource_selector()
	)
	hbox.add_child(_cell_input_resource_btn)

	_cell_default_btn = Button.new()
	_cell_default_btn.text = "默认值"
	_cell_default_btn.tooltip_text = "将选中单元格设置为类型默认值/Schema 默认值"
	_cell_default_btn.pressed.connect(func() -> void:
		_apply_cell_default_value()
	)
	hbox.add_child(_cell_default_btn)

	_cell_apply_btn = Button.new()
	_cell_apply_btn.text = "应用"
	_cell_apply_btn.tooltip_text = "应用输入到选中单元格"
	_cell_apply_btn.pressed.connect(func() -> void:
		_apply_cell_input_value()
	)
	_cell_apply_btn.visible = false
	hbox.add_child(_cell_apply_btn)

	_update_cell_input_ui()
	return panel


func _update_cell_input_ui() -> void:
	var readonly := _state_manager and _state_manager.is_file_readonly()
	var has_cell := _active_cell.x >= 0 and _active_cell.y >= 0

	_cell_input_line.editable = not readonly and has_cell
	_cell_input_text.editable = not readonly and has_cell
	_cell_input_number.editable = not readonly and has_cell
	_cell_apply_btn.disabled = readonly or not has_cell
	_cell_default_btn.disabled = readonly or not has_cell
	_cell_input_bool.disabled = readonly or not has_cell
	_cell_input_enum.disabled = readonly or not has_cell
	_cell_input_color.disabled = readonly or not has_cell
	_cell_input_array_btn.disabled = readonly or not has_cell
	_cell_input_resource_btn.disabled = readonly or not has_cell

	# 更新所有动态 SpinBox 的可编辑状态
	for spin in _cell_input_vec_spins:
		if spin and is_instance_valid(spin):
			spin.editable = not readonly and has_cell

	if not has_cell:
		_cell_pos_label.text = "未选择单元格"
		_cell_type_label.text = ""
		_cell_input_line.text = ""
		_cell_input_line.visible = true
		_cell_input_text.text = ""
		_cell_input_text.visible = false
		_cell_input_number.visible = false
		_cell_input_bool.visible = false
		_cell_input_enum.visible = false
		_cell_input_vec_container.visible = false
		_cell_input_color.visible = false
		_cell_input_array_btn.visible = false
		_cell_input_resource_btn.visible = false
#endregion

#region 文件操作功能 File Operations
## 加载文件
func load_file(file_path: String) -> bool:
	if file_path.is_empty():
		push_error("文件路径为空")
		return false

	var binding_key := _get_binding_key_for_file(file_path)

	# 检查文件是否已打开（用 uid 优先的 key）
	if _open_files.has(binding_key):
		_switch_to_binding_key(binding_key)
		return true

	# 为当前文件创建独立的数据处理器/数据模型（多标签页必须隔离数据源）
	var tab_processor := GDSVDataProcessor.new()
	# 同步面板级默认配置
	tab_processor.auto_trim_whitespace = _data_processor.auto_trim_whitespace
	tab_processor.default_delimiter = _data_processor.default_delimiter

	var success := tab_processor.load_gdsv_file(file_path)
	if not success:
		push_error("加载文件失败: " + tab_processor.last_error)
		return false

	var tab_model := GDSVDataModel.new()
	tab_model.set_data_processor(tab_processor)

	# 自动检测并加载 Schema（Schema/Validation/StateManager 仍是全局共享）
	var schema_path := _schema_manager.auto_detect_schema(file_path)
	if not schema_path.is_empty():
		_schema_manager.load_schema(schema_path)

	# 创建标签页（每个 tab 绑定自己的 data_model/data_processor）
	var tab_control := _create_tab_control(file_path, tab_model, tab_processor, binding_key)
	_tab_container.add_child(tab_control)
	_tab_container.current_tab = _tab_container.get_tab_count() - 1

	# 记录打开的文件
	_open_files[binding_key] = tab_control

	# 设置状态（仍使用 file_path 作为“当前文件”的对外展示）
	_state_manager.set_file_path(file_path)

	file_loaded.emit(file_path)
	_update_status_bar()

	return true


## 保存当前文件
func save_current_file() -> bool:
	if _current_tab_index < 0 or _current_tab_index >= _tab_container.get_tab_count():
		return false

	var tab_control: Control = _tab_container.get_tab_control(_current_tab_index)
	if not tab_control or not tab_control.has_method("get_file_path"):
		return false

	var file_path: String = tab_control.get_file_path()
	return save_file(file_path)


## 保存文件
func save_file(file_path: String) -> bool:
	if file_path.is_empty():
		return false

	# 多标签页：必须保存对应 tab 自己的 data_processor，不能用面板级 _data_processor。
	var binding_key := _get_binding_key_for_file(file_path)
	var tab_control: Control = _open_files.get(binding_key) as Control
	var processor: GDSVDataProcessor = null
	var model: GDSVDataModel = null
	if tab_control:
		if tab_control.has_method("get_data_processor"):
			processor = tab_control.get_data_processor() as GDSVDataProcessor
		if tab_control.has_method("get_data_model"):
			model = tab_control.get_data_model() as GDSVDataModel

	# 兜底：如果没取到，就回退使用当前活跃的 _data_processor。
	if not processor:
		processor = _data_processor

	var success := processor.save_gdsv_file(file_path)
	if success:
		# 保存成功后：清除“该 tab”的修改状态。
		if model and model.has_method("clear_modified"):
			model.clear_modified()
		else:
			# 兼容旧模型：只能清全局状态（只对当前 tab 完全准确）
			_state_manager.mark_file_saved()

		file_saved.emit(file_path)
		_update_status_bar()

		# 更新标签页标题
		var tab_index := _get_tab_index_by_binding_key(binding_key)
		if tab_index >= 0:
			_tab_container.set_tab_title(tab_index, file_path.get_file())

	return success


## 关闭文件
func close_file(file_path: String) -> void:
	var binding_key := _get_binding_key_for_file(file_path)
	if not _open_files.has(binding_key):
		return

	var tab_control: Control = _open_files[binding_key] as Control

	# 注意：StateManager 是“当前活跃文件”的状态。
	# 关闭非当前 tab 时，不应使用 _state_manager.is_file_modified() 判断。
	var is_modified := false
	if tab_control and tab_control.has_method("get_data_model"):
		var m: GDSVDataModel = tab_control.get_data_model()
		if m:
			is_modified = bool(m.is_modified())

	if not is_modified:
		_close_file_internal(file_path, binding_key)
		return

	_show_save_confirmation(file_path,
		func(choice: StringName) -> void:
			match str(choice):
				"save":
					if save_file(file_path):
						_close_file_internal(file_path, binding_key)
					else:
						push_error("保存失败，未关闭文件: " + file_path)
				"dont_save":
					_close_file_internal(file_path, binding_key)
				_: # cancel / other
					pass
	)


func _close_file_internal(file_path: String, binding_key: String) -> void:
	var tab_control: Control = _open_files.get(binding_key) as Control
	if not tab_control or not is_instance_valid(tab_control):
		_open_files.erase(binding_key)
		return

	# 先从容器移除，再释放，确保标签页 UI 立即更新
	if tab_control.get_parent() == _tab_container:
		_tab_container.remove_child(tab_control)
	tab_control.queue_free()

	_open_files.erase(binding_key)

	if _tab_container.get_tab_count() > 0:
		_tab_container.current_tab = clampi(_tab_container.current_tab, 0, _tab_container.get_tab_count() - 1)
	else:
		_state_manager.close_file()

	file_closed.emit(file_path)
	_update_status_bar()


## 显示保存确认对话框
func _show_save_confirmation(file_path: String, on_choice: Callable) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "保存文件"
	dialog.dialog_text = "文件 " + file_path.get_file() + " 已修改，是否保存？"
	dialog.get_ok_button().text = "保存"
	dialog.cancel_button_text = "取消"
	dialog.add_button("不保存", false, "dont_save")
	add_child(dialog)

	var _emit_and_close := func(action: StringName) -> void:
		if on_choice:
			on_choice.call(action)
		dialog.hide()
		dialog.queue_free()

	dialog.confirmed.connect(func() -> void:
		_emit_and_close.call("save")
	)
	dialog.canceled.connect(func() -> void:
		_emit_and_close.call("cancel")
	)
	dialog.custom_action.connect(func(action: StringName) -> void:
		if str(action) == "dont_save":
			_emit_and_close.call("dont_save")
		else:
			_emit_and_close.call("cancel")
	)
	# 兜底：用户按右上角关闭按钮
	dialog.close_requested.connect(func() -> void:
		_emit_and_close.call("cancel")
	)

	dialog.popup_centered()


## 检查外部文件修改
func check_external_file_modification() -> void:
	if _state_manager.has_file() and _data_processor:
		if _data_processor.is_file_modified_externally():
			_show_external_modification_warning()


## 显示外部文件修改警告
func _show_external_modification_warning() -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "文件已修改"
	dialog.dialog_text = "文件已被外部程序修改，是否重新加载？\n\n注意：重新加载将丢失所有未保存的修改。"
	dialog.get_ok_button().text = "重新加载"
	dialog.add_button("取消", true)

	dialog.confirmed.connect(_on_reload_confirmed)

	add_child(dialog)
	dialog.popup_centered()


## 重新加载确认回调
func _on_reload_confirmed() -> void:
	if _state_manager.has_file():
		var file_path: String = _state_manager.file_path
		load_file(file_path)


## 关闭所有文件
func close_all_files() -> void:
	var binding_keys := _open_files.keys()
	for binding_key in binding_keys:
		var tab_control := _open_files.get(binding_key) as Object
		if tab_control and tab_control.has_method("get_file_path"):
			close_file(tab_control.get_file_path())
#endregion

#region 标签页管理功能 Tab Management Features
## 创建标签页控件
func _create_tab_control(file_path: String, tab_model: GDSVDataModel, tab_processor: GDSVDataProcessor, binding_key: String) -> Control:
	var tab_control := GDSVEditorTab.new()
	tab_control.name = file_path.get_file()
	tab_control._file_path = file_path
	# 统一绑定：优先用 uid:// 作为编号
	if str(binding_key).begins_with("uid://"):
		tab_control._doc_uid = binding_key
	else:
		tab_control._doc_uid = ""
	tab_control._data_model = tab_model
	tab_control._data_processor = tab_processor
	tab_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 添加表格视图
	var table_view := _create_table_view(tab_model, tab_processor)
	tab_control._table_view = table_view
	tab_control.add_child(table_view)

	return tab_control


## 创建表格视图
func _create_table_view(tab_model: GDSVDataModel, tab_processor: GDSVDataProcessor) -> Control:
	var table_view := TableView.new()
	table_view.set_data_model(tab_model)
	table_view.set_state_manager(_state_manager)
	table_view.set_schema_manager(_schema_manager)
	table_view.set_validation_manager(_validation_manager)
	table_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	table_view.enable_double_click_editing = false

	if _config_manager:
		table_view.show_line_numbers = _config_manager.get_show_row_numbers()
		table_view.enable_virtual_scrolling = _config_manager.get_enable_virtual_scroll()
		table_view.set_text_overflow_mode(_get_text_overflow_mode())

	# 连接行列操作信号
	if not table_view.row_requested.is_connected(_on_row_operation_requested):
		table_view.row_requested.connect(_on_row_operation_requested)
	if not table_view.row_reordered.is_connected(_on_row_reordered):
		table_view.row_reordered.connect(_on_row_reordered)
	if not table_view.column_requested.is_connected(_on_column_operation_requested):
		table_view.column_requested.connect(_on_column_operation_requested)
	if not table_view.column_settings_requested.is_connected(_on_column_settings_requested):
		table_view.column_settings_requested.connect(_on_column_settings_requested)
	if not table_view.fields_settings_requested.is_connected(_on_fields_settings_requested):
		table_view.fields_settings_requested.connect(_on_fields_settings_requested)
	if not table_view.cell_selected.is_connected(_on_table_cell_selected):
		table_view.cell_selected.connect(_on_table_cell_selected)

	return table_view


## 切换到指定文件（兼容接口：内部转为 binding_key）
func _switch_to_file(file_path: String) -> void:
	_switch_to_binding_key(_get_binding_key_for_file(file_path))


## 切换到指定 binding_key（uid 优先）
func _switch_to_binding_key(binding_key: String) -> void:
	var tab_index := _get_tab_index_by_binding_key(binding_key)
	if tab_index >= 0:
		_tab_container.current_tab = tab_index


## 获取文件对应的标签页索引（兼容接口：内部转为 binding_key）
func _get_tab_index_by_path(file_path: String) -> int:
	return _get_tab_index_by_binding_key(_get_binding_key_for_file(file_path))


## 获取 binding_key 对应的标签页索引
func _get_tab_index_by_binding_key(binding_key: String) -> int:
	for i in range(_tab_container.get_tab_count()):
		var tab_control := _tab_container.get_tab_control(i)
		if not tab_control:
			continue
		if tab_control.has_method("get_binding_key") and tab_control.get_binding_key() == binding_key:
			return i
		# 兼容旧 tab：没有 get_binding_key 时用 file_path 对比
		if tab_control.has_method("get_file_path") and tab_control.get_file_path() == binding_key:
			return i
	return -1


## 标签页切换回调
func _on_tab_changed(index: int) -> void:
	_current_tab_index = index

	if index >= 0 and index < _tab_container.get_tab_count():
		var tab_control := _tab_container.get_tab_control(index)
		if tab_control:
			# 切换当前活跃的数据源（否则 Tab 只是“标签”，内容不会变）
			# 注意：必须先切换 _data_model，再绑定 processor。
			if tab_control.has_method("get_data_model"):
				var m: GDSVDataModel = tab_control.get_data_model()
				if m:
					_data_model = m
					_state_manager.set_data_model(_data_model)

			if tab_control.has_method("get_data_processor"):
				var p: GDSVDataProcessor = tab_control.get_data_processor()
				if p:
					_data_processor = p
					_schema_manager.set_data_processor(_data_processor)
					_validation_manager.set_data_processor(_data_processor)
					_data_model.set_data_processor(_data_processor)

			if tab_control.has_method("get_file_path"):
				var file_path: String = tab_control.get_file_path()
				_state_manager.set_file_path(file_path)
				# Tab 切换时：SchemaManager 为全局共享对象，必须清理旧 schema，
				# 否则字段设置弹窗可能仍显示上一个文件的类型。
				if _schema_manager:
					_schema_manager.unload_schema()
				_update_status_bar()

			# 主动刷新一次，避免 TabContainer 切换时 TableView 布局/可见行计算没更新
			if tab_control.has_method("get_table_view"):
				var tv = tab_control.get_table_view()
				if tv and tv.has_method("refresh"):
					tv.call_deferred("refresh")

	_active_cell = Vector2i(-1, -1)
	# Tab 切换后，底部输入区必须与当前表格重新绑定（类型/默认值等依赖 _data_model/_schema_manager）。
	_refresh_cell_input_from_model()
#endregion

#region Schema和验证功能 Schema and Validation Features
## 加载Schema
func load_schema(schema_path: String) -> bool:
	if not _schema_manager:
		return false

	return _schema_manager.load_schema(schema_path)


## 验证数据
func validate_current_file() -> void:
	if _current_tab_index < 0:
		return

	validation_started.emit()

	if _validation_manager:
		var error_count := _validation_manager.validate_table()
		_update_status_bar()


## 显示验证错误
func show_validation_errors() -> void:
	# TODO: 实现错误对话框
	print("显示验证错误")
#endregion

#region 搜索和替换功能 Search and Replace Features
## 搜索文本
func search_text(search_text: String) -> void:
	_run_search(search_text, false, false)


## 替换文本
func replace_text(search_text: String, replace_text: String) -> void:
	# TODO: 实现替换功能
	print("替换: ", search_text, " -> ", replace_text)


func _ensure_search_dialog() -> void:
	if _search_dialog and is_instance_valid(_search_dialog):
		return

	_search_dialog = AcceptDialog.new()
	_search_dialog.title = "查询"
	_search_dialog.min_size = Vector2(420, 0)
	_search_dialog.get_ok_button().hide()
	_search_dialog.add_button("关闭", false, "close")
	_search_dialog.add_button("上一条", false, "prev")
	_search_dialog.add_button("下一条", false, "next")
	_search_dialog.add_button("查询", false, "search")
	_search_dialog.custom_action.connect(_on_search_dialog_action)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_search_dialog.add_child(vbox)

	_search_dialog_line_edit = LineEdit.new()
	_search_dialog_line_edit.placeholder_text = "输入查询内容"
	_search_dialog_line_edit.text_submitted.connect(func(_text: String) -> void:
		_on_search_dialog_confirmed()
	)
	vbox.add_child(_search_dialog_line_edit)

	var options_row := HBoxContainer.new()
	options_row.add_theme_constant_override("separation", 10)
	vbox.add_child(options_row)

	_search_dialog_case_checkbox = CheckBox.new()
	_search_dialog_case_checkbox.text = "区分大小写"
	options_row.add_child(_search_dialog_case_checkbox)

	_search_dialog_regex_checkbox = CheckBox.new()
	_search_dialog_regex_checkbox.text = "正则"
	options_row.add_child(_search_dialog_regex_checkbox)

	_search_dialog_status_label = Label.new()
	_search_dialog_status_label.text = ""
	vbox.add_child(_search_dialog_status_label)

	add_child(_search_dialog)


func _show_search_dialog() -> void:
	_ensure_search_dialog()
	_search_dialog.popup_centered()
	if _search_dialog_line_edit:
		_search_dialog_line_edit.grab_focus()


func _on_search_dialog_confirmed() -> void:
	if not _search_dialog_line_edit:
		return
	var text := _search_dialog_line_edit.text.strip_edges()
	if text.is_empty():
		_update_search_dialog_status("请输入查询内容")
		return
	_run_search(text, _search_dialog_case_checkbox.button_pressed, _search_dialog_regex_checkbox.button_pressed)


func _on_search_dialog_action(action: String) -> void:
	if action == "search":
		_on_search_dialog_confirmed()
		return

	if action == "close":
		_search_dialog.hide()
		return

	if _search_results.is_empty():
		_update_search_dialog_status("没有匹配结果")
		return
	if action == "prev":
		_select_search_result(_current_search_index - 1)
	elif action == "next":
		_select_search_result(_current_search_index + 1)


func _run_search(search_text: String, case_sensitive: bool, use_regex: bool) -> void:
	if not _data_model:
		_update_search_dialog_status("未打开文件")
		return
	if not _data_processor:
		_update_search_dialog_status("数据处理器不可用")
		return

	if use_regex:
		_search_results = _data_processor.search_regex(search_text)
	else:
		_search_results = _data_model.search_text(
			search_text,
			case_sensitive,
			GDSVDataModel.MatchMode.MATCH_CONTAINS
		)

	if _data_processor.has_error:
		_update_search_dialog_status(_data_processor.last_error)
		return

	if _search_results.is_empty():
		_current_search_index = -1
		_update_search_dialog_status("未找到匹配")
		return

	_select_search_result(0)
	_update_search_dialog_status("匹配 %s 项" % _search_results.size())


func _select_search_result(index: int) -> void:
	if _search_results.is_empty():
		_current_search_index = -1
		return

	if index < 0:
		index = _search_results.size() - 1
	elif index >= _search_results.size():
		index = 0

	_current_search_index = index
	var result: Dictionary = _search_results[index]
	var row := int(result.get("row", -1))
	var col := int(result.get("column", -1))
	if row < 0 or col < 0:
		_update_search_dialog_status("查询结果无效")
		return

	var table_view := _get_active_table_view()
	if table_view and table_view.has_method("_select_cell"):
		table_view.call("_select_cell", Vector2i(row, col))
		table_view.queue_redraw()
	if _state_manager:
		_state_manager.select_cell(row, col)

	_active_cell = Vector2i(row, col)
	_refresh_cell_input_from_model()
	_update_search_dialog_status("结果 %s / %s" % [str(index + 1), str(_search_results.size())])


func _update_search_dialog_status(text: String) -> void:
	if _search_dialog_status_label:
		_search_dialog_status_label.text = text
#endregion

#region UI更新功能 UI Update Features
## 更新状态栏
func _update_status_bar() -> void:
	if _file_status_label:
		if _state_manager.has_file():
			var file_name := _state_manager.get_file_name()
			var modified_mark := "*" if _state_manager.is_file_modified() else ""
			var readonly_mark := " (只读)" if _state_manager.is_file_readonly() else ""
			_file_status_label.text = file_name + modified_mark + readonly_mark
		else:
			_file_status_label.text = "未打开文件"

	if _validation_label:
		if _validation_manager and _validation_manager.has_errors():
			var error_count := _validation_manager.get_error_count()
			var warning_count := _validation_manager.get_warning_count()
			var text := "验证状态: "
			if error_count > 0:
				text += str(error_count) + " 个错误"
			if warning_count > 0:
				if error_count > 0:
					text += ", "
				text += str(warning_count) + " 个警告"
			_validation_label.text = text
		else:
			_validation_label.text = "验证状态: 无错误"

	if _row_count_label:
		_row_count_label.text = "行数: " + str(_data_processor.get_row_count())

	if _col_count_label:
		_col_count_label.text = "列数: " + str(_data_processor.get_column_count())
#endregion

#region 工具方法 Utility Methods
## 清理打开的文件
func _cleanup_open_files() -> void:
	for binding_key in _open_files:
		var tab_control: Object = _open_files[binding_key]
		if is_instance_valid(tab_control):
			(tab_control as Node).queue_free()
	_open_files.clear()
#endregion

#region 回调处理 Callback Handlers
## 文件加载回调
func _on_file_loaded(success: bool, error_message: String) -> void:
	if not success:
		push_error("文件加载失败: " + error_message)


## 文件保存回调
func _on_file_saved(success: bool, error_message: String) -> void:
	if not success:
		push_error("文件保存失败: " + error_message)
	else:
		print("文件保存成功")


## 状态管理器文件保存回调
func _on_state_manager_file_saved(file_path: String) -> void:
	print("文件已保存: ", file_path)


## 验证完成回调
func _on_validation_completed(results: Array) -> void:
	_update_status_bar()


## 状态变化回调
func _on_state_changed(state_type: String, old_value: Variant, new_value: Variant) -> void:
	_update_status_bar()


## 标签页关闭回调
func _on_tab_close_pressed(index: int) -> void:
	var tab_control := _tab_container.get_tab_control(index)
	if tab_control and tab_control.has_method("get_file_path"):
		close_file(tab_control.get_file_path())


## 保存按钮回调
func _on_save_pressed() -> void:
	save_current_file()


## 加载Schema按钮回调
func _on_load_schema_pressed() -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.title = "选择Schema文件"
	dialog.add_filter("*.schema; Schema文件")
	dialog.file_selected.connect(_on_schema_file_selected)
	add_child(dialog)
	dialog.popup_centered()


## 加载Schema文件选择回调
func _on_schema_file_selected(schema_path: String) -> void:
	load_schema(schema_path)


## 导入按钮回调
func _on_import_pressed() -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.title = "导入文件"
	dialog.add_filter("*.gdsv; GDSV文件")
	dialog.add_filter("*.csv; CSV文件")
	dialog.add_filter("*.tsv; TSV文件")
	dialog.add_filter("*.json; JSON文件")
	dialog.file_selected.connect(_on_import_file_selected)
	add_child(dialog)
	dialog.popup_centered()


## 导入文件选择回调
func _on_import_file_selected(file_path: String) -> void:
	var extension := file_path.get_extension().to_lower()
	var success := false

	match extension:
		"tsv":
			success = _data_processor.import_tsv_file(file_path)
		"json":
			success = _data_processor.import_json_file(file_path)
		_:
			success = load_file(file_path)

	if success:
		_state_manager.set_file_path(file_path)
		_state_manager.mark_file_saved()
		_update_status_bar()
		print("导入成功: ", file_path)
	else:
		push_error("导入失败: " + _data_processor.last_error)


## 导出按钮回调
func _on_export_pressed() -> void:
	if not _state_manager.has_file():
		push_warning("没有打开的文件")
		return

	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	dialog.title = "导出文件"
	dialog.add_filter("*.tsv; TSV文件")
	dialog.add_filter("*.json; JSON文件")
	dialog.file_selected.connect(_on_export_file_selected)
	# FileDialog 在 Godot 4.5 不支持 await popup_hide（不存在该属性/信号包装）。
	# 这里交给 file_selected 回调处理导出逻辑；关闭/取消时自动回收。
	dialog.file_selected.connect(func(_p: String) -> void:
		dialog.hide()
		dialog.queue_free()
	)
	dialog.canceled.connect(func() -> void:
		dialog.hide()
		dialog.queue_free()
	)
	dialog.close_requested.connect(func() -> void:
		dialog.hide()
		dialog.queue_free()
	)
	add_child(dialog)
	dialog.popup_centered()


## 设置按钮回调
func _on_settings_pressed() -> void:
	var settings_dialog := SettingsDialog.new()
	settings_dialog.config_manager = _config_manager
	settings_dialog.settings_changed.connect(_on_settings_changed)
	add_child(settings_dialog)
	settings_dialog.popup_centered()


## 字段设置按钮回调
func _on_column_settings_pressed() -> void:
	if not _state_manager or not _state_manager.has_file():
		push_warning("未打开文件")
		return

	_ensure_fields_settings_dialog()
	var col := _state_manager.selected_cell.y if _state_manager else -1
	_fields_settings_dialog.open_for_column(col)


## 设置变化回调
func _on_settings_changed() -> void:
	_apply_all_settings()


## 导出文件选择回调
func _on_export_file_selected(file_path: String) -> void:
	var extension := file_path.get_extension().to_lower()
	var success := false

	match extension:
		"tsv":
			success = _data_processor.export_tsv_file(file_path)
		"json":
			success = _data_processor.export_json_file(file_path)
		_:
			push_error("不支持的导出格式")
			return

	if success:
		print("导出成功: ", file_path)
	else:
		push_error("导出失败: " + _data_processor.last_error)


## 搜索按钮回调
func _on_search_pressed() -> void:
	_show_search_dialog()


## 撤销按钮回调
func _on_undo_pressed() -> void:
	if _data_model and _data_model.has_undo():
		_data_model.undo()


## 重做按钮回调
func _on_redo_pressed() -> void:
	if _data_model and _data_model.has_redo():
		_data_model.redo()


## 验证按钮回调
func _on_validate_pressed() -> void:
	validate_current_file()
#endregion

#region 辅助方法 Auxiliary Methods
## 获取数据处理器
func get_data_processor() -> GDSVDataProcessor:
	return _data_processor


## 获取数据模型
func get_data_model() -> GDSVDataModel:
	return _data_model


## 获取状态管理器
func get_state_manager() -> GDSVStateManager:
	return _state_manager


## 获取 Schema 管理器
func get_schema_manager() -> SchemaManager:
	return _schema_manager


## 获取验证管理器
func get_validation_manager() -> ValidationManager:
	return _validation_manager
#endregion

#region 绑定工具方法 Binding Utilities
## 生成稳定的绑定 key：优先 uid://，不可用则回退为 file_path
func _get_binding_key_for_file(file_path: String) -> String:
	var p := str(file_path).strip_edges()
	if p.is_empty():
		return ""
	if p.begins_with("uid://"):
		return p
	if not p.begins_with("res://"):
		# 外部路径/临时文件：无法稳定取 UID，回退使用原始路径
		return p
	# Godot 4.5：优先通过 ResourceUID 从路径获取 UID。
	# 注意：不要通过 `Resource.resource_uid` 取（4.5 下 Resource 不一定暴露该属性，会报错）。
	if not ResourceLoader.exists(p):
		return p

	# Godot 4.5.1：优先通过 ResourceLoader.get_resource_uid(path) 获取 UID。
	# 说明：4.5.1 环境下 `ResourceUID.get_id()` 可能不存在，因此不能依赖该 API。
	var uid_id: int = 0
	if ResourceLoader.has_method("get_resource_uid"):
		uid_id = int(ResourceLoader.get_resource_uid(p))

	if uid_id == 0:
		return p
	return ResourceUID.id_to_text(uid_id)
#endregion

#region 行列操作回调 Row/Column Callbacks
## 行操作请求回调
func _on_row_operation_requested(operation: String, row: int) -> void:
	match operation:
		"insert_above":
			_data_model.insert_row(row)
		"insert_below":
			_data_model.insert_row(row + 1)
		"delete":
			_data_model.remove_row(row)
		"move_up":
			_data_model.move_row(row, row - 1)
		"move_down":
			_data_model.move_row(row, row + 1)


func _on_row_reordered(from_index: int, to_index: int) -> void:
	if not _data_model:
		return
	_data_model.move_row(from_index, to_index)


## 列操作请求回调
func _on_column_operation_requested(operation: String, column: int) -> void:
	match operation:
		"insert_left":
			var col_name := "Column_" + str(column + 1)
			_data_model.insert_column(column, col_name, "")
		"insert_right":
			var col_name := "Column_" + str(column + 2)
			_data_model.insert_column(column + 1, col_name, "")
		"delete":
			_data_model.remove_column(column)
		"move_left":
			_data_model.move_column(column, column - 1)
		"move_right":
			_data_model.move_column(column, column + 1)


## 列设置请求回调（右键菜单）
func _on_column_settings_requested(column: int) -> void:
	if not _data_model:
		return

	_ensure_fields_settings_dialog()
	# 关键：多标签页切换后，弹窗可能仍绑定旧的 data_model，需要每次打开前刷新绑定。
	_fields_settings_dialog.data_model = _data_model
	_fields_settings_dialog.schema_manager = _schema_manager

	# 注意：不要在这里隐式 load_schema()。
	# SchemaManager 是全局共享的，但加载 schema 会直接覆盖 StateManager/DataModel 的类型定义，
	# 若 schema 与当前表头不完全一致，会导致“全部变成 string / 第一列标红”等连锁问题。
	_fields_settings_dialog.open_for_column(column)


func _on_fields_settings_requested() -> void:
	# 顶部左上角按钮：没有明确列时用当前选中列，否则让弹窗自行选中第一个字段。
	var col := _active_cell.y if _active_cell.y >= 0 else -1
	_on_column_settings_requested(col)
#endregion


func _ensure_fields_settings_dialog() -> void:
	if _fields_settings_dialog and is_instance_valid(_fields_settings_dialog):
		return

	_fields_settings_dialog = FieldsSettingsDialog.new()
	_fields_settings_dialog.data_model = _data_model
	_fields_settings_dialog.schema_manager = _schema_manager
	_fields_settings_dialog.config_manager = _config_manager
	_fields_settings_dialog.commit_changes = Callable(self, "_commit_field_settings_changes")
	add_child(_fields_settings_dialog)


func _commit_field_settings_changes() -> void:
	_write_full_schema_from_current_state()
	_update_status_bar()


func _write_full_schema_from_current_state() -> void:
	if not _schema_manager or not _state_manager or not _data_model:
		return
	if not _state_manager.has_file():
		return

	var file_path := _state_manager.file_path
	if file_path.is_empty():
		return

	var schema_path := _schema_manager.get_schema_path()
	if schema_path.is_empty():
		schema_path = _get_default_schema_path_for_file(file_path)

	if schema_path.is_empty():
		return

	var schema_data := _schema_manager.get_schema_data()
	if not (schema_data is Dictionary):
		schema_data = {}
	else:
		schema_data = schema_data.duplicate(true)

	var fields: Array = []
	var header := _data_model.get_header()
	for i in range(header.size()):
		var col_def := _data_model.get_column_type_definition(i)
		col_def = col_def.duplicate()
		col_def["name"] = header[i]
		if not col_def.has("type") or str(col_def.get("type", "")).is_empty():
			col_def["type"] = "string"
		fields.append(_convert_type_definition_to_schema_field(col_def))

	schema_data["fields"] = fields

	if not _write_schema_file(schema_path, schema_data):
		return

	_schema_manager.load_schema(schema_path)


func _get_default_schema_path_for_file(file_path: String) -> String:
	if file_path.is_empty():
		return ""
	var base_dir := file_path.get_base_dir()
	var base_name := file_path.get_file().get_basename()
	if base_dir.is_empty() or base_name.is_empty():
		return ""
	return base_dir.path_join(base_name + ".schema")


func _convert_type_definition_to_schema_field(type_definition: Dictionary) -> Dictionary:
	var field: Dictionary = {}

	var name := str(type_definition.get("name", "")).strip_edges()
	if name.is_empty():
		return field
	field["name"] = name

	var type_str := str(type_definition.get("type", "string")).strip_edges()
	if type_str.is_empty():
		type_str = "string"
	field["type"] = type_str

	if type_definition.has("required"):
		field["required"] = bool(type_definition.get("required", false))

	if type_definition.has("default"):
		field["default_value"] = type_definition.get("default")

	var constraints: Dictionary = {}
	if type_definition.has("min"):
		constraints["min"] = type_definition.get("min")
	if type_definition.has("max"):
		constraints["max"] = type_definition.get("max")
	if type_definition.has("min_length"):
		constraints["min_length"] = type_definition.get("min_length")
	if type_definition.has("max_length"):
		constraints["max_length"] = type_definition.get("max_length")
	if type_definition.has("pattern"):
		constraints["pattern"] = type_definition.get("pattern")
	if not constraints.is_empty():
		field["constraints"] = constraints

	if type_definition.has("enum_values") and type_definition.enum_values is Array:
		field["enum_values"] = type_definition.enum_values

	if type_definition.has("array_element_type"):
		field["array_type"] = type_definition.get("array_element_type")

	return field


func _write_schema_file(schema_path: String, schema_data: Dictionary) -> bool:
	var file := FileAccess.open(schema_path, FileAccess.WRITE)
	if file == null:
		push_error("无法写入 Schema 文件: " + schema_path)
		return false

	var json_text := JSON.stringify(schema_data, "\t")
	file.store_string(json_text + "\n")
	file.close()
	return true

#region 输入处理 Input Handling
## 处理输入事件（快捷键）
func _input(event: InputEvent) -> void:
	if not _should_handle_shortcuts():
		return

	if not event is InputEventKey:
		return

	var key_event := event as InputEventKey
	if not key_event.pressed:
		return

	# 如果当前正在编辑单元格，尽量不要抢占键盘事件（让 LineEdit/OptionButton 等处理）。
	# 这里仅保留 Ctrl+S 保存快捷键。
	if _state_manager and _state_manager.is_in_edit_mode():
		if Input.is_key_pressed(KEY_CTRL) and key_event.keycode == KEY_S:
			save_current_file()
			get_viewport().set_input_as_handled()
		return

	# 当焦点在文本输入控件上时，不处理表格级快捷键（避免覆盖文本编辑行为）。
	var focus_owner := get_viewport().gui_get_focus_owner()
	if focus_owner and (focus_owner is LineEdit or focus_owner is TextEdit):
		if Input.is_key_pressed(KEY_CTRL) and key_event.keycode == KEY_S:
			save_current_file()
			get_viewport().set_input_as_handled()
		return

	# Ctrl + S: 保存文件
	if Input.is_key_pressed(KEY_CTRL) and key_event.keycode == KEY_S:
		save_current_file()
		get_viewport().set_input_as_handled()
		return

	# Ctrl + C: 复制
	if Input.is_key_pressed(KEY_CTRL) and key_event.keycode == KEY_C:
		_copy_selection()
		get_viewport().set_input_as_handled()
		return

	# Ctrl + X: 剪切
	if Input.is_key_pressed(KEY_CTRL) and key_event.keycode == KEY_X:
		_cut_selection()
		get_viewport().set_input_as_handled()
		return

	# Ctrl + V: 粘贴
	if Input.is_key_pressed(KEY_CTRL) and key_event.keycode == KEY_V:
		_paste_clipboard()
		get_viewport().set_input_as_handled()
		return

	# Ctrl + A: 全选
	if Input.is_key_pressed(KEY_CTRL) and key_event.keycode == KEY_A:
		_select_all()
		get_viewport().set_input_as_handled()
		return

	# Delete: 删除选中内容
	if key_event.keycode == KEY_DELETE:
		_delete_selection()
		get_viewport().set_input_as_handled()
		return

	# Ctrl + Z: 撤销
	if Input.is_key_pressed(KEY_CTRL) and key_event.keycode == KEY_Z:
		if _data_model and _data_model.has_undo():
			_data_model.undo()
			get_viewport().set_input_as_handled()
		return

	# Ctrl + Y: 重做
	if Input.is_key_pressed(KEY_CTRL) and key_event.keycode == KEY_Y:
		if _data_model and _data_model.has_redo():
			_data_model.redo()
			get_viewport().set_input_as_handled()
		return

	# Ctrl + F: 搜索
	if Input.is_key_pressed(KEY_CTRL) and key_event.keycode == KEY_F:
		_show_search_bar()
		get_viewport().set_input_as_handled()
		return

	# Ctrl + H: 替换
	if Input.is_key_pressed(KEY_CTRL) and key_event.keycode == KEY_H:
		_show_replace_bar()
		get_viewport().set_input_as_handled()
		return

	# Ctrl + Home: 跳转到第一个单元格
	if Input.is_key_pressed(KEY_CTRL) and key_event.keycode == KEY_HOME:
		_jump_to_cell(0, 0)
		get_viewport().set_input_as_handled()
		return

	# Ctrl + End: 跳转到最后一个单元格
	if Input.is_key_pressed(KEY_CTRL) and key_event.keycode == KEY_END:
		if _data_model:
			var last_row: int = _data_model.get_row_count() - 1
			var last_col: int = _data_model.get_column_count() - 1
			_jump_to_cell(last_row, last_col)
		get_viewport().set_input_as_handled()
		return

	# F2: 进入编辑模式
	if key_event.keycode == KEY_F2:
		_enter_edit_mode()
		get_viewport().set_input_as_handled()
		return
#endregion

#region 快捷键条件 Shortcut Conditions
func _should_handle_shortcuts() -> bool:
	if not is_visible_in_tree():
		return false

	var viewport := get_viewport()
	if not viewport:
		return false

	var focus_owner := viewport.gui_get_focus_owner()
	if focus_owner and (focus_owner == self or is_ancestor_of(focus_owner)):
		return true

	# 表格视图是自绘控件，默认可能不抢焦点；这种情况下用鼠标位置作为兜底判断。
	return get_global_rect().has_point(viewport.get_mouse_position())
#endregion

#region 剪贴板功能 Clipboard Features
## 复制选中内容
func _copy_selection() -> void:
	if not _has_selection or not _data_model:
		return

	var rows := []
	var start_row := min(_selection.start_row, _selection.end_row)
	var end_row := max(_selection.start_row, _selection.end_row)
	var start_col := min(_selection.start_col, _selection.end_col)
	var end_col := max(_selection.start_col, _selection.end_col)

	for row in range(start_row, end_row + 1):
		var row_data := []
		for col in range(start_col, end_col + 1):
			row_data.append(_data_model.get_cell_value(row, col))
		rows.append(row_data)

	_clipboard = {"rows": rows, "cols": end_col - start_col + 1}
	_has_clipboard_data = true

	print("已复制 ", rows.size(), " 行, ", end_col - start_col + 1, " 列")


## 剪切选中内容
func _cut_selection() -> void:
	_copy_selection()
	_delete_selection()


## 粘贴剪贴板内容
func _paste_clipboard() -> void:
	if not _has_clipboard_data or not _data_model:
		return

	var current_row := -1
	var current_col := -1

	# 获取当前选中位置或默认为第一个单元格
	if _has_selection:
		current_row = min(_selection.start_row, _selection.end_row)
		current_col = min(_selection.start_col, _selection.end_col)
	else:
		current_row = 0
		current_col = 0

	var rows: Array = _clipboard.rows as Array
	var col_count: int = int(_clipboard.cols)

	for i in range(rows.size()):
		var row := current_row + i
		if row >= _data_model.get_row_count():
			_data_model.insert_row(row, [])

		for j in range(col_count):
			var col := current_col + j
			if col >= _data_model.get_column_count():
				var col_name := "Column_" + str(col + 1)
				_data_model.insert_column(col, col_name, "")

			_data_model.set_cell_value(row, col, rows[i][j])

	print("已粘贴 ", rows.size(), " 行, ", col_count, " 列")


## 删除选中内容
func _delete_selection() -> void:
	var table_view := _get_active_table_view()
	if table_view and table_view.has_method("has_selection") and table_view.has_selection():
		table_view.delete_selection()
		return

	if not _has_selection or not _data_model:
		return

	var start_row := min(_selection.start_row, _selection.end_row)
	var end_row := max(_selection.start_row, _selection.end_row)
	var start_col := min(_selection.start_col, _selection.end_col)
	var end_col := max(_selection.start_col, _selection.end_col)

	for row in range(start_row, end_row + 1):
		for col in range(start_col, end_col + 1):
			_data_model.set_cell_value(row, col, "")

	print("已删除选中内容")


## 全选
func _select_all() -> void:
	if not _data_model:
		return

	var table_view := _get_active_table_view()
	if table_view:
		table_view.select_all()

	_selection = {
		"start_row": 0,
		"start_col": 0,
		"end_row": _data_model.get_row_count() - 1,
		"end_col": _data_model.get_column_count() - 1
	}
	_has_selection = true

	print("已全选: ", _data_model.get_row_count(), " 行, ", _data_model.get_column_count(), " 列")
#endregion

#region 搜索和替换 Search and Replace Features
## 显示搜索栏
func _show_search_bar() -> void:
	if _search_bar:
		_search_bar.show()
		if _search_line_edit:
			_search_line_edit.grab_focus()
		print("搜索栏已显示")


## 显示替换栏
func _show_replace_bar() -> void:
	if _search_bar:
		_search_bar.show()
		if _replace_line_edit:
			_replace_line_edit.show()
		print("替换栏已显示")
#endregion

#region 导航功能 Navigation Features
## 跳转到指定单元格
func _jump_to_cell(row: int, col: int) -> void:
	if not _data_model:
		return

	if row < 0 or row >= _data_model.get_row_count():
		push_error("行索引超出范围")
		return

	if col < 0 or col >= _data_model.get_column_count():
		push_error("列索引超出范围")
		return

	# TODO: 实现跳转到单元格的视觉更新
	print("跳转到单元格: ", row, ", ", col)
#endregion

#region TableView Helpers
func _get_active_table_view() -> TableView:
	if not _tab_container:
		return null
	if _current_tab_index < 0 or _current_tab_index >= _tab_container.get_tab_count():
		return null

	var tab_control := _tab_container.get_tab_control(_current_tab_index)
	if tab_control and tab_control.has_method("get_table_view"):
		return tab_control.get_table_view() as TableView

	return null
#endregion

#region Cell Input Logic
func _on_table_cell_selected(row: int, column: int) -> void:
	_active_cell = Vector2i(row, column)
	_refresh_cell_input_from_model()


func _get_type_definition_for_column(column: int) -> Dictionary:
	if _schema_manager and _schema_manager.is_schema_loaded():
		var def := _schema_manager.get_type_definition_for_index(column)
		if def and def is Dictionary and not def.is_empty():
			return def
	return _data_model.get_column_type_definition(column) if _data_model else {}


func _refresh_cell_input_from_model() -> void:
	if not _data_model or _active_cell.x < 0 or _active_cell.y < 0:
		_update_cell_input_ui()
		return

	var header := _data_model.get_header()
	var col_name := header[_active_cell.y] if _active_cell.y >= 0 and _active_cell.y < header.size() else ("Col " + str(_active_cell.y))
	_cell_pos_label.text = "R%s C%s (%s)" % [str(_active_cell.x + 1), str(_active_cell.y + 1), col_name]

	var type_def := _get_type_definition_for_column(_active_cell.y)
	var t := str(type_def.get("type", "string")).strip_edges()
	_cell_type_label.text = "类型: %s" % (t if not t.is_empty() else "string")

	var current := _data_model.get_cell_value(_active_cell.x, _active_cell.y)

	_suppress_cell_input_callbacks = true

	_cell_input_line.visible = true
	_cell_input_text.visible = false
	_cell_input_number.visible = false
	_cell_input_bool.visible = false
	_cell_input_enum.visible = false
	_cell_input_vec_container.visible = false
	_cell_input_color.visible = false
	_cell_input_array_btn.visible = false
	_cell_input_resource_btn.visible = false

	var t_lower := t.to_lower()

	# 检查是否是多值类型（包括 vector2, vector3 和新增的类型）
	var is_multi_value := false
	var component_count := 0
	var is_integer := false
	var component_labels: Array = []

	if t_lower == "vector2":
		is_multi_value = true
		component_count = 2
		is_integer = false
		component_labels = ["X", "Y"]
	elif t_lower == "vector3":
		is_multi_value = true
		component_count = 3
		is_integer = false
		component_labels = ["X", "Y", "Z"]
	elif MULTI_VALUE_TYPE_CONFIG.has(t_lower):
		is_multi_value = true
		var config: Array = MULTI_VALUE_TYPE_CONFIG[t_lower]
		component_count = config[0]
		is_integer = config[1]
		component_labels = config[2]

	if is_multi_value:
		_cell_input_line.visible = false
		_cell_input_vec_container.visible = true

		# 设置 SpinBox 的可见性和步长
		for i in range(_cell_input_vec_spins.size()):
			var spin := _cell_input_vec_spins[i]
			var label := _cell_input_vec_labels[i]

			if i < component_count:
				label.visible = true
				label.text = component_labels[i] if i < component_labels.size() else str(i)
				spin.visible = true
				spin.step = 1.0 if is_integer else 0.01
			else:
				label.visible = false
				spin.visible = false

		# 解析并设置值
		var values := _parse_number_list(str(current))
		while values.size() < component_count:
			values.append(0.0)

		for i in range(min(component_count, _cell_input_vec_spins.size())):
			_cell_input_vec_spins[i].value = float(values[i])

		_suppress_cell_input_callbacks = false
		_update_cell_input_ui()
		return

	# 非多值类型的处理
	match t_lower:
		"string", "json":
			_cell_input_line.visible = false
			_cell_input_text.visible = true
			_cell_input_text.text = str(current)
		"resource", "texture2d", "texture", "packedscene", "shader", "material", "audiostream", "font", "theme":
			_cell_input_line.visible = true
			_cell_input_line.editable = false
			_cell_input_line.text = str(current)
			_cell_input_line.placeholder_text = "点击右侧按钮选择资源..."
			_cell_input_resource_btn.visible = true
		"int":
			_cell_input_line.editable = true
			_cell_input_line.visible = false
			_cell_input_number.visible = true
			_cell_input_number_is_int = true
			_cell_input_number.step = 1.0
			var s := str(current).strip_edges()
			if s.is_valid_int():
				_cell_input_number.value = float(s.to_int())
			elif s.is_valid_float():
				_cell_input_number.value = s.to_float()
			else:
				_cell_input_number.value = 0.0
		"float":
			_cell_input_line.visible = false
			_cell_input_number.visible = true
			_cell_input_number_is_int = false
			_cell_input_number.step = 0.01
			var s := str(current).strip_edges()
			_cell_input_number.value = s.to_float() if s.is_valid_float() else 0.0
		"bool":
			_cell_input_line.visible = false
			_cell_input_bool.visible = true
			var v := str(current).strip_edges().to_lower()
			_cell_input_bool.button_pressed = v in ["true", "1", "yes", "y"]
		"color":
			_cell_input_line.visible = false
			_cell_input_color.visible = true
			_cell_input_color.color = _parse_color(str(current))
		"enum":
			var enum_values: Array = type_def.get("enum_values", []) as Array
			if not enum_values.is_empty():
				_cell_input_line.visible = false
				_cell_input_enum.visible = true
				_cell_input_enum.clear()
				var selected := 0
				for i in range(enum_values.size()):
					var ev := str(enum_values[i])
					_cell_input_enum.add_item(ev, i)
					if ev == current:
						selected = i
				_cell_input_enum.select(selected)
			else:
				_cell_input_line.text = current
		_:
			# 检查是否是 Array / PackedArray 类型，使用 Array 编辑按钮
			if t_lower.begins_with("array") or t_lower.begins_with("packed"):
				_cell_input_line.visible = false
				_cell_input_array_btn.visible = true
				_array_editor_current_value = str(current)
				var item_count := _count_array_items(_array_editor_current_value)
				_cell_input_array_btn.text = "[%d 个项]" % item_count
			else:
				_cell_input_line.text = current

	_suppress_cell_input_callbacks = false
	_update_cell_input_ui()


func _get_input_raw_text() -> String:
	if _cell_input_bool.visible:
		return "true" if _cell_input_bool.button_pressed else "false"
	if _cell_input_enum.visible:
		return _cell_input_enum.get_item_text(_cell_input_enum.selected) if _cell_input_enum.selected >= 0 else ""
	if _cell_input_text.visible:
		return _cell_input_text.text
	if _cell_input_color.visible:
		return _color_to_hex(_cell_input_color.color)
	if _cell_input_array_btn.visible:
		return _array_editor_current_value
	if _cell_input_vec_container.visible:
		# 收集所有可见的 SpinBox 的值
		var values: PackedStringArray = []
		for i in range(_cell_input_vec_spins.size()):
			var spin := _cell_input_vec_spins[i]
			if spin and spin.visible:
				values.append(str(spin.value))
		return ",".join(values)
	if _cell_input_number.visible:
		return str(int(_cell_input_number.value)) if _cell_input_number_is_int else str(_cell_input_number.value)
	return _cell_input_line.text


func _open_cell_resource_selector() -> void:
	if not _data_model or _active_cell.x < 0 or _active_cell.y < 0:
		return
	if _state_manager and _state_manager.is_file_readonly():
		return

	var type_def := _get_type_definition_for_column(_active_cell.y)
	var data_type := str(type_def.get("type", "resource")).strip_edges().to_lower()

	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.title = "选择资源"
	dialog.access = FileDialog.ACCESS_RESOURCES

	var filters := PackedStringArray()
	match data_type:
		"texture2d", "texture":
			filters.append("*.png, *.jpg, *.jpeg, *.webp ; 图片")
			filters.append("*.svg ; SVG")
		"packedscene":
			filters.append("*.tscn, *.scn ; 场景")
		"shader":
			filters.append("*.gdshader, *.shader ; Shader")
		"audiostream":
			filters.append("*.ogg, *.wav, *.mp3 ; 音频")
		"font":
			filters.append("*.ttf, *.otf, *.woff, *.woff2 ; 字体")
		"resource", "material", "theme":
			filters.append("*.tres, *.res ; 资源")
		_:
			filters.append("*.tres, *.res ; 资源")

	filters.append("*.* ; 所有文件")
	dialog.filters = filters

	# 选择资源后：写入 uid://（能取到时）或 res:// 路径
	dialog.file_selected.connect(func(path: String) -> void:
		var uid_text := ""
		if ResourceLoader.exists(path) and ResourceLoader.has_method("get_resource_uid"):
			var uid_id: int = int(ResourceLoader.get_resource_uid(path))
			if uid_id != 0:
				uid_text=ResourceUID.id_to_text(uid_id)

		var new_value := path
		if uid_text.begins_with("uid://"):
			new_value=uid_text

		_apply_value_to_selected_cells(new_value, true)
		var table_view := _get_active_table_view()
		if table_view:
			table_view.refresh()
		_refresh_cell_input_from_model()

		dialog.hide()
		dialog.queue_free()
	)

	dialog.canceled.connect(func() -> void:
		dialog.hide()
		dialog.queue_free()
	)
	dialog.close_requested.connect(func() -> void:
		dialog.hide()
		dialog.queue_free()
	)

	add_child(dialog)
	dialog.popup_centered()


func _color_to_hex(c: Color) -> String:
	"""将 Color 转换为十六进制字符串"""
	var r := int(c.r * 255.0)
	var g := int(c.g * 255.0)
	var b := int(c.b * 255.0)
	var a := int(c.a * 255.0)
	if a < 255:
		return "#%02x%02x%02x%02x" % [r, g, b, a]
	else:
		return "#%02x%02x%02x" % [r, g, b]


func _extract_array_element_type(type_str: String) -> String:
	"""从 Array 类型字符串中提取元素类型，如 Array[int] -> int"""
	var regex := RegEx.new()
	regex.compile("Array\\[([^\\]]+)\\]")
	var result := regex.search(type_str)
	if result:
		return result.get_string(1).strip_edges()
	return "string"


func _get_packed_array_element_type(type_str_lower: String) -> String:
	"""从 PackedArray 类型推导元素类型。

	PackedArray 的元素类型是固定的，因此编辑器不应允许逐元素选择类型。
	"""
	match type_str_lower:
		"packedbytearray":
			return "int"
		"packedint32array", "packedint64array":
			return "int"
		"packedfloat32array", "packedfloat64array":
			return "float"
		"packedstringarray":
			return "string"
		"packedvector2array":
			return "vector2"
		"packedvector3array":
			return "vector3"
		"packedcolorarray":
			return "color"
		_:
			# 兜底：按字符串处理
			return "string"


func _count_array_items(array_str: String) -> int:
	"""计算数组字符串中的项数"""
	var cleaned := array_str.strip_edges()
	if cleaned.is_empty() or cleaned == "[]":
		return 0

	# 尝试解析为 JSON
	var json := JSON.new()
	var error := json.parse(cleaned)
	if error == OK:
		var data = json.data
		if data is Array:
			return data.size()

	# 如果不是有效的 JSON，尝试简单的逗号分隔计数
	if cleaned.begins_with("[") and cleaned.ends_with("]"):
		var content := cleaned.substr(1, cleaned.length() - 2).strip_edges()
		if content.is_empty():
			return 0
		return content.split(",").size()

	return 0


func _open_array_editor() -> void:
	"""打开 Array 编辑弹窗"""
	if not _array_editor_dialog:
		_create_array_editor_dialog()

	var element_type := ""
	var is_packed := false
	if _active_cell.y >= 0:
		var type_def := _get_type_definition_for_column(_active_cell.y)
		var t := str(type_def.get("type", "string")).strip_edges().to_lower()
		is_packed = t.begins_with("packed")
		if is_packed:
			element_type = _get_packed_array_element_type(t)

	# 更新标题（PackedArray 显示元素类型）
	_array_editor_dialog.title = "编辑数组"
	if is_packed:
		_array_editor_dialog.title = "编辑 PackedArray (%s)" % element_type

	# 解析当前数组值（PackedArray 强制元素类型，不允许逐元素选类型）
	_populate_array_editor(_array_editor_current_value, element_type)

	# 显示弹窗（使用固定尺寸，不使用 ratio）
	_array_editor_dialog.popup_centered()


func _create_array_editor_dialog() -> void:
	"""创建 Array 编辑弹窗（Godot Inspector 风格）"""
	_array_editor_dialog = AcceptDialog.new()
	_array_editor_dialog.title = "编辑数组"
	_array_editor_dialog.size = Vector2i(650, 750) # 加宽弹窗（650x750）
	_array_editor_dialog.min_size = Vector2i(600, 650)
	_array_editor_dialog.ok_button_text = "确定"
	_array_editor_dialog.confirmed.connect(_on_array_editor_ok)
	_array_editor_dialog.canceled.connect(_on_array_editor_cancel)
	_array_editor_dialog.close_requested.connect(_on_array_editor_cancel)
	add_child(_array_editor_dialog)

	# 主容器（带外边距）
	var margin_container := MarginContainer.new()
	margin_container.custom_minimum_size = Vector2(630, 730)
	margin_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin_container.add_theme_constant_override("margin_left", 12)
	margin_container.add_theme_constant_override("margin_right", 12)
	margin_container.add_theme_constant_override("margin_top", 12)
	margin_container.add_theme_constant_override("margin_bottom", 12)
	_array_editor_dialog.add_child(margin_container)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin_container.add_child(main_vbox)

	# 标题行（Godot 风格：带背景的工具栏）
	var title_panel := PanelContainer.new()
	var title_stylebox := StyleBoxFlat.new()
	title_stylebox.bg_color = Color(0.24, 0.24, 0.26, 1.0) # Godot 工具栏颜色
	title_stylebox.set_content_margin_all(8)
	title_stylebox.corner_radius_top_left = 4
	title_stylebox.corner_radius_top_right = 4
	title_panel.add_theme_stylebox_override("panel", title_stylebox)
	main_vbox.add_child(title_panel)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 12)
	title_panel.add_child(title_row)

	# Size 标签（Godot 风格：加粗、蓝色调）
	var size_label := Label.new()
	size_label.text = "Size: 0"
	size_label.set_meta("is_size_label", true)
	size_label.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0, 1.0))
	size_label.add_theme_font_size_override("font_size", 14)
	title_row.add_child(size_label)

	title_row.add_child(Control.new()) # Spacer
	title_row.get_child(-1).size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 添加按钮（使用 Godot 图标）
	var add_btn := Button.new()
	add_btn.text = "添加元素"
	add_btn.icon = get_theme_icon("Add", "EditorIcons")
	add_btn.tooltip_text = "在数组末尾添加新元素"
	add_btn.pressed.connect(_on_array_editor_add_element)
	title_row.add_child(add_btn)

	# 元素区域背景面板
	var elements_panel := PanelContainer.new()
	elements_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var elements_stylebox := StyleBoxFlat.new()
	elements_stylebox.bg_color = Color(0.2, 0.2, 0.22, 1.0) # 深色背景
	elements_stylebox.border_width_left = 1
	elements_stylebox.border_width_right = 1
	elements_stylebox.border_width_top = 1
	elements_stylebox.border_width_bottom = 1
	elements_stylebox.border_color = Color(0.35, 0.35, 0.35, 0.6) # 边框
	elements_stylebox.corner_radius_bottom_left = 4
	elements_stylebox.corner_radius_bottom_right = 4
	elements_stylebox.set_content_margin_all(8)
	elements_panel.add_theme_stylebox_override("panel", elements_stylebox)
	main_vbox.add_child(elements_panel)

	# 滚动容器（带边框）
	_array_editor_scroll = ScrollContainer.new()
	_array_editor_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_array_editor_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	elements_panel.add_child(_array_editor_scroll)

	# 元素容器
	_array_editor_vbox = VBoxContainer.new()
	_array_editor_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_array_editor_vbox.add_theme_constant_override("separation", 3) # 紧凑间距
	_array_editor_scroll.add_child(_array_editor_vbox)


func _populate_array_editor(array_str: String, forced_element_type: String = "") -> void:
	"""填充 Array 编辑器的内容（Godot Inspector 风格）"""
	if not _array_editor_vbox:
		return

	# 清空现有元素
	for child in _array_editor_vbox.get_children():
		child.queue_free()
	_array_editor_items.clear()

	var cleaned := array_str.strip_edges()
	if cleaned.is_empty() or cleaned == "[]":
		_update_array_size_label()
		return

	# 尝试解析为 JSON
	var json := JSON.new()
	var error := json.parse(cleaned)
	if error == OK:
		var data = json.data
		if data is Array:
			for item in data:
				# PackedArray：元素类型固定，不允许逐元素选类型
				if not forced_element_type.is_empty():
					_add_array_element_row(forced_element_type, str(item), forced_element_type)
					continue

				# Array：允许逐元素选类型（兼容旧数据）
				# 检查是否是新格式（带类型信息）：{value: xxx, type: xxx}
				if item is Dictionary and item.has("value") and item.has("type"):
					_add_array_element_row(str(item["type"]), str(item["value"]))
				else:
					_add_array_element_row(_infer_type_from_value(item), str(item))

	_update_array_size_label()

	# 强制刷新布局（延迟一帧执行，确保布局计算完成）
	call_deferred("_force_layout_update")


func _infer_type_from_value(value: Variant) -> String:
	"""从值推断类型"""
	match typeof(value):
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "string"
		TYPE_VECTOR2: return "vector2"
		TYPE_VECTOR3: return "vector3"
		TYPE_COLOR: return "color"
		TYPE_ARRAY: return "array"
		_: return "string"


func _add_array_element_row(element_type: String = "string", element_value: String = "", forced_element_type: String = "") -> void:
	"""添加一个数组元素行（智能布局：简单类型一行，复杂类型换行）"""
	# 判断是否需要换行（复杂类型：4个输入框或6个输入框）
	var type_lower := element_type.to_lower()
	var needs_wrap := type_lower in ["vector4", "vector4i", "rect2", "rect2i", "quaternion", "plane", "transform2d"]

	# 创建带背景的面板容器
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN # 允许垂直方向自动调整大小
	# 为复杂类型设置足够的最小高度
	if needs_wrap:
		panel.custom_minimum_size.y = 75 # 复杂类型最小高度 75px（减少一半）
	_array_editor_vbox.add_child(panel)

	# 延迟刷新布局（确保元素添加后布局正确）
	call_deferred("_force_layout_update")

	# 添加内边距容器
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	margin.size_flags_vertical = Control.SIZE_SHRINK_BEGIN # 允许垂直方向自动调整大小
	panel.add_child(margin)

	# 统一使用水平布局（所有类型都在一行）
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN # 允许垂直方向自动调整大小
	margin.add_child(row)

	# 索引标签（Godot 风格：灰色、右对齐，固定宽度）
	var index_label := Label.new()
	index_label.text = str(_array_editor_items.size())
	index_label.custom_minimum_size.x = 24
	index_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN # 固定大小，不扩展
	index_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	index_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1.0))
	row.add_child(index_label)

	# 类型选择器（固定宽度）
	var type_selector := OptionButton.new()
	type_selector.custom_minimum_size.x = 120
	type_selector.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN # 固定大小，不扩展
	type_selector.add_item("String", 0)
	type_selector.add_item("Int", 1)
	type_selector.add_item("Float", 2)
	type_selector.add_item("Bool", 3)
	type_selector.add_item("Vector2", 4)
	type_selector.add_item("Vector2i", 5)
	type_selector.add_item("Vector3", 6)
	type_selector.add_item("Vector3i", 7)
	type_selector.add_item("Vector4", 8)
	type_selector.add_item("Vector4i", 9)
	type_selector.add_item("Rect2", 10)
	type_selector.add_item("Rect2i", 11)
	type_selector.add_item("Color", 12)
	type_selector.add_item("Quaternion", 13)
	type_selector.add_item("Plane", 14)
	type_selector.add_item("Transform2D", 15)

	# PackedArray：类型固定，不允许选择类型
	if not forced_element_type.is_empty():
		type_selector.disabled = true
		type_selector.visible = false

	# 设置当前类型
	match element_type.to_lower():
		"int": type_selector.selected = 1
		"float": type_selector.selected = 2
		"bool": type_selector.selected = 3
		"vector2": type_selector.selected = 4
		"vector2i": type_selector.selected = 5
		"vector3": type_selector.selected = 6
		"vector3i": type_selector.selected = 7
		"vector4": type_selector.selected = 8
		"vector4i": type_selector.selected = 9
		"rect2": type_selector.selected = 10
		"rect2i": type_selector.selected = 11
		"color": type_selector.selected = 12
		"quaternion": type_selector.selected = 13
		"plane": type_selector.selected = 14
		"transform2d": type_selector.selected = 15
		_: type_selector.selected = 0

	row.add_child(type_selector)

	# 输入框容器（填满中间剩余空间）
	# 注意：这里不要用 MarginContainer。MarginContainer 的最小尺寸/缓存行为在“删子节点+重建”时
	# 容易导致 HBoxContainer 的剩余宽度分配不稳定，表现为 value 区域无法横向铺满。
	var value_container := PanelContainer.new()
	value_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_container.size_flags_vertical = Control.SIZE_FILL
	value_container.custom_minimum_size.y = 28
	# 用一个透明 StyleBox，避免 PanelContainer 默认样式影响观感
	var _value_bg := StyleBoxEmpty.new()
	value_container.add_theme_stylebox_override("panel", _value_bg)
	row.add_child(value_container)

	# 删除按钮（固定宽度）
	var delete_btn := Button.new()
	delete_btn.icon = get_theme_icon("Remove", "EditorIcons")
	delete_btn.custom_minimum_size = Vector2(32, 28)
	delete_btn.size_flags_horizontal = Control.SIZE_SHRINK_END # 固定大小，不扩展
	delete_btn.tooltip_text = "删除此元素"
	row.add_child(delete_btn)

	# 存储元素数据
	var element_data := {
		"type": element_type,
		"value": element_value,
		"forced_type": forced_element_type,
		"panel": panel,
		"type_selector": type_selector,
		"value_container": value_container,
		"delete_btn": delete_btn,
		"index_label": index_label
	}
	_array_editor_items.append(element_data)

	# 创建值编辑器
	_create_value_editor_for_element(element_data)

	# 连接信号（使用 element_data 引用而不是索引，避免删除元素后索引错乱）
	if forced_element_type.is_empty():
		type_selector.item_selected.connect(_on_element_type_changed.bind(element_data))
	delete_btn.pressed.connect(_on_element_delete.bind(element_data))


func _create_value_editor_for_element(element_data: Dictionary) -> void:
	"""为元素创建值编辑器（智能布局：输入框容器内部可能换行）"""
	var value_container: Control = element_data["value_container"]

	# 清空容器（立即删除，不使用 queue_free）
	for child in value_container.get_children():
		value_container.remove_child(child)
		child.free() # 立即释放，而不是 queue_free

	# 重置容器属性：让元素编辑区始终占满这一行的剩余空间
	value_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_container.size_flags_vertical = Control.SIZE_FILL
	# 注意：这里不要固定 X 方向最小宽度，否则在 ScrollContainer/VBoxContainer 的最小尺寸计算里
	# 可能导致 value 区域只满足最小值而不随视口横向铺满。
	value_container.custom_minimum_size.x = 0
	value_container.update_minimum_size()

	var element_type: String = element_data["type"]
	var element_value: String = element_data["value"]

	match element_type.to_lower():
		"string":
			var line_edit := LineEdit.new()
			line_edit.text = element_value
			line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
			value_container.add_child(line_edit)
			element_data["editor"] = line_edit

		"int":
			var spin_box := SpinBox.new()
			spin_box.step = 1.0
			spin_box.allow_greater = true
			spin_box.allow_lesser = true
			spin_box.value = element_value.to_int() if element_value.is_valid_int() else 0
			spin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			spin_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
			value_container.add_child(spin_box)
			element_data["editor"] = spin_box

		"float":
			var spin_box := SpinBox.new()
			spin_box.step = 0.01
			spin_box.allow_greater = true
			spin_box.allow_lesser = true
			spin_box.value = element_value.to_float() if element_value.is_valid_float() else 0.0
			spin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			spin_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
			value_container.add_child(spin_box)
			element_data["editor"] = spin_box

		"bool":
			var check_box := CheckBox.new()
			check_box.button_pressed = element_value.to_lower() in ["true", "1", "yes"]
			check_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			check_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
			value_container.add_child(check_box)
			element_data["editor"] = check_box

		"vector2", "vector2i":
			var hbox := HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 4)
			hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			hbox.custom_minimum_size.y = 28 # 设置最小高度，确保输入框可见
			value_container.add_child(hbox)

			var values := _parse_number_list(element_value)
			while values.size() < 2:
				values.append(0.0)

			var is_int := element_type.to_lower() == "vector2i"
			for i in range(2):
				var label := Label.new()
				label.text = ["X", "Y"][i]
				label.custom_minimum_size.x = 12
				hbox.add_child(label)

				var spin := SpinBox.new()
				spin.step = 1.0 if is_int else 0.01
				spin.allow_greater = true
				spin.allow_lesser = true
				spin.value = values[i]
				spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				hbox.add_child(spin)

			element_data["editor"] = hbox

		"vector3", "vector3i":
			var hbox := HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 4)
			hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			hbox.custom_minimum_size.y = 28 # 设置最小高度，确保输入框可见
			value_container.add_child(hbox)

			var values := _parse_number_list(element_value)
			while values.size() < 3:
				values.append(0.0)

			var is_int := element_type.to_lower() == "vector3i"
			for i in range(3):
				var label := Label.new()
				label.text = ["X", "Y", "Z"][i]
				label.custom_minimum_size.x = 12
				hbox.add_child(label)

				var spin := SpinBox.new()
				spin.step = 1.0 if is_int else 0.01
				spin.allow_greater = true
				spin.allow_lesser = true
				spin.value = values[i]
				spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				hbox.add_child(spin)

			element_data["editor"] = hbox

		"vector4", "vector4i":
			# 输入框容器内部使用 VBoxContainer 换行（两行布局）
			var vbox := VBoxContainer.new()
			vbox.add_theme_constant_override("separation", 4)
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			value_container.add_child(vbox)

			var values := _parse_number_list(element_value)
			while values.size() < 4:
				values.append(0.0)

			var is_int := element_type.to_lower() == "vector4i"
			var labels := ["X", "Y", "Z", "W"]

			# 第一行：X, Y
			var row1 := HBoxContainer.new()
			row1.add_theme_constant_override("separation", 4)
			row1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row1.custom_minimum_size.y = 28
			vbox.add_child(row1)

			for i in range(2):
				var label := Label.new()
				label.text = labels[i]
				label.custom_minimum_size.x = 12
				row1.add_child(label)

				var spin := SpinBox.new()
				spin.step = 1.0 if is_int else 0.01
				spin.allow_greater = true
				spin.allow_lesser = true
				spin.value = values[i]
				spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row1.add_child(spin)

			# 第二行：Z, W
			var row2 := HBoxContainer.new()
			row2.add_theme_constant_override("separation", 4)
			row2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row2.custom_minimum_size.y = 28
			vbox.add_child(row2)

			for i in range(2, 4):
				var label := Label.new()
				label.text = labels[i]
				label.custom_minimum_size.x = 12
				row2.add_child(label)

				var spin := SpinBox.new()
				spin.step = 1.0 if is_int else 0.01
				spin.allow_greater = true
				spin.allow_lesser = true
				spin.value = values[i]
				spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row2.add_child(spin)

			element_data["editor"] = vbox

		"rect2", "rect2i":
			# 输入框容器内部使用 VBoxContainer 换行（两行布局）
			var vbox := VBoxContainer.new()
			vbox.add_theme_constant_override("separation", 4)
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			value_container.add_child(vbox)

			var values := _parse_number_list(element_value)
			while values.size() < 4:
				values.append(0.0)

			var is_int := element_type.to_lower() == "rect2i"
			var labels := ["X", "Y", "W", "H"]

			# 第一行：X, Y
			var row1 := HBoxContainer.new()
			row1.add_theme_constant_override("separation", 4)
			row1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row1.custom_minimum_size.y = 28
			vbox.add_child(row1)

			for i in range(2):
				var label := Label.new()
				label.text = labels[i]
				label.custom_minimum_size.x = 12
				row1.add_child(label)

				var spin := SpinBox.new()
				spin.step = 1.0 if is_int else 0.01
				spin.allow_greater = true
				spin.allow_lesser = true
				spin.value = values[i]
				spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row1.add_child(spin)

			# 第二行：W, H
			var row2 := HBoxContainer.new()
			row2.add_theme_constant_override("separation", 4)
			row2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row2.custom_minimum_size.y = 28
			vbox.add_child(row2)

			for i in range(2, 4):
				var label := Label.new()
				label.text = labels[i]
				label.custom_minimum_size.x = 12
				row2.add_child(label)

				var spin := SpinBox.new()
				spin.step = 1.0 if is_int else 0.01
				spin.allow_greater = true
				spin.allow_lesser = true
				spin.value = values[i]
				spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row2.add_child(spin)

			element_data["editor"] = vbox

		"quaternion":
			# 输入框容器内部使用 VBoxContainer 换行（两行布局）
			var vbox := VBoxContainer.new()
			vbox.add_theme_constant_override("separation", 4)
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			value_container.add_child(vbox)

			var values := _parse_number_list(element_value)
			while values.size() < 4:
				values.append(0.0)

			var labels := ["X", "Y", "Z", "W"]

			# 第一行：X, Y
			var row1 := HBoxContainer.new()
			row1.add_theme_constant_override("separation", 4)
			row1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row1.custom_minimum_size.y = 28
			vbox.add_child(row1)

			for i in range(2):
				var label := Label.new()
				label.text = labels[i]
				label.custom_minimum_size.x = 12
				row1.add_child(label)

				var spin := SpinBox.new()
				spin.step = 0.01
				spin.allow_greater = true
				spin.allow_lesser = true
				spin.value = values[i]
				spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row1.add_child(spin)

			# 第二行：Z, W
			var row2 := HBoxContainer.new()
			row2.add_theme_constant_override("separation", 4)
			row2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row2.custom_minimum_size.y = 28
			vbox.add_child(row2)

			for i in range(2, 4):
				var label := Label.new()
				label.text = labels[i]
				label.custom_minimum_size.x = 12
				row2.add_child(label)

				var spin := SpinBox.new()
				spin.step = 0.01
				spin.allow_greater = true
				spin.allow_lesser = true
				spin.value = values[i]
				spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row2.add_child(spin)

			element_data["editor"] = vbox

		"plane":
			# 输入框容器内部使用 VBoxContainer 换行（两行布局）
			var vbox := VBoxContainer.new()
			vbox.add_theme_constant_override("separation", 4)
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			value_container.add_child(vbox)

			var values := _parse_number_list(element_value)
			while values.size() < 4:
				values.append(0.0)

			var labels := ["A", "B", "C", "D"]

			# 第一行：A, B
			var row1 := HBoxContainer.new()
			row1.add_theme_constant_override("separation", 4)
			row1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row1.custom_minimum_size.y = 28
			vbox.add_child(row1)

			for i in range(2):
				var label := Label.new()
				label.text = labels[i]
				label.custom_minimum_size.x = 12
				row1.add_child(label)

				var spin := SpinBox.new()
				spin.step = 0.01
				spin.allow_greater = true
				spin.allow_lesser = true
				spin.value = values[i]
				spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row1.add_child(spin)

			# 第二行：C, D
			var row2 := HBoxContainer.new()
			row2.add_theme_constant_override("separation", 4)
			row2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row2.custom_minimum_size.y = 28
			vbox.add_child(row2)

			for i in range(2, 4):
				var label := Label.new()
				label.text = labels[i]
				label.custom_minimum_size.x = 12
				row2.add_child(label)

				var spin := SpinBox.new()
				spin.step = 0.01
				spin.allow_greater = true
				spin.allow_lesser = true
				spin.value = values[i]
				spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row2.add_child(spin)

			element_data["editor"] = vbox

		"transform2d":
			# 输入框容器内部使用 VBoxContainer 换行（两行布局）
			var vbox := VBoxContainer.new()
			vbox.add_theme_constant_override("separation", 4)
			vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
			value_container.add_child(vbox)

			var values := _parse_number_list(element_value)
			while values.size() < 6:
				values.append(0.0)

			# Transform2D 有 6 个值，分两行显示
			# 第一行：x.x, x.y, y.x
			# 第二行：y.y, origin.x, origin.y
			var labels := [
				["x.x", "x.y", "y.x"],
				["y.y", "o.x", "o.y"]
			]

			# 第一行：x.x, x.y, y.x
			var row1 := HBoxContainer.new()
			row1.add_theme_constant_override("separation", 4)
			row1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row1.custom_minimum_size.y = 28
			vbox.add_child(row1)

			for col_idx in range(3):
				var idx := col_idx
				var label := Label.new()
				label.text = labels[0][col_idx]
				label.custom_minimum_size.x = 24 # 增加标签宽度以容纳 "o.x" 等文本
				row1.add_child(label)

				var spin := SpinBox.new()
				spin.step = 0.01
				spin.allow_greater = true
				spin.allow_lesser = true
				spin.value = values[idx]
				spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row1.add_child(spin)

			# 第二行：y.y, o.x, o.y
			var row2 := HBoxContainer.new()
			row2.add_theme_constant_override("separation", 4)
			row2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row2.custom_minimum_size.y = 28
			vbox.add_child(row2)

			for col_idx in range(3):
				var idx := 3 + col_idx
				var label := Label.new()
				label.text = labels[1][col_idx]
				label.custom_minimum_size.x = 24 # 增加标签宽度以容纳 "o.x" 等文本
				row2.add_child(label)

				var spin := SpinBox.new()
				spin.step = 0.01
				spin.allow_greater = true
				spin.allow_lesser = true
				spin.value = values[idx]
				spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				row2.add_child(spin)

			element_data["editor"] = vbox

		"color":
			var color_picker := ColorPickerButton.new()
			color_picker.color = _parse_color(element_value)
			color_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			color_picker.size_flags_vertical = Control.SIZE_EXPAND_FILL
			value_container.add_child(color_picker)
			element_data["editor"] = color_picker

		_:
			# 默认使用 LineEdit
			var line_edit := LineEdit.new()
			line_edit.text = element_value
			line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
			value_container.add_child(line_edit)
			element_data["editor"] = line_edit


func _on_array_editor_add_element() -> void:
	"""添加新元素"""
	var element_type := "string"
	var forced_type := ""
	if _active_cell.y >= 0:
		var type_def := _get_type_definition_for_column(_active_cell.y)
		var t := str(type_def.get("type", "string")).strip_edges().to_lower()
		if t.begins_with("packed"):
			forced_type = _get_packed_array_element_type(t)
			element_type = forced_type

	# PackedArray：不使用空字符串作为默认值，直接使用元素类型默认值
	# Array：默认值跟随当前选中的元素类型
	var default_value := _get_default_value_for_type(element_type)
	_add_array_element_row(element_type, default_value, forced_type)
	_update_array_size_label()


func _on_element_type_changed(type_index: int, element_data: Dictionary) -> void:
	"""元素类型改变（注意：type_index 是第一个参数，因为 item_selected 信号传递的是索引）"""
	if not element_data:
		return

	# 更新类型
	match type_index:
		0: element_data["type"] = "string"
		1: element_data["type"] = "int"
		2: element_data["type"] = "float"
		3: element_data["type"] = "bool"
		4: element_data["type"] = "vector2"
		5: element_data["type"] = "vector2i"
		6: element_data["type"] = "vector3"
		7: element_data["type"] = "vector3i"
		8: element_data["type"] = "vector4"
		9: element_data["type"] = "vector4i"
		10: element_data["type"] = "rect2"
		11: element_data["type"] = "rect2i"
		12: element_data["type"] = "color"
		13: element_data["type"] = "quaternion"
		14: element_data["type"] = "plane"
		15: element_data["type"] = "transform2d"
		_: element_data["type"] = "string"

	# 判断类型并设置合适的最小高度
	var type_str: String = element_data["type"]
	var type_lower: String = type_str.to_lower()
	var is_complex: bool = type_lower in ["vector4", "vector4i", "rect2", "rect2i", "quaternion", "plane", "transform2d"]
	var is_multi_value: bool = type_lower in ["vector2", "vector2i", "vector3", "vector3i"]
	var is_simple: bool = type_lower in ["string", "int", "float", "bool", "color"]

	# 动态更新 PanelContainer 的最小高度
	var panel: Control = element_data.get("panel")
	if panel:
		if is_complex:
			panel.custom_minimum_size.y = 75 # 复杂类型最小高度 75px（两行输入框）
		elif is_multi_value:
			panel.custom_minimum_size.y = 40 # 多值类型最小高度 40px（一行多个输入框）
		elif is_simple:
			panel.custom_minimum_size.y = 40 # 简单类型最小高度 40px（一个输入框）
		else:
			panel.custom_minimum_size.y = 0 # 其他类型不设置最小高度

		# 通知布局系统更新最小尺寸（避免手动 reset_size 导致行宽度被错误回推）
		panel.update_minimum_size()

	# 重新创建值编辑器（不需要移动容器，因为所有类型的 value_container 都在第二行）
	_create_value_editor_for_element(element_data)

	# 延迟刷新布局（确保元素切换后布局正确）
	call_deferred("_force_layout_update")
	call_deferred("_refresh_array_element_layout", element_data)
	call_deferred("_force_array_editor_dialog_width")


func _on_element_delete(element_data: Dictionary) -> void:
	"""删除元素"""
	if not element_data:
		return

	# 查找元素在数组中的索引
	var element_index := _array_editor_items.find(element_data)
	if element_index < 0:
		return

	var panel: Control = element_data["panel"]

	# 移除 UI
	panel.queue_free()

	# 移除数据
	_array_editor_items.remove_at(element_index)

	# 更新所有索引标签
	for i in range(_array_editor_items.size()):
		var item_data: Dictionary = _array_editor_items[i]
		var label: Label = item_data["index_label"]
		label.text = str(i)

	_update_array_size_label()


func _update_array_size_label() -> void:
	"""更新数组大小标签"""
	if not _array_editor_dialog:
		return

	# 查找 size_label
	for child in _array_editor_dialog.get_children():
		if child is VBoxContainer:
			for vbox_child in child.get_children():
				if vbox_child is HBoxContainer:
					for hbox_child in vbox_child.get_children():
						if hbox_child is Label and hbox_child.has_meta("is_size_label"):
							hbox_child.text = "Size: %d" % _array_editor_items.size()
							return


func _force_layout_update() -> void:
	"""强制刷新布局。

	避免使用 `reset_size()`：在 ScrollContainer + 大量子节点的场景下，反复 reset 可能导致
	最小尺寸被短暂归零，从而出现“元素全部消失/高度塌陷”的现象。
	"""
	if not _array_editor_vbox:
		return

	# 让各层容器重新排版即可
	for element_data in _array_editor_items:
		var panel: Control = element_data.get("panel")
		if panel:
			panel.update_minimum_size()
			if panel is Container:
				(panel as Container).queue_sort()

	_array_editor_vbox.update_minimum_size()
	_array_editor_vbox.queue_sort()

	if _array_editor_scroll and _array_editor_scroll is Container:
		_array_editor_scroll.update_minimum_size()
		(_array_editor_scroll as Container).queue_sort()

	# AcceptDialog 继承自 Window，不是 Container；这里不做 Container cast。
	# 如需触发布局，优先对内部容器（如 `_array_editor_vbox` / `_array_editor_scroll`）queue_sort。


func _refresh_array_element_layout(element_data: Dictionary) -> void:
	"""在类型切换后强制刷新单个元素行的布局。

	现象：某些类型之间切换时，即使输入框数量相同，`value_container` 仍可能拿不到 HBox 的剩余宽度。
	手动拖动弹窗大小会触发一次完整布局，从而恢复。

	这里做同等效果的“程序化触发”：对该行及其父容器 `queue_sort()`。
	"""
	if not element_data:
		return
	if not _array_editor_vbox:
		return

	var value_container: Control = element_data.get("value_container")
	if value_container:
		value_container.update_minimum_size()

		var row := value_container.get_parent()
		if row is Container:
			(row as Container).queue_sort()

	var panel: Control = element_data.get("panel")
	if panel:
		panel.update_minimum_size()
		if panel is Container:
			(panel as Container).queue_sort()

	_array_editor_vbox.update_minimum_size()
	_array_editor_vbox.queue_sort()

	if _array_editor_scroll and _array_editor_scroll is Container:
		_array_editor_scroll.update_minimum_size()
		(_array_editor_scroll as Container).queue_sort()


func _force_array_editor_dialog_width() -> void:
	"""在类型切换后防止数组弹窗宽度逐步变窄。

	Godot 的容器在移除/重建子控件后，可能会用“当前最小宽度”去反推窗口尺寸，
	导致在输入控件数量相同的类型之间来回切换时，窗口宽度不断收缩。
	"""
	if not _array_editor_dialog:
		return

	# 兜底：不小于创建弹窗时的宽度（如需改默认宽度，建议两处保持一致）
	var min_width := 650

	# 若弹窗当前更宽，保持更宽的值
	min_width = maxi(min_width, int(_array_editor_dialog.size.x))

	_array_editor_dialog.min_size = Vector2i(min_width, int(_array_editor_dialog.min_size.y))
	_array_editor_dialog.size = Vector2i(maxi(min_width, int(_array_editor_dialog.size.x)), int(_array_editor_dialog.size.y))
	_array_editor_dialog.reset_size()
	_array_editor_dialog.update_minimum_size()

	# 触发一次完整布局（效果类似用户手动拖动窗口大小）
	for child in _array_editor_dialog.get_children():
		if child is Container:
			(child as Container).queue_sort()

	if _array_editor_vbox:
		_array_editor_vbox.reset_size()
		_array_editor_vbox.queue_sort()


func _get_element_value(element_data: Dictionary) -> Variant:
	"""获取元素的值"""
	var editor = element_data.get("editor")
	if not editor:
		return ""

	var element_type: String = element_data["type"]

	match element_type.to_lower():
		"string":
			if editor is LineEdit:
				return editor.text
		"int":
			if editor is SpinBox:
				return int(editor.value)
		"float":
			if editor is SpinBox:
				return editor.value
		"bool":
			if editor is CheckBox:
				return editor.button_pressed
		"vector2":
			if editor is HBoxContainer:
				var spins: Array = []
				for child in editor.get_children():
					if child is SpinBox:
						spins.append(child)
				if spins.size() >= 2:
					return Vector2(spins[0].value, spins[1].value)
		"vector2i":
			if editor is HBoxContainer:
				var spins: Array = []
				for child in editor.get_children():
					if child is SpinBox:
						spins.append(child)
				if spins.size() >= 2:
					return Vector2i(int(spins[0].value), int(spins[1].value))
		"vector3":
			if editor is HBoxContainer:
				var spins: Array = []
				for child in editor.get_children():
					if child is SpinBox:
						spins.append(child)
				if spins.size() >= 3:
					return Vector3(spins[0].value, spins[1].value, spins[2].value)
		"vector3i":
			if editor is HBoxContainer:
				var spins: Array = []
				for child in editor.get_children():
					if child is SpinBox:
						spins.append(child)
				if spins.size() >= 3:
					return Vector3i(int(spins[0].value), int(spins[1].value), int(spins[2].value))
		"vector4":
			if editor is VBoxContainer:
				var spins: Array = []
				for row in editor.get_children():
					if row is HBoxContainer:
						for child in row.get_children():
							if child is SpinBox:
								spins.append(child)
				if spins.size() >= 4:
					return Vector4(spins[0].value, spins[1].value, spins[2].value, spins[3].value)
		"vector4i":
			if editor is VBoxContainer:
				var spins: Array = []
				for row in editor.get_children():
					if row is HBoxContainer:
						for child in row.get_children():
							if child is SpinBox:
								spins.append(child)
				if spins.size() >= 4:
					return Vector4i(int(spins[0].value), int(spins[1].value), int(spins[2].value), int(spins[3].value))
		"rect2":
			if editor is VBoxContainer:
				var spins: Array = []
				for row in editor.get_children():
					if row is HBoxContainer:
						for child in row.get_children():
							if child is SpinBox:
								spins.append(child)
				if spins.size() >= 4:
					return Rect2(spins[0].value, spins[1].value, spins[2].value, spins[3].value)
		"rect2i":
			if editor is VBoxContainer:
				var spins: Array = []
				for row in editor.get_children():
					if row is HBoxContainer:
						for child in row.get_children():
							if child is SpinBox:
								spins.append(child)
				if spins.size() >= 4:
					return Rect2i(int(spins[0].value), int(spins[1].value), int(spins[2].value), int(spins[3].value))
		"quaternion":
			if editor is VBoxContainer:
				var spins: Array = []
				for row in editor.get_children():
					if row is HBoxContainer:
						for child in row.get_children():
							if child is SpinBox:
								spins.append(child)
				if spins.size() >= 4:
					return Quaternion(spins[0].value, spins[1].value, spins[2].value, spins[3].value)
		"plane":
			if editor is VBoxContainer:
				var spins: Array = []
				for row in editor.get_children():
					if row is HBoxContainer:
						for child in row.get_children():
							if child is SpinBox:
								spins.append(child)
				if spins.size() >= 4:
					return Plane(spins[0].value, spins[1].value, spins[2].value, spins[3].value)
		"transform2d":
			if editor is VBoxContainer:
				var spins: Array = []
				for row in editor.get_children():
					if row is HBoxContainer:
						for child in row.get_children():
							if child is SpinBox:
								spins.append(child)
				if spins.size() >= 6:
					return Transform2D(
						Vector2(spins[0].value, spins[1].value),
						Vector2(spins[3].value, spins[4].value),
						Vector2(spins[2].value, spins[5].value)
					)
		"color":
			if editor is ColorPickerButton:
				return editor.color

	return ""


func _on_array_editor_ok() -> void:
	"""确定按钮 - 保存数组数据"""
	var is_packed := false
	if _active_cell.y >= 0:
		var type_def := _get_type_definition_for_column(_active_cell.y)
		var t := str(type_def.get("type", "string")).strip_edges().to_lower()
		is_packed = t.begins_with("packed")

	var items: Array = []
	for element_data in _array_editor_items:
		var value = _get_element_value(element_data)
		var type_str = element_data["type"]

		if is_packed:
			# PackedArray：仅保存值数组
			items.append(value)
		else:
			# Array：保存为带类型注解的格式：{value: xxx, type: xxx}
			items.append({
				"value": value,
				"type": type_str
			})

	# 转换为 JSON 字符串
	_array_editor_current_value = JSON.stringify(items)

	# 更新按钮文本
	_cell_input_array_btn.text = "[%d 个项]" % items.size()

	# 应用到单元格
	_apply_cell_input_value()

	# 关闭弹窗
	_array_editor_dialog.hide()


func _on_array_editor_cancel() -> void:
	"""取消按钮 - 关闭弹窗"""
	_array_editor_dialog.hide()


func _get_default_value_for_type(type_str: String) -> String:
	"""获取类型的默认值（用于 Array / PackedArray 的“添加元素”）"""
	match type_str.to_lower():
		"int":
			return "0"
		"float":
			return "0.0"
		"bool":
			return "false"
		"string":
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


func _prompt_for_value(title: String, current_value: String, type_str: String, callback: Callable) -> void:
	"""弹出输入对话框，通过回调返回用户输入的值"""
	# 创建简单的输入对话框
	var dialog := AcceptDialog.new()
	dialog.title = title
	dialog.size = Vector2i(400, 150)
	add_child(dialog)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(380, 100)
	dialog.add_child(vbox)

	var label := Label.new()
	label.text = "请输入值（类型: %s）:" % type_str
	vbox.add_child(label)

	var line_edit := LineEdit.new()
	line_edit.text = current_value
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(line_edit)

	# 确认回调
	dialog.confirmed.connect(func() -> void:
		callback.call(line_edit.text)
		dialog.queue_free()
	)

	# 取消回调
	dialog.canceled.connect(func() -> void:
		dialog.queue_free()
	)

	dialog.popup_centered()


func _apply_cell_default_value() -> void:
	if not _data_model or _active_cell.x < 0 or _active_cell.y < 0:
		return
	var type_def := _get_type_definition_for_column(_active_cell.y)
	var default_value := _data_model.get_effective_default_string(type_def)
	_apply_value_to_selected_cells(default_value, true)


func _apply_cell_input_value() -> void:
	if not _data_model:
		return
	if _suppress_cell_input_callbacks:
		return
	var raw := _get_input_raw_text()
	_apply_value_to_selected_cells(raw, false)


func _apply_value_to_selected_cells(raw_value: String, is_already_converted: bool) -> void:
	var table_view := _get_active_table_view()
	if not table_view:
		return
	if _state_manager and _state_manager.is_file_readonly():
		return

	var cells := table_view.get_selected_cells() if table_view.has_method("get_selected_cells") else []
	if cells.is_empty():
		if _active_cell.x >= 0 and _active_cell.y >= 0:
			cells = [_active_cell]
		else:
			return

	var on_failure := "default"
	var empty_policy := "use_default"
	if _config_manager:
		on_failure = str(_config_manager.get_type_change_failure_policy()).strip_edges()
		empty_policy = str(_config_manager.get_type_change_empty_policy()).strip_edges()

	var changes: Array = []
	for cell: Vector2i in cells:
		if not _data_model.is_valid_index(cell.x, cell.y):
			continue

		var type_def := _get_type_definition_for_column(cell.y)
		var default_value := _data_model.get_effective_default_string(type_def)
		var type_name := str(type_def.get("type", "string")).strip_edges().to_lower()

		var value := str(raw_value)
		var empty_check := value.strip_edges()
		var is_packed_array := type_name.begins_with("packed")
		if empty_check.is_empty() and not is_packed_array:
			if empty_policy == "use_default":
				value = default_value
			else:
				value = ""
		elif not is_already_converted:
			var convert_input := value if type_name in ["string", "json"] else value.strip_edges()
			var converted := _data_model.try_convert_string_to_type_string(convert_input, type_def)
			if converted.get("ok", false):
				value = str(converted.get("value", ""))
			else:
				if on_failure == "default":
					value = default_value
				else:
					value = str(raw_value)

		changes.append({"row": cell.x, "column": cell.y, "value": value})

	if not changes.is_empty():
		_data_model.batch_set_cells(changes)

	# 输入区实时写回时不要立刻刷新 UI：
	# - TextEdit/LineEdit 会因为重设 text 导致焦点丢失
	# - SpinBox 频繁刷新可能导致拖拽/点击状态异常（表现为“鼠标被吞”）
	if _cell_input_live_applying:
		var focus_owner := get_viewport().gui_get_focus_owner()
		if focus_owner and _cell_input_panel and _cell_input_panel.is_ancestor_of(focus_owner):
			return

	_refresh_cell_input_from_model()
#endregion


func _schedule_apply_cell_input() -> void:
	if _suppress_cell_input_callbacks:
		return
	if not _cell_input_debounce_timer:
		return
	if _state_manager and _state_manager.is_file_readonly():
		return
	if _active_cell.x < 0 or _active_cell.y < 0:
		return

	# Timer/面板未进树时不要 start，避免报错。
	if not _cell_input_panel or not _cell_input_panel.is_inside_tree():
		return
	if not _cell_input_debounce_timer.is_inside_tree():
		return

	_cell_input_debounce_timer.start()


func _parse_number_list(text: String) -> Array[float]:
	var cleaned := str(text).strip_edges()
	if cleaned.is_empty():
		return []
	var regex := RegEx.new()
	regex.compile("[-+]?\\d*\\.?\\d+(?:[eE][-+]?\\d+)?")
	var out: Array[float] = []
	for m in regex.search_all(cleaned):
		var s := m.get_string()
		if s.is_valid_float():
			out.append(s.to_float())
	return out


func _parse_color(text: String) -> Color:
	"""解析颜色字符串，支持多种格式"""
	var cleaned := str(text).strip_edges()
	if cleaned.is_empty():
		return Color(1, 1, 1, 1)

	# 尝试十六进制格式（#RRGGBB 或 #RRGGBBAA）
	if cleaned.begins_with("#"):
		var hex := cleaned.substr(1)
		if hex.is_valid_html_color():
			return Color.html(cleaned)

	# 尝试命名颜色（如 "red", "blue"）
	if cleaned.is_valid_html_color():
		return Color.html(cleaned)

	# 尝试数字列表格式（r,g,b 或 r,g,b,a）
	var values := _parse_number_list(cleaned)
	if values.size() >= 3:
		var r := clampf(values[0], 0.0, 1.0)
		var g := clampf(values[1], 0.0, 1.0)
		var b := clampf(values[2], 0.0, 1.0)
		var a := clampf(values[3], 0.0, 1.0) if values.size() >= 4 else 1.0
		return Color(r, g, b, a)

	# 默认返回白色
	return Color(1, 1, 1, 1)

#region 编辑功能 Editing Features
## 进入编辑模式
func _enter_edit_mode() -> void:
	if not _data_model:
		return

	# TODO: 实现进入编辑模式
	print("进入编辑模式")
#endregion

#region 错误处理功能 Error Handling Features
## 错误发生时的处理
func _on_error_occurred(error_data: Dictionary) -> void:
	print("错误发生: ", error_data.message)
	# TODO: 显示错误对话框或状态栏提示


## 警告发生时的处理
func _on_warning_occurred(warning_data: Dictionary) -> void:
	print("警告: ", warning_data.message)
	# TODO: 显示警告对话框或状态栏提示
#endregion

#region 配置管理功能 Config Management Features
## 配置变化时的处理
func _on_config_changed(config_key: String) -> void:
	print("配置变化: ", config_key)

	# 根据配置键应用相应的变化
	match config_key:
		ConfigManager.KEY_THEME:
			_apply_theme_settings()
		ConfigManager.KEY_AUTO_SAVE_INTERVAL:
			_apply_auto_save_settings()
		ConfigManager.KEY_SHOW_ROW_NUMBERS:
			_apply_row_numbers_settings()
		ConfigManager.KEY_ENABLE_VIRTUAL_SCROLL:
			_apply_virtual_scroll_settings()
		ConfigManager.KEY_CELL_TEXT_OVERFLOW:
			_apply_text_overflow_settings()


## 配置加载完成
func _on_config_loaded() -> void:
	print("配置加载完成")
	_apply_all_settings()


## 配置保存完成
func _on_config_saved() -> void:
	print("配置保存完成")


## 应用所有配置设置
func _apply_all_settings() -> void:
	_apply_theme_settings()
	_apply_auto_save_settings()
	_apply_row_numbers_settings()
	_apply_virtual_scroll_settings()
	_apply_text_overflow_settings()


## 应用主题设置
func _apply_theme_settings() -> void:
	if _ui_style_manager:
		_ui_style_manager.set_theme(_config_manager.get_theme())


## 应用自动保存设置
func _apply_auto_save_settings() -> void:
	if _state_manager and _config_manager.get_auto_save_enabled():
		_state_manager.set_auto_save_interval(_config_manager.get_auto_save_interval())


## 应用行号显示设置
func _apply_row_numbers_settings() -> void:
	if not _config_manager:
		return

	_for_each_table_view(func(table_view):
		table_view.show_line_numbers=_config_manager.get_show_row_numbers()
		table_view.refresh()
	)


## 应用虚拟滚动设置
func _apply_virtual_scroll_settings() -> void:
	if not _config_manager:
		return

	_for_each_table_view(func(table_view):
		table_view.enable_virtual_scrolling=_config_manager.get_enable_virtual_scroll()
		table_view.refresh()
	)


func _apply_text_overflow_settings() -> void:
	if not _config_manager:
		return

	var mode := _get_text_overflow_mode()
	var auto_row_height := _config_manager.get_wrap_auto_row_height()
	var max_lines := _config_manager.get_wrap_max_lines()
	_for_each_table_view(func(table_view):
		table_view.apply_text_layout_settings(mode, auto_row_height, max_lines)
	)


func _get_text_overflow_mode() -> int:
	match _config_manager.get_cell_text_overflow():
		"clip":
			return TableView.TextOverflowMode.CLIP
		"wrap":
			return TableView.TextOverflowMode.WRAP
		_:
			return TableView.TextOverflowMode.ELLIPSIS


func _for_each_table_view(action: Callable) -> void:
	for binding_key in _open_files.keys():
		var tab_control := _open_files[binding_key] as Object
		if tab_control and tab_control.has_method("get_table_view"):
			var table_view = tab_control.get_table_view()
			if table_view is TableView:
				action.call(table_view)
#endregion
