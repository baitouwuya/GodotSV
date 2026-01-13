class_name CSVEditorTab
extends Control

## CSV 编辑器标签页辅助类，为标签页控件提供文件路径访问功能

## 文件路径
var _file_path: String = ""

## 表格视图
var _table_view: Control


## 获取文件路径
func get_file_path() -> String:
	return _file_path


## 获取表格视图
func get_table_view() -> Control:
	return _table_view
