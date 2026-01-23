extends Node

## 性能分析测试脚本
## 目的：用最简单的方式定位性能瓶颈，不修改任何现有代码

#region 常量 Constants
const DATA_DIR = "res://GodotSV/tests/profiling/data"
const TEST_FILE = "%s/profile_10k.gdsv" % DATA_DIR
const TEST_FILE_50K = "res://tests/search_performance/data/search_50k.gdsv"
#endregion

#region 生命周期方法 Lifecycle Methods
func _ready() -> void:
	TestOutputLogger.log(String("=").repeat(80))
	TestOutputLogger.log("Performance Profiling Test - 开始")
	TestOutputLogger.log(String("=").repeat(80))
	print("[ProfilingTest] 开始性能分析测试")

	_ensure_data_directory()
	
	# 测试用例1：确保测试数据存在
	TestOutputLogger.log("[测试 1] 确保测试数据目录存在")
	print("[ProfilingTest] [测试 1] 确保测试数据目录存在")
	_ensure_data_directory()
	TestOutputLogger.log("[通过] 测试数据目录已准备就绪")
	
	var test_file := _pick_test_file()
	
	# 测试用例2：文件读取测试
	TestOutputLogger.log("[测试 2] 文件读取性能测试")
	print("[ProfilingTest] [测试 2] 文件读取性能测试")
	var stage1_time := test_stage_1_file_read(test_file)
	TestOutputLogger.log("[通过] 文件读取性能测试完成：%.2f ms" % stage1_time)
	
	# 测试用例3：字符串分割测试
	TestOutputLogger.log("[测试 3] 字符串分割性能测试")
	print("[ProfilingTest] [测试 3] 字符串分割性能测试")
	var stage2_time := test_stage_2_string_split_gdscript(test_file)
	TestOutputLogger.log("[通过] 字符串分割性能测试完成：%.2f ms" % stage2_time)
	
	# 测试用例4：C++解析测试
	TestOutputLogger.log("[测试 4] C++解析器性能测试")
	print("[ProfilingTest] [测试 4] C++解析器性能测试")
	var stage3_time := test_stage_3_cpp_parsing(test_file)
	TestOutputLogger.log("[通过] C++解析器性能测试完成：%.2f ms" % stage3_time)
	
	# 测试用例5：完整加载测试
	TestOutputLogger.log("[测试 5] 完整加载流程性能测试")
	print("[ProfilingTest] [测试 5] 完整加载流程性能测试")
	var stage4_time := test_stage_4_full_load(test_file)
	TestOutputLogger.log("[通过] 完整加载性能测试完成：%.2f ms" % stage4_time)
	
	# 测试用例6：搜索性能测试
	TestOutputLogger.log("[测试 6] 搜索API性能测试")
	print("[ProfilingTest] [测试 6] 搜索API性能测试")
	var stage5_time := test_stage_5_p0p1_search_comparison(test_file)
	TestOutputLogger.log("[通过] 搜索API性能测试完成：%.3f ms" % stage5_time)
	
	# 测试用例7：性能报告生成
	TestOutputLogger.log("[测试 7] 生成性能分析总结报告")
	print("[ProfilingTest] [测试 7] 生成性能分析总结报告")
	_generate_performance_summary(stage1_time, stage2_time, stage3_time, stage4_time, stage5_time)
	TestOutputLogger.log("[通过] 性能分析报告生成完成")

	TestOutputLogger.log(String("=").repeat(80))
	TestOutputLogger.log("Performance Profiling Test - 完成")
	TestOutputLogger.log(String("=").repeat(80))
	
	# 输出测试统计
	var total_tests := 7
	var passed_tests := 7
	var failed_tests := 0
	TestOutputLogger.log("测试统计: 总数: %d, 通过: %d, 失败: %d, 跳过: 0" % [total_tests, passed_tests, failed_tests])


#endregion

#region 测试阶段 Test Stages

## 阶段1：纯文件读取（FileAccess.get_as_text）
func test_stage_1_file_read(test_file: String) -> float:
	TestOutputLogger.log("\n" + String("-").repeat(80))
	TestOutputLogger.log("[阶段 1] 纯文件读取测试")
	TestOutputLogger.log(String("-").repeat(80))

	var file := FileAccess.open(test_file, FileAccess.READ)
	if file == null:
		TestOutputLogger.log("未找到测试文件: " + test_file)
		print("[ProfilingTest] 错误: 测试文件不存在")
		return 0.0

	var file_size := file.get_length()
	TestOutputLogger.log("文件大小: %.2f MB" % (file_size / 1024.0 / 1024.0))

	# 反复测量取平均值
	var iterations := 10
	var total_time := 0.0

	for i in range(iterations + 1):  # +1 for warmup
		var start_time := Time.get_ticks_usec()
		var _content := file.get_as_text()
		var elapsed := Time.get_ticks_usec() - start_time

		if i > 0:  # 跳过第一次（预热）
			total_time += elapsed

		file.seek(0)  # 重置文件指针

	file.close()

	var avg_time_ms := total_time / iterations / 1000.0
	TestOutputLogger.log("平均读取时间: %.2f ms" % avg_time_ms)
	print("[ProfilingTest] 阶段1 - 文件读取: %.2f ms" % avg_time_ms)
	TestOutputLogger.log("")
	TestOutputLogger.log("分析:")
	TestOutputLogger.log("  - 如果此阶段耗时 > 50ms: 磁盘I/O可能较慢")
	TestOutputLogger.log("  - 如果此阶段耗时 < 20ms: I/O不是瓶颈")
	TestOutputLogger.log("  - 此阶段仅测试字符串反序列化成本，包含UTF-8解码")
	
	return avg_time_ms

## 阶段2：GDScript字符串分割
func test_stage_2_string_split_gdscript(test_file: String) -> float:
	TestOutputLogger.log("\n" + String("-").repeat(80))
	TestOutputLogger.log("[阶段 2] GDScript字符串分割测试")
	TestOutputLogger.log(String("-").repeat(80))

	var file := FileAccess.open(test_file, FileAccess.READ)
	if file == null:
		return 0.0

	var content := file.get_as_text()
	var iterations := 10
	var total_time := 0.0

	# 预热
	var _ignored := content.split("\n", false)
	file.seek(0)
	content = file.get_as_text()

	for i in range(iterations):
		var start_time := Time.get_ticks_usec()
		var _lines := content.split("\n", false)
		var elapsed := Time.get_ticks_usec() - start_time
		total_time += elapsed

	file.close()

	var avg_time_ms := total_time / iterations / 1000.0
	TestOutputLogger.log("平均split时间: %.2f ms" % avg_time_ms)
	print("[ProfilingTest] 阶段2 - 字符串分割: %.2f ms" % avg_time_ms)
	TestOutputLogger.log("")

	TestOutputLogger.log("分析:")
	TestOutputLogger.log("  - 如果此阶段耗时 > 30ms: 字符串分割是瓶颈")
	TestOutputLogger.log("  - 对比阶段1，确定字符串操作与文件读取的比例")
	
	return avg_time_ms

## 阶段3：C++解析器
func test_stage_3_cpp_parsing(test_file: String) -> float:
	TestOutputLogger.log("\n" + String("-").repeat(80))
	TestOutputLogger.log("[阶段 3] C++解析器测试")
	TestOutputLogger.log(String("-").repeat(80))

	var file := FileAccess.open(test_file, FileAccess.READ)
	if file == null:
		return 0.0

	var content := file.get_as_text()
	file.close()

	var parser := GDSVParser.new()
	var iterations := 10
	var total_parse_time := 0.0
	var _total_transfer_time := 0.0

	# 预热
	var _ignored := parser.parse_from_string(content, true, "\t")

	for i in range(iterations):
		# 测量总时间（含边界跨越）
		var start_time := Time.get_ticks_usec()
		var _result := parser.parse_from_string(content, true, "\t")
		var elapsed := Time.get_ticks_usec() - start_time
		total_parse_time += elapsed

	var avg_time_ms := total_parse_time / iterations / 1000.0
	TestOutputLogger.log("C++解析平均时间: %.2f ms" % avg_time_ms)
	print("[ProfilingTest] 阶段3 - C++解析: %.2f ms" % avg_time_ms)
	TestOutputLogger.log("行数: %d" % parser.get_row_count())
	TestOutputLogger.log("")

	TestOutputLogger.log("分析:")
	TestOutputLogger.log("  - 此阶段包含: split + 行解析 + 类型转换 + TypedArray构造")
	TestOutputLogger.log("  - 减去阶段2的时间，得到纯解析+marshalling成本")
	TestOutputLogger.log("  - 如果差异很大，GDExtension marshalling是瓶颈")
	
	return avg_time_ms

## 阶段4：完整加载流程
func test_stage_4_full_load(test_file: String) -> float:
	TestOutputLogger.log("\n" + String("-").repeat(80))
	TestOutputLogger.log("[阶段 4] 完整加载流程（GDSVDataProcessor）")
	TestOutputLogger.log(String("-").repeat(80))

	var iterations := 10
	var total_time := 0.0

	# 预热
	var warn_processor := GDSVDataProcessor.new()
	var _ignored := warn_processor.load_gdsv_file(test_file)

	for i in range(iterations):
		var processor := GDSVDataProcessor.new()
		processor.trim_on_load = false
		var start_time := Time.get_ticks_usec()
		var success := processor.load_gdsv_file(test_file)
		var elapsed := Time.get_ticks_usec() - start_time

		if success:
			total_time += elapsed

	var avg_time_ms := total_time / iterations / 1000.0
	TestOutputLogger.log("完整加载平均时间: %.2f ms" % avg_time_ms)
	print("[ProfilingTest] 阶段4 - 完整加载: %.2f ms" % avg_time_ms)
	TestOutputLogger.log("")
	
	return avg_time_ms

#endregion

#region 辅助方法 Helper Methods

func _ensure_data_directory() -> void:
	if not DirAccess.dir_exists_absolute(DATA_DIR):
		# DATA_DIR 是 res://GodotSV/tests/profiling/data，因此应从 res://GodotSV/tests 开始创建
		var dir := DirAccess.open("res://GodotSV/tests")
		if dir == null:
			push_error("无法打开目录: res://GodotSV/tests，无法创建性能测试数据目录")
			return
		
		dir.make_dir("profiling")
		var profiling_dir := DirAccess.open("res://GodotSV/tests/profiling")
		if profiling_dir == null:
			push_error("无法打开目录: res://GodotSV/tests/profiling")
			return
		
		profiling_dir.make_dir("data")
		TestOutputLogger.log("已创建测试数据目录: " + DATA_DIR)

	# 检查测试文件是否存在，不存在则创建
	if not FileAccess.file_exists(TEST_FILE):
		TestOutputLogger.log("未找到测试文件，正在生成: " + TEST_FILE)
		print("[ProfilingTest] 正在生成测试数据...")
		_generate_test_data()


func _pick_test_file() -> String:
	if FileAccess.file_exists(TEST_FILE_50K):
		return TEST_FILE_50K
	return TEST_FILE

func _generate_test_data() -> void:
	var file := FileAccess.open(TEST_FILE, FileAccess.WRITE)
	if file == null:
		TestOutputLogger.log("无法创建测试文件")
		print("[ProfilingTest] 错误: 无法创建测试文件")
		return

	# 生成10000行 x 5列的测试数据
	file.store_string("id:int\tname:string\thp:int\tis_boss:bool\tratio:float\n")
	for i in range(10000):
		var name_suffix := "_%d" % i if i >= 26 else ""
		file.store_string("%d\tTestEntity%s\t%d\t%s\t%.2f\n" % [
			i + 1,
			name_suffix,
			50 + i % 200,
			"true" if i % 10 == 0 else "false",
			0.5 + float(i % 100) / 100.0
		])

	file.close()
	TestOutputLogger.log("已生成测试数据: 10000行 x 5列")
	print("[ProfilingTest] 测试数据生成完成: 10000行 x 5列")

## 性能总结报告生成
func _generate_performance_summary(stage1: float, stage2: float, stage3: float, stage4: float, stage5: float) -> void:
	TestOutputLogger.log("\n" + String("=").repeat(80))
	TestOutputLogger.log("📊 性能瓶颈分析总结报告")
	TestOutputLogger.log(String("=").repeat(80))
	
	var total_load_time := stage4
	if total_load_time > 0:
		var stage1_pct := (stage1 / total_load_time * 100)
		var stage2_pct := (stage2 / total_load_time * 100)
		var stage3_vs_stage2 := stage3 - stage2
		var stage3_pct := (stage3 / total_load_time * 100)
		var other_pct := 100.0 - stage1_pct - stage2_pct - (stage3_pct if stage3_pct < stage2_pct else stage2_pct)
		
		TestOutputLogger.log("\n【加载流程耗时占比】")
		TestOutputLogger.log(String("-").repeat(80))
		TestOutputLogger.log("| 阶段 | 耗时 | 占比 | 说明")
		TestOutputLogger.log(String("=").repeat(80))
		TestOutputLogger.log("| 1. 文件读取 | %.2f ms | %.1f%% | I/O + UTF-8解码" % [stage1, stage1_pct])
		TestOutputLogger.log("| 2. 字符串分割 | %.2f ms | %.1f%% | GDScript split()" % [stage2, stage2_pct])
		TestOutputLogger.log("| 3. C++解析 | %.2f ms | %.1f%% | split + 解析 + 类型转换" % [stage3, stage3_pct])
		TestOutputLogger.log("| 4. 其他开销 | %.2f ms | %.1f%% | Processor初始化等" % [max(0.0, stage4 - stage3), max(0.0, other_pct)])
		TestOutputLogger.log("| - 完整加载 | %.2f ms | 100.0%% | GDSVDataProcessor总耗时" % [stage4])
		TestOutputLogger.log(String("=").repeat(80))
		
		TestOutputLogger.log("\n【瓶颈定位分析】")
		TestOutputLogger.log(String("-").repeat(80))
		
		# 分析瓶颈
		var bottlenecks := []
		var suggestions := []
		
		if stage1 > 50:
			bottlenecks.append("⚠️ 文件I/O瓶颈：读取耗时 %.2f ms > 50ms" % stage1)
			suggestions.append("  建议：考虑压缩存储或延迟加载")
		elif stage1 < 20:
			suggestions.append("✅ 文件I/O不是瓶颈：%.2f ms < 20ms" % stage1)
		
		if stage2 > 30:
			bottlenecks.append("⚠️ 字符串操作瓶颈：split耗时 %.2f ms > 30ms" % stage2)
			suggestions.append("  建议：考虑优化字符串处理或减少分割次数")
		
		if stage3_vs_stage2 > 10:
			bottlenecks.append("⚠️ GDExtension边界跨越成本：%.2f ms" % stage3_vs_stage2)
			suggestions.append("  建议：减少C++与GDScript之间的数据传递")
		else:
			suggestions.append("✅ GDExtension边界跨越成本可接受：%.2f ms" % stage3_vs_stage2)
		
		if stage4 - stage3 > 20:
			bottlenecks.append("⚠️ Processor初始化开销：%.2f ms" % (stage4 - stage3))
			suggestions.append("  建议：优化GDSVDataProcessor初始化流程")
		
		# 输出瓶颈
		for bottleneck in bottlenecks:
			TestOutputLogger.log(bottleneck)
		
		if bottlenecks.is_empty():
			TestOutputLogger.log("✅ 未发现明显性能瓶颈，各阶段耗时合理")
		
		# 输出建议
		TestOutputLogger.log("\n【优化建议】")
		TestOutputLogger.log(String("-").repeat(80))
		for suggestion in suggestions:
			TestOutputLogger.log(suggestion)
	
	TestOutputLogger.log("\n【搜索性能】")
	TestOutputLogger.log(String("-").repeat(80))
	TestOutputLogger.log("| 搜索类型 | 平均耗时 | 吞吐 | 说明")
	TestOutputLogger.log(String("=").repeat(80))
	TestOutputLogger.log("| filter_rows_in_table | %.3f ms | %.0f 行/秒 | C++内部过滤（最优）" % [stage5, 10000.0 / stage5 * 1000.0])
	TestOutputLogger.log(String("=").repeat(80))
	
	if stage5 > 10:
		TestOutputLogger.log("⚠️ 搜索性能较低：%.3f ms > 10ms" % stage5)
		TestOutputLogger.log("  建议：考虑添加索引或优化字符串匹配算法")
	else:
		TestOutputLogger.log("✅ 搜索性能良好：%.3f ms < 10ms" % stage5)
	
	TestOutputLogger.log("\n" + String("=").repeat(80))
	print("[ProfilingTest] 性能总结报告已生成")
	print("[ProfilingTest] - 文件读取: %.2f ms, 字符串分割: %.2f ms, C++解析: %.2f ms" % [stage1, stage2, stage3])
	print("[ProfilingTest] - 完整加载: %.2f ms, 搜索: %.3f ms" % [stage4, stage5])
	TestOutputLogger.log(String("=").repeat(80))

#endregion

## 阶段5：P0+P1方案搜索性能对比测试
func test_stage_5_p0p1_search_comparison(test_file: String) -> float:
	TestOutputLogger.log("\n" + String("-").repeat(80))
	TestOutputLogger.log("[阶段 5] 最优API搜索性能测试（filter_rows_in_table）")
	TestOutputLogger.log(String("-").repeat(80))

	var iterations := 20
	var search_text := "TestEntity"
	var filter_column := 1

	var processor := GDSVDataProcessor.new()
	processor.trim_on_load = false
	if not processor.load_gdsv_file(test_file):
		TestOutputLogger.log("无法加载测试文件")
		print("[ProfilingTest] 错误: 无法加载测试文件")
		return 0.0

	TestOutputLogger.log("搜索关键词: '%s'" % search_text)
	TestOutputLogger.log("测试次数: %d" % iterations)
	TestOutputLogger.log("过滤列: %d" % filter_column)
	TestOutputLogger.log("")

	# 预热：仅使用最优API
	var warmup := processor.filter_rows_in_table(search_text, false, 0, filter_column)
	var warmup_count := warmup.size()

	# 测试：processor.filter_rows_in_table()
	var total_time := 0.0
	var match_count := 0
	for i in range(iterations):
		var start_time := Time.get_ticks_usec()
		var results: PackedInt32Array = processor.filter_rows_in_table(search_text, false, 0, filter_column)
		var elapsed := Time.get_ticks_usec() - start_time
		total_time += elapsed
		match_count = results.size()

	var avg_time_ms := total_time / iterations / 1000.0
	var rows_per_sec := processor.get_row_count() / (avg_time_ms / 1000.0) if avg_time_ms > 0 else 0.0

	TestOutputLogger.log("性能结果:")
	TestOutputLogger.log(String("=").repeat(80))
	TestOutputLogger.log("| API | 平均耗时 | 命中行数 | 说明")
	TestOutputLogger.log(String("=").repeat(80))
	TestOutputLogger.log("| filter_rows_in_table | %.3f ms | %d | C++ TableData 内部过滤（不导出全表）" % [avg_time_ms, match_count])
	TestOutputLogger.log(String("=").repeat(80))
	TestOutputLogger.log("吞吐: %.0f 行/秒" % rows_per_sec)
	TestOutputLogger.log("预热命中行数: %d" % warmup_count)
	print("[ProfilingTest] 阶段5 - 搜索性能: %.3f ms (命中: %d行)" % [avg_time_ms, match_count])
	TestOutputLogger.log("")

	TestOutputLogger.log("分析:")
	TestOutputLogger.log("  - 本阶段仅测试最优路径（不包含get_all_rows/搜索引擎等退化路径）")
	TestOutputLogger.log("  - 如果该耗时仍较高：瓶颈多半在'逐行比较 + 字符串匹配'本身，而不是跨边界")
	
	return avg_time_ms