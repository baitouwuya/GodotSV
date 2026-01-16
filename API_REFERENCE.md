# GodotSV API 参考

完整的 API 参考文档，涵盖所有 C++ GDExtension 类和 GDScript 高级 API。

## 目录

1. [C++ 核心类 API](#c-核心类-api)
   - [CSVParser](#csvparser-csv-parser)
   - [CSVTableData](#csvtabledata-表格数据管理器)
   - [CSVTypeConverter](#csvtypeconverter-类型转换器)
   - [CSVSearchEngine](#csvsearchengine-搜索引擎)
   - [CSVDataValidator](#csvdatavalidator-数据验证器)
   - [CSVStreamReader](#csvstreamreader-流式读取器)
   - [CSVTypeAnnotationParser](#csvtypeannotationparser-类型注解解析器)
2. [GDScript 高级 API](#gdscript-高级-api)
   - [CSVLoader](#csvloader-高级加载器)
   - [CSVResource](#csvresource-数据资源)
   - [CSVSchema](#csvschema-schema-定义)
   - [CSVFieldDefinition](#csvfielddefinition-字段定义)
   - [CSVStreamReaderGD](#csvstreamreadergd-流式读取器-gdscript)

---

## C++ 核心类 API

### CSVParser - CSV 解析器

负责将 CSV 文件或字符串解析为结构化的二维数组。

#### 方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `ParseFromString` | `(content: String, has_header: bool = true, delimiter: String = ",") -> Array` | 从字符串解析 CSV |
| `ParseFromFile` | `(file_path: String, has_header: bool = true, delimiter: String = ",") -> Array` | 从文件解析 CSV |
| `GetHeader` | `() -> PackedStringArray` | 获取表头行 |
| `GetRowCount` | `() -> int` | 获取数据行数（不含表头） |
| `GetColumnCount` | `() -> int` | 获取列数 |
| `GetLastError` | `() -> String` | 获取解析错误信息 |
| `HasError` | `() -> bool` | 是否有解析错误 |

#### 使用示例

```gdscript
var parser := CSVParser.new()

# 从文件解析
var rows := parser.ParseFromFile("res://data/items.csv")
if parser.HasError():
    print("解析错误: ", parser.GetLastError())
    return

print("表头: ", parser.GetHeader())
print("行数: ", parser.GetRowCount())
print("列数: ", parser.GetColumnCount())

# 从字符串解析
var csv_text := "name,age,city\nAlice,25,New York\nBob,30,Los Angeles"
rows = parser.ParseFromString(csv_text)
```

---

### CSVTableData - 表格数据管理器

提供完整的表格数据 CRUD（增删改查）操作。

#### 方法和属性

##### 数据读取

| 方法 | 签名 | 说明 |
|------|------|------|
| `Initialize` | `(rows: Array, header: PackedStringArray)` | 初始化表格数据 |
| `GetRows` | `() -> Array` | 获取所有行数据 |
| `GetHeader` | `() -> PackedStringArray` | 获取表头 |
| `GetRowCount` | `() -> int` | 获取行数 |
| `GetColumnCount` | `() -> int` | 获取列数 |
| `GetCellValue` | `(row: int, column: int) -> String` | 获取单元格值 |
| `GetRow` | `(row: int) -> PackedStringArray` | 获取指定行 |
| `GetColumn` | `(column: int) -> PackedStringArray` | 获取指定列 |

##### 数据修改

| 方法 | 签名 | 说明 |
|------|------|------|
| `SetCellValue` | `(row: int, column: int, value: String) -> bool` | 设置单元格值 |
| `SetRow` | `(row: int, row_data: PackedStringArray) -> bool` | 设置整行数据 |
| `SetColumn` | `(column: int, column_data: PackedStringArray) -> bool` | 设置整列数据 |

##### 行/列操作

| 方法 | 签名 | 说明 |
|------|------|------|
| `InsertRow` | `(row: int, row_data: PackedStringArray) -> bool` | 在指定位置插入行 |
| `AppendRow` | `(row_data: PackedStringArray)` | 在末尾添加行 |
| `RemoveRow` | `(row: int) -> bool` | 删除指定行 |
| `MoveRow` | `(from: int, to: int) -> bool` | 移动行位置 |
| `InsertColumn` | `(column: int, name: String, default_value: String = "") -> bool` | 插入列 |
| `RemoveColumn` | `(column: int) -> bool` | 删除列 |
| `MoveColumn` | `(from: int, to: int) -> bool` | 移动列位置 |

##### 批量和工具方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `BatchSetCells` | `(cells: Array) -> int` | 批量设置单元格，cells 为 `[{row, column, value}, ...]` |
| `Clear` | `()` | 清空所有数据 |
| `Resize` | `(row_count: int, column_count: int, default_value: String = "")` | 调整表格大小 |
| `IsValidIndex` | `(row: int, column: int) -> bool` | 检查索引是否有效 |

#### 使用示例

```gdscript
var table := CSVTableData.new()

# 初始化表格
table.Initialize([["Alice", "25"], ["Bob", "30"]], ["name", "age"])

# 读取数据
var row0 := table.GetRow(0)  # ["Alice", "25"]
var age := table.GetCellValue(0, 1)  # "25"

# 修改数据
table.SetCellValue(0, 1, "26")
table.UpdateCell(0, "age", "26")

# 添加行
table.AppendRow(["Charlie", "35"])
table.InsertRow(1, ["David", "28"])

# 删除行
table.RemoveRow(2)

# 批量修改
table.BatchSetCells([
    {row = 0, column = 0, value = "Alice Smith"},
    {row = 1, column = 0, value = "David Johnson"}
])

# 调整大小
table.Resize(10, 3, "N/A")
```

---

### CSVTypeConverter - 类型转换器

将字符串转换为各种 Godot 类型。

#### 方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `ConvertString` | `(value: String, type: String, extra_param = null) -> Variant` | 转换字符串到指定类型 |
| `ConvertRow` | `(row: PackedStringArray, types: PackedStringArray, extra_params: Array) -> Array` | 批量转换整行 |
| `ToInt` | `(value: String, range: String = "") -> int` | 转换为整数，range 格式 `"min..max"` |
| `ToFloat` | `(value: String, range: String = "") -> float` | 转换为浮点数 |
| `ToBool` | `(value: String) -> bool` | 转换为布尔值 |
| `ToStringName` | `(value: String) -> StringName` | 转换为 StringName |
| `ToArray` | `(value: String, element_type: String) -> Array` | 转换为数组 |
| `ToEnum` | `(value: String, enum_values: PackedStringArray) -> String` | 转换为枚举值 |
| `ToResource` | `(value: String, resource_type: String) -> Resource` | 转换并加载资源 |
| `GetLastError` | `() -> String` | 获取转换错误 |
| `HasError` | `() -> bool` | 是否有错误 |

#### type 参数支持的值

| 类型字符串 | 说明 |
|------------|------|
| `"int"` | 整数 |
| `"float"` | 浮点数 |
| `"bool"` | 布尔值 |
| `"string"` | 字符串 |
| `"StringName"` | StringName |
| `"Array"` | 数组 |
| `"enum"` | 枚举 |
| `"Texture2D"` | Texture2D 资源 |
| `"PackedScene"` | PackedScene 资源 |
| `"Resource"` | 通用资源 |

#### 使用示例

```gdscript
var converter := CSVTypeConverter.new()

# 基本类型转换
var age: int = converter.ToInt("25")
var price: float = converter.ToFloat("19.99")
var active: bool = converter.ToBool("true")
var id: StringName = converter.ToStringName("player_01")

# 带范围约束的转换
var age2: int = converter.ToInt("30", "0..150")  # 0-150 范围

# 数组转换
var tags: Array = converter.ToArray("tag1,tag2,tag3", "string")

# 枚举转换
var rarity: String = converter.ToEnum("rare", ["common", "rare", "epic", "legendary"])

# 资源加载
var texture: Texture2D = converter.ToResource("res://icon.png", "Texture2D")
var scene: PackedScene = converter.ToResource("res://enemy.tscn", "PackedScene")

# 批量转换
var types := PackedStringArray(["int", "float", "bool"])
var params := ["0..100", "0.0..1000.0", null]
var converted: Array = converter.ConvertRow(["50", "99.5", "true"], types, params)
```

---

### CSVSearchEngine - 搜索引擎

提供高级搜索、替换和过滤功能。

#### 常量

| 常量 | 值 | 说明 |
|------|------|------|
| `MATCH_CONTAINS` | 0 | 包含 |
| `MATCH_NOT_CONTAINS` | 1 | 不包含 |
| `MATCH_EQUALS` | 2 | 等于 |
| `MATCH_NOT_EQUALS` | 3 | 不等于 |
| `MATCH_STARTS_WITH` | 4 | 开头匹配 |
| `MATCH_ENDS_WITH` | 5 | 结尾匹配 |

#### 方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `Search` | `(rows: Array, text: String, case_sensitive: bool = false, mode: int = 0, columns: PackedInt32Array = []) -> Array` | 搜索关键词 |
| `SearchRegex` | `(rows: Array, pattern: String, columns: PackedInt32Array = []) -> Array` | 正则表达式搜索 |
| `Replace` | `(rows: Array, search_text: String, replace_text: String, case_sensitive: bool = false, mode: int = 0, columns: PackedInt32Array = []) -> Array` | 批量替换文本 |
| `FilterRows` | `(rows: Array, text: String, case_sensitive: bool = false, mode: int = 0, column: int = -1) -> PackedInt32Array` | 过滤行，返回行索引 |
| `FindNext` | `(rows: Array, text: String, start_row: int = 0, start_column: int = 0, case_sensitive: bool = false, columns: PackedInt32Array = []) -> Dictionary` | 查找下一个匹配项 |
| `FindPrevious` | `(rows: Array, text: String, start_row: int = 0, start_column: int = 0, case_sensitive: bool = false, columns: PackedInt32Array = []) -> Dictionary` | 查找上一个匹配项 |
| `GetMatchCount` | `() -> int` | 获取上一次搜索的匹配数量 |
| `GetSearchTime` | `() -> float` | 获取搜索耗时（毫秒） |
| `GetLastError` | `() -> String` | 获取错误信息 |
| `HasError` | `() -> bool` | 是否有错误 |

#### 搜索结果格式

```gdscript
# Search 和 SearchRegex 返回的数组，每个元素是：
{
    "row": int,        # 行号
    "column": int,     # 列号
    "start_pos": int,  # 匹配起始位置
    "end_pos": int,    # 匹配结束位置
    "matched_text": String  # 匹配的文本
}
```

#### 使用示例

```gdscript
var engine := CSVSearchEngine.new()
var rows := _get_csv_rows()  # 获取 CSV 行数据

# 基本搜索 - 查找包含 "sword" 的行
var results := engine.Search(rows, "sword", false, CSVSearchEngine.MATCH_CONTAINS)
print("找到 %d 个匹配" % engine.GetMatchCount())
print("搜索耗时: %.2f ms" % engine.GetSearchTime())

# 指定列搜索
var hero_columns := PackedInt32Array([0, 1, 2])  # 只搜索前3列
results = engine.Search(rows, "legendary", false, CSVSearchEngine.MATCH_EQUALS, hero_columns)

# 正则表达式搜索
results = engine.SearchRegex(rows, r"^\d+$", hero_columns)  # 查找纯数字

# 过滤行 - 获取所有包含 "gold" 的行索引
var filtered_indices := engine.FilterRows(rows, "gold")
for idx in filtered_indices:
    print("行 %d 包含 gold" % idx)

# 替换文本
var new_rows := engine.Replace(rows, "old_value", "new_value")

# 查找下一个匹配项
var next_match := engine.FindNext(rows, "sword", 0, 0)
if not next_match.is_empty():
    print("下一个匹配在行 %d 列 %d" % [next_match.row, next_match.column])

# 查找上一个匹配项
var prev_match := engine.FindPrevious(rows, "sword", 10, 5)
```

---

### CSVDataValidator - 数据验证器

验证 CSV 数据是否符合类型和约束要求。

#### 方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `validate_cell` | `(value: String, field_name: String, field_info: Dictionary) -> bool` | 验证单个单元格 |
| `validate_row` | `(row: PackedStringArray, header: PackedStringArray, field_map: Dictionary) -> bool` | 验证整行数据 |
| `validate_table` | `(rows: Array, header: PackedStringArray, field_map: Dictionary) -> bool` | 验证整表数据 |
| `get_errors` | `() -> Array` | 获取所有验证错误 |
| `get_error_count` | `() -> int` | 获取错误数量 |
| `get_last_error` | `() -> Dictionary` | 获取最后一个错误 |
| `clear_errors` | `()` | 清除所有错误 |
| `has_errors` | `() -> bool` | 是否有错误 |

#### field_info 字典结构

> 注意：`field_info["name"]` 会用于生成错误信息中的字段名；`field_info["type"]` 推荐使用小写字符串（`"int"`、`"float"`、`"bool"`、`"enum"`、`"string"`）。

```gdscript
{
    "name": String,           # 字段名（用于错误信息）
    "type": String,           # 字段类型（推荐小写："int"/"float"/"bool"/"enum"/"string"）
    "required": bool,         # 是否必需
    "default": Variant,       # 默认值
    "range": String,          # 范围约束（如 "0..100"）
    "enum_values": Array,     # 枚举值列表
    "resource_type": String   # 资源类型（可选）
}
```

#### 错误信息格式

> 注意：
> - `validate_table()` 会返回真实的 `row` / `column`，用于精确定位错误位置。
> - `validate_cell()` / `validate_row()` 场景下，`row` 可能为 `-1`（因为调用方未提供具体行号）。

```gdscript
{
    "row": int,              # 行号（validate_cell/validate_row 场景可能为 -1）
    "column": int,           # 列号
    "field_name": String,    # 字段名
    "error_message": String, # 错误消息
    "value": String          # 单元格值
}
```

#### 使用示例

```gdscript
var validator := CSVDataValidator.new()

# 定义字段映射
var field_map := {
    "id": {"name": "id", "type": "int", "required": true, "range": "1..9999"},
    "name": {"name": "name", "type": "string", "required": true},
    "price": {"name": "price", "type": "float", "range": "0.0..999999.0"},
    "rarity": {"name": "rarity", "type": "enum", "enum_values": ["common", "rare", "epic", "legendary"]}
}

# 验证整表
var is_valid := validator.validate_table(rows, header, field_map)

if validator.has_errors():
    print("验证失败，共有 %d 个错误：" % validator.get_error_count())
    for error in validator.get_errors():
        print("  行%d 列%d %s: %s" % [error.row, error.column, error.field_name, error.error_message])

# 验证单行
var row := PackedStringArray(["5", "Super Sword", "9999.0", "epic"])
is_valid = validator.validate_row(row, header, field_map)
```

---

### CSVStreamReader - 流式读取器

用于逐行读取大型 CSV 文件，降低内存占用。

#### 方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `OpenFile` | `(file_path: String, has_header: bool = true, delimiter: String = ",") -> bool` | 打开文件 |
| `CloseFile` | `()` | 关闭文件 |
| `ReadNextLine` | `() -> PackedStringArray` | 读取下一行 |
| `ReadLines` | `(count: int) -> Array` | 读取指定数量的行 |
| `ReadAll` | `() -> Array` | 读取所有剩余行 |
| `Pause` | `()` | 暂停读取 |
| `Resume` | `()` | 恢复读取 |
| `IsPaused` | `() -> bool` | 是否已暂停 |
| `IsEOF` | `() -> bool` | 是否到达文件末尾 |
| `IsOpen` | `() -> bool` | 文件是否已打开 |
| `GetHeader` | `() -> PackedStringArray` | 获取表头 |
| `GetCurrentLineNumber` | `() -> int` | 获取当前行号 |
| `GetReadLineCount` | `() -> int` | 获取已读取的行数 |
| `GetTotalLineCount` | `() -> int` | 获取文件总行数 |
| `GetProgress` | `() -> float` | 获取读取进度（0.0-1.0） |
| `SeekToLine` | `(line_number: int) -> bool` | 跳转到指定行号 |
| `Reset` | `()` | 重置到文件开头 |
| `GetLastError` | `() -> String` | 获取错误 |
| `HasError` | `() -> bool` | 是否有错误 |

#### 使用示例

```gdscript
var reader := CSVStreamReader.new()

# 打开文件
if not reader.OpenFile("res://data/large_file.csv"):
    print("打开文件失败: ", reader.GetLastError())
    return

var header := reader.GetHeader()
print("表头: ", header)

# 逐行读取
print("开始逐行读取...")
while not reader.IsEOF():
    var line := reader.ReadNextLine()
    if line.is_empty():
        continue

    # 处理行数据
    _process_line(line)

    # 显示进度
    print("读取进度: %.1f%%, 已读 %d/%d 行" % [
        reader.GetProgress() * 100,
        reader.GetReadLineCount(),
        reader.GetTotalLineCount()
    ])

reader.CloseFile()

# 分批读取
if reader.OpenFile("res://data/large_file.csv"):
    var batch_size := 100
    var total := 0

    while not reader.IsEOF():
        var batch := reader.ReadLines(batch_size)
        _process_batch(batch)
        total += batch.size()

    print("共处理 %d 行数据" % total)
    reader.CloseFile()
```

---

### CSVTypeAnnotationParser - 类型注解解析器

解析表头中的类型标注语法，支持内联定义数据类型。

#### 支持的语法

| 语法 | 说明 |
|------|------|
| `field_name:Type` | 基本类型标注 |
| `*field_name:Type` | 必需字段标识 |
| `field_name:Type=value` | 带默认值 |
| `field_name:int[min..max]` | 范围约束 |
| `field_name:enum(val1,val2)` | 枚举类型 |
| `field_name:Array[Type]` | 数组类型 |

#### 方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `ParseHeader` | `(header: PackedStringArray) -> PackedStringArray` | 解析表头，返回清理后的字段名 |
| `GetFieldType` | `(field_name: String) -> String` | 获取字段类型 |
| `IsFieldRequired` | `(field_name: String) -> bool` | 字段是否必需 |
| `GetFieldDefault` | `(field_name: String) -> String` | 获取字段默认值 |
| `GetFieldRange` | `(field_name: String) -> String | 获取范围约束 `"min..max"` |
| `GetFieldEnumValues` | `(field_name: String) -> PackedStringArray` | 获取枚举值列表 |
| `GetArrayElementType` | `(field_name: String) -> String` | 获取数组元素类型 |
| `IsAnnotationValid` | `(annotation: String) -> bool` | 静态方法，检查语法是否有效 |
| `GetLastError` | `() -> String` | 获取错误 |
| `HasError` | `() -> bool` | 是否有错误 |

#### 使用示例

```gdscript
var parser := CSVTypeAnnotationParser.new()

# 带类型注解的表头
var annotated_header := PackedStringArray([
    "*id:int[1..9999]",                  # 必需，整数，范围1-9999
    "name:string=default_name",         # 字符串，默认值
    "price:float[0.0..10000.0]",        # 浮点数，范围
    "rarity:enum(common,rare,epic)",    # 枚举
    "tags:Array[string]",               # 字符串数组
    "texture:Texture2D"                 # 资源类型
])

# 解析表头
var clean_header := parser.ParseHeader(annotated_header)
# 结果: ["id", "name", "price", "rarity", "tags", "texture"]

# 获取字段类型信息
print("id 类型: ", parser.GetFieldType("id"))           # "int"
print("id 范围: ", parser.GetFieldRange("id"))         # "1..9999"
print("id 是否必需: ", parser.IsFieldRequired("id"))   # true

print("name 类型: ", parser.GetFieldType("name"))              # "string"
print("name 默认值: ", parser.GetFieldDefault("name"))        # "default_name"
print("name 是否必需: ", parser.IsFieldRequired("name"))      # false

print("rarity 类型: ", parser.GetFieldType("rarity"))
print("rarity 枚举值: ", parser.GetFieldEnumValues("rarity"))
# 结果: ["common", "rare", "epic"]

print("tags 类型: ", parser.GetFieldType("tags"))
print("tags 元素类型: ", parser.GetArrayElementType("tags"))
# 结果: "string"

# 检查语法有效性
var is_valid := CSVTypeAnnotationParser.IsAnnotationValid("price:float[0.0..1000.0]")
print("语法是否有效: ", is_valid)  # true
```

---

## GDScript 高级 API

### CSVLoader - 高级加载器

提供链式调用 API，简洁优雅的 CSV 加载方式。

#### 方法

##### 链式配置方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `load_file` | `(path: String) -> CSVLoader` | 加载 CSV 文件 |
| `with_header` | `(has_header: bool) -> CSVLoader` | 设置是否包含表头 |
| `with_delimiter` | `(delimiter: String) -> CSVLoader` | 设置分隔符 |
| `with_type` | `(field_name: StringName, type: FieldType) -> CSVLoader` | 设置字段类型 |
| `with_default` | `(field_name: StringName, default_value: Variant) -> CSVLoader` | 设置字段默认值 |
| `with_required_fields` | `(fields: Array[StringName]) -> CSVLoader` | 设置必需字段 |
| `with_schema` | `(schema: CSVSchema) -> CSVLoader` | 设置 Schema |

##### 数据读取方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `parse_all` | `() -> CSVResource` | 解析所有数据 |
| `stream` | `() -> CSVStreamReaderGD` | 创建流式读取器 |

##### 缓存和工具方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `clear_cache` | `static ()` | 清除缓存（LRU 缓存机制） |
| `get_errors` | `() -> Array[String]` | 获取错误信息 |
| `get_warnings` | `() -> Array[String]` | 获取警告信息 |
| `has_errors` | `() -> bool` | 是否有错误 |
| `has_warnings` | `() -> bool` | 是否有警告 |

#### 使用示例

```gdscript
# 基础用法
var items := CSVLoader.new()
    .load_file("res://data/items.csv")
    .parse_all()

# 完整配置
var items_configured := CSVLoader.new()
    .load_file("res://data/items.csv")
    .with_header(true)
    .with_delimiter(",")
    .with_type("price", CSVFieldDefinition.FieldType.TYPE_INT)
    .with_type("stackable", CSVFieldDefinition.FieldType.TYPE_BOOL)
    .with_default("price", 0)
    .with_default("description", "No description")
    .with_schema(my_schema)
    .parse_all()

# 错误处理
if items.has_errors():
    for error in items.get_errors():
        print("错误: ", error)

# 清除缓存
CSVLoader.clear_cache()
```

---

### CSVResource - 数据资源

存储解析后的 CSV 数据，继承自 `Resource`，可被保存和加载。

#### 属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `headers` | `PackedStringArray` | 表头行 |
| `rows` | `Array[Dictionary]` | 数据行 |
| `raw_data` | `Array[PackedStringArray]` | 原始数据（调试用） |
| `errors` | `Array[String]` | 错误信息 |
| `warnings` | `Array[String]` | 警告信息 |
| `total_rows` | `int` | 总行数 |
| `successful_rows` | `int` | 成功行数 |
| `failed_rows` | `int` | 失败行数 |
| `has_header` | `bool` | 是否包含表头 |
| `delimiter` | `String` | 分隔符 |
| `source_csv_path` | `String` | 源文件路径 |

#### 数据访问方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `get_value` | `(row_index: int, field_name: StringName) -> Variant` | 获取字段值 |
| `get_int` | `(row_index: int, field_name: StringName, default_value: int = 0) -> int` | 获取整数值 |
| `get_float` | `(row_index: int, field_name: StringName, default_value: float = 0.0) -> float` | 获取浮点数值 |
| `get_bool` | `(row_index: int, field_name: StringName, default_value: bool = false) -> bool` | 获取布尔值 |
| `get_string` | `(row_index: int, field_name: StringName, default_value: String = "") -> String` | 获取字符串值 |
| `get_string_name` | `(row_index: int, field_name: StringName, default_value: StringName = &"") -> StringName` | 获取 StringName 值 |

#### 查询方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `find_row` | `(field_name: StringName, value: Variant) -> Dictionary` | 根据字段查找单行 |
| `find_rows` | `(field_name: StringName, value: Variant) -> Array[Dictionary]` | 根据字段查找多行 |

#### 统计和工具方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `get_row_count` | `() -> int` | 获取行数 |
| `get_column_count` | `() -> int` | 获取列数 |
| `has_errors` | `() -> bool` | 是否有错误 |
| `has_warnings` | `() -> bool` | 是否有警告 |
| `get_errors` | `() -> Array[String]` | 获取所有错误 |
| `get_warnings` | `() -> Array[String]` | 获取所有警告 |
| `get_statistics` | `() -> String` | 获取解析统计信息 |
| `clear` | `()` | 清空所有数据 |

#### 使用示例

```gdscript
var items := CSVLoader.new().load_file("res://data/items.csv").parse_all()

# 访问数据
var sword_name: String = items.get_string(0, "display_name")
var sword_price: int = items.get_int(0, "price")
var is_stackable: bool = items.get_bool(0, "stackable")

# 遍历所有行
for i in range(items.get_row_count()):
    var item_name := items.get_string(i, "display_name")
    var item_price := items.get_int(i, "price")
    print("物品: %s, 价格: %d" % [item_name, item_price])

# 查找数据
var sword_item := items.find_row("id", "sword")
if not sword_item.is_empty():
    print("找到剑: ", sword_item.display_name)

var all_rare_items := items.find_rows("rarity", "rare")
print("稀有物品数量: ", all_rare_items.size())

# 统计信息
print(items.get_statistics())
if items.has_errors():
    for error in items.get_errors():
        print("错误: ", error)
```

---

### CSVSchema - Schema 定义

定义 CSV 数据模式和验证规则，继承自 `Resource`。

#### 属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `field_definitions` | `Dictionary` | 字段定义字典（字段名 -> CSVFieldDefinition） |
| `has_header` | `bool` | 是否包含表头 |
| `delimiter` | `String` | 分隔符（默认为逗号） |

#### 方法

##### 字段管理

| 方法 | 签名 | 说明 |
|------|------|------|
| `add_field` | `(field_name: StringName, field_type: FieldType = TYPE_STRING) -> CSVFieldDefinition` | 添加字段定义 |
| `get_field_definition` | `(field_name: StringName) -> CSVFieldDefinition` | 获取字段定义 |
| `get_field_names` | `() -> Array` | 获取所有字段名 |
| `has_field` | `(field_name: StringName) -> bool` | 检查是否包含字段 |
| `get_field_count` | `() -> int` | 获取字段数量 |

##### 约束查询

| 方法 | 签名 | 说明 |
|------|------|------|
| `get_required_fields` | `() -> Array` | 获取必需字段列表 |
| `get_unique_fields` | `() -> Array` | 获取唯一字段列表 |

##### 表头验证

| 方法 | 签名 | 说明 |
|------|------|------|
| `validate_header` | `(header_row: PackedStringArray) -> Array[String]` | 验证表头 |
| `validate_row` | `(row_data: Dictionary, row_index: int) -> Array[String]` | 验证行数据 |

##### 索引映射

| 方法 | 签名 | 说明 |
|------|------|------|
| `get_header_indices` | `(header_row: PackedStringArray) -> Dictionary` | 获取字段索引映射 |

#### 使用示例

```gdscript
# 创建 Schema
var schema := CSVSchema.new()

# 定义字段
schema.add_field("id", CSVFieldDefinition.FieldType.TYPE_STRING_NAME)
    .with_required(true)
    .with_unique(true)

schema.add_field("price", CSVFieldDefinition.FieldType.TYPE_INT)
    .with_required(true)
    .with_range(0, 10000)
    .with_default(0)

schema.add_field("rarity", CSVFieldDefinition.FieldType.TYPE_STRING)
    .with_enum(["common", "rare", "epic", "legendary"])

schema.add_field("texture", CSVFieldDefinition.FieldType.TYPE_TEXTURE)
    .with_resource_base_path("res://assets/textures/")

# 使用 Schema 加载数据
var items := CSVLoader.new()
    .load_file("res://data/items.csv")
    .with_schema(schema)
    .parse_all()

if items.has_errors():
    for error in items.get_errors():
        print("验证错误: ", error)

# 保存 Schema 为资源文件
ResourceSaver.save(schema, "res://data/schemas/items_schema.tres")

# 加载已保存的 Schema
var loaded_schema: CSVSchema = load("res://data/schemas/items_schema.tres")
```

---

### CSVFieldDefinition - 字段定义

定义单个字段的类型和验证规则。

#### FieldType 枚举

| 值 | 名称 | 说明 |
|----|------|------|
| 0 | TYPE_STRING | 字符串 |
| 1 | TYPE_INT | 整数 |
| 2 | TYPE_FLOAT | 浮点数 |
| 3 | TYPE_BOOL | 布尔 |
| 4 | TYPE_STRING_NAME | StringName |
| 5 | TYPE_JSON | JSON (Dictionary 或 Array) |
| 6 | TYPE_ARRAY | 数组（逗号分隔） |
| 7 | TYPE_TEXTURE | Texture2D 资源 |
| 8 | TYPE_SCENE | PackedScene 资源 |
| 9 | TYPE_RESOURCE | 通用 Resource |

#### 属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `field_name` | `StringName` | 字段名称 |
| `type` | `FieldType` | 字段类型 |
| `default_value` | `Variant` | 默认值 |
| `required` | `bool` | 是否必需 |
| `min_value` | `Variant` | 最小值 |
| `max_value` | `Variant` | 最大值 |
| `enum_values` | `Array` | 枚举值列表 |
| `unique` | `bool` | 是否唯一 |
| `resource_base_path` | `String` | 资源基础路径 |
| `description` | `String` | 字段描述 |

#### 方法

##### 链式配置方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `with_type` | `(type: FieldType) -> CSVFieldDefinition` | 设置字段类型 |
| `with_default` | `(default_value: Variant) -> CSVFieldDefinition` | 设置默认值 |
| `with_required` | `(required: bool = true) -> CSVFieldDefinition` | 设置是否必需 |
| `with_range` | `(min: Variant, max: Variant) -> CSVFieldDefinition` | 设置范围约束 |
| `with_enum` | `(enum_values: Array) -> CSVFieldDefinition` | 设置枚举值 |
| `with_unique` | `(unique: bool = true) -> CSVFieldDefinition` | 设置是否唯一 |
| `with_resource_base_path` | `(path: String) -> CSVFieldDefinition` | 设置资源路径 |
| `with_description` | `(desc: String) -> CSVFieldDefinition` | 设置描述 |

##### 验证方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `validate_value` | `(value: Variant, row_index: int) -> bool` | 验证值是否符合定义 |
| `get_validation_error` | `(value: Variant, row_index: int) -> String` | 获取验证错误信息 |
| `is_value_empty` | `(value: Variant) -> bool` | 判断值是否为空 |
| `get_type_default` | `() -> Variant` | 获取类型的默认值 |

#### 使用示例

```gdscript
# 创建字段定义
var field := CSVFieldDefinition.new(
    "price",
    CSVFieldDefinition.FieldType.TYPE_INT
)

# 链式配置
field
    .with_required(true)
    .with_range(0, 10000)
    .with_default(100)
    .with_description("物品价格，单位：金币")

# 验证值
var is_valid := field.validate_value(500, 1)
if not is_valid:
    print(field.get_validation_error(500, 1))

# 在 Schema 中使用
var schema := CSVSchema.new()
schema.add_field("name", CSVFieldDefinition.FieldType.TYPE_STRING)
    .with_required(true)
    .with_unique(true)

schema.add_field("price", CSVFieldDefinition.FieldType.TYPE_INT)
    .with_range(0, 10000)
    .with_default(0)
```

---

### CSVStreamReaderGD - 流式读取器 (GDScript)

GDScript 封装的流式读取器，用于逐行处理大型 CSV 文件。

#### 方法

##### 核心方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `has_next` | `() -> bool` | 检查是否有下一行 |
| `next` | `() -> Dictionary` | 读取下一行 |
| `close` | `()` | 关闭文件 |
| `get_headers` | `() -> PackedStringArray` | 获取表头 |
| `get_current_line_index` | `() -> int` | 获取当前行索引 |

##### 配置方法

| 方法 | 签名 | 说明 |
|------|------|------|
| `set_field_type` | `(field_name: StringName, type: FieldType)` | 设置字段类型 |
| `set_default_value` | `(field_name: StringName, default_value: Variant)` | 设置默认值 |
| `set_schema` | `(schema: CSVSchema)` | 设置 Schema |

##### 错误处理

| 方法 | 签名 | 说明 |
|------|------|------|
| `get_errors` | `() -> Array[String]` | 获取错误信息 |
| `get_warnings` | `() -> Array[String]` | 获取警告信息 |
| `has_errors` | `() -> bool` | 是否有错误 |
| `has_warnings` | `() -> bool` | 是否有警告 |

#### 使用示例

```gdscript
# 创建流式读取器
var reader := CSVLoader.new()
    .load_file("res://data/large_file.csv")
    .with_type("price", CSVFieldDefinition.FieldType.TYPE_INT)
    .stream()

# 读取数据
var count := 0
var total_price := 0

while reader.has_next():
    var row := reader.next()
    if row.is_empty():
        continue

    var price: int = row.get("price", 0)
    total_price += price
    count += 1

    # 每处理 1000 行输出一次进度
    if count % 1000 == 0:
        print("已处理 %d 行" % count)

    # 如果需要暂停
    if count >= 5000:
        break

# 关闭读取器
reader.close()

print("共处理 %d 行，总价: %d" % [count, total_price])

# 错误处理
if reader.has_errors():
    for error in reader.get_errors():
        print("错误: ", error)
```

---

## 综合使用示例

### 示例 1：完整的数据加载和查询流程

```gdscript
func load_and_query_items() -> void:
    # 创建 Schema
    var schema := CSVSchema.new()
    schema.add_field("id", CSVFieldDefinition.FieldType.TYPE_STRING_NAME)
        .with_required(true)
        .with_unique(true)

    schema.add_field("price", CSVFieldDefinition.FieldType.TYPE_INT)
        .with_range(0, 10000)
        .with_default(0)

    schema.add_field("stackable", CSVFieldDefinition.FieldType.TYPE_BOOL)
        .with_default(false)

    schema.add_field("rarity", CSVFieldDefinition.FieldType.TYPE_STRING)
        .with_enum(["common", "rare", "epic", "legendary"])

    # 加载数据
    var items := CSVLoader.new()
        .load_file("res://data/items.csv")
        .with_schema(schema)
        .parse_all()

    # 错误检查
    if items.has_errors():
        for error in items.get_errors():
            print("加载错误: ", error)
        return

    # 查询稀有物品
    var rare_items := items.find_rows("rarity", "rare")
    print("稀有物品数量: %d" % rare_items.size())

    # 统计总价格
    var total_price := 0
    for i in range(items.get_row_count()):
        total_price += items.get_int(i, "price")
    print("总价格: %d" % total_price)

    # 查找特定物品
    var sword := items.find_row("id", "legendary_sword")
    if not sword.is_empty():
        print("传说之剑: %s, 价格: %d" % [sword.display_name, sword.price])
```

### 示例 2：使用搜索引擎

```gdscript
func search_and_replace() -> void:
    # 解析 CSV
    var parser := CSVParser.new()
    var rows := parser.ParseFromFile("res://data/products.csv")

    # 创建搜索引擎
    var engine := CSVSearchEngine.new()

    # 搜索包含 "old" 的产品
    var results := engine.Search(rows, "old", false, CSVSearchEngine.MATCH_CONTAINS)

    print("找到 %d 个包含 'old' 的产品，耗时 %.2f ms" % [
        engine.GetMatchCount(),
        engine.GetSearchTime()
    ])

    # 替换文本
    var new_rows := engine.Replace(rows, "old_product", "new_product")

    # 过滤价格大于 1000 的产品
    var price_column := 2  # 价格列索引
    var all_rows := parser.GetRows()

    # 使用表格数据管理器
    var table := CSVTableData.new()
    table.Initialize(new_rows, parser.GetHeader())

    # 查找并修改数据
    for i in range(table.GetRowCount()):
        var price := table.GetCellValue(i, price_column).to_int()
        if price > 1000:
            table.SetCellValue(i, 1, "Premium")  # 设置为 Premium 等级
```

### 示例 3：流式处理大文件

```gdscript
func process_large_csv() -> void:
    # 创建 Schema
    var schema := CSVSchema.new()
    schema.add_field("user_id", CSVFieldDefinition.FieldType.TYPE_STRING_NAME)
        .with_unique(true)
    schema.add_field("level", CSVFieldDefinition.FieldType.TYPE_INT)
        .with_range(1, 100)
    schema.add_field("exp", CSVFieldDefinition.FieldType.TYPE_INT)

    # 创建流式读取器
    var reader := CSVLoader.new()
        .load_file("res://data/users_large.csv")
        .with_schema(schema)
        .stream()

    # 统计数据
    var stats := {
        total_users = 0,
        level_1_10 = 0,
        level_11_50 = 0,
        level_51_100 = 0,
        total_exp = 0
    }

    # 逐行处理
    while reader.has_next():
        var user := reader.next()
        if user.is_empty():
            continue

        var level: int = user.get("level", 1)
        var exp: int = user.get("exp", 0)

        stats.total_users += 1
        stats.total_exp += exp

        if level <= 10:
            stats.level_1_10 += 1
        elif level <= 50:
            stats.level_11_50 += 1
        else:
            stats.level_51_100 += 1

    reader.close()

    # 输出统计结果
    print("用户统计:")
    print("  总用户数: %d" % stats.total_users)
    print("  1-10级: %d" % stats.level_1_10)
    print("  11-50级: %d" % stats.level_11_50)
    print("  51-100级: %d" % stats.level_51_100)
    print("  总经验值: %d" % stats.total_exp)

    # 检查错误
    if reader.has_errors():
        print("处理过程中发现错误:")
        for error in reader.get_errors():
            print("  - %s" % error)
```

### 示例 4：使用类型注解解析器

```gdscript
func parse_annotated_csv() -> void:
    # 带类型注解的 CSV 内容
    var csv_content := """
*id:int[1..9999],name:string=default_name,price:float[0.0..9999.0],rarity:enum(common,rare,epic),stock:bool
1,Sword,99.99,rare,true
2,Shield,149.99,rare,true
3,Potion,19.99,common,false
4,Dragon Armor,999.99,epic,false
"""

    # 解析 CSV
    var parser := CSVParser.new()
    var rows := parser.ParseFromString(csv_content)
    var header := parser.GetHeader()

    # 使用类型注解解析器
    var annotation_parser := CSVTypeAnnotationParser.new()
    var clean_header := annotation_parser.ParseHeader(header)

    print("字段类型信息:")
    for field_name in clean_header:
        var type := annotation_parser.GetFieldType(field_name)
        var is_required := annotation_parser.IsFieldRequired(field_name)
        var default_val := annotation_parser.GetFieldDefault(field_name)
        var range_val := annotation_parser.GetFieldRange(field_name)

        print("  %s: type=%s, required=%s, default=%s, range=%s" % [
            field_name, type, is_required, default_val, range_val
        ])

    # 创建类型转换器
    var converter := CSVTypeConverter.new()

    # 处理每行数据
    for i in range(rows.size()):
        var row := rows[i]
        print("\n第 %d 行:" % (i + 1))

        for j in range(row.size()):
            var field_name := clean_header[j]
            var type := annotation_parser.GetFieldType(field_name)
            var range_val := annotation_parser.GetFieldRange(field_name)
            var enum_vals := annotation_parser.GetFieldEnumValues(field_name)

            var value_string := row[j]

            # 根据类型转换值
            var converted_value: Variant
            match type:
                "int":
                    converted_value = converter.ToInt(value_string, range_val)
                "float":
                    converted_value = converter.ToFloat(value_string, range_val)
                "bool":
                    converted_value = converter.ToBool(value_string)
                "enum":
                    converted_value = converter.ToEnum(value_string, enum_vals)
                _:
                    converted_value = value_string

            print("  %s = %s" % [field_name, converted_value])
```

---

## 错误处理最佳实践

```gdscript
class_name GodotSVHandler extends Node

## 安全的 CSV 加载函数
func load_csv_safely(file_path: String, schema: CSVSchema = null) -> CSVResource:
    # 1. 检查文件是否存在
    if not FileAccess.file_exists(file_path):
        push_error("文件不存在: " + file_path)
        return null

    # 2. 加载数据
    var data := CSVLoader.new()
        .load_file(file_path)
        .with_schema(schema)
        .parse_all()

    # 3. 检查加载错误
    if data == null or data.has_errors():
        push_error("CSV 加载失败:")
        for error in data.get_errors():
            push_error("  " + error)
        return null

    # 4. 检查数据完整性
    if data.get_row_count() == 0:
        push_warning("CSV 文件为空或没有数据行")

    # 5. 检查警告
    if data.has_warnings():
        for warning in data.get_warnings():
            print("CSV 警告: " + warning)

    return data


## 带重试的文件加载
func load_csv_with_retry(file_path: String, max_retries: int = 3) -> CSVResource:
    for attempt in range(max_retries):
        var data := CSVLoader.new().load_file(file_path).parse_all()

        if not data.has_errors():
            return data

        print("加载失败（尝试 %d/%d）: %s" % [attempt + 1, max_retries, file_path])

        # 清除缓存重试
        CSVLoader.clear_cache()
        await get_tree().create_timer(0.5).timeout

    push_error("多次重试后仍无法加载: " + file_path)
    return null
```

---

## 性能优化建议

1. **使用缓存**: 对于频繁访问的 CSV 文件，`CSVLoader` 会自动缓存
2. **流式读取大文件**: 文件超过 10MB 时使用 `stream()` 方法
3. **预定义 Schema**: 将 Schema 保存为资源文件，避免运行时创建
4. **批量操作**: 使用 `CSVTableData.BatchSetCells()` 而非多次单独设置
5. **限制搜索列**: 使用 `CSVSearchEngine` 时指定列索引，避免全表搜索

---

## 版本信息

- **插件版本**: 1.0.0
- **Godot 版本要求**: 4.5+
- **最低兼容性**: `compatibility_minimum = "4.5"` (在 `.gdextension` 文件中)

---

**最后更新**: 2026-01-12
