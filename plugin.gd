@tool
extends EditorPlugin

## GodotSV 插件入口，负责注册 CSV 导入插件和编辑器插件

const CSV_IMPORTER_NAME := "godotsv.importer"
const LEGACY_TRANSLATION_DIR := "res://.godot/godotsv/legacy_translation"
const INVALID_TRANSLATION_NAME_CHARS := [":", "[", "]", "(", ")"]

var _unified_import_plugin: EditorImportPlugin = null
var _editor_plugin: GDSVEditorPlugin = null
var _legacy_cleanup_attempts: int = 0


#region 生命周期方法 Lifecycle Methods
func _enter_tree() -> void:
	add_to_group("godotsv_plugin")
	# 确保 GDSVResource 脚本类已注册（避免导入生成的 .res 加载时找不到类型）
	var csv_resource_script := _load_plugin_script("gdsv_resource.gd")
	if csv_resource_script == null:
		push_error("GodotSV: 无法加载 gdsv_resource.gd（请确认插件目录完整）")
		return

	# 触发GDSVResource的class_name注册（编辑器启动早期时序问题）
	GDSVResource.ensure_registered()

	# 创建并注册统一导入插件（支持 .gdsv, .csv, .tsv, .tab, .psv, .asc）
	_unified_import_plugin = preload("unified_gdsv_import_plugin.gd").new()
	add_import_plugin(_unified_import_plugin)

	# 创建并托管编辑器插件
	# 注意：不要手动调用另一个 EditorPlugin 的 _enter_tree/_exit_tree，
	# 否则会导致快捷键/动作注册异常、生命周期错乱。
	_editor_plugin = GDSVEditorPlugin.new()
	add_child(_editor_plugin)
	_editor_plugin.owner = self

	# 清理旧的 Translation CSV 导入产物（例如 sample_people.age.translation），避免污染 CSV 目录
	# 注意：旧的 *.translation 清理改为“被动触发”。
	# 仅在读取/导入 CSV 时按需触发，避免与编辑器资源扫描/导入线程抢占文件句柄导致锁冲突。
	# 触发入口见：request_legacy_translation_cleanup()


func _exit_tree() -> void:
	remove_from_group("godotsv_plugin")
	# 移除统一导入插件
	if _unified_import_plugin != null:
		remove_import_plugin(_unified_import_plugin)
		_unified_import_plugin = null

	# 清理编辑器插件
	if _editor_plugin != null:
		_editor_plugin.queue_free()
		_editor_plugin = null
#endregion




#region 兼容性清理 Compatibility Cleanup
## 请求一次“旧的 *.translation”清理（被动触发）。
## 该方法会在编辑器扫描结束后再执行，避免与扫描线程冲突。
static func request_legacy_translation_cleanup() -> void:
	var root := Engine.get_main_loop() as SceneTree
	if root == null:
		return

	var plugin := root.get_first_node_in_group("godotsv_plugin")
	if plugin == null:
		return

	(plugin as EditorPlugin).call_deferred("_schedule_legacy_translation_cleanup")
#endregion




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
	#
	# 重要：不要递归扫描整个 res://。
	# 这会触发 Godot 编辑器在资源扫描/导入阶段对多种资源生成或更新
	# .godot/editor/*translation-folding-*.cfg，进而在某些项目/环境下出现“文件被占用/权限不足”。
	#
	# 旧版本我们会把误导入的 *.translation 移到本目录，因此只需要扫描这里即可。
	var target_dir_abs := ProjectSettings.globalize_path(LEGACY_TRANSLATION_DIR)
	DirAccess.make_dir_recursive_absolute(target_dir_abs)
	_cleanup_legacy_translation_files_in_dir(LEGACY_TRANSLATION_DIR)

	# 额外清理：删除“文件名非法（含类型标注符号）”的 *.translation 产物。
	# 这些文件通常来自 Godot 内置 CSV Translation importer 把 CSV 表头拼进文件名。
	# 只扫描“使用我们 importer 的 CSV 所在目录”，避免全项目扫描引发锁冲突。
	_cleanup_invalid_translation_files_for_godotsv_csvs()


func _cleanup_invalid_translation_files_for_godotsv_csvs() -> void:
	var csv_dirs := _collect_godotsv_csv_dirs()
	for dir_path: String in csv_dirs:
		_cleanup_invalid_translation_files_in_dir(dir_path)


func _collect_godotsv_csv_dirs() -> Array[String]:
	var result: Array[String] = []
	var csv_import_paths := _collect_godotsv_csv_import_paths()
	for csv_import_path: String in csv_import_paths:
		var dir_path := csv_import_path.get_base_dir()
		if not dir_path.is_empty() and not (dir_path in result):
			result.append(dir_path)
	return result


func _collect_godotsv_csv_import_paths() -> Array[String]:
	var result: Array[String] = []

	var editor_if := get_editor_interface()
	if editor_if == null or not editor_if.has_method("get_resource_filesystem"):
		return result

	var fs := editor_if.get_resource_filesystem()
	if fs == null:
		return result

	var root := fs.get_filesystem()
	if root == null:
		return result

	_collect_godotsv_csv_import_paths_in_dir(root, result)
	return result


func _collect_godotsv_csv_import_paths_in_dir(dir, out_paths: Array[String]) -> void:
	# 这里的 dir 是 EditorFileSystemDirectory，无法静态类型标注。
	if dir == null:
		return

	var file_count: int = dir.get_file_count()
	for i in range(file_count):
		var file_path: String = dir.get_file_path(i)
		if not file_path.ends_with(".csv"):
			continue

		var import_path := file_path + ".import"
		if not FileAccess.file_exists(import_path):
			continue

		var import_text := FileAccess.get_file_as_string(import_path)
		if import_text.find('importer="%s"' % CSV_IMPORTER_NAME) >= 0:
			out_paths.append(file_path)

	var subdir_count: int = dir.get_subdir_count()
	for j in range(subdir_count):
		_collect_godotsv_csv_import_paths_in_dir(dir.get_subdir(j), out_paths)


func _cleanup_invalid_translation_files_in_dir(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return

	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		if entry.begins_with("."):
			entry = dir.get_next()
			continue

		if dir.current_is_dir():
			entry = dir.get_next()
			continue

		if entry.ends_with(".translation") and _is_invalid_translation_file_name(entry):
			_try_remove_file(dir_path.path_join(entry))

		entry = dir.get_next()
	dir.list_dir_end()


func _is_invalid_translation_file_name(file_name: String) -> bool:
	for ch: String in INVALID_TRANSLATION_NAME_CHARS:
		if file_name.find(ch) >= 0:
			return true
	return false


func _try_remove_file(path: String) -> void:
	var abs := ProjectSettings.globalize_path(path)
	if DirAccess.remove_absolute(abs) != OK:
		# 编辑器环境下不使用 assert，避免影响稳定性
		push_warning("GodotSV: 无法删除文件（可能被占用/权限不足）: %s" % path)


func _cleanup_legacy_translation_files_in_dir(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return

	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		if entry.begins_with("."):
			entry = dir.get_next()
			continue

		var full_path := dir_path.path_join(entry)
		if dir.current_is_dir():
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
		var safe_base_name := _make_safe_file_stem(base_name)
		var new_name := "%s_%d.translation" % [safe_base_name, Time.get_unix_time_from_system()]
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
	return _editor_plugin._get_plugin_name() if _editor_plugin else "GodotSV"


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

#region 工具方法 Utility Methods
func _make_safe_file_stem(stem: String) -> String:
	# 只用于生成临时/迁移文件名：去掉可能导致跨平台问题的字符。
	# 不要试图保留所有符号，优先保证文件可创建、可复制、可导入。
	var s := stem.strip_edges()
	if s.is_empty():
		return "translation"

	# Windows/跨平台常见非法字符 + 路径分隔符
	var illegal_chars := ["\\", "/", ":", "*", "?", "\"", "<", ">", "|", "\n", "\r", "\t"]
	for ch in illegal_chars:
		s = s.replace(ch, "_")

	# 避免隐藏文件或以点结尾
	while s.begins_with("."):
		s = s.trim_prefix(".")
	while s.ends_with("."):
		s = s.trim_suffix(".")

	# 兜底
	return s if not s.is_empty() else "translation"


func _load_plugin_script(file_name: String) -> Script:
	# 使用插件自身脚本路径拼接，避免用户把插件放到不同目录时路径失效。
	# 约定：本文件与目标脚本（如 csv_resource.gd）位于同一目录。
	if file_name.is_empty():
		return null

	var plugin_dir: String = get_script().resource_path.get_base_dir()
	if plugin_dir.is_empty():
		return null

	var script_path: String = plugin_dir.path_join(file_name)
	var script_res := load(script_path)
	return script_res as Script
#endregion
