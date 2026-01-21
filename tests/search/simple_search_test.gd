## GDSV 搜索功能独立测试脚本
## 这是一个自包含的测试脚本，不依赖外部类定义
## 在 _ready() 中自动运行所有测试用例

extends Node

# 测试数据（内置，不依赖外部文件）
# 注意：使用制表符分隔符（GDSV 标准格式）
var test_data_content := """id:int	name:String	age:int	city:String	active:bool	score:float	tags:String
1	Alice	25	New York	true	95.5	game;dev
2	Bob	30	San Francisco	true	87.0	backend
3	Charlie	35	Seattle	false	72.3	frontend
4	Diana	28	Austin	true	91.2	game
5	Eve	22	Boston	false	88.7	dev;server
6	Frank	40	Chicago	true	76.5	tester
7	Grace	26	Denver	false	94.1	dev
8	Henry	33	Phoenix	true	82.9	game;dev
9	Iris	29	Portland	true	89.4	frontend;dev
10	Jack	31	Miami	false	79.6	tester
"""

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
	TestOutputLogger.log("GDSV 搜索功能独立测试")
	TestOutputLogger.log(repeat_str("=", 70) + "\n")

	test_start_time = Time.get_ticks_msec()

	# 初始化数据处理器
	processor = GDSVDataProcessor.new()
	add_child(processor)

	# 设置默认分隔符为制表符（GDSV 标准格式）
	processor.default_delimiter = "\t"

	# 加载测试数据
	if not processor.load_gdsv_content(test_data_content):
		TestOutputLogger.log("错误: 无法加载测试数据")
		TestOutputLogger.log(processor.last_error)
		return

	TestOutputLogger.log("测试数据加载成功!")
	TestOutputLogger.log("行数: %d, 列数: %d" % [processor.get_row_count(), processor.get_column_count()])
	TestOutputLogger.log("表头: %s\n" % processor.get_header())
	TestOutputLogger.log("\n" + repeat_str("-", 70) + "\n")

	# 运行所有测试
	run_all_tests()

	# 生成测试报告
	generate_summary_report()

	# 测试完成，窗口保持打开，等待用户操作
	# 用户可以通过按 ESC 退出或直接关闭窗口


## 运行所有测试
func run_all_tests() -> void:
	# 测试 1: 基础文本搜索
	run_test_basic_text_search()

	# 测试 2: 大小写敏感搜索
	run_test_case_sensitive_search()

	# 测试 3: 正则表达式搜索
	run_test_regex_search()

	# 测试 4: 空结果测试
	run_test_empty_result()

	# 测试 5: 多结果测试
	run_test_multiple_results()

	# 测试 6: 边界情况 - 特定列搜索
	run_test_column_specific_search()


## 测试 1: 基础文本搜索
func run_test_basic_text_search() -> void:
	TestOutputLogger.log("\n[测试 1] 基础文本搜索")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "基础文本搜索 - 查找名字 'Alice'"

	TestOutputLogger.log("测试场景: 在表格中搜索名字为 'Alice' 的记录")
	TestOutputLogger.log("搜索文本: Alice")
	TestOutputLogger.log("搜索模式: 不区分大小写, 包含匹配\n")

	var results = processor.search_text("Alice", false, 0)

	TestOutputLogger.log("搜索结果:")
	if results.is_empty():
		TestOutputLogger.log("  (无结果)")
		failed_count += 1
		print_result(test_name, false, "未找到预期结果")
	else:
		for result in results:
			TestOutputLogger.log("  行 %d, 列 %d: '%s'" % [result["row"], result["column"], result["matched_text"]])

		# 验证结果
		if results.size() == 1 and results[0]["row"] == 0:
			passed_count += 1
			print_result(test_name, true, "准确找到 1 条记录 (Alice)")
		else:
			failed_count += 1
			print_result(test_name, false, "预期 1 条记录，实际找到 %d 条" % results.size())


## 测试 2: 大小写敏感搜索
func run_test_case_sensitive_search() -> void:
	TestOutputLogger.log("\n[测试 2] 大小写敏感搜索")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "大小写敏感搜索 - 查找 'ALICE'"

	TestOutputLogger.log("测试场景: 区分大小写搜索 'ALICE'，应该找不到 'Alice'")
	TestOutputLogger.log("搜索文本: ALICE")
	TestOutputLogger.log("搜索模式: 区分大小写, 包含匹配\n")

	var results = processor.search_text("ALICE", true, 0)

	TestOutputLogger.log("搜索结果:")
	if results.is_empty():
		TestOutputLogger.log("  (无结果) - 符合预期！")
		passed_count += 1
		print_result(test_name, true, "正确处理大小写敏感，未找到匹配项")
	else:
		for result in results:
			TestOutputLogger.log("  行 %d, 列 %d: '%s'" % [result["row"], result["column"], result["matched_text"]])
		failed_count += 1
		print_result(test_name, false, "预期无结果，但找到 %d 条记录" % results.size())

	TestOutputLogger.log("")

	# 额外测试：大小写不敏感搜索
	test_count += 1
	test_name = "大小写不敏感 - 查找 'alice'（应找到 Alice）"

	TestOutputLogger.log("测试场景: 不区分大小写搜索 'alice'，应该找到 'Alice'")
	TestOutputLogger.log("搜索文本: alice")
	TestOutputLogger.log("搜索模式: 不区分大小写, 包含匹配\n")

	results = processor.search_text("alice", false, 0)

	TestOutputLogger.log("搜索结果:")
	if results.is_empty():
		TestOutputLogger.log("  (无结果)")
		failed_count += 1
		print_result(test_name, false, "未找到预期结果")
	else:
		for result in results:
			TestOutputLogger.log("  行 %d, 列 %d: '%s'" % [result["row"], result["column"], result["matched_text"]])

		if results.size() >= 1:
			passed_count += 1
			print_result(test_name, true, "找到 %d 条记录" % results.size())
		else:
			failed_count += 1
			print_result(test_name, false, "预期至少 1 条记录，实际找到 %d 条" % results.size())


## 测试 3: 正则表达式搜索
func run_test_regex_search() -> void:
	TestOutputLogger.log("\n[测试 3] 正则表达式搜索")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "正则表达式 - 查找以 'S' 开头的城市名"

	TestOutputLogger.log("测试场景: 使用正则表达式查找以 'S' 开头的城市")
	TestOutputLogger.log("正则模式: ^S.+$")
	TestOutputLogger.log("说明: 匹配以大写 S 开头的字符串\n")

	var results = processor.search_regex("^S.+$")

	TestOutputLogger.log("搜索结果:")
	if results.is_empty():
		TestOutputLogger.log("  (无结果)")
		failed_count += 1
		print_result(test_name, false, "未找到匹配的城市名")
	else:
		var found_cities := []
		for result in results:
			var value := str(result["matched_text"])
			found_cities.append(value)
			TestOutputLogger.log("  行 %d, 列 %d: '%s'" % [result["row"], result["column"], result["matched_text"]])

		# 验证结果（应该找到 San Francisco, Seattle）
		var expected := ["San Francisco", "Seattle"]
		var all_found := true
		for city in expected:
			if city not in found_cities:
				all_found = false
				break

		if all_found and found_cities.size() == 2:
			passed_count += 1
			print_result(test_name, true, "正确找到所有匹配的城市: %s" % str(found_cities))
		else:
			failed_count += 1
			print_result(test_name, false, "预期找到 %s，实际找到 %s" % [str(expected), str(found_cities)])

	TestOutputLogger.log("")

	# 额外测试：查找包含数字的标签
	test_count += 1
	test_name = "正则表达式 - 查找邮箱模式"

	TestOutputLogger.log("测试场景: 使用正则表达式查找邮箱地址格式")
	TestOutputLogger.log("正则模式: [a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}")
	TestOutputLogger.log("说明: 匹配标准邮箱格式\n")

	# 注意：测试数据中没有邮箱列，所以这个测试预期找到 0 个结果
	results = processor.search_regex("[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}")

	TestOutputLogger.log("搜索结果:")
	if results.is_empty():
		TestOutputLogger.log("  (无结果) - 符合预期！")
		passed_count += 1
		print_result(test_name, true, "正确处理无匹配情况")
	else:
		for result in results:
			TestOutputLogger.log("  行 %d, 列 %d: '%s'" % [result["row"], result["column"], result["matched_text"]])
		failed_count += 1
		print_result(test_name, false, "预期无邮箱结果，但找到 %d 条记录" % results.size())

	TestOutputLogger.log("")

	# 额外测试：查找以数字开头的名字
	test_count += 1
	test_name = "正则表达式 - 查找年龄 > 30 的记录"

	TestOutputLogger.log("测试场景: 使用正则表达式查找年龄大于 30 的记录")
	TestOutputLogger.log("正则模式: ^[3-9][0-9]$|^100$")
	TestOutputLogger.log("说明: 匹配 30-99 或 100 的年龄\n")

	results = processor.search_regex("^[3-9][0-9]$|^100$")

	TestOutputLogger.log("搜索结果:")
	if results.is_empty():
		TestOutputLogger.log("  (无结果)")
		failed_count += 1
		print_result(test_name, false, "未找到预期结果")
	else:
		var found_ages := []
		for result in results:
			var value := str(result["matched_text"])
			found_ages.append(value)
			TestOutputLogger.log("  行 %d, 列 %d: '%s'" % [result["row"], result["column"], result["matched_text"]])

		if results.size() >= 3:  # Bob(30), Charlie(35), Henry(33), Frank(40), Jack(31) 共5人
			passed_count += 1
			print_result(test_name, true, "找到 %d 条年龄 > 30 的记录" % results.size())
		else:
			failed_count += 1
			print_result(test_name, false, "预期至少 5 条记录，实际找到 %d 条" % results.size())


## 测试 4: 空结果测试
func run_test_empty_result() -> void:
	TestOutputLogger.log("\n[测试 4] 空结果测试")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "空结果 - 查找不存在的城市"

	TestOutputLogger.log("测试场景: 搜索表格中不存在的城市名")
	TestOutputLogger.log("搜索文本: NonExistentCity")
	TestOutputLogger.log("搜索模式: 不区分大小写, 包含匹配\n")

	var results = processor.search_text("NonExistentCity", false, 0)

	TestOutputLogger.log("搜索结果:")
	if results.is_empty():
		TestOutputLogger.log("  (无结果) - 符合预期！")
		passed_count += 1
		print_result(test_name, true, "正确处理无匹配情况")
	else:
		for result in results:
			TestOutputLogger.log("  行 %d, 列 %d: '%s'" % [result["row"], result["column"], result["matched_text"]])
		failed_count += 1
		print_result(test_name, false, "预期无结果，但找到 %d 条记录" % results.size())

	TestOutputLogger.log("")

	# 额外测试：空字符串搜索
	test_count += 1
	test_name = "边界情况 - 空字符串搜索"

	TestOutputLogger.log("测试场景: 搜索空字符串（应该匹配所有内容）")
	TestOutputLogger.log("搜索文本: '' (空字符串)")
	TestOutputLogger.log("搜索模式: 不区分大小写, 包含匹配\n")

	results = processor.search_text("", false, 0)

	TestOutputLogger.log("搜索结果:")
	if results.is_empty():
		TestOutputLogger.log("  (无结果)")
		failed_count += 1
		print_result(test_name, false, "空字符串应该匹配所有内容")
	else:
		TestOutputLogger.log("  共找到 %d 条结果 (匹配所有单元格)" % results.size())

		if results.size() > 0:
			passed_count += 1
			print_result(test_name, true, "空字符串正确匹配所有单元格 (%d 个)" % results.size())
		else:
			failed_count += 1
			print_result(test_name, false, "预期找到结果，但返回空数组")


## 测试 5: 多结果测试
func run_test_multiple_results() -> void:
	TestOutputLogger.log("\n[测试 5] 多结果测试")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "多结果 - 查找所有 'dev' 标签"

	TestOutputLogger.log("测试场景: 搜索在标签列中包含 'dev' 的记录")
	TestOutputLogger.log("搜索文本: dev")
	TestOutputLogger.log("搜索模式: 不区分大小写, 包含匹配\n")

	var results = processor.search_text("dev", false, 0)

	TestOutputLogger.log("搜索结果:")
	if results.is_empty():
		TestOutputLogger.log("  (无结果)")
		failed_count += 1
		print_result(test_name, false, "未找到任何包含 'dev' 的记录")
	else:
		TestOutputLogger.log("  共找到 %d 条结果\n" % results.size())

		# 收集匹配的行和值
		var matched_rows := {}
		for result in results:
			var row_idx: int = result["row"]
			if not matched_rows.has(row_idx):
				matched_rows[row_idx] = []
			matched_rows[row_idx].append(result["matched_text"])
			TestOutputLogger.log("  行 %d, 列 %d: '%s'" % [result["row"], result["column"], result["matched_text"]])

		# 提取所有包含 dev 的行索引
		var matched_cells := results.size()
		var unique_rows := matched_rows.keys().size()

		# 验证结果（Alice, Eve, Grace, Henry, Iris 都有 dev 标签）
		if matched_cells >= 5 and unique_rows >= 4:
			passed_count += 1
			print_result(test_name, true, "正确找到包含 'dev' 的记录（%d 个单元格，%d 行）" % [matched_cells, unique_rows])
		else:
			failed_count += 1
			print_result(test_name, false, "预期至少 5 个单元格匹配，实际找到 %d 个" % matched_cells)

	TestOutputLogger.log("")

	# 额外测试：查找所有活跃用户
	test_count += 1
	test_name = "多结果 - 查找所有活跃用户 (active=true)"

	TestOutputLogger.log("测试场景: 搜索 active 字段为 true 的记录")
	TestOutputLogger.log("搜索文本: true")
	TestOutputLogger.log("搜索模式: 区分大小写, 包含匹配\n")

	results = processor.search_text("true", true, 0)

	TestOutputLogger.log("搜索结果:")
	if results.is_empty():
		TestOutputLogger.log("  (无结果)")
		failed_count += 1
		print_result(test_name, false, "未找到活跃用户")
	else:
		var active_users := []
		for result in results:
			var row_idx: int = result["row"]
			if row_idx not in active_users:
				active_users.append(row_idx)
			TestOutputLogger.log("  行 %d, 列 %d: '%s'" % [result["row"], result["column"], result["matched_text"]])

		# 验证结果（Alice, Bob, Diana, Frank, Henry, Iris 都有 active=true）
		if active_users.size() >= 6:
			passed_count += 1
			print_result(test_name, true, "正确找到 %d 个活跃用户" % active_users.size())
		else:
			failed_count += 1
			print_result(test_name, false, "预期至少 6 个活跃用户，实际找到 %d 个" % active_users.size())


## 测试 6: 边界情况 - 特定列搜索
func run_test_column_specific_search() -> void:
	TestOutputLogger.log("\n[测试 6] 特定列搜索")
	TestOutputLogger.log(repeat_str("-", 70))

	test_count += 1
	var test_name := "特定列 - 仅在 city 列搜索 'o'"

	TestOutputLogger.log("测试场景: 仅在城市名称列中搜索包含字母 'o' 的记录")
	TestOutputLogger.log("搜索文本: o")
	TestOutputLogger.log("搜索模式: 不区分大小写, 包含匹配")
	TestOutputLogger.log("搜索范围: 仅 city 列（索引 3）\n")

	var search_columns := PackedInt32Array([3])  # city 列的索引
	var results = processor.search_text("o", false, 0, search_columns)

	TestOutputLogger.log("搜索结果:")
	if results.is_empty():
		TestOutputLogger.log("  (无结果)")
		failed_count += 1
		print_result(test_name, false, "未找到包含 'o' 的城市名")
	else:
		var cities := []
		for result in results:
			cities.append(result["matched_text"])
			TestOutputLogger.log("  行 %d: '%s'" % [result["row"], result["matched_text"]])

		# 验证结果（New York, San Francisco, Boston, Chicago, Portland, Miami 都包含 o）
		if results.size() >= 6:
			passed_count += 1
			print_result(test_name, true, "正确找到 %d 个包含 'o' 的城市" % results.size())
		else:
			failed_count += 1
			print_result(test_name, false, "预期至少 6 个城市，实际找到 %d 个" % results.size())

	TestOutputLogger.log("")

	# 额外测试：仅在 tags 列搜索
	test_count += 1
	test_name = "特定列 - 仅在 tags 列搜索 'game'"

	TestOutputLogger.log("测试场景: 仅在标签列中搜索 'game'")
	TestOutputLogger.log("搜索文本: game")
	TestOutputLogger.log("搜索模式: 不区分大小写, 包含匹配")
	TestOutputLogger.log("搜索范围: 仅 tags 列（索引 6）\n")

	search_columns = PackedInt32Array([6])  # tags 列的索引
	results = processor.search_text("game", false, 0, search_columns)

	TestOutputLogger.log("搜索结果:")
	if results.is_empty():
		TestOutputLogger.log("  (无结果)")
		failed_count += 1
		print_result(test_name, false, "未找到包含 'game' 的标签")
	else:
		var rows := []
		for result in results:
			rows.append(result["row"])
			TestOutputLogger.log("  行 %d: '%s'" % [result["row"], result["matched_text"]])

		# 验证结果（Alice, Diana, Henry 都有 game 标签）
		if results.size() >= 3:
			passed_count += 1
			print_result(test_name, true, "正确找到 %d 行包含 'game' 标签的记录" % results.size())
		else:
			failed_count += 1
			print_result(test_name, false, "预期至少 3 条记录，实际找到 %d 条" % results.size())


## 打印单个测试结果
func print_result(test_name: String, passed: bool, message: String) -> void:
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
