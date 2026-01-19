class_name GDSVDataModel
extends Node

## GDSV 数据模型，封装表格数据和数据操作逻辑
## 提供数据观察、批量操作和撤销/重做支持

## 搜索匹配模式枚举
enum MatchMode {
	MATCH_CONTAINS = 0,
	MATCH_NOT_CONTAINS = 1,
	MATCH_EQUALS = 2,
	MATCH_NOT_EQUALS = 3,
	MATCH_STARTS_WITH = 4,
	MATCH_ENDS_WITH = 5
}
#region 信号 Signals
signal data_changed(change_type: String, details: Dictionary)
signal row_inserted(row_index: int)
signal row_removed(row_index: int)
signal row_moved(from_index: int, to_index: int)
signal column_inserted(column_index: int, column_name: String)
signal column_removed(column_index: int, column_name: String)
signal column_moved(from_index: int, to_index: int)
signal cell_changed(row_index: int, column_index: int, old_value: String, new_value: String)
signal selection_changed(selections: Array)
#endregion

#region 导出变量 Export Variables
## 数据处理器实例
@export var data_processor: GDSVDataProcessor

## 是否启用撤销/重做
@export var enable_undo_redo: bool = true
#endregion

#region 公共变量 Public Variables
## 选中的单元格列表 [Vector2i]
var selections: Array = []

## 当前编辑的单元格
var editing_cell: Vector2i = Vector2i(-1, -1)

## 撤销/重做管理器
var undo_redo: UndoRedo

## 是否有未保存修改（每个标签页独立）
var modified: bool = false
#endregion

#region 私有变量 Private Variables
var _type_definitions: Array = []
var _column_types: Dictionary = {}
var _row_heights: Dictionary = {}
var _column_widths: Dictionary = {}
#endregion


func _ensure_type_definitions_size() -> void:
	var col_count := get_column_count()

	if col_count <= 0:
		_type_definitions.clear()
		return

	if _type_definitions.size() < col_count:
		var header := get_header()
		for i in range(_type_definitions.size(), col_count):
			var name := header[i] if i < header.size() else ("Column_" + str(i + 1))
			_type_definitions.append({"name": name, "type": "string"})
	elif _type_definitions.size() > col_count:
		_type_definitions.resize(col_count)

#region 生命周期方法 Lifecycle Methods
func _init() -> void:
	_initialize_undo_redo()


func _ready() -> void:
	if data_processor:
		data_processor.data_changed.connect(_on_data_processor_data_changed)
#endregion

#region 初始化功能 Initialization Features
func _initialize_undo_redo() -> void:
	undo_redo = UndoRedo.new()


func set_data_processor(processor: GDSVDataProcessor) -> void:
	if data_processor and data_processor.data_changed.is_connected(_on_data_processor_data_changed):
		data_processor.data_changed.disconnect(_on_data_processor_data_changed)
	
	data_processor = processor
	
	if data_processor and not data_processor.data_changed.is_connected(_on_data_processor_data_changed):
		data_processor.data_changed.connect(_on_data_processor_data_changed)
#endregion

#region 数据查询功能 Data Query Features
## 获取表格行数
func get_row_count() -> int:
	return data_processor.get_row_count() if data_processor else 0


## 获取表格列数
func get_column_count() -> int:
	return data_processor.get_column_count() if data_processor else 0


## 获取表头
func get_header() -> PackedStringArray:
	return data_processor.get_header() if data_processor else PackedStringArray()


## 获取原始表头
func get_original_header() -> PackedStringArray:
	return data_processor.get_original_header() if data_processor else PackedStringArray()


## 获取指定行
func get_row(row_index: int) -> PackedStringArray:
	return data_processor.get_row(row_index)


## 获取指定列
func get_column(column_index: int) -> PackedStringArray:
	return data_processor.get_column(column_index)


## 获取单元格值
func get_cell_value(row_index: int, column_index: int) -> String:
	return data_processor.get_cell_value(row_index, column_index)


## 获取单元格类型
func get_cell_type(row_index: int, column_index: int) -> String:
	_ensure_type_definitions_size()
	if column_index < _type_definitions.size():
		return _type_definitions[column_index].get("type", "string")
	return "string"


## 获取列类型定义
func get_column_type_definition(column_index: int) -> Dictionary:
	_ensure_type_definitions_size()
	if column_index < _type_definitions.size():
		return _type_definitions[column_index]
	return {}


## 获取所有类型定义
func get_type_definitions() -> Array:
	_ensure_type_definitions_size()
	return _type_definitions.duplicate()


## 获取所有行数据
func get_all_rows() -> Array[PackedStringArray]:
	if not data_processor:
		return []

	# 返回对外快照：避免调用方修改返回值影响内部数据
	var rows := data_processor.get_all_rows()
	var snapshot: Array[PackedStringArray] = []
	for row in rows:
		snapshot.append((row as PackedStringArray).duplicate())
	return snapshot


## 兼容旧接口：返回与 `get_all_rows()` 等价的数据快照。
## 注意：该方法仅用于向后兼容；新代码请使用 `get_all_rows()`。
func to_array() -> Array[PackedStringArray]:
	return get_all_rows()

#endregion

#region 数据修改功能 Data Modification Features
## 设置单元格值
func set_cell_value(row_index: int, column_index: int, value: String) -> bool:
	if not data_processor:
		return false
	
	if not data_processor.is_valid_index(row_index, column_index):
		return false
	
	var old_value: String = data_processor.get_cell_value(row_index, column_index)
	
	if value == old_value:
		return true
	
	if enable_undo_redo:
		undo_redo.create_action("Set Cell Value")
		undo_redo.add_do_method(data_processor.set_cell_value.bind(row_index, column_index, value))
		undo_redo.add_undo_method(data_processor.set_cell_value.bind(row_index, column_index, old_value))
		undo_redo.commit_action()
	else:
		data_processor.set_cell_value(row_index, column_index, value)
	
	var old_value_str: String = old_value
	var new_value_str: String = value
	cell_changed.emit(row_index, column_index, old_value_str, new_value_str)
	data_changed.emit("cell_modified", {"row": row_index, "column": column_index, "old_value": old_value_str, "new_value": new_value_str})
	modified = true
	
	return true


## 批量设置单元格
func batch_set_cells(cells: Array) -> int:
	if not data_processor:
		return 0
	
	var old_values := {}
	for cell_data in cells:
		if cell_data is Dictionary and cell_data.has("row") and cell_data.has("column"):
			var row: int = cell_data.row
			var col: int = cell_data.column
			old_values[Vector2i(row, col)] = data_processor.get_cell_value(row, col)
	
	if enable_undo_redo:
		undo_redo.create_action("Batch Set Cells")
		undo_redo.add_do_method(data_processor.batch_set_cells.bind(cells))
		undo_redo.add_undo_method(_undo_batch_set_cells.bind(cells, old_values))
		undo_redo.commit_action()
	else:
		data_processor.batch_set_cells(cells)
	
	
	for cell_data in cells:
		if cell_data is Dictionary and cell_data.has("row") and cell_data.has("column"):
			var row: int = cell_data.row
			var col: int = cell_data.column
			var old_value: String = old_values.get(Vector2i(row, col), "")
			var new_value: String = cell_data.get("value", "")
			cell_changed.emit(row, col, old_value, new_value)
	
	data_changed.emit("batch_modified", {"count": cells.size()})
	modified = true
	
	return cells.size()


## 插入行
func insert_row(row_index: int, row_data: Array[PackedStringArray] = []) -> bool:
	if not data_processor:
		return false
	
	var actual_data: PackedStringArray
	if row_data.is_empty():
		actual_data = PackedStringArray()
		actual_data.resize(get_column_count())
		for i in range(actual_data.size()):
			actual_data[i] = ""
	else:
		actual_data = row_data[0] if row_data.size() > 0 else PackedStringArray()
	
	if enable_undo_redo:
		undo_redo.create_action("Insert Row")
		undo_redo.add_do_method(data_processor.insert_row.bind(row_index, actual_data))
		undo_redo.add_undo_method(data_processor.remove_row.bind(row_index))
		undo_redo.commit_action()
	else:
		data_processor.insert_row(row_index, actual_data)
	
	row_inserted.emit(row_index)
	data_changed.emit("row_inserted", {"row_index": row_index})
	modified = true
	
	return true


## 删除行
func remove_row(row_index: int) -> bool:
	if not data_processor:
		return false
	
	var row_data: PackedStringArray = data_processor.get_row(row_index)
	
	if enable_undo_redo:
		undo_redo.create_action("Remove Row")
		undo_redo.add_do_method(data_processor.remove_row.bind(row_index))
		undo_redo.add_undo_method(data_processor.insert_row.bind(row_index, row_data))
		undo_redo.commit_action()
	else:
		data_processor.remove_row(row_index)
	
	row_removed.emit(row_index)
	data_changed.emit("row_removed", {"row_index": row_index})
	
	return true


## 移动行
func move_row(from_index: int, to_index: int) -> bool:
	if not data_processor:
		return false
	
	if enable_undo_redo:
		undo_redo.create_action("Move Row")
		undo_redo.add_do_method(data_processor.move_row.bind(from_index, to_index))
		undo_redo.add_undo_method(data_processor.move_row.bind(to_index, from_index))
		undo_redo.commit_action()
	else:
		data_processor.move_row(from_index, to_index)
	
	row_moved.emit(from_index, to_index)
	data_changed.emit("row_moved", {"from_index": from_index, "to_index": to_index})
	
	return true


## 插入列
func insert_column(column_index: int, column_name: String, default_value: String = "") -> bool:
	if not data_processor:
		return false

	_ensure_type_definitions_size()
	column_index = clampi(column_index, 0, get_column_count())
	
	if enable_undo_redo:
		undo_redo.create_action("Insert Column")
		undo_redo.add_do_method(data_processor.insert_column.bind(column_index, column_name, default_value))
		undo_redo.add_undo_method(data_processor.remove_column.bind(column_index))
		undo_redo.commit_action()
	else:
		data_processor.insert_column(column_index, column_name, default_value)
	
	_type_definitions.insert(column_index, {"name": column_name, "type": "string"})
	
	column_inserted.emit(column_index, column_name)
	data_changed.emit("column_inserted", {"column_index": column_index, "column_name": column_name})
	
	return true


## 删除列
func remove_column(column_index: int) -> bool:
	if not data_processor:
		return false

	_ensure_type_definitions_size()

	var column_name := get_header()[column_index] if column_index < get_column_count() else ""
	
	if enable_undo_redo:
		undo_redo.create_action("Remove Column")
		undo_redo.add_do_method(data_processor.remove_column.bind(column_index))
		undo_redo.add_undo_method(_undo_remove_column.bind(column_index, column_name))
		undo_redo.commit_action()
	else:
		data_processor.remove_column(column_index)
	
	if column_index < _type_definitions.size():
		_type_definitions.remove_at(column_index)
	
	column_removed.emit(column_index, column_name)
	data_changed.emit("column_removed", {"column_index": column_index, "column_name": column_name})
	
	return true


## 移动列
func move_column(from_index: int, to_index: int) -> bool:
	if not data_processor:
		return false

	_ensure_type_definitions_size()
	
	if enable_undo_redo:
		undo_redo.create_action("Move Column")
		undo_redo.add_do_method(data_processor.move_column.bind(from_index, to_index))
		undo_redo.add_undo_method(data_processor.move_column.bind(to_index, from_index))
		undo_redo.commit_action()
	else:
		data_processor.move_column(from_index, to_index)
	
	if from_index < _type_definitions.size():
		var temp: Dictionary = _type_definitions[from_index]
		_type_definitions.remove_at(from_index)
		_type_definitions.insert(to_index, temp)
	
	column_moved.emit(from_index, to_index)
	data_changed.emit("column_moved", {"from_index": from_index, "to_index": to_index})
	
	return true


## 重命名列
func rename_column(column_index: int, new_name: String) -> bool:
	if not data_processor:
		return false

	_ensure_type_definitions_size()

	var header := get_header()
	if column_index < 0 or column_index >= header.size():
		return false

	var old_name := header[column_index]
	new_name = new_name.strip_edges()
	if new_name.is_empty() or new_name == old_name:
		return true

	if enable_undo_redo:
		undo_redo.create_action("Rename Column")
		undo_redo.add_do_method(data_processor.rename_column.bind(column_index, new_name))
		undo_redo.add_undo_method(data_processor.rename_column.bind(column_index, old_name))
		undo_redo.commit_action()
	else:
		data_processor.rename_column(column_index, new_name)

	if column_index < _type_definitions.size():
		var type_def: Dictionary = _type_definitions[column_index]
		type_def = type_def.duplicate()
		type_def["name"] = new_name
		_type_definitions[column_index] = type_def

		_column_types.erase(old_name)
		_column_types[new_name] = type_def.get("type", "string")

	data_changed.emit("column_renamed", {"column_index": column_index, "old_name": old_name, "column_name": new_name})
	return true


## 批量删除行
func batch_remove_rows(row_indices: PackedInt32Array) -> int:
	if not data_processor:
		return 0
	
	var sorted_indices := row_indices.duplicate()
	sorted_indices.sort()
	
	# 反转数组以便从大到小删除
	var reversed_indices := PackedInt32Array()
	for i in range(sorted_indices.size() - 1, -1, -1):
		reversed_indices.append(sorted_indices[i])
	
	if enable_undo_redo:
		undo_redo.create_action("Batch Remove Rows")
	
	var removed_count := 0
	for row_index in reversed_indices:
		var row_data: PackedStringArray = data_processor.get_row(row_index)
		
		if enable_undo_redo:
			undo_redo.add_do_method(data_processor.remove_row.bind(row_index))
			undo_redo.add_undo_method(data_processor.insert_row.bind(row_index, row_data))
		else:
			data_processor.remove_row(row_index)
		
		removed_count += 1
	
	if enable_undo_redo:
		undo_redo.commit_action()
	
	data_changed.emit("batch_rows_removed", {"count": removed_count})
	
	return removed_count
#endregion

#region 类型定义功能 Type Definition Features
## 设置类型定义
func set_type_definitions(definitions: Array) -> void:
	_type_definitions = definitions.duplicate()
	_column_types.clear()
	
	for i in range(definitions.size()):
		var definition: Dictionary = definitions[i]
		if definition.has("name"):
			_column_types[definition.name] = definition.get("type", "string")
	_ensure_type_definitions_size()


## 更新列类型定义
func update_column_type(column_index: int, type_definition: Dictionary) -> void:
	_ensure_type_definitions_size()
	if column_index >= 0 and column_index < _type_definitions.size():
		_type_definitions[column_index] = type_definition.duplicate()
		
		if type_definition.has("name"):
			_column_types[type_definition.name] = type_definition.get("type", "string")


## 将整列值转换为指定类型（用于字段类型变更）。
## options:
## - on_failure: "error" | "default"
## - empty_policy: "keep_empty" | "use_default"
## 返回：{changed:int, failed:int, filled_empty:int}
func convert_column_values(column_index: int, target_definition: Dictionary, options: Dictionary = {}) -> Dictionary:
	if not data_processor:
		return {"changed": 0, "failed": 0, "filled_empty": 0}
	if column_index < 0 or column_index >= get_column_count():
		return {"changed": 0, "failed": 0, "filled_empty": 0}

	var on_failure := str(options.get("on_failure", "default"))
	if on_failure not in ["error", "default"]:
		on_failure = "default"
	var empty_policy := str(options.get("empty_policy", "use_default"))
	if empty_policy not in ["keep_empty", "use_default"]:
		empty_policy = "use_default"

	var default_value := _get_effective_default_string(target_definition)
	var row_count := get_row_count()

	var changes: Array = []
	var changed := 0
	var failed := 0
	var filled_empty := 0

	for row in range(row_count):
		var old_value := data_processor.get_cell_value(row, column_index)
		var old_trim := old_value.strip_edges()

		if old_trim.is_empty():
			if empty_policy == "use_default" and not default_value.is_empty():
				# 空值填充默认值
				changes.append({"row": row, "column": column_index, "value": default_value})
				changed += 1
				filled_empty += 1
			continue

		var converted := _convert_string_to_type_string(old_trim, target_definition)
		if converted["ok"]:
			var new_value: String = converted["value"]
			if new_value != old_value:
				changes.append({"row": row, "column": column_index, "value": new_value})
				changed += 1
		else:
			failed += 1
			if on_failure == "default":
				# 强制写入默认值（可能为空）
				changes.append({"row": row, "column": column_index, "value": default_value})
				changed += 1

	if not changes.is_empty():
		# 走 DataModel 的批量接口以触发信号与（可选）UndoRedo。
		batch_set_cells(changes)

	return {"changed": changed, "failed": failed, "filled_empty": filled_empty}


## 将字符串按指定类型定义转换为“存储字符串”。
## 返回：{ok: bool, value: String}
func try_convert_string_to_type_string(value: String, type_def: Dictionary) -> Dictionary:
	return _convert_string_to_type_string(str(value), type_def)


## 获取指定类型定义的“有效默认值”（schema default 优先，否则 type default）。
func get_effective_default_string(type_def: Dictionary) -> String:
	return _get_effective_default_string(type_def)


func _get_effective_default_string(type_def: Dictionary) -> String:
	var t := str(type_def.get("type", "string")).strip_edges().to_lower()

	# 1) schema default（若提供）：尝试按目标类型转换；不兼容则忽略，避免“默认值本身不合法”导致整列被写成红色值。
	if type_def.has("default"):
		var v := str(type_def.get("default", "")).strip_edges()
		if not v.is_empty():
			var converted := _convert_string_to_type_string(v, type_def)
			if converted.get("ok", false):
				return str(converted.get("value", ""))

	# 2) enum：若未设置（或无效）schema default，则使用 enum_values 的第一个值
	if t == "enum":
		var enum_values: Array = type_def.get("enum_values", []) as Array
		if not enum_values.is_empty():
			return str(enum_values[0]).strip_edges()

	# 3) type default
	return _get_type_default_string(str(type_def.get("type", "string")))


func _get_type_default_string(type_name: String) -> String:
	var t := str(type_name).strip_edges().to_lower()
	match t:
		"bool":
			return "false"
		"int":
			return "0"
		"float":
			return "0"
		"vector2":
			return "0,0"
		"vector3":
			return "0,0,0"
		"color":
			return "#FFFFFFFF"
		"enum":
			var values: Array = type_definitions_get_enum_values(type_name)
			return str(values[0]) if not values.is_empty() else ""
		_:
			return ""


func type_definitions_get_enum_values(_unused: String) -> Array:
	# 兼容：enum 默认值优先使用当前定义的 enum_values（若存在）
	# 这里无法获取到具体列的 definition，因此由调用方通过 schema default 覆盖更可靠。
	return []


func _convert_string_to_type_string(value: String, type_def: Dictionary) -> Dictionary:
	var t := str(type_def.get("type", "string")).strip_edges().to_lower()

	match t:
		"string", "stringname", "json":
			return {"ok": true, "value": value}
		"int":
			if value.is_valid_int():
				return {"ok": true, "value": str(value.to_int())}
			# 允许 "0.0"/"1e3" 等可安全转换为整数的浮点文本（更贴近 int(float) 的行为）
			if value.is_valid_float():
				var f := value.to_float()
				if absf(f - round(f)) < 0.000001:
					return {"ok": true, "value": str(int(round(f)))}
			return {"ok": false}
		"float":
			if not value.is_valid_float():
				return {"ok": false}
			return {"ok": true, "value": str(value.to_float())}
		"bool":
			var v := value.to_lower()
			if v in ["true", "1", "yes", "y"]:
				return {"ok": true, "value": "true"}
			if v in ["false", "0", "no", "n"]:
				return {"ok": true, "value": "false"}
			return {"ok": false}
		"enum":
			var enum_values: Array = type_def.get("enum_values", []) as Array
			for ev in enum_values:
				if str(ev).strip_edges() == value:
					return {"ok": true, "value": value}
			return {"ok": false}
		"resource":
			# 资源类型仍以字符串存储；存在性由 ValidationManager 负责高亮
			return {"ok": true, "value": value}
		"vector2":
			var parts := _parse_number_list(value)
			if parts.size() < 2:
				return {"ok": false}
			return {"ok": true, "value": "%s,%s" % [str(parts[0]), str(parts[1])]}
		"vector3":
			var parts := _parse_number_list(value)
			if parts.size() < 3:
				return {"ok": false}
			return {"ok": true, "value": "%s,%s,%s" % [str(parts[0]), str(parts[1]), str(parts[2])]}
		"color":
			var c := _parse_color(value)
			if c == null:
				return {"ok": false}
			return {"ok": true, "value": _color_to_hex(c)}
		_:
			# 未知类型：不转换（保持字符串）
			return {"ok": true, "value": value}


func _parse_number_list(text: String) -> Array[float]:
	var cleaned := str(text).strip_edges()
	if cleaned.is_empty():
		return []
	var regex := RegEx.new()
	regex.compile("[-+]?\\d*\\.?\\d+(?:[eE][-+]?\\d+)?")
	var out: Array[float] = []
	for m in regex.search_all(cleaned):
		var s := m.get_string()
		if s.is_valid_float():
			out.append(s.to_float())
	return out


func _parse_color(text: String) -> Variant:
	var s := str(text).strip_edges()
	if s.is_empty():
		return null
	if s.begins_with("#"):
		var hex := s.substr(1)
		if hex.length() == 6 or hex.length() == 8:
			var r := hex.substr(0, 2).hex_to_int()
			var g := hex.substr(2, 2).hex_to_int()
			var b := hex.substr(4, 2).hex_to_int()
			var a := 255
			if hex.length() == 8:
				a = hex.substr(6, 2).hex_to_int()
			return Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0)

	var parts := _parse_number_list(s)
	if parts.size() >= 3:
		var a := parts[3] if parts.size() >= 4 else 1.0
		return Color(parts[0], parts[1], parts[2], a)
	return null


func _color_to_hex(c: Color) -> String:
	var r := clampi(int(round(c.r * 255.0)), 0, 255)
	var g := clampi(int(round(c.g * 255.0)), 0, 255)
	var b := clampi(int(round(c.b * 255.0)), 0, 255)
	var a := clampi(int(round(c.a * 255.0)), 0, 255)
	return "#%02X%02X%02X%02X" % [r, g, b, a]
#endregion

#region 选择功能 Selection Features
## 选择单元格
func select_cell(row_index: int, column_index: int, append: bool = false) -> void:
	var new_selections := PackedVector2Array()
	
	if append:
		new_selections = PackedVector2Array(selections)
	
	new_selections.append(Vector2i(row_index, column_index))
	selections = new_selections
	
	selection_changed.emit(selections)


## 选择矩形区域
func select_rect(from_row: int, from_col: int, to_row: int, to_col: int) -> void:
	var new_selections := PackedVector2Array()
	
	var start_row := mini(from_row, to_row)
	var end_row := maxi(from_row, to_row)
	var start_col := mini(from_col, to_col)
	var end_col := maxi(from_col, to_col)
	
	for row in range(start_row, end_row + 1):
		for col in range(start_col, end_col + 1):
			new_selections.append(Vector2i(row, col))
	
	selections = new_selections
	selection_changed.emit(selections)


## 清除选择
func clear_selection() -> void:
	selections.clear()
	selection_changed.emit(selections)


## 获取选中的行索引
func get_selected_rows() -> PackedInt32Array:
	var rows := PackedInt32Array()
	var row_set := {}
	
	for selection in selections:
		if selection is Vector2i or selection is Array:
			var row_index: int = selection[0] if selection is Array else selection.x
			if not row_set.has(row_index):
				row_set[row_index] = true
				rows.append(row_index)
	
	return rows


## 获取选中的列索引
func get_selected_columns() -> PackedInt32Array:
	var cols := PackedInt32Array()
	var col_set := {}
	
	for selection in selections:
		if selection is Vector2i or selection is Array:
			var col_index: int = selection[1] if selection is Array else selection.y
			if not col_set.has(col_index):
				col_set[col_index] = true
				cols.append(col_index)
	
	return cols


## 是否有选区
func has_selection() -> bool:
	return not selections.is_empty()
#endregion

#region 撤销/重做功能 Undo/Redo Features
## 撤销
func undo() -> void:
	if undo_redo and enable_undo_redo:
		undo_redo.undo()


## 重做
func redo() -> void:
	if undo_redo and enable_undo_redo:
		undo_redo.redo()


## 是否可以撤销
func can_undo() -> bool:
	return enable_undo_redo and undo_redo != null and undo_redo.has_undo()


## 是否可以重做
func can_redo() -> bool:
	return enable_undo_redo and undo_redo != null and undo_redo.has_redo()


## 是否可以撤销（兼容旧接口）
func has_undo() -> bool:
	return can_undo()


## 是否可以重做（兼容旧接口）
func has_redo() -> bool:
	return can_redo()


## 清空撤销/重做历史
func clear_undo_redo_history() -> void:
	if undo_redo:
		undo_redo.clear_history()
#endregion

#region 状态查询功能 State Query Features
## 是否有未保存修改
func is_modified() -> bool:
	return modified


## 清除未保存修改标记（保存成功后调用）
func clear_modified() -> void:
	modified = false
#endregion

#region 工具方法 Utility Methods
## 验证整表
func validate_all() -> Array:
	if not data_processor:
		return []

	_ensure_type_definitions_size()
	
	return data_processor.validate_all(_type_definitions)


## 搜索文本
func search_text(search_text: String, case_sensitive: bool = false, match_mode: int = MatchMode.MATCH_CONTAINS, search_columns: PackedInt32Array = PackedInt32Array()) -> Array:
	if not data_processor:
		return []
	
	return data_processor.search_text(search_text, case_sensitive, match_mode, search_columns)


## 替换文本
func replace_text(search_text: String, replace_text: String, case_sensitive: bool = false, match_mode: int = MatchMode.MATCH_CONTAINS, search_columns: PackedInt32Array = PackedInt32Array()) -> bool:
	if not data_processor:
		return false
	
	var success: bool = data_processor.replace_text(search_text, replace_text, case_sensitive, match_mode, search_columns)
	
	if success:
		data_changed.emit("replace_completed", {"search_text": search_text, "replace_text": replace_text})
	
	return success


## 过滤行
func filter_rows(filter_text: String, case_sensitive: bool = false, match_mode: int = MatchMode.MATCH_CONTAINS, filter_column: int = -1) -> PackedInt32Array:
	if not data_processor:
		return PackedInt32Array()
	
	return data_processor.filter_rows(filter_text, case_sensitive, match_mode, filter_column)


## 检查索引是否有效
func is_valid_index(row_index: int, column_index: int) -> bool:
	return data_processor.is_valid_index(row_index, column_index) if data_processor else false


## 获取行高
func get_row_height(row_index: int) -> int:
	return _row_heights.get(row_index, 30)


## 设置行高
func set_row_height(row_index: int, height: int) -> void:
	_row_heights[row_index] = height


## 获取列宽
func get_column_width(column_index: int) -> int:
	return _column_widths.get(column_index, 100)


## 设置列宽
func set_column_width(column_index: int, width: int) -> void:
	_column_widths[column_index] = width


## 重置所有布局
func reset_layout() -> void:
	_row_heights.clear()
	_column_widths.clear()


func _undo_batch_set_cells(cells: Array, old_values: Dictionary) -> void:
	var undo_cells := []
	for cell_data in cells:
		if cell_data is Dictionary and cell_data.has("row") and cell_data.has("column"):
			var row: int = cell_data.row
			var col: int = cell_data.column
			var key: Vector2i = Vector2i(row, col)
			if old_values.has(key):
				undo_cells.append({"row": row, "column": col, "value": old_values[key]})
	
	data_processor.batch_set_cells(undo_cells)


func _undo_remove_column(column_index: int, column_name: String) -> void:
	var row_count: int = data_processor.get_row_count()
	var default_value: String = ""
	
	for i in range(row_count):
		data_processor.set_cell_value(i, column_index, default_value)
	
	data_processor.insert_column(column_index, column_name, default_value)


func _on_data_processor_data_changed(change_type: String, details: Dictionary) -> void:
	match change_type:
		"load", "import":
			_ensure_type_definitions_size()
			_apply_type_definitions_from_header()
	data_changed.emit(change_type, details)


func _apply_type_definitions_from_header() -> void:
	if not data_processor:
		return

	var original_header := get_original_header()
	if original_header.is_empty():
		return

	var defs: Array = data_processor.parse_type_annotations(original_header)
	if defs.is_empty():
		return

	# 与当前列数对齐，避免极端情况下越界
	var col_count := get_column_count()
	if col_count <= 0:
		return

	if defs.size() > col_count:
		defs.resize(col_count)
	elif defs.size() < col_count:
		for i in range(defs.size(), col_count):
			var name := "Column_" + str(i + 1)
			defs.append({"name": name, "type": "string"})

	set_type_definitions(defs)
#endregion
