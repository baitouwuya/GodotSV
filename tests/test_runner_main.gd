extends Control

## Test Runner Main - GDSV Test Suite UI
##
## A UI-based test runner for GDSV plugin tests.
## Provides categorized test execution with result visualization.

#region UI References
@onready var category_container: VBoxContainer = $HSplitContainer/CategoryPanel/VBoxContainer
# Tab Container references
@onready var tab_container: TabContainer = $HSplitContainer/ResultsPanel/VBoxContainer/TabContainer

# Overview Tab references
@onready var stat_total_label: Label = $HSplitContainer/ResultsPanel/VBoxContainer/TabContainer/OverviewTab/MarginContainer/VBoxContainer/StatsHBox/StatCard1/VBoxContainer/StatValueLabel
@onready var stat_passed_label: Label = $HSplitContainer/ResultsPanel/VBoxContainer/TabContainer/OverviewTab/MarginContainer/VBoxContainer/StatsHBox/StatCard2/VBoxContainer/StatValueLabel
@onready var stat_failed_label: Label = $HSplitContainer/ResultsPanel/VBoxContainer/TabContainer/OverviewTab/MarginContainer/VBoxContainer/StatsHBox/StatCard3/VBoxContainer/StatValueLabel
@onready var stat_skipped_label: Label = $HSplitContainer/ResultsPanel/VBoxContainer/TabContainer/OverviewTab/MarginContainer/VBoxContainer/StatsHBox/StatCard4/VBoxContainer/StatValueLabel
@onready var pass_rate_label: Label = $HSplitContainer/ResultsPanel/VBoxContainer/TabContainer/OverviewTab/MarginContainer/VBoxContainer/PassRateVBox/PassRateLabel
@onready var progress_bar: ProgressBar = $HSplitContainer/ResultsPanel/VBoxContainer/TabContainer/OverviewTab/MarginContainer/VBoxContainer/PassRateVBox/PassRateBar
@onready var stats_label: Label = $HSplitContainer/ResultsPanel/VBoxContainer/TabContainer/OverviewTab/MarginContainer/VBoxContainer/StatsLabel
@onready var time_label: Label = $HSplitContainer/ResultsPanel/VBoxContainer/TabContainer/OverviewTab/MarginContainer/VBoxContainer/MetricsHBox/TimeLabel
@onready var status_label: Label = $HSplitContainer/ResultsPanel/VBoxContainer/TabContainer/OverviewTab/MarginContainer/VBoxContainer/MetricsHBox/StatusLabel
@onready var category_stats_label: Label = $HSplitContainer/ResultsPanel/VBoxContainer/TabContainer/OverviewTab/MarginContainer/VBoxContainer/CategoryStatsLabel

# Details Tab references
@onready var filter_option: OptionButton = $HSplitContainer/ResultsPanel/VBoxContainer/TabContainer/DetailsTab/VBoxContainer/ToolbarHBox/FilterOption
@onready var search_edit: LineEdit = $HSplitContainer/ResultsPanel/VBoxContainer/TabContainer/DetailsTab/VBoxContainer/ToolbarHBox/SearchEdit
@onready var summary_tree: Tree = $HSplitContainer/ResultsPanel/VBoxContainer/TabContainer/DetailsTab/VBoxContainer/SummaryScroll/SummaryTree

# Output Tab references
@onready var copy_btn: Button = $HSplitContainer/ResultsPanel/VBoxContainer/TabContainer/OutputTab/VBoxContainer/ToolbarHBox/CopyBtn
@onready var clear_btn: Button = $HSplitContainer/ResultsPanel/VBoxContainer/TabContainer/OutputTab/VBoxContainer/ToolbarHBox/ClearBtn
@onready var export_btn: Button = $HSplitContainer/ResultsPanel/VBoxContainer/TabContainer/OutputTab/VBoxContainer/ToolbarHBox/ExportBtn
@onready var auto_scroll_check: CheckBox = $HSplitContainer/ResultsPanel/VBoxContainer/TabContainer/OutputTab/VBoxContainer/ToolbarHBox/AutoScrollCheck
@onready var results_label: RichTextLabel = $HSplitContainer/ResultsPanel/VBoxContainer/TabContainer/OutputTab/VBoxContainer/ResultsScroll/ResultsLabel
#endregion

#region Test Categories Configuration
var test_categories: Array[Dictionary] = [
	{
		"name": "Basic Format I/O Tests",
		"scene_path": "res://tests/basic_io/basic_io_test.tscn",
		"description": "Basic GDSV file read/write functionality"
	},
	{
		"name": "Multi-Format I/O Tests",
		"scene_path": "res://tests/multi_format/multi_format_test.tscn",
		"description": "CSV, TSV, and GDSV format compatibility"
	},
	{
		"name": "Performance Profiling Tests",
		"scene_path": "res://tests/profiling/profiling_test.tscn",
		"description": "Identify performance bottlenecks"
	},
	{
		"name": "Large File I/O Tests",
		"scene_path": "res://tests/large_file/large_file_test.tscn",
		"description": "Performance tests for large datasets"
	},
	{
		"name": "Search Performance Tests",
		"scene_path": "res://tests/search_performance/search_performance_test.tscn",
		"description": "Search operation performance benchmarks"
	},
	{
		"name": "Existing Search Function Tests",
		"scene_path": "res://tests/search/simple_search_test.tscn",
		"description": "Current search functionality validation"
	},
	{
		"name": "Type Optimization Tests",
		"scene_path": "res://tests/type_optimization/type_optimization_test.tscn",
		"description": "StringName type conversion optimization validation"
	}
]
#endregion

#region Test Runtime State
var current_test_scene: Node = null
var test_output_buffer: PackedStringArray = []
var test_stats: Dictionary = {
	"total": 0,
	"passed": 0,
	"failed": 0,
	"skipped": 0
}
var is_running: bool = false
var start_time: float = 0.0
var test_results: Array[Dictionary] = []  # Store individual test results
var current_test_name: String = ""  # Track current test name
var current_category_name: String = ""  # Track current test category
var test_start_times: Dictionary = {}  # Track individual test start times (test_name -> start_time_ms)

# Run all tests state
var is_running_all_tests: bool = false
var current_test_index: int = 0
var total_test_count: int = 0

# Output batching optimization
var output_buffer_pending: PackedStringArray = []  # Pending output messages for batch update
var output_update_timer: Timer = null  # Timer for batch output updates
const OUTPUT_UPDATE_INTERVAL_MS := 100  # Update output every 100ms
#endregion

#region Colors for Formatting
const COLOR_PASS := "[color=green]"
const COLOR_FAIL := "[color=red]"
const COLOR_INFO := "[color=cyan]"
const COLOR_WARN := "[color=yellow]"
const COLOR_SEPARATOR := "[color=gray]"
const SEPARATOR_LINE := "============================================================"  # 60个等号
#endregion


#region Lifecycle Methods

func _ready() -> void:
	_setup_ui()
	_setup_output_timer()
	_connect_print_signals()
	_clear_results()

	# Connect tree signals
	summary_tree.item_activated.connect(_on_tree_item_activated)

#endregion


#region UI Setup

func _setup_ui() -> void:
	# Setup tab titles
	tab_container.set_tab_title(0, "概览")
	tab_container.set_tab_title(1, "详情")
	tab_container.set_tab_title(2, "输出")

	# Setup tree columns for details tab
	summary_tree.set_column_title(0, "名称")
	summary_tree.set_column_title(1, "状态")
	summary_tree.set_column_title(2, "耗时")
	summary_tree.set_column_custom_minimum_width(0, 300)
	summary_tree.set_column_custom_minimum_width(1, 80)
	summary_tree.set_column_custom_minimum_width(2, 100)

	# Connect button signals
	copy_btn.pressed.connect(_on_copy_all_clicked)
	clear_btn.pressed.connect(_on_clear_clicked)
	export_btn.pressed.connect(_on_export_clicked)
	search_edit.text_changed.connect(_on_search_text_changed)
	filter_option.item_selected.connect(_on_filter_selected)

	# Clear existing buttons
	for child in category_container.get_children():
		child.queue_free()

	# Add title
	var title := Label.new()
	title.text = "GDSV Test Suite"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	category_container.add_child(title)

	# Add separator
	var separator1 := HSeparator.new()
	category_container.add_child(separator1)

	# Add category buttons
	for category in test_categories:
		var button := Button.new()
		button.text = category.name
		var tooltip := "%s\n\n%s" % [category.name, category.description]
		button.tooltip_text = tooltip
		button.pressed.connect(_on_test_category_clicked.bind(category))
		category_container.add_child(button)

	# Add separator
	var separator2 := HSeparator.new()
	category_container.add_child(separator2)

	# Add "Run All" button
	var run_all_button := Button.new()
	run_all_button.text = "Run All Tests"
	run_all_button.add_theme_color_override("font_color", Color.CYAN)
	run_all_button.pressed.connect(_on_run_all_tests)
	category_container.add_child(run_all_button)

	# Add "Clear Results" button
	var clear_button := Button.new()
	clear_button.text = "Clear Results"
	clear_button.pressed.connect(_clear_results)
	category_container.add_child(clear_button)


func _connect_print_signals() -> void:
	# 连接 Autoload 单例的信号
	if TestOutputLogger:
		TestOutputLogger.message_emitted.connect(_on_print_message)


func _setup_output_timer() -> void:
	# Setup timer for batch output updates
	output_update_timer = Timer.new()
	output_update_timer.wait_time = OUTPUT_UPDATE_INTERVAL_MS / 1000.0
	output_update_timer.one_shot = true
	output_update_timer.timeout.connect(_flush_output_buffer)
	add_child(output_update_timer)


#endregion


#region Test Execution

func _on_test_category_clicked(category: Dictionary) -> void:
	if is_running:
		_append_output(COLOR_WARN, "[Warning] Test already running, please wait...")
		return

	if not FileAccess.file_exists(category.scene_path):
		_append_output(COLOR_FAIL, "[Error] Test scene not found: %s" % category.scene_path)
		return

	current_category_name = category.name
	_run_test(category.scene_path)


func _on_run_all_tests() -> void:
	if is_running:
		_append_output(COLOR_WARN, "[Warning] Tests already running, please wait...")
		return

	_clear_results()
	is_running_all_tests = true
	current_test_index = 0
	total_test_count = test_categories.size()

	for i in range(test_categories.size()):
		current_test_index = i
		var category: Dictionary = test_categories[i]
		current_category_name = category.name
		_append_output(COLOR_SEPARATOR, "\n" + SEPARATOR_LINE)
		_append_output(COLOR_INFO, "Running: %s" % category.name)
		_append_output(COLOR_SEPARATOR, SEPARATOR_LINE)

		# Only reset stats for the first test, accumulate for subsequent tests
		_run_test(category.scene_path, i == 0)

		if current_test_scene:
			await _wait_for_test_completion()

		_append_output(COLOR_SEPARATOR, "\n")

	is_running_all_tests = false
	_append_output(COLOR_INFO, "All tests completed!")
	_update_stats_display()
	_update_details_tree()


func _run_test(scene_path: String, reset_stats: bool = true) -> void:
	if reset_stats:
		_reset_test_state()
	is_running = true
	start_time = Time.get_ticks_msec()
	status_label.text = "运行中..."
	progress_bar.value = 0.0

	var packed_scene := load(scene_path) as PackedScene
	if not packed_scene:
		_append_output(COLOR_FAIL, "[Error] Failed to load scene: %s" % scene_path)
		_mark_test_completed()
		return

	# Remove previous test scene
	if current_test_scene:
		current_test_scene.queue_free()
		await current_test_scene.tree_exited

	# Instance and add the test scene
	current_test_scene = packed_scene.instantiate()
	add_child(current_test_scene)

	_append_output(COLOR_INFO, "Started: %s" % scene_path)

	# Wait for test to complete - extend wait time
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	_mark_test_completed()


func _wait_for_test_completion() -> void:
	# Wait for test scene to finish or a timeout
	var timeout := 30.0  # 30 seconds max
	var start_wait_time := Time.get_ticks_msec()

	while is_running and (Time.get_ticks_msec() - start_wait_time) / 1000.0 < timeout:
		await get_tree().process_frame

	_mark_test_completed()


func _mark_test_completed() -> void:
	is_running = false
	var elapsed := (Time.get_ticks_msec() - start_time) / 1000.0
	time_label.text = "耗时: %.2fs" % elapsed
	status_label.text = "就绪"

	# Force flush any pending output immediately
	_flush_output_buffer()

	# Update UI after test completion
	_update_stats_display()
	_update_details_tree()


#endregion


#region Print Output Capture

signal _print_message(message: String)

func _on_print_message(message: String) -> void:
	test_output_buffer.append(message)

	# Parse test results from output
	_parse_test_output(message)

	# Batch output: add to pending buffer instead of immediate display
	output_buffer_pending.append(message)

	# Start/restart the flush timer
	if output_update_timer:
		output_update_timer.start()


func _print(message: Variant) -> void:
	_print_message.emit(str(message))


func _parse_test_output(message: String) -> void:
	# Strip leading/trailing whitespace for more robust matching
	var clean_message := message.strip_edges()

	# Detect test start marker: [测试 N] or [Test N]
	# Example: [测试 1] 读取基本GDSV文件
	# Note: Messages may have leading newline like "\n[测试 1] ..."
	var test_start_regex = RegEx.new()
	test_start_regex.compile("^\\[测试\\s*\\d+\\]\\s*(.+)")
	var test_start_result = test_start_regex.search(clean_message)

	if test_start_result:
		current_test_name = test_start_result.get_string(1).strip_edges()
		# Record the start time for this individual test
		test_start_times[current_test_name] = Time.get_ticks_msec()
		return  # Just record test name, don't increment total yet

	# Detect test result markers: [通过] or [失败]
	# Example:   [通过] 成功读取并验证GDSV文件
	if "[通过]" in message or "[ PASS]" in message or "(PASS)" in message:
		if not current_test_name.is_empty():
			# Calculate duration for this individual test
			var duration_ms: int = 0
			if test_start_times.has(current_test_name):
				duration_ms = Time.get_ticks_msec() - test_start_times[current_test_name]
				test_start_times.erase(current_test_name)  # Clean up

			test_stats.passed += 1
			test_stats.total += 1
			test_results.append({
				"name": current_test_name,
				"status": "passed",
				"category": current_category_name,
				"message": message.strip_edges(),
				"duration": duration_ms
			})
			
			# 立即更新概览标签页
			_update_stats_display()
			
			current_test_name = ""
	elif "[失败]" in message or "[ FAIL]" in message or "(FAIL)" in message:
		if not current_test_name.is_empty():
			# Calculate duration for this individual test
			var duration_ms: int = 0
			if test_start_times.has(current_test_name):
				duration_ms = Time.get_ticks_msec() - test_start_times[current_test_name]
				test_start_times.erase(current_test_name)  # Clean up

			test_stats.failed += 1
			test_stats.total += 1
			test_results.append({
				"name": current_test_name,
				"status": "failed",
				"category": current_category_name,
				"message": message.strip_edges(),
				"duration": duration_ms
			})
			
			# 立即更新概览标签页
			_update_stats_display()
			
			current_test_name = ""

	# Parse test summary statistics from output
	# Example: 测试统计: 总数: 10, 通过: 8, 失败: 2
	if "测试统计:" in message:
		var stats_line = message.replace("测试统计:", "").strip_edges()
		var parts = stats_line.split(", ")
		for part in parts:
			if "总数:" in part:
				test_stats.total = part.split(":")[1].to_int()
			elif "通过:" in part:
				test_stats.passed = part.split(":")[1].to_int()
			elif "失败:" in part:
				test_stats.failed = part.split(":")[1].to_int()
			elif "跳过:" in part or "skipped" in part.to_lower():
				test_stats.skipped = part.split(":")[1].to_int()
		
		# 解析到汇总统计时，也更新概览
		_update_stats_display()


func _flush_output_buffer() -> void:
	# Display all pending output at once
	if output_buffer_pending.is_empty():
		return

	var accumulated_text := ""
	for message in output_buffer_pending:
		accumulated_text += _format_output_bbcode(message) + "\n"

	# Single append_text call for all accumulated text
	results_label.append_text(accumulated_text)

	# Clear the pending buffer
	output_buffer_pending.clear()

	# Auto-scroll if enabled
	if auto_scroll_check.button_pressed:
		results_label.scroll_to_line(results_label.get_line_count() - 1)


func _format_output_bbcode(message: String) -> String:
	# Convert message to BBCode format
	var output_bbcode := message

	# Convert common patterns to BBCode
	if message.begins_with("="):
		output_bbcode = COLOR_SEPARATOR + message + "[/color]"
	elif message.begins_with("-"):
		output_bbcode = COLOR_SEPARATOR + message + "[/color]"
	elif "通过" in message or "PASS" in message:
		output_bbcode = COLOR_PASS + message + "[/color]"
	elif "失败" in message or "FAIL" in message:
		output_bbcode = COLOR_FAIL + message + "[/color]"
	elif "测试" in message or "Test" in message:
		output_bbcode = COLOR_INFO + message + "[/color]"
	elif "[测试" in message:
		output_bbcode = COLOR_INFO + message + "[/color]"

	return output_bbcode


func _display_output(message: String) -> void:
	# Display a single message immediately (used for non-batched scenarios)
	results_label.append_text(_format_output_bbcode(message) + "\n")

	# Auto-scroll if enabled
	if auto_scroll_check.button_pressed:
		results_label.scroll_to_line(results_label.get_line_count() - 1)


func _append_output(color_code: String, message: String) -> void:
	results_label.append_text(color_code + message + "[/color]" + "\n")


#endregion


#region Statistics and Display

func _reset_test_state() -> void:
	test_stats = {"total": 0, "passed": 0, "failed": 0, "skipped": 0}
	test_output_buffer.clear()
	output_buffer_pending.clear()  # Clear pending output buffer
	test_results.clear()
	current_test_name = ""
	current_category_name = ""
	test_start_times.clear()  # Clear test start times
	start_time = Time.get_ticks_msec()

	# Stop the output timer if running
	if output_update_timer and output_update_timer.time_left > 0:
		output_update_timer.stop()


func _update_stats_display() -> void:
	var total: int = test_stats.total
	var passed: int = test_stats.passed
	var failed: int = test_stats.failed
	var skipped: int = test_stats.skipped
	var rate := 0.0

	# Only calculate pass rate if there are tests completed
	if total > 0:
		rate = (passed * 100.0) / total

	# Update stat cards
	stat_total_label.text = str(total)
	stat_passed_label.text = str(passed)
	stat_failed_label.text = str(failed)
	stat_skipped_label.text = str(skipped)

	# Update pass rate label
	if total > 0:
		pass_rate_label.text = "%.1f%%" % rate
	else:
		pass_rate_label.text = "等待测试..."

	# Update progress bar
	if is_running_all_tests:
		# Show execution progress when running all tests
		var execution_progress: float = (current_test_index + 1) * 100.0 / float(total_test_count)
		progress_bar.value = execution_progress
		pass_rate_label.text = "执行中: %d/%d" % [current_test_index + 1, total_test_count]
	elif total > 0:
		# Show pass rate after tests complete
		var pass_rate := (passed * 100.0) / float(total)
		progress_bar.value = pass_rate
	elif is_running:
		progress_bar.value = 0.0
	# else: keep current value

	# Update stats label (kept for compatibility)
	var stats_text := "Tests: %d | Passed: %d | Failed: %d | Skipped: %d | Rate: %.1f%%" % [total, passed, failed, skipped, rate]
	stats_label.text = stats_text

	# Update time label
	if is_running:
		var elapsed := (Time.get_ticks_msec() - start_time) / 1000.0
		time_label.text = "耗时: %.2fs" % elapsed

	# Update category statistics
	_update_category_stats_display()


func _update_category_stats_display() -> void:
	# Calculate statistics for each category
	var category_map: Dictionary = {}

	for result in test_results:
		var category := result.get("category", "未分类") as String
		if category.is_empty():
			category = "未分类"

		if not category_map.has(category):
			category_map[category] = {"total": 0, "passed": 0, "failed": 0}

		category_map[category].total += 1
		if result.get("status") == "passed":
			category_map[category].passed += 1
		elif result.get("status") == "failed":
			category_map[category].failed += 1

	# Build category stats text
	var stats_lines: PackedStringArray = []

	if category_map.is_empty():
		category_stats_label.text = "暂无测试数据"
	else:
		stats_lines.append("【分类统计】")
		for category in category_map:
			var stats: Dictionary = category_map[category]
			var pass_rate := 0.0
			if stats.total > 0:
				pass_rate = (stats.passed * 100.0) / stats.total

			stats_lines.append("  %s: %d/%d/%d ( %.1f%%)" % [
				category,
				stats.passed,
				stats.total,
				stats.failed,
				pass_rate
			])

		category_stats_label.text = "\n".join(stats_lines)


func _update_details_tree() -> void:
	# Clear existing tree
	summary_tree.clear()

	# Create hidden root
	var root := summary_tree.create_item()
	root.set_collapsed(false)

	# Group test results by category
	var category_map: Dictionary = {}

	for result in test_results:
		var category := result.get("category", "未分类") as String
		if category.is_empty():
			category = "未分类"

		if not category_map.has(category):
			category_map[category] = []
		category_map[category].append(result)

	# If no categories, create "所有测试" group
	if category_map.is_empty():
		category_map["所有测试"] = []

	# Create tree items for each category
	for category in category_map:
		var tests: Array = category_map[category]

		# Create category node (root item)
		var category_item := summary_tree.create_item(root)
		category_item.set_text(0, category)
		category_item.set_text(1, "%d 测试" % tests.size())
		category_item.set_collapsed(false)

		# Create test items under category
		for test in tests:
			var test_item := summary_tree.create_item(category_item)
			test_item.set_text(0, test.name)
			test_item.set_text(1, "通过" if test.status == "passed" else "失败")
			# Display duration in milliseconds or seconds
			var duration_ms := test.get("duration", 0) as int
			if duration_ms >= 1000:
				test_item.set_text(2, "%.2fs" % (duration_ms / 1000.0))
			else:
				test_item.set_text(2, "%dms" % duration_ms)

			# Set icon or color based on status
			if test.status == "passed":
				test_item.set_custom_color(0, Color.GREEN)
				test_item.set_custom_color(1, Color.GREEN)
			else:
				test_item.set_custom_color(0, Color.RED)
				test_item.set_custom_color(1, Color.RED)

			# Store test data index in metadata for lookup
			test_item.set_metadata(0, test_results.find(test))

	# Expand all items
	summary_tree.set_hide_root(true)


func _clear_results() -> void:
	results_label.clear()
	_reset_test_state()
	_update_stats_display()

	# Clear tree
	summary_tree.clear()

	# Add welcome message
	_append_output(COLOR_INFO, SEPARATOR_LINE)
	_append_output(COLOR_INFO, "GDSV Test Suite - Ready")
	_append_output(COLOR_INFO, SEPARATOR_LINE)
	_append_output(COLOR_SEPARATOR, "\nSelect a test category from the left panel to begin.")
	results_label.scroll_to_line(0)


func _on_copy_all_clicked() -> void:
	DisplayServer.clipboard_set(results_label.text)


func _on_clear_clicked() -> void:
	_clear_results()


func _on_export_clicked() -> void:
	var save_path := "res://test_export_%s.txt" % Time.get_datetime_string_from_system().replace(":", "-")
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(results_label.text)
		file.close()
		_append_output(COLOR_INFO, "Results exported to: %s" % save_path)
	else:
		_append_output(COLOR_FAIL, "Failed to export results to: %s" % save_path)


func _on_search_text_changed(text: String) -> void:
	# Filter tree items based on search text
	var root: TreeItem = summary_tree.get_root()
	if not root:
		return

	for category_item in root.get_children():
		# Category level
		var has_visible_children := false

		# Check each test item under category
		for test_item in category_item.get_children():
			var item_name: String = test_item.get_text(0).to_lower()
			var matches := text.is_empty() or text.to_lower() in item_name

			test_item.visible = matches
			if matches:
				has_visible_children = true

		# Show category only if it has visible children or if search is empty
		category_item.visible = has_visible_children


func _on_filter_selected(index: int) -> void:
	# Filter tree items based on selected filter option
	var root: TreeItem = summary_tree.get_root()
	if not root:
		return

	for category_item in root.get_children():
		# Category level - count visible children
		var has_visible_children := false

		# Check each test item under category
		for test_item in category_item.get_children():
			var status: String = test_item.get_text(1)
			var should_show := false

			match index:
				0:  # All
					should_show = true
				1:  # Pass
					should_show = status == "通过"
				2:  # Fail
					should_show = status == "失败"

			test_item.visible = should_show
			if should_show:
				has_visible_children = true

		# Show category only if it has visible children
		category_item.visible = has_visible_children


func _on_tree_item_activated() -> void:
	var item: TreeItem = summary_tree.get_selected()
	if not item:
		return

	# Get the parent to check if this is a category or test item
	var parent: TreeItem = item.get_parent()
	if not parent or parent == summary_tree.get_root():
		# This is a root item (category), skip
		return

	# Get metadata index and retrieve test data
	var metadata: Variant = item.get_metadata(0)
	if metadata == null:
		return

	var index := metadata as int
	if index < 0 or index >= test_results.size():
		return

	var test_data := test_results[index]

	# Create and show popup window
	_show_test_detail_popup(test_data)


func _show_test_detail_popup(test_data: Dictionary) -> void:
	# Create AcceptDialog-based popup
	var dialog := AcceptDialog.new()
	dialog.title = "测试详情"
	dialog.min_size = Vector2(500, 300)

	# Create container for content
	var container := VBoxContainer.new()
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 10)

	# Create labels for each field
	var name_label := Label.new()
	name_label.text = "测试名称: " + test_data.get("name", "未知")
	name_label.add_theme_font_size_override("font_size", 14)

	var status_container := HBoxContainer.new()
	var status_prefix_label := Label.new()
	status_prefix_label.text = "状态: "
	var status_label := Label.new()
	status_label.text = "通过" if test_data.get("status") == "passed" else "失败"
	status_label.add_theme_color_override("font_color", Color.GREEN if test_data.get("status") == "passed" else Color.RED)
	status_container.add_child(status_prefix_label)
	status_container.add_child(status_label)

	var category_label := Label.new()
	category_label.text = "分类: " + test_data.get("category", "未分类")

	var duration_ms := test_data.get("duration", 0) as int
	var duration_label := Label.new()
	if duration_ms >= 1000:
		duration_label.text = "耗时: %.2fs" % (duration_ms / 1000.0)
	else:
		duration_label.text = "耗时: %dms" % duration_ms

	var message_prefix_label := Label.new()
	message_prefix_label.text = "消息内容:"
	message_prefix_label.add_theme_font_size_override("font_size", 13)

	var message_label := Label.new()
	message_label.text = test_data.get("message", "无消息")
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size = Vector2(0, 100)

	# Add all children to container
	container.add_child(name_label)
	container.add_child(status_container)
	container.add_child(category_label)
	container.add_child(duration_label)
	container.add_child(HSeparator.new())
	container.add_child(message_prefix_label)
	container.add_child(message_label)

	# Add container to dialog
	dialog.add_child(container)
	add_child(dialog)

	# Show dialog centered
	dialog.popup_centered()

	# Clean up dialog when closed (delay to allow animation)
	dialog.close_requested.connect(func():
		dialog.queue_free()
	)


#endregion
