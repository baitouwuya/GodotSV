## GDSV 基础I/O功能测试脚本
## 测试GDSV文件的读取、写入和基本类型转换功能
##
## 注意：本测试脚本使用 TestOutputLogger 进行输出，而非直接使用 TestOutputLogger.log("")
## 所有 test_output 均通过 TestOutputLogger.log("") 输出
##

extends Node

# 数据处理器实例
var processor: GDSVDataProcessor

# 测试统计
var test_count := 0
var passed_count := 0
var failed_count := 0

# 测试时间追踪
var test_start_time: float = 0.0
var test_end_time: float = 0.0

# 测试数据目录
const DATA_DIR = "res://tests/basic_io/data/"
const TEMP_DIR = "user://test_output/"

# 字符串重复辅助函数
func repeat_str(s: String, count: int) -> String:
	var result := ""
	for i in range(count):
		result += s
	return result

func _ready() -> void:
	TestOutputLogger.log("\n" + repeat_str("=", 70))
	TestOutputLogger.log("GDSV 基础 I/O 功能测试")
	TestOutputLogger.log(repeat_str("=", 70) + "\n")

	test_start_time = Time.get_ticks_msec()

	# 初始化数据处理器
	processor = GDSVDataProcessor.new()
	add_child(processor)

	# 确保临时目录存在
	DirAccess.make_dir_absolute(TEMP_DIR)

	# 运行所有测试
	run_all_tests()

	# 生成测试报告
	generate_summary_report()

	# 清理临时文件
	cleanup_temp_files()


## 运行所有测试
func run_all_tests() -> void:
	# 测试 1: 读取基本GDSV文件
	run_test_read_basic_gdsv()

	# 测试 2: 验证字段类型转换（int, float, bool, string）
	run_test_type_conversion()

	# 测试 3: 写入GDSV文件并读取验证
	run_test_write_and_read_gdsv()

	# 测试 4: 测试空文件处理
	run_test_empty_file()

	# 测试 5: 测试特殊字符处理
	run_test_special_characters()


## 测试 1: 读取基本GDSV文件
func run_test_read_basic_gdsv() -> void:
	TestOutputLogger.log("\n[测试 1] 读取基本GDSV文件")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "读取基本GDSV文件"

	var file_path := DATA_DIR + "basic_read.gdsv"

	TestOutputLogger.log("测试场景: 从文件读取GDSV格式数据")
	TestOutputLogger.log("文件路径: %s\n" % file_path)

	if not FileAccess.file_exists(file_path):
		failed_count += 1
		print_result(test_name, false, "测试文件不存在")
		return

	var success := processor.load_gdsv_file(file_path)

	if not success:
		failed_count += 1
		print_result(test_name, false, "文件读取失败: " + processor.last_error)
		return

	TestOutputLogger.log("文件读取成功!")
	TestOutputLogger.log("  行数: %d" % processor.get_row_count())
	TestOutputLogger.log("  列数: %d" % processor.get_column_count())
	TestOutputLogger.log("  表头: %s" % processor.get_header())
	TestOutputLogger.log("")

	# 验证数据内容
	var header := processor.get_header()
	if header.size() != 5:
		failed_count += 1
		print_result(test_name, false, "表头列数不正确，预期5列，实际%d列" % header.size())
		return

	var expected_header := PackedStringArray(["id", "name", "level", "is_active", "score"])
	var header_match := true
	for i in range(min(header.size(), expected_header.size())):
		if header[i] != expected_header[i]:
			header_match = false
			break

	if not header_match:
		failed_count += 1
		print_result(test_name, false, "表头内容不匹配")
		return

	# 验证数据行
	if processor.get_row_count() != 3:
		failed_count += 1
		print_result(test_name, false, "数据行数不正确，预期3行，实际%d行" % processor.get_row_count())
		return

	TestOutputLogger.log("数据内容验证:")
	var rows := processor.get_all_rows()
	for i in range(rows.size()):
		TestOutputLogger.log("  行%d: %s" % [i, str(rows[i])])

	passed_count += 1
	print_result(test_name, true, "成功读取并验证GDSV文件")


## 测试 2: 验证字段类型转换（int, float, bool, string）
func run_test_type_conversion() -> void:
	TestOutputLogger.log("\n[测试 2] 验证字段类型转换")
	TestOutputLogger.log(repeat_str("-", 70))

	# 重新加载测试数据
	processor.load_gdsv_file(DATA_DIR + "basic_read.gdsv")

	test_count += 1
	var test_name := "类型转换 - int字段"

	TestOutputLogger.log("测试场景: 验证int类型字段的读取和转换")

	var id_value := processor.get_cell_value(0, 0)  # 第一行第一列: id
	TestOutputLogger.log("  获取值: '%s'" % id_value)

	if id_value != "1":
		failed_count += 1
		print_result(test_name, false, "int字段值不正确，预期'1'，实际'%s'" % id_value)
	else:
		passed_count += 1
		print_result(test_name, true, "int字段值正确: %s" % id_value)

	TestOutputLogger.log("")

	# 测试 float 类型
	test_count += 1
	test_name = "类型转换 - float字段"

	TestOutputLogger.log("测试场景: 验证float类型字段的读取和转换")

	var score_value := processor.get_cell_value(0, 4)  # 第一行第五列: score
	TestOutputLogger.log("  获取值: '%s'" % score_value)

	if score_value != "95.5":
		failed_count += 1
		print_result(test_name, false, "float字段值不正确，预期'95.5'，实际'%s'" % score_value)
	else:
		passed_count += 1
		print_result(test_name, true, "float字段值正确: %s" % score_value)

	TestOutputLogger.log("")

	# 测试 bool 类型
	test_count += 1
	test_name = "类型转换 - bool字段"

	TestOutputLogger.log("测试场景: 验证bool类型字段的读取和转换")

	var bool_value_1 := processor.get_cell_value(0, 3)  # 第一行第四列: is_active
	var bool_value_2 := processor.get_cell_value(1, 3)  # 第二行第四列: is_active
	TestOutputLogger.log("  获取值1: '%s'" % bool_value_1)
	TestOutputLogger.log("  获取值2: '%s'" % bool_value_2)

	if bool_value_1 == "true" and bool_value_2 == "false":
		passed_count += 1
		print_result(test_name, true, "bool字段值正确: true, false")
	else:
		failed_count += 1
		print_result(test_name, false, "bool字段值不正确，预期'true'和'false'")

	TestOutputLogger.log("")

	# 测试 string 类型
	test_count += 1
	test_name = "类型转换 - string字段"

	TestOutputLogger.log("测试场景: 验证string类型字段的读取")

	var name_value := processor.get_cell_value(1, 1)  # 第二行第二列: name
	TestOutputLogger.log("  获取值: '%s'" % name_value)

	if name_value == "Player Two":
		passed_count += 1
		print_result(test_name, true, "string字段值正确: %s" % name_value)
	else:
		failed_count += 1
		print_result(test_name, false, "string字段值不正确，预期'Player Two'，实际'%s'" % name_value)


## 测试 3: 写入GDSV文件并读取验证
func run_test_write_and_read_gdsv() -> void:
	TestOutputLogger.log("\n[测试 3] 写入GDSV文件并读取验证")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "写入GDSV文件"

	TestOutputLogger.log("测试场景: 创建新数据，写入文件后重新读取验证")

	# 清空原有数据
	processor.clear_data()

	# 创建测试数据
	var test_content := "id:int\tname\tscore:float\tactive:bool\n1\tTest\t100.5\ttrue\n2\tDemo\t50.25\tfalse"

	TestOutputLogger.log("  测试内容:\n%s" % test_content.replace("\t", "\\t").replace("\n", "\\n\n"))

	# 加载测试内容
	if not processor.load_gdsv_content(test_content):
		failed_count += 1
		print_result(test_name, false, "加载测试内容失败: " + processor.last_error)
		return

	TestOutputLogger.log("  内容加载成功")

	# 保存到临时文件
	var temp_file := TEMP_DIR + "test_write.gdsv"
	if not processor.save_gdsv_file(temp_file):
		failed_count += 1
		print_result(test_name, false, "保存文件失败: " + processor.last_error)
		return

	TestOutputLogger.log("  文件保存成功: %s" % temp_file)

	# 读取保存的文件
	processor.clear_data()
	if not processor.load_gdsv_file(temp_file):
		failed_count += 1
		print_result(test_name, false, "重新读取文件失败: " + processor.last_error)
		return

	TestOutputLogger.log("  文件重新读取成功")

	# 验证数据一致
	if processor.get_row_count() != 2 or processor.get_column_count() != 4:
		failed_count += 1
		print_result(test_name, false, "读取的数据维度不正确")
		return

	var row0 := processor.get_row(0)
	if row0[0] != "1" or row0[1] != "Test" or row0[2] != "100.5" or row0[3] != "true":
		failed_count += 1
		print_result(test_name, false, "第一行数据不匹配: %s" % str(row0))
		return

	var row1 := processor.get_row(1)
	if row1[0] != "2" or row1[1] != "Demo" or row1[2] != "50.25" or row1[3] != "false":
		failed_count += 1
		print_result(test_name, false, "第二行数据不匹配: %s" % str(row1))
		return

	passed_count += 1
	print_result(test_name, true, "写入和读取验证成功")


## 测试 4: 测试空文件处理
func run_test_empty_file() -> void:
	TestOutputLogger.log("\n[测试 4] 空文件处理")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "处理空文件"

	TestOutputLogger.log("测试场景: 尝试加载空文件应返回失败")

	var empty_file := DATA_DIR + "empty.gdsv"

	if not FileAccess.file_exists(empty_file):
		# 创建空文件
		var file := FileAccess.open(empty_file, FileAccess.WRITE)
		if file:
			file.close()
			TestOutputLogger.log("  已创建空测试文件: %s" % empty_file)
		else:
			failed_count += 1
			print_result(test_name, false, "无法创建空测试文件")
			return

	# 清空处理器
	processor.clear_data()

	# 读取空文件
	var success := processor.load_gdsv_file(empty_file)

	if success:
		failed_count += 1
		print_result(test_name, false, "空文件应该加载失败，但成功了")
	else:
		passed_count += 1
		print_result(test_name, true, "空文件正确返回失败: " + processor.last_error)

	TestOutputLogger.log("")

	# 测试只有表头的文件
	test_count += 1
	test_name = "处理只有表头的文件"

	TestOutputLogger.log("测试场景: 加载只有表头的文件（0行数据）")

	var header_only_content := "id\tname\tvalue\n"
	processor.clear_data()

	success = processor.load_gdsv_content(header_only_content)

	if not success:
		failed_count += 1
		print_result(test_name, false, "加载仅含表头的内容失败: " + processor.last_error)
	else:
		if processor.get_row_count() == 0 and processor.get_column_count() == 3:
			passed_count += 1
			print_result(test_name, true, "仅含表头文件加载正确 (0行, 3列)")
		else:
			failed_count += 1
			print_result(test_name, false, "行数/列数不正确: %d行, %d列" % [processor.get_row_count(), processor.get_column_count()])


## 测试 5: 测试特殊字符处理
func run_test_special_characters() -> void:
	TestOutputLogger.log("\n[测试 5] 特殊字符处理")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "处理包含特殊字符的数据"

	TestOutputLogger.log("测试场景: 读写包含引号、换行符、分隔符的数据")

	var special_content := """id:int\tname: String\tdescription: String
1\tItem\t"Contains \t tab"
2\tItem\t"Contains \n newline"
3\tItem\t"Contains "" quotes"
4\tItem\tNormal, simple
"""

	TestOutputLogger.log("  测试内容（包含制表符、换行符、引号）:\n%s" % special_content.replace("\n", "\\n\n").replace("\t", "\\t"))

	processor.clear_data()

	if not processor.load_gdsv_content(special_content):
		failed_count += 1
		print_result(test_name, false, "加载特殊字符内容失败: " + processor.last_error)
		return

	TestOutputLogger.log("  内容加载成功")

	# 验证数据
	if processor.get_row_count() != 4:
		failed_count += 1
		print_result(test_name, false, "行数不正确，预期4行，实际%d行" % processor.get_row_count())
		return

	# 检查特殊字符是否被正确保存
	var desc_values := []
	for i in range(processor.get_row_count()):
		desc_values.append(processor.get_cell_value(i, 2))

	TestOutputLogger.log("  描述列值:")
	for i in range(desc_values.size()):
		TestOutputLogger.log("    行%d: '%s'" % [i, desc_values[i]])

	# 保存并重新读取
	var temp_file := TEMP_DIR + "test_special.gdsv"
	if not processor.save_gdsv_file(temp_file):
		failed_count += 1
		print_result(test_name, false, "保存特殊字符文件失败: " + processor.last_error)
		return

	processor.clear_data()

	if not processor.load_gdsv_file(temp_file):
		failed_count += 1
		print_result(test_name, false, "重新读取特殊字符文件失败: " + processor.last_error)
		return

	# 验证重新读取后的数据
	var new_desc_values := []
	for i in range(processor.get_row_count()):
		new_desc_values.append(processor.get_cell_value(i, 2))

	var all_match := true
	for i in range(desc_values.size()):
		if desc_values[i] != new_desc_values[i]:
			all_match = false
			break

	if all_match:
		passed_count += 1
		print_result(test_name, true, "特殊字符读写验证成功")
	else:
		failed_count += 1
		print_result(test_name, false, "特殊字符读写后不一致")

	TestOutputLogger.log("")

	# 测试包含逗号的字段 (CSV特殊字符)
	test_count += 1
	test_name = "处理包含逗号的字段"

	TestOutputLogger.log("测试场景: 使用逗号分隔符处理包含逗号的字段")

	processor.default_delimiter = ","

	var csv_content = """id:int,name:String,value:String
1,Item A,"Value with, comma"
2,Item B,Normal value"""

	TestOutputLogger.log("  CSV格式内容:\n%s" % csv_content.replace("\n", "\\n\n"))

	processor.clear_data()

	if not processor.load_gdsv_content(csv_content):
		failed_count += 1
		print_result(test_name, false, "加载CSV格式内容失败: " + processor.last_error)
		return

	TestOutputLogger.log("  CSV内容加载成功")

	var value1 := processor.get_cell_value(0, 2)
	TestOutputLogger.log("  第一行value字段: '%s'" % value1)

	if value1 == "Value with, comma":
		passed_count += 1
		print_result(test_name, true, "逗号分隔字段正确读取")
	else:
		failed_count += 1
		print_result(test_name, false, "逗号分隔字段读取错误: '%s'" % value1)


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

	# 根据结果打印不同信息
	if failed_count > 0:
		TestOutputLogger.log("测试失败！请检查上述错误信息。")
	else:
		TestOutputLogger.log("所有测试通过！")
	TestOutputLogger.log("\n测试窗口将保持打开，按 ESC 键可退出")


## 清理临时文件
func cleanup_temp_files() -> void:
	var dir := DirAccess.open(TEMP_DIR)
	if dir:
		var files_to_delete := ["test_write.gdsv", "test_special.gdsv"]
		for file_name in files_to_delete:
			var file_path: String = TEMP_DIR + file_name
			if dir.file_exists(file_name):
				dir.remove(file_path)
				TestOutputLogger.log("已清理临时文件: %s" % file_path)


## 输入处理 - 允许用户按 ESC 退出
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC 默认映射为 ui_cancel
		TestOutputLogger.log("\n用户按 ESC 退出窗口")
		var exit_code := 1 if failed_count > 0 else 0
		get_tree().quit(exit_code)
