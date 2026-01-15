@tool
class_name CSVImportPlugin
extends EditorImportPlugin

## CSV 文件导入插件，将 CSV 文件导入为 CSVResource 资源

const _GODOTSV_PLUGIN_SCRIPT := preload("res://addons/GodotSV/plugin.gd")


func _get_importer_name() -> String:
	return "godotsv.importer"


func _get_visible_name() -> String:
	return "CSV Data"


func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["csv"])


func _get_save_extension() -> String:
	return "res"


func _get_resource_type() -> String:
	# 返回基础类型以避免编辑器在加载导入产物前对“自定义脚本类名”做严格匹配，
	# 否则在某些时序下会出现 “No loader found ... expected type: CSVResource”。
	# 实际加载出的资源仍会是 csv_resource.gd 脚本实例（CSVResource）。
	return "Resource"


func _get_priority() -> float:
	return 10.0


func _get_import_options(path: String, preset_index: int) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	
	options.append({
		"name": "has_header",
		"default_value": true,
		"property_hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_EDITOR_INSTANTIATE_OBJECT,
		"type": TYPE_BOOL
	})
	
	options.append({
		"name": "delimiter",
		"default_value": ",",
		"property_hint": PROPERTY_HINT_NONE,
		"hint_string": "",
		"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_EDITOR_INSTANTIATE_OBJECT,
		"type": TYPE_STRING
	})
	
	options.append({
		"name": "encoding",
		"default_value": 0,
		"property_hint": PROPERTY_HINT_ENUM,
		"hint_string": "UTF-8,UTF-16",
		"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_EDITOR_INSTANTIATE_OBJECT,
		"type": TYPE_INT
	})
	
	options.append({
		"name": "schema_path",
		"default_value": "",
		"property_hint": PROPERTY_HINT_FILE,
		"hint_string": "*.tres",
		"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_EDITOR_INSTANTIATE_OBJECT,
		"type": TYPE_STRING
	})
	
	return options


func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return true


func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array[String], gen_files: Array[String]) -> Error:
	# 被动触发旧 *.translation 清理：仅在真正发生导入时执行，避免编辑器启动扫描期文件锁冲突。
	_GODOTSV_PLUGIN_SCRIPT.request_legacy_translation_cleanup()

	# 创建 CSVLoader 实例
	var loader: CSVLoader = CSVLoader.new()
	
	# 应用导入选项
	var has_header: bool = bool(options.get("has_header", true))
	var delimiter: String = str(options.get("delimiter", ","))
	
	loader.load_file(source_file)
	loader.with_header(has_header)
	loader.with_delimiter(delimiter)
	
	# 如果指定了 Schema，应用 Schema
	var schema_path := options.get("schema_path", "")
	if not schema_path.is_empty():
		if ResourceLoader.exists(schema_path):
			var schema: CSVSchema = load(schema_path)
			if schema != null:
				loader.with_schema(schema)
		else:
			push_warning("CSV 导入警告: Schema 文件不存在: %s" % schema_path)
	
	# 解析 CSV 数据
	var csv_resource: CSVResource = loader.parse_all()
	csv_resource.source_csv_path = source_file
	
	# 检查是否有错误
	if csv_resource.has_errors():
		var errors: Array[String] = csv_resource.get_errors()
		for error: String in errors:
			push_error("CSV 导入错误 (%s): %s" % [source_file, error])
		return ERR_PARSE_ERROR
	
	# 保存资源
	var save_path_str := "%s.%s" % [save_path, _get_save_extension()]
	var result := ResourceSaver.save(csv_resource, save_path_str)
	
	if result != OK:
		push_error("CSV 导入失败: 无法保存资源到 %s (错误码: %d)" % [save_path_str, result])
		return result
	
	return OK
