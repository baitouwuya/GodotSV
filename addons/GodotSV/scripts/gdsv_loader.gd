@tool
class_name GDSVLoader
extends RefCounted

# 编辑器插件脚本路径（仅在编辑器中使用，避免导出后 preload 失败）
const _PLUGIN_SCRIPT_PATH := "res://addons/GodotSV/scripts/plugin.gd"
const _GDSV_STREAM_READER_SCRIPT := preload("res://addons/GodotSV/scripts/gdsv_stream_reader.gd")

# 延迟加载插件脚本（仅在编辑器中）
static var _plugin_script: GDScript = null

static func _get_plugin_script() -> GDScript:
	if _plugin_script == null and Engine.is_editor_hint():
		if ResourceLoader.exists(_PLUGIN_SCRIPT_PATH):
			_plugin_script = load(_PLUGIN_SCRIPT_PATH)
	return _plugin_script


## GDSV 文件加载器，提供 GDSV 文件的读取、解析和转换功能

## GDSV 文件路径
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

## GDSV Schema 资源
var _schema: GDSVSchema = null

## GDSV 数据处理器
var gdsv_data_processor: GDSVDataProcessor

## 类型转换器
var _type_converter: GDSVTypeConverter = null

## 错误信息列表
var _errors: Array[String] = []

## 警告信息列表
var _warnings: Array[String] = []

## 解析统计信息
var _total_rows: int = 0
var _successful_rows: int = 0
var _failed_rows: int = 0

## 当前解析行号（用于类型转换错误报告）
var _current_row: int = 0

## 缓存字典（文件路径 -> GDSVResource）
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
	_current_row = 0
	_type_converter = GDSVTypeConverter.new()


## 加载 GDSV 文件
func load_file(file_path: String) -> GDSVLoader:
	_file_path = file_path

	if not FileAccess.file_exists(file_path):
		var hint := ""
		if not Engine.is_editor_hint():
			hint = " (导出构建中请确保文件未被导出设置排除)"
		_errors.append("文件不存在: %s%s" % [_get_display_path(file_path), hint])
		return self

	return self


## 设置是否包含表头
func with_header(has_header: bool) -> GDSVLoader:
	_has_header = has_header
	return self


## 设置分隔符
func with_delimiter(delimiter: String) -> GDSVLoader:
	_delimiter = delimiter
	return self


## 设置字段类型
func with_type(field_name: StringName, type: GDSVFieldDefinition.FieldType) -> GDSVLoader:
	_field_types[field_name] = type
	return self


## 设置字段默认值
func with_default(field_name: StringName, default_value: Variant) -> GDSVLoader:
	_default_values[field_name] = default_value
	return self


## 设置必需字段
func with_required_fields(fields: Array[StringName]) -> GDSVLoader:
	_required_fields = fields
	return self


## 设置 CSV Schema
func with_schema(schema: GDSVSchema) -> GDSVLoader:
	_schema = schema
	return self


## 清除缓存
static func clear_cache() -> void:
	_cache.clear()
	_cache_order.clear()


## 解析所有数据
func parse_all() -> GDSVResource:
	if Engine.is_editor_hint():
		# 被动触发旧 *.translation 清理：仅在真正发生读取时执行，避免编辑器启动扫描期文件锁冲突。
		var plugin_script := _get_plugin_script()
		if plugin_script:
			plugin_script.request_legacy_translation_cleanup()

	var gdsv_resource: GDSVResource = GDSVResource.new()
	gdsv_resource.has_header = _has_header
	gdsv_resource.delimiter = _delimiter

	# 检查文件路径是否有效
	if _file_path.is_empty():
		gdsv_resource.add_error("未设置文件路径，请先调用 load_file()")
		return gdsv_resource

	# 检查缓存
	if _cache.has(_file_path):
		_update_cache_order(_file_path)
		return _cache[_file_path]

	# 读取文件内容
	var content := _read_file_content()
	if content.is_empty():
		gdsv_resource.add_error("文件内容为空或读取失败: %s" % _get_display_path(_file_path))
		return gdsv_resource

	# 使用 GDSVDataProcessor 处理数据
	if not gdsv_data_processor:
		gdsv_data_processor = GDSVDataProcessor.new()

	gdsv_data_processor.default_delimiter = _delimiter
	var success := gdsv_data_processor.load_gdsv_content(content, _file_path, {"trim_on_load": true})

	if not success or gdsv_data_processor.has_error:
		var error_msg := gdsv_data_processor.last_error if gdsv_data_processor.last_error else "未知错误"
		gdsv_resource.add_error(error_msg)
		return gdsv_resource

	# 更新资源数据
	gdsv_resource.headers = gdsv_data_processor.get_header()
	gdsv_resource.total_rows = gdsv_data_processor.get_row_count()
	gdsv_resource.successful_rows = gdsv_data_processor.get_row_count()
	gdsv_resource.failed_rows = 0

	# 添加所有行数据
	var all_rows := gdsv_data_processor.get_all_rows()
	for row in all_rows:
		gdsv_resource.add_raw_row(row)
		gdsv_resource.add_row(_convert_row_to_dict(row, _build_header_indices(gdsv_resource.headers), 0)[0])

	# 缓存结果
	_add_to_cache(_file_path, gdsv_resource)

	# 输出解析统计
	_log_statistics(gdsv_resource)

	return gdsv_resource


## 创建流式读取器
func stream() -> RefCounted:
	if Engine.is_editor_hint():
		# 被动触发旧 *.translation 清理：仅在真正发生读取时执行，避免编辑器启动扫描期文件锁冲突。
		var plugin_script := _get_plugin_script()
		if plugin_script:
			plugin_script.request_legacy_translation_cleanup()

	var reader := _GDSV_STREAM_READER_SCRIPT.new(_file_path, _has_header, _delimiter)

	# 应用字段类型
	for field_name in _field_types:
		reader.set_field_type(field_name, _field_types[field_name])

	# 应用默认值
	for field_name in _default_values:
		reader.set_default_value(field_name, _default_values[field_name])

	# 应用必需字段
	reader.set_required_fields(_required_fields)

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
		if content.unicode_at(0) == 0xFEFF: # UTF-8 BOM
			content = content.substr(1)

	return content


## 建立字段名到列索引的映射
func _build_header_indices(header_row: PackedStringArray) -> Dictionary:
	var indices := {}
	for i in range(header_row.size()):
		var field_name: StringName = StringName(header_row[i].strip_edges())
		indices[field_name] = i
	return indices


## 转换行数据为字典格式，同时处理多余字段并扩展表头
func _convert_row_to_dict(row: PackedStringArray, header_indices: Dictionary, row_index: int) -> Array:
	var dict := {}

	# 处理已知列
	for field_name in header_indices:
		var col_index: int = header_indices[field_name] as int
		if col_index < row.size():
			var value := row[col_index].strip_edges()
			if not value.is_empty():
				dict[field_name] = value

	_total_rows += 1
	_successful_rows += 1

	# 处理多余字段，自动扩展表头
	var extended_header := PackedStringArray()
	var extended_indices := {}

	if row.size() > header_indices.size():
		var existing_col_names := header_indices.keys()
		var start_index := header_indices.size()

		for i in range(start_index, row.size()):
			var col_name := "Column_" + str(i + 1)
			var suffix := 1

			# 确保列名唯一（避免与已存在列名冲突）
			while col_name in existing_col_names or col_name in extended_indices:
				col_name = "Column_" + str(i + 1) + "_" + str(suffix)
				suffix += 1

			var value := row[i].strip_edges()
			if not value.is_empty():
				dict[col_name] = value

			extended_header.append(col_name)
			extended_indices[col_name] = i

	return [dict, extended_header, extended_indices]


## 添加到缓存
func _add_to_cache(path: String, resource: GDSVResource) -> void:
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
func _log_statistics(resource: GDSVResource) -> void:
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
