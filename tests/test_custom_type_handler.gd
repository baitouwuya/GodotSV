extends Node

## GDSV 自定义类型处理器测试脚本
## 验证 GDSVTypeHandlerRegistry 的自定义类型注册、注销、别名转换等功能

# 测试统计
var test_count := 0
var passed_count := 0
var failed_count := 0
var test_start_time := 0.0

# 测试用实例
var type_converter: GDSVTypeConverter

# GDScript 自定义类型（模式 A：处理器即类型）
const PercentageType = preload("res://tests/gdsv_type_percentage.gd")
# GDScript 自定义类型（模式 B：独立类 + 处理器桥接）
const GoldType = preload("res://tests/gold.gd")
const GoldHandlerType = preload("res://tests/gold_handler.gd")


func _log(message: String) -> void:
	print(message)
	TestOutputLogger.log(message)


func _is_gold(value: Variant) -> bool:
	return typeof(value) == TYPE_OBJECT and value != null and value.get_script() == GoldType


func _ready() -> void:
	# 等待 GDExtension 完全初始化
	await get_tree().process_frame
	await get_tree().process_frame

	_log("\n" + "=".repeat(70))
	_log("GDSV 自定义类型处理器测试")
	_log("=".repeat(70) + "\n")

	test_start_time = Time.get_ticks_msec()

	type_converter = GDSVTypeConverter.new()

	_run_all_tests()
	_generate_summary_report()


func _run_all_tests() -> void:
	_test_registry_get_all_types()
	_test_has_type_builtin()
	_test_has_type_unknown()
	_test_builtin_convert_sanity()
	_test_register_type_by_name()
	_test_get_type_for_alias()
	_test_convert_with_alias()
	_test_convert_result_with_alias()
	_test_unregister_type()
	_test_convert_after_unregister()
	_test_register_empty_name()
	_test_unregister_nonexistent()
	_test_type_system_integrity()
	_test_register_multiple_aliases()
	_test_overwrite_alias()
	# GDScript 自定义类型测试
	_test_gdscript_register_custom_type()
	_test_gdscript_convert_percentage()
	_test_gdscript_convert_percentage_decimal()
	_test_gdscript_convert_invalid_percentage()
	_test_gdscript_validate_percentage_range()
	_test_gdscript_unregister_custom_type()
	# 模式 B: 独立类 + 处理器桥接测试
	_test_gold_register()
	_test_gold_convert_plain()
	_test_gold_convert_suffix()
	_test_gold_convert_invalid()
	_test_gold_result_is_instance()
	_test_gold_unregister()


## 测试 1: 获取所有已注册类型
func _test_registry_get_all_types() -> void:
	_log("\n[测试 1] 获取所有已注册类型")
	_log("-".repeat(70))

	test_count += 1
	var registry := GDSVTypeHandlerRegistry.get_singleton()
	if not registry:
		failed_count += 1
		_log("  [失败] Registry 单例为 null")
		return

	var all_types: Array = registry.get_all_types()
	var expected_types := ["int", "float", "bool", "String", "Vector2", "Vector3",
		"Vector4", "Rect2", "Array", "StringName", "Color", "Resource", "enum"]

	var missing: PackedStringArray = []
	for expected_type: String in expected_types:
		var found := false
		for registered_type: StringName in all_types:
			if str(registered_type) == expected_type:
				found = true
				break
		if not found:
			missing.append(expected_type)

	if missing.is_empty():
		passed_count += 1
		_log("  [通过] 所有 %d 个内置类型均已注册" % expected_types.size())
	else:
		failed_count += 1
		_log("  [失败] 缺少类型: %s" % ", ".join(missing))


## 测试 2: has_type 对已知类型返回 true
func _test_has_type_builtin() -> void:
	_log("\n[测试 2] has_type 检查内置类型")
	_log("-".repeat(70))

	test_count += 1
	var registry := GDSVTypeHandlerRegistry.get_singleton()
	if not registry:
		failed_count += 1
		_log("  [失败] Registry 不可用")
		return

	var types_to_check := ["int", "float", "bool", "String"]
	var all_found := true
	for type_name: String in types_to_check:
		if not registry.has_type(type_name):
			all_found = false
			_log("  has_type('%s') = false (异常)" % type_name)

	if all_found:
		passed_count += 1
		_log("  [通过] 所有内置类型 has_type 返回 true")
	else:
		failed_count += 1
		_log("  [失败] 部分内置类型 has_type 返回 false")


## 测试 3: has_type 对未知类型返回 false
func _test_has_type_unknown() -> void:
	_log("\n[测试 3] has_type 检查未知类型")
	_log("-".repeat(70))

	test_count += 1
	var registry := GDSVTypeHandlerRegistry.get_singleton()
	if not registry:
		failed_count += 1
		_log("  [失败] Registry 不可用")
		return

	var unknown_types := ["nonexistent", "my_custom", "FooBar"]
	var all_false := true
	for type_name: String in unknown_types:
		if registry.has_type(type_name):
			all_false = false
			_log("  has_type('%s') = true (异常)" % type_name)

	if all_false:
		passed_count += 1
		_log("  [通过] 所有未知类型 has_type 返回 false")
	else:
		failed_count += 1
		_log("  [失败] 部分未知类型 has_type 返回 true")


## 测试 4: 内置类型转换基线测试
func _test_builtin_convert_sanity() -> void:
	_log("\n[测试 4] 内置类型转换基线测试")
	_log("-".repeat(70))

	test_count += 1

	var int_result: Variant = type_converter.convert_string("42", "int")
	var float_result: Variant = type_converter.convert_string("3.14", "float")
	var bool_result: Variant = type_converter.convert_string("true", "bool")

	var all_ok := true
	if typeof(int_result) != TYPE_INT or int_result != 42:
		all_ok = false
		_log("  int 转换异常: %s (type=%d)" % [str(int_result), typeof(int_result)])
	if typeof(float_result) != TYPE_FLOAT or abs(float_result - 3.14) > 0.001:
		all_ok = false
		_log("  float 转换异常: %s (type=%d)" % [str(float_result), typeof(float_result)])
	if typeof(bool_result) != TYPE_BOOL or bool_result != true:
		all_ok = false
		_log("  bool 转换异常: %s (type=%d)" % [str(bool_result), typeof(bool_result)])

	if all_ok:
		passed_count += 1
		_log("  [通过] 内置类型 convert_string 正常工作")
	else:
		failed_count += 1
		_log("  [失败] 内置类型 convert_string 存在问题")


## 测试 5: register_type_by_name 注册别名
func _test_register_type_by_name() -> void:
	_log("\n[测试 5] register_type_by_name 注册自定义别名")
	_log("-".repeat(70))

	test_count += 1
	var registry := GDSVTypeHandlerRegistry.get_singleton()
	if not registry:
		failed_count += 1
		_log("  [失败] Registry 不可用")
		return

	# 将 GDSVTypeInt 注册为 "score" 类型
	registry.register_type_by_name("score", "GDSVTypeInt")

	var has_score := registry.has_type("score")
	# 验证 get_all_types 包含 "score"
	var all_types: Array = registry.get_all_types()
	var found_in_list := false
	for t: StringName in all_types:
		if str(t) == "score":
			found_in_list = true
			break

	if has_score and found_in_list:
		passed_count += 1
		_log("  [通过] 别名 'score' 注册成功，has_type 和 get_all_types 均可查询")
	else:
		failed_count += 1
		_log("  [失败] has_type=%s, found_in_list=%s" % [str(has_score), str(found_in_list)])


## 测试 6: get_type 能获取别名对应的处理器
func _test_get_type_for_alias() -> void:
	_log("\n[测试 6] get_type 获取别名处理器")
	_log("-".repeat(70))

	test_count += 1
	var registry := GDSVTypeHandlerRegistry.get_singleton()
	if not registry:
		failed_count += 1
		_log("  [失败] Registry 不可用")
		return

	var handler: Variant = registry.get_type("score")
	if handler != null:
		passed_count += 1
		_log("  [通过] get_type('score') 返回有效处理器")
	else:
		failed_count += 1
		_log("  [失败] get_type('score') 返回 null")


## 测试 7: 通过别名进行类型转换
func _test_convert_with_alias() -> void:
	_log("\n[测试 7] 通过自定义别名进行类型转换")
	_log("-".repeat(70))

	test_count += 1

	var result: Dictionary = type_converter.convert_string_result("42", "score")
	var success: bool = result.get("success", false)
	var value: Variant = result.get("value", null)

	if success and typeof(value) == TYPE_INT and value == 42:
		passed_count += 1
		_log("  [通过] convert_string_result('42', 'score') = {success=true, value=42}")
	else:
		failed_count += 1
		_log("  [失败] 结果: success=%s, value=%s (type=%d)" % [
			str(success), str(value), typeof(value)
		])


## 测试 8: convert_string_result 返回正确的结果字典
func _test_convert_result_with_alias() -> void:
	_log("\n[测试 8] convert_string_result 使用自定义别名")
	_log("-".repeat(70))

	test_count += 1

	var result: Dictionary = type_converter.convert_string_result("100", "score")
	var success: bool = result.get("success", false)
	var value: Variant = result.get("value", null)
	var error_msg: String = result.get("error_message", "")

	if success and typeof(value) == TYPE_INT and value == 100 and error_msg.is_empty():
		passed_count += 1
		_log("  [通过] convert_string_result 返回 {success=true, value=100, error_message=''}")
	else:
		failed_count += 1
		_log("  [失败] 结果: success=%s, value=%s, error=%s" % [str(success), str(value), error_msg])


## 测试 9: unregister_type 注销自定义类型
func _test_unregister_type() -> void:
	_log("\n[测试 9] unregister_type 注销自定义类型")
	_log("-".repeat(70))

	test_count += 1
	var registry := GDSVTypeHandlerRegistry.get_singleton()
	if not registry:
		failed_count += 1
		_log("  [失败] Registry 不可用")
		return

	# 注销 "score"
	registry.unregister_type("score")

	var has_score := registry.has_type("score")
	if not has_score:
		passed_count += 1
		_log("  [通过] 注销后 has_type('score') = false")
	else:
		failed_count += 1
		_log("  [失败] 注销后 has_type('score') 仍返回 true")


## 测试 10: 注销后转换应失败
func _test_convert_after_unregister() -> void:
	_log("\n[测试 10] 注销后类型转换应失败")
	_log("-".repeat(70))

	test_count += 1

	var result: Dictionary = type_converter.convert_string_result("42", "score")
	var success: bool = result.get("success", false)

	if not success:
		passed_count += 1
		_log("  [通过] 注销后 convert_string_result 返回 success=false")
		var error_msg: String = result.get("error_message", "")
		if not error_msg.is_empty():
			_log("  错误信息: %s" % error_msg)
	else:
		failed_count += 1
		_log("  [失败] 注销后转换仍然成功: %s" % str(result.get("value")))


## 测试 11: 注册空名称应安全处理
func _test_register_empty_name() -> void:
	_log("\n[测试 11] 注册空名称类型")
	_log("-".repeat(70))

	test_count += 1
	var registry := GDSVTypeHandlerRegistry.get_singleton()
	if not registry:
		failed_count += 1
		_log("  [失败] Registry 不可用")
		return

	# 记录注册前类型数量
	var count_before: int = registry.get_all_types().size()

	# 注册空名称（应被安全忽略）
	registry.register_type_by_name("", "GDSVTypeInt")

	var count_after: int = registry.get_all_types().size()

	if count_before == count_after:
		passed_count += 1
		_log("  [通过] 空名称注册被正确拒绝，类型数量未变 (%d)" % count_before)
	else:
		failed_count += 1
		_log("  [失败] 空名称注册改变了类型数量: %d -> %d" % [count_before, count_after])


## 测试 12: 注销不存在的类型应安全处理
func _test_unregister_nonexistent() -> void:
	_log("\n[测试 12] 注销不存在的类型")
	_log("-".repeat(70))

	test_count += 1
	var registry := GDSVTypeHandlerRegistry.get_singleton()
	if not registry:
		failed_count += 1
		_log("  [失败] Registry 不可用")
		return

	var count_before: int = registry.get_all_types().size()

	# 注销一个从未注册过的类型
	registry.unregister_type("completely_nonexistent_type_12345")

	var count_after: int = registry.get_all_types().size()

	if count_before == count_after:
		passed_count += 1
		_log("  [通过] 注销不存在的类型安全完成，类型数量不变 (%d)" % count_before)
	else:
		failed_count += 1
		_log("  [失败] 注销操作改变了类型数量: %d -> %d" % [count_before, count_after])


## 测试 13: 注册/注销不影响内置类型
func _test_type_system_integrity() -> void:
	_log("\n[测试 13] 类型系统完整性验证")
	_log("-".repeat(70))

	test_count += 1
	var registry := GDSVTypeHandlerRegistry.get_singleton()
	if not registry:
		failed_count += 1
		_log("  [失败] Registry 不可用")
		return

	# 注册一个临时别名
	registry.register_type_by_name("temp_test_type", "GDSVTypeFloat")

	# 验证内置类型仍然正常工作
	var int_result: Dictionary = type_converter.convert_string_result("99", "int")
	var float_result: Dictionary = type_converter.convert_string_result("3.14", "float")
	var bool_result: Dictionary = type_converter.convert_string_result("true", "bool")

	# 注销临时别名
	registry.unregister_type("temp_test_type")

	# 再次验证内置类型
	var int_result2: Dictionary = type_converter.convert_string_result("99", "int")
	var float_result2: Dictionary = type_converter.convert_string_result("3.14", "float")
	var bool_result2: Dictionary = type_converter.convert_string_result("true", "bool")

	var all_ok := true
	if not int_result.get("success", false):
		all_ok = false
		_log("  注册期间 int 转换失败")
	if not float_result.get("success", false):
		all_ok = false
		_log("  注册期间 float 转换失败")
	if not bool_result.get("success", false):
		all_ok = false
		_log("  注册期间 bool 转换失败")
	if not int_result2.get("success", false):
		all_ok = false
		_log("  注销后 int 转换失败")
	if not float_result2.get("success", false):
		all_ok = false
		_log("  注销后 float 转换失败")
	if not bool_result2.get("success", false):
		all_ok = false
		_log("  注销后 bool 转换失败")

	if all_ok:
		passed_count += 1
		_log("  [通过] 注册/注销自定义类型不影响内置类型转换")
	else:
		failed_count += 1
		_log("  [失败] 内置类型转换受到影响")


## 测试 14: 注册多个别名指向不同类型
func _test_register_multiple_aliases() -> void:
	_log("\n[测试 14] 注册多个自定义别名")
	_log("-".repeat(70))

	test_count += 1
	var registry := GDSVTypeHandlerRegistry.get_singleton()
	if not registry:
		failed_count += 1
		_log("  [失败] Registry 不可用")
		return

	# 注册多个别名
	registry.register_type_by_name("hp", "GDSVTypeInt")
	registry.register_type_by_name("speed", "GDSVTypeFloat")
	registry.register_type_by_name("active", "GDSVTypeBool")

	# 验证转换
	var hp_result: Dictionary = type_converter.convert_string_result("100", "hp")
	var speed_result: Dictionary = type_converter.convert_string_result("9.8", "speed")
	var active_result: Dictionary = type_converter.convert_string_result("true", "active")

	# 清理
	registry.unregister_type("hp")
	registry.unregister_type("speed")
	registry.unregister_type("active")

	var all_ok := true
	if not hp_result.get("success", false) or hp_result.get("value") != 100:
		all_ok = false
		_log("  hp 转换异常: %s" % str(hp_result))
	if not speed_result.get("success", false) or abs(speed_result.get("value", 0.0) - 9.8) > 0.001:
		all_ok = false
		_log("  speed 转换异常: %s" % str(speed_result))
	if not active_result.get("success", false) or active_result.get("value") != true:
		all_ok = false
		_log("  active 转换异常: %s" % str(active_result))

	if all_ok:
		passed_count += 1
		_log("  [通过] 多个别名均可独立注册并正确转换")
	else:
		failed_count += 1
		_log("  [失败] 部分别名转换不正确")


## 测试 15: 覆盖已有别名注册
func _test_overwrite_alias() -> void:
	_log("\n[测试 15] 覆盖已有别名注册")
	_log("-".repeat(70))

	test_count += 1
	var registry := GDSVTypeHandlerRegistry.get_singleton()
	if not registry:
		failed_count += 1
		_log("  [失败] Registry 不可用")
		return

	# 先注册为 int
	registry.register_type_by_name("damage", "GDSVTypeInt")
	var result_int: Dictionary = type_converter.convert_string_result("50", "damage")

	# 覆盖为 float
	registry.register_type_by_name("damage", "GDSVTypeFloat")
	var result_float: Dictionary = type_converter.convert_string_result("50.5", "damage")

	# 清理
	registry.unregister_type("damage")

	var phase1_ok: bool = result_int.get("success", false) and result_int.get("value") == 50
	var phase2_ok: bool = result_float.get("success", false) and abs(result_float.get("value", 0.0) - 50.5) < 0.001

	if phase1_ok and phase2_ok:
		passed_count += 1
		_log("  [通过] 别名 'damage' 从 int 覆盖为 float 后转换正确")
	else:
		failed_count += 1
		_log("  [失败] phase1(int): %s, phase2(float): %s" % [str(result_int), str(result_float)])


## 测试 16: GDScript 自定义类型注册
func _test_gdscript_register_custom_type() -> void:
	_log("\n[测试 16] GDScript 自定义类型 - 注册百分比类型")
	_log("-".repeat(70))

	test_count += 1
	var registry := GDSVTypeHandlerRegistry.get_singleton()
	if not registry:
		failed_count += 1
		_log("  [失败] Registry 不可用")
		return

	var handler := PercentageType.new()
	registry.register_type(handler)

	if registry.has_type("percentage"):
		passed_count += 1
		_log("  [通过] GDScript 百分比类型注册成功")
	else:
		failed_count += 1
		_log("  [失败] 注册后 has_type('percentage') 返回 false")


## 测试 17: GDScript 自定义类型转换 - 百分比格式
func _test_gdscript_convert_percentage() -> void:
	_log("\n[测试 17] GDScript 自定义类型 - 百分比格式转换")
	_log("-".repeat(70))

	test_count += 1

	var result: Dictionary = type_converter.convert_string_result("50%", "percentage")
	var success: bool = result.get("success", false)
	var value: Variant = result.get("value", null)

	if success and typeof(value) == TYPE_FLOAT and abs(value - 0.5) < 0.001:
		passed_count += 1
		_log("  [通过] '50%%' -> %s" % str(value))
	else:
		failed_count += 1
		_log("  [失败] 结果: success=%s, value=%s (type=%d)" % [
			str(success), str(value), typeof(value)
		])
		var error_msg: String = result.get("error_message", "")
		if not error_msg.is_empty():
			_log("  错误信息: %s" % error_msg)


## 测试 18: GDScript 自定义类型转换 - 小数格式
func _test_gdscript_convert_percentage_decimal() -> void:
	_log("\n[测试 18] GDScript 自定义类型 - 小数格式转换")
	_log("-".repeat(70))

	test_count += 1

	var result: Dictionary = type_converter.convert_string_result("0.75", "percentage")
	var success: bool = result.get("success", false)
	var value: Variant = result.get("value", null)

	if success and typeof(value) == TYPE_FLOAT and abs(value - 0.75) < 0.001:
		passed_count += 1
		_log("  [通过] '0.75' -> %s" % str(value))
	else:
		failed_count += 1
		_log("  [失败] 结果: success=%s, value=%s (type=%d)" % [
			str(success), str(value), typeof(value)
		])


## 测试 19: GDScript 自定义类型转换 - 无效输入
func _test_gdscript_convert_invalid_percentage() -> void:
	_log("\n[测试 19] GDScript 自定义类型 - 无效输入处理")
	_log("-".repeat(70))

	test_count += 1

	var result: Dictionary = type_converter.convert_string_result("abc%", "percentage")
	var success: bool = result.get("success", false)

	if not success:
		passed_count += 1
		var error_msg: String = result.get("error_message", "")
		_log("  [通过] 无效输入 'abc%%' 正确返回失败: %s" % error_msg)
	else:
		failed_count += 1
		_log("  [失败] 无效输入应返回失败，但 success=true")


## 测试 20: GDScript 自定义类型 - 验证范围约束
func _test_gdscript_validate_percentage_range() -> void:
	_log("\n[测试 20] GDScript 自定义类型 - 验证范围约束")
	_log("-".repeat(70))

	test_count += 1

	# 正常范围内: "50%" -> 0.5，默认范围 [0, 1]
	var result_ok: Dictionary = type_converter.convert_string_result("50%", "percentage")
	# 超出范围: "200%" -> 2.0，默认范围 [0, 1]
	var result_over: Dictionary = type_converter.convert_string_result("200%", "percentage")

	var ok_success: bool = result_ok.get("success", false)
	# 200% = 2.0 应该转换成功（StringToVariant 不检查范围），但 validate 会拒绝
	var over_success: bool = result_over.get("success", false)

	# 注意：convert_string_result 不会自动调用 validate（除非有 constraints）
	# 所以 200% 也会成功转换为 2.0
	if ok_success and over_success:
		var ok_val: float = result_ok.get("value", 0.0)
		var over_val: float = result_over.get("value", 0.0)
		if abs(ok_val - 0.5) < 0.001 and abs(over_val - 2.0) < 0.001:
			passed_count += 1
			_log("  [通过] '50%%' -> %s, '200%%' -> %s (转换成功，范围验证独立)" % [str(ok_val), str(over_val)])
		else:
			failed_count += 1
			_log("  [失败] 值不正确: ok=%s, over=%s" % [str(ok_val), str(over_val)])
	else:
		failed_count += 1
		_log("  [失败] 转换失败: ok=%s, over=%s" % [str(ok_success), str(over_success)])


## 测试 21: GDScript 自定义类型 - 注销
func _test_gdscript_unregister_custom_type() -> void:
	_log("\n[测试 21] GDScript 自定义类型 - 注销百分比类型")
	_log("-".repeat(70))

	test_count += 1
	var registry := GDSVTypeHandlerRegistry.get_singleton()
	if not registry:
		failed_count += 1
		_log("  [失败] Registry 不可用")
		return

	registry.unregister_type("percentage")

	if not registry.has_type("percentage"):
		passed_count += 1
		_log("  [通过] GDScript 百分比类型注销成功")
	else:
		failed_count += 1
		_log("  [失败] 注销后 has_type('percentage') 仍返回 true")


## ======================================================================
## 模式 B 测试: 独立类 Gold + 桥接处理器 GoldHandler
## ======================================================================

## 测试 22: 注册 Gold 类型（模式 B）
func _test_gold_register() -> void:
	_log("\n[测试 22] 模式 B - 注册 Gold 类型（独立类 + 处理器桥接）")
	_log("-".repeat(70))

	test_count += 1
	var registry := GDSVTypeHandlerRegistry.get_singleton()
	if not registry:
		failed_count += 1
		_log("  [失败] Registry 不可用")
		return

	var handler := GoldHandlerType.new()
	registry.register_type(handler)

	if registry.has_type("Gold"):
		passed_count += 1
		_log("  [通过] Gold 类型注册成功")
	else:
		failed_count += 1
		_log("  [失败] 注册后 has_type('Gold') 返回 false")


## 测试 23: 纯数字字符串转换为 Gold 实例
func _test_gold_convert_plain() -> void:
	_log("\n[测试 23] 模式 B - 纯数字转换 '100' -> Gold")
	_log("-".repeat(70))

	test_count += 1

	var result: Dictionary = type_converter.convert_string_result("100", "Gold")
	var success: bool = result.get("success", false)
	var value: Variant = result.get("value", null)

	if success and _is_gold(value) and value.amount == 100:
		passed_count += 1
		_log("  [通过] '100' -> Gold(amount=100)")
	else:
		failed_count += 1
		_log("  [失败] success=%s, value=%s, type=%d" % [
			str(success), str(value), typeof(value)
		])


## 测试 24: 带后缀字符串转换
func _test_gold_convert_suffix() -> void:
	_log("\n[测试 24] 模式 B - 后缀格式转换 '500g' / '200gold'")
	_log("-".repeat(70))

	test_count += 1

	var result_g: Dictionary = type_converter.convert_string_result("500g", "Gold")
	var result_gold: Dictionary = type_converter.convert_string_result("200gold", "Gold")

	var g_ok: bool = result_g.get("success", false) and _is_gold(result_g.get("value")) and result_g.get("value").amount == 500
	var gold_ok: bool = result_gold.get("success", false) and _is_gold(result_gold.get("value")) and result_gold.get("value").amount == 200

	if g_ok and gold_ok:
		passed_count += 1
		_log("  [通过] '500g' -> Gold(500), '200gold' -> Gold(200)")
	else:
		failed_count += 1
		_log("  [失败] g=%s, gold=%s" % [str(result_g), str(result_gold)])


## 测试 25: 无效输入
func _test_gold_convert_invalid() -> void:
	_log("\n[测试 25] 模式 B - 无效输入 'abc'")
	_log("-".repeat(70))

	test_count += 1

	var result: Dictionary = type_converter.convert_string_result("abc", "Gold")
	var success: bool = result.get("success", false)

	if not success:
		passed_count += 1
		var error_msg: String = result.get("error_message", "")
		_log("  [通过] 无效输入正确返回失败: %s" % error_msg)
	else:
		failed_count += 1
		_log("  [失败] 无效输入应返回失败，但 success=true")


## 测试 26: 转换结果是 Gold 类实例（非基础类型）
func _test_gold_result_is_instance() -> void:
	_log("\n[测试 26] 模式 B - 验证结果是 Gold 类实例")
	_log("-".repeat(70))

	test_count += 1

	var result: Dictionary = type_converter.convert_string_result("42", "Gold")
	var value: Variant = result.get("value", null)

	if _is_gold(value):
		if value.amount == 42 and str(value) == "42g":
			passed_count += 1
			_log("  [通过] 结果是 Gold 实例, amount=%d, str=%s" % [value.amount, str(value)])
		else:
			failed_count += 1
			_log("  [失败] Gold 实例属性不正确: amount=%d, str=%s" % [value.amount, str(value)])
	else:
		failed_count += 1
		_log("  [失败] 结果不是 Gold 实例, type=%d" % typeof(value))


## 测试 27: 注销 Gold 类型
func _test_gold_unregister() -> void:
	_log("\n[测试 27] 模式 B - 注销 Gold 类型")
	_log("-".repeat(70))

	test_count += 1
	var registry := GDSVTypeHandlerRegistry.get_singleton()
	if not registry:
		failed_count += 1
		_log("  [失败] Registry 不可用")
		return

	registry.unregister_type("Gold")

	if not registry.has_type("Gold"):
		passed_count += 1
		_log("  [通过] Gold 类型注销成功")
	else:
		failed_count += 1
		_log("  [失败] 注销后 has_type('Gold') 仍返回 true")


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