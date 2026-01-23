extends Node

## GDSV 类型注解解析测试脚本
## 验证类型注解语法解析与默认值、必填、枚举、数组元素类型等字段

#region 测试配置 Test Configuration
const DATA_DIR := "res://tests/type_annotation/data/"
const SAMPLE_FILE := DATA_DIR + "annotation_sample.gdsv"
#endregion

#region 测试状态 Test State
var processor: GDSVDataProcessor
var test_count := 0
var passed_count := 0
var failed_count := 0
var test_start_time := 0.0
#endregion

#region 生命周期方法 Lifecycle Methods
func _ready() -> void:
	_test_log_header()
	_test_setup_processor()
	_run_all_tests()
	_generate_summary_report()
#endregion

#region 测试流程 Composite Methods
func _run_all_tests() -> void:
	_run_test_parse_header()
	_run_test_required_and_defaults()
	_run_test_enum_and_array()
#endregion

#region 测试用例 Feature Methods
func _run_test_parse_header() -> void:
	TestOutputLogger.log("\n[测试 1] 类型注解解析 - 基础字段")
	TestOutputLogger.log(_repeat_str("-", 70))

	test_count += 1
	var test_name := "类型注解解析 - 字段数量与类型"

	var header := _get_sample_header()
	var definitions := processor.parse_type_annotations(header)

	var condition := definitions.size() == 5
	condition = condition and _find_def_type(definitions, "id") == "int"
	condition = condition and _find_def_type(definitions, "name") == "string"
	condition = condition and _find_def_type(definitions, "active") == "bool"
	condition = condition and _find_def_type(definitions, "rarity") == "enum"
	condition = condition and _find_def_type(definitions, "tags") == "array"

	if condition:
		_pass_test(test_name, "字段类型解析正确")
	else:
		_fail_test(test_name, "字段类型解析不符合预期")


func _run_test_required_and_defaults() -> void:
	TestOutputLogger.log("\n[测试 2] 类型注解解析 - 必填与默认值")
	TestOutputLogger.log(_repeat_str("-", 70))

	test_count += 1
	var test_name := "类型注解解析 - required 与 default"

	var header := _get_sample_header()
	var definitions := processor.parse_type_annotations(header)

	var required_ok := _is_field_required(definitions, "id")
	var name_default := _get_field_default(definitions, "name")
	var active_default := _get_field_default(definitions, "active")

	var condition := required_ok
	condition = condition and name_default == "Unknown"
	condition = condition and active_default == "false"

	if condition:
		_pass_test(test_name, "required/default 解析正确")
	else:
		_fail_test(test_name, "required/default 解析不符合预期")


func _run_test_enum_and_array() -> void:
	TestOutputLogger.log("\n[测试 3] 类型注解解析 - 枚举与数组元素类型")
	TestOutputLogger.log(_repeat_str("-", 70))

	test_count += 1
	var test_name := "类型注解解析 - enum 与 array"

	var header := _get_sample_header()
	var definitions := processor.parse_type_annotations(header)

	var enum_values := _get_enum_values(definitions, "rarity")
	var array_element := _get_array_element_type(definitions, "tags")

	var condition := enum_values.size() == 3
	condition = condition and enum_values[0] == "common"
	condition = condition and enum_values[1] == "rare"
	condition = condition and enum_values[2] == "epic"
	condition = condition and array_element == "string"

	if condition:
		_pass_test(test_name, "enum/array 解析正确")
	else:
		_fail_test(test_name, "enum/array 解析不符合预期")
#endregion

#region 断言与工具方法 Utility Methods
func _test_log_header() -> void:
	TestOutputLogger.log("\n" + _repeat_str("=", 70))
	TestOutputLogger.log("GDSV 类型注解解析测试")
	TestOutputLogger.log("验证注解语法解析、默认值与枚举/数组元素类型")
	TestOutputLogger.log(_repeat_str("=", 70) + "\n")
	
	if not FileAccess.file_exists(SAMPLE_FILE):
		TestOutputLogger.log("[失败] 测试数据不存在: %s" % SAMPLE_FILE)


func _test_setup_processor() -> void:
	processor = GDSVDataProcessor.new()
	add_child(processor)
	processor.default_delimiter = "\t"


func _get_sample_header() -> PackedStringArray:
	var file := FileAccess.open(SAMPLE_FILE, FileAccess.READ)
	if file == null:
		return PackedStringArray()

	var first_line := file.get_line()
	file.close()
	return PackedStringArray(first_line.split("\t"))


func _find_def_type(definitions: Array, field_name: String) -> String:
	for definition in definitions:
		if definition.get("name") == field_name:
			return str(definition.get("type", "")).to_lower()
	return ""


func _is_field_required(definitions: Array, field_name: String) -> bool:
	for definition in definitions:
		if definition.get("name") == field_name:
			return bool(definition.get("required", false))
	return false


func _get_field_default(definitions: Array, field_name: String) -> String:
	for definition in definitions:
		if definition.get("name") == field_name:
			return str(definition.get("default", ""))
	return ""


func _get_enum_values(definitions: Array, field_name: String) -> PackedStringArray:
	for definition in definitions:
		if definition.get("name") == field_name:
			var values: PackedStringArray = definition.get("enum_values", PackedStringArray())
			if values is PackedStringArray:
				var cleaned := PackedStringArray()
				for value in values:
					cleaned.append(str(value).strip_edges())
				return cleaned
	return PackedStringArray()


func _get_array_element_type(definitions: Array, field_name: String) -> String:
	for definition in definitions:
		if definition.get("name") == field_name:
			return str(definition.get("array_element_type", "")).to_lower()
	return ""


func _repeat_str(content: String, count: int) -> String:
	var output := ""
	for i in range(count):
		output += content
	return output


func _pass_test(test_name: String, message: String) -> void:
	passed_count += 1
	_print_result(test_name, true, message)


func _fail_test(test_name: String, message: String) -> void:
	failed_count += 1
	_print_result(test_name, false, message)


func _print_result(test_name: String, passed: bool, message: String) -> void:
	var status := "[通过]" if passed else "[失败]"
	if passed:
		TestOutputLogger.log("%s %s" % [status, test_name])
		return
	TestOutputLogger.log("%s %s - %s" % [status, test_name, message])
#endregion

#region 汇总报告 Composite Methods
func _generate_summary_report() -> void:
	var elapsed := (Time.get_ticks_msec() - test_start_time) / 1000.0

	TestOutputLogger.log("\n" + _repeat_str("=", 70))
	TestOutputLogger.log("测试执行完成")
	TestOutputLogger.log(_repeat_str("=", 70))
	TestOutputLogger.log("测试统计:")
	TestOutputLogger.log("  总数: %d" % test_count)
	TestOutputLogger.log("  通过: %d" % passed_count)
	TestOutputLogger.log("  失败: %d" % failed_count)
	TestOutputLogger.log("  成功率: %.1f%%" % (passed_count * 100.0 / test_count if test_count > 0 else 0.0))
	TestOutputLogger.log("  执行时间: %.3f 秒" % elapsed)
	TestOutputLogger.log(_repeat_str("=", 70) + "\n")
#endregion
