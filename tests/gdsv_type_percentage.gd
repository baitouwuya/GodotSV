@tool
class_name GDSVTypePercentage
extends GDSVTypeHandler
## GDScript 自定义百分比类型处理器
##
## 将百分比字符串（如 "50%"、"0.5"）转换为浮点数（0.0 ~ 1.0）。
## 演示如何用 GDScript 扩展 GDSVTypeHandler 创建自定义类型。

func _get_type_name() -> StringName:
	return "percentage"


func _get_variant_type() -> int:
	return TYPE_FLOAT


func _get_display_name() -> String:
	return "百分比"


func _get_category() -> int:
	return GDSVTypeHandler.TYPE_CATEGORY_CUSTOM


func _get_description() -> String:
	return "百分比类型，支持 '50%' 或 '0.5' 格式，转换为 0.0~1.0 浮点数"


func _get_type_default_value() -> Variant:
	return 0.0


func _string_to_variant(input: String) -> Dictionary:
	var trimmed := input.strip_edges()
	if trimmed.is_empty():
		return {"success": true, "value": 0.0, "error_message": ""}

	if trimmed.ends_with("%"):
		var num_str := trimmed.substr(0, trimmed.length() - 1).strip_edges()
		if not num_str.is_valid_float():
			return {
				"success": false,
				"value": null,
				"error_message": "无效的百分比值: '%s'" % input
			}
		var val: float = num_str.to_float() / 100.0
		return {"success": true, "value": val, "error_message": ""}
	else:
		if not trimmed.is_valid_float():
			return {
				"success": false,
				"value": null,
				"error_message": "无效的百分比值: '%s'" % input
			}
		return {"success": true, "value": trimmed.to_float(), "error_message": ""}


func _variant_to_string(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
		var pct: float = float(value) * 100.0
		return {"success": true, "value": "%s%%" % str(pct), "error_message": ""}
	return {
		"success": false,
		"value": null,
		"error_message": "无法将类型 %d 转换为百分比字符串" % typeof(value)
	}


func _validate(value: Variant, constraints: Dictionary) -> Dictionary:
	if typeof(value) != TYPE_FLOAT and typeof(value) != TYPE_INT:
		return {
			"success": false,
			"value": null,
			"error_message": "百分比值必须是数值类型"
		}

	var val: float = float(value)
	var min_val: float = constraints.get("min_value", 0.0)
	var max_val: float = constraints.get("max_value", 1.0)

	if val < min_val or val > max_val:
		return {
			"success": false,
			"value": null,
			"error_message": "百分比值 %s 超出范围 [%s, %s]" % [str(val), str(min_val), str(max_val)]
		}

	return {"success": true, "value": value, "error_message": ""}
