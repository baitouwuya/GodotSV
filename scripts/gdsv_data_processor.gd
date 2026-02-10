class_name GDSVDataProcessor
extends Node

## GDSV 数据处理器，封装所有 C++ 模块的 GDScript 接口
## 提供统一的错误处理和类型安全的 API 设计

#region 信号 Signals
signal file_loaded(success: bool, error_message: String)
signal file_saved(success: bool, error_message: String)
signal data_changed(change_type: String, details: Dictionary)
signal validation_completed(results: Array)
signal search_completed(match_count: int, search_time: float)
#endregion

#region 常量 Constants
const ERROR_FILE_NOT_FOUND = "文件未找到"
const ERROR_INVALID_FORMAT = "GDSV 格式无效"
const ERROR_VALIDATION_FAILED = "数据验证失败"
const ERROR_CONVERSION_FAILED = "类型转换失败"
const ERROR_SEARCH_FAILED = "搜索失败"
#endregion

#region 导出变量 Export Variables
## 是否自动去除单元格首尾空格
@export var auto_trim_whitespace: bool = true

## 默认 GDSV 分隔符
@export var default_delimiter: String = ","
#endregion

#region 公共变量 Public Variables
## 最后的文件路径
var last_file_path: String = ""

## 最后的文件修改时间
var last_file_modified_time: int = 0

## 最后的错误信息
var last_error: String = ""

## 是否有错误
var has_error: bool = false

## 原始文件扩展名（用于保存时保留）
var original_file_extension: String = ".gdsv"
#endregion

#region 私有变量 Private Variables
## C++ GDSV 解析器实例
var _gdsv_parser: GDSVParser

## C++ 类型标注解析器实例
var _type_annotation_parser: GDSVTypeAnnotationParser

## C++ 类型转换器实例
var _type_converter: GDSVTypeConverter

## C++ 数据验证器实例
var _data_validator: GDSVDataValidator

## C++ 搜索引擎实例
var _search_engine: GDSVSearchEngine

## C++ 表格数据实例
var _table_data: GDSVTableData

## 原始表头（带类型标注）
var _original_header: PackedStringArray

## 清理后的表头（去除类型标注）
var _cleaned_header: PackedStringArray
#endregion

#region 生命周期方法 Lifecycle Methods
func _init() -> void:
	_initialize_cpp_objects()

func _ready() -> void:
	pass
#endregion

#region 初始化功能 Initialization Features
func _initialize_cpp_objects() -> void:
	_gdsv_parser = GDSVParser.new()
	_type_annotation_parser = GDSVTypeAnnotationParser.new()
	_type_converter = GDSVTypeConverter.new()
	_data_validator = GDSVDataValidator.new()
	_search_engine = GDSVSearchEngine.new()
	_table_data = GDSVTableData.new()


func reset() -> void:
	_reset_error_state()
	_original_header.clear()
	_cleaned_header.clear()
	_table_data.clear()
#endregion

#region 文件加载功能 File Loading Features
## 加载 GDSV 文件
func load_gdsv_file(file_path: String) -> bool:
	_reset_error_state()
	
	if not FileAccess.file_exists(file_path):
		_set_error(ERROR_FILE_NOT_FOUND)
		file_loaded.emit(false, last_error)
		return false

	# 存储原始文件扩展名
	if file_path.contains("."):
		original_file_extension = "." + file_path.get_extension()
	else:
		original_file_extension = ".gdsv"

	# 基于后缀自动推断分隔符（用于 .gdsv/.tsv/.tab 等）
	default_delimiter = _infer_default_delimiter_for_file(file_path)
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		_set_error("无法打开文件: " + file_path)
		file_loaded.emit(false, last_error)
		return false
	
	var content := file.get_as_text()
	file.close()
	
	return load_gdsv_content(content, file_path)


## 加载 GDSV 内容字符串
func load_gdsv_content(content: String, file_path: String = "") -> bool:
	_reset_error_state()
	
	if content.is_empty():
		_set_error(ERROR_INVALID_FORMAT)
		file_loaded.emit(false, last_error)
		return false

	# 兼容：去除 UTF-8 BOM
	if content.length() >= 1 and content.unicode_at(0) == 0xFEFF:
		content = content.substr(1)

	# 兼容：当文件包含表头时，允许在表头前出现注释/空行
	# 注意：GDSVParser 会按“行索引 i==0”来判断表头，因此这里要先把前置注释/空行移除。
	var normalized_content := content
	var lines := normalized_content.split("\n", false)
	if not lines.is_empty():
		var start_idx := 0
		while start_idx < lines.size():
			var line := lines[start_idx].strip_edges()
			if line.is_empty() or line.begins_with("#"):
				start_idx += 1
				continue
			break
		if start_idx > 0:
			normalized_content = "\n".join(lines.slice(start_idx))
	
	var gdsv_data: Array = _gdsv_parser.parse_from_string(normalized_content, true, default_delimiter)

	if _gdsv_parser.has_error():
		_set_error(_gdsv_parser.get_last_error())
		file_loaded.emit(false, last_error)
		return false

	_original_header = _gdsv_parser.get_header()
	_cleaned_header = _extract_clean_header()

	var rows: Array[PackedStringArray] = []
	for row in gdsv_data:
		if row is PackedStringArray:
			rows.append(row)
	_table_data.initialize(rows, _cleaned_header)
	_normalize_table_shape()
	
	if auto_trim_whitespace:
		_trim_all_cells()
	
	last_file_path = file_path
	
	# 如果有文件路径，更新文件扩展名
	if not file_path.is_empty():
		if file_path.contains("."):
			original_file_extension = "." + file_path.get_extension()
		else:
			original_file_extension = ".gdsv"
	
	# 记录文件修改时间
	if not file_path.is_empty() and FileAccess.file_exists(file_path):
		last_file_modified_time = FileAccess.get_modified_time(file_path)
	
	file_loaded.emit(true, "")
	data_changed.emit("load", {"file_path": file_path})
	
	return true
#endregion

#region 文件保存功能 File Saving Features
## 保存 GDSV 文件
func save_gdsv_file(file_path: String) -> bool:
	_reset_error_state()

	# 重要：按调用方传入的路径原样保存。
	# 之前的“同路径强制改回 original_file_extension”会导致：
	# - 用户以为保存的是 `xxx.csv/xxx.gdsv`，实际写到了另一个后缀文件
	# - 表现为“点保存并关闭了，但磁盘文件没变化”（其实写到了另一个文件）
	# 因此仅在“完全没有扩展名”时才补默认扩展名。
	if file_path.get_extension().is_empty():
		file_path = file_path + original_file_extension

	# 保存时使用目标路径的后缀推断分隔符（与加载逻辑一致），避免：
	# - 打开的是 .gdsv/.tsv（tab 分隔），保存时却写成逗号分隔，导致看起来“没正确写入”
	default_delimiter = _infer_default_delimiter_for_file(file_path)

	var content := get_gdsv_string()
	if content.is_empty():
		_set_error("没有数据可保存")
		file_saved.emit(false, last_error)
		return false
	
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		_set_error("无法写入文件: " + file_path)
		file_saved.emit(false, last_error)
		return false
	
	file.store_string(content)
	file.close()
	
	last_file_path = file_path
	
	# 记录文件修改时间
	if FileAccess.file_exists(file_path):
		last_file_modified_time = FileAccess.get_modified_time(file_path)
	
	file_saved.emit(true, "")
	return true


## 检查文件是否被外部修改
func is_file_modified_externally() -> bool:
	if last_file_path.is_empty():
		return false
	
	if not FileAccess.file_exists(last_file_path):
		return false
	
	var current_modified_time := FileAccess.get_modified_time(last_file_path)
	return current_modified_time != last_file_modified_time


## 获取文件修改时间
func get_file_modified_time(file_path: String) -> int:
	if FileAccess.file_exists(file_path):
		return FileAccess.get_modified_time(file_path)
	return 0


## 获取 GDSV 字符串
func get_gdsv_string() -> String:
	var rows: Array[PackedStringArray] = _get_all_rows_internal()
	if rows.is_empty():
		return ""
	
	var gdsv_lines := PackedStringArray()

	gdsv_lines.append(_join_gdsv_row(_original_header))

	for row in rows:
		gdsv_lines.append(_join_gdsv_row(row))

	return "\n".join(gdsv_lines)
#endregion

#region 导入导出功能 Import/Export Features
## 导入 TSV 文件
func import_tsv_file(file_path: String) -> bool:
	_reset_error_state()
	
	if not FileAccess.file_exists(file_path):
		_set_error("文件不存在: " + file_path)
		return false
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		_set_error("无法打开文件: " + file_path)
		return false
	
	var content := file.get_as_text()
	file.close()
	
	# 将TSV转换为GDSV格式
	var gdsv_content := _tsv_to_gdsv(content)

	return load_gdsv_content(gdsv_content, file_path)


## TSV 转换为 GDSV
func _tsv_to_gdsv(tsv_content: String) -> String:
	var lines := tsv_content.split("\n")
	var gdsv_lines := PackedStringArray()

	for line in lines:
		if line.strip_edges().is_empty():
			continue

		# 替换制表符为逗号
		var gdsv_line := line.replace("\t", ",")
		gdsv_lines.append(gdsv_line)

	return "\n".join(gdsv_lines)


## 导出为 TSV 文件
func export_tsv_file(file_path: String) -> bool:
	_reset_error_state()
	
	var rows: Array[PackedStringArray] = _get_all_rows_internal()
	if rows.is_empty():
		_set_error("没有数据可导出")
		return false
	
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		_set_error("无法写入文件: " + file_path)
		return false
	
	# 导出表头
	file.store_string(_join_tsv_row(_original_header) + "\n")
	
	# 导出数据行
	for row in rows:
		file.store_string(_join_tsv_row(row) + "\n")
	
	file.close()
	return true


## 导入 JSON 文件
func import_json_file(file_path: String) -> bool:
	_reset_error_state()
	
	if not FileAccess.file_exists(file_path):
		_set_error("文件不存在: " + file_path)
		return false
	
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		_set_error("无法打开文件: " + file_path)
		return false
	
	var content := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(content)
	
	if parse_result != OK:
		_set_error("JSON解析失败: " + json.get_error_message())
		return false
	
	var data: Variant = json.data
	
	# 检查数据格式
	if not data is Array:
		_set_error("JSON数据格式错误：应为数组")
		return false
	
	if data.is_empty():
		_set_error("JSON数据为空")
		return false
	
	# 提取表头
	var first_item: Variant = data[0]
	if first_item is Dictionary:
		_original_header = PackedStringArray(first_item.keys())
	else:
		_set_error("JSON数据格式错误：应为对象数组")
		return false

	# JSON 不包含内联类型标注，这里保持原始表头与清理表头一致
	_cleaned_header = _extract_clean_header()
	
	# 提取数据行
	var rows: Array = []
	for item in data:
		if item is Dictionary:
			var row: PackedStringArray = PackedStringArray()
			for key in _original_header:
				var value: Variant = item.get(key, "")
				row.append(str(value))
			rows.append(row)
	
	_table_data.initialize(rows, _cleaned_header)
	_normalize_table_shape()

	if auto_trim_whitespace:
		_trim_all_cells()

	last_file_path = file_path

	# 记录文件修改时间
	if FileAccess.file_exists(file_path):
		last_file_modified_time = FileAccess.get_modified_time(file_path)
	
	file_loaded.emit(true, "")
	data_changed.emit("import", {"file_path": file_path})
	
	return true


## 导出为 JSON 文件
func export_json_file(file_path: String) -> bool:
	_reset_error_state()
	
	var rows: Array[PackedStringArray] = _get_all_rows_internal()
	if rows.is_empty():
		_set_error("没有数据可导出")
		return false
	
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		_set_error("无法写入文件: " + file_path)
		return false
	
	# 构建JSON数据数组
	var json_data: Array = []
	for row in rows:
		var item: Dictionary = {}
		for i in range(_original_header.size()):
			if i < row.size():
				item[_original_header[i]] = row[i]
			else:
				item[_original_header[i]] = ""
		json_data.append(item)
	
	# 转换为JSON字符串
	var json_string := JSON.stringify(json_data, "\t")
	
	file.store_string(json_string)
	file.close()
	return true


## TSV 行拼接
func _join_tsv_row(row: PackedStringArray) -> String:
	var tsv_values := []
	
	for value in row:
		# TSV不需要特殊处理引号
		tsv_values.append(value)
	
	return "\t".join(tsv_values)
#endregion

#region 数据查询功能 Data Query Features
## 获取表格行数
func get_row_count() -> int:
	return _table_data.get_row_count()


## 获取表格列数
func get_column_count() -> int:
	return _table_data.get_column_count()


## 获取表头
func get_header() -> PackedStringArray:
	return _cleaned_header.duplicate()


## 获取原始表头（带类型标注）
func get_original_header() -> PackedStringArray:
	return _original_header.duplicate()


## 获取指定行
func get_row(row_index: int) -> PackedStringArray:
	return _table_data.get_row(row_index)


## 获取指定列
func get_column(column_index: int) -> PackedStringArray:
	return _table_data.get_column(column_index)


## 获取单元格值
func get_cell_value(row_index: int, column_index: int) -> String:
	return _table_data.get_cell_value(row_index, column_index)


## 获取所有行
func get_all_rows() -> Array[PackedStringArray]:
	return _get_all_rows_internal()


## 内部方法：从C++获取所有行（C++方法名为get_rows）
func _get_all_rows_internal() -> Array[PackedStringArray]:
	if not _table_data:
		return []
	var result: Array[PackedStringArray] = []
	var raw_rows: Array = _table_data.get_rows()
	for row in raw_rows:
		if row is PackedStringArray:
			result.append(row)
	return result
#endregion

#region 数据修改功能 Data Modification Features
## 设置单元格值
func set_cell_value(row_index: int, column_index: int, value: String) -> bool:
	if auto_trim_whitespace:
		value = value.strip_edges()
	
	var success: bool = _table_data.set_cell_value(row_index, column_index, value)
	if success:
		data_changed.emit("cell", {"row": row_index, "column": column_index, "value": value})
	
	return success


## 批量设置单元格
func batch_set_cells(cells: Array) -> int:
	if auto_trim_whitespace:
		for cell_data in cells:
			if cell_data is Dictionary and cell_data.has("value"):
				cell_data.value = str(cell_data.value).strip_edges()
	
	var count: int = _table_data.batch_set_cells(cells)
	if count > 0:
		data_changed.emit("batch", {"count": count})
	
	return count


## 插入行
func insert_row(row_index: int, row_data: PackedStringArray) -> bool:
	if auto_trim_whitespace:
		for i in range(row_data.size()):
			row_data[i] = row_data[i].strip_edges()
	
	var success: bool = _table_data.insert_row(row_index, row_data)
	if success:
		data_changed.emit("insert_row", {"row": row_index})
	
	return success


## 删除行
func remove_row(row_index: int) -> bool:
	var success: bool = _table_data.remove_row(row_index)
	if success:
		data_changed.emit("remove_row", {"row": row_index})
	
	return success


## 移动行
func move_row(from_index: int, to_index: int) -> bool:
	var success: bool = _table_data.move_row(from_index, to_index)
	if success:
		data_changed.emit("move_row", {"from": from_index, "to": to_index})
	
	return success


func _normalize_table_shape() -> void:
	if not _table_data:
		return

	_table_data.resize(_table_data.get_row_count(), _table_data.get_column_count(), "")


func _ensure_headers_synced() -> void:
	if not _table_data:
		return

	var col_count: int = _table_data.get_column_count()

	if _original_header.size() != col_count:
		if _cleaned_header.size() == col_count:
			_original_header = _cleaned_header.duplicate()
		else:
			_original_header = PackedStringArray()
			for i in range(col_count):
				_original_header.append("Column_" + str(i + 1))

	if _cleaned_header.size() != col_count:
		if _original_header.size() == col_count and not _original_header.is_empty():
			_cleaned_header = _extract_clean_header()
		else:
			_cleaned_header = _original_header.duplicate()


## 插入列
func insert_column(column_index: int, column_name: String, default_value: String = "") -> bool:
	_normalize_table_shape()
	_ensure_headers_synced()
	column_index = clampi(column_index, 0, _table_data.get_column_count())

	var success: bool = _table_data.insert_column(column_index, column_name, default_value)
	if success:
		_original_header.insert(column_index, column_name)
		_cleaned_header.insert(column_index, column_name)
		data_changed.emit("insert_column", {"column": column_index, "name": column_name})
	
	return success


## 删除列
func remove_column(column_index: int) -> bool:
	_normalize_table_shape()
	_ensure_headers_synced()
	if _table_data.get_column_count() <= 0:
		return false
	column_index = clampi(column_index, 0, _table_data.get_column_count() - 1)

	var success: bool = _table_data.remove_column(column_index)
	if success:
		_original_header.remove_at(column_index)
		_cleaned_header.remove_at(column_index)
		data_changed.emit("remove_column", {"column": column_index})
	
	return success


## 移动列
func move_column(from_index: int, to_index: int) -> bool:
	_normalize_table_shape()
	_ensure_headers_synced()

	var success: bool = _table_data.move_column(from_index, to_index)
	if success:
		var temp_header := _original_header[from_index]
		_original_header.remove_at(from_index)
		_original_header.insert(to_index, temp_header)
		
		temp_header = _cleaned_header[from_index]
		_cleaned_header.remove_at(from_index)
		_cleaned_header.insert(to_index, temp_header)
		
		data_changed.emit("move_column", {"from": from_index, "to": to_index})
	
	return success


## 重命名列（仅修改表头，不改变数据内容）
func rename_column(column_index: int, new_name: String) -> bool:
	_normalize_table_shape()
	_ensure_headers_synced()

	if _table_data.get_column_count() <= 0:
		return false

	column_index = clampi(column_index, 0, _table_data.get_column_count() - 1)
	new_name = new_name.strip_edges()
	if new_name.is_empty():
		return false

	var old_name := _cleaned_header[column_index] if column_index < _cleaned_header.size() else ""
	if new_name == old_name:
		return true

	if column_index < _original_header.size():
		_original_header[column_index] = new_name
	if column_index < _cleaned_header.size():
		_cleaned_header[column_index] = new_name

	# 同步更新 C++ TableData 内的 header_
	if _table_data:
		_table_data.initialize(_table_data.get_rows(), _cleaned_header)

	data_changed.emit("rename_column", {"column": column_index, "old_name": old_name, "name": new_name})
	return true
#endregion

#region 类型标注解析功能 Type Annotation Features
## 解析类型标注
func parse_type_annotations(header_row: PackedStringArray) -> Array:
	_reset_error_state()

	# 优先解析 GDSV 列定义（<name>[:<type>][=<default>])
	var gdsv_parser := GDSVColumnParser.new()
	if gdsv_parser.has_gdsv_syntax(header_row):
		return parse_gdsv_definitions(header_row)
	
	# 使用C++解析器解析表头，返回清理后的字段名
	var cleaned_names: PackedStringArray = _type_annotation_parser.parse_header(header_row)
	
	var results: Array = []
	for i in range(cleaned_names.size()):
		var field_name: String = cleaned_names[i]
		var result: Dictionary = {
			"name": field_name,
			"type": _type_annotation_parser.get_field_type(field_name),
			"required": _type_annotation_parser.is_field_required(field_name),
			"default": _type_annotation_parser.get_field_default(field_name),
			"range": _type_annotation_parser.get_field_range(field_name),
			"enum_values": _type_annotation_parser.get_field_enum_values(field_name),
			"array_element_type": _type_annotation_parser.get_array_element_type(field_name)
		}
		results.append(result)
	
	return results


## 解析 GDSV 列定义（用于编辑器字段面板）
func parse_gdsv_definitions(header_row: PackedStringArray) -> Array:
	_reset_error_state()

	var gdsv_parser := GDSVColumnParser.new()
	var defs: Array = gdsv_parser.parse_header(header_row)
	if gdsv_parser.has_error():
		_set_error("GDSV syntax error: " + gdsv_parser.get_last_error())
		return []

	var results: Array = []
	for def in defs:
		var name := str(def.get("name", "")).strip_edges()
		if name.is_empty():
			continue

		var type_str := str(def.get("type", "")).strip_edges().to_lower()
		if type_str.is_empty():
			type_str = "string"

		var result: Dictionary = {
			"name": name,
			"type": type_str,
			"default": def.get("default_value", "")
		}
		results.append(result)

	return results


## 提取清理后的表头
func _extract_clean_header() -> PackedStringArray:
	# 使用C++解析器解析表头，返回清理后的字段名
	return _type_annotation_parser.parse_header(_original_header)
#endregion

#region 类型转换功能 Type Conversion Features
## 转换单元格值
func convert_cell_value(value: String, type_definition: Dictionary) -> Variant:
	_reset_error_state()
	
	var result: Variant = _type_converter.convert_value(value, type_definition)
	if result.is_empty() and _type_converter.has_error():
		_set_error(_type_converter.get_last_error())
	
	return result


## 批量转换行
func convert_row(row_data: PackedStringArray, type_definitions: Array) -> Array:
	_reset_error_state()
	
	var converted: Array = []
	for i in range(min(row_data.size(), type_definitions.size())):
		var value: Variant = convert_cell_value(row_data[i], type_definitions[i])
		converted.append(value)
	
	return converted
#endregion

#region 数据验证功能 Data Validation Features
## 验证单元格值
func validate_cell_value(value: String, row_index: int, column_index: int, type_definition: Dictionary) -> Dictionary:
	_reset_error_state()
	
	var field_name := str(type_definition.get("name", ""))
	if field_name.is_empty() and column_index >= 0 and column_index < _cleaned_header.size():
		field_name = str(_cleaned_header[column_index])
	var field_info := type_definition.duplicate()
	field_info["name"] = field_name
	field_info["type"] = str(type_definition.get("type", "string")).to_lower()
	var is_valid: bool = _data_validator.ValidateCell(value, field_name, field_info)
	
	if is_valid:
		return {}
	
	return {
		"row": row_index,
		"column": column_index,
		"field_name": field_name,
		"error_message": "数据验证失败",
		"value": value,
	}


## 验证整行
func validate_row(row_data: PackedStringArray, row_index: int, type_definitions: Array) -> Array:
	_reset_error_state()
	
	var errors: Array = []
	for i in range(min(row_data.size(), type_definitions.size())):
		var err: Dictionary = validate_cell_value(row_data[i], row_index, i, type_definitions[i])
		if not err.is_empty():
			errors.append(err)
	
	return errors


## 验证整表
func validate_all(type_definitions: Array) -> Array:
	_reset_error_state()
	
	if not _data_validator:
		validation_completed.emit([])
		return []
	
	var rows: Array[PackedStringArray] = _get_all_rows_internal()
	var header := get_header()
	var field_map := _build_field_map_from_type_definitions(header, type_definitions)
	
	_data_validator.ClearErrors()
	_data_validator.ValidateTable(rows, header, field_map)
	
	var errors: Array = _data_validator.GetErrors()
	validation_completed.emit(errors)
	return errors


func _build_field_map_from_type_definitions(header: PackedStringArray, type_definitions: Array) -> Dictionary:
	var field_map: Dictionary = {}
	
	for i in range(header.size()):
		var field_name := str(header[i])
		var def: Dictionary = type_definitions[i] if i < type_definitions.size() and type_definitions[i] is Dictionary else {}
		
		var field_info: Dictionary = {}
		field_info["name"] = field_name
		field_info["type"] = str(def.get("type", "string")).to_lower()
		if def.has("required"):
			field_info["required"] = bool(def.get("required", false))
		if def.has("default"):
			field_info["default"] = def.get("default")
		if def.has("range"):
			field_info["range"] = def.get("range")
		if def.has("enum_values"):
			field_info["enum_values"] = def.get("enum_values")
		if def.has("resource_type"):
			field_info["resource_type"] = str(def.get("resource_type", ""))
		
		field_map[field_name] = field_info
	
	return field_map
#endregion

#region 搜索功能 Search Features
## 搜索文本
func search_text(search_text: String, case_sensitive: bool = false, match_mode: int = 0, search_columns: PackedInt32Array = PackedInt32Array()) -> Array:
	_reset_error_state()
	
	var rows: Array[PackedStringArray] = _get_all_rows_internal()
	var results: Array = []
	
	# 简单实现：如果C++搜索引擎不可用，使用GDScript后备实现
	if _search_engine == null:
		for row_index in range(rows.size()):
			var row: PackedStringArray = rows[row_index]
			for col_index in range(row.size()):
				var cell_value: String = row[col_index]
				if not cell_value.is_empty():
					var should_match: bool = false
					if case_sensitive:
						if match_mode == 0: # MATCH_CONTAINS
							should_match = search_text in cell_value
						elif match_mode == 1: # MATCH_STARTS_WITH
							should_match = cell_value.begins_with(search_text)
						elif match_mode == 2: # MATCH_ENDS_WITH
							should_match = cell_value.ends_with(search_text)
					else:
						if match_mode == 0: # MATCH_CONTAINS
							should_match = search_text.to_lower() in cell_value.to_lower()
						elif match_mode == 1: # MATCH_STARTS_WITH
							should_match = cell_value.to_lower().begins_with(search_text.to_lower())
						elif match_mode == 2: # MATCH_ENDS_WITH
							should_match = cell_value.to_lower().ends_with(search_text.to_lower())
					
					if should_match:
						results.append({"row": row_index, "column": col_index, "value": cell_value})
		
		search_completed.emit(results.size(), 0.0)
		return results
	
	# 使用C++搜索引擎
	results = _search_engine.search(rows, search_text, case_sensitive, match_mode, search_columns)
	
	if _search_engine.has_error():
		_set_error(_search_engine.get_last_error())
		return []
	
	search_completed.emit(_search_engine.get_match_count(), _search_engine.get_search_time())
	
	return results


## 正则表达式搜索
func search_regex(pattern: String) -> Array:
	_reset_error_state()
	
	var rows: Array[PackedStringArray] = _get_all_rows_internal()
	var results: Array = []
	
	# GDScript后备实现
	if _search_engine == null:
		var regex := RegEx.new()
		var error := regex.compile(pattern)
		if error != OK:
			_set_error("正则表达式编译失败")
			return []
		
		for row_index in range(rows.size()):
			var row: PackedStringArray = rows[row_index]
			for col_index in range(row.size()):
				var cell_value: String = row[col_index]
				var regex_result := regex.search(cell_value)
				if regex_result != null:
					results.append({"row": row_index, "column": col_index, "value": cell_value})
		
		search_completed.emit(results.size(), 0.0)
		return results
	
	# 使用C++搜索引擎
	results = _search_engine.search_regex(rows, pattern)
	
	if _search_engine.has_error():
		_set_error(_search_engine.get_last_error())
		return []
	
	search_completed.emit(_search_engine.get_match_count(), _search_engine.get_search_time())
	
	return results


## 替换文本
func replace_text(search_text: String, replace_text: String, case_sensitive: bool = false, match_mode: int = 0, search_columns: PackedInt32Array = PackedInt32Array()) -> bool:
	_reset_error_state()
	
	var rows: Array[PackedStringArray] = _get_all_rows_internal()
	var new_rows: Array[PackedStringArray] = []
	var match_count: int = 0
	
	# GDScript后备实现
	if _search_engine == null:
		for row in rows:
			var new_row: PackedStringArray = row.duplicate()
			for col_index in range(new_row.size()):
				var cell_value: String = new_row[col_index]
				var should_replace: bool = false
				
				if case_sensitive:
					if match_mode == 0: # MATCH_CONTAINS
						should_replace = search_text in cell_value
					elif match_mode == 1: # MATCH_STARTS_WITH
						should_replace = cell_value.begins_with(search_text)
					elif match_mode == 2: # MATCH_ENDS_WITH
						should_replace = cell_value.ends_with(search_text)
				else:
					if match_mode == 0: # MATCH_CONTAINS
						should_replace = search_text.to_lower() in cell_value.to_lower()
					elif match_mode == 1: # MATCH_STARTS_WITH
						should_replace = cell_value.to_lower().begins_with(search_text.to_lower())
					elif match_mode == 2: # MATCH_ENDS_WITH
						should_replace = cell_value.to_lower().ends_with(search_text.to_lower())
				
				if should_replace:
					if case_sensitive:
						new_row[col_index] = cell_value.replace(search_text, replace_text)
					else:
						# 不区分大小写的替换
						var lower_value = cell_value.to_lower()
						var lower_search = search_text.to_lower()
						var lower_replace = replace_text.to_lower()
						var result_str = ""
						var search_pos = 0
						while true:
							var found_pos = lower_value.find(lower_search, search_pos)
							if found_pos == -1:
								result_str += cell_value.substr(search_pos)
								break
							result_str += cell_value.substr(search_pos, found_pos - search_pos)
							result_str += replace_text
							search_pos = found_pos + search_text.length()
						new_row[col_index] = result_str
					match_count += 1
			new_rows.append(new_row)
		
		if match_count > 0:
			_table_data.clear()
			_table_data.initialize(new_rows, _cleaned_header)
			data_changed.emit("replace", {"count": match_count})
		
		return match_count > 0
	
	# 使用C++搜索引擎
	new_rows = _search_engine.replace(rows, search_text, replace_text, case_sensitive, match_mode, search_columns)
	
	if _search_engine.has_error():
		_set_error(_search_engine.get_last_error())
		return false
	
	_table_data.clear()
	_table_data.initialize(new_rows, _cleaned_header)
	
	data_changed.emit("replace", {"count": _search_engine.get_match_count()})
	
	return _search_engine.get_match_count() > 0


## 过滤行
func filter_rows(filter_text: String, case_sensitive: bool = false, match_mode: int = 0, filter_column: int = -1) -> PackedInt32Array:
	_reset_error_state()
	
	var rows: Array[PackedStringArray] = _get_all_rows_internal()
	var filtered: PackedInt32Array = PackedInt32Array()
	
	# GDScript后备实现
	if _search_engine == null:
		for row_index in range(rows.size()):
			var row: PackedStringArray = rows[row_index]
			var match_found: bool = false
			
			# 检查指定列
			if filter_column >= 0 and filter_column < row.size():
				var cell_value: String = row[filter_column]
				match_found = _check_match(cell_value, filter_text, case_sensitive, match_mode)
			else:
				# 检查所有列
				for cell_value in row:
					if _check_match(cell_value, filter_text, case_sensitive, match_mode):
						match_found = true
						break
			
			if match_found:
				filtered.append(row_index)
		
		return filtered
	
	# 使用C++搜索引擎
	filtered = _search_engine.filter_rows(rows, filter_text, case_sensitive, match_mode, filter_column)
	
	if _search_engine.has_error():
		_set_error(_search_engine.get_last_error())
		return PackedInt32Array()
	
	return filtered


## 检查匹配的辅助函数
func _check_match(cell_value: String, search_text: String, case_sensitive: bool, match_mode: int) -> bool:
	if case_sensitive:
		if match_mode == 0: # MATCH_CONTAINS
			return search_text in cell_value
		elif match_mode == 1: # MATCH_STARTS_WITH
			return cell_value.begins_with(search_text)
		elif match_mode == 2: # MATCH_ENDS_WITH
			return cell_value.ends_with(search_text)
	else:
		if match_mode == 0: # MATCH_CONTAINS
			return search_text.to_lower() in cell_value.to_lower()
		elif match_mode == 1: # MATCH_STARTS_WITH
			return cell_value.to_lower().begins_with(search_text.to_lower())
		elif match_mode == 2: # MATCH_ENDS_WITH
			return cell_value.to_lower().ends_with(search_text.to_lower())
	return false
#endregion

#region 工具方法 Utility Methods
## 重置错误状态
func _reset_error_state() -> void:
	last_error = ""
	has_error = false


## 设置错误
func _set_error(error_message: String) -> void:
	last_error = error_message
	has_error = true
	push_error("GDSVDataProcessor: " + error_message)


## 去除所有单元格的首尾空格
func _trim_all_cells() -> void:
	var rows: Array[PackedStringArray] = _get_all_rows_internal()
	var trim_cells: Array = []
	
	for row_index in range(rows.size()):
		var row_data: PackedStringArray = rows[row_index]
		for column_index in range(row_data.size()):
			trim_cells.append({
				"row": row_index,
				"column": column_index,
				"value": row_data[column_index].strip_edges()
			})
	
	if not trim_cells.is_empty():
		_table_data.batch_set_cells(trim_cells)


## 将行数据转换为 GDSV 行字符串
func _join_gdsv_row(row_data: PackedStringArray) -> String:
	var escaped_cells := PackedStringArray()
	var delimiter := default_delimiter
	if delimiter.is_empty():
		delimiter = ","

	for cell in row_data:
		var cell_str := str(cell)

		# 需要加引号的情况：包含分隔符 / 换行 / 双引号
		if cell_str.contains(delimiter) or cell_str.contains("\n") or cell_str.contains("\""):
			cell_str = "\"" + cell_str.replace("\"", "\"\"") + "\""

		escaped_cells.append(cell_str)

	return delimiter.join(escaped_cells)


## 检查索引是否有效
func is_valid_index(row_index: int, column_index: int) -> bool:
	return _table_data.is_valid_index(row_index, column_index)


## 清空数据
func clear_data() -> void:
	_table_data.clear()
	_original_header.clear()
	_cleaned_header.clear()
	data_changed.emit("clear", {})


## 基于后缀推断默认分隔符（编辑器内打开文件用）
func _infer_default_delimiter_for_file(file_path: String) -> String:
	var ext := file_path.get_extension().to_lower()
	match ext:
		"gdsv", "tsv", "tab", "asc":
			return "\t"
		"psv":
			return "|"
		_:
			return ","
#endregion
