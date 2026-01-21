extends Node

## 搜索性能测试脚本
## 测试 GDSVDataProcessor 和 CSVSearchEngine 在大文件中的搜索性能

#region 常量 Constants

## 测试文件路径
const DATA_DIR = "res://tests/search_performance/data"
const FILE_10K = "%s/search_10k.gdsv" % DATA_DIR
const FILE_50K = "%s/search_50k.gdsv" % DATA_DIR

#endregion

#region 生命周期方法 Lifecycle Methods

func _ready() -> void:
	TestOutputLogger.log("=".repeat(80))
	TestOutputLogger.log("开始搜索性能测试")
	TestOutputLogger.log("=".repeat(80))
	TestOutputLogger.log("\n")

	# 运行所有测试
	_run_all_tests()

	TestOutputLogger.log("\n")
	TestOutputLogger.log("=".repeat(80))
	TestOutputLogger.log("所有测试完成")
	TestOutputLogger.log("=".repeat(80))

#endregion

#region 测试运行 Test Runner

## 运行所有测试
func _run_all_tests() -> void:
	# 测试1: 在10,000行数据中搜索单个字段
	test1_search_10k_single_field()

	# 测试2: 在50,000行数据中搜索单个字段
	test2_search_50k_single_field()

	# 测试3: 多列搜索性能对比
	test4_multi_column_search()

	# 测试4: 大小写敏感vs不敏感搜索性能对比
	test5_case_sensitivity_comparison()

#endregion

#region 测试方法 Test Methods

## 测试1: 在10,000行数据中搜索单个字段
func test1_search_10k_single_field() -> void:
	TestOutputLogger.log("\n" + "-".repeat(80))
	TestOutputLogger.log("[测试 1] 在10,000行数据中搜索单个字段")
	TestOutputLogger.log("-".repeat(80))

	if not FileAccess.file_exists(FILE_10K):
		TestOutputLogger.log("未找到测试文件: %s" % FILE_10K)
		TestOutputLogger.log("请先运行以下命令生成测试数据:")
		TestOutputLogger.log("  python tools/generate_test_data.py --preset search --rows 10000 --output %s" % FILE_10K)
		TestOutputLogger.log("  [失败] 测试文件不存在")
		return

	# 加载数据
	var processor := GDSVDataProcessor.new()
	var load_start := Time.get_ticks_usec()
	var success := processor.load_gdsv_file(FILE_10K)
	var load_time_ms := (Time.get_ticks_usec() - load_start) / 1000.0

	if not success:
		TestOutputLogger.log("加载失败: %s" % processor.last_error)
		TestOutputLogger.log("  [失败] 文件加载失败")
		return

	TestOutputLogger.log("文件加载成功: %d 行, 加载时间: %.2f ms" % [processor.get_row_count(), load_time_ms])

	# 执行搜索（最优路径：TableData 内部过滤，不导出所有行）
	var search_patterns: Array[Dictionary] = [
		{"term": "Alice", "desc": "精确匹配 'Alice'"},
		{"term": "test", "desc": "部分匹配 'test'"},
		{"term": "game", "desc": "标签搜索 'game'"},
		{"term": "@example.com", "desc": "邮箱域名搜索"},
	]

	TestOutputLogger.log("\n搜索性能测试 (10k行 / 最优API):")
	for pattern in search_patterns:
		var search_term: String = pattern["term"]
		var description: String = pattern["desc"]
		var search_start := Time.get_ticks_usec()
		var results: PackedInt32Array = processor.filter_rows_in_table(search_term)
		var search_time_ms := (Time.get_ticks_usec() - search_start) / 1000.0

		TestOutputLogger.log("  %s: 找到 %d 条结果, 耗时 %.4f ms (%.0f 行/秒)" % [
			description,
			results.size(),
			search_time_ms,
			processor.get_row_count() / (search_time_ms / 1000.0) if search_time_ms > 0 else 0
		])

	TestOutputLogger.log("  [通过] 10K行搜索性能测试完成")

## 测试2: 在50,000行数据中搜索单个字段
func test2_search_50k_single_field() -> void:
	TestOutputLogger.log("\n" + "-".repeat(80))
	TestOutputLogger.log("[测试 2] 在50,000行数据中搜索单个字段")
	TestOutputLogger.log("-".repeat(80))

	if not FileAccess.file_exists(FILE_50K):
		TestOutputLogger.log("未找到测试文件: %s" % FILE_50K)
		TestOutputLogger.log("请先运行以下命令生成测试数据:")
		TestOutputLogger.log("  python tools/generate_test_data.py --preset search --rows 50000 --output %s" % FILE_50K)
		TestOutputLogger.log("  [失败] 测试文件不存在")
		return

	# 加载数据
	var processor := GDSVDataProcessor.new()
	var load_start := Time.get_ticks_usec()
	var success := processor.load_gdsv_file(FILE_50K)
	var load_time_ms := (Time.get_ticks_usec() - load_start) / 1000.0

	if not success:
		TestOutputLogger.log("加载失败: %s" % processor.last_error)
		TestOutputLogger.log("  [失败] 文件加载失败")
		return

	TestOutputLogger.log("文件加载成功: %d 行, 加载时间: %.2f ms" % [processor.get_row_count(), load_time_ms])

	# 执行搜索（最优路径：TableData 内部过滤，不导出所有行）
	var search_patterns: Array[Dictionary] = [
		{"term": "User_1000", "desc": "精确用户名搜索"},
		{"term": "test", "desc": "部分匹配 'test'"},
		{"term": "admin", "desc": "管理员搜索"},
	]

	TestOutputLogger.log("\n搜索性能测试 (50k行 / 最优API):")
	for pattern in search_patterns:
		var search_term: String = pattern["term"]
		var description: String = pattern["desc"]
		var search_start := Time.get_ticks_usec()
		var results: PackedInt32Array = processor.filter_rows_in_table(search_term)
		var search_time_ms := (Time.get_ticks_usec() - search_start) / 1000.0

		TestOutputLogger.log("  %s: 找到 %d 条结果, 耗时 %.4f ms (%.0f 行/秒)" % [
			description,
			results.size(),
			search_time_ms,
			processor.get_row_count() / (search_time_ms / 1000.0) if search_time_ms > 0 else 0
		])

	TestOutputLogger.log("  [通过] 50K行搜索性能测试完成")

## 测试3: 使用正则表达式搜索
func test3_regex_search() -> void:
	TestOutputLogger.log("\n" + "-".repeat(80))
	TestOutputLogger.log("[测试 3] 使用正则表达式搜索")
	TestOutputLogger.log("-".repeat(80))
	TestOutputLogger.log("\n正则表达式搜索测试: (跳过)")
	TestOutputLogger.log("  [跳过] regex不属于最优API路径（需要导出全表），本套测试只跑最优API")

## 测试4: 多列搜索性能对比
func test4_multi_column_search() -> void:
	TestOutputLogger.log("\n" + "-".repeat(80))
	TestOutputLogger.log("[测试 4] 多列搜索性能对比")
	TestOutputLogger.log("-".repeat(80))

	if not FileAccess.file_exists(FILE_10K):
		TestOutputLogger.log("未找到测试文件: %s" % FILE_10K)
		TestOutputLogger.log("  [失败] 测试文件不存在")
		return

	var processor := GDSVDataProcessor.new()
	processor.load_gdsv_file(FILE_10K)

	TestOutputLogger.log("文件加载成功: %d 行" % processor.get_row_count())

	var search_term := "test"

	# 单列搜索（只搜索name列，假设是第0列）
	var single_start := Time.get_ticks_usec()
	var single_results: PackedInt32Array = processor.filter_rows_in_table(search_term, false, GDSVSearchEngine.MATCH_CONTAINS, 0)
	var single_time_ms := (Time.get_ticks_usec() - single_start) / 1000.0

	# 多列搜索（当前最优API为单列或全列：用 -1 表示全列）
	var multi_start := Time.get_ticks_usec()
	var multi_results: PackedInt32Array = processor.filter_rows_in_table(search_term, false, GDSVSearchEngine.MATCH_CONTAINS, -1)
	var multi_time_ms := (Time.get_ticks_usec() - multi_start) / 1000.0

	TestOutputLogger.log("\n搜索词: '%s'" % search_term)
	TestOutputLogger.log("  单列搜索 (name): 找到 %d 条结果, 耗时 %.4f ms" % [single_results.size(), single_time_ms])
	TestOutputLogger.log("  多列搜索 (全部): 找到 %d 条结果, 耗时 %.4f ms" % [multi_results.size(), multi_time_ms])
	TestOutputLogger.log("  性能差异: %.2fx" % (multi_time_ms / single_time_ms if single_time_ms > 0 else 0))
	TestOutputLogger.log("  [通过] 多列搜索性能测试完成")

## 测试5: 大小写敏感vs不敏感搜索性能对比
func test5_case_sensitivity_comparison() -> void:
	TestOutputLogger.log("\n" + "-".repeat(80))
	TestOutputLogger.log("[测试 5] 大小写敏感vs不敏感搜索性能对比")
	TestOutputLogger.log("-".repeat(80))

	if not FileAccess.file_exists(FILE_10K):
		TestOutputLogger.log("未找到测试文件: %s" % FILE_10K)
		TestOutputLogger.log("  [失败] 测试文件不存在")
		return

	var processor := GDSVDataProcessor.new()
	processor.load_gdsv_file(FILE_10K)

	TestOutputLogger.log("文件加载成功: %d 行" % processor.get_row_count())

	var search_term := "Test"

	# 大小写敏感搜索
	var sensitive_start := Time.get_ticks_usec()
	var sensitive_results: PackedInt32Array = processor.filter_rows_in_table(search_term, true)
	var sensitive_time_ms := (Time.get_ticks_usec() - sensitive_start) / 1000.0

	# 大小写不敏感搜索
	var insensitive_start := Time.get_ticks_usec()
	var insensitive_results: PackedInt32Array = processor.filter_rows_in_table(search_term, false)
	var insensitive_time_ms := (Time.get_ticks_usec() - insensitive_start) / 1000.0

	TestOutputLogger.log("\n搜索词: '%s'" % search_term)
	TestOutputLogger.log("  大小写敏感:   找到 %d 条结果, 耗时 %.4f ms" % [sensitive_results.size(), sensitive_time_ms])
	TestOutputLogger.log("  大小写不敏感: 找到 %d 条结果, 耗时 %.4f ms" % [insensitive_results.size(), insensitive_time_ms])
	TestOutputLogger.log("  性能差异: %.2fx" % (insensitive_time_ms / sensitive_time_ms if sensitive_time_ms > 0 else 0))
	TestOutputLogger.log("  [通过] 大小写敏感性能测试完成")

#endregion
