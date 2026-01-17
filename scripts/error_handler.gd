class_name ErrorHandler
extends RefCounted

## 错误处理和日志管理器
## 提供统一的错误处理、日志记录和用户友好的错误提示

signal error_occurred(error_data: Dictionary)
signal warning_occurred(warning_data: Dictionary)

#region 错误类型常量 Error Type Constants
## 文件加载失败
const ERROR_FILE_LOAD_FAILED = "file_load_failed"

## 文件保存失败
const ERROR_FILE_SAVE_FAILED = "file_save_failed"

## Schema 加载失败
const ERROR_SCHEMA_LOAD_FAILED = "schema_load_failed"

## 数据验证失败
const ERROR_VALIDATION_FAILED = "validation_failed"

## 未预期异常
const ERROR_UNEXPECTED_EXCEPTION = "unexpected_exception"

## 配置文件损坏
const ERROR_CONFIG_CORRUPTED = "config_corrupted"

## 文件格式错误
const ERROR_FILE_FORMAT_INVALID = "file_format_invalid"

## 文件已修改
const WARNING_FILE_MODIFIED = "file_modified"

## 未保存的更改
const WARNING_UNSAVED_CHANGES = "unsaved_changes"
#endregion

#region 公共变量 Public Variables
## 是否启用详细日志
var verbose_logging: bool = false

## 错误历史记录
var error_history: Array[Dictionary] = []

## 警告历史记录
var warning_history: Array[Dictionary] = []

## 最大历史记录数
var max_history_size: int = 100
#endregion

#region 错误处理 Error Handling
## 处理错误
func handle_error(error_type: String, message: String, context: Dictionary = {}) -> void:
	var error_data := _create_error_data(error_type, message, context)
	
	# 记录到历史
	_add_to_error_history(error_data)
	
	# 发出信号
	error_occurred.emit(error_data)
	
	# 使用 Godot 内置日志
	push_error(_format_error_message(error_data))
	
	# 详细日志
	if verbose_logging:
		printerr(_format_detailed_error(error_data))


## 处理警告
func handle_warning(warning_type: String, message: String, context: Dictionary = {}) -> void:
	var warning_data := _create_error_data(warning_type, message, context)
	
	# 记录到历史
	_add_to_warning_history(warning_data)
	
	# 发出信号
	warning_occurred.emit(warning_data)
	
	# 使用 Godot 内置日志
	push_warning(_format_warning_message(warning_data))
	
	# 详细日志
	if verbose_logging:
		print(_format_detailed_warning(warning_data))


## 处理异常
func handle_exception(exception: Variant, context: Dictionary = {}) -> void:
	var merged_context: Dictionary = {"stack_trace": get_stack(), "exception": str(exception)}
	merged_context.merge(context, true)
	
	var error_data := _create_error_data(
		ERROR_UNEXPECTED_EXCEPTION,
		str(exception),
		merged_context
	)
	
	_add_to_error_history(error_data)
	error_occurred.emit(error_data)
	push_error(_format_error_message(error_data))
	
	if verbose_logging:
		printerr(_format_detailed_error(error_data))


## 处理文件加载失败
func handle_file_load_error(file_path: String, error_message: String) -> void:
	handle_error(
		ERROR_FILE_LOAD_FAILED,
		"无法加载文件: " + file_path,
		{
			"file_path": file_path,
			"original_error": error_message
		}
	)


## 处理文件保存失败
func handle_file_save_error(file_path: String, error_message: String) -> void:
	handle_error(
		ERROR_FILE_SAVE_FAILED,
		"无法保存文件: " + file_path,
		{
			"file_path": file_path,
			"original_error": error_message
		}
	)


## 处理 Schema 加载失败
func handle_schema_load_error(schema_path: String, error_message: String) -> void:
	handle_error(
		ERROR_SCHEMA_LOAD_FAILED,
		"无法加载 Schema: " + schema_path,
		{
			"schema_path": schema_path,
			"original_error": error_message
		}
	)


## 处理数据验证失败
func handle_validation_error(validation_errors: Array[Dictionary]) -> void:
	var error_count := validation_errors.size()
	handle_error(
		ERROR_VALIDATION_FAILED,
		"数据验证失败: 发现 " + str(error_count) + " 个错误",
		{
			"error_count": error_count,
			"errors": validation_errors
		}
	)


## 处理配置文件损坏
func handle_config_corrupted_error(config_path: String, error_message: String) -> void:
	handle_error(
		ERROR_CONFIG_CORRUPTED,
		"配置文件损坏: " + config_path + "，将使用默认配置",
		{
			"config_path": config_path,
			"original_error": error_message
		}
	)


## 处理文件已修改警告
func handle_file_modified_warning(file_path: String) -> void:
	handle_warning(
		WARNING_FILE_MODIFIED,
		"文件已被外部程序修改: " + file_path,
		{"file_path": file_path}
	)


## 处理未保存更改警告
func handle_unsaved_changes_warning(file_path: String) -> void:
	handle_warning(
		WARNING_UNSAVED_CHANGES,
		"文件有未保存的更改: " + file_path,
		{"file_path": file_path}
	)
#endregion

#region 工具方法 Utility Methods
## 获取错误历史
func get_error_history() -> Array[Dictionary]:
	return error_history.duplicate()


## 获取警告历史
func get_warning_history() -> Array[Dictionary]:
	return warning_history.duplicate()


## 清除历史记录
func clear_history() -> void:
	error_history.clear()
	warning_history.clear()


## 获取最后一次错误
func get_last_error() -> Dictionary:
	if error_history.is_empty():
		return {}
	return error_history[-1]


## 获取最后一次警告
func get_last_warning() -> Dictionary:
	if warning_history.is_empty():
		return {}
	return warning_history[-1]


## 获取错误数量
func get_error_count() -> int:
	return error_history.size()


## 获取警告数量
func get_warning_count() -> int:
	return warning_history.size()
#endregion

#region 私有方法 Private Methods
## 创建错误数据
func _create_error_data(error_type: String, message: String, context: Dictionary) -> Dictionary:
	return {
		"type": error_type,
		"message": message,
		"timestamp": Time.get_datetime_string_from_system(),
		"context": context
	}


## 添加到错误历史
func _add_to_error_history(error_data: Dictionary) -> void:
	error_history.append(error_data)
	if error_history.size() > max_history_size:
		error_history.pop_front()


## 添加到警告历史
func _add_to_warning_history(warning_data: Dictionary) -> void:
	warning_history.append(warning_data)
	if warning_history.size() > max_history_size:
		warning_history.pop_front()


## 格式化错误消息
func _format_error_message(error_data: Dictionary) -> String:
	return "[%s] %s: %s" % [error_data.timestamp, error_data.type, error_data.message]


## 格式化警告消息
func _format_warning_message(warning_data: Dictionary) -> String:
	return "[%s] %s: %s" % [warning_data.timestamp, warning_data.type, warning_data.message]


## 格式化详细错误
func _format_detailed_error(error_data: Dictionary) -> String:
	var message := "===== 错误详情 =====\n"
	message += "类型: %s\n" % error_data.type
	message += "消息: %s\n" % error_data.message
	message += "时间: %s\n" % error_data.timestamp
	
	if not error_data.context.is_empty():
		message += "上下文:\n"
		for key in error_data.context:
			message += "  %s: %s\n" % [key, error_data.context[key]]
	
	if error_data.context.has("stack_trace"):
		message += "堆栈:\n"
		var stack: Array = error_data.context.stack_trace
		for item in stack:
			message += "  %s:%d in %s()\n" % [item.source, item.line, item.function]
	
	message += "==================\n"
	return message


## 格式化详细警告
func _format_detailed_warning(warning_data: Dictionary) -> String:
	var message := "===== 警告详情 =====\n"
	message += "类型: %s\n" % warning_data.type
	message += "消息: %s\n" % warning_data.message
	message += "时间: %s\n" % warning_data.timestamp
	
	if not warning_data.context.is_empty():
		message += "上下文:\n"
		for key in warning_data.context:
			message += "  %s: %s\n" % [key, warning_data.context[key]]
	
	message += "==================\n"
	return message
