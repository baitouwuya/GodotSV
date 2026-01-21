## GDSV 多格式读写测试脚本
## 测试 CSV、TSV、GDSV 三种格式的读取和互转

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

# 字符串重复辅助函数
func repeat_str(s: String, count: int) -> String:
	var result := ""
	for i in range(count):
		result += s
	return result

func _ready() -> void:
	TestOutputLogger.log("\n" + repeat_str("=", 70))
	TestOutputLogger.log("GDSV 多格式读写测试")
	TestOutputLogger.log(repeat_str("=", 70) + "\n")

	test_start_time = Time.get_ticks_msec()

	# 初始化数据处理器
	processor = GDSVDataProcessor.new()
	add_child(processor)

	TestOutputLogger.log("\n" + repeat_str("-", 70) + "\n")

	# 运行所有测试
	run_all_tests()

	# 生成测试报告
	generate_summary_report()

	# 测试完成，窗口保持打开，等待用户操作
	# 用户可以通过按 ESC 退出或直接关闭窗口


## 运行所有测试
func run_all_tests() -> void:
	# 测试 1: 读取 CSV 文件
	run_test_1_read_csv()

	# 测试 2: 读取 TSV 文件
	run_test_2_read_tsv()

	# 测试 3: 读取 GDSV 文件
	run_test_3_read_gdsv()

	# 测试 4: CSV 转 GDSV 格式转换
	run_test_4_csv_to_gdsv()

	# 测试 5: TSV 转 GDSV 格式转换
	run_test_5_tsv_to_gdsv()

	# 测试 6: 验证不同格式的数据一致性
	run_test_6_data_consistency()


## 测试 1: 读取 CSV 文件
func run_test_1_read_csv() -> void:
	TestOutputLogger.log("\n[测试 1] 读取 CSV 文件")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "读取 CSV 文件 (test_data/compatibility.csv)"
	var test_path := "res://test_data/compatibility.csv"

	TestOutputLogger.log("测试场景: 从 CSV 文件加载数据")
	TestOutputLogger.log("文件路径: %s\n" % test_path)

	var success := processor.load_gdsv_file(test_path)
	TestOutputLogger.log("加载结果: %s" % ("成功" if success else "失败"))
	if not success:
		TestOutputLogger.log("错误信息: %s" % processor.last_error)
		failed_count += 1
		print_result(test_name, false, "文件加载失败")
		return

	var row_count := processor.get_row_count()
	var column_count := processor.get_column_count()
	var header := processor.get_header()

	TestOutputLogger.log("行数: %d" % row_count)
	TestOutputLogger.log("列数: %d" % column_count)
	TestOutputLogger.log("表头: %s\n" % str(header))

	# 验证数据内容
	if row_count > 0 and column_count > 0:
		TestOutputLogger.log("前 3 行数据:")
		var display_limit: int = min(3, row_count)
		for i in range(display_limit):
			var row := processor.get_row(i)
			TestOutputLogger.log("  行 %d: %s" % [i, str(row)])

	# CSV 数据验证
	var expected_rows := 2  # compatibility.csv 有 2 数据行 + 空行
	var expected_cols := 3  # id:int, name, level:int

	if row_count >= expected_rows and column_count == expected_cols:
		passed_count += 1
		print_result(test_name, true, "CSV 文件读取成功，数据格式正确")
	else:
		failed_count += 1
		print_result(test_name, false, "数据行数或列数不符合预期 (预期: %d行%d列, 实际: %d行%d列)" % [expected_rows, expected_cols, row_count, column_count])


## 测试 2: 读取 TSV 文件
func run_test_2_read_tsv() -> void:
	TestOutputLogger.log("\n[测试 2] 读取 TSV 文件")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "读取 TSV 文件 (test_data/compatibility.tsv)"
	var test_path := "res://test_data/compatibility.tsv"

	TestOutputLogger.log("测试场景: 从 TSV 文件加载数据")
	TestOutputLogger.log("文件路径: %s\n" % test_path)

	# 重置处理器
	processor.reset()

	var success := processor.load_gdsv_file(test_path)
	TestOutputLogger.log("加载结果: %s" % ("成功" if success else "失败"))
	if not success:
		TestOutputLogger.log("错误信息: %s" % processor.last_error)
		failed_count += 1
		print_result(test_name, false, "文件加载失败")
		return

	var row_count := processor.get_row_count()
	var column_count := processor.get_column_count()
	var header := processor.get_header()

	TestOutputLogger.log("行数: %d" % row_count)
	TestOutputLogger.log("列数: %d" % column_count)
	TestOutputLogger.log("表头: %s\n" % str(header))

	# 验证数据内容
	if row_count > 0 and column_count > 0:
		TestOutputLogger.log("前 3 行数据:")
		var display_limit: int = min(3, row_count)
		for i in range(display_limit):
			var row := processor.get_row(i)
			TestOutputLogger.log("  行 %d: %s" % [i, str(row)])

	# TSV 数据验证
	var expected_rows := 2  # compatibility.tsv 有 2 数据行（与CSV保持一致）
	var expected_cols := 3  # id:int, name, level:int

	if row_count >= expected_rows and column_count == expected_cols:
		passed_count += 1
		print_result(test_name, true, "TSV 文件读取成功，数据格式正确")
	else:
		failed_count += 1
		print_result(test_name, false, "数据行数或列数不符合预期 (预期: %d行%d列, 实际: %d行%d列)" % [expected_rows, expected_cols, row_count, column_count])


## 测试 3: 读取 GDSV 文件
func run_test_3_read_gdsv() -> void:
	TestOutputLogger.log("\n[测试 3] 读取 GDSV 文件")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "读取 GDSV 文件 (test_data/basic.gdsv)"
	var test_path := "res://test_data/basic.gdsv"

	TestOutputLogger.log("测试场景: 从 GDSV 文件加载数据")
	TestOutputLogger.log("文件路径: %s\n" % test_path)

	# 重置处理器
	processor.reset()

	var success := processor.load_gdsv_file(test_path)
	TestOutputLogger.log("加载结果: %s" % ("成功" if success else "失败"))
	if not success:
		TestOutputLogger.log("错误信息: %s" % processor.last_error)
		failed_count += 1
		print_result(test_name, false, "文件加载失败")
		return

	var row_count := processor.get_row_count()
	var column_count := processor.get_column_count()
	var header := processor.get_header()

	TestOutputLogger.log("行数: %d" % row_count)
	TestOutputLogger.log("列数: %d" % column_count)
	TestOutputLogger.log("表头: %s\n" % str(header))

	# 验证数据内容
	if row_count > 0 and column_count > 0:
		TestOutputLogger.log("所有数据:")
		for i in range(row_count):
			var row := processor.get_row(i)
			TestOutputLogger.log("  行 %d: %s" % [i, str(row)])

	# GDSV 数据验证
	var expected_rows := 1  # basic.gdsv 有 1 数据行
	var expected_cols := 5  # id:int=, name:string=, hp:int=, is_boss:bool=, ratio:float=

	if row_count >= expected_rows and column_count == expected_cols:
		passed_count += 1
		print_result(test_name, true, "GDSV 文件读取成功，数据格式正确")
	else:
		failed_count += 1
		print_result(test_name, false, "数据行数或列数不符合预期 (预期: %d行%d列, 实际: %d行%d列)" % [expected_rows, expected_cols, row_count, column_count])


## 测试 4: CSV 转 GDSV 格式转换
func run_test_4_csv_to_gdsv() -> void:
	TestOutputLogger.log("\n[测试 4] CSV 转 GDSV 格式转换")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "CSV 转 GDSV 转换"
	var csv_path := "res://test_data/compatibility.csv"
	var gdsv_path := "res://tests/multi_format/data/output_csv_to_gdsv.gdsv"

	TestOutputLogger.log("测试场景: 将 CSV 文件转换为 GDSV 格式保存")
	TestOutputLogger.log("源文件: %s" % csv_path)
	TestOutputLogger.log("目标文件: %s\n" % gdsv_path)

	# 重置处理器
	processor.reset()

	# 加载 CSV
	var load_success := processor.load_gdsv_file(csv_path)
	if not load_success:
		TestOutputLogger.log("错误: 无法加载源文件")
		TestOutputLogger.log(processor.last_error)
		failed_count += 1
		print_result(test_name, false, "无法加载源文件")
		return

	# 获取原始数据
	var original_rows := processor.get_all_rows()
	var original_header := processor.get_header()

	TestOutputLogger.log("原始数据 (%d 行, %d 列):" % [original_rows.size(), original_header.size()])
	for i in range(min(3, original_rows.size())):
		TestOutputLogger.log("  行 %d: %s" % [i, str(original_rows[i])])

	# 保存为 GDSV
	var save_success := processor.save_gdsv_file(gdsv_path)
	TestOutputLogger.log("\n保存结果: %s" % ("成功" if save_success else "失败"))
	if not save_success:
		TestOutputLogger.log("错误信息: %s" % processor.last_error)
		failed_count += 1
		print_result(test_name, false, "保存为 GDSV 失败")
		return

	# 验证保存的文件
	processor.reset()
	var verify_success := processor.load_gdsv_file(gdsv_path)
	if not verify_success:
		failed_count += 1
		print_result(test_name, false, "无法验证保存的文件")
		return

	var loaded_rows := processor.get_all_rows()
	var loaded_header := processor.get_header()

	TestOutputLogger.log("\n验证数据 (%d 行, %d 列):" % [loaded_rows.size(), loaded_header.size()])
	for i in range(min(3, loaded_rows.size())):
		TestOutputLogger.log("  行 %d: %s" % [i, str(loaded_rows[i])])

	# 验证数据一致性
	var data_matches := true
	if original_rows.size() != loaded_rows.size():
		data_matches = false
		TestOutputLogger.log("\n警告: 行数不匹配 (原始: %d, 加载: %d)" % [original_rows.size(), loaded_rows.size()])
	else:
		for i in range(original_rows.size()):
			var original_row: Array = original_rows[i]
			var loaded_row: Array = loaded_rows[i]
			if original_row != loaded_row:
				data_matches = false
				TestOutputLogger.log("\n警告: 行 %d 数据不匹配" % i)
				TestOutputLogger.log("  原始: %s" % str(original_row))
				TestOutputLogger.log("  加载: %s" % str(loaded_row))
				break

	if data_matches and original_header == loaded_header:
		passed_count += 1
		print_result(test_name, true, "CSV 转 GDSV 成功，数据一致")
	else:
		failed_count += 1
		print_result(test_name, false, "数据不一致")


## 测试 5: TSV 转 GDSV 格式转换
func run_test_5_tsv_to_gdsv() -> void:
	TestOutputLogger.log("\n[测试 5] TSV 转 GDSV 格式转换")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "TSV 转 GDSV 转换"
	var tsv_path := "res://test_data/compatibility.tsv"
	var gdsv_path := "res://tests/multi_format/data/output_tsv_to_gdsv.gdsv"

	TestOutputLogger.log("测试场景: 将 TSV 文件转换为 GDSV 格式保存")
	TestOutputLogger.log("源文件: %s" % tsv_path)
	TestOutputLogger.log("目标文件: %s\n" % gdsv_path)

	# 重置处理器
	processor.reset()

	# 加载 TSV
	var load_success := processor.load_gdsv_file(tsv_path)
	if not load_success:
		TestOutputLogger.log("错误: 无法加载源文件")
		TestOutputLogger.log(processor.last_error)
		failed_count += 1
		print_result(test_name, false, "无法加载源文件")
		return

	# 获取原始数据
	var original_rows := processor.get_all_rows()
	var original_header := processor.get_header()

	TestOutputLogger.log("原始数据 (%d 行, %d 列):" % [original_rows.size(), original_header.size()])
	for i in range(min(3, original_rows.size())):
		TestOutputLogger.log("  行 %d: %s" % [i, str(original_rows[i])])

	# 保存为 GDSV
	var save_success := processor.save_gdsv_file(gdsv_path)
	TestOutputLogger.log("\n保存结果: %s" % ("成功" if save_success else "失败"))
	if not save_success:
		TestOutputLogger.log("错误信息: %s" % processor.last_error)
		failed_count += 1
		print_result(test_name, false, "保存为 GDSV 失败")
		return

	# 验证保存的文件
	processor.reset()
	var verify_success := processor.load_gdsv_file(gdsv_path)
	if not verify_success:
		failed_count += 1
		print_result(test_name, false, "无法验证保存的文件")
		return

	var loaded_rows := processor.get_all_rows()
	var loaded_header := processor.get_header()

	TestOutputLogger.log("\n验证数据 (%d 行, %d 列):" % [loaded_rows.size(), loaded_header.size()])
	for i in range(min(3, loaded_rows.size())):
		TestOutputLogger.log("  行 %d: %s" % [i, str(loaded_rows[i])])

	# 验证数据一致性
	var data_matches := true
	if original_rows.size() != loaded_rows.size():
		data_matches = false
		TestOutputLogger.log("\n警告: 行数不匹配 (原始: %d, 加载: %d)" % [original_rows.size(), loaded_rows.size()])
	else:
		for i in range(original_rows.size()):
			var original_row: Array = original_rows[i]
			var loaded_row: Array = loaded_rows[i]
			if original_row != loaded_row:
				data_matches = false
				TestOutputLogger.log("\n警告: 行 %d 数据不匹配" % i)
				TestOutputLogger.log("  原始: %s" % str(original_row))
				TestOutputLogger.log("  加载: %s" % str(loaded_row))
				break

	if data_matches and original_header == loaded_header:
		passed_count += 1
		print_result(test_name, true, "TSV 转 GDSV 成功，数据一致")
	else:
		failed_count += 1
		print_result(test_name, false, "数据不一致")


## 测试 6: 验证不同格式的数据一致性
func run_test_6_data_consistency() -> void:
	TestOutputLogger.log("\n[测试 6] 验证不同格式的数据一致性")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "CSV 和 TSV 数据一致性验证"

	TestOutputLogger.log("测试场景: 验证 CSV 和 TSV 同名文件的数据是否一致")
	TestOutputLogger.log(" CSV 文件: res://test_data/compatibility.csv")
	TestOutputLogger.log(" TSV 文件: res://test_data/compatibility.tsv\n")

	# 加载 CSV
	processor.reset()
	var csv_success := processor.load_gdsv_file("res://test_data/compatibility.csv")
	if not csv_success:
		TestOutputLogger.log("错误: 无法加载 CSV 文件")
		failed_count += 1
		print_result(test_name, false, "无法加载 CSV 文件")
		return

	var csv_rows := processor.get_all_rows()
	var csv_header := processor.get_header()

	TestOutputLogger.log("CSV 数据:")
	TestOutputLogger.log("  行数: %d" % csv_rows.size())
	TestOutputLogger.log("  表头: %s" % str(csv_header))
	for i in range(min(2, csv_rows.size())):
		TestOutputLogger.log("  行 %d: %s" % [i, str(csv_rows[i])])

	# 加载 TSV
	processor.reset()
	var tsv_success := processor.load_gdsv_file("res://test_data/compatibility.tsv")
	if not tsv_success:
		TestOutputLogger.log("错误: 无法加载 TSV 文件")
		failed_count += 1
		print_result(test_name, false, "无法加载 TSV 文件")
		return

	var tsv_rows := processor.get_all_rows()
	var tsv_header := processor.get_header()

	TestOutputLogger.log("\nTSV 数据:")
	TestOutputLogger.log("  行数: %d" % tsv_rows.size())
	TestOutputLogger.log("  表头: %s" % str(tsv_header))
	for i in range(min(2, tsv_rows.size())):
		TestOutputLogger.log("  行 %d: %s" % [i, str(tsv_rows[i])])

	# 验证一致性（只比较非空行的数据）
	TestOutputLogger.log("\n一致性验证:")

	# 提取非空行进行比较
	var csv_data_rows: Array = []
	for row in csv_rows:
		var is_empty := true
		for cell in row:
			if not str(cell).is_empty():
				is_empty = false
				break
		if not is_empty:
			csv_data_rows.append(row)

	var tsv_data_rows: Array = []
	for row in tsv_rows:
		var is_empty := true
		for cell in row:
			if not str(cell).is_empty():
				is_empty = false
				break
		if not is_empty:
			tsv_data_rows.append(row)

	var data_consistency := true
	if csv_data_rows.size() != tsv_data_rows.size():
		data_consistency = false
		TestOutputLogger.log("  ⚠ 非空行数不匹配 (CSV: %d, TSV: %d)" % [csv_data_rows.size(), tsv_data_rows.size()])
	else:
		TestOutputLogger.log("  ✓ 非空行数匹配: %d" % csv_data_rows.size())
		# 比较每一行
		for i in range(csv_data_rows.size()):
			var csv_row: Array = csv_data_rows[i]
			var tsv_row: Array = tsv_data_rows[i]
			if csv_row.size() != tsv_row.size():
				data_consistency = false
				TestOutputLogger.log("  ⚠ 行 %d 列数不匹配 (CSV: %d, TSV: %d)" % [i, csv_row.size(), tsv_row.size()])
				break
			for j in range(csv_row.size()):
				var csv_cell: Variant = csv_row[j]
				var tsv_cell: Variant = tsv_row[j]
				if csv_cell != tsv_cell:
					data_consistency = false
					TestOutputLogger.log("  ⚠ 行 %d 列 %d 不匹配" % [i, j])
					TestOutputLogger.log("    CSV: '%s'" % str(csv_cell))
					TestOutputLogger.log("    TSV: '%s'" % str(tsv_cell))
					break
			if not data_consistency:
				break

	# 验证表头一致性
	var header_consistency := csv_header.size() == tsv_header.size()
	if header_consistency:
		TestOutputLogger.log("  ✓ 表头列数匹配: %d" % csv_header.size())
		for i in range(csv_header.size()):
			var csv_header_item: String = csv_header[i]
			var tsv_header_item: String = tsv_header[i]
			if csv_header_item != tsv_header_item:
				header_consistency = false
				TestOutputLogger.log("  ⚠ 表头列 %d 不匹配 (CSV: '%s', TSV: '%s')" % [i, csv_header_item, tsv_header_item])
				break

	if header_consistency:
		TestOutputLogger.log("  ✓ 表头内容一致")

	if data_consistency and header_consistency:
		passed_count += 1
		print_result(test_name, true, "CSV 和 TSV 数据一致")
	else:
		failed_count += 1
		print_result(test_name, false, "CSV 和 TSV 数据不一致")


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


## 输入处理 - 允许用户按 ESC 退出
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ESC 默认映射为 ui_cancel
		TestOutputLogger.log("\n用户按 ESC 退出窗口")
		var exit_code := 1 if failed_count > 0 else 0
		get_tree().quit(exit_code)
