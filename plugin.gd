@tool
extends EditorPlugin

## CSV Handler 插件入口，负责注册 CSV 导入插件和编辑器插件

const CSV_RESOURCE_SCRIPT: Script = preload("res://addons/csv_handler/csv_resource.gd")
const CSV_IMPORTER_NAME := "csv_handler.importer"
const LEGACY_TRANSLATION_DIR := "res://.godot/csv_handler/legacy_translation"

var _import_plugin: CSVImportPlugin = null
var _editor_plugin: CSVEditorPlugin = null
var _legacy_cleanup_attempts: int = 0


func _enter_tree() -> void:
	# 确保 CSVResource 脚本类已注册（避免导入生成的 .res 加载时找不到类型）
	if CSV_RESOURCE_SCRIPT == null:
		push_error("CSV Handler: 无法预加载 csv_resource.gd")
		return
	
	# 触发CSVResource的class_name注册（编辑器启动早期时序问题）
	CSVResource.ensure_registered()

	# 创建并注册导入插件
	_import_plugin = CSVImportPlugin.new()
	add_import_plugin(_import_plugin)

	# 创建并托管编辑器插件
	# 注意：不要手动调用另一个 EditorPlugin 的 _enter_tree/_exit_tree，
	# 否则会导致快捷键/动作注册异常、生命周期错乱。
	_editor_plugin = CSVEditorPlugin.new()
	add_child(_editor_plugin)
	_editor_plugin.owner = self

	# 清理旧的 Translation CSV 导入产物（例如 sample_people.age.translation），避免污染 CSV 目录
	call_deferred("_schedule_legacy_translation_cleanup")


func _exit_tree() -> void:
	# 移除导入插件
	if _import_plugin != null:
		remove_import_plugin(_import_plugin)
		_import_plugin.queue_free()
		_import_plugin = null
	
	# 清理编辑器插件
	if _editor_plugin != null:
		_editor_plugin.queue_free()
		_editor_plugin = null


func _schedule_legacy_translation_cleanup() -> void:
	# 避免在编辑器启动扫描期间干扰文件系统线程
	_legacy_cleanup_attempts += 1
	if _legacy_cleanup_attempts > 40:
		return

	var editor_if := get_editor_interface()
	if editor_if and editor_if.has_method("get_resource_filesystem"):
		var fs := editor_if.get_resource_filesystem()
		if fs and fs.has_method("is_scanning") and fs.is_scanning():
			await get_tree().create_timer(0.5).timeout
			_schedule_legacy_translation_cleanup()
			return

	_cleanup_legacy_translation_files()

func _cleanup_legacy_translation_files() -> void:
	# 仅清理“由 CSV 翻译导入器误导入产生”的 *.translation 文件：
	# 文件名形如 <csv_base>.<locale>.translation，并且对应的 <csv_base>.csv 当前使用我们的 importer。
	_cleanup_legacy_translation_files_in_dir("res://")


func _cleanup_legacy_translation_files_in_dir(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return

	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		if entry.begins_with(".") and entry != ".godot":
			entry = dir.get_next()
			continue

		var full_path := dir_path.path_join(entry)
		if dir.current_is_dir():
			if entry != ".godot":
				_cleanup_legacy_translation_files_in_dir(full_path)
		else:
			if entry.ends_with(".translation"):
				_try_move_legacy_translation_file(full_path)

		entry = dir.get_next()
	dir.list_dir_end()


func _try_move_legacy_translation_file(translation_path: String) -> void:
	var stem := translation_path.trim_suffix(".translation")
	var dot := stem.rfind(".")
	if dot < 0:
		return

	var csv_base := stem.substr(0, dot)
	var csv_path := csv_base + ".csv"
	var csv_import_path := csv_path + ".import"
	if not FileAccess.file_exists(csv_import_path):
		return

	var import_text := FileAccess.get_file_as_string(csv_import_path)
	if import_text.find('importer="%s"' % CSV_IMPORTER_NAME) < 0:
		return

	# 移动到隐藏目录，避免在 CSV 文件目录中出现
	var target_dir_abs := ProjectSettings.globalize_path(LEGACY_TRANSLATION_DIR)
	DirAccess.make_dir_recursive_absolute(target_dir_abs)

	var target_path := LEGACY_TRANSLATION_DIR.path_join(translation_path.get_file())
	var from_abs := ProjectSettings.globalize_path(translation_path)
	var to_abs := ProjectSettings.globalize_path(target_path)

	if FileAccess.file_exists(target_path):
		var base_name := translation_path.get_file().trim_suffix(".translation")
		var new_name := "%s_%d.translation" % [base_name, Time.get_unix_time_from_system()]
		target_path = LEGACY_TRANSLATION_DIR.path_join(new_name)
		to_abs = ProjectSettings.globalize_path(target_path)

	DirAccess.rename_absolute(from_abs, to_abs)


func _handles(object: Object) -> bool:
	return _editor_plugin._handles(object) if _editor_plugin else false


func _edit(object: Object) -> void:
	if _editor_plugin:
		_editor_plugin._edit(object)


func _make_visible(visible: bool) -> void:
	if _editor_plugin:
		_editor_plugin._make_visible(visible)


func _get_plugin_name() -> String:
	return _editor_plugin._get_plugin_name() if _editor_plugin else "CSV Handler"


func _get_plugin_icon() -> Texture2D:
	return _editor_plugin._get_plugin_icon() if _editor_plugin else EditorInterface.get_editor_theme().get_icon("File", "EditorIcons")


func _apply_changes() -> void:
	if _editor_plugin:
		_editor_plugin._apply_changes()


func _get_state() -> Dictionary:
	return _editor_plugin._get_state() if _editor_plugin else {}


func _set_state(state: Dictionary) -> void:
	if _editor_plugin:
		_editor_plugin._set_state(state)
