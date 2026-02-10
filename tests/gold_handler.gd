@tool
class_name GoldHandler
extends GDSVTypeHandler
## Gold 类型的 GDSV 桥接处理器
##
## 将独立数据类 Gold 注册到 GDSV 类型系统。
## 支持 "100"、"100g"、"100gold" 格式的字符串转换。
## 这是模式 B（独立类 + 处理器桥接）的示例。

const _Gold = preload("res://tests/gold.gd")


func _get_type_name() -> StringName:
	return "Gold"


func _get_variant_type() -> int:
	return TYPE_OBJECT


func _get_display_name() -> String:
	return "金币"


func _get_category() -> int:
	return GDSVTypeHandler.TYPE_CATEGORY_CUSTOM


func _get_description() -> String:
	return "游戏金币类型，将数字字符串转换为 Gold 实例"


func _get_type_default_value() -> Variant:
	return _Gold.new(0)


func _string_to_variant(input: String) -> Dictionary:
	var trimmed := input.strip_edges()
	if trimmed.is_empty():
		return {"success": true, "value": _Gold.new(0), "error_message": ""}

	var num_str := trimmed
	if num_str.ends_with("gold"):
		num_str = num_str.substr(0, num_str.length() - 4).strip_edges()
	elif num_str.ends_with("g"):
		num_str = num_str.substr(0, num_str.length() - 1).strip_edges()

	if not num_str.is_valid_int():
		return {
			"success": false,
			"value": null,
			"error_message": "无效的金币值: '%s'" % input
		}

	return {"success": true, "value": _Gold.new(num_str.to_int()), "error_message": ""}


func _variant_to_string(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_OBJECT and value != null and value.get_script() == _Gold:
		return {"success": true, "value": "%dg" % value.amount, "error_message": ""}
	return {"success": false, "value": null, "error_message": "非 Gold 类型"}


func _validate(value: Variant, constraints: Dictionary) -> Dictionary:
	if typeof(value) != TYPE_OBJECT or value == null or value.get_script() != _Gold:
		return {"success": false, "value": null, "error_message": "值必须是 Gold 类型"}
	var min_val: int = constraints.get("min_value", 0)
	if value.amount < min_val:
		return {
			"success": false,
			"value": null,
			"error_message": "金币数量 %d 低于最小值 %d" % [value.amount, min_val]
		}
	return {"success": true, "value": value, "error_message": ""}
