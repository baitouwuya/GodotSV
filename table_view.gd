class_name TableView
extends Control

## 虚拟滚动表格视图，仅渲染可见行以优化性能
## 支持表头、行号、单元格渲染和列宽调整

#region 信号 Signals
signal cell_selected(row: int, column: int)
signal cell_double_clicked(row: int, column: int)
signal column_width_changed(column: int, width: int)
signal row_requested(operation: String, row: int)
signal row_reordered(from_index: int, to_index: int)
signal column_requested(operation: String, column: int)
signal column_settings_requested(column: int)
signal fields_settings_requested()
#endregion

#region 常量 Constants
const DEFAULT_CELL_HEIGHT: int = 30
const DEFAULT_HEADER_HEIGHT: int = 35
const DEFAULT_LINE_NUMBER_WIDTH: int = 64
const MIN_COLUMN_WIDTH: int = 50
const MAX_COLUMN_WIDTH: int = 500
const SCROLLBAR_THICKNESS: int = 20

const TEXT_PADDING_X: float = 5.0
const TEXT_PADDING_Y: float = 3.0

const COLOR_HEADER: Color = Color(0.2, 0.2, 0.2, 1.0)
const COLOR_HEADER_BORDER: Color = Color(0.4, 0.4, 0.4, 1.0)
const COLOR_LINE_NUMBER: Color = Color(0.15, 0.15, 0.15, 1.0)
const COLOR_LINE_NUMBER_BORDER: Color = Color(0.3, 0.3, 0.3, 1.0)
const COLOR_CELL_SELECTED: Color = Color(0.3, 0.5, 0.8, 0.5)
const COLOR_CELL_HOVER: Color = Color(0.3, 0.3, 0.3, 0.3)
const COLOR_CELL_ERROR: Color = Color(1.0, 0.2, 0.2, 0.6)
const COLOR_CELL_WARNING: Color = Color(1.0, 0.8, 0.2, 0.6)
const COLOR_CELL_INFO: Color = Color(0.2, 0.6, 1.0, 0.6)
const COLOR_SELECTION: Color = Color(0.3, 0.5, 0.8, 0.3)
#endregion

## 上下文菜单操作枚举
enum ContextMenuAction {
	INSERT_ROW_ABOVE,
	INSERT_ROW_BELOW,
	DELETE_ROW,
	MOVE_ROW_UP,
	MOVE_ROW_DOWN,
	COLUMN_SETTINGS
}

## 单元格文本溢出显示方式
enum TextOverflowMode {
	CLIP,
	ELLIPSIS,
	WRAP
}

#region 导出变量 Export Variables
## 是否显示行号
@export var show_line_numbers: bool = true

## 是否启用虚拟滚动
@export var enable_virtual_scrolling: bool = true

## 单元格高度
@export var cell_height: int = DEFAULT_CELL_HEIGHT

## 表头高度
@export var header_height: int = DEFAULT_HEADER_HEIGHT

## 单元格文本溢出显示方式
@export var text_overflow_mode: int = TextOverflowMode.ELLIPSIS

## 换行时自动调整行高（行高将随内容换行而变化）
@export var wrap_auto_row_height: bool = true

## 换行最大行数（用于限制自动行高，超过将以省略号结尾）
@export var wrap_max_lines: int = 6
#endregion

#region 公共变量 Public Variables
## 数据模型
var data_model: GDSVDataModel

## 状态管理器
var state_manager: GDSVStateManager

## Schema 管理器
var schema_manager: SchemaManager

## 验证管理器
var validation_manager: ValidationManager
#endregion

#region 私有变量 Private Variables
## 滚动容器
var _scroll_container: ScrollContainer

## 表头容器
var _header_container: Control

## 行号容器
var _line_number_container: Control

## 单元格容器
var _cell_container: Control

## 左上角“字段设置”按钮（行号与表头交界处）
var _corner_fields_button: Button

## 行尾添加按钮（位于最后一行之后）
var _add_row_button: Button

## 滚动条
var _v_scroll_bar: VScrollBar
var _h_scroll_bar: HScrollBar

## 当前选中单元格
var _selected_cell: Vector2i = Vector2i(-1, -1)

## 悬停单元格
var _hover_cell: Vector2i = Vector2i(-1, -1)

## 正在调整列宽
var _resizing_column: int = -1

## 调整列宽起始位置
var _resize_start_pos: float = 0.0

## 调整列宽起始宽度
var _resize_start_width: int = 0

## 编辑器控件
var _cell_editor: LineEdit
var _is_editing: bool = false

## 编辑的单元格坐标
var _editing_cell: Vector2i = Vector2i(-1, -1)

## 自动去除空格
var _auto_trim_whitespace: bool = true

## 智能编辑器控件
var _smart_editor: Control

## 当前编辑器类型
var _current_editor_type: String = "LineEdit"
var _spinbox_is_int: bool = false

## 是否启用双击进入单元格编辑（暂时关闭：统一使用 CSVEditorPanel 的输入区编辑）
@export var enable_double_click_editing: bool = false

## 选区管理
var _selection_start: Vector2i = Vector2i(-1, -1)
var _selection_end: Vector2i = Vector2i(-1, -1)
var _has_selection: bool = false

## 多选单元格列表
var _selected_cells: Array[Vector2i] = []

## 右键菜单
var _context_menu: PopupMenu

## 拖拽状态
var _is_dragging: bool = false
var _drag_target: Vector2i = Vector2i(-1, -1)
var _drag_source: Vector2i = Vector2i(-1, -1)

var _row_layout_dirty: bool = true
var _row_heights: PackedFloat32Array = PackedFloat32Array()
var _row_tops: PackedFloat32Array = PackedFloat32Array()

## 可见行范围
var _visible_row_start: int = 0
var _visible_row_end: int = 0

## 列宽数组
var _column_widths: PackedInt32Array

## 滚动偏移
var _scroll_offset: Vector2 = Vector2.ZERO

## 图片缓存（避免每帧反复加载资源）
var _image_cache: Dictionary = {}
#endregion

#region 生命周期方法 Lifecycle Methods
func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	_build_ui()
	_initialize_context_menu()
	_connect_signals()
	_call_deferred_refresh_after_layout()
	resized.connect(_call_deferred_refresh_after_layout)


func _process(delta: float) -> void:
	pass


func _exit_tree() -> void:
	_cleanup_ui()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_call_deferred_refresh_after_layout()


func _call_deferred_refresh_after_layout() -> void:
	# VBoxContainer/ScrollContainer 的布局更新发生在帧末尾。
	# 直接在 RESIZED 通知里读取 `_scroll_container.size` 往往会得到过小值，
	# 从而导致“只能显示两行/三行、滚动条消失”。
	call_deferred("_refresh_after_layout")


func _refresh_after_layout() -> void:
	if not is_inside_tree():
		return
	_update_scroll_ranges()
	_update_visible_rows()
	_update_corner_fields_button_layout()
	_update_add_row_button_layout()
#endregion

#region 初始化功能 Initialization Features
func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	clip_contents = true

	# 创建主容器
	var main_container := VBoxContainer.new()
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(main_container)

	# 创建表头容器
	_header_container = _create_header_container()
	main_container.add_child(_header_container)

	# 创建滚动容器
	_scroll_container = ScrollContainer.new()
	_scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	main_container.add_child(_scroll_container)

	# 创建滚动容器内的内容容器
	var scroll_content := Control.new()
	scroll_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll_content.custom_minimum_size = Vector2(0, 0)
	scroll_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll_container.add_child(scroll_content)

	# 创建行号容器
	_line_number_container = _create_line_number_container()
	scroll_content.add_child(_line_number_container)

	# 创建单元格容器
	_cell_container = Control.new()
	_cell_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cell_container.mouse_default_cursor_shape = Control.CURSOR_ARROW
	scroll_content.add_child(_cell_container)

	# 让 TableView 自己接收输入，避免子控件坐标系导致命中偏移
	_header_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_scroll_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line_number_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cell_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 创建垂直滚动条
	_v_scroll_bar = VScrollBar.new()
	_v_scroll_bar.custom_minimum_size = Vector2(SCROLLBAR_THICKNESS, 0)
	_v_scroll_bar.step = 1.0
	_v_scroll_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_v_scroll_bar.z_as_relative = false
	_v_scroll_bar.z_index = 100
	add_child(_v_scroll_bar)

	# 创建水平滚动条
	_h_scroll_bar = HScrollBar.new()
	_h_scroll_bar.custom_minimum_size = Vector2(0, SCROLLBAR_THICKNESS)
	_h_scroll_bar.step = 1.0
	_h_scroll_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	_h_scroll_bar.z_as_relative = false
	_h_scroll_bar.z_index = 100
	add_child(_h_scroll_bar)

	_corner_fields_button = Button.new()
	_corner_fields_button.text = "字段"
	_corner_fields_button.tooltip_text = "字段设置"
	_corner_fields_button.focus_mode = Control.FOCUS_NONE
	_corner_fields_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_corner_fields_button.z_as_relative = false
	_corner_fields_button.z_index = 101
	var settings_icon: Texture2D = null
	if has_theme_icon("EditorSettings", "EditorIcons"):
		settings_icon = get_theme_icon("EditorSettings", "EditorIcons")
	elif has_theme_icon("Tools", "EditorIcons"):
		settings_icon = get_theme_icon("Tools", "EditorIcons")
	elif has_theme_icon("Settings", "EditorIcons"):
		settings_icon = get_theme_icon("Settings", "EditorIcons")
	if settings_icon:
		_corner_fields_button.icon = settings_icon
	_corner_fields_button.pressed.connect(func() -> void:
		fields_settings_requested.emit()
	)
	add_child(_corner_fields_button)

	_add_row_button = Button.new()
	_add_row_button.text = "+"
	_add_row_button.tooltip_text = "追加行"
	_add_row_button.focus_mode = Control.FOCUS_NONE
	_add_row_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_add_row_button.z_as_relative = false
	_add_row_button.z_index = 101
	_add_row_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var line_bg := StyleBoxFlat.new()
	line_bg.bg_color = Color(COLOR_LINE_NUMBER.r, COLOR_LINE_NUMBER.g, COLOR_LINE_NUMBER.b, 0.6)
	_add_row_button.add_theme_stylebox_override("normal", line_bg)
	var line_bg_hover := line_bg.duplicate()
	(line_bg_hover as StyleBoxFlat).bg_color.a = 0.75
	(line_bg_hover as StyleBoxFlat).border_width_left = 1
	(line_bg_hover as StyleBoxFlat).border_width_top = 1
	(line_bg_hover as StyleBoxFlat).border_width_right = 1
	(line_bg_hover as StyleBoxFlat).border_width_bottom = 1
	(line_bg_hover as StyleBoxFlat).border_color = COLOR_LINE_NUMBER_BORDER
	_add_row_button.add_theme_stylebox_override("hover", line_bg_hover)
	var line_bg_pressed := line_bg.duplicate()
	(line_bg_pressed as StyleBoxFlat).bg_color.a = 0.9
	(line_bg_pressed as StyleBoxFlat).border_width_left = 1
	(line_bg_pressed as StyleBoxFlat).border_width_top = 1
	(line_bg_pressed as StyleBoxFlat).border_width_right = 1
	(line_bg_pressed as StyleBoxFlat).border_width_bottom = 1
	(line_bg_pressed as StyleBoxFlat).border_color = COLOR_LINE_NUMBER_BORDER
	_add_row_button.add_theme_stylebox_override("pressed", line_bg_pressed)
	if has_theme_icon("Add", "EditorIcons"):
		_add_row_button.icon = get_theme_icon("Add", "EditorIcons")
		_add_row_button.text = ""
	_add_row_button.pressed.connect(func() -> void:
		var row_count := data_model.get_row_count() if data_model else 0
		row_requested.emit("insert_below", row_count - 1)
	)

	add_child(_add_row_button)


	_update_scrollbar_layout()
	_update_corner_fields_button_layout()
	_update_add_row_button_layout()


func _update_corner_fields_button_layout() -> void:
	if not _corner_fields_button:
		return

	var w := _get_line_number_width()
	if _line_number_container:
		_line_number_container.custom_minimum_size = Vector2(w, _line_number_container.custom_minimum_size.y)

	var should_show := show_line_numbers and header_height > 0
	_corner_fields_button.visible = should_show
	if not should_show:
		return

	_corner_fields_button.position = Vector2(0, 0)
	_corner_fields_button.size = Vector2(w, header_height)


func _update_add_row_button_layout() -> void:
	if not _add_row_button:
		return
	if not show_line_numbers:
		_add_row_button.visible = false
		return

	var row_count := data_model.get_row_count() if data_model else 0
	var total_height := _get_total_rows_height(row_count)
	var button_height := float(cell_height)
	var w := float(_get_line_number_width())
	_add_row_button.visible = true
	_add_row_button.size = Vector2(w, button_height)
	_add_row_button.position = Vector2(0, header_height + total_height - _scroll_offset.y)


func _connect_signals() -> void:
	_v_scroll_bar.value_changed.connect(_on_v_scroll_changed)
	_h_scroll_bar.value_changed.connect(_on_h_scroll_changed)

	# 连接单元格选择和双击信号
	cell_selected.connect(_on_cell_selected)
	cell_double_clicked.connect(_on_cell_double_clicked)
#endregion

#region UI构建功能 UI Building Features
## 创建表头容器
func _create_header_container() -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(0, header_height)
	return container


## 创建行号容器
func _create_line_number_container() -> Control:
	var container := Control.new()
	container.custom_minimum_size = Vector2(_get_line_number_width(), 0)
	return container


func _get_line_number_width() -> int:
	if not show_line_numbers:
		return 0

	var font := get_theme_font("font", "Label")
	if not font:
		return DEFAULT_LINE_NUMBER_WIDTH

	var font_size := get_theme_font_size("font_size", "Label")
	var row_count := data_model.get_row_count() if data_model else 0
	var last_index := maxi(0, row_count - 1)
	var text := str(last_index)
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var desired := int(ceil(text_size.x + TEXT_PADDING_X * 2.0 + 10.0))
	return maxi(DEFAULT_LINE_NUMBER_WIDTH, desired)
#endregion

#region 渲染功能 Rendering Features
func _should_use_auto_row_height() -> bool:
	return wrap_auto_row_height and text_overflow_mode == TextOverflowMode.WRAP and data_model != null


func _invalidate_row_layout() -> void:
	_row_layout_dirty = true


func _ensure_row_layout(force: bool = false) -> void:
	if not _should_use_auto_row_height():
		_row_layout_dirty = false
		_row_heights = PackedFloat32Array()
		_row_tops = PackedFloat32Array()
		return

	if not _row_layout_dirty:
		return

	# 列宽拖拽时避免每帧全量重算（在鼠标释放时强制刷新）
	if _resizing_column >= 0 and not force:
		return

	_rebuild_row_layout()


func _rebuild_row_layout() -> void:
	var row_count := data_model.get_row_count() if data_model else 0
	var col_count := data_model.get_column_count() if data_model else 0

	_row_heights.resize(row_count)
	_row_tops.resize(row_count + 1)
	_row_tops[0] = 0.0

	var font := get_theme_font("font", "Label")
	var font_size := get_theme_font_size("font_size", "Label")
	var line_height := _get_font_height(font, font_size)
	var min_row_height := float(cell_height)
	var max_lines := maxi(1, wrap_max_lines)

	var current_top := 0.0
	for row in range(row_count):
		var needed_lines := 1

		for col in range(col_count):
			if needed_lines >= max_lines:
				break

			var value := str(data_model.get_cell_value(row, col))
			if value.is_empty():
				continue

			var max_width := maxf(0.0, float(_get_column_width(col)) - TEXT_PADDING_X * 2.0)
			if max_width <= 1.0:
				continue

			# 快速路径：一行能放下就不进行换行计算
			if _measure_text_width(font, font_size, value) <= max_width:
				continue

			var lines := _wrap_text(font, font_size, value, max_width, max_lines)
			needed_lines = max(needed_lines, lines.size())

		var row_height := maxf(min_row_height, TEXT_PADDING_Y * 2.0 + float(needed_lines) * line_height)
		_row_heights[row] = row_height
		current_top += row_height
		_row_tops[row + 1] = current_top

	_row_layout_dirty = false


func _get_total_rows_height(row_count: int) -> float:
	if not _should_use_auto_row_height():
		return float(row_count * cell_height)
	if _row_tops.size() != row_count + 1:
		return float(row_count * cell_height)
	return float(_row_tops[row_count])


func _get_row_top(row: int) -> float:
	if not _should_use_auto_row_height():
		return float(row * cell_height)
	if _row_tops.size() > row:
		return float(_row_tops[row])
	return float(row * cell_height)


func _get_row_height(row: int) -> float:
	if not _should_use_auto_row_height():
		return float(cell_height)
	if _row_heights.size() > row:
		return float(_row_heights[row])
	return float(cell_height)


func _get_row_from_y(y: float) -> int:
	var row_count := data_model.get_row_count() if data_model else 0
	if row_count <= 0:
		return 0
	if y <= 0.0:
		return 0

	if not _should_use_auto_row_height() or _row_tops.size() != row_count + 1:
		return clampi(int(floor(y / float(cell_height))), 0, row_count)

	if y >= float(_row_tops[row_count]):
		return row_count

	var low := 0
	var high := row_count
	while low < high:
		var mid := int((low + high) / 2)
		if float(_row_tops[mid + 1]) <= y:
			low = mid + 1
		else:
			high = mid
	return low

## 更新可见行
func _update_visible_rows() -> void:
	if not enable_virtual_scrolling:
		return

	_ensure_row_layout()

	var container_height := maxf(0.0, size.y - float(header_height) - (float(SCROLLBAR_THICKNESS) if _h_scroll_bar and _h_scroll_bar.visible else 0.0))
	var row_count := data_model.get_row_count() if data_model else 0

	_visible_row_start = _get_row_from_y(_scroll_offset.y)
	_visible_row_end = min(_get_row_from_y(_scroll_offset.y + container_height) + 2, row_count)

	_request_redraw()


## 绘制
func _draw() -> void:
	_ensure_row_layout()

	# 背景（保证表格绘制在背景之上）
	var panel_style := get_theme_stylebox("panel", "Panel")
	draw_style_box(panel_style, Rect2(Vector2.ZERO, size))

	_draw_header()
	_draw_cells()
	_draw_selection()
	_draw_hover()
	_draw_line_numbers()


## 绘制表头
func _draw_header() -> void:
	var header_count := data_model.get_column_count() if data_model else 0
	if header_count == 0:
		return

	var fixed_x_offset: float = float(_get_line_number_width())
	var x_offset: float = fixed_x_offset - _scroll_offset.x

	# 绘制表头背景
	draw_rect(Rect2(0, 0, size.x, header_height), COLOR_HEADER)

	# 绘制列表头
	var header := data_model.get_header() if data_model else PackedStringArray()
	for i in range(header_count):
		var width := _get_column_width(i)
		draw_rect(Rect2(x_offset, 0, width, header_height), COLOR_HEADER)
		draw_rect(Rect2(x_offset + width - 1, 0, 1, header_height), COLOR_HEADER_BORDER)

		# 绘制列标题文本
		var text := header[i] if i < header.size() else ""
		var font := get_theme_font("font", "Label")
		var font_size := get_theme_font_size("font_size", "Label")
		_draw_text_in_rect(font, font_size, Rect2(x_offset, 0, width, header_height), text, TextOverflowMode.ELLIPSIS)

		x_offset += width

	# 绘制行号列表头（放到最后，避免水平滚动时列头覆盖行号区域）
	if show_line_numbers:
		draw_rect(Rect2(0, 0, fixed_x_offset, header_height), COLOR_LINE_NUMBER)
		draw_rect(Rect2(fixed_x_offset - 1, 0, 1, header_height), COLOR_LINE_NUMBER_BORDER)


## 绘制行号
func _draw_line_numbers() -> void:
	if not show_line_numbers:
		return

	var row_count := data_model.get_row_count() if data_model else 0
	var w := float(_get_line_number_width())

	for row in range(_visible_row_start, _visible_row_end):
		var row_top := _get_row_top(row)
		var row_height := _get_row_height(row)
		var y_pos := header_height + row_top - _scroll_offset.y
		var rect := Rect2(0, y_pos, w, row_height)

		var bg_color := COLOR_LINE_NUMBER
		if _is_dragging:
			if row == _drag_source.x:
				bg_color = COLOR_CELL_SELECTED
		draw_rect(rect, bg_color)
		draw_rect(Rect2(w - 1, y_pos, 1, row_height), COLOR_LINE_NUMBER_BORDER)

		var text := str(row)
		var font := get_theme_font("font", "Label")
		var font_size := get_theme_font_size("font_size", "Label")
		_draw_text_in_rect(font, font_size, Rect2(0, y_pos, w, row_height), text, TextOverflowMode.CLIP)


## 绘制单元格
func _draw_cells() -> void:
	var row_count := data_model.get_row_count() if data_model else 0
	var col_count := data_model.get_column_count() if data_model else 0

	if row_count == 0 or col_count == 0:
		return

	var base_x_offset: float = float(_get_line_number_width()) - _scroll_offset.x

	for row in range(_visible_row_start, _visible_row_end):
		var row_top := _get_row_top(row)
		var row_height := _get_row_height(row)
		var y_pos := header_height + row_top - _scroll_offset.y
		var current_x := base_x_offset

		for col in range(col_count):
			var width := _get_column_width(col)
			var rect := Rect2(current_x, y_pos, width, row_height)

			# 检查单元格是否被选中
			var cell: Vector2i = Vector2i(row, col)
			if _is_cell_selected(cell):
				draw_rect(rect, COLOR_SELECTION)

			# 绘制单元格边框
			draw_rect(Rect2(current_x, y_pos, width - 1, row_height - 1), Color(0.4, 0.4, 0.4, 0.3), false, 1.0)

			# 检查是否有错误
			var error: Dictionary = _get_cell_error(row, col)
			if not error.is_empty():
				var severity: int = int(error.get("severity", ValidationManager.ErrorSeverity.ERROR))
				var error_color := _get_error_color(severity)
				draw_rect(rect, error_color)

			# 获取单元格值
			var cell_value: String = str(data_model.get_cell_value(row, col))

			# 优先尝试按图片显示（Texture2D / resource 里指向图片资源）
			var type_def := _get_type_definition_for_column(col)
			if _try_draw_image_cell(type_def, rect, cell_value):
				current_x += width
				continue

			# 绘制单元格文本
			var font := get_theme_font("font", "Label")
			var font_size := get_theme_font_size("font_size", "Label")
			_draw_text_in_rect(font, font_size, rect, cell_value, text_overflow_mode)

			current_x += width


## 绘制选中
func _draw_selection() -> void:
	if _selected_cell.x < 0 or _selected_cell.y < 0:
		return

	var row := _selected_cell.x
	var col := _selected_cell.y

	if row < _visible_row_start or row >= _visible_row_end:
		return

	var x_offset: float = float(_get_line_number_width()) - _scroll_offset.x
	for c in range(col):
		x_offset += _get_column_width(c)

	var row_top := _get_row_top(row)
	var row_height := _get_row_height(row)
	var y_pos := header_height + row_top - _scroll_offset.y
	var width := _get_column_width(col)

	draw_rect(Rect2(x_offset, y_pos, width, row_height), COLOR_CELL_SELECTED)


## 绘制悬停
func _draw_hover() -> void:
	if _hover_cell.x < 0 or _hover_cell.y < 0:
		return

	var row := _hover_cell.x
	var col := _hover_cell.y

	if row < _visible_row_start or row >= _visible_row_end:
		return

	var x_offset: float = float(_get_line_number_width()) - _scroll_offset.x
	for c in range(col):
		x_offset += _get_column_width(c)

	var row_top := _get_row_top(row)
	var row_height := _get_row_height(row)
	var y_pos := header_height + row_top - _scroll_offset.y
	var width := _get_column_width(col)

	draw_rect(Rect2(x_offset, y_pos, width, row_height), COLOR_CELL_HOVER)
#endregion

#region 事件处理功能 Event Handling Features
## 处理单元格容器输入
func _on_cell_container_input(event: InputEvent) -> void:
	if not event is InputEventMouse:
		return

	var mouse_event := event as InputEventMouse
	var mouse_pos := mouse_event.position

	# 转换为单元格坐标
	var cell_pos := _get_cell_from_position(mouse_pos)

	if cell_pos.x >= 0 and cell_pos.y >= 0:
		_hover_cell = cell_pos
		_request_redraw()

	if mouse_event is InputEventMouseButton:
		var button_event := mouse_event as InputEventMouseButton

		if button_event.pressed:
			if button_event.button_index == MOUSE_BUTTON_LEFT:
				_selected_cell = cell_pos
				if data_model:
					data_model.select_cell(cell_pos.x, cell_pos.y)
				cell_selected.emit(cell_pos.x, cell_pos.y)
				_request_redraw()

			elif button_event.button_index == MOUSE_BUTTON_LEFT and button_event.double_click:
				cell_double_clicked.emit(cell_pos.x, cell_pos.y)


## 处理表头容器输入
func _on_header_container_input(event: InputEvent) -> void:
	if not event is InputEventMouse:
		return

	var mouse_event := event as InputEventMouse
	var mouse_pos := mouse_event.position

	if mouse_event is InputEventMouseButton:
		var button_event := mouse_event as InputEventMouseButton

		if button_event.pressed and button_event.button_index == MOUSE_BUTTON_LEFT:
			# 检查是否在列边界上
			var col := _get_column_from_position(mouse_pos)
			if col >= 0:
				var col_edge := _get_column_edge_position(col)
				if abs(mouse_pos.x - col_edge) < 5:
					_resizing_column = col
					_resize_start_pos = mouse_pos.x
					_resize_start_width = _get_column_width(col)


## 处理行号容器输入
func _on_line_number_container_input(event: InputEvent) -> void:
	# TODO: 实现行号列选择功能
	pass


## 处理垂直滚动变化
func _on_v_scroll_changed(value: float) -> void:
	var max_scroll_y := maxf(0.0, _v_scroll_bar.max_value - _v_scroll_bar.page) if _v_scroll_bar else 0.0
	_scroll_offset.y = clampf(value, 0.0, max_scroll_y)
	_update_visible_rows()
	_update_add_row_button_layout()
	_request_redraw()


## 处理水平滚动变化
func _on_h_scroll_changed(value: float) -> void:
	var max_scroll_x := maxf(0.0, _h_scroll_bar.max_value - _h_scroll_bar.page) if _h_scroll_bar else 0.0
	_scroll_offset.x = clampf(value, 0.0, max_scroll_x)
	_request_redraw()


## 处理GUI输入
func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouse and not event is InputEventKey:
		return

	# 处理鼠标事件
	if event is InputEventMouse:
		var mouse_event := event as InputEventMouse
		var is_in_header := mouse_event.position.y <= header_height
		var is_in_cells := mouse_event.position.y >= header_height

		if mouse_event is InputEventMouseMotion:
			if _is_dragging:
				_update_drag_target_from_position(mouse_event.position)
				_request_redraw()
				return

			if _resizing_column < 0:
				if is_in_cells and not _is_editing:
					var hover_cell := _get_cell_from_position(mouse_event.position)
					if hover_cell != _hover_cell:
						_hover_cell = hover_cell
						_request_redraw()
				elif _hover_cell.x >= 0 or _hover_cell.y >= 0:
					_hover_cell = Vector2i(-1, -1)
					_request_redraw()

			if _resizing_column >= 0:
				var delta := mouse_event.position.x - _resize_start_pos
				var new_width := clamp(_resize_start_width + int(delta), MIN_COLUMN_WIDTH, MAX_COLUMN_WIDTH)
				_set_column_width(_resizing_column, new_width)
				_resize_start_pos = mouse_event.position.x
				_resize_start_width = new_width
				_update_scroll_ranges()
				_update_visible_rows()
				_request_redraw()

		if mouse_event is InputEventMouseButton:
			var button_event := mouse_event as InputEventMouseButton

			if button_event.pressed:
				if not _is_editing:
					grab_focus()

				match button_event.button_index:
					MOUSE_BUTTON_LEFT:
						if is_in_header:
							var col := _get_column_from_position(button_event.position)
							if col >= 0:
								var col_edge := _get_column_edge_position(col)
								if abs(button_event.position.x - col_edge) < 5.0:
									_resizing_column = col
									_resize_start_pos = button_event.position.x
									_resize_start_width = _get_column_width(col)
									return
								if not _is_editing:
									_select_column(col)
									return

						if is_in_cells:
							if _is_in_line_number_area(button_event.position) and not _is_editing:
								_start_row_drag_from_position(button_event.position)
								return

							var cell := _get_cell_from_position(button_event.position)
							if cell.x >= 0 and cell.y >= 0:
								_handle_left_click(cell, button_event)
								if button_event.double_click:
									cell_double_clicked.emit(cell.x, cell.y)
					MOUSE_BUTTON_RIGHT:
						if is_in_cells:
							var cell := _get_cell_from_position(button_event.position)
							if cell.x >= 0 and cell.y >= 0:
								_show_context_menu(cell, button_event)

			if not button_event.pressed:
				if button_event.button_index == MOUSE_BUTTON_LEFT:
					if _is_dragging:
						_finish_row_drag()
						return

					if _resizing_column >= 0:
						column_width_changed.emit(_resizing_column, _get_column_width(_resizing_column))
						_resizing_column = -1
						_invalidate_row_layout()
						if _should_use_auto_row_height():
							refresh()

	# 处理键盘事件
	if event is InputEventKey:
		var key_event := event as InputEventKey

		if key_event.pressed and _is_editing:
			match key_event.keycode:
				KEY_ENTER:
					_finish_editing()
					_move_to_next_row()
					get_viewport().set_input_as_handled()

				KEY_KP_ENTER:
					_finish_editing()
					_move_to_next_row()
					get_viewport().set_input_as_handled()

				KEY_TAB:
					_finish_editing()
					if key_event.shift_pressed:
						_move_to_previous_column()
					else:
						_move_to_next_column()
					get_viewport().set_input_as_handled()

				KEY_ESCAPE:
					_cancel_editing()
					get_viewport().set_input_as_handled()
		elif key_event.pressed and not _is_editing:
			match key_event.keycode:
				KEY_DELETE:
					if has_selection():
						batch_delete_selected_cells()
						get_viewport().set_input_as_handled()

#region 工具方法 Utility Methods
## 从位置获取单元格坐标
func _get_cell_from_position(pos: Vector2) -> Vector2i:
	if pos.y < header_height:
		return Vector2i(-1, -1)

	var row_count := data_model.get_row_count() if data_model else 0
	var col_count := data_model.get_column_count() if data_model else 0
	if row_count <= 0 or col_count <= 0:
		return Vector2i(-1, -1)

	var adjusted_x := pos.x + _scroll_offset.x
	var adjusted_y := pos.y - header_height + _scroll_offset.y
	_ensure_row_layout()
	var row := _get_row_from_y(adjusted_y)
	if row < 0 or row >= row_count:
		return Vector2i(-1, -1)

	var x_offset: float = float(_get_line_number_width())

	for col in range(col_count):
		var width := _get_column_width(col)
		if adjusted_x >= x_offset and adjusted_x < x_offset + width:
			return Vector2i(row, col)
		x_offset += width

	return Vector2i(-1, -1)


## 从位置获取列索引
func _get_column_from_position(pos: Vector2) -> int:
	var col_count := data_model.get_column_count() if data_model else 0
	if col_count <= 0:
		return -1

	var adjusted_x := pos.x + _scroll_offset.x
	var x_offset: float = float(_get_line_number_width())

	for col in range(col_count):
		var width := _get_column_width(col)
		if adjusted_x >= x_offset and adjusted_x < x_offset + width:
			return col
		x_offset += width

	return -1


## 获取列边缘位置
func _get_column_edge_position(col: int) -> float:
	var x_offset: float = float(_get_line_number_width()) - _scroll_offset.x

	for c in range(col + 1):
		x_offset += _get_column_width(c)

	return x_offset


func _is_in_line_number_area(pos: Vector2) -> bool:
	if not show_line_numbers:
		return false
	return pos.x >= 0.0 and pos.x <= float(_get_line_number_width())


func _start_row_drag_from_position(pos: Vector2) -> void:
	if not data_model:
		return
	if state_manager and state_manager.is_file_readonly():
		return
	var row := _get_row_from_y(pos.y - header_height + _scroll_offset.y)
	if row < 0 or row >= data_model.get_row_count():
		return
	_is_dragging = true
	_drag_source = Vector2i(row, 0)
	_drag_target = Vector2i(row, 0)
	_select_row(row)
	_request_redraw()


func _update_drag_target_from_position(pos: Vector2) -> void:
	if not data_model:
		return
	var row_count := data_model.get_row_count()
	if row_count <= 0:
		return
	var row := _get_row_from_y(pos.y - header_height + _scroll_offset.y)
	row = clampi(row, 0, row_count - 1)
	_drag_target = Vector2i(row, 0)
	_select_row(row)


func _finish_row_drag() -> void:
	if not _is_dragging:
		return
	_is_dragging = false
	if _drag_source.x >= 0 and _drag_target.x >= 0 and _drag_source.x != _drag_target.x:
		row_reordered.emit(_drag_source.x, _drag_target.x)
	_drag_source = Vector2i(-1, -1)
	_drag_target = Vector2i(-1, -1)
	_request_redraw()


## 获取列宽
func _get_column_width(col: int) -> int:
	if col < _column_widths.size():
		return _column_widths[col]
	return 100


## 设置列宽
func _set_column_width(col: int, width: int) -> void:
	while col >= _column_widths.size():
		_column_widths.append(100)

	_column_widths[col] = width

	if state_manager:
		state_manager.set_column_width(col, width)


## 请求重绘
func _request_redraw() -> void:
	queue_redraw()


func _try_draw_image_cell(type_def: Dictionary, rect: Rect2, cell_value: String) -> bool:
	var t := str(type_def.get("type", "")).strip_edges().to_lower()
	if t.is_empty():
		return false

	# 只对“资源类/贴图类”尝试走图片渲染
	# - 支持 schema 的 "Texture2D" / "texture2d"
	# - 支持通用 "resource" 但内容指向图片
	if t != "texture2d" and t != "texture" and t != "resource" and not t.begins_with("resource"):
		return false

	var tex := _get_texture_from_cell_value(cell_value)
	if not tex:
		return false

	_draw_texture_fit_in_rect(tex, rect)
	return true


func _get_texture_from_cell_value(cell_value: String) -> Texture2D:
	var key := str(cell_value).strip_edges()
	if key.is_empty():
		return null

	# 缓存
	if _image_cache.has(key):
		return _image_cache[key] as Texture2D

	var resolved := key
	if resolved.begins_with("uid://"):
		var uid_id: int = ResourceUID.text_to_id(resolved)
		if uid_id != 0:
			var uid_path := ResourceUID.get_id_path(uid_id)
			if not uid_path.is_empty():
				resolved = uid_path

	if not resolved.begins_with("res://"):
		_image_cache[key] = null
		return null

	if not ResourceLoader.exists(resolved):
		_image_cache[key] = null
		return null

	var res := ResourceLoader.load(resolved)
	var tex: Texture2D = null
	if res is Texture2D:
		tex = res as Texture2D
	elif res is ImageTexture:
		tex = res as Texture2D
	elif res is AtlasTexture:
		tex = res as Texture2D
	elif res is CompressedTexture2D:
		tex = res as Texture2D
	else:
		# 兜底：有些资源（如 SpriteFrames、Theme 等）也可能间接包含贴图，这里不做深挖，保持简单。
		tex = null

	_image_cache[key] = tex
	return tex


func _draw_texture_fit_in_rect(tex: Texture2D, rect: Rect2) -> void:
	if not tex:
		return

	var padding := 2.0
	var target := Rect2(
		rect.position + Vector2(padding, padding),
		rect.size - Vector2(padding * 2.0, padding * 2.0)
	)
	if target.size.x <= 1.0 or target.size.y <= 1.0:
		return

	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return

	var scale := minf(target.size.x / tex_size.x, target.size.y / tex_size.y)
	scale = maxf(0.0, scale)
	var draw_size := tex_size * scale
	var draw_pos := target.position + (target.size - draw_size) * 0.5

	draw_texture_rect(tex, Rect2(draw_pos, draw_size), false)


func apply_text_layout_settings(mode: int, auto_row_height: bool, max_lines: int) -> void:
	text_overflow_mode = mode
	wrap_auto_row_height = auto_row_height
	wrap_max_lines = clamp(max_lines, 1, 20)
	_invalidate_row_layout()
	refresh()


func set_text_overflow_mode(mode: int) -> void:
	text_overflow_mode = mode
	_invalidate_row_layout()
	refresh()


func set_wrap_auto_row_height(enabled: bool) -> void:
	wrap_auto_row_height = enabled
	_invalidate_row_layout()
	refresh()


func set_wrap_max_lines(lines: int) -> void:
	wrap_max_lines = clamp(lines, 1, 20)
	_invalidate_row_layout()
	refresh()


func _measure_text_width(font: Font, font_size: int, text: String) -> float:
	if not font:
		return 0.0
	if font.has_method("get_string_size"):
		return (font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size) as Vector2).x
	return float(text.length() * font_size)


func _get_font_height(font: Font, font_size: int) -> float:
	if not font:
		return float(font_size)
	if font.has_method("get_height"):
		return float(font.get_height(font_size))
	return float(font_size)


func _get_font_ascent(font: Font, font_size: int) -> float:
	if not font:
		return float(font_size)
	if font.has_method("get_ascent"):
		return float(font.get_ascent(font_size))
	return float(font_size)


func _fit_text_ellipsis(font: Font, font_size: int, text: String, max_width: float) -> String:
	if text.is_empty():
		return text

	var ellipsis := "..."
	var full_width := _measure_text_width(font, font_size, text)
	if full_width <= max_width:
		return text

	var ellipsis_width := _measure_text_width(font, font_size, ellipsis)
	if max_width <= ellipsis_width:
		return ""

	var available := max_width - ellipsis_width
	var low := 0
	var high := text.length()
	while low < high:
		var mid := int(ceil((low + high) / 2.0))
		var candidate := text.substr(0, mid)
		if _measure_text_width(font, font_size, candidate) <= available:
			low = mid
		else:
			high = mid - 1

	return text.substr(0, low) + ellipsis


func _wrap_text(font: Font, font_size: int, text: String, max_width: float, max_lines: int) -> PackedStringArray:
	var max_lines_clamped := maxi(1, max_lines)
	var lines := PackedStringArray()
	if text.is_empty():
		lines.append("")
		return lines

	var use_words := text.contains(" ")
	var parts: PackedStringArray
	if use_words:
		parts = text.split(" ", false)
	else:
		parts = PackedStringArray()
		for i in range(text.length()):
			parts.append(text.substr(i, 1))

	var current := ""
	var truncated := false
	for part in parts:
		var next := part if current.is_empty() else (current + (" " if use_words else "") + part)
		if _measure_text_width(font, font_size, next) <= max_width or current.is_empty():
			current = next
			continue

		lines.append(current)
		current = part

		if lines.size() >= max_lines_clamped:
			truncated = true
			break

	if lines.size() < max_lines_clamped and not current.is_empty():
		lines.append(current)

	# 超过最大行数或未完全容纳时，将最后一行用省略号截断
	if truncated and not lines.is_empty():
		lines[lines.size() - 1] = _fit_text_ellipsis(font, font_size, lines[lines.size() - 1], max_width)

	return lines


func _draw_text_in_rect(font: Font, font_size: int, rect: Rect2, text: String, mode: int) -> void:
	if not font:
		return

	var padding_x := TEXT_PADDING_X
	var padding_y := TEXT_PADDING_Y

	var max_width := maxf(0.0, rect.size.x - TEXT_PADDING_X * 2.0)
	var max_height := maxf(0.0, rect.size.y - TEXT_PADDING_Y * 2.0)

	var height := _get_font_height(font, font_size)
	var ascent := _get_font_ascent(font, font_size)
	var max_lines := maxi(1, int(floor(max_height / height)))

	var lines := PackedStringArray()
	match mode:
		TextOverflowMode.WRAP:
			lines = _wrap_text(font, font_size, text, max_width, max_lines)
		TextOverflowMode.ELLIPSIS:
			lines.append(_fit_text_ellipsis(font, font_size, text, max_width))
		_:
			lines.append(text)

	for i in range(min(lines.size(), max_lines)):
		var x := rect.position.x + padding_x
		var baseline_y := rect.position.y + padding_y + ascent + float(i) * height
		draw_string(font, Vector2(x, baseline_y), lines[i], HORIZONTAL_ALIGNMENT_LEFT, max_width, font_size)


func _update_scrollbar_layout() -> void:
	if not _v_scroll_bar or not _h_scroll_bar:
		return

	var fixed_width := float(_get_line_number_width())
	var thickness := float(SCROLLBAR_THICKNESS)

	var right_inset := thickness if _v_scroll_bar.visible else 0.0
	var bottom_inset := thickness if _h_scroll_bar.visible else 0.0

	_v_scroll_bar.position = Vector2(size.x - thickness, header_height)
	_v_scroll_bar.size = Vector2(thickness, maxf(0.0, size.y - float(header_height) - bottom_inset))

	_h_scroll_bar.position = Vector2(fixed_width, size.y - thickness)
	_h_scroll_bar.size = Vector2(maxf(0.0, size.x - fixed_width - right_inset), thickness)
	_update_corner_fields_button_layout()
	_update_add_row_button_layout()


## 更新滚动条范围
func _update_scroll_ranges() -> void:
	if not _v_scroll_bar or not _h_scroll_bar:
		return

	_ensure_row_layout()

	var row_count := data_model.get_row_count() if data_model else 0
	var col_count := data_model.get_column_count() if data_model else 0

	var total_height := _get_total_rows_height(row_count)
	var total_width := 0.0
	for col in range(col_count):
		total_width += float(_get_column_width(col))

	var fixed_width := float(_get_line_number_width())
	var thickness := float(SCROLLBAR_THICKNESS)

	var v_visible := _v_scroll_bar.visible
	var h_visible := _h_scroll_bar.visible

	# 迭代两次，解决横/纵滚动条可见性互相影响的问题
	for _i in range(2):
		var visible_height := maxf(0.0, size.y - float(header_height) - (thickness if h_visible else 0.0))
		v_visible = total_height > visible_height

		var visible_width := maxf(0.0, size.x - fixed_width - (thickness if v_visible else 0.0))
		h_visible = total_width > visible_width

	_v_scroll_bar.visible = v_visible
	_h_scroll_bar.visible = h_visible
	_v_scroll_bar.min_value = 0.0
	_h_scroll_bar.min_value = 0.0

	var final_visible_height := maxf(0.0, size.y - float(header_height) - (thickness if h_visible else 0.0))
	_v_scroll_bar.max_value = maxf(0.0, total_height)
	_v_scroll_bar.page = clampf(final_visible_height, 0.0, _v_scroll_bar.max_value)
	if not v_visible:
		_v_scroll_bar.value = 0.0
		_scroll_offset.y = 0.0
	else:
		var max_scroll_y := maxf(0.0, _v_scroll_bar.max_value - _v_scroll_bar.page)
		_scroll_offset.y = clampf(_scroll_offset.y, 0.0, max_scroll_y)
		_v_scroll_bar.value = _scroll_offset.y

	var final_visible_width := maxf(0.0, size.x - fixed_width - (thickness if v_visible else 0.0))
	_h_scroll_bar.max_value = maxf(0.0, total_width)
	_h_scroll_bar.page = clampf(final_visible_width, 0.0, _h_scroll_bar.max_value)
	if not h_visible:
		_h_scroll_bar.value = 0.0
		_scroll_offset.x = 0.0
	else:
		var max_scroll_x := maxf(0.0, _h_scroll_bar.max_value - _h_scroll_bar.page)
		_scroll_offset.x = clampf(_scroll_offset.x, 0.0, max_scroll_x)
		_h_scroll_bar.value = _scroll_offset.x

	_update_scrollbar_layout()


## 清理UI
func _cleanup_ui() -> void:
	# TODO: 清理UI节点
	pass


## 初始化功能 Initialization Features
## 初始化表格视图
func _initialize_table_view() -> void:
	_initialize_context_menu()


## 初始化右键菜单
func _initialize_context_menu() -> void:
	_context_menu = PopupMenu.new()

	# 行操作菜单项
	_context_menu.add_separator("行操作")
	_context_menu.add_item("在上方插入行", ContextMenuAction.INSERT_ROW_ABOVE)
	_context_menu.add_item("在下方插入行", ContextMenuAction.INSERT_ROW_BELOW)
	_context_menu.add_item("删除行", ContextMenuAction.DELETE_ROW)
	_context_menu.add_item("向上移动行", ContextMenuAction.MOVE_ROW_UP)
	_context_menu.add_item("向下移动行", ContextMenuAction.MOVE_ROW_DOWN)

	# 字段设置（不在右键菜单提供列增删/移动）
	_context_menu.add_separator("字段")
	_context_menu.add_item("字段设置...", ContextMenuAction.COLUMN_SETTINGS)

	_context_menu.id_pressed.connect(_on_context_menu_pressed)
	add_child(_context_menu)


## 设置数据模型
func set_data_model(model: GDSVDataModel) -> void:
	data_model = model

	if data_model:
		data_model.data_changed.connect(_on_data_changed)


## 设置状态管理器
func set_state_manager(manager: GDSVStateManager) -> void:
	state_manager = manager


## 设置 Schema 管理器
func set_schema_manager(manager: SchemaManager) -> void:
	schema_manager = manager
	if schema_manager:
		schema_manager.type_definitions_changed.connect(_on_type_definitions_changed)


## 设置验证管理器
func set_validation_manager(manager: ValidationManager) -> void:
	validation_manager = manager
	if validation_manager:
		validation_manager.error_added.connect(_on_error_added)
		validation_manager.error_removed.connect(_on_error_removed)
		validation_manager.errors_cleared.connect(_on_errors_cleared)


## 数据变化回调
func _on_data_changed(change_type: String, details: Dictionary) -> void:
	refresh()


## 单元格选中回调
func _on_cell_selected(row: int, column: int) -> void:
	if _is_editing:
		_finish_editing()


## 单元格双击回调
func _on_cell_double_clicked(row: int, column: int) -> void:
	if not enable_double_click_editing:
		return
	if _try_open_popup_editor(row, column):
		return
	_start_editing(row, column)

func _get_type_definition_for_column(column: int) -> Dictionary:
	if not data_model:
		return {}
	var type_def: Dictionary = {}
	if schema_manager and schema_manager.is_schema_loaded():
		type_def = schema_manager.get_type_definition_for_index(column)
	if type_def.is_empty():
		type_def = data_model.get_column_type_definition(column)
	return type_def


func _try_open_popup_editor(row: int, column: int) -> bool:
	if _is_editing:
		_finish_editing()
	if not data_model or not data_model.is_valid_index(row, column):
		return false
	if state_manager and state_manager.is_file_readonly():
		return false

	var type_def := _get_type_definition_for_column(column)
	if type_def.is_empty():
		return false

	var t := str(type_def.get("type", "")).strip_edges().to_lower()
	match t:
		"vector2":
			_open_vector_dialog(row, column, 2)
			return true
		"vector3":
			_open_vector_dialog(row, column, 3)
			return true
		"color":
			_open_color_dialog(row, column)
			return true
		_:
			return false


func _attach_window_to_root(win: Window) -> void:
	if not win:
		return
	var root := get_tree().root if get_tree() else null
	if not root:
		return
	if win.get_parent():
		win.get_parent().remove_child(win)
	root.add_child(win)


func _open_vector_dialog(row: int, column: int, dimensions: int) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "编辑 Vector%s" % str(dimensions)
	dialog.min_size = Vector2(360, 180)
	dialog.size = Vector2(400, 200)
	dialog.transient = true
	var parent_win := get_window()
	if parent_win:
		dialog.transient_to = parent_win
	dialog.exclusive = true
	dialog.always_on_top = true
	if state_manager:
		state_manager.start_edit_mode(row, column)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	dialog.add_child(vbox)

	var values := _parse_number_list(data_model.get_cell_value(row, column))
	while values.size() < dimensions:
		values.append(0.0)

	var labels := PackedStringArray(["X", "Y", "Z", "W"])
	var spins: Array[SpinBox] = []
	for i in range(dimensions):
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 8)
		vbox.add_child(line)

		var label := Label.new()
		label.text = labels[i]
		label.custom_minimum_size.x = 24
		line.add_child(label)

		var spin := SpinBox.new()
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spin.step = 0.01
		spin.allow_greater = true
		spin.allow_lesser = true
		spin.value = float(values[i])
		line.add_child(spin)
		spins.append(spin)

	dialog.confirmed.connect(func() -> void:
		var parts := PackedStringArray()
		for s in spins:
			parts.append(str(s.value))
		var new_value := ",".join(parts)
		data_model.set_cell_value(row, column, new_value)
		_invalidate_row_layout()
	)

	dialog.visibility_changed.connect(func() -> void:
		if not dialog.visible:
			if state_manager:
				state_manager.end_edit_mode()
			dialog.queue_free()
	)

	_attach_window_to_root(dialog)
	dialog.popup_centered()


func _open_color_dialog(row: int, column: int) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = "编辑 Color"
	dialog.min_size = Vector2(360, 220)
	dialog.size = Vector2(420, 260)
	dialog.transient = true
	var parent_win := get_window()
	if parent_win:
		dialog.transient_to = parent_win
	dialog.exclusive = true
	dialog.always_on_top = true
	if state_manager:
		state_manager.start_edit_mode(row, column)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	dialog.add_child(vbox)

	var picker := ColorPickerButton.new()
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var parsed := _parse_color(data_model.get_cell_value(row, column))
	picker.color = parsed if parsed != null else Color(1, 1, 1, 1)
	vbox.add_child(picker)

	dialog.confirmed.connect(func() -> void:
		var new_value := _color_to_hex(picker.color)
		data_model.set_cell_value(row, column, new_value)
		_invalidate_row_layout()
	)

	dialog.visibility_changed.connect(func() -> void:
		if not dialog.visible:
			if state_manager:
				state_manager.end_edit_mode()
			dialog.queue_free()
	)

	_attach_window_to_root(dialog)
	dialog.popup_centered()


## 开始编辑
func _start_editing(row: int, column: int) -> void:
	if not data_model or not data_model.is_valid_index(row, column):
		return

	if state_manager and state_manager.is_file_readonly():
		return

	_editing_cell = Vector2i(row, column)
	_is_editing = true

	# 获取类型定义
	var type_def := _get_type_definition_for_column(column)

	# 根据类型创建智能编辑器
	if type_def:
		_create_smart_editor(row, column, type_def)
	else:
		_create_line_editor(row, column)

	if state_manager:
		state_manager.start_edit_mode(row, column)


## 完成编辑
func _finish_editing() -> void:
	if not _is_editing:
		return

	var new_value := ""

	# 根据编辑器类型获取值
	match _current_editor_type:
		"LineEdit":
			if _cell_editor:
				new_value = _cell_editor.text
		"OptionButton":
			if _smart_editor is OptionButton:
				var option_button := _smart_editor as OptionButton
				new_value = option_button.get_item_text(option_button.selected)
		"CheckBox":
			if _smart_editor is CheckBox:
				var check_box := _smart_editor as CheckBox
				new_value = "true" if check_box.button_pressed else "false"
		"SpinBox":
			if _smart_editor is SpinBox:
				var spin_box := _smart_editor as SpinBox
				new_value = str(int(spin_box.value)) if _spinbox_is_int else str(spin_box.value)

	# 自动去除空格
	if _auto_trim_whitespace and not new_value.is_empty():
		new_value = new_value.strip_edges()

	# 更新数据
	if _editing_cell.x >= 0 and _editing_cell.y >= 0:
		if data_model:
			data_model.set_cell_value(_editing_cell.x, _editing_cell.y, new_value)
			_invalidate_row_layout()

	_stop_editing()
	if _should_use_auto_row_height():
		refresh()


## 取消编辑
func _cancel_editing() -> void:
	if not _is_editing:
		return

	_stop_editing()


## 停止编辑
func _stop_editing() -> void:
	if _cell_editor:
		_cell_editor.queue_free()
		_cell_editor = null

	if _smart_editor:
		_smart_editor.queue_free()
		_smart_editor = null

	_is_editing = false
	_current_editor_type = ""
	_spinbox_is_int = false

	if state_manager:
		state_manager.end_edit_mode()

	_request_redraw()


## 编辑器文本提交回调
func _on_editor_text_submitted(text: String) -> void:
	_finish_editing()


## 枚举项选择回调
func _on_enum_item_selected(index: int, row: int, column: int) -> void:
	# 延迟一点完成编辑
	await get_tree().process_frame
	_finish_editing()


## 布尔复选框切换回调
func _on_bool_toggled(pressed: bool, row: int, column: int) -> void:
	# 延迟一点完成编辑
	await get_tree().process_frame
	_finish_editing()


## 资源编辑器输入回调
func _on_resource_editor_input(event: InputEvent, row: int, column: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# 打开文件选择对话框
		_open_resource_selector(row, column)


## 打开资源选择对话框
func _open_resource_selector(row: int, column: int) -> void:
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.title = "选择资源"
	dialog.access = FileDialog.ACCESS_RESOURCES

	var type_def: Dictionary = {}
	if schema_manager and schema_manager.is_schema_loaded():
		type_def = schema_manager.get_type_definition_for_index(column)

	var data_type := str(type_def.get("type", "resource")).strip_edges().to_lower()
	var filters := PackedStringArray()

	match data_type:
		"texture2d", "texture":
			filters.append("*.png, *.jpg, *.jpeg, *.webp ; 图片")
			filters.append("*.svg ; SVG")
		"packedscene":
			filters.append("*.tscn, *.scn ; 场景")
		"shader":
			filters.append("*.gdshader, *.shader ; Shader")
		"material":
			filters.append("*.tres, *.res ; 资源")
		"audiostream":
			filters.append("*.ogg, *.wav, *.mp3 ; 音频")
		"font":
			filters.append("*.ttf, *.otf, *.woff, *.woff2 ; 字体")
		"theme":
			filters.append("*.tres, *.res ; 资源")
		"resource":
			filters.append("*.tres, *.res ; 资源")
		_:
			filters.append("*.tres, *.res ; 资源")

	filters.append("*.* ; 所有文件")
	dialog.filters = filters

	dialog.file_selected.connect(func(path: String):
		# 统一用路径显示，同时尽力写入 uid://...（如果能解析到）
		var uid_text := ""
		if ResourceLoader.exists(path):
			var res: Resource = ResourceLoader.load(path)
			if res:
				var uid_id: int = int(res.resource_uid)
				if uid_id != 0:
					uid_text = ResourceUID.id_to_text(uid_id)

		if _cell_editor:
			var display := path
			if not uid_text.is_empty():
				display = "%s\nUID：%s" % [path, uid_text]
			_cell_editor.text = display

		# 将实际值写回表格：优先 uid，其次路径（与字段设置一致）
		if uid_text.begins_with("uid://"):
			data_model.set_cell_value(row, column, uid_text)
		else:
			data_model.set_cell_value(row, column, path)

		_finish_editing()
	)

	get_tree().root.add_child(dialog)
	dialog.popup_centered()
	await dialog.popup_hide
	dialog.queue_free()


## 创建 LineEdit 编辑器
func _create_line_editor(row: int, column: int) -> void:
	_cell_editor = LineEdit.new()
	_cell_editor.text = data_model.get_cell_value(row, column)

	# 检查是否有默认值提示
	var type_def: Dictionary = {}
	if schema_manager and schema_manager.is_schema_loaded():
		type_def = schema_manager.get_type_definition_for_index(column)

	if type_def and type_def.has("default") and not str(type_def.get("default", "")).is_empty():
		_cell_editor.placeholder_text = str(type_def.get("default", ""))

	_setup_common_editor(row, column)


## 创建下拉框编辑器（枚举类型）
func _create_enum_editor(row: int, column: int, type_def: Dictionary) -> void:
	var option_button := OptionButton.new()

	var current_value := data_model.get_cell_value(row, column)
	var selected_index := 0

	# 添加枚举选项
	var enum_values: Array = type_def.get("enum_values", []) as Array
	for i in range(enum_values.size()):
		var value: String = str(enum_values[i])
		option_button.add_item(value)
		if value == current_value:
			selected_index = i

	option_button.selected = selected_index

	# 设置为智能编辑器
	_smart_editor = option_button
	_smart_editor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 计算位置
	var editor_pos := _get_cell_position(row, column)
	var editor_size := Vector2(_get_column_width(column), ceil(_get_row_height(row)))

	_smart_editor.position = editor_pos
	_smart_editor.size = editor_size
	_smart_editor.focus_mode = Control.FOCUS_ALL

	_cell_container.add_child(_smart_editor)
	_smart_editor.grab_focus()

	# 连接信号
	option_button.item_selected.connect(_on_enum_item_selected.bind(row, column))

	_current_editor_type = "OptionButton"


## 创建复选框编辑器（布尔类型）
func _create_bool_editor(row: int, column: int, type_def: Dictionary) -> void:
	var check_box := CheckBox.new()

	var current_value := data_model.get_cell_value(row, column).to_lower()
	if current_value in ["true", "1", "yes"]:
		check_box.button_pressed = true

	# 设置为智能编辑器
	_smart_editor = check_box
	_smart_editor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# 计算位置
	var editor_pos := _get_cell_position(row, column)
	var editor_size := Vector2(_get_column_width(column), ceil(_get_row_height(row)))

	_smart_editor.position = editor_pos
	_smart_editor.size = editor_size

	_cell_container.add_child(_smart_editor)
	_smart_editor.grab_focus()

	# 连接信号
	check_box.toggled.connect(_on_bool_toggled.bind(row, column))

	_current_editor_type = "CheckBox"


## 创建文件选择对话框（资源类型）
func _create_resource_editor(row: int, column: int, type_def: Dictionary) -> void:
	# 使用 LineEdit 显示路径，点击时打开文件选择对话框
	_cell_editor = LineEdit.new()
	_cell_editor.text = data_model.get_cell_value(row, column)
	_cell_editor.editable = false # 只读，点击时打开对话框
	_cell_editor.placeholder_text = "点击选择资源..."

	_setup_common_editor(row, column)

	# 连接 GUI 输入信号以处理点击
	_cell_editor.gui_input.connect(_on_resource_editor_input.bind(row, column))


## 创建智能编辑器
func _create_smart_editor(row: int, column: int, type_def: Dictionary) -> void:
	var data_type: String = str(type_def.get("type", "")).to_lower()

	match data_type:
		"int":
			_create_number_editor(row, column, true)
		"float":
			_create_number_editor(row, column, false)
		"enum":
			var enum_values: Array = type_def.get("enum_values", []) as Array
			if not enum_values.is_empty():
				_create_enum_editor(row, column, type_def)
			else:
				_create_line_editor(row, column)
		"bool":
			_create_bool_editor(row, column, type_def)
		"resource":
			_create_resource_editor(row, column, type_def)
		_:
			_create_line_editor(row, column)


func _create_number_editor(row: int, column: int, is_int: bool) -> void:
	var spin_box := SpinBox.new()
	spin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spin_box.allow_greater = true
	spin_box.allow_lesser = true
	if is_int:
		spin_box.step = 1.0
	else:
		spin_box.step = 0.01

	var current_text := str(data_model.get_cell_value(row, column)).strip_edges()
	if current_text.is_empty():
		spin_box.value = 0.0
	elif current_text.is_valid_float():
		spin_box.value = current_text.to_float()
	else:
		spin_box.value = 0.0

	_smart_editor = spin_box
	_smart_editor.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var editor_pos := _get_cell_position(row, column)
	var editor_size := Vector2(_get_column_width(column), ceil(_get_row_height(row)))
	_smart_editor.position = editor_pos
	_smart_editor.size = editor_size
	_smart_editor.focus_mode = Control.FOCUS_ALL

	_cell_container.add_child(_smart_editor)
	_smart_editor.grab_focus()

	_spinbox_is_int = is_int
	_current_editor_type = "SpinBox"
	spin_box.focus_exited.connect(_on_smart_editor_focus_exited)


func _on_smart_editor_focus_exited() -> void:
	await get_tree().process_frame
	if _smart_editor and not _smart_editor.has_focus():
		_finish_editing()


## 设置通用编辑器属性
func _setup_common_editor(row: int, column: int) -> void:
	if not _cell_editor:
		return

	# 计算编辑器位置和大小
	var editor_pos := _get_cell_position(row, column)
	var editor_size := Vector2(_get_column_width(column), ceil(_get_row_height(row)))

	_cell_editor.position = editor_pos
	_cell_editor.size = editor_size
	_cell_editor.focus_mode = Control.FOCUS_ALL

	# 添加到容器
	_cell_container.add_child(_cell_editor)
	_cell_editor.grab_focus()
	_cell_editor.select_all()

	# 连接编辑器信号
	_cell_editor.text_submitted.connect(_on_editor_text_submitted)
	_cell_editor.focus_exited.connect(_on_editor_focus_exited)

	_current_editor_type = "LineEdit"


## 编辑器失去焦点回调
func _on_editor_focus_exited() -> void:
	# 延迟一点，确保不是因为点击了其他单元格
	await get_tree().process_frame
	if _cell_editor and not _cell_editor.has_focus():
		_finish_editing()


## 获取单元格位置
func _get_cell_position(row: int, column: int) -> Vector2:
	var x_offset: float = float(_get_line_number_width())

	for c in range(column):
		x_offset += _get_column_width(c)

	x_offset -= _scroll_offset.x
	_ensure_row_layout()
	var y_pos := _get_row_top(row) - _scroll_offset.y

	return Vector2(x_offset, y_pos)


## 移动到下一行
func _move_to_next_row() -> void:
	if _editing_cell.x >= 0:
		var next_row := _editing_cell.x + 1
		var row_count := data_model.get_row_count() if data_model else 0

		if next_row < row_count:
			_selected_cell = Vector2i(next_row, _editing_cell.y)
			if data_model:
				data_model.select_cell(next_row, _editing_cell.y)
				cell_selected.emit(next_row, _editing_cell.y)
			_request_redraw()


## 移动到上一行
func _move_to_previous_row() -> void:
	if _editing_cell.x >= 0:
		var prev_row := _editing_cell.x - 1

		if prev_row >= 0:
			_selected_cell = Vector2i(prev_row, _editing_cell.y)
			if data_model:
				data_model.select_cell(prev_row, _editing_cell.y)
				cell_selected.emit(prev_row, _editing_cell.y)
			_request_redraw()


## 移动到下一列
func _move_to_next_column() -> void:
	if _editing_cell.y >= 0:
		var next_col := _editing_cell.y + 1
		var col_count := data_model.get_column_count() if data_model else 0

		if next_col < col_count:
			_selected_cell = Vector2i(_editing_cell.x, next_col)
			if data_model:
				data_model.select_cell(_editing_cell.x, next_col)
				cell_selected.emit(_editing_cell.x, next_col)
			_request_redraw()


## 移动到上一列
func _move_to_previous_column() -> void:
	if _editing_cell.y >= 0:
		var prev_col := _editing_cell.y - 1

		if prev_col >= 0:
			_selected_cell = Vector2i(_editing_cell.x, prev_col)
			if data_model:
				data_model.select_cell(_editing_cell.x, prev_col)
				cell_selected.emit(_editing_cell.x, prev_col)
			_request_redraw()


## 刷新视图
func refresh() -> void:
	_image_cache.clear()
	_ensure_row_layout(true)
	_update_scroll_ranges()
	_update_visible_rows()
	_update_corner_fields_button_layout()
	_update_add_row_button_layout()
	_request_redraw()


## 获取单元格错误
func _get_cell_error(row: int, column: int) -> Dictionary:
	if validation_manager:
		return validation_manager.get_cell_error(row, column)
	return {}


## 获取错误颜色
func _get_error_color(severity: int) -> Color:
	if validation_manager:
		return validation_manager.get_error_color(severity)
	return COLOR_CELL_ERROR


## 类型定义变化回调
func _on_type_definitions_changed(definitions: Array) -> void:
	_request_redraw()


## 错误添加回调
func _on_error_added(error: Dictionary) -> void:
	_request_redraw()


## 错误移除回调
func _on_error_removed(row: int, column: int) -> void:
	_request_redraw()


## 所有错误清除回调
func _on_errors_cleared() -> void:
	_request_redraw()
#endregion

#region 选区管理功能 Selection Features
## 处理左键点击
func _handle_left_click(cell: Vector2i, event: InputEventMouseButton) -> void:
	if Input.is_key_pressed(KEY_CTRL):
		# 多选模式
		_toggle_cell_selection(cell)
	elif Input.is_key_pressed(KEY_SHIFT):
		# 矩形选区模式
		_update_selection_range(cell)
	else:
		# 单选模式
		_clear_selection()
		_select_cell(cell)
	_request_redraw()


## 选择单元格
func _select_cell(cell: Vector2i) -> void:
	_selected_cell = cell
	_selection_start = cell
	_selection_end = cell
	_has_selection = true
	_selected_cells.clear()
	_selected_cells.append(cell)
	cell_selected.emit(cell.x, cell.y)


## 切换单元格选择
func _toggle_cell_selection(cell: Vector2i) -> void:
	if _is_cell_selected(cell):
		_remove_cell_from_selection(cell)
	else:
		_add_cell_to_selection(cell)
	_selected_cell = cell
	_has_selection = not _selected_cells.is_empty()


## 添加单元格到选区
func _add_cell_to_selection(cell: Vector2i) -> void:
	if not _is_cell_selected(cell):
		_selected_cells.append(cell)


## 从选区移除单元格
func _remove_cell_from_selection(cell: Vector2i) -> void:
	var index := _selected_cells.find(cell)
	if index >= 0:
		_selected_cells.remove_at(index)


## 更新选区范围
func _update_selection_range(end_cell: Vector2i) -> void:
	_selection_end = end_cell
	_selected_cells.clear()
	_has_selection = true

	var start_row := min(_selection_start.x, _selection_end.x)
	var end_row := max(_selection_start.x, _selection_end.x)
	var start_col := min(_selection_start.y, _selection_end.y)
	var end_col := max(_selection_start.y, _selection_end.y)

	for row in range(start_row, end_row + 1):
		for col in range(start_col, end_col + 1):
			_selected_cells.append(Vector2i(row, col))


## 清除选区
func _clear_selection() -> void:
	_selected_cells.clear()
	_has_selection = false
	_selection_start = Vector2i(-1, -1)
	_selection_end = Vector2i(-1, -1)


## 检查单元格是否被选中
func _is_cell_selected(cell: Vector2i) -> bool:
	return cell in _selected_cells


func _select_row(row: int) -> void:
	if not data_model:
		return
	var col_count := data_model.get_column_count()
	if row < 0 or col_count <= 0:
		return
	_selected_cells.clear()
	for col in range(col_count):
		_selected_cells.append(Vector2i(row, col))
	_selected_cell = Vector2i(row, 0)
	_selection_start = Vector2i(row, 0)
	_selection_end = Vector2i(row, col_count - 1)
	_has_selection = true
	cell_selected.emit(row, 0)


func _select_column(column: int) -> void:
	if not data_model:
		return
	var row_count := data_model.get_row_count()
	if column < 0 or row_count <= 0:
		return
	_selected_cells.clear()
	for row in range(row_count):
		_selected_cells.append(Vector2i(row, column))
	_selected_cell = Vector2i(0, column)
	_selection_start = Vector2i(0, column)
	_selection_end = Vector2i(row_count - 1, column)
	_has_selection = true
	cell_selected.emit(0, column)


## 获取选中单元格列表
func get_selected_cells() -> Array[Vector2i]:
	return _selected_cells.duplicate()


## 是否有选中单元格
func has_selection() -> bool:
	return _has_selection or not _selected_cells.is_empty()
#endregion

#region 行列操作功能 Row/Column Operations
## 显示右键菜单
func _show_context_menu(cell: Vector2i, event: InputEventMouseButton) -> void:
	_selected_cell = cell

	# 设置菜单项状态
	var row_count := data_model.get_row_count() if data_model else 0
	var col_count := data_model.get_column_count() if data_model else 0

	_context_menu.set_item_disabled(ContextMenuAction.MOVE_ROW_UP, cell.x == 0)
	_context_menu.set_item_disabled(ContextMenuAction.MOVE_ROW_DOWN, cell.x == row_count - 1)
	_context_menu.set_item_disabled(ContextMenuAction.COLUMN_SETTINGS, cell.y < 0 or cell.y >= col_count)

	# 在嵌套容器/滚动区域里，局部坐标可能与实际屏幕位置存在偏移。
	# 这里改用 viewport 坐标，并让 PopupMenu 通过 parent/viewport 正确换算位置。
	var popup_pos := get_viewport().get_mouse_position()
	_context_menu.popup_on_parent(Rect2(popup_pos, Vector2.ZERO))


## 上下文菜单回调
func _on_context_menu_pressed(id: int) -> void:
	match id:
		ContextMenuAction.INSERT_ROW_ABOVE:
			row_requested.emit("insert_above", _selected_cell.x)
		ContextMenuAction.INSERT_ROW_BELOW:
			row_requested.emit("insert_below", _selected_cell.x)
		ContextMenuAction.DELETE_ROW:
			row_requested.emit("delete", _selected_cell.x)
		ContextMenuAction.MOVE_ROW_UP:
			row_requested.emit("move_up", _selected_cell.x)
		ContextMenuAction.MOVE_ROW_DOWN:
			row_requested.emit("move_down", _selected_cell.x)
		ContextMenuAction.COLUMN_SETTINGS:
			column_settings_requested.emit(_selected_cell.y)


## 插入行
func insert_row(row: int) -> void:
	if not data_model:
		return

	data_model.insert_row(row, PackedStringArray())
	_clear_selection()
	_invalidate_row_layout()
	refresh()


## 删除行
func delete_row(row: int) -> void:
	if not data_model:
		return

	data_model.remove_row(row)
	_clear_selection()
	_selected_cell = Vector2i(-1, -1)
	_invalidate_row_layout()
	refresh()


## 移动行
func move_row(row: int, direction: int) -> void:
	if not data_model:
		return

	var new_row := row + direction
	data_model.move_row(row, new_row)
	_invalidate_row_layout()
	refresh()


## 插入列
func insert_column(column: int) -> void:
	if not data_model:
		return

	var column_name := "Column_" + str(column + 1)
	data_model.insert_column(column, column_name, "")
	_clear_selection()
	_invalidate_row_layout()
	refresh()


## 删除列
func delete_column(column: int) -> void:
	if not data_model:
		return

	data_model.remove_column(column)
	_clear_selection()
	_selected_cell = Vector2i(-1, -1)
	_invalidate_row_layout()
	refresh()


## 移动列
func move_column(column: int, direction: int) -> void:
	if not data_model:
		return

	var new_col := column + direction
	data_model.move_column(column, new_col)
	_invalidate_row_layout()
	refresh()


## 批量删除选中单元格
func batch_delete_selected_cells() -> void:
	if _selected_cells.is_empty():
		return

	for cell: Vector2i in _selected_cells:
		if data_model and data_model.is_valid_index(cell.x, cell.y):
			data_model.set_cell_value(cell.x, cell.y, "")

	_clear_selection()
	_invalidate_row_layout()
	refresh()


## 选择全部单元格
func select_all() -> void:
	if not data_model:
		return

	var row_count := data_model.get_row_count()
	var col_count := data_model.get_column_count()
	if row_count <= 0 or col_count <= 0:
		return

	_selected_cell = Vector2i(0, 0)
	_selection_start = Vector2i(0, 0)
	_selection_end = Vector2i(row_count - 1, col_count - 1)
	_has_selection = true
	_selected_cells.clear()

	for row in range(row_count):
		for col in range(col_count):
			_selected_cells.append(Vector2i(row, col))

	_request_redraw()


## 删除当前选区（支持全选/矩形/多选）
func delete_selection() -> void:
	if _selected_cells.is_empty():
		return

	batch_delete_selected_cells()


## 批量设置选中单元格的值
func batch_set_selected_cells(value: String) -> void:
	if _selected_cells.is_empty():
		return

	for cell: Vector2i in _selected_cells:
		if data_model and data_model.is_valid_index(cell.x, cell.y):
			data_model.set_cell_value(cell.x, cell.y, value)

	_invalidate_row_layout()
	refresh()


## 批量填充选中单元格
func batch_fill_cells(start_value: String, increment: float = 0.0) -> void:
	if _selected_cells.is_empty():
		return

	var sorted_cells: Array[Vector2i] = _selected_cells.duplicate()
	sorted_cells.sort_custom(func(a, b):
		return a.x < b.x or (a.x == b.x and a.y < b.y)
	)

	var current_value: Variant = float(start_value) if start_value.is_valid_float() else start_value
	var is_number: bool = start_value.is_valid_float()

	for i in range(sorted_cells.size()):
		var cell: Vector2i = sorted_cells[i]
		if data_model and data_model.is_valid_index(cell.x, cell.y):
			if is_number:
				data_model.set_cell_value(cell.x, cell.y, str(current_value))
				current_value = float(current_value) + increment
			else:
				data_model.set_cell_value(cell.x, cell.y, start_value)

	_invalidate_row_layout()
	refresh()


func _parse_number_list(text: String) -> Array[float]:
	var cleaned := str(text).strip_edges()
	if cleaned.is_empty():
		return []
	var regex := RegEx.new()
	regex.compile("[-+]?\\d*\\.?\\d+(?:[eE][-+]?\\d+)?")
	var out: Array[float] = []
	for m in regex.search_all(cleaned):
		var s := m.get_string()
		if s.is_valid_float():
			out.append(s.to_float())
	return out


func _parse_color(text: String) -> Variant:
	var s := str(text).strip_edges()
	if s.is_empty():
		return null
	if s.begins_with("#"):
		var hex := s.substr(1)
		if hex.length() == 6 or hex.length() == 8:
			var r := hex.substr(0, 2).hex_to_int()
			var g := hex.substr(2, 2).hex_to_int()
			var b := hex.substr(4, 2).hex_to_int()
			var a := 255
			if hex.length() == 8:
				a = hex.substr(6, 2).hex_to_int()
			return Color(r / 255.0, g / 255.0, b / 255.0, a / 255.0)

	var parts := _parse_number_list(s)
	if parts.size() >= 3:
		var a := parts[3] if parts.size() >= 4 else 1.0
		return Color(parts[0], parts[1], parts[2], a)
	return null


func _color_to_hex(c: Color) -> String:
	var r := clampi(int(round(c.r * 255.0)), 0, 255)
	var g := clampi(int(round(c.g * 255.0)), 0, 255)
	var b := clampi(int(round(c.b * 255.0)), 0, 255)
	var a := clampi(int(round(c.a * 255.0)), 0, 255)
	return "#%02X%02X%02X%02X" % [r, g, b, a]
#endregion
