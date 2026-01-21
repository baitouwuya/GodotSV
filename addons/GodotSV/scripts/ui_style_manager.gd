class_name UIStyleManager
extends Node

## UI样式管理器，提供统一的样式主题

signal theme_changed(theme_name: String)

#region 主题常量 Theme Constants
const THEME_LIGHT = "light"
const THEME_DARK = "dark"
const THEME_AUTO = "auto"
#endregion

#region 样式常量 Style Constants
## 错误单元格颜色
const ERROR_CELL_COLOR = Color(1.0, 0.3, 0.3, 0.3)

## 选中单元格颜色
const SELECTED_CELL_COLOR = Color(0.2, 0.6, 1.0, 0.3)

## 选中单元格边框颜色
const SELECTED_BORDER_COLOR = Color(0.2, 0.6, 1.0, 1.0)

## 修改标记颜色
const MODIFIED_INDICATOR_COLOR = Color(1.0, 0.8, 0.0, 1.0)

## 验证通过颜色
const VALIDATION_OK_COLOR = Color(0.3, 0.8, 0.3, 0.2)

## 验证警告颜色
const VALIDATION_WARN_COLOR = Color(1.0, 0.7, 0.0, 0.2)

## 表头背景色
const HEADER_BG_COLOR = Color(0.9, 0.9, 0.9, 1.0)

## 行号列背景色
const ROW_NUMBER_BG_COLOR = Color(0.85, 0.85, 0.85, 1.0)

## 奇数行背景色
const ODD_ROW_BG_COLOR = Color(1.0, 1.0, 1.0, 0.0)

## 偶数行背景色
const EVEN_ROW_BG_COLOR = Color(0.97, 0.97, 0.97, 1.0)
#endregion

#region 公共变量 Public Variables
## 当前主题名称
var current_theme: String = THEME_AUTO
#endregion

#region 主题管理 Theme Management
## 设置主题
func set_theme(theme_name: String) -> void:
	current_theme = theme_name
	theme_changed.emit(theme_name)


## 获取错误单元格样式
func get_error_cell_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = ERROR_CELL_COLOR
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(1.0, 0.0, 0.0, 0.8)
	return style


## 获取选中单元格样式
func get_selected_cell_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = SELECTED_CELL_COLOR
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = SELECTED_BORDER_COLOR
	return style


## 获取表头样式
func get_header_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = HEADER_BG_COLOR
	style.border_width_bottom = 1
	style.border_color = Color(0.7, 0.7, 0.7, 1.0)
	return style


## 获取行号列样式
func get_row_number_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = ROW_NUMBER_BG_COLOR
	style.border_width_right = 1
	style.border_color = Color(0.7, 0.7, 0.7, 1.0)
	return style


## 获取单元格样式
func get_cell_style(is_odd_row: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = ODD_ROW_BG_COLOR if is_odd_row else EVEN_ROW_BG_COLOR
	return style


## 应用样式到控件
func apply_error_style(control: Control) -> void:
	control.add_theme_stylebox_override("panel", get_error_cell_style())


## 应用选中样式到控件
func apply_selected_style(control: Control) -> void:
	control.add_theme_stylebox_override("panel", get_selected_cell_style())


## 移除所有样式
func clear_styles(control: Control) -> void:
	control.remove_theme_stylebox_override("panel")
#endregion

#region 工具方法 Utility Methods
## 检查是否为暗色主题
func is_dark_theme() -> bool:
	if current_theme == THEME_DARK:
		return true
	elif current_theme == THEME_AUTO:
		var editor_settings := EditorInterface.get_editor_settings()
		var theme := editor_settings.get_setting("interface/theme/accent_color")
		# 基于编辑器主题判断
		return theme.to_html().to_lower() == "#000000"
	return false


## 获取主题感知的颜色
func get_theme_color(base_color: Color) -> Color:
	if is_dark_theme():
		return base_color.lightened(0.2)
	return base_color
