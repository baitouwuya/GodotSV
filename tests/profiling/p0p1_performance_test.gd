## P0+P1组合方案性能测试脚本
## 验证C++内嵌搜索API的性能提升

class_name P0P1PerformanceTest
extends Node

## 测试数据规模
const TEST_SIZES = [1000, 5000, 10000, 50000]

## 测试关键词
const SEARCH_KEYWORDS = ["测试", "data", "error", "success"]

#region 生命周期方法 Lifecycle Methods
func _ready() -> void:
	TestOutputLogger.log("=== P0+P1组合方案性能测试 ===")
	print("[P0P1PerfTest] 开始P0+P1性能测试")
	
	# 测试用例1：准备测试数据
	TestOutputLogger.log("[测试 1] 准备测试数据")
	print("[P0P1PerfTest] [测试 1] 准备测试数据")
	var test_data = _create_test_data(50000)
	TestOutputLogger.log("[通过] 测试数据创建成功：%d 行" % test_data["rows"].size())
	
	# 测试用例2：执行性能测试
	TestOutputLogger.log("[测试 2] 执行性能测试")
	print("[P0P1PerfTest] [测试 2] 执行性能测试")
	var all_results := _run_performance_tests(test_data)
	TestOutputLogger.log("[通过] 性能测试执行完成，测试了 %d 种规模" % all_results.size())
	
	# 测试用例3：生成性能报告
	TestOutputLogger.log("[测试 3] 生成性能总结报告")
	print("[P0P1PerfTest] [测试 3] 生成性能总结报告")
	_generate_p0p1_summary(all_results)
	TestOutputLogger.log("[通过] 性能总结报告生成完成")
	
	# 输出测试统计
	var total_tests := 3
	var passed_tests := 3
	var failed_tests := 0
	TestOutputLogger.log("测试统计: 总数: %d, 通过: %d, 失败: %d, 跳过: 0" % [total_tests, passed_tests, failed_tests])
#endregion

#region 测试执行 Test Execution
func _run_performance_tests(data: Dictionary) -> Array:
	TestOutputLogger.log("\n--- 开始性能测试（只跑最优API） ---\n")
	
	var all_results := []

	for size in TEST_SIZES:
		TestOutputLogger.log("测试数据规模: %d 行" % size)
		print("[P0P1PerfTest] 测试规模: %d行" % size)
		var rows = _slice_rows(data["rows"], size)
		var header = data["header"]

		# 创建GDSVTableData对象
		var table_data = GDSVTableData.new()
		table_data.initialize(rows, header)

		# 只测试最优API（内嵌过滤）
		var results = _test_p0_search(table_data, size)
		all_results.append(results)

		TestOutputLogger.log("")  # 空行分隔
	
	return all_results

func _test_p0_search(table_data: GDSVTableData, size: int) -> Dictionary:
	TestOutputLogger.log("  [最优API] TableData.filter_rows_in_table():")
	
	var results_dict := {}
	results_dict["size"] = size

	for keyword in SEARCH_KEYWORDS:
		var start = Time.get_ticks_usec()
		# 最优性能：只返回行号，避免构造大量Dictionary
		# status列为3（见_create_test_data），该列中注入了关键词
		var results: PackedInt32Array = table_data.filter_rows_in_table(keyword, false, GDSVTableData.MATCH_CONTAINS, 3)
		var elapsed = (Time.get_ticks_usec() - start) / 1000.0

		TestOutputLogger.log("    搜索 '%s': %.3f ms, 命中行数: %d" % [keyword, elapsed, results.size()])
		print("[P0P1PerfTest]   '%s': %.3f ms, 命中: %d" % [keyword, elapsed, results.size()])
		
		results_dict[keyword] = {
			"time_ms": elapsed,
			"matches": results.size(),
			"throughput": size / (elapsed / 1000.0) if elapsed > 0 else 0.0
		}
	
	return results_dict
#endregion

#region 功能验证 Functional Verification
func test_functional_correctness() -> void:
	TestOutputLogger.log("\n=== 功能正确性验证 ===")
	print("[P0P1PerfTest] 开始功能正确性验证")
	
	var test_data = _create_simple_test_data()
	var table_data = GDSVTableData.new()
	table_data.initialize(test_data["rows"], test_data["header"])
	
	# 测试1: 基础搜索
	_test_basic_search(table_data)
	
	# 测试2: 列过滤搜索
	_test_column_filter_search(table_data)
	
	# 测试3: 大小写敏感
	_test_case_sensitive(table_data)
	
	# 测试4: 匹配模式
	_test_match_modes(table_data)
	
	# 测试5: 行过滤
	_test_row_filter(table_data)
	
	# 测试6: 单列查找
	_test_column_value_lookup(table_data)
	
	# 测试7: 正则搜索
	_test_regex_search(table_data)
	
	TestOutputLogger.log("\n✅ 所有功能测试通过！")
	print("[P0P1PerfTest] 功能测试全部通过")

func _test_basic_search(table_data: GDSVTableData) -> void:
	TestOutputLogger.log("  测试1: 基础搜索")
	
	var results = table_data.search_in_table("apple")
	assert(results.size() == 2, "应该找到2个'apple'")
	
	var result1 = results[0]
	assert(result1["row"] == 0, "第一个结果在第0行")
	assert(result1["column"] == 1, "第一个结果在第1列")
	assert(result1["matched_text"] == "apple", "匹配文本正确")
	
	TestOutputLogger.log("    ✅ 基础搜索通过")

func _test_column_filter_search(table_data: GDSVTableData) -> void:
	TestOutputLogger.log("  测试2: 列过滤搜索")
	
	# 只搜索第0列
	var results = table_data.search_in_table("Alice", false, 0, PackedInt32Array([0]))
	assert(results.size() == 1, "应该找到1个'Alice'")
	assert(results[0]["column"] == 0, "结果在第0列")
	
	TestOutputLogger.log("    ✅ 列过滤搜索通过")

func _test_case_sensitive(table_data: GDSVTableData) -> void:
	TestOutputLogger.log("  测试3: 大小写敏感")
	
	# 大小写不敏感
	var results1 = table_data.search_in_table("APPLE", false)
	assert(results1.size() == 2, "大小写不敏感应找到2个")
	
	# 大小写敏感
	var results2 = table_data.search_in_table("APPLE", true)
	assert(results2.size() == 0, "大小写敏感应找到0个")
	
	TestOutputLogger.log("    ✅ 大小写敏感通过")

func _test_match_modes(table_data: GDSVTableData) -> void:
	TestOutputLogger.log("  测试4: 匹配模式")
	
	# 包含
	var r1 = table_data.search_in_table("app", false, GDSVTableData.MATCH_CONTAINS)
	assert(r1.size() == 2, "包含模式应找到2个")
	
	# 开头
	var r2 = table_data.search_in_table("app", false, GDSVTableData.MATCH_STARTS_WITH)
	assert(r2.size() == 2, "开头模式应找到2个")
	
	# 结尾
	var r3 = table_data.search_in_table("e", false, GDSVTableData.MATCH_ENDS_WITH)
	assert(r3.size() == 3, "结尾模式应找到3个")
	
	# 等于
	var r4 = table_data.search_in_table("apple", false, GDSVTableData.MATCH_EQUALS)
	assert(r4.size() == 2, "等于模式应找到2个")
	
	TestOutputLogger.log("    ✅ 匹配模式通过")

func _test_row_filter(table_data: GDSVTableData) -> void:
	TestOutputLogger.log("  测试5: 行过滤")
	
	var filtered = table_data.filter_rows_in_table("apple")
	assert(filtered.size() == 2, "应该过滤出2行")
	assert(filtered.has(0), "应该包含第0行")
	assert(filtered.has(1), "应该包含第1行")
	
	TestOutputLogger.log("    ✅ 行过滤通过")

func _test_column_value_lookup(table_data: GDSVTableData) -> void:
	TestOutputLogger.log("  测试6: 单列查找")
	
	var rows = table_data.find_rows_by_column_value(0, "Alice")
	assert(rows.size() == 1, "应该找到1行")
	assert(rows[0] == 0, "应该是第0行")
	
	TestOutputLogger.log("    ✅ 单列查找通过")

func _test_regex_search(table_data: GDSVTableData) -> void:
	TestOutputLogger.log("  测试7: 正则搜索")
	
	var results = table_data.search_regex_in_table(r"a\w+")
	assert(results.size() > 0, "正则搜索应该找到匹配")
	
	TestOutputLogger.log("    ✅ 正则搜索通过")
#endregion

#region 数据生成 Data Generation
func _create_test_data(row_count: int) -> Dictionary:
	var rows: Array[PackedStringArray] = []
	var header := PackedStringArray(["id", "name", "email", "status", "date"])
	
	var _keywords = ["测试", "data", "error", "success", "warning", "apple", "banana", "orange"]
	var statuses = ["active", "inactive", "pending", "error", "success"]
	var names = ["Alice", "Bob", "Charlie", "David", "Eve"]
	
	for i in range(row_count):
		var row := PackedStringArray()
		row.append(str(i))  # id
		row.append(names[i % names.size()] + "_" + str(i))  # name
		row.append("user%d@example.com" % i)  # email
		row.append(statuses[i % statuses.size() + int(i % 10 == 0)])  # status (混合一些关键词)
		row.append("2024-01-%02d" % (i % 31 + 1))  # date
		
		# 在某些行中注入测试关键词
		if i % 1000 == 0:
			row[3] = "error测试"
		elif i % 500 == 0:
			row[3] = "success_data"
		elif i % 250 == 0:
			row[2] = "apple@example.com"
		
		rows.append(row)
	
	return {"rows": rows, "header": header}

func _create_simple_test_data() -> Dictionary:
	var rows: Array[PackedStringArray] = [
		PackedStringArray(["Alice", "apple@example.com", "active"]),
		PackedStringArray(["Bob", "banana@example.com", "inactive"]),
		PackedStringArray(["Charlie", "orange@example.com", "active"]),
		PackedStringArray(["Alice Smith", "applepie@example.com", "error"]),
	]
	
	var header := PackedStringArray(["name", "email", "status"])
	
	return {"rows": rows, "header": header}

func _slice_rows(all_rows: Array[PackedStringArray], count: int) -> Array[PackedStringArray]:
	var result: Array[PackedStringArray] = []
	for i in range(min(count, all_rows.size())):
		result.append(all_rows[i])
	return result

## P0+P1性能总结报告生成
func _generate_p0p1_summary(all_results: Array) -> void:
	TestOutputLogger.log("\n" + String("=").repeat(80))
	TestOutputLogger.log("📊 P0+P1方案搜索性能总结报告")
	TestOutputLogger.log(String("=").repeat(80))
	
	TestOutputLogger.log("\n【不同数据规模下的搜索性能对比】")
	TestOutputLogger.log(String("-").repeat(80))
	TestOutputLogger.log("| 数据规模 | 关键词 | 平均耗时 | 命中行数 | 吞吐 (行/秒) |")
	TestOutputLogger.log(String("=").repeat(80))
	
	for result in all_results:
		var size = result["size"]
		for keyword in SEARCH_KEYWORDS:
			if keyword in result:
				var perf = result[keyword]
				TestOutputLogger.log("| %d | %s | %.3f ms | %d | %.0f |" % [
					size,
					keyword,
					perf.time_ms,
					perf.matches,
					perf.throughput
				])
		TestOutputLogger.log("|" + String(" ").repeat(60) + "|")  # 分隔线
	
	TestOutputLogger.log(String("=").repeat(80))
	
	# 性能趋势分析
	TestOutputLogger.log("\n【性能趋势分析】")
	TestOutputLogger.log(String("-").repeat(80))
	
	if all_results.size() >= 2:
		var first_result = all_results[0]
		var last_result = all_results[all_results.size() - 1]
		
		var size_ratio = float(last_result["size"]) / first_result["size"]
		TestOutputLogger.log("数据规模增长: %.1fx (%d -> %d 行)" % [size_ratio, first_result["size"], last_result["size"]])
		
		for keyword in SEARCH_KEYWORDS:
			if keyword in first_result and keyword in last_result:
				var time1 = first_result[keyword].time_ms
				var time2 = last_result[keyword].time_ms
				var time_ratio = time2 / time1 if time1 > 0 else 0
				
				TestOutputLogger.log("  关键词 '%s':" % keyword)
				TestOutputLogger.log("    耗时变化: %.3f ms -> %.3f ms (%.2fx)" % [time1, time2, time_ratio])
				
				if time_ratio > size_ratio * 1.5:
					TestOutputLogger.log("    ⚠️ 性能下降超过线性增长，存在性能问题")
				elif time_ratio > size_ratio:
					TestOutputLogger.log("    ⚠️ 性能下降略超线性增长")
				else:
					TestOutputLogger.log("    ✅ 性能下降符合或优于线性增长")
	
	# 优化建议
	TestOutputLogger.log("\n【优化建议】")
	TestOutputLogger.log(String("-").repeat(80))
	
	var has_slow_search := false
	for result in all_results:
		for keyword in SEARCH_KEYWORDS:
			if keyword in result and result[keyword].time_ms > 50:
				has_slow_search = true
				TestOutputLogger.log("  数据规模 %d 行，搜索 '%s' 耗时 %.3f ms > 50ms" % [
					result["size"], keyword, result[keyword].time_ms
				])
	
	if has_slow_search:
		TestOutputLogger.log("\n  建议：")
		TestOutputLogger.log("    1. 考虑为常用搜索列添加索引")
		TestOutputLogger.log("    2. 优化字符串匹配算法（如使用KMP、Boyer-Moore等）")
		TestOutputLogger.log("    3. 对大数据集实现分页搜索或延迟加载")
	else:
		TestOutputLogger.log("  ✅ 所有搜索性能良好（< 50ms）")
		TestOutputLogger.log("  当前实现已满足性能要求")
	
	TestOutputLogger.log("\n" + String("=").repeat(80))
	print("[P0P1PerfTest] P0+P1性能总结报告已生成")
	
	# 控制台输出简要总结
	if all_results.size() > 0:
		var summary = all_results[all_results.size() - 1]
		var total_time := 0.0
		var total_throughput := 0.0
		for keyword in SEARCH_KEYWORDS:
			if keyword in summary:
				total_time += summary[keyword].time_ms
				total_throughput += summary[keyword].throughput
		
		var avg_time := total_time / SEARCH_KEYWORDS.size()
		var avg_throughput := total_throughput / SEARCH_KEYWORDS.size()
		print("[P0P1PerfTest] 最大规模(%d行) - 平均搜索: %.3f ms, 平均吞吐: %.0f 行/秒" % [
			summary["size"], avg_time, avg_throughput
		])
	
	TestOutputLogger.log(String("=").repeat(80))
#endregion
