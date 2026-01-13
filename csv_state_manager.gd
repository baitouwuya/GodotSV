class_name CSVStateManager
extends Node

## CSV 状态管理器，管理文件状态、UI状态和Schema状态
## 提供统一的状态查询和变更通知机制

#region 信号 Signals
signal state_changed(state_type: String, old_value: Variant, new_value: Variant)
signal file_state_changed(is_modified: bool, is_readonly: bool)
signal ui_selection_changed(selected_cells: Array)
signal scroll_position_changed(scroll_pos: Vector2)
signal schema_state_changed(schema_loaded: bool, schema_path: String)
signal validation_state_changed(has_errors: bool, error_count: int)
#endregion

#region 信号定义 Signal Definitions
## 文件状态信号
signal file_loaded(file_path: String)
signal file_saved(file_path: String)
signal file_closed()
signal file_modified_changed(is_modified: bool)

## UI状态信号
signal cell_selected(row: int, col: int)
signal selection_cleared()
signal edit_mode_started(row: int, col: int)
signal edit_mode_ended()
signal scroll_scrolled(position: Vector2)

## Schema状态信号
signal schema_loaded(schema_path: String)
signal schema_unloaded()
signal schema_applied()
signal type_definition_changed(column: int, definition: Dictionary)

## 验证状态信号
signal validation_started()
signal validation_finished(errors: Array)
signal error_count_changed(count: int)
#endregion

#region 导出变量 Export Variables
## 数据模型实例
@export var data_model: CSVDataModel

## 自动保存间隔（秒），0表示禁用
@export var auto_save_interval: float = 300.0
#endregion

#region 公共变量 Public Variables
## 文件状态
var file_path: String = ""
var file_modified: bool = false
var file_readonly: bool = false
var file_encoding: String = "utf-8"
var file_delimiter: String = ","

## UI状态
var selected_cell: Vector2i = Vector2i(-1, -1)
var selection_anchor: Vector2i = Vector2i(-1, -1)
var scroll_position: Vector2 = Vector2.ZERO
var column_widths: PackedInt32Array = []
var row_heights: PackedInt32Array = []
var column_order: PackedInt32Array = []

## Schema状态
var is_schema_loaded: bool = false
var schema_path: String = ""
var schema_definitions: Array = []

## 验证状态
var validation_errors: Array = []
var has_validation_errors: bool = false
var last_validation_time: float = 0.0
#endregion

#region 私有变量 Private Variables
var _auto_save_timer: Timer
var _is_editing: bool = false
var _editing_cell: Vector2i = Vector2i(-1, -1)
#endregion

#region 生命周期方法 Lifecycle Methods
func _init() -> void:
	_setup_auto_save_timer()


func _ready() -> void:
	if data_model:
		data_model.data_changed.connect(_on_data_model_data_changed)
		data_model.cell_changed.connect(_on_data_model_cell_changed)
		data_model.selection_changed.connect(_on_data_model_selection_changed)
#endregion

#region 初始化功能 Initialization Features
func _setup_auto_save_timer() -> void:
	_auto_save_timer = Timer.new()
	_auto_save_timer.wait_time = auto_save_interval
	_auto_save_timer.timeout.connect(_on_auto_save)
	add_child(_auto_save_timer)


func set_data_model(model: CSVDataModel) -> void:
	if data_model:
		data_model.data_changed.disconnect(_on_data_model_data_changed)
		data_model.cell_changed.disconnect(_on_data_model_cell_changed)
		data_model.selection_changed.disconnect(_on_data_model_selection_changed)
	
	data_model = model
	
	if data_model:
		data_model.data_changed.connect(_on_data_model_data_changed)
		data_model.cell_changed.connect(_on_data_model_cell_changed)
		data_model.selection_changed.connect(_on_data_model_selection_changed)


func reset_all_states() -> void:
	_reset_file_state()
	_reset_ui_state()
	_reset_schema_state()
	_reset_validation_state()


func _reset_file_state() -> void:
	file_path = ""
	file_modified = false
	file_readonly = false
	file_encoding = "utf-8"
	file_delimiter = ","
	file_state_changed.emit(false, false)


func _reset_ui_state() -> void:
	selected_cell = Vector2i(-1, -1)
	selection_anchor = Vector2i(-1, -1)
	scroll_position = Vector2.ZERO
	column_widths.clear()
	row_heights.clear()
	column_order.clear()


func _reset_schema_state() -> void:
	is_schema_loaded = false
	schema_path = ""
	schema_definitions.clear()
	schema_state_changed.emit(false, "")


func _reset_validation_state() -> void:
	validation_errors.clear()
	has_validation_errors = false
	last_validation_time = 0.0
	validation_state_changed.emit(false, 0)
#endregion

#region 文件状态管理 File State Management
## 设置文件路径
func set_file_path(path: String) -> void:
	var old_path := file_path
	file_path = path
	state_changed.emit("file_path", old_path, file_path)
	
	if not path.is_empty():
		file_loaded.emit(path)


## 获取文件名
func get_file_name() -> String:
	if file_path.is_empty():
		return "未命名.csv"
	return file_path.get_file()


## 获取显示名称（带修改标记）
func get_display_name() -> String:
	var name := get_file_name()
	if file_modified:
		name += " *"
	return name


## 标记文件为已修改
func mark_file_modified() -> void:
	if not file_modified:
		var old_value := file_modified
		file_modified = true
		state_changed.emit("file_modified", old_value, true)
		file_modified_changed.emit(true, false)
		_start_auto_save()


## 标记文件为未修改
func mark_file_saved() -> void:
	var old_modified := file_modified
	file_modified = false
	
	state_changed.emit("file_modified", old_modified, false)
	file_modified_changed.emit(false, file_readonly)
	
	_stop_auto_save()
	
	if not file_path.is_empty():
		file_saved.emit(file_path)


## 设置文件为只读
func set_readonly(readonly: bool) -> void:
	var old_readonly := file_readonly
	file_readonly = readonly
	state_changed.emit("file_readonly", old_readonly, readonly)
	file_modified_changed.emit(file_modified, readonly)


## 关闭文件
func close_file() -> void:
	file_closed.emit()
	reset_all_states()


## 检查是否可以关闭
func can_close() -> bool:
	return not file_modified or is_auto_save_enabled()


## 设置文件编码
func set_file_encoding(encoding: String) -> void:
	var old_encoding := file_encoding
	file_encoding = encoding
	state_changed.emit("file_encoding", old_encoding, file_encoding)


## 设置文件分隔符
func set_file_delimiter(delimiter: String) -> void:
	var old_delimiter := file_delimiter
	file_delimiter = delimiter
	state_changed.emit("file_delimiter", old_delimiter, file_delimiter)


## 是否有文件
func has_file() -> bool:
	return not file_path.is_empty()


## 是否已修改
func is_file_modified() -> bool:
	return file_modified


## 是否为只读
func is_file_readonly() -> bool:
	return file_readonly
#endregion

#region UI状态管理 UI State Management
## 选择单元格
func select_cell(row: int, col: int, anchor: Vector2i = Vector2i(-1, -1)) -> void:
	var old_cell := selected_cell
	selected_cell = Vector2i(row, col)
	
	if anchor.x >= 0 and anchor.y >= 0:
		selection_anchor = anchor
	else:
		selection_anchor = selected_cell
	
	state_changed.emit("selected_cell", old_cell, selected_cell)
	ui_selection_changed.emit(data_model.selections if data_model else [])
	cell_selected.emit(row, col)


## 清除选择
func clear_selection() -> void:
	var old_cell := selected_cell
	selected_cell = Vector2i(-1, -1)
	selection_anchor = Vector2i(-1, -1)
	
	state_changed.emit("selected_cell", old_cell, selected_cell)
	ui_selection_changed.emit([])
	selection_cleared.emit()


## 获取选中的单元格
func get_selected_cell() -> Vector2i:
	return selected_cell


## 是否有选中单元格
func has_selected_cell() -> bool:
	return selected_cell.x >= 0 and selected_cell.y >= 0


## 设置滚动位置
func set_scroll_position(position: Vector2) -> void:
	var old_pos := scroll_position
	scroll_position = position
	state_changed.emit("scroll_position", old_pos, scroll_position)
	scroll_position_changed.emit(scroll_position)
	scroll_scrolled.emit(position)


## 获取滚动位置
func get_scroll_position() -> Vector2:
	return scroll_position


## 设置列宽
func set_column_width(column_index: int, width: int) -> void:
	while column_index >= column_widths.size():
		column_widths.append(100)
	
	var old_width := column_widths[column_index]
	column_widths[column_index] = width
	
	if data_model:
		data_model.set_column_width(column_index, width)


## 获取列宽
func get_column_width(column_index: int) -> int:
	if column_index < column_widths.size():
		return column_widths[column_index]
	return 100


## 设置行高
func set_row_height(row_index: int, height: int) -> void:
	while row_index >= row_heights.size():
		row_heights.append(30)
	
	var old_height := row_heights[row_index]
	row_heights[row_index] = height
	
	if data_model:
		data_model.set_row_height(row_index, height)


## 获取行高
func get_row_height(row_index: int) -> int:
	if row_index < row_heights.size():
		return row_heights[row_index]
	return 30


## 设置列顺序
func set_column_order(order: PackedInt32Array) -> void:
	column_order = order


## 获取列顺序
func get_column_order() -> PackedInt32Array:
	return column_order


## 重置布局
func reset_layout() -> void:
	column_widths.clear()
	row_heights.clear()
	column_order.clear()
	
	if data_model:
		data_model.reset_layout()


## 开始编辑模式
func start_edit_mode(row: int, col: int) -> void:
	_is_editing = true
	_editing_cell = Vector2i(row, col)
	edit_mode_started.emit(row, col)


## 结束编辑模式
func end_edit_mode() -> void:
	_is_editing = false
	_editing_cell = Vector2i(-1, -1)
	edit_mode_ended.emit()


## 是否处于编辑模式
func is_in_edit_mode() -> bool:
	return _is_editing


## 获取正在编辑的单元格
func get_editing_cell() -> Vector2i:
	return _editing_cell
#endregion

#region Schema状态管理 Schema State Management
## 设置类型定义（不改变 schema_loaded 状态；用于 SchemaManager 或内联类型标注）
func set_type_definitions(definitions: Array) -> void:
	schema_definitions = definitions.duplicate()
	if data_model:
		data_model.set_type_definitions(schema_definitions)


## 加载Schema
func load_schema(schema_path: String, definitions: Array) -> bool:
	var old_loaded := is_schema_loaded
	var old_path := schema_path
	
	is_schema_loaded = true
	self.schema_path = schema_path
	schema_definitions = definitions
	
	state_changed.emit("schema_loaded", old_loaded, true)
	schema_state_changed.emit(true, self.schema_path)
	schema_loaded.emit(self.schema_path)
	
	if data_model:
		data_model.set_type_definitions(definitions)
		schema_applied.emit()
	
	return true


## 卸载Schema
func unload_schema() -> void:
	var old_loaded := is_schema_loaded
	var old_path := schema_path
	
	is_schema_loaded = false
	schema_path = ""
	schema_definitions.clear()
	
	state_changed.emit("schema_loaded", old_loaded, false)
	schema_state_changed.emit(false, "")
	schema_unloaded.emit()
	
	if data_model:
		data_model.set_type_definitions([])


## 是否已加载Schema
func is_schema_loaded_flag() -> bool:
	return is_schema_loaded


## 获取Schema路径
func get_schema_path() -> String:
	return schema_path


## 获取Schema定义
func get_schema_definitions() -> Array:
	return schema_definitions.duplicate()


## 更新类型定义
func update_type_definition(column_index: int, definition: Dictionary) -> void:
	if column_index >= 0 and column_index < schema_definitions.size():
		schema_definitions[column_index] = definition
		
		if data_model:
			data_model.update_column_type(column_index, definition)
		
		type_definition_changed.emit(column_index, definition)
#endregion

#region 验证状态管理 Validation State Management
## 开始验证
func start_validation() -> void:
	validation_started.emit()


## 完成验证
func finish_validation(errors: Array) -> void:
	validation_errors = errors
	has_validation_errors = not errors.is_empty()
	last_validation_time = Time.get_ticks_msec() / 1000.0
	
	state_changed.emit("has_validation_errors", false, has_validation_errors)
	validation_state_changed.emit(has_validation_errors, errors.size())
	validation_finished.emit(errors)
	error_count_changed.emit(errors.size())


## 获取验证错误
func get_validation_errors() -> Array:
	return validation_errors.duplicate()


## 是否有验证错误
func has_errors() -> bool:
	return has_validation_errors


## 获取错误数量
func get_error_count() -> int:
	return validation_errors.size()


## 清除验证错误
func clear_validation_errors() -> void:
	var old_count := validation_errors.size()
	validation_errors.clear()
	has_validation_errors = false
	
	state_changed.emit("has_validation_errors", true, false)
	validation_state_changed.emit(false, 0)
	error_count_changed.emit(0)
#endregion

#region 自动保存功能 Auto Save Features
## 设置自动保存间隔
func set_auto_save_interval(interval: float) -> void:
	auto_save_interval = interval
	
	if _auto_save_timer:
		_auto_save_timer.wait_time = interval


## 获取自动保存间隔
func get_auto_save_interval() -> float:
	return auto_save_interval


## 是否启用自动保存
func is_auto_save_enabled() -> bool:
	return auto_save_interval > 0.0 and _auto_save_timer


## 启动自动保存
func _start_auto_save() -> void:
	if is_auto_save_enabled() and not _auto_save_timer.is_stopped():
		_auto_save_timer.start()


## 停止自动保存
func _stop_auto_save() -> void:
	if _auto_save_timer:
		_auto_save_timer.stop()


## 自动保存回调
func _on_auto_save() -> void:
	if file_modified and not file_path.is_empty():
		if data_model and data_model.data_processor:
			var success := data_model.data_processor.save_csv_file(file_path)
			if success:
				mark_file_saved()
#endregion

#region 状态查询功能 State Query Features
## 获取完整状态快照
func get_state_snapshot() -> Dictionary:
	return {
		"file": {
			"path": file_path,
			"modified": file_modified,
			"readonly": file_readonly,
			"encoding": file_encoding,
			"delimiter": file_delimiter
		},
		"ui": {
			"selected_cell": selected_cell,
			"selection_anchor": selection_anchor,
			"scroll_position": scroll_position,
			"is_editing": _is_editing
		},
		"schema": {
			"loaded": is_schema_loaded,
			"path": schema_path
		},
		"validation": {
			"has_errors": has_validation_errors,
			"error_count": validation_errors.size()
		}
	}


## 检查是否有未保存的更改
func has_unsaved_changes() -> bool:
	return file_modified


## 检查是否可以安全操作
func can_perform_operation(operation: String) -> bool:
	match operation:
		"edit":
			return not file_readonly
		"save":
			return not file_path.is_empty()
		"schema":
			return true
		"validate":
			return has_file()
		_:
			return true
#endregion

#region 回调处理 Callback Handlers
func _on_data_model_data_changed(change_type: String, details: Dictionary) -> void:
	mark_file_modified()


func _on_data_model_cell_changed(row_index: int, column_index: int, old_value: String, new_value: String) -> void:
	mark_file_modified()


func _on_data_model_selection_changed(selections: Array) -> void:
	ui_selection_changed.emit(selections)
#endregion
