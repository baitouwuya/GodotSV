class_name SchemaManager
extends Node

## Schema 管理器，负责 Schema 文件的检测、加载、解析和应用
## 支持外部 Schema 文件和内联类型标注的优先级处理

#region 信号 Signals
## Schema 加载完成
signal schema_loaded(schema_path: String)

## Schema 卸载完成
signal schema_unloaded()

## Schema 验证完成
signal schema_validated(is_valid: bool, errors: Array[Dictionary])

## 类型定义变化
signal type_definitions_changed(definitions: Array)

## 文件变化检测
signal schema_file_changed(schema_path: String)
#endregion

#region 常量 Constants
## Schema 文件扩展名
const SCHEMA_EXTENSIONS: PackedStringArray = [".json", ".csv.schema", ".schema"]

## 自动检测的 Schema 文件名
const AUTO_DETECT_SCHEMA_NAMES: PackedStringArray = ["schema.json", "data.schema", ".csv.schema"]

## Schema 文件监控间隔（秒）
const FILE_WATCH_INTERVAL: float = 1.0
#endregion

#region 私有变量 Private Variables
## 当前加载的 Schema 文件路径
var _current_schema_path: String = ""

## Schema 数据
var _schema_data: Dictionary = {}

## 类型定义数组（每列一个 Dictionary）
var _type_definitions: Array[Dictionary] = []

## 文件监控器
var _file_watcher: Timer

## Schema 文件最后修改时间
var _schema_file_mod_time: int = 0

## 是否使用外部 Schema 优先
var _external_schema_priority: bool = true

## 数据处理器引用
var _data_processor: GDSVDataProcessor

## 状态管理器引用
var _state_manager: GDSVStateManager
#endregion

#region 生命周期方法 Lifecycle Methods
func _init() -> void:
	_initialize_file_watcher()


func _ready() -> void:
	if _file_watcher:
		add_child(_file_watcher)


func _exit_tree() -> void:
	if _file_watcher:
		_file_watcher.queue_free()
		_file_watcher = null
#endregion

#region 初始化功能 Initialization Features
## 初始化文件监控器
func _initialize_file_watcher() -> void:
	_file_watcher = Timer.new()
	_file_watcher.wait_time = FILE_WATCH_INTERVAL
	_file_watcher.autostart = false
	_file_watcher.timeout.connect(_on_file_watcher_timeout)


## 设置数据处理器
func set_data_processor(processor: GDSVDataProcessor) -> void:
	_data_processor = processor


## 设置状态管理器
func set_state_manager(manager: GDSVStateManager) -> void:
	_state_manager = manager
#endregion

#region Schema加载功能 Schema Loading Features
## 自动检测 Schema 文件
func auto_detect_schema(csv_file_path: String) -> String:
	if csv_file_path.is_empty():
		return ""
	
	# 获取 CSV 文件所在目录
	var base_dir := csv_file_path.get_base_dir()
	var file_name := csv_file_path.get_file().get_basename()
	
	# 1. 检查同名的 .schema 文件
	var schema_path := base_dir.path_join(file_name + ".schema")
	if FileAccess.file_exists(schema_path):
		return schema_path
	
	# 2. 检查 .csv.schema 文件
	schema_path = base_dir.path_join(file_name + ".csv.schema")
	if FileAccess.file_exists(schema_path):
		return schema_path
	
	# 3. 检查自动检测的 Schema 文件名
	for schema_name in AUTO_DETECT_SCHEMA_NAMES:
		schema_path = base_dir.path_join(schema_name)
		if FileAccess.file_exists(schema_path):
			return schema_path
	
	return ""


## 加载 Schema 文件
func load_schema(schema_path: String) -> bool:
	if schema_path.is_empty():
		push_error("Schema 文件路径为空")
		return false
	
	if not FileAccess.file_exists(schema_path):
		push_error("Schema 文件不存在: " + schema_path)
		return false
	
	# 读取文件内容
	var file := FileAccess.open(schema_path, FileAccess.READ)
	if file == null:
		push_error("无法打开 Schema 文件: " + schema_path)
		return false
	
	var content := file.get_as_text()
	file.close()
	
	# 解析 JSON
	var json := JSON.new()
	var error := json.parse(content)
	if error != OK:
		push_error("Schema 文件解析失败: " + json.get_error_message())
		return false
	
	if not json.data is Dictionary:
		push_error("Schema 文件格式错误，应为 JSON 对象")
		return false
	
	_schema_data = json.data
	
	# 验证 Schema
	if not _validate_schema():
		return false
	
	# 解析类型定义
	_parse_type_definitions()
	
	# 应用 Schema
	_apply_schema()
	
	# 记录文件修改时间
	_record_schema_mod_time(schema_path)
	
	# 启动文件监控
	_start_file_watcher(schema_path)
	
	_current_schema_path = schema_path
	
	schema_loaded.emit(schema_path)
	type_definitions_changed.emit(_type_definitions)
	
	print("Schema 加载成功: ", schema_path)
	return true


## 卸载 Schema
func unload_schema() -> void:
	_current_schema_path = ""
	_schema_data.clear()
	_type_definitions.clear()
	
	if _file_watcher:
		_file_watcher.stop()
	
	# 从内联类型标注恢复（表头可能包含类型标注）
	_load_inline_type_annotations()
	
	schema_unloaded.emit()
	type_definitions_changed.emit(_type_definitions)
	
	print("Schema 已卸载")


func _load_inline_type_annotations() -> void:
	if not _data_processor or not _state_manager:
		return
	var header := _data_processor.get_original_header()
	if header.is_empty():
		_state_manager.set_type_definitions([])
		return
	var definitions := _data_processor.parse_type_annotations(header)
	_state_manager.set_type_definitions(definitions)


## 重新加载 Schema
func reload_schema() -> bool:
	if _current_schema_path.is_empty():
		return false
	
	var schema_path := _current_schema_path
	unload_schema()
	return load_schema(schema_path)
#endregion

#region Schema解析功能 Schema Parsing Features
## 验证 Schema 格式
func _validate_schema() -> bool:
	if not _schema_data.has("fields"):
		push_error("Schema 缺少 'fields' 字段")
		return false
	
	if not _schema_data.fields is Array:
		push_error("'fields' 字段应为数组")
		return false
	
	if _schema_data.fields.is_empty():
		push_warning("Schema 没有定义任何字段")
	
	return true


## 解析类型定义
func _parse_type_definitions() -> void:
	_type_definitions.clear()
	
	if not _schema_data.has("fields"):
		return
	
	var fields: Array = _schema_data.fields as Array

	for field in fields:
		if not field is Dictionary:
			continue

		var definition: Dictionary = {}

		if field.has("name"):
			definition["name"] = str(field.name)
		if field.has("type"):
			definition["type"] = str(field.type)
		if field.has("required"):
			definition["required"] = bool(field.required)
		if field.has("default_value"):
			definition["default"] = field.default_value
		if field.has("description"):
			definition["description"] = str(field.description)

		if field.has("constraints") and field.constraints is Dictionary:
			var constraints: Dictionary = field.constraints as Dictionary
			if constraints.has("min"):
				definition["min"] = constraints.min
			if constraints.has("max"):
				definition["max"] = constraints.max
			if constraints.has("min_length"):
				definition["min_length"] = constraints.min_length
			if constraints.has("max_length"):
				definition["max_length"] = constraints.max_length
			if constraints.has("pattern"):
				definition["pattern"] = str(constraints.pattern)

		if field.has("enum_values") and field.enum_values is Array:
			definition["enum_values"] = field.enum_values

		if field.has("array_type"):
			definition["array_element_type"] = field.array_type

		if not definition.has("name"):
			continue
		if not definition.has("type") or str(definition["type"]).is_empty():
			definition["type"] = "string"

		_type_definitions.append(definition)


## 应用 Schema
func _apply_schema() -> void:
	if not _state_manager:
		return

	_state_manager.set_type_definitions(_type_definitions)
#endregion

#region 文件监控功能 File Monitoring Features
## 记录 Schema 文件修改时间
func _record_schema_mod_time(schema_path: String) -> void:
	var file := FileAccess.open(schema_path, FileAccess.READ)
	if file:
		_schema_file_mod_time = file.get_modified_time(schema_path)
		file.close()


## 启动文件监控
func _start_file_watcher(schema_path: String) -> void:
	if not _file_watcher:
		return
	
	_file_watcher.timeout.disconnect(_on_file_watcher_timeout)
	_file_watcher.timeout.connect(_on_file_watcher_timeout.bind(schema_path))
	
	# Timer 未进场景树时 start 会报错（编辑器插件/面板刷新阶段可能触发）。
	if not _file_watcher.is_inside_tree():
		call_deferred("_start_file_watcher", schema_path)
		return
	
	_file_watcher.start()


## 停止文件监控
func _stop_file_watcher() -> void:
	if _file_watcher:
		_file_watcher.stop()


## 文件监控器超时回调
func _on_file_watcher_timeout(schema_path: String) -> void:
	if schema_path.is_empty() or not FileAccess.file_exists(schema_path):
		return
	
	var file := FileAccess.open(schema_path, FileAccess.READ)
	if not file:
		return
	
	var current_mod_time := file.get_modified_time(schema_path)
	file.close()
	
	if current_mod_time != _schema_file_mod_time:
		print("Schema 文件已修改: ", schema_path)
		schema_file_changed.emit(schema_path)
		
		# 自动重新加载
		reload_schema()
#endregion

#region 内联类型标注功能 Inline Type Annotation Features
## 检查是否应该使用外部 Schema
func should_use_external_schema(csv_file_path: String) -> bool:
	if not _external_schema_priority:
		return false
	
	if _current_schema_path.is_empty():
		return false
	
	# 检查 CSV 文件是否有内联类型标注
	var has_inline_annotations := _has_inline_type_annotations(csv_file_path)
	
	# 外部 Schema 优先
	return not has_inline_annotations


## 检查文件是否有内联类型标注
func _has_inline_type_annotations(csv_file_path: String) -> bool:
	if csv_file_path.is_empty():
		return false
	
	var file := FileAccess.open(csv_file_path, FileAccess.READ)
	if not file:
		return false
	
	# 读取前几行检查
	var line_count := 0
	while not file.eof_reached() and line_count < 5:
		var line := file.get_line()
		if ":" in line or "[" in line:
			file.close()
			return true
		line_count += 1
	
	file.close()
	return false


## 合并外部 Schema 和内联类型标注
func merge_with_inline_annotations() -> void:
	if _type_definitions.is_empty():
		return
	
	# TODO: 实现合并逻辑
	pass
#endregion

#region 公共接口 Public API
## 获取当前 Schema 路径
func get_schema_path() -> String:
	return _current_schema_path


## 获取类型定义
func get_type_definitions() -> Array:
	return _type_definitions


## 获取指定列的类型定义
func get_type_definition_for_column(column_name: String) -> Dictionary:
	for definition in _type_definitions:
		if str(definition.get("name", "")) == column_name:
			return definition
	return {}


## 获取指定索引的类型定义
func get_type_definition_for_index(index: int) -> Dictionary:
	if index >= 0 and index < _type_definitions.size():
		return _type_definitions[index]
	return {}


## 检查是否已加载 Schema
func is_schema_loaded() -> bool:
	return not _current_schema_path.is_empty()


## 设置外部 Schema 优先
func set_external_schema_priority(priority: bool) -> void:
	_external_schema_priority = priority


## 获取 Schema 数据
func get_schema_data() -> Dictionary:
	return _schema_data
#endregion


#region In-memory Updates (Editor UI)
## 在编辑器 UI 中直接更新单个字段定义（不落盘）。
## 用于字段设置对话框即时刷新 TableView 的编辑方式与 Validation。
func apply_type_definition_in_memory(column_index: int, definition: Dictionary) -> void:
	if column_index < 0:
		return
	if column_index >= _type_definitions.size():
		return
	var def := definition.duplicate(true)
	_type_definitions[column_index] = def
	if _state_manager:
		_state_manager.update_type_definition(column_index, def)
	type_definitions_changed.emit(_type_definitions)


## 批量替换类型定义（不落盘）。
func set_type_definitions_in_memory(definitions: Array) -> void:
	_type_definitions = definitions.duplicate(true)
	if _state_manager:
		_state_manager.set_type_definitions(_type_definitions)
	type_definitions_changed.emit(_type_definitions)
#endregion
