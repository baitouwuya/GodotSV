class_name GDSVSchema
extends Resource

## GDSV 数据模式定义，用于定义 GDSV 文件的整体结构、字段定义和验证规则

## 字段定义字典（字段名 -> GDSVFieldDefinition）
@export var field_definitions: Dictionary = {}

## 是否包含表头
@export var has_header: bool = true

## 分隔符（默认为逗号）
@export var delimiter: String = ","


func _init() -> void:
	field_definitions = {}


## 添加字段定义
func add_field(field_name: StringName, field_type: GDSVFieldDefinition.FieldType = GDSVFieldDefinition.FieldType.TYPE_STRING) -> GDSVFieldDefinition:
	var definition := GDSVFieldDefinition.new(field_name, field_type)
	field_definitions[field_name] = definition
	return definition


## 获取字段定义
func get_field_definition(field_name: StringName) -> GDSVFieldDefinition:
	return field_definitions.get(field_name)


## 获取所有字段名
func get_field_names() -> Array:
	return field_definitions.keys()


## 检查是否包含字段
func has_field(field_name: StringName) -> bool:
	return field_definitions.has(field_name)


## 获取字段数量
func get_field_count() -> int:
	return field_definitions.size()


## 获取必需字段列表
func get_required_fields() -> Array:
	var required := []
	for field_name in field_definitions:
		var definition: GDSVFieldDefinition = field_definitions[field_name]
		if definition.required:
			required.append(field_name)
	return required


## 获取唯一字段列表
func get_unique_fields() -> Array:
	var unique := []
	for field_name in field_definitions:
		var definition: GDSVFieldDefinition = field_definitions[field_name]
		if definition.unique:
			unique.append(field_name)
	return unique


## 验证表头是否符合 Schema
func validate_header(header_row: PackedStringArray) -> Array[String]:
	var errors: Array[String] = []
	var required_fields := get_required_fields()
	
	# 检查必需字段是否存在
	for required_field in required_fields:
		if not required_field in header_row:
			errors.append("缺少必需字段: %s" % required_field)
	
	return errors


## 验证行数据是否符合 Schema
func validate_row(row_data: Dictionary, row_index: int) -> Array[String]:
	var errors: Array[String] = []
	
	for field_name in field_definitions:
		var definition: GDSVFieldDefinition = field_definitions[field_name]
		var value := row_data.get(field_name)
		
		if not definition.validate_value(value, row_index):
			errors.append(definition.get_validation_error(value, row_index))
	
	return errors


## 获取字段索引映射（字段名 -> 列索引）
func get_header_indices(header_row: PackedStringArray) -> Dictionary:
	var indices := {}
	for i in range(header_row.size()):
		var field_name: StringName = StringName(header_row[i].strip_edges())
		if has_field(field_name):
			indices[field_name] = i
	return indices
