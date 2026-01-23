class_name GDSVStreamReaderGD
extends RefCounted

## GDSV 流式读取器，用于逐行读取大型 GDSV 文件，减少内存占用

## 文件对象
var _file: FileAccess = null

## 文件路径
var _file_path: String = ""

## 是否包含表头
var _has_header: bool = true

## 分隔符
var _delimiter: String = ","

## 表头列
var _headers: PackedStringArray = []

## 字段类型映射
var _field_types: Dictionary = {}

## 默认值映射
var _default_values: Dictionary = {}

## 类型转换器
var _type_converter: GDSVTypeConverter = null

## 当前行索引
var _current_line_index: int = 0

## 是否已读取表头
var _header_read: bool = false

## GDSV Schema
var _schema: GDSVSchema = null

## 必需字段列表
var _required_fields: Array[StringName] = []

## 错误信息列表
var _errors: Array[String] = []

## 警告信息列表
var _warnings: Array[String] = []

## 缓冲区（用于处理多行字段）
var _buffer: String = ""

## 是否在引号内
var _in_quotes: bool = false


func _init(file_path: String, has_header: bool = true, delimiter: String = ",") -> void:
	_file_path = file_path
	_has_header = has_header
	_delimiter = delimiter
	_type_converter = GDSVTypeConverter.new()
	_open_file()


## 打开文件
func _open_file() -> void:
	_file = FileAccess.open(_file_path, FileAccess.READ)
	if _file == null:
		_errors.append("无法打开文件: %s (错误码: %d)" % [_file_path, FileAccess.get_open_error()])


## 关闭文件
func close() -> void:
	if _file != null:
		_file.close()
		_file = null


## 检查是否有下一行
func has_next() -> bool:
	if _file == null:
		return false
	
	return not _file.eof_reached()


## 读取下一行
func next() -> Dictionary:
	if _file == null:
		_errors.append("文件未打开或已关闭")
		return {}
	
	# 读取表头
	if not _header_read and _has_header:
		_read_header()
		_header_read = true
		return {} # 返回空字典表示表头已读取
	
	# 读取数据行
	while not _file.eof_reached():
		var line := _file.get_line()
		_current_line_index += 1
		
		# 处理多行字段
		_buffer += line
		
		# 检查引号匹配
		if line.count('"') % 2 != 0:
			_in_quotes = not _in_quotes
		
		# 如果不在引号内，说明是一行完整的记录
		if not _in_quotes:
			var row_data := _parse_buffered_line()
			if row_data.is_empty():
				continue
			
			return row_data
	
	# 文件结束
	return {}


## 读取表头
func _read_header() -> void:
	if _file == null:
		return
	
	while not _file.eof_reached():
		var line := _file.get_line()
		_current_line_index += 1
		
		if line.is_empty():
			continue
		
		_headers = _parse_gdsv_line(line)
		break


## 解析缓冲的行
func _parse_buffered_line() -> Dictionary:
	var line := _buffer
	_buffer = "" # 清空缓冲区
	
	if line.strip_edges().is_empty():
		return {}
	
	var row := _parse_gdsv_line(line)
	if row.is_empty():
		return {}
	
	# 转换为字典格式
	var dict := _convert_row_to_dict(row)
	
	# 应用类型转换
	_apply_type_conversions(dict)
	
	# 应用默认值
	_apply_default_values(dict)
	
	# 验证数据
	if _schema != null:
		var validation_errors := _schema.validate_row(dict, _current_line_index)
		if not validation_errors.is_empty():
			for error in validation_errors:
				_errors.append(error)
			return {}
	
	return dict


## 解析 GDSV 行
func _parse_gdsv_line(line: String) -> PackedStringArray:
	var result := PackedStringArray()
	var current := ""
	var in_quotes := false
	
	for i in range(line.length()):
		var char := line[i]
		
		if char == '"':
			if in_quotes and i < line.length() - 1 and line[i + 1] == '"':
				current += '"'
				i += 1
			else:
				in_quotes = not in_quotes
		elif char == _delimiter and not in_quotes:
			result.append(current.strip_edges())
			current = ""
		else:
			current += char
	
	result.append(current.strip_edges())
	return result


## 转换为字典格式
func _convert_row_to_dict(row: PackedStringArray) -> Dictionary:
	var dict := {}
	
	for i in range(min(row.size(), _headers.size())):
		var field_name: StringName = StringName(_headers[i].strip_edges())
		var value := row[i].strip_edges()
		if not value.is_empty():
			dict[field_name] = value
	
	return dict


## 应用类型转换
func _apply_type_conversions(row_data: Dictionary) -> void:
	for field_name in _field_types:
		var type: GDSVFieldDefinition.FieldType = _field_types[field_name]
		var value := row_data.get(field_name)
		
		if value == null:
			if field_name in _required_fields:
				_errors.append("必需字段为空: 行 %d, 列 '%s'" % [_current_line_index, field_name])
				_warnings.append("必需字段为空: 行 %d, 列 '%s'" % [_current_line_index, field_name])
			continue
		
		row_data[field_name] = _convert_value(value, type)


## 转换值
func _convert_value(value: Variant, type: GDSVFieldDefinition.FieldType) -> Variant:
	if value == null:
		return null

	var str_value := str(value).strip_edges()
	if str_value.is_empty():
		return null

	match type:
		GDSVFieldDefinition.FieldType.TYPE_INT, GDSVFieldDefinition.FieldType.TYPE_FLOAT, GDSVFieldDefinition.FieldType.TYPE_BOOL, GDSVFieldDefinition.FieldType.TYPE_STRING_NAME:
			var type_name := _get_converter_type(type)
			var result: Dictionary = _type_converter.convert_string_result(str_value, type_name)
			if not bool(result.get("success", false)):
				_warnings.append("Type conversion failed at row %d: %s" % [_current_line_index, str(result.get("error_message", ""))])
				return str_value
			return result.get("value")
		GDSVFieldDefinition.FieldType.TYPE_JSON:
			var json := JSON.new()
			var error := json.parse(str_value)
			if error == OK:
				return json.data
			_warnings.append("JSON parse failed at row %d: '%s'" % [_current_line_index, str_value])
			return null
		GDSVFieldDefinition.FieldType.TYPE_ARRAY:
			if value is Array:
				return value
			return str_value.split(_delimiter, false)
		GDSVFieldDefinition.FieldType.TYPE_RESOURCE, GDSVFieldDefinition.FieldType.TYPE_TEXTURE, GDSVFieldDefinition.FieldType.TYPE_SCENE:
			return _load_resource(str_value, type)
		_:
			return str_value


## 应用默认值
func _apply_default_values(row_data: Dictionary) -> void:
	for field_name in _default_values:
		if field_name in _required_fields:
			continue
		if not row_data.has(field_name) or row_data[field_name] == null:
			row_data[field_name] = _default_values[field_name]
	
	for field_name in _field_types:
		if field_name in _required_fields:
			continue
		if not row_data.has(field_name) or row_data[field_name] == null:
			var type: GDSVFieldDefinition.FieldType = _field_types[field_name]
			row_data[field_name] = _get_type_default(type)


## 获取类型默认值
func _get_type_default(type: GDSVFieldDefinition.FieldType) -> Variant:
	match type:
		GDSVFieldDefinition.FieldType.TYPE_INT:
			return 0
		GDSVFieldDefinition.FieldType.TYPE_FLOAT:
			return 0.0
		GDSVFieldDefinition.FieldType.TYPE_BOOL:
			return false
		GDSVFieldDefinition.FieldType.TYPE_STRING_NAME:
			return &""
		GDSVFieldDefinition.FieldType.TYPE_JSON:
			return null
		GDSVFieldDefinition.FieldType.TYPE_ARRAY:
			return []
		GDSVFieldDefinition.FieldType.TYPE_RESOURCE, GDSVFieldDefinition.FieldType.TYPE_TEXTURE, GDSVFieldDefinition.FieldType.TYPE_SCENE:
			return null
		_:
			return ""


func _get_converter_type(type: GDSVFieldDefinition.FieldType) -> String:
	match type:
		GDSVFieldDefinition.FieldType.TYPE_INT:
			return "int"
		GDSVFieldDefinition.FieldType.TYPE_FLOAT:
			return "float"
		GDSVFieldDefinition.FieldType.TYPE_BOOL:
			return "bool"
		GDSVFieldDefinition.FieldType.TYPE_STRING_NAME:
			return "StringName"
		_:
			return "String"


## 加载资源
func _load_resource(path: String, type: GDSVFieldDefinition.FieldType) -> Variant:
	if path.is_empty():
		return null
	
	if not ResourceLoader.exists(path):
		_warnings.append("资源不存在: %s" % path)
		return null
	
	var resource := ResourceLoader.load(path)
	if resource == null:
		_warnings.append("资源加载失败: %s" % path)
		return null
	
	return resource


## 设置字段类型
func set_field_type(field_name: StringName, type: GDSVFieldDefinition.FieldType) -> void:
	_field_types[field_name] = type


## 设置默认值
func set_default_value(field_name: StringName, default_value: Variant) -> void:
	_default_values[field_name] = default_value


## 设置 Schema
func set_schema(schema: GDSVSchema) -> void:
	_schema = schema


func set_required_fields(fields: Array[StringName]) -> void:
	_required_fields = fields


## 获取表头
func get_headers() -> PackedStringArray:
	return _headers


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


## 获取当前行索引
func get_current_line_index() -> int:
	return _current_line_index
