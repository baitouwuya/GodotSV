class_name GDSVFieldDefinition
extends Resource

## CSV 字段定义，用于描述 CSV 文件中某个字段的类型、默认值和验证规则

enum FieldType {
	TYPE_STRING,           ## 字符串类型
	TYPE_INT,              ## 整数类型
	TYPE_FLOAT,            ## 浮点数类型
	TYPE_BOOL,             ## 布尔类型
	TYPE_STRING_NAME,      ## StringName 类型
	TYPE_JSON,             ## JSON 类型（解析为 Dictionary 或 Array）
	TYPE_ARRAY,            ## 数组类型（逗号分隔字符串）
	TYPE_TEXTURE,          ## Texture2D 资源类型
	TYPE_SCENE,            ## PackedScene 资源类型
	TYPE_RESOURCE,         ## 通用 Resource 类型
}

## 字段名称
@export var field_name: StringName

## 字段类型
@export var type: FieldType = FieldType.TYPE_STRING

## 默认值
@export var default_value: Variant

## 是否为必需字段
@export var required: bool = false

## 最小值（仅对 int 和 float 有效）
@export var min_value: Variant

## 最大值（仅对 int 和 float 有效）
@export var max_value: Variant

## 枚举值列表（用于枚举验证）
@export var enum_values: Array = []

## 是否唯一（用于唯一性约束）
@export var unique: bool = false

## 资源基础路径（用于 TYPE_RESOURCE、TYPE_TEXTURE、TYPE_SCENE）
@export var resource_base_path: String = ""

## 字段描述/注释
@export var description: String = ""


func _init(p_field_name: StringName = &"", p_type: FieldType = FieldType.TYPE_STRING) -> void:
	field_name = p_field_name
	type = p_type


## 设置字段类型，返回 self 支持链式调用
func with_type(p_type: FieldType) -> GDSVFieldDefinition:
	type = p_type
	return self


## 设置默认值，返回 self 支持链式调用
func with_default(p_default_value: Variant) -> GDSVFieldDefinition:
	default_value = p_default_value
	return self


## 设置是否必需，返回 self 支持链式调用
func with_required(p_required: bool = true) -> GDSVFieldDefinition:
	required = p_required
	return self


## 设置范围约束，返回 self 支持链式调用
func with_range(p_min: Variant, p_max: Variant) -> GDSVFieldDefinition:
	min_value = p_min
	max_value = p_max
	return self


## 设置枚举值，返回 self 支持链式调用
func with_enum(p_enum_values: Array) -> GDSVFieldDefinition:
	enum_values = p_enum_values
	return self


## 设置是否唯一，返回 self 支持链式调用
func with_unique(p_unique: bool = true) -> GDSVFieldDefinition:
	unique = p_unique
	return self


## 设置资源基础路径，返回 self 支持链式调用
func with_resource_base_path(p_path: String) -> GDSVFieldDefinition:
	resource_base_path = p_path
	return self


## 设置描述，返回 self 支持链式调用
func with_description(p_desc: String) -> GDSVFieldDefinition:
	description = p_desc
	return self


## 获取类型的默认值
func get_type_default() -> Variant:
	match type:
		FieldType.TYPE_INT:
			return 0
		FieldType.TYPE_FLOAT:
			return 0.0
		FieldType.TYPE_BOOL:
			return false
		FieldType.TYPE_STRING_NAME:
			return &""
		FieldType.TYPE_JSON:
			return null
		FieldType.TYPE_ARRAY:
			return []
		FieldType.TYPE_RESOURCE, FieldType.TYPE_TEXTURE, FieldType.TYPE_SCENE:
			return null
		_:
			return ""


## 验证值是否符合字段定义
func validate_value(value: Variant, row_index: int) -> bool:
	# 检查必需字段
	if required and is_value_empty(value):
		return false
	
	# 检查范围约束
	if not _validate_range(value):
		return false
	
	# 检查枚举约束
	if not _validate_enum(value):
		return false
	
	return true


## 获取验证错误信息
func get_validation_error(value: Variant, row_index: int) -> String:
	if required and is_value_empty(value):
		return "行 %d: 字段 '%s' 是必需字段，但值为空" % [row_index, field_name]
	
	if not _validate_range(value):
		return "行 %d: 字段 '%s' 的值 %s 超出范围 [%s, %s]" % [row_index, field_name, value, min_value, max_value]
	
	if not _validate_enum(value):
		return "行 %d: 字段 '%s' 的值 %s 不在枚举值列表中: %s" % [row_index, field_name, value, enum_values]
	
	return ""


## 判断值是否为空
func is_value_empty(value: Variant) -> bool:
	if value == null:
		return true
	
	if type == FieldType.TYPE_STRING and value == "":
		return true
	
	if type == FieldType.TYPE_STRING_NAME and value == &"":
		return true
	
	if type == FieldType.TYPE_ARRAY and (value == null or (value is Array and value.is_empty())):
		return true
	
	return false


#region 私有方法 Private Methods
## 验证范围约束
func _validate_range(value: Variant) -> bool:
	if min_value == null and max_value == null:
		return true
	
	if value == null:
		return true
	
	match type:
		FieldType.TYPE_INT:
			if min_value != null and int(value) < int(min_value):
				return false
			if max_value != null and int(value) > int(max_value):
				return false
		FieldType.TYPE_FLOAT:
			if min_value != null and float(value) < float(min_value):
				return false
			if max_value != null and float(value) > float(max_value):
				return false
	
	return true


## 验证枚举约束
func _validate_enum(value: Variant) -> bool:
	if enum_values.is_empty():
		return true
	
	return value in enum_values
#endregion
