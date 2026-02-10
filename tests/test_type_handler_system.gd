extends Node

## GDSV 类型处理器系统测试脚本
## 验证 GDSVTypeHandlerRegistry 单例、类型处理器获取、转换与约束验证

# 测试统计
var test_count := 0
var passed_count := 0
var failed_count := 0
var test_start_time := 0.0

# 测试用实例
var type_converter: GDSVTypeConverter


func _log(message: String) -> void:
	print(message)
	TestOutputLogger.log(message)


func _ready() -> void:
	# 等待 GDExtension 完全初始化
	await get_tree().process_frame
	await get_tree().process_frame

	_log("\n" + "=".repeat(70))
	_log("GDSV 类型处理器系统测试")
	_log("=".repeat(70) + "\n")

	test_start_time = Time.get_ticks_msec()

	type_converter = GDSVTypeConverter.new()

	_run_all_tests()
	_generate_summary_report()


func _run_all_tests() -> void:
	_test_registry_singleton()
	_test_get_type_handlers()
	_test_string_to_variant()
	_test_validate_with_constraints()


## 测试 1: Registry 单例获取
func _test_registry_singleton() -> void:
	_log("\n[测试 1] Registry 单例获取")
	_log("-".repeat(70))

	test_count += 1
	var registry := GDSVTypeHandlerRegistry.get_singleton()

	if registry != null:
		passed_count += 1
		_log("  [通过] Registry 单例获取成功: %s" % registry.get_class())
	else:
		failed_count += 1
		_log("  [失败] Registry 单例为 null")


## 测试 2: 获取基础类型处理器
func _test_get_type_handlers() -> void:
	_log("\n[测试 2] 获取基础类型处理器")
	_log("-".repeat(70))

	test_count += 1
	var registry := GDSVTypeHandlerRegistry.get_singleton()
	if not registry:
		failed_count += 1
		_log("  [失败] Registry 不可用，跳过测试")
		return

	var types_to_check := ["int", "float", "bool", "String"]
	var all_found := true

	for type_name: String in types_to_check:
		var has_it := registry.has_type(type_name)
		if not has_it:
			all_found = false
			_log("  %s handler: 未找到" % type_name)
		else:
			_log("  %s handler: 已注册" % type_name)

	if all_found:
		passed_count += 1
		_log("  [通过] 所有基础类型处理器均可获取")
	else:
		failed_count += 1
		_log("  [失败] 部分类型处理器缺失")


## 测试 3: 类型转换验证（通过 GDSVTypeConverter）
func _test_string_to_variant() -> void:
	_log("\n[测试 3] 类型转换验证")
	_log("-".repeat(70))

	test_count += 1

	var all_correct := true

	# 测试 int 转换
	var int_result: Dictionary = type_converter.convert_string_result("42", "int")
	_log("  int '42' -> %s" % str(int_result))
	if not int_result.get("success", false) or int_result.get("value") != 42:
		all_correct = false

	# 测试 bool 转换
	var bool_result: Dictionary = type_converter.convert_string_result("true", "bool")
	_log("  bool 'true' -> %s" % str(bool_result))
	if not bool_result.get("success", false) or bool_result.get("value") != true:
		all_correct = false

	# 测试 float 转换
	var float_result: Dictionary = type_converter.convert_string_result("3.14", "float")
	_log("  float '3.14' -> %s" % str(float_result))
	if not float_result.get("success", false):
		all_correct = false

	# 测试 String 转换
	var str_result: Dictionary = type_converter.convert_string_result("hello", "String")
	_log("  String 'hello' -> %s" % str(str_result))
	if not str_result.get("success", false) or str_result.get("value") != "hello":
		all_correct = false

	if all_correct:
		passed_count += 1
		_log("  [通过] 所有类型转换正确")
	else:
		failed_count += 1
		_log("  [失败] 部分类型转换存在错误")


## 测试 4: 未知类型转换应安全失败
func _test_validate_with_constraints() -> void:
	_log("\n[测试 4] 未知类型安全处理")
	_log("-".repeat(70))

	test_count += 1

	# 测试不存在的类型不会崩溃
	var result: Dictionary = type_converter.convert_string_result("42", "nonexistent_type")
	var success: bool = result.get("success", false)

	if not success:
		passed_count += 1
		_log("  [通过] 未知类型转换安全返回失败")
		var error_msg: String = result.get("error_message", "")
		if not error_msg.is_empty():
			_log("  错误信息: %s" % error_msg)
	else:
		failed_count += 1
		_log("  [失败] 未知类型转换不应成功")


func _generate_summary_report() -> void:
	var elapsed := (Time.get_ticks_msec() - test_start_time) / 1000.0

	_log("\n" + "=".repeat(70))
	_log("测试执行完成")
	_log("=".repeat(70))
	_log("测试统计:")
	_log("  总数: %d" % test_count)
	_log("  通过: %d" % passed_count)
	_log("  失败: %d" % failed_count)
	_log("  成功率: %.1f%%" % (passed_count * 100.0 / test_count if test_count > 0 else 0.0))
	_log("  执行时间: %.3f 秒" % elapsed)
	_log("=".repeat(70) + "\n")
