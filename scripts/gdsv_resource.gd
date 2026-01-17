@tool
class_name GDSVResource
extends Resource

## GDSV 资源，用于存储解析后的 GDSV 数据

## 表头行
@export var headers: PackedStringArray = []

## 数据行（每个元素是一个 Dictionary）
@export var rows: Array[Dictionary] = []

## 原始数据（用于调试）
@export var raw_data: Array[PackedStringArray] = []

## 错误信息列表
@export var errors: Array[String] = []

## 警告信息列表
@export var warnings: Array[String] = []

## 解析统计信息
@export var total_rows: int = 0
@export var successful_rows: int = 0
@export var failed_rows: int = 0

## 是否包含表头
@export var has_header: bool = true

## 分隔符
@export var delimiter: String = ","

## 源 GDSV 文件路径（编辑器用：用于在双击资源时回到源文件编辑）
@export var source_gdsv_path: String = ""


## 添加一行数据
func add_row(row_data: Dictionary) -> void:
	rows.append(row_data)
	successful_rows += 1


## 添加错误信息
func add_error(error_msg: String) -> void:
	errors.append(error_msg)
	failed_rows += 1


## 添加警告信息
func add_warning(warning_msg: String) -> void:
	warnings.append(warning_msg)


## 添加原始数据行
func add_raw_row(raw_row: PackedStringArray) -> void:
	raw_data.append(raw_row)
	total_rows += 1


## 获取指定字段的值
func get_value(row_index: int, field_name: StringName) -> Variant:
	if row_index < 0 or row_index >= rows.size():
		return null
	
	return rows[row_index].get(field_name)


## 获取指定字段的整数值
func get_int(row_index: int, field_name: StringName, default_value: int = 0) -> int:
	var value := get_value(row_index, field_name)
	if value == null:
		return default_value
	
	if value is int:
		return value
	
	return int(value)


## 获取指定字段的浮点数值
func get_float(row_index: int, field_name: StringName, default_value: float = 0.0) -> float:
	var value := get_value(row_index, field_name)
	if value == null:
		return default_value
	
	if value is float:
		return value
	
	return float(value)


## 获取指定字段的布尔值
func get_bool(row_index: int, field_name: StringName, default_value: bool = false) -> bool:
	var value := get_value(row_index, field_name)
	if value == null:
		return default_value
	
	if value is bool:
		return value
	
	if value is String:
		return value.to_lower() == "true" or value == "1"
	
	return bool(value)


## 获取指定字段的字符串值
func get_string(row_index: int, field_name: StringName, default_value: String = "") -> String:
	var value := get_value(row_index, field_name)
	if value == null:
		return default_value
	
	return str(value)


## 获取指定字段的 StringName 值
func get_string_name(row_index: int, field_name: StringName, default_value: StringName = &"") -> StringName:
	var value := get_value(row_index, field_name)
	if value == null:
		return default_value
	
	if value is StringName:
		return value
	
	return StringName(str(value))


## 获取行数
func get_row_count() -> int:
	return rows.size()


## 获取列数
func get_column_count() -> int:
	return headers.size()


## 根据字段查找行
func find_rows(field_name: StringName, value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row in rows:
		if row.get(field_name) == value:
			result.append(row)
	return result


## 根据字段查找单行
func find_row(field_name: StringName, value: Variant) -> Dictionary:
	for row in rows:
		if row.get(field_name) == value:
			return row
	return {}


## 检查是否有错误
func has_errors() -> bool:
	return errors.size() > 0


## 检查是否有警告
func has_warnings() -> bool:
	return warnings.size() > 0


## 获取所有错误信息
func get_errors() -> Array[String]:
	return errors


## 获取所有警告信息
func get_warnings() -> Array[String]:
	return warnings


## 清空数据
func clear() -> void:
	headers.clear()
	rows.clear()
	raw_data.clear()
	errors.clear()
	warnings.clear()
	total_rows = 0
	successful_rows = 0
	failed_rows = 0


## 获取解析统计信息
func get_statistics() -> String:
	return "解析统计: 总行数=%d, 成功=%d, 失败=%d, 错误=%d, 警告=%d" % [
		total_rows, successful_rows, failed_rows, errors.size(), warnings.size()
	]


#region 工具方法 Utility Methods
## 仅用于编辑器：通过创建实例确保class_name在编辑器启动阶段注册
static func ensure_registered() -> void:
	if not Engine.is_editor_hint():
		return

	# 创建一次实例即可触发脚本类注册，不持有引用避免泄漏
	var _tmp := GDSVResource.new()
	_tmp = null
#endregion
