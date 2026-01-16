class_name GDSVEditorTab
extends Control

## CSV 编辑器标签页辅助类，为标签页控件提供文件路径访问功能

## 文件路径（用于显示/回退）
var _file_path: String = ""

## 文档 UID（优先）：用于标签页与数据/Schema/UI 绑定的稳定编号
## - Godot 4.4+ 的 ResourceUID 文本格式：uid://xxxx
## - 为空时回退使用 file_path
var _doc_uid: String = ""

## 表格视图
var _table_view: Control

## 每个标签页独立的数据模型/处理器（用于多标签页切换）
var _data_model: GDSVDataModel
var _data_processor: GDSVDataProcessor


## 获取文件路径
func get_file_path() -> String:
	return _file_path


## 获取 UID（可能为空）
func get_doc_uid() -> String:
	return _doc_uid


## 获取文档绑定 key（优先 uid，其次 file_path）
func get_binding_key() -> String:
	if not _doc_uid.is_empty():
		return _doc_uid
	return _file_path

## 获取表格视图
func get_table_view() -> Control:
	return _table_view


## 获取数据模型
func get_data_model() -> GDSVDataModel:
	return _data_model


## 获取数据处理器
func get_data_processor() -> GDSVDataProcessor:
	return _data_processor
