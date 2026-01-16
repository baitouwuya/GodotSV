class_name CSVEditorTab
extends Control

## CSV 编辑器标签页辅助类，为标签页控件提供文件路径访问功能

## 文件路径
var _file_path: String = ""

## 表格视图
var _table_view: Control

## 每个标签页独立的数据模型/处理器（用于多标签页切换）
var _data_model: CSVDataModel
var _data_processor: CSVDataProcessor


## 获取文件路径
func get_file_path() -> String:
	return _file_path


## 获取表格视图
func get_table_view() -> Control:
	return _table_view


## 获取数据模型
func get_data_model() -> CSVDataModel:
	return _data_model


## 获取数据处理器
func get_data_processor() -> CSVDataProcessor:
	return _data_processor
