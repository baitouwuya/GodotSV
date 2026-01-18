class_name ConfigManager
extends Node

## 配置和偏好设置管理器
## 管理用户配置和偏好设置，支持保存到配置文件

signal config_changed(config_key: String)
signal config_loaded()
signal config_saved()

#region 配置键常量 Config Key Constants
## 自动保存间隔（秒）
const KEY_AUTO_SAVE_INTERVAL = "auto_save_interval"

## 默认分隔符
const KEY_DEFAULT_DELIMITER = "default_delimiter"

## 显示行号
const KEY_SHOW_ROW_NUMBERS = "show_row_numbers"

## 启用虚拟滚动
const KEY_ENABLE_VIRTUAL_SCROLL = "enable_virtual_scroll"

## 自动去除空格
const KEY_AUTO_TRIM_SPACES = "auto_trim_spaces"

## 主题选择
const KEY_THEME = "theme"

## 默认编码
const KEY_DEFAULT_ENCODING = "default_encoding"

## 最大撤销历史
const KEY_MAX_UNDO_HISTORY = "max_undo_history"

## 自动保存启用
const KEY_AUTO_SAVE_ENABLED = "auto_save_enabled"

## 字体大小
const KEY_FONT_SIZE = "font_size"

## 单元格文本溢出显示方式
const KEY_CELL_TEXT_OVERFLOW = "cell_text_overflow"

## 换行模式自动行高
const KEY_WRAP_AUTO_ROW_HEIGHT = "wrap_auto_row_height"

## 换行模式最大行数（用于限制自动行高）
const KEY_WRAP_MAX_LINES = "wrap_max_lines"

## 字段类型变更：转换失败处理策略（error/default）
const KEY_TYPE_CHANGE_FAILURE_POLICY = "type_change_failure_policy"

## 字段类型变更：空值处理策略（keep_empty/use_default）
const KEY_TYPE_CHANGE_EMPTY_POLICY = "type_change_empty_policy"
#endregion

#region 默认配置值 Default Config Values
const DEFAULT_AUTO_SAVE_INTERVAL = 60
const DEFAULT_DEFAULT_DELIMITER = ","
const DEFAULT_SHOW_ROW_NUMBERS = true
const DEFAULT_ENABLE_VIRTUAL_SCROLL = true
const DEFAULT_AUTO_TRIM_SPACES = false
const DEFAULT_THEME = "auto"
const DEFAULT_DEFAULT_ENCODING = "utf-8"
const DEFAULT_MAX_UNDO_HISTORY = 100
const DEFAULT_AUTO_SAVE_ENABLED = true
const DEFAULT_FONT_SIZE = 14
const DEFAULT_CELL_TEXT_OVERFLOW = "ellipsis"
const DEFAULT_WRAP_AUTO_ROW_HEIGHT = true
const DEFAULT_WRAP_MAX_LINES = 6
const DEFAULT_TYPE_CHANGE_FAILURE_POLICY = "default"
const DEFAULT_TYPE_CHANGE_EMPTY_POLICY = "use_default"
#endregion

#region 公共变量 Public Variables
## 配置文件路径
var config_file_path: String = "user://gdsv_editor_config.json"

## 配置数据
var config_data: Dictionary = {}

## 是否已加载配置
var is_config_loaded: bool = false
#endregion

#region 生命周期方法 Lifecycle Methods
func _ready() -> void:
	load_config()
#endregion

#region 配置管理 Config Management
## 加载配置
func load_config() -> void:
	if not FileAccess.file_exists(config_file_path):
		print("配置文件不存在，使用默认配置: ", config_file_path)
		_load_default_config()
		return
	
	var file := FileAccess.open(config_file_path, FileAccess.READ)
	if file == null:
		push_error("无法打开配置文件: " + config_file_path)
		_load_default_config()
		return
	
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var parse_result := json.parse(json_string)
	
	if parse_result != OK:
		push_error("配置文件解析失败: " + json.get_error_message())
		_load_default_config()
		return
	
	config_data = json.data
	_validate_and_fix_config()
	is_config_loaded = true
	config_loaded.emit()
	
	print("配置加载成功: ", config_file_path)


## 保存配置
func save_config() -> void:
	var json_string := JSON.stringify(config_data, "\t")
	
	var file := FileAccess.open(config_file_path, FileAccess.WRITE)
	if file == null:
		push_error("无法保存配置文件: " + config_file_path)
		return
	
	file.store_string(json_string)
	file.close()
	
	config_saved.emit()
	print("配置保存成功: ", config_file_path)


## 重新加载配置
func reload_config() -> void:
	load_config()
#endregion

#region 配置访问 Config Access
## 获取配置值
func get_config(key: String, default_value: Variant = null) -> Variant:
	if config_data.has(key):
		return config_data[key]
	return default_value


## 设置配置值
func set_config(key: String, value: Variant) -> void:
	config_data[key] = value
	config_changed.emit(key)


## 获取自动保存间隔
func get_auto_save_interval() -> int:
	return get_config(KEY_AUTO_SAVE_INTERVAL, DEFAULT_AUTO_SAVE_INTERVAL) as int


## 设置自动保存间隔
func set_auto_save_interval(interval: int) -> void:
	set_config(KEY_AUTO_SAVE_INTERVAL, clamp(interval, 10, 600))


## 获取默认分隔符
func get_default_delimiter() -> String:
	return get_config(KEY_DEFAULT_DELIMITER, DEFAULT_DEFAULT_DELIMITER) as String


## 设置默认分隔符
func set_default_delimiter(delimiter: String) -> void:
	if delimiter.is_empty():
		return
	set_config(KEY_DEFAULT_DELIMITER, delimiter)


## 获取显示行号
func get_show_row_numbers() -> bool:
	return get_config(KEY_SHOW_ROW_NUMBERS, DEFAULT_SHOW_ROW_NUMBERS) as bool


## 设置显示行号
func set_show_row_numbers(show: bool) -> void:
	set_config(KEY_SHOW_ROW_NUMBERS, show)


## 获取启用虚拟滚动
func get_enable_virtual_scroll() -> bool:
	return get_config(KEY_ENABLE_VIRTUAL_SCROLL, DEFAULT_ENABLE_VIRTUAL_SCROLL) as bool


## 设置启用虚拟滚动
func set_enable_virtual_scroll(enable: bool) -> void:
	set_config(KEY_ENABLE_VIRTUAL_SCROLL, enable)


## 获取自动去除空格
func get_auto_trim_spaces() -> bool:
	return get_config(KEY_AUTO_TRIM_SPACES, DEFAULT_AUTO_TRIM_SPACES) as bool


## 设置自动去除空格
func set_auto_trim_spaces(trim: bool) -> void:
	set_config(KEY_AUTO_TRIM_SPACES, trim)


## 获取主题
func get_theme() -> String:
	return get_config(KEY_THEME, DEFAULT_THEME) as String


## 设置主题
func set_theme(theme_name: String) -> void:
	if theme_name not in ["light", "dark", "auto"]:
		return
	set_config(KEY_THEME, theme_name)


## 获取默认编码
func get_default_encoding() -> String:
	return get_config(KEY_DEFAULT_ENCODING, DEFAULT_DEFAULT_ENCODING) as String


## 设置默认编码
func set_default_encoding(encoding: String) -> void:
	set_config(KEY_DEFAULT_ENCODING, encoding)


## 获取最大撤销历史
func get_max_undo_history() -> int:
	return get_config(KEY_MAX_UNDO_HISTORY, DEFAULT_MAX_UNDO_HISTORY) as int


## 设置最大撤销历史
func set_max_undo_history(max_history: int) -> void:
	set_config(KEY_MAX_UNDO_HISTORY, clamp(max_history, 10, 500))


## 获取自动保存启用
func get_auto_save_enabled() -> bool:
	return get_config(KEY_AUTO_SAVE_ENABLED, DEFAULT_AUTO_SAVE_ENABLED) as bool


## 设置自动保存启用
func set_auto_save_enabled(enabled: bool) -> void:
	set_config(KEY_AUTO_SAVE_ENABLED, enabled)


## 获取字体大小
func get_font_size() -> int:
	return get_config(KEY_FONT_SIZE, DEFAULT_FONT_SIZE) as int


## 设置字体大小
func set_font_size(size: int) -> void:
	set_config(KEY_FONT_SIZE, clamp(size, 10, 24))


## 获取单元格文本溢出显示方式
func get_cell_text_overflow() -> String:
	return get_config(KEY_CELL_TEXT_OVERFLOW, DEFAULT_CELL_TEXT_OVERFLOW) as String


## 设置单元格文本溢出显示方式
func set_cell_text_overflow(mode: String) -> void:
	if mode not in ["clip", "ellipsis", "wrap"]:
		return
	set_config(KEY_CELL_TEXT_OVERFLOW, mode)


## 获取换行自动行高
func get_wrap_auto_row_height() -> bool:
	return get_config(KEY_WRAP_AUTO_ROW_HEIGHT, DEFAULT_WRAP_AUTO_ROW_HEIGHT) as bool


## 设置换行自动行高
func set_wrap_auto_row_height(enabled: bool) -> void:
	set_config(KEY_WRAP_AUTO_ROW_HEIGHT, enabled)


## 获取换行最大行数
func get_wrap_max_lines() -> int:
	return get_config(KEY_WRAP_MAX_LINES, DEFAULT_WRAP_MAX_LINES) as int


## 设置换行最大行数
func set_wrap_max_lines(lines: int) -> void:
	set_config(KEY_WRAP_MAX_LINES, clamp(lines, 1, 20))


## 获取字段类型变更：转换失败处理策略
func get_type_change_failure_policy() -> String:
	return get_config(KEY_TYPE_CHANGE_FAILURE_POLICY, DEFAULT_TYPE_CHANGE_FAILURE_POLICY) as String


## 设置字段类型变更：转换失败处理策略
func set_type_change_failure_policy(policy: String) -> void:
	if policy not in ["error", "default"]:
		return
	set_config(KEY_TYPE_CHANGE_FAILURE_POLICY, policy)


## 获取字段类型变更：空值处理策略
func get_type_change_empty_policy() -> String:
	return get_config(KEY_TYPE_CHANGE_EMPTY_POLICY, DEFAULT_TYPE_CHANGE_EMPTY_POLICY) as String


## 设置字段类型变更：空值处理策略
func set_type_change_empty_policy(policy: String) -> void:
	if policy not in ["keep_empty", "use_default"]:
		return
	set_config(KEY_TYPE_CHANGE_EMPTY_POLICY, policy)
#endregion

#region 配置导出导入 Config Export/Import
## 导出配置为字典
func export_config() -> Dictionary:
	return config_data.duplicate()


## 导入配置
func import_config(config: Dictionary) -> void:
	config_data = config.duplicate()
	_validate_and_fix_config()
	config_loaded.emit()


## 重置为默认配置
func reset_to_default() -> void:
	_load_default_config()
	config_loaded.emit()
#endregion

#region 私有方法 Private Methods
## 加载默认配置
func _load_default_config() -> void:
	config_data = {
		KEY_AUTO_SAVE_INTERVAL: DEFAULT_AUTO_SAVE_INTERVAL,
		KEY_DEFAULT_DELIMITER: DEFAULT_DEFAULT_DELIMITER,
		KEY_SHOW_ROW_NUMBERS: DEFAULT_SHOW_ROW_NUMBERS,
		KEY_ENABLE_VIRTUAL_SCROLL: DEFAULT_ENABLE_VIRTUAL_SCROLL,
		KEY_AUTO_TRIM_SPACES: DEFAULT_AUTO_TRIM_SPACES,
		KEY_THEME: DEFAULT_THEME,
		KEY_DEFAULT_ENCODING: DEFAULT_DEFAULT_ENCODING,
		KEY_MAX_UNDO_HISTORY: DEFAULT_MAX_UNDO_HISTORY,
		KEY_AUTO_SAVE_ENABLED: DEFAULT_AUTO_SAVE_ENABLED,
		KEY_FONT_SIZE: DEFAULT_FONT_SIZE,
		KEY_CELL_TEXT_OVERFLOW: DEFAULT_CELL_TEXT_OVERFLOW,
		KEY_WRAP_AUTO_ROW_HEIGHT: DEFAULT_WRAP_AUTO_ROW_HEIGHT,
		KEY_WRAP_MAX_LINES: DEFAULT_WRAP_MAX_LINES,
		KEY_TYPE_CHANGE_FAILURE_POLICY: DEFAULT_TYPE_CHANGE_FAILURE_POLICY,
		KEY_TYPE_CHANGE_EMPTY_POLICY: DEFAULT_TYPE_CHANGE_EMPTY_POLICY,
	}
	is_config_loaded = true


## 验证和修复配置
func _validate_and_fix_config() -> void:
	# 确保所有配置项都有有效的值
	if not config_data.has(KEY_AUTO_SAVE_INTERVAL) or not _is_valid_int(config_data[KEY_AUTO_SAVE_INTERVAL]):
		config_data[KEY_AUTO_SAVE_INTERVAL] = DEFAULT_AUTO_SAVE_INTERVAL
	
	if not config_data.has(KEY_DEFAULT_DELIMITER) or not _is_valid_string(config_data[KEY_DEFAULT_DELIMITER]):
		config_data[KEY_DEFAULT_DELIMITER] = DEFAULT_DEFAULT_DELIMITER
	
	if not config_data.has(KEY_SHOW_ROW_NUMBERS) or not _is_valid_bool(config_data[KEY_SHOW_ROW_NUMBERS]):
		config_data[KEY_SHOW_ROW_NUMBERS] = DEFAULT_SHOW_ROW_NUMBERS
	
	if not config_data.has(KEY_ENABLE_VIRTUAL_SCROLL) or not _is_valid_bool(config_data[KEY_ENABLE_VIRTUAL_SCROLL]):
		config_data[KEY_ENABLE_VIRTUAL_SCROLL] = DEFAULT_ENABLE_VIRTUAL_SCROLL
	
	if not config_data.has(KEY_AUTO_TRIM_SPACES) or not _is_valid_bool(config_data[KEY_AUTO_TRIM_SPACES]):
		config_data[KEY_AUTO_TRIM_SPACES] = DEFAULT_AUTO_TRIM_SPACES
	
	if not config_data.has(KEY_THEME) or not _is_valid_theme(config_data[KEY_THEME]):
		config_data[KEY_THEME] = DEFAULT_THEME
	
	if not config_data.has(KEY_DEFAULT_ENCODING) or not _is_valid_string(config_data[KEY_DEFAULT_ENCODING]):
		config_data[KEY_DEFAULT_ENCODING] = DEFAULT_DEFAULT_ENCODING
	
	if not config_data.has(KEY_MAX_UNDO_HISTORY) or not _is_valid_int(config_data[KEY_MAX_UNDO_HISTORY]):
		config_data[KEY_MAX_UNDO_HISTORY] = DEFAULT_MAX_UNDO_HISTORY
	
	if not config_data.has(KEY_AUTO_SAVE_ENABLED) or not _is_valid_bool(config_data[KEY_AUTO_SAVE_ENABLED]):
		config_data[KEY_AUTO_SAVE_ENABLED] = DEFAULT_AUTO_SAVE_ENABLED
	
	if not config_data.has(KEY_FONT_SIZE) or not _is_valid_int(config_data[KEY_FONT_SIZE]):
		config_data[KEY_FONT_SIZE] = DEFAULT_FONT_SIZE

	if not config_data.has(KEY_CELL_TEXT_OVERFLOW) or not _is_valid_cell_text_overflow(config_data[KEY_CELL_TEXT_OVERFLOW]):
		config_data[KEY_CELL_TEXT_OVERFLOW] = DEFAULT_CELL_TEXT_OVERFLOW

	if not config_data.has(KEY_WRAP_AUTO_ROW_HEIGHT) or not _is_valid_bool(config_data[KEY_WRAP_AUTO_ROW_HEIGHT]):
		config_data[KEY_WRAP_AUTO_ROW_HEIGHT] = DEFAULT_WRAP_AUTO_ROW_HEIGHT

	if not config_data.has(KEY_WRAP_MAX_LINES) or not _is_valid_wrap_max_lines(config_data[KEY_WRAP_MAX_LINES]):
		config_data[KEY_WRAP_MAX_LINES] = DEFAULT_WRAP_MAX_LINES
	
	if not config_data.has(KEY_TYPE_CHANGE_FAILURE_POLICY) or not _is_valid_type_change_failure_policy(config_data[KEY_TYPE_CHANGE_FAILURE_POLICY]):
		config_data[KEY_TYPE_CHANGE_FAILURE_POLICY] = DEFAULT_TYPE_CHANGE_FAILURE_POLICY
	
	if not config_data.has(KEY_TYPE_CHANGE_EMPTY_POLICY) or not _is_valid_type_change_empty_policy(config_data[KEY_TYPE_CHANGE_EMPTY_POLICY]):
		config_data[KEY_TYPE_CHANGE_EMPTY_POLICY] = DEFAULT_TYPE_CHANGE_EMPTY_POLICY


## 检查是否为有效整数
func _is_valid_int(value: Variant) -> bool:
	return value is int


## 检查是否为有效字符串
func _is_valid_string(value: Variant) -> bool:
	return value is String and not value.is_empty()


## 检查是否为有效布尔值
func _is_valid_bool(value: Variant) -> bool:
	return value is bool


## 检查是否为有效主题
func _is_valid_theme(value: Variant) -> bool:
	return value is String and value in ["light", "dark", "auto"]


## 检查是否为有效单元格文本溢出模式
func _is_valid_cell_text_overflow(value: Variant) -> bool:
	return value is String and value in ["clip", "ellipsis", "wrap"]


## 检查是否为有效换行最大行数
func _is_valid_wrap_max_lines(value: Variant) -> bool:
	return value is int and value >= 1 and value <= 20


## 检查是否为有效类型变更失败策略
func _is_valid_type_change_failure_policy(value: Variant) -> bool:
	return value is String and value in ["error", "default"]


## 检查是否为有效空值处理策略
func _is_valid_type_change_empty_policy(value: Variant) -> bool:
	return value is String and value in ["keep_empty", "use_default"]
