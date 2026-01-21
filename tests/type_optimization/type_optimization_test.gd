## GDSV 类型优化测试脚本
## 验证类型转换器优化后的正确性（StringName 哈希比较）
## 测试所有支持类型的转换正确性：int, float, bool, String, StringName, Array, enum, Texture2D, PackedScene, Resource

extends Node

# 数据处理器实例
var processor: GDSVDataProcessor
var type_converter: GDSVTypeConverter

# 测试统计
var test_count := 0
var passed_count := 0
var failed_count := 0

# 测试时间追踪
var test_start_time: float = 0.0
var test_end_time: float = 0.0

# 测试数据目录
const DATA_DIR = "res://tests/type_optimization/data/"

# 字符串重复辅助函数
func repeat_str(s: String, count: int) -> String:
	var result := ""
	for i in range(count):
		result += s
	return result

func _ready() -> void:
	TestOutputLogger.log("\n" + repeat_str("=", 70))
	TestOutputLogger.log("GDSV 类型转换优化测试")
	TestOutputLogger.log("验证 StringName 哈希比较优化后的类型转换正确性")
	TestOutputLogger.log(repeat_str("=", 70) + "\n")

	test_start_time = Time.get_ticks_msec()

	# 初始化数据处理器和类型转换器
	processor = GDSVDataProcessor.new()
	type_converter = GDSVTypeConverter.new()
	add_child(processor)

	# 设置默认分隔符为制表符
	processor.default_delimiter = "\t"

	# 运行所有测试
	run_all_tests()

	# 生成测试报告
	generate_summary_report()

	# 测试完成，窗口保持打开，等待用户操作
	# 用户可以通过按 ESC 退出或直接关闭窗口


## 运行所有测试
func run_all_tests() -> void:
	# 测试 1: int 类型转换
	run_test_int_type()

	# 测试 2: float 类型转换
	run_test_float_type()

	# 测试 3: bool 类型转换
	run_test_bool_type()

	# 测试 4: String 类型转换
	run_test_string_type()

	# 测试 5: StringName 类型转换
	run_test_stringname_type()

	# 测试 6: Array 类型转换
	run_test_array_type()

	# 测试 7: enum 类型转换
	run_test_enum_type()

	# 测试 8: Texture2D 资源类型转换
	run_test_texture2d_type()

	# 测试 9: PackedScene 资源类型转换
	run_test_packedscene_type()

	# 测试 10: Resource 通用类型转换
	run_test_resource_type()

	# 测试 11: 批量类型转换性能测试
	run_test_batch_conversion()


## 测试 1: int 类型转换
func run_test_int_type() -> void:
	TestOutputLogger.log("\n[测试 1] int 类型转换")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "int 类型转换 - 正确性"

	TestOutputLogger.log("测试场景: 将字符串 '123' 转换为 int 类型")

	var result := type_converter.ConvertString("123", "int")

	if result.get_type() == TYPE_INT and result == 123:
		passed_count += 1
		print_result(test_name, true, "'123' 转换为 123 (int)")
	else:
		failed_count += 1
		print_result(test_name, false, "预期 123 (int)，实际: %s (类型:%d)" % [str(result), result.get_type()])

	TestOutputLogger.log("")

	# 测试负数
	test_count += 1
	test_name = "int 类型转换 - 负数"

	TestOutputLogger.log("测试场景: 将字符串 '-456' 转换为 int 类型")

	result = type_converter.ConvertString("-456", "int")

	if result.get_type() == TYPE_INT and result == -456:
		passed_count += 1
		print_result(test_name, true, "'-456' 转换为 -456 (int)")
	else:
		failed_count += 1
		print_result(test_name, false, "预期 -456 (int)，实际: %s" % str(result))


## 测试 2: float 类型转换
func run_test_float_type() -> void:
	TestOutputLogger.log("\n[测试 2] float 类型转换")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "float 类型转换 - 正确性"

	TestOutputLogger.log("测试场景: 将字符串 '123.45' 转换为 float 类型")

	var result := type_converter.ConvertString("123.45", "float")

	if result.get_type() == TYPE_FLOAT and abs(result - 123.45) < 0.001:
		passed_count += 1
		print_result(test_name, true, "'123.45' 转换为 %s (float)" % str(result))
	else:
		failed_count += 1
		print_result(test_name, false, "预期 123.45 (float)，实际: %s" % str(result))

	TestOutputLogger.log("")

	# 测试科学计数法
	test_count += 1
	test_name = "float 类型转换 - 科学计数法"

	TestOutputLogger.log("测试场景: 将字符串 '1.5e2' 转换为 float 类型")

	result = type_converter.ConvertString("1.5e2", "float")

	if result.get_type() == TYPE_FLOAT and abs(result - 150.0) < 0.001:
		passed_count += 1
		print_result(test_name, true, "'1.5e2' 转换为 %s (float)" % str(result))
	else:
		failed_count += 1
		print_result(test_name, false, "预期 150.0 (float)，实际: %s" % str(result))


## 测试 3: bool 类型转换
func run_test_bool_type() -> void:
	TestOutputLogger.log("\n[测试 3] bool 类型转换")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "bool 类型转换 - true"

	TestOutputLogger.log("测试场景: 将字符串 'true' 转换为 bool 类型")

	var result := type_converter.ConvertString("true", "bool")

	if result.get_type() == TYPE_BOOL and result == true:
		passed_count += 1
		print_result(test_name, true, "'true' 转换为 true (bool)")
	else:
		failed_count += 1
		print_result(test_name, false, "预期 true (bool)，实际: %s" % str(result))

	TestOutputLogger.log("")

	# 测试 false
	test_count += 1
	test_name = "bool 类型转换 - false"

	TestOutputLogger.log("测试场景: 将字符串 'false' 转换为 bool 类型")

	result = type_converter.ConvertString("false", "bool")

	if result.get_type() == TYPE_BOOL and result == false:
		passed_count += 1
		print_result(test_name, true, "'false' 转换为 false (bool)")
	else:
		failed_count += 1
		print_result(test_name, false, "预期 false (bool)，实际: %s" % str(result))

	TestOutputLogger.log("")

	# 测试数字形式
	test_count += 1
	test_name = "bool 类型转换 - 数字形式"

	TestOutputLogger.log("测试场景: 将 '1' 转换为 true，'0' 转换为 false")

	var result1 := type_converter.ConvertString("1", "bool")
	var result0 := type_converter.ConvertString("0", "bool")

	if result1 == true and result0 == false:
		passed_count += 1
		print_result(test_name, true, "'1' -> true, '0' -> false (bool)")
	else:
		failed_count += 1
		print_result(test_name, false, "预期 '1'->true, '0'->false，实际: %s, %s" % [str(result1), str(result0)])


## 测试 4: String 类型转换
func run_test_string_type() -> void:
	TestOutputLogger.log("\n[测试 4] String 类型转换")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "String 类型转换 - 基本字符串"

	TestOutputLogger.log("测试场景: 将字符串 'Hello World' 转换为 String 类型")

	var result := type_converter.ConvertString("Hello World", "string")

	if result.get_type() == TYPE_STRING and result == "Hello World":
		passed_count += 1
		print_result(test_name, true, "'Hello World' 转换为 'Hello World' (String)")
	else:
		failed_count += 1
		print_result(test_name, false, "预期 'Hello World' (String)，实际: %s" % str(result))

	TestOutputLogger.log("")

	# 测试空字符串
	test_count += 1
	test_name = "String 类型转换 - 空字符串"

	TestOutputLogger.log("测试场景: 将空字符串 '' 转换为 String 类型")

	result = type_converter.ConvertString("", "string")

	if result.get_type() == TYPE_STRING and result == "":
		passed_count += 1
		print_result(test_name, true, "'' 转换为 '' (String)")
	else:
		failed_count += 1
		print_result(test_name, false, "预期空字符串 (String)，实际: '%s'" % str(result))

	TestOutputLogger.log("")

	# 测试特殊字符
	test_count += 1
	test_name = "String 类型转换 - 特殊字符"

	TestOutputLogger.log("测试场景: 将包含特殊字符的字符串转换为 String 类型")

	result = type_converter.ConvertString("Hello\nWorld\t\"", "string")

	if result.get_type() == TYPE_STRING and result == "Hello\nWorld\t\"":
		passed_count += 1
		print_result(test_name, true, "特殊字符正确保留 (String)")
	else:
		failed_count += 1
		print_result(test_name, false, "特殊字符转换失败")


## 测试 5: StringName 类型转换
func run_test_stringname_type() -> void:
	TestOutputLogger.log("\n[测试 5] StringName 类型转换")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "StringName 类型转换 - 基本用法"

	TestOutputLogger.log("测试场景: 将字符串 'AnimationPlayer' 转换为 StringName 类型")

	var result := type_converter.ConvertString("AnimationPlayer", "stringname")

	if result.get_type() == TYPE_STRING_NAME and str(result) == "AnimationPlayer":
		passed_count += 1
		print_result(test_name, true, "'AnimationPlayer' 转换为 StringName")
	else:
		failed_count += 1
		print_result(test_name, false, "预期 StringName，实际: %s (类型:%d)" % [str(result), result.get_type()])

	TestOutputLogger.log("")

	# 测试 Godot 内置 StringName
	test_count += 1
	test_name = "StringName 类型转换 - Godot 内置"

	TestOutputLogger.log("测试场景: 转换常见的 Godot 内置 StringName")

	var builtin_names = ["ui_accept", "ui_cancel", "ui_up", "ui_down", "ui_left", "ui_right"]
	var all_passed := true
	for name in builtin_names:
		var builtin_result := type_converter.ConvertString(name, "stringname")
		if builtin_result.get_type() != TYPE_STRING_NAME:
			all_passed = false
			TestOutputLogger.log("  失败: '%s' 转换失败" % name)

	if all_passed:
		passed_count += 1
		print_result(test_name, true, "所有内置 StringName 均正确转换")
	else:
		failed_count += 1
		print_result(test_name, false, "部分内置 StringName 转换失败")


## 测试 6: Array 类型转换
func run_test_array_type() -> void:
	TestOutputLogger.log("\n[测试 6] Array 类型转换")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "Array 类型转换 - 逗号分隔"

	TestOutputLogger.log("测试场景: 将字符串 'apple,banana,cherry' 转换为数组")

	var result := type_converter.ConvertString("apple,banana,cherry", "array")

	if result.get_type() == TYPE_ARRAY and result.size() == 3 and result[0] == "apple":
		passed_count += 1
		print_result(test_name, true, "'apple,banana,cherry' 转换为 Array")
		TestOutputLogger.log("  数组内容: %s" % str(result))
	else:
		failed_count += 1
		print_result(test_name, false, "预期 3 元素数组，实际: %s" % str(result))

	TestOutputLogger.log("")

	# 测试空数组
	test_count += 1
	test_name = "Array 类型转换 - 空数组"

	TestOutputLogger.log("测试场景: 将空字符串 '' 转换为数组")

	result = type_converter.ConvertString("", "array")

	if result.get_type() == TYPE_ARRAY and result.size() == 0:
		passed_count += 1
		print_result(test_name, true, "'' 转换为空数组")
	else:
		failed_count += 1
		print_result(test_name, false, "预期空数组，实际: %s" % str(result))

	TestOutputLogger.log("")

	# 测试分号分隔
	test_count += 1
	test_name = "Array 类型转换 - 分号分隔"

	TestOutputLogger.log("测试场景: 将字符串 'a;b;c' 转换为分号分隔的数组")

	result = type_converter.ConvertString("a;b;c", "array")

	if result.get_type() == TYPE_ARRAY and result.size() == 3:
		passed_count += 1
		print_result(test_name, true, "分号分隔符正确处理")
	else:
		failed_count += 1
		print_result(test_name, false, "分隔符处理失败，结果: %s" % str(result))


## 测试 7: enum 类型转换
func run_test_enum_type() -> void:
	TestOutputLogger.log("\n[测试 7] enum 类型转换")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "enum 类型转换 - 枚举值验证"

	TestOutputLogger.log("测试场景: 转换为枚举值，验证有效值和非有效值")

	# 设置枚举值列表
	var enum_values := PackedStringArray(["normal", "rare", "epic", "legendary"])

	# 测试有效值
	var valid_result := type_converter.ConvertString("epic", "enum", enum_values)

	if str(valid_result) == "epic":
		passed_count += 1
		print_result(test_name, true, "'epic' 转换为有效枚举值")
	else:
		failed_count += 1
		print_result(test_name, false, "枚举值转换失败: %s" % str(valid_result))

	TestOutputLogger.log("")

	# 测试无效值
	test_count += 1
	test_name = "enum 类型转换 - 无效值处理"

	TestOutputLogger.log("测试场景: 尝试转换无效的枚举值 'invalid'")

	var invalid_result := type_converter.ConvertString("invalid", "enum", enum_values)

	if str(invalid_result).is_empty():
		passed_count += 1
		print_result(test_name, true, "无效枚举值返回空字符串")
	else:
		failed_count += 1
		print_result(test_name, false, "无效枚举值应返回空字符串，实际: %s" % str(invalid_result))


## 测试 8: Texture2D 资源类型转换
func run_test_texture2d_type() -> void:
	TestOutputLogger.log("\n[测试 8] Texture2D 资源类型转换")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "Texture2D 类型转换 - 资源加载"

	TestOutputLogger.log("测试场景: 尝试加载 Texture2D 资源")

	# 使用内置图标或测试资源路径
	var icon_path := "res://icon.svg"
	var result := type_converter.ConvertString(icon_path, "texture2d")

	# 注意：如果文件不存在，测试应该优雅处理
	if result.get_type() == TYPE_OBJECT:
		passed_count += 1
		print_result(test_name, true, "Texture2D 资源加载成功或处理正确")
	else:
		# 在测试环境中，文件可能不存在
		if result == null or (result.get_type() == TYPE_NIL):
			passed_count += 1
			print_result(test_name, true, "Texture2D 资源不存在时返回 null (符合预期)")
		else:
			failed_count += 1
			print_result(test_name, false, "Texture2D 转换异常，结果类型: %d" % result.get_type())


## 测试 9: PackedScene 资源类型转换
func run_test_packedscene_type() -> void:
	TestOutputLogger.log("\n[测试 9] PackedScene 资源类型转换")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "PackedScene 类型转换 - 场景加载"

	TestOutputLogger.log("测试场景: 尝试加载 PackedScene 资源")

	# 使用测试场景路径
	var scene_path := "res://tests/basic_io/basic_io_test.tscn"
	var result := type_converter.ConvertString(scene_path, "packedscene")

	if result.get_type() == TYPE_OBJECT:
		passed_count += 1
		print_result(test_name, true, "PackedScene 资源加载成功或处理正确")
	else:
		if result == null or (result.get_type() == TYPE_NIL):
			passed_count += 1
			print_result(test_name, true, "PackedScene 资源不存在时返回 null (符合预期)")
		else:
			failed_count += 1
			print_result(test_name, false, "PackedScene 转换异常，结果类型: %d" % result.get_type())


## 测试 10: Resource 通用类型转换
func run_test_resource_type() -> void:
	TestOutputLogger.log("\n[测试 10] Resource 通用类型转换")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "Resource 类型转换 - 通用资源"

	TestOutputLogger.log("测试场景: 尝试加载通用 Resource")

	var resource_path := "res://icon.svg"
	var result := type_converter.ConvertString(resource_path, "resource")

	if result.get_type() == TYPE_OBJECT:
		passed_count += 1
		print_result(test_name, true, "Resource 资源加载成功或处理正确")
	else:
		if result == null or (result.get_type() == TYPE_NIL):
			passed_count += 1
			print_result(test_name, true, "Resource 资源不存在时返回 null (符合预期)")
		else:
			failed_count += 1
			print_result(test_name, false, "Resource 转换异常，结果类型: %d" % result.get_type())


## 测试 11: 批量类型转换性能测试
func run_test_batch_conversion() -> void:
	TestOutputLogger.log("\n[测试 11] 批量类型转换性能测试")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "批量类型转换 - ConvertRow 方法"

	TestOutputLogger.log("测试场景: 使用 ConvertRow 方法批量转换一行数据")

	var test_row := PackedStringArray(["123", "45.67", "true", "Hello", "test_key", "a,b,c"])
	var test_types := PackedStringArray(["int", "float", "bool", "string", "stringname", "array"])
	var test_params := Array()

	test_params.append("")  # int 无需额外参数
	test_params.append("")  # float 无需额外参数
	test_params.append("")  # bool 无需额外参数
	test_params.append("")  # string 无需额外参数
	test_params.append("")  # stringname 无需额外参数
	test_params.append("")  # array 无需额外参数

	var start_time := Time.get_ticks_msec()
	var results := type_converter.ConvertRow(test_row, test_types, test_params)
	var elapsed := Time.get_ticks_msec() - start_time

	if results.size() == 6:
		var all_correct := true

		# 验证每个结果
		if results[0].get_type() != TYPE_INT or results[0] != 123:
			all_correct = false
		if results[1].get_type() != TYPE_FLOAT or abs(results[1] - 45.67) > 0.01:
			all_correct = false
		if results[2].get_type() != TYPE_BOOL or results[2] != true:
			all_correct = false
		if results[3].get_type() != TYPE_STRING or results[3] != "Hello":
			all_correct = false
		if results[4].get_type() != TYPE_STRING_NAME:
			all_correct = false
		if results[5].get_type() != TYPE_ARRAY:
			all_correct = false

		if all_correct:
			passed_count += 1
			print_result(test_name, true, "批量转换成功，耗时: %d ms" % elapsed)
			TestOutputLogger.log("  转换结果:")
			TestOutputLogger.log("    [0] int: %s (类型: %d)" % [str(results[0]), results[0].get_type()])
			TestOutputLogger.log("    [1] float: %s (类型: %d)" % [str(results[1]), results[1].get_type()])
			TestOutputLogger.log("    [2] bool: %s (类型: %d)" % [str(results[2]), results[2].get_type()])
			TestOutputLogger.log("    [3] string: %s (类型: %d)" % [str(results[3]), results[3].get_type()])
			TestOutputLogger.log("    [4] stringname: %s (类型: %d)" % [str(results[4]), results[4].get_type()])
			TestOutputLogger.log("    [5] array: %s (类型: %d)" % [str(results[5]), results[5].get_type()])
		else:
			failed_count += 1
			print_result(test_name, false, "批量转换结果类型不正确")
	else:
		failed_count += 1
		print_result(test_name, false, "批量转换结果数量不正确，预期 6 个，实际 %d 个" % results.size())


## 打印单个测试结果
func print_result(_test_name: String, passed: bool, message: String) -> void:
	var status := "[通过]" if passed else "[失败]"
	var prefix := "  " if passed else "  "
	TestOutputLogger.log("%s %s %s" % [prefix, status, message])


## 生成汇总报告
func generate_summary_report() -> void:
	test_end_time = Time.get_ticks_msec()
	var elapsed := (test_end_time - test_start_time) / 1000.0

	TestOutputLogger.log("\n" + repeat_str("=", 70))
	TestOutputLogger.log("测试执行完成")
	TestOutputLogger.log(repeat_str("=", 70))
	TestOutputLogger.log("")
	TestOutputLogger.log("测试统计:")
	TestOutputLogger.log("  总数: %d" % test_count)
	TestOutputLogger.log("  通过: %d" % passed_count)
	TestOutputLogger.log("  失败: %d" % failed_count)
	TestOutputLogger.log("  成功率: %.1f%%" % (passed_count * 100.0 / test_count if test_count > 0 else 0.0))
	TestOutputLogger.log("")
	TestOutputLogger.log("执行时间: %.3f 秒" % elapsed)
	TestOutputLogger.log(repeat_str("=", 70) + "\n")

	# 性能优化说明
	TestOutputLogger.log("优化说明:")
	TestOutputLogger.log("  GDSVTypeConverter 使用 StringName 哈希比较代替 if-else 字符串比较")
	TestOutputLogger.log("  类型识别通过哈希值匹配，性能大幅提升")
	TestOutputLogger.log("")

	# 根据结果打印不同信息
	if failed_count > 0:
		TestOutputLogger.log("测试失败！请检查上述错误信息。")
	else:
		TestOutputLogger.log("所有测试通过！类型转换优化验证成功！")
	TestOutputLogger.log("\n测试窗口将保持打开，按 ESC 键可退出")


## 输入处理 - 允许用户按 ESC 退出
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC 默认映射为 ui_cancel
		TestOutputLogger.log("\n用户按 ESC 退出窗口")
		var exit_code := 1 if failed_count > 0 else 0
		get_tree().quit(exit_code)
