class_name CSVLoader
extends RefCounted

## CSV 文件加载器，提供 CSV 文件的读取、解析和转换功能

## CSV 文件路径
var _file_path: String = ""

## 是否包含表头
var _has_header: bool = true

## 分隔符
var _delimiter: String = ","

## 字段类型映射（字段名 -> 类型）
var _field_types: Dictionary = {}

## 默认值映射（字段名 -> 默认值）
var _default_values: Dictionary = {}

## 必需字段列表
var _required_fields: Array[StringName] = []

## CSV Schema 资源
var _schema: CSVSchema = null

## 错误信息列表
var _errors: Array[String] = []

## 警告信息列表
var _warnings: Array[String] = []

## 解析统计信息
var _total_rows: int = 0
var _successful_rows: int = 0
var _failed_rows: int = 0

## 缓存字典（文件路径 -> CSVResource）
static var _cache: Dictionary = {}

## 缓存大小限制
static var _cache_max_size: int = 10

## LRU 缓存顺序
static var _cache_order: Array[String] = []


func _init() -> void:
	_errors.clear()
	_warnings.clear()
	_total_rows = 0
	_successful_rows = 0
	_failed_rows = 0


## 加载 CSV 文件
func load_file(file_path: String) -> CSVLoader:
	_file_path = file_path
	
	if not FileAccess.file_exists(file_path):
		_errors.append("文件不存在: %s" % _get_display_path(file_path))
		return self
	
	return self


## 设置是否包含表头
func with_header(has_header: bool) -> CSVLoader:
	_has_header = has_header
	return self


## 设置分隔符
func with_delimiter(delimiter: String) -> CSVLoader:
	_delimiter = delimiter
	return self


## 设置字段类型
func with_type(field_name: StringName, type: CSVFieldDefinition.FieldType) -> CSVLoader:
	_field_types[field_name] = type
	return self


## 设置字段默认值
func with_default(field_name: StringName, default_value: Variant) -> CSVLoader:
	_default_values[field_name] = default_value
	return self


## 设置必需字段
func with_required_fields(fields: Array[StringName]) -> CSVLoader:
	_required_fields = fields
	return self


## 设置 CSV Schema
func with_schema(schema: CSVSchema) -> CSVLoader:
	_schema = schema
	return self


## 清除缓存
static func clear_cache() -> void:
	_cache.clear()
	_cache_order.clear()


## 解析所有数据
func parse_all() -> CSVResource:
	var csv_resource := CSVResource.new()
	csv_resource.has_header = _has_header
	csv_resource.delimiter = _delimiter
	
	# 检查文件路径是否有效
	if _file_path.is_empty():
		csv_resource.add_error("未设置文件路径，请先调用 load_file()")
		return csv_resource
	
	# 检查缓存
	if _cache.has(_file_path):
		_update_cache_order(_file_path)
		return _cache[_file_path]
	
	# 读取文件内容
	var file_content := _read_file_content()
	if file_content.is_empty():
		csv_resource.add_error("文件内容为空或读取失败: %s" % _get_display_path(_file_path))
		return csv_resource
	
	# 解析 CSV 数据
	var lines := file_content.split("\n")
	
	# 解析表头
	var header_row: PackedStringArray
	if _has_header and lines.size() > 0:
		header_row = _parse_csv_line(lines[0])
		lines = lines.slice(1)  # 移除表头行
		
		# 检查重复列名
		_check_duplicate_headers(header_row)
		
		# 应用 Schema 验证
		if _schema != null:
			var schema_errors := _schema.validate_header(header_row)
			for error in schema_errors:
				csv_resource.add_error(error)
				_errors.append(error)
	
	csv_resource.headers = header_row
	
	# 建立字段名到列索引的映射
	var header_indices := _build_header_indices(header_row)
	
	# 解析数据行
	for i in range(lines.size()):
		var line := lines[i].strip_edges()
		if line.is_empty():
			continue
		
		var row_data := _parse_csv_line(line)
		csv_resource.add_raw_row(row_data)
		
		# 转换为字典格式
		var dict_row := _convert_row_to_dict(row_data, header_indices, i + 2)  # +2 因为跳过表头且从1开始计数
		
		if dict_row.is_empty():
			_failed_rows += 1
			continue
		
		# 应用类型转换
		_apply_type_conversions(dict_row)
		
		# 应用默认值
		_apply_default_values(dict_row)
		
		# 验证数据
		if _schema != null:
			var validation_errors := _schema.validate_row(dict_row, i + 2)
			if not validation_errors.is_empty():
				for error in validation_errors:
					csv_resource.add_error(error)
					_errors.append(error)
				_failed_rows += 1
				continue
		
		csv_resource.add_row(dict_row)
	
	# 更新统计信息
	csv_resource.total_rows = _total_rows
	csv_resource.successful_rows = _successful_rows
	csv_resource.failed_rows = _failed_rows
	
	# 添加错误和警告到资源
	for error in _errors:
		csv_resource.add_error(error)
	
	for warning in _warnings:
		csv_resource.add_warning(warning)
	
	# 缓存结果
	_add_to_cache(_file_path, csv_resource)
	
	# 输出解析统计
	_log_statistics(csv_resource)
	
	return csv_resource


## 创建流式读取器
func stream() -> CSVStreamReaderGD:
	var reader := CSVStreamReaderGD.new(_file_path, _has_header, _delimiter)
	
	# 应用字段类型
	for field_name in _field_types:
		reader.set_field_type(field_name, _field_types[field_name])
	
	# 应用默认值
	for field_name in _default_values:
		reader.set_default_value(field_name, _default_values[field_name])
	
	# 应用 Schema
	if _schema != null:
		reader.set_schema(_schema)
	
	return reader


## 读取文件内容
func _read_file_content() -> String:
	var file := FileAccess.open(_file_path, FileAccess.READ)
	if file == null:
		var error_str := "无法打开文件: %s (错误码: %d)" % [_get_display_path(_file_path), FileAccess.get_open_error()]
		_errors.append(error_str)
		return ""
	
	var content := file.get_as_text()
	file.close()
	
	# 处理 BOM（字节顺序标记）
	if content.length() >= 1:
		if content.unicode_at(0) == 0xFEFF:  # UTF-8 BOM
			content = content.substr(1)
	
	return content


## 解析 CSV 行（支持 RFC 4180 标准）
func _parse_csv_line(line: String) -> PackedStringArray:
	var result := PackedStringArray()
	var current := ""
	var in_quotes := false
	
	var i := 0
	while i < line.length():
		var char := line[i]
		
		if char == '"':
			if in_quotes and i < line.length() - 1 and line[i + 1] == '"':
				# 两个引号表示一个引号字符
				current += '"'
				i += 2
				continue
			in_quotes = not in_quotes
			i += 1
			continue
		
		if char == _delimiter and not in_quotes:
			result.append(current.strip_edges())
			current = ""
			i += 1
			continue
		
		current += char
		i += 1
	
	result.append(current.strip_edges())
	return result


## 建立字段名到列索引的映射
func _build_header_indices(header_row: PackedStringArray) -> Dictionary:
	var indices := {}
	for i in range(header_row.size()):
		var field_name: StringName = StringName(header_row[i].strip_edges())
		indices[field_name] = i
	return indices


## 转换行数据为字典格式
func _convert_row_to_dict(row: PackedStringArray, header_indices: Dictionary, row_index: int) -> Dictionary:
	var dict := {}
	
	for field_name in header_indices:
		var col_index: int = header_indices[field_name] as int
		if col_index < row.size():
			var value := row[col_index].strip_edges()
			if not value.is_empty():
				dict[field_name] = value
	
	_total_rows += 1
	_successful_rows += 1
	
	return dict


## 应用类型转换
func _apply_type_conversions(row_data: Dictionary) -> void:
	for field_name in _field_types:
		var type: CSVFieldDefinition.FieldType = _field_types[field_name]
		var value := row_data.get(field_name)
		
		if value == null:
			continue
		
		row_data[field_name] = _convert_value(value, type)


## 转换值到指定类型
func _convert_value(value: Variant, type: CSVFieldDefinition.FieldType) -> Variant:
	if value == null:
		return null
	
	match type:
		CSVFieldDefinition.FieldType.TYPE_INT:
			return int(value)
		CSVFieldDefinition.FieldType.TYPE_FLOAT:
			return float(value)
		CSVFieldDefinition.FieldType.TYPE_BOOL:
			if value is bool:
				return value
			if value is String:
				return value.to_lower() == "true" or value == "1"
			return bool(value)
		CSVFieldDefinition.FieldType.TYPE_STRING_NAME:
			if value is StringName:
				return value
			return StringName(str(value))
		CSVFieldDefinition.FieldType.TYPE_JSON:
			var json := JSON.new()
			var error := json.parse(str(value))
			if error == OK:
				return json.data
			return null
		CSVFieldDefinition.FieldType.TYPE_ARRAY:
			if value is Array:
				return value
			if value is String:
				return value.split(_delimiter, false)
			return []
		CSVFieldDefinition.FieldType.TYPE_RESOURCE, CSVFieldDefinition.FieldType.TYPE_TEXTURE, CSVFieldDefinition.FieldType.TYPE_SCENE:
			return _load_resource(str(value), type)
		_:
			return value


## 应用默认值
func _apply_default_values(row_data: Dictionary) -> void:
	# 应用显式设置的默认值
	for field_name in _default_values:
		if not row_data.has(field_name) or row_data[field_name] == null:
			row_data[field_name] = _default_values[field_name]
	
	# 应用类型默认值
	for field_name in _field_types:
		if not row_data.has(field_name) or row_data[field_name] == null:
			var type: CSVFieldDefinition.FieldType = _field_types[field_name]
			row_data[field_name] = _get_type_default(type)


## 获取类型的默认值
func _get_type_default(type: CSVFieldDefinition.FieldType) -> Variant:
	match type:
		CSVFieldDefinition.FieldType.TYPE_INT:
			return 0
		CSVFieldDefinition.FieldType.TYPE_FLOAT:
			return 0.0
		CSVFieldDefinition.FieldType.TYPE_BOOL:
			return false
		CSVFieldDefinition.FieldType.TYPE_STRING_NAME:
			return &""
		CSVFieldDefinition.FieldType.TYPE_JSON:
			return null
		CSVFieldDefinition.FieldType.TYPE_ARRAY:
			return []
		CSVFieldDefinition.FieldType.TYPE_RESOURCE, CSVFieldDefinition.FieldType.TYPE_TEXTURE, CSVFieldDefinition.FieldType.TYPE_SCENE:
			return null
		_:
			return ""


## 加载资源
func _load_resource(path: String, type: CSVFieldDefinition.FieldType) -> Variant:
	if path.is_empty():
		return null

	var resolved_path := path
	if resolved_path.begins_with("uid://"):
		var uid_id: int = ResourceUID.text_to_id(resolved_path)
		if uid_id != 0:
			var uid_path: String = ResourceUID.get_id_path(uid_id)
			if not uid_path.is_empty():
				resolved_path = uid_path

	if not ResourceLoader.exists(resolved_path):
		_warnings.append("资源不存在: %s" % resolved_path)
		return null

	var resource := ResourceLoader.load(resolved_path)
	if resource == null:
		_warnings.append("资源加载失败: %s" % resolved_path)
		return null

	# CSV 里允许只存 uid://；加载成功后，使用真实路径便于后续调试/序列化
	if path.begins_with("uid://") and resource is Resource:
		var loaded_uid_id: int = int((resource as Resource).resource_uid)
		if loaded_uid_id != 0:
			var loaded_path: String = ResourceUID.get_id_path(loaded_uid_id)
			if not loaded_path.is_empty():
				# 注意：这里不直接回写到 row_data，因为 Loader 当前仅返回 Resource。
				# 如需回写单元格值，请在更上层（转换器/数据模型）处理。
				pass

	return resource


## 检查重复的表头列名
func _check_duplicate_headers(header_row: PackedStringArray) -> void:
	var seen: Dictionary = {}
	for i in range(header_row.size()):
		var header := header_row[i].strip_edges()
		if seen.has(header):
			_warnings.append("重复的列名: '%s' (行: %d, 列: %d)" % [header, 1, i + 1])
		else:
			seen[header] = true


## 添加到缓存
func _add_to_cache(path: String, resource: CSVResource) -> void:
	# 如果缓存已满，移除最旧的条目
	if _cache.size() >= _cache_max_size and not _cache.has(path):
		if _cache_order.is_empty():
			_cache.clear()
		else:
			var oldest_path: String = _cache_order[0]
			_cache.erase(oldest_path)
			_cache_order.remove_at(0)
	
	_cache[path] = resource
	
	# 更新缓存顺序
	if path in _cache_order:
		_cache_order.erase(path)
	_cache_order.append(path)


## 更新缓存顺序（LRU）
func _update_cache_order(path: String) -> void:
	if path in _cache_order:
		_cache_order.erase(path)
	_cache_order.append(path)


## 获取显示路径（相对路径）
func _get_display_path(path: String) -> String:
	if path.begins_with("res://"):
		return path
	if path.begins_with("user://"):
		return path
	
	# 尝试转换为相对路径
	var res_path := ProjectSettings.localize_path(path)
	if res_path.begins_with("res://"):
		return res_path
	
	return path


## 输出解析统计信息
func _log_statistics(resource: CSVResource) -> void:
	var stats := resource.get_statistics()
	
	# 尝试使用 GLog（如果存在）
	if ClassDB.class_exists("GLog"):
		var glog = Engine.get_singleton("GLog")
		if glog != null:
			glog.info(stats)
			return
	
	# 回退到 Godot 内置日志
	if resource.has_errors():
		push_error(stats)
	else:
		print(stats)


## 获取错误信息
func get_errors() -> Array[String]:
	return _errors


## 获取警告信息
func get_warnings() -> Array[String]:
	return _warnings


## 检查是否有错误
func has_errors() -> bool:
	return _errors.size() > 0


## 检查是否有警告
func has_warnings() -> bool:
	return _warnings.size() > 0
