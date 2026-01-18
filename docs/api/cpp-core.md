# C++ 核心类 API

本页概述核心 C++ GDExtension 类的职责与常用接口。

## GDSVParser

- 解析 GDSV/CSV 字符串或文件为二维数组。
- 常用：`ParseFromString` / `ParseFromFile` / `GetHeader`。

## GDSVTableData

- 表格数据增删改查。
- 常用：`GetCellValue` / `SetCellValue` / `InsertRow` / `RemoveColumn`。

## GDSVTypeConverter

- 字符串 -> Variant 类型转换。
- 常用：`ConvertString` / `ToInt` / `ToFloat` / `ToResource`。

## GDSVSearchEngine

- 搜索、替换与过滤。
- 常用：`Search` / `SearchRegex` / `Replace` / `FilterRows`。

## GDSVDataValidator

- 校验单元格/行/表数据。
- 常用：`ValidateCell` / `ValidateRow` / `ValidateTable`。

## GDSVStreamReader

- 大文件流式读取。
- 常用：`OpenFile` / `ReadNextLine` / `GetProgress`。

## GDSVTypeAnnotationParser

- 解析表头内联类型注解。
- 常用：`ParseHeader` / `GetFieldType` / `IsAnnotationValid`。

详细方法签名请参考本目录下的 API 文档与源码绑定注释（插件包内无 doc_classes）。

