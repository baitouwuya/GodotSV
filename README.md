# GodotSV

Godot Data Separated Values - 高性能表格数据处理插件

## 特性

- 📊 **多格式支持**：.gdsv, .csv, .tsv, .tab, .psv, .asc
- 🔗 **链式调用 API**：简洁易用的流式接口
- ⚡ **C++ 核心实现**：高性能解析引擎
- 🎯 **丰富的类型系统**：int, float, bool, StringName, JSON, Array, Resource 等
- 📝 **内置可视化编辑器**：直观的表格编辑界面
- ✅ **Schema 验证**：完整的数据验证支持
- 🌊 **流式读取**：处理大文件内存友好

## 安装

### 前置要求

- Godot 4.5+
- 支持的平台：Windows, Linux, macOS

### 安装步骤

1. 下载本插件
2. 将 `GodotSV` 文件夹复制到你的 Godot 项目的 `addons/` 目录下：
   ```
   your_project/
   └── addons/
       └── GodotSV/
   ```
3. 在 Godot 编辑器中打开 `项目 > 项目设置 > 插件`
4. 找到 `GodotSV` 并点击**启用**

## 快速开始

### 基础用法

```gdscript
# 加载 GDSV 文件
var loader = GDSVLoader.new()

# 链式调用配置
var resource = loader.load_file("res://data/characters.gdsv")
    .with_header(true)
    .with_delimiter("\t")
    .parse_all()

# 访问数据
if not resource.has_errors():
    # 获取表头
    print("表头: ", resource.headers)

    # 获取第一行数据
    var first_row = resource.rows[0]
    print("第一行: ", first_row)

    # 使用类型安全的访问方法
    var id = resource.get_int(0, "id")
    var name = resource.get_string(0, "name")
    var active = resource.get_bool(0, "active")

    print("ID: %d, 名称: %s, 活动: %s" % [id, name, active])
else:
    print("错误: ", resource.get_errors())
```

### GDSV 格式说明

GDSV 文件使用 Tab 分隔符，支持类型注解：

```
id:int	name:string	active:bool=false	health:float=100.0
1	Alice	true	85.5
2	Bob	false	72.3
3	Charlie	true	90.0
```

**类型注解语法**：
- `field_name:type` - 指定类型
- `field_name:type=default_value` - 指定类型和默认值

**支持的类型**：
- `int` - 整数
- `float` - 浮点数
- `bool` - 布尔值（true/false）
- `string` - 字符串
- `string_name` - StringName 类型
- `json` - JSON 对象解析
- `array` - 数组（逗号分隔）

### 从 CSV 导入

```gdscript
# 加载 CSV 文件（自动检测分隔符）
var loader = GDSVLoader.new()
var resource = loader.load_file("res://data/users.csv")
    .with_header(true)
    .parse_all()
```

## API 参考

### GDSVLoader - 高级加载器

链式配置方法：

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `load_file` | `path: String` | `GDSVLoader` | 加载文件，支持链式调用 |
| `with_header` | `has_header: bool` | `GDSVLoader` | 设置文件是否有表头 |
| `with_delimiter` | `delimiter: String` | `GDSVLoader` | 设置分隔符（默认自动检测） |
| `with_type` | `field_name: StringName, type: FieldType` | `GDSVLoader` | 指定字段类型 |
| `with_default` | `field_name: StringName, value: Variant` | `GDSVLoader` | 设置字段默认值 |
| `with_schema` | `schema: GDSVSchema` | `GDSVLoader` | 应用 Schema 验证 |
| `parse_all` | - | `GDSVResource` | 解析全部数据 |
| `stream` | - | `GDSVStreamReaderGD` | 创建流式读取器 |
| `has_errors` | - | `bool` | 是否有错误 |
| `get_errors` | - | `Array[String]` | 获取错误信息 |

### GDSVResource - 数据资源

数据访问方法：

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `get_value` | `row_index: int, field_name: StringName` | `Variant` | 获取指定单元格值 |
| `get_int` | `row_index: int, field_name: StringName, default: int = 0` | `int` | 获取整数 |
| `get_float` | `row_index: int, field_name: StringName, default: float = 0.0` | `float` | 获取浮点数 |
| `get_bool` | `row_index: int, field_name: StringName, default: bool = false` | `bool` | 获取布尔值 |
| `get_string` | `row_index: int, field_name: StringName, default: String = ""` | `String` | 获取字符串 |
| `find_rows` | `field_name: StringName, value: Variant` | `Array[Dictionary]` | 查找匹配的所有行 |
| `find_row` | `field_name: StringName, value: Variant` | `Dictionary` | 查找匹配的首行 |
| `clear` | - | `void` | 清空数据 |
| `get_statistics` | - | `String` | 获取统计信息 |

导出属性：

| 属性名 | 类型 | 说明 |
|--------|------|------|
| `headers` | `PackedStringArray` | 表头 |
| `rows` | `Array[Dictionary]` | 所有数据行 |
| `raw_data` | `Array[PackedStringArray]` | 原始字符串数据 |
| `errors` | `Array[String]` | 错误信息 |
| `warnings` | `Array[String]` | 警告信息 |
| `total_rows` | `int` | 总行数 |
| `successful_rows` | `int` | 成功解析的行数 |
| `failed_rows` | `int` | 失败的行数 |
| `has_header` | `bool` | 是否有表头 |
| `delimiter` | `String` | 分隔符 |
| `source_gdsv_path` | `String` | 源文件路径 |

### GDSVSchema - Schema 定义

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `add_field` | `name: StringName, type: FieldType` | `GDSVFieldDefinition` | 添加字段定义 |
| `validate_header` | `header: PackedStringArray` | `Array[String]` | 验证表头，返回错误信息 |
| `validate_row` | `data: Dictionary, index: int` | `Array[String]` | 验证单行数据 |
| `get_header_indices` | `header: PackedStringArray` | `Dictionary` | 获取表头索引映射 |

### GDSVFieldDefinition - 字段定义

FieldType 枚举：

| 值 | 说明 |
|----|------|
| `TYPE_STRING` | 字符串类型 |
| `TYPE_INT` | 整数类型 |
| `TYPE_FLOAT` | 浮点数类型 |
| `TYPE_BOOL` | 布尔值类型 |
| `TYPE_STRING_NAME` | StringName 类型 |
| `TYPE_JSON` | JSON 对象 |
| `TYPE_ARRAY` | 数组 |
| `TYPE_TEXTURE` | Texture 资源 |
| `TYPE_SCENE` | Scene 资源 |
| `TYPE_RESOURCE` | 自定义资源 |

链式配置方法：

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `with_type` | `type: FieldType` | `GDSVFieldDefinition` | 设置字段类型 |
| `with_default` | `value: Variant` | `GDSVFieldDefinition` | 设置默认值 |
| `with_required` | `required: bool = true` | `GDSVFieldDefinition` | 设置是否必需 |
| `with_range` | `min: Variant, max: Variant` | `GDSVFieldDefinition` | 设置数值范围 |
| `with_enum` | `values: Array` | `GDSVFieldDefinition` | 设置枚举值 |
| `with_unique` | `unique: bool = true` | `GDSVFieldDefinition` | 设置是否唯一 |
| `validate_value` | `value: Variant, index: int` | `bool` | 验证单个值 |

### GDSVStreamReaderGD - 流式读取器

| 方法 | 参数 | 返回值 | 说明 |
|------|------|--------|------|
| `next` | - | `Dictionary` | 读取下一行数据 |
| `has_next` | - | `bool` | 是否还有下一行 |
| `set_field_type` | `field_name: StringName, type: FieldType` | `void` | 设置字段类型 |
| `set_default_value` | `field_name: StringName, value: Variant` | `void` | 设置默认值 |
| `set_schema` | `schema: GDSVSchema` | `void` | 设置 Schema |
| `get_headers` | - | `PackedStringArray` | 获取表头 |

完整 API 文档请查看 [API_REFERENCE.md](./API_REFERENCE.md)

## 使用示例

### 示例 1：基本数据加载

```gdscript
extends Node

func _ready():
    # 创建加载器
    var loader = GDSVLoader.new()

    # 加载并解析文件
    var resource = loader.load_file("res://data/items.gdsv")
        .with_header(true)
        .parse_all()

    # 检查错误
    if resource.has_errors():
        print("解析错误:")
        for error in resource.get_errors():
            print("  - ", error)
        return

    # 遍历数据
    for i in resource.rows.size():
        var item = resource.get_value(i, "name")
        var price = resource.get_float(i, "price")
        print("商品: %s, 价格: %.2f" % [item, price])
```

### 示例 2：使用 Schema 验证

```gdscript
extends Node

func _ready():
    # 创建 Schema
    var schema = GDSVSchema.new()

    # 定义字段
    schema.add_field("id", GDSVFieldDefinition.FieldType.TYPE_INT)
        .with_required(true)
        .with_unique(true)

    schema.add_field("name", GDSVFieldDefinition.FieldType.TYPE_STRING)
        .with_required(true)

    schema.add_field("age", GDSVFieldDefinition.FieldType.TYPE_INT)
        .with_range(0, 120)
        .with_default(18)

    schema.add_field("role", GDSVFieldDefinition.FieldType.TYPE_STRING)
        .with_enum(["warrior", "mage", "archer"])
        .with_default("warrior")

    # 使用 Schema 加载数据
    var loader = GDSVLoader.new()
    var resource = loader.load_file("res://data/players.gdsv")
        .with_header(true)
        .with_schema(schema)
        .parse_all()

    # 检查验证结果
    if resource.has_errors():
        print("验证失败:")
        for error in resource.get_errors():
            print("  - ", error)
    else:
        print("验证通过！共 %d 条记录" % resource.successful_rows)
```

### 示例 3：流式处理大文件

```gdscript
extends Node

func process_large_file():
    var loader = GDSVLoader.new()

    # 创建流式读取器
    var stream = loader.load_file("res://data/large_dataset.gdsv")
        .with_header(true)
        .stream()

    # 设置字段类型（可选）
    stream.set_field_type("id", GDSVFieldDefinition.FieldType.TYPE_INT)
    stream.set_field_type("score", GDSVFieldDefinition.FieldType.TYPE_FLOAT)
    stream.set_field_type("active", GDSVFieldDefinition.FieldType.TYPE_BOOL)

    # 逐行处理
    var processed_count = 0
    var total_score = 0.0

    while stream.has_next():
        var row = stream.next()
        var score = row.get("score", 0.0)
        total_score += score
        processed_count += 1

        # 防止长时间阻塞
        if processed_count % 100 == 0:
            await get_tree().process_frame

    print("处理完成: %d 条记录" % processed_count)
    print("平均分数: %.2f" % (total_score / processed_count))
```

### 示例 4：数据查询和过滤

```gdscript
extends Node

func query_data():
    var loader = GDSVLoader.new()
    var resource = loader.load_file("res://data/products.gdsv")
        .with_header(true)
        .parse_all()

    # 查找特定条件的行
    var active_products = resource.find_rows("active", true)

    print("活跃商品数量: %d" % active_products.size())

    # 获取统计信息
    var stats = resource.get_statistics()
    print("统计信息: ", stats)
```

### 示例 5：带默认值和类型转换

```gdscript
extends Node

func load_with_defaults():
    var loader = GDSVLoader.new()

    # 设置字段类型和默认值
    loader.with_type("id", GDSVFieldDefinition.FieldType.TYPE_INT)
    loader.with_type("health", GDSVFieldDefinition.FieldType.TYPE_FLOAT)
    loader.with_type("is_active", GDSVFieldDefinition.FieldType.TYPE_BOOL)
    loader.with_default("health", 100.0)
    loader.with_default("is_active", false)

    var resource = loader.load_file("res://data/characters.gdsv")
        .with_header(true)
        .parse_all()

    # 使用类型安全的访问方法
    for i in resource.rows.size():
        var health = resource.get_float(i, "health")
        var is_active = resource.get_bool(i, "is_active")
        print("角色 %d: 生命值 %.1f, 活跃: %s" % [i, health, is_active])
```

### 示例 6：从 CSV 导入并转换为 GDSV

```gdscript
extends Node

func csv_to_gdsv(csv_path: String, gdsv_path: String):
    # 加载 CSV
    var loader = GDSVLoader.new()
    var resource = loader.load_file(csv_path)
        .with_header(true)
        .parse_all()

    if resource.has_errors():
        print("CSV 解析错误: ", resource.get_errors())
        return false

    # 创建输出内容
    var lines = []
    lines.append("\t".join(resource.headers))

    for row_data in resource.raw_data:
        lines.append("\t".join(row_data))

    # 写入 GDSV 文件
    var file = FileAccess.open(gdsv_path, FileAccess.WRITE)
    if file:
        for line in lines:
            file.store_line(line)
        file.close()
        print("转换成功: %s" % gdsv_path)
        return true
    else:
        print("无法写入文件: %s" % gdsv_path)
        return false
```

## 编辑器集成

### 打开 GDSV 文件

在 Godot 编辑器中：
1. 在文件系统面板中双击 `.gdsv` 文件
2. 文件将在内置编辑器中打开
3. 支持直观的数据编辑、查看和验证

### 导入 CSV 为 GDSV

通过统一导入插件：
1. 将 `.csv` 文件拖入项目
2. Godot 会自动识别并配置导入设置
3. 在导入面板中可以指定：
   - 是否有表头
   - 分隔符（自动检测）
   - Schema 路径（可选）

### Schema 管理

1. 创建 Schema 资源：在编辑器中新建 `GDSVSchema` 资源
2. 添加字段定义并配置类型、验证规则
3. 在加载器中使用：`loader.with_schema(schema)`
4. 编辑器界面会实时显示验证结果

### 数据编辑器功能

- **查看数据**：表格视图，支持滚动和分页
- **编辑单元格**：双击单元格进行编辑
- **撤销/重做**：支持编辑历史
- **搜索和替换**：快速定位和修改数据
- **验证**：实时显示验证错误和警告
- **统计**：查看数据统计信息

## 最佳实践

### 1. 使用 GDSV 格式

对于新项目，推荐使用 GDSV 格式：
- 使用 Tab 分隔符（兼容性最好）
- 在表头行使用类型注解
- 提供合理的默认值

```
id:int	name:string	tags:array	health:float=100
1	Player	["hero","main"]	150
2	Enemy	["monster"]	50
```

### 2. 使用 Schema 验证

对于关键数据，始终使用 Schema：
```gdscript
var schema = GDSVSchema.new()
schema.add_field("id", GDSVFieldDefinition.FieldType.TYPE_INT).with_required(true).with_unique(true)
schema.add_field("name", GDSVFieldDefinition.FieldType.TYPE_STRING).with_required(true)

var resource = loader.with_schema(schema).parse_all()
```

### 3. 大文件使用流式读取

对于超过 1000 行的文件，使用流式读取：
```gdscript
var stream = loader.load_file(path).with_header(true).stream()
while stream.has_next():
    var row = stream.next()
    # 处理行
    if process_count % 100 == 0:
        await get_tree().process_frame
```

### 4. 错误处理

始终检查错误：
```gdscript
if resource.has_errors():
    push_error("数据加载失败: " + str(resource.get_errors()))
    return

if resource.has_warnings():
    for warning in resource.get_warnings():
        print("警告: ", warning)
```

### 5. 类型安全访问

使用类型安全的访问方法：
```gdscript
# 推荐：类型安全方式
var id = resource.get_int(row_index, "id", 0)
var active = resource.get_bool(row_index, "active", false)

# 避免直接使用 get_value（可能返回错误类型）
var value = resource.get_value(row_index, "id")  # 可能返回字符串 "123"
```

### 6. 资源管理

`GDSVResource` 继承自 `Resource`，可以保存到场景中：
```gdscript
# 在 Inspector 中保存加载的数据
@export var characters_data: GDSVResource

# 或动态保存
ResourceSaver.save(resource, "res://data/characters_resource.tres")
```

## 故障排查

### 问题 1：找不到插件

**现象**：Godot 提示找不到 GodotSV 插件

**解决方案**：
1. 确认插件已启用（项目设置 > 插件）
2. 检查 `addons/GodotSV/plugin.cfg` 存在
3. 确认 GDExtension 库与平台的架构匹配

### 问题 2：数据解析失败

**现象**：`parse_all()` 返回错误信息

**解决方案**：
1. 检查文件路径是否正确
2. 确认文件格式（分隔符、编码）
3. 查看错误信息，定位问题行
4. 尝试使用 `with_header(false)` 如果文件没有表头

### 问题 3：类型转换错误

**现象**：`get_int()` 或 `get_float()` 返回默认值

**解决方案**：
1. 确认数据内容符合类型要求
2. 使用类型注解或 `with_type()` 指定类型
3. 检查数据中是否有空值，使用默认值参数

### 问题 4：大文件内存不足

**现象**：处理大文件时内存占用过高

**解决方案**：
1. 使用 `stream()` 方法进行流式读取
2. 避免将所有数据存储在单个资源中
3. 分批处理数据，每次处理一部分

### 问题 5：编辑器中文件无法打开

**现象**：双击 .gdsv 文件没有反应

**解决方案**：
1. 确认插件已启用
2. 检查编辑器日志是否有错误信息
3. 尝试重启 Godot 编辑器
4. 确认导入配置正确

## 版本兼容性

| Godot 版本 | 支持状态 | 备注 |
|------------|----------|------|
| 4.5+ | ✅ 完全支持 | 推荐版本 |
| 4.4 | ⚠️ 部分支持 | 可能需要兼容性补丁 |
| 4.3 及以下 | ❌ 不支持 | 需要升级 Godot |

**支持平台**：
- Windows (x86_64)
- Linux (x86_64)
- macOS (universal, arm64, x86_64)

## 许可证

MIT License

## 贡献

欢迎 contributions！请通过以下方式参与：

1. 报告问题：在项目仓库提交 Issue
2. 提供改进：提交 Pull Request
3. 分享使用经验：在项目讨论区交流

## 技术支持

- 📖 完整 API 文档: [API_REFERENCE.md](./API_REFERENCE.md)
- 📝 迁移指南: [MIGRATION.md](../../MIGRATION.md)

---

**GodotSV** - 让 Godot 的表格数据处理更简单、更高效！
