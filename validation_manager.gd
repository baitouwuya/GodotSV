class_name ValidationManager
extends Node

## 验证管理器，负责实时数据验证、错误显示和错误统计

#region 信号 Signals
## 验证完成
signal validation_completed(error_count: int)

## 错误添加
signal error_added(error: Dictionary)

## 错误移除
signal error_removed(row: int, column: int)

## 所有错误清除
signal errors_cleared()

## 验证状态变化
signal validation_state_changed(is_validating: bool)
#endregion

#region 常量 Constants
## 错误类型枚举
enum ErrorType {
	TYPE_MISMATCH,       # 类型不匹配
	VALUE_OUT_OF_RANGE,  # 值超出范围
	REQUIRED_FIELD,      # 必填字段为空
	INVALID_ENUM,        # 无效枚举值
	INVALID_PATTERN,     # 正则表达式不匹配
	INVALID_LENGTH,      # 长度不符合要求
	INVALID_ARRAY,       # 无效数组
	INVALID_RESOURCE,    # 无效资源路径
	CUSTOM_ERROR         # 自定义错误
}

## 错误严重程度
enum ErrorSeverity {
	ERROR,       # 错误（必须修复）
	WARNING,     # 警告（建议修复）
	INFO         # 信息（提示）
}

## 错误颜色
const COLOR_ERROR: Color = Color(1.0, 0.2, 0.2, 1.0)
const COLOR_WARNING: Color = Color(1.0, 0.8, 0.2, 1.0)
const COLOR_INFO: Color = Color(0.2, 0.6, 1.0, 1.0)
const COLOR_NORMAL: Color = Color(0.0, 0.0, 0.0, 0.0)
#endregion

#region 私有变量 Private Variables
## 数据处理器引用
var _data_processor: GDSVDataProcessor

## Schema 管理器引用
var _schema_manager: SchemaManager

## 状态管理器引用
var _state_manager: GDSVStateManager

## 数据模型引用（用于获取更细粒度的单元格变化事件）
var _data_model: GDSVDataModel

## 错误列表 {row: {column: error_data}}
var _errors: Dictionary = {}

## 错误数量统计
var _error_count: int = 0

## 警告数量统计
var _warning_count: int = 0

## 信息数量统计
var _info_count: int = 0

## 是否正在验证
var _is_validating: bool = false

## 实时验证开关
var _real_time_validation: bool = true

## 验证延迟（秒）
var _validation_delay: float = 0.15

## 当前验证队列
var _validation_queue: Array[Dictionary] = []

## 是否已安排一次队列刷新（用于防抖/合并）
var _is_validation_flush_scheduled: bool = false
#endregion

#region 生命周期方法 Lifecycle Methods
func _init() -> void:
	pass


func _ready() -> void:
	pass


func _exit_tree() -> void:
	pass
#endregion

#region 初始化功能 Initialization Features
## 设置数据处理器
func set_data_processor(processor: GDSVDataProcessor) -> void:
	if _data_processor and _data_processor.data_changed.is_connected(_on_data_changed):
		_data_processor.data_changed.disconnect(_on_data_changed)
	
	_data_processor = processor
	if _data_processor and not _data_processor.data_changed.is_connected(_on_data_changed):
		_data_processor.data_changed.connect(_on_data_changed)


## 设置 Schema 管理器
func set_schema_manager(manager: SchemaManager) -> void:
	_schema_manager = manager
	if _schema_manager:
		_schema_manager.type_definitions_changed.connect(_on_type_definitions_changed)


## 设置状态管理器
func set_state_manager(manager: GDSVStateManager) -> void:
	_state_manager = manager
	_connect_to_data_model_from_state_manager()


func _connect_to_data_model_from_state_manager() -> void:
	if _data_model:
		if _data_model.cell_changed.is_connected(_on_data_model_cell_changed):
			_data_model.cell_changed.disconnect(_on_data_model_cell_changed)
		if _data_model.data_changed.is_connected(_on_data_model_data_changed):
			_data_model.data_changed.disconnect(_on_data_model_data_changed)
		_data_model = null

	if not _state_manager or not _state_manager.data_model:
		return

	_data_model = _state_manager.data_model
	if _data_model:
		_data_model.cell_changed.connect(_on_data_model_cell_changed)
		_data_model.data_changed.connect(_on_data_model_data_changed)


func _on_data_model_cell_changed(row_index: int, column_index: int, _old_value: String, _new_value: String) -> void:
	schedule_cell_validation(row_index, column_index)


func _on_data_model_data_changed(change_type: String, _details: Dictionary) -> void:
	# 行/列结构变化时重新验证整个表格，确保错误位置跟随变化
	match change_type:
		"row_inserted", "row_removed", "row_moved", "batch_rows_removed", "column_inserted", "column_removed", "column_moved", "column_renamed", "load", "import", "clear":
			validate_table()
#endregion

#region 验证功能 Validation Features
## 验证单个单元格
func validate_cell(row: int, column: int, value: Variant) -> Dictionary:
	var error_data := {}
	var type_def: Dictionary = {}
	
	# 获取类型定义
	if _schema_manager and _schema_manager.is_schema_loaded():
		type_def = _schema_manager.get_type_definition_for_index(column)
	
	# 1. 必填字段验证
	if type_def and bool(type_def.get("required", false)) and (value == null or str(value).is_empty()):
		error_data = {
			"type": ErrorType.REQUIRED_FIELD,
			"severity": ErrorSeverity.ERROR,
			"message": "必填字段不能为空",
			"row": row,
			"column": column
		}
		return error_data

	# 非必填字段：空值视为“使用默认值”，不参与后续类型/范围等校验（更贴近 Godot Inspector 的语义）。
	if value == null or str(value).is_empty():
		return {}
	
	# 2. 类型验证
	if type_def and not _validate_type(value, type_def):
		error_data = {
			"type": ErrorType.TYPE_MISMATCH,
			"severity": ErrorSeverity.ERROR,
			"message": str("类型不匹配，应为 ", type_def.get("type", "")),
			"row": row,
			"column": column
		}
		return error_data
	
	# 3. 范围验证
	if type_def and not _validate_range(value, type_def):
		var min_val: Variant = type_def.get("min", null)
		var max_val: Variant = type_def.get("max", null)
		error_data = {
			"type": ErrorType.VALUE_OUT_OF_RANGE,
			"severity": ErrorSeverity.ERROR,
			"message": str("值超出范围 [", min_val, ", ", max_val, "]"),
			"row": row,
			"column": column
		}
		return error_data
	
	# 4. 枚举值验证
	if type_def:
		var enum_values: Array = type_def.get("enum_values", []) as Array
		if not enum_values.is_empty() and not value in enum_values:
			error_data = {
				"type": ErrorType.INVALID_ENUM,
				"severity": ErrorSeverity.ERROR,
				"message": str("无效的枚举值: ", value),
				"row": row,
				"column": column
			}
			return error_data
	
	# 5. 正则表达式验证
	var pattern := str(type_def.get("pattern", "")) if type_def else ""
	if not pattern.is_empty():
		var regex := RegEx.new()
		regex.compile(pattern)
		if not regex.search(str(value)):
			error_data = {
				"type": ErrorType.INVALID_PATTERN,
				"severity": ErrorSeverity.ERROR,
				"message": str("值不符合格式要求: ", pattern),
				"row": row,
				"column": column
			}
			return error_data
	
	# 6. 长度验证
	if type_def and not _validate_length(value, type_def):
		var min_len: int = int(type_def.get("min_length", 0))
		var max_len: int = int(type_def.get("max_length", 0))
		error_data = {
			"type": ErrorType.INVALID_LENGTH,
			"severity": ErrorSeverity.ERROR,
			"message": str("长度不符合要求 [", min_len, ", ", max_len, "]"),
			"row": row,
			"column": column
		}
		return error_data
	
	# 7. 资源路径验证
	if type_def and str(type_def.get("type", "")).to_lower() == "resource":
		if not _validate_resource_path(str(value)):
			error_data = {
				"type": ErrorType.INVALID_RESOURCE,
				"severity": ErrorSeverity.WARNING,
				"message": "资源无效或不存在",
				"row": row,
				"column": column
			}
			return error_data
	
	return {}


## 验证类型
func _validate_type(value: Variant, type_def: Dictionary) -> bool:
	var data_type: String = str(type_def.get("type", "")).to_lower()
	
	match data_type:
		"int":
			if value is int:
				return true
			var s := str(value).strip_edges()
			if s.is_valid_int():
				return true
			if s.is_valid_float():
				var f := s.to_float()
				return absf(f - round(f)) < 0.000001
			return false
		"float":
			return value is float or str(value).is_valid_float()
		"bool":
			return value is bool or value in [true, false, "true", "false", "True", "False", "1", "0"]
		"string":
			return value is String
		"stringname":
			return true  # 任何值都可以转换为 StringName
		"vector2":
			return _parse_number_list(str(value)).size() >= 2
		"vector3":
			return _parse_number_list(str(value)).size() >= 3
		"vector2i":
			return _parse_int_list(str(value)).size() >= 2
		"vector3i":
			return _parse_int_list(str(value)).size() >= 3
		"color":
			return _is_valid_color_string(str(value))
		"resource":
			return value is String or value is Resource
		"enum":
			return true  # 单独验证
		"array":
			return value is Array or str(value).begins_with("[")
		"json":
			return true
		_:
			return true  # 未知类型，通过验证


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


func _parse_int_list(text: String) -> Array[int]:
	var cleaned := str(text).strip_edges()
	if cleaned.is_empty():
		return []
	var regex := RegEx.new()
	regex.compile("[-+]?\\d+")
	var out: Array[int] = []
	for m in regex.search_all(cleaned):
		out.append(int(m.get_string()))
	return out


func _is_valid_color_string(text: String) -> bool:
	var s := str(text).strip_edges()
	if s.is_empty():
		return true
	if s.begins_with("#"):
		var hex := s.substr(1)
		if hex.length() != 6 and hex.length() != 8:
			return false
		for i in range(hex.length()):
			var c := hex.substr(i, 1)
			if not (
				(c >= "0" and c <= "9")
				or (c >= "a" and c <= "f")
				or (c >= "A" and c <= "F")
			):
				return false
		return true

	# 允许 r,g,b 或 r,g,b,a 的数值写法
	return _parse_number_list(s).size() >= 3


## 验证范围
func _validate_range(value: Variant, type_def: Dictionary) -> bool:
	var min_val: Variant = type_def.get("min", null)
	var max_val: Variant = type_def.get("max", null)
	
	# 如果没有设置范围，通过验证
	if min_val == null and max_val == null:
		return true
	
	# 转换为数值进行比较
	var num_value: float = 0.0
	if value is int or value is float:
		num_value = float(value)
	elif str(value).is_valid_float():
		num_value = str(value).to_float()
	else:
		return false
	
	# 验证最小值
	if min_val != null and num_value < float(min_val):
		return false
	
	# 验证最大值
	if max_val != null and num_value > float(max_val):
		return false
	
	return true


## 验证长度
func _validate_length(value: Variant, type_def: Dictionary) -> bool:
	var min_len: int = int(type_def.get("min_length", 0))
	var max_len: int = int(type_def.get("max_length", 0))
	
	var str_value := str(value)
	var length := str_value.length()
	
	# 验证最小长度
	if length < min_len:
		return false
	
	# 验证最大长度
	if max_len > 0 and length > max_len:
		return false
	
	return true


## 验证资源路径
func _validate_resource_path(path: String) -> bool:
	if path.is_empty():
		return false
	
	# 检查是否是有效的资源路径
	if not path.begins_with("res://") and not path.begins_with("user://"):
		return false
	
	# 检查文件是否存在
	return ResourceLoader.exists(path)


## 验证整个表格
func validate_table() -> int:
	if not _data_processor:
		return 0
	
	_is_validating = true
	validation_state_changed.emit(true)
	
	_clear_all_errors()
	
	var row_count := _data_processor.get_row_count()
	var col_count := _data_processor.get_column_count()
	
	for row in range(row_count):
		for col in range(col_count):
			var value := _data_processor.get_cell_value(row, col)
			var error: Dictionary = validate_cell(row, col, value)
			
			if not error.is_empty():
				_add_error(error)
	
	_is_validating = false
	validation_state_changed.emit(false)
	
	validation_completed.emit(_error_count)
	return _error_count
#endregion

#region 实时验证功能 Real-time Validation Features
## 计划验证单元格
func schedule_cell_validation(row: int, column: int) -> void:
	if not _real_time_validation:
		return
	
	# 添加到验证队列
	_validation_queue.append({"row": row, "column": column})
	
	_schedule_validation_flush()


func _schedule_validation_flush() -> void:
	if _is_validation_flush_scheduled:
		return
	
	_is_validation_flush_scheduled = true
	call_deferred("_flush_validation_queue")


func _flush_validation_queue() -> void:
	_is_validation_flush_scheduled = false
	_execute_validation_queue()


## 执行验证队列
func _execute_validation_queue() -> void:
	if _validation_queue.is_empty():
		return
	
	for item in _validation_queue:
		var row: int = int(item.row)
		var col: int = int(item.column)
		
		var value := _data_processor.get_cell_value(row, col) if _data_processor else ""
		var error := validate_cell(row, col, value)
		
		# 移除旧错误
		_remove_error(row, col)
		
		# 添加新错误
		if not error.is_empty():
			_add_error(error)
	
	_validation_queue.clear()
#endregion

#region 错误管理功能 Error Management Features
## 添加错误
func _add_error(error: Dictionary) -> void:
	var row: int = int(error.row)
	var col: int = int(error.column)
	
	# 添加到错误列表
	if not _errors.has(row):
		_errors[row] = {}
	
	_errors[row][col] = error
	
	# 更新统计
	var severity: int = int(error.severity)
	match severity:
		ErrorSeverity.ERROR:
			_error_count += 1
		ErrorSeverity.WARNING:
			_warning_count += 1
		ErrorSeverity.INFO:
			_info_count += 1
	
	error_added.emit(error)


## 移除错误
func _remove_error(row: int, column: int) -> void:
	if not _errors.has(row):
		return
	
	if not _errors[row].has(column):
		return
	
	var error: Dictionary = _errors[row][column]
	_errors[row].erase(column)
	
	# 更新统计
	var severity: int = int(error.severity)
	match severity:
		ErrorSeverity.ERROR:
			_error_count -= 1
		ErrorSeverity.WARNING:
			_warning_count -= 1
		ErrorSeverity.INFO:
			_info_count -= 1
	
	# 如果该行没有错误了，移除该行
	if _errors[row].is_empty():
		_errors.erase(row)
	
	error_removed.emit(row, column)


## 清除所有错误
func _clear_all_errors() -> void:
	_errors.clear()
	_error_count = 0
	_warning_count = 0
	_info_count = 0
	
	errors_cleared.emit()


## 获取指定单元格的错误
func get_cell_error(row: int, column: int) -> Dictionary:
	if _errors.has(row) and _errors[row].has(column):
		var error: Dictionary = _errors[row][column]
		return error
	return {}


## 获取所有错误
func get_all_errors() -> Array[Dictionary]:
	var all_errors: Array[Dictionary] = []
	
	for row in _errors:
		for col in _errors[row]:
			all_errors.append(_errors[row][col])
	
	return all_errors


## 获取错误数量
func get_error_count() -> int:
	return _error_count


## 获取警告数量
func get_warning_count() -> int:
	return _warning_count


## 获取信息数量
func get_info_count() -> int:
	return _info_count


## 是否有错误
func has_errors() -> bool:
	return _error_count > 0


## 获取错误颜色
func get_error_color(severity: int) -> Color:
	match severity:
		ErrorSeverity.ERROR:
			return COLOR_ERROR
		ErrorSeverity.WARNING:
			return COLOR_WARNING
		ErrorSeverity.INFO:
			return COLOR_INFO
		_:
			return COLOR_ERROR


## 获取单元格颜色
func get_cell_color(row: int, column: int) -> Color:
	var error := get_cell_error(row, column)
	if not error.is_empty():
		var severity: int = int(error.severity)
		return get_error_color(severity)
	return COLOR_NORMAL
#endregion

#region 回调处理 Callback Handlers
## 数据变化回调
func _on_data_changed(change_type: String, details: Dictionary) -> void:
	var row: int = int(details.get("row", -1))
	var col: int = int(details.get("column", -1))
	if row >= 0 and col >= 0:
		schedule_cell_validation(row, col)


## 类型定义变化回调
func _on_type_definitions_changed(definitions: Array) -> void:
	# 类型定义变化时重新验证整个表格
	validate_table()
#endregion

#region 配置功能 Configuration Features
## 设置实时验证
func set_real_time_validation(enabled: bool) -> void:
	_real_time_validation = enabled


## 获取实时验证状态
func get_real_time_validation() -> bool:
	return _real_time_validation


## 设置验证延迟
func set_validation_delay(delay: float) -> void:
	_validation_delay = delay


## 获取验证延迟
func get_validation_delay() -> float:
	return _validation_delay


## 是否正在验证
func is_validating() -> bool:
	return _is_validating
#endregion
