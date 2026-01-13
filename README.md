# GodotSV

通用 CSV 文件处理和导入系统，为 Godot 提供强大的 CSV 数据解析、类型转换、验证和资源加载功能。

## 特性

- **灵活的 CSV 解析**：支持 RFC 4180 标准，处理引号、转义字符和多行字段
- **类型安全**：自动类型转换（int、float、bool、StringName、JSON、Array、资源类型）
- **Schema 验证**：定义数据模式，验证字段类型、范围、枚举值和唯一性约束
- **资源加载**：自动加载 Texture2D、PackedScene 等资源
- **默认值支持**：为缺失或空字段提供默认值
- **缓存机制**：LRU 缓存策略，避免重复读取
- **流式读取**：支持大文件的逐行读取，减少内存占用
- **Godot 集成**：EditorImportPlugin 支持，CSV 文件可作为资源导入
- **链式调用**：Builder 模式 API，简洁优雅的配置方式
- **错误处理**：详细的错误信息和日志记录

## 安装

将 `addons/GodotSV` 文件夹复制到您的 Godot 项目的 `addons` 目录下，然后在项目设置中启用 "CSV Handler" 插件。

## 快速开始

### 基础用法

```gdscript
# 示例 CSV 文件 (items.csv)
# id,display_name,price,stackable
# sword,长剑,100,true
# shield,盾牌,150,true
# potion,药水,50,false

# 加载并解析 CSV 文件
var loader := CSVLoader.new()
var data: CSVResource = loader.load_file("res://data/items.csv").parse_all()

# 访问数据
for item in data.rows:
    print("物品ID: %s" % item.id)
    print("物品名称: %s" % item.display_name)
    print("价格: %d" % item.price)
    print("可堆叠: %s" % item.stackable)
```

### 使用类型转换

```gdscript
var items := CSVLoader.new()
    .load_file("res://data/items.csv")
    .with_type("price", CSVFieldDefinition.FieldType.TYPE_INT)
    .with_type("stackable", CSVFieldDefinition.FieldType.TYPE_BOOL)
    .parse_all()

# 数据已自动转换类型
var price: int = items.rows[0].price
var is_stackable: bool = items.rows[0].stackable
```

### 使用默认值

```gdscript
var items := CSVLoader.new()
    .load_file("res://data/items.csv")
    .with_type("price", CSVFieldDefinition.FieldType.TYPE_INT)
    .with_default("price", 0)  # 价格字段为空时使用默认值 0
    .with_default("stackable", true)  # 可堆叠字段为空时默认为 true
    .parse_all()
```

### 使用 Schema 验证

```gdscript
# 创建 Schema 资源（在编辑器中或代码中）
var schema := CSVSchema.new()
schema.add_field("id", CSVFieldDefinition.FieldType.TYPE_STRING_NAME)
    .with_required(true)  # id 字段是必需的
    .with_unique(true)    # id 字段必须唯一

schema.add_field("price", CSVFieldDefinition.FieldType.TYPE_INT)
    .with_required(true)
    .with_range(0, 10000)  # 价格范围 0-10000

schema.add_field("rarity", CSVFieldDefinition.FieldType.TYPE_STRING)
    .with_enum(["common", "rare", "epic", "legendary"])  # 枚举值

# 使用 Schema 加载 CSV
var items := CSVLoader.new()
    .load_file("res://data/items.csv")
    .with_schema(schema)
    .parse_all()

# 检查错误
if items.has_errors():
    for error in items.get_errors():
        print("错误: %s" % error)
```

### 流式读取大文件

```gdscript
# 对于大文件，使用流式读取避免内存问题
var reader := CSVLoader.new()
    .load_file("res://data/large_data.csv")
    .stream()

while reader.has_next():
    var row := reader.next()
    # 处理每一行数据
    process_row(row)

reader.close()
```

### 使用资源导入系统

1. 将 CSV 文件放入项目目录
2. 在编辑器中选择 CSV 文件，在导入面板中配置：
   - 是否包含表头
   - 分隔符类型
   - 编码格式
   - Schema 资源（可选）
3. 导入后，使用 `load()` 或 `preload()` 直接加载资源

```gdscript
# 直接加载导入后的 CSV 资源
var items: CSVResource = preload("res://data/items.csv")

# 数据已解析，可直接使用
for item in items.rows:
    print("物品: %s" % item.display_name)
```

## API 参考

### CSVLoader

核心 CSV 加载器类，提供链式调用 API。

#### 方法

| 方法 | 说明 |
|------|------|
| `load_file(path: String) -> CSVLoader` | 加载 CSV 文件 |
| `with_header(has_header: bool) -> CSVLoader` | 设置是否包含表头 |
| `with_delimiter(delimiter: String) -> CSVLoader` | 设置分隔符 |
| `with_type(field_name: StringName, type: FieldType) -> CSVLoader` | 设置字段类型 |
| `with_default(field_name: StringName, default_value: Variant) -> CSVLoader` | 设置字段默认值 |
| `with_required_fields(fields: Array[StringName]) -> CSVLoader` | 设置必需字段 |
| `with_schema(schema: CSVSchema) -> CSVLoader` | 设置 Schema |
| `parse_all() -> CSVResource` | 解析所有数据 |
| `stream() -> CSVStreamReader` | 创建流式读取器 |
| `clear_cache()` | 清除缓存 |

### CSVResource

存储解析后的 CSV 数据。

#### 属性

| 属性 | 类型 | 说明 |
|------|------|------|
| `headers` | PackedStringArray | 表头行 |
| `rows` | Array[Dictionary] | 数据行 |
| `errors` | Array[String] | 错误信息 |
| `warnings` | Array[String] | 警告信息 |

#### 方法

| 方法 | 说明 |
|------|------|
| `get_value(row_index: int, field_name: StringName) -> Variant` | 获取字段值 |
| `get_int(row_index: int, field_name: StringName, default_value: int = 0) -> int` | 获取整数值 |
| `get_float(row_index: int, field_name: StringName, default_value: float = 0.0) -> float` | 获取浮点数值 |
| `get_bool(row_index: int, field_name: StringName, default_value: bool = false) -> bool` | 获取布尔值 |
| `get_string(row_index: int, field_name: StringName, default_value: String = "") -> String` | 获取字符串值 |
| `get_string_name(row_index: int, field_name: StringName, default_value: StringName = &"") -> StringName` | 获取 StringName 值 |
| `find_row(field_name: StringName, value: Variant) -> Dictionary` | 查找单行数据 |
| `find_rows(field_name: StringName, value: Variant) -> Array[Dictionary]` | 查找多行数据 |

### CSVSchema

定义 CSV 数据模式和验证规则。

#### 方法

| 方法 | 说明 |
|------|------|
| `add_field(field_name: StringName, field_type: FieldType) -> CSVFieldDefinition` | 添加字段定义 |
| `get_field_definition(field_name: StringName) -> CSVFieldDefinition` | 获取字段定义 |
| `validate_header(header_row: PackedStringArray) -> Array[String]` | 验证表头 |
| `validate_row(row_data: Dictionary, row_index: int) -> Array[String]` | 验证数据行 |

### CSVFieldDefinition

字段定义类。

#### 类型枚举

| 类型 | 说明 |
|------|------|
| `TYPE_STRING` | 字符串类型 |
| `TYPE_INT` | 整数类型 |
| `TYPE_FLOAT` | 浮点数类型 |
| `TYPE_BOOL` | 布尔类型 |
| `TYPE_STRING_NAME` | StringName 类型 |
| `TYPE_JSON` | JSON 类型（Dictionary 或 Array） |
| `TYPE_ARRAY` | 数组类型（逗号分隔） |
| `TYPE_TEXTURE` | Texture2D 资源类型 |
| `TYPE_SCENE` | PackedScene 资源类型 |
| `TYPE_RESOURCE` | 通用 Resource 类型 |

#### 方法

| 方法 | 说明 |
|------|------|
| `with_type(type: FieldType) -> CSVFieldDefinition` | 设置字段类型 |
| `with_default(default_value: Variant) -> CSVFieldDefinition` | 设置默认值 |
| `with_required(required: bool = true) -> CSVFieldDefinition` | 设置是否必需 |
| `with_range(min: Variant, max: Variant) -> CSVFieldDefinition` | 设置范围约束 |
| `with_enum(enum_values: Array) -> CSVFieldDefinition` | 设置枚举值 |
| `with_unique(unique: bool = true) -> CSVFieldDefinition` | 设置是否唯一 |

### CSVStreamReader

流式读取器，用于逐行读取大文件。

#### 方法

| 方法 | 说明 |
|------|------|
| `has_next() -> bool` | 检查是否有下一行 |
| `next() -> Dictionary` | 读取下一行 |
| `close()` | 关闭文件 |
| `get_headers() -> PackedStringArray` | 获取表头 |
| `get_errors() -> Array[String]` | 获取错误信息 |

## 使用示例

### 场景 1：物品定义系统

```gdscript
# items.csv
# id,display_name,description,price,rarity,icon_path
# sword,长剑,一把锋利的剑,100,rare,res://icons/sword.png
# shield,盾牌,坚固的盾牌,150,common,res://icons/shield.png

var loader := CSVLoader.new()
var items_data := loader.load_file("res://data/items.csv")
    .with_type("price", CSVFieldDefinition.FieldType.TYPE_INT)
    .with_type("icon_path", CSVFieldDefinition.FieldType.TYPE_TEXTURE)
    .with_schema(create_item_schema())
    .parse_all()

# 创建物品定义
for item_row in items_data.rows:
    var item_def := ItemDefinition.new()
    item_def.id = item_row.id
    item_def.display_name = item_row.display_name
    item_def.price = item_row.price
    item_def.icon = item_row.icon_path  # 自动加载为 Texture2D
    item_database.add_item(item_def)
```

### 场景 2：敌人配置

```gdscript
# enemies.csv
# id,name,hp,attack_damage,speed,sprite_path
# goblin,哥布林,50,10,100,res://sprites/goblin.png
# orc,兽人,100,20,80,res://sprites/orc.png

var enemies := CSVLoader.new()
    .load_file("res://data/enemies.csv")
    .with_type("hp", CSVFieldDefinition.FieldType.TYPE_INT)
    .with_type("attack_damage", CSVFieldDefinition.FieldType.TYPE_INT)
    .with_type("speed", CSVFieldDefinition.FieldType.TYPE_INT)
    .parse_all()

# 初始化敌人数据库
for enemy_data in enemies.rows:
    var enemy := EnemyData.new()
    enemy.name = enemy_data.name
    enemy.max_hp = enemy_data.hp
    enemy.attack_damage = enemy_data.attack_damage
    enemy.move_speed = enemy_data.speed
    enemy.sprite = enemy_data.sprite_path
    enemy_database.register(enemy.id, enemy)
```

### 场景 3：本地化数据

```gdscript
# localization.csv
# key,en,zh,ja
# menu_start,Start,开始,スタート
# menu_options,Options,选项,オプション
# menu_quit,Quit,退出,終了

var loc := CSVLoader.new()
    .load_file("res://data/localization.csv")
    .parse_all()

# 构建本地化字典
for row in loc.rows:
    var key := row.key
    localization_dict[key] = {
        "en": row.en,
        "zh": row.zh,
        "ja": row.ja
    }

# 获取本地化文本
func get_text(key: String, lang: String = "zh") -> String:
    if localization_dict.has(key):
        return localization_dict[key].get(lang, key)
    return key
```

## 最佳实践

### 性能优化

1. **使用缓存**：对于频繁访问的 CSV 文件，系统会自动缓存，避免重复读取
2. **流式读取大文件**：文件大小超过 10MB 时，建议使用 `stream()` 方法
3. **合理使用 Schema**：Schema 可以在导入时预处理，提升运行时性能

### 错误处理

```gdscript
var data := CSVLoader.new().load_file("res://data/items.csv").parse_all()

if data.has_errors():
    print("解析失败，共 %d 个错误：" % data.get_errors().size())
    for error in data.get_errors():
        print("  - %s" % error)
    return

if data.has_warnings():
    print("解析成功，但有警告：")
    for warning in data.get_warnings():
        print("  - %s" % warning)

print("解析完成：共 %d 行数据" % data.get_row_count())
```

### Schema 设计

将 Schema 保存为资源文件，便于复用和维护：

```gdscript
# 在编辑器中创建 item_schema.tres
# [Resource]
# script = ExtResource("res://addons/csv_handler/csv_schema.gd")
# field_definitions = {
#   "id": {
#     "type": 4,  # TYPE_STRING_NAME
#     "required": true,
#     "unique": true
#   },
#   "price": {
#     "type": 1,  # TYPE_INT
#     "required": true,
#     "min_value": 0,
#     "max_value": 10000
#   }
# }

# 使用 Schema 资源
var schema: CSVSchema = load("res://data/schemas/item_schema.tres")
var items := CSVLoader.new()
    .load_file("res://data/items.csv")
    .with_schema(schema)
    .parse_all()
```

## 故障排查

### 问题：文件找不到

**原因**：文件路径不正确或文件不存在

**解决**：
- 检查文件路径是否正确（使用 `res://` 或 `user://` 前缀）
- 确认文件确实存在于指定位置
- 使用 `FileAccess.file_exists()` 检查文件是否存在

### 问题：类型转换失败

**原因**：数据格式与指定类型不匹配

**解决**：
- 检查 CSV 数据格式是否正确
- 使用 Schema 定义验证规则
- 提供合理的默认值处理空字段

### 问题：资源加载失败

**原因**：资源路径不存在或资源类型不匹配

**解决**：
- 检查资源路径是否正确
- 确认资源文件存在且类型匹配
- 使用 `ResourceLoader.exists()` 验证资源

### 问题：内存占用过高

**原因**：一次性加载大型 CSV 文件

**解决**：
- 使用 `stream()` 方法进行流式读取
- 及时调用 `CSVLoader.clear_cache()` 清除缓存
- 考虑将数据分批处理

## 许可证

本系统为 Project Aetherflow 项目的一部分，遵循项目许可证。

## 贡献

欢迎提交问题和改进建议！

## 版本历史

### v1.0.0 (2026-01-09)
- 初始版本发布
- 支持 CSV 文件读取和解析
- 实现类型转换和验证
- 支持 Schema 定义
- 集成 Godot 资源导入系统
- 提供流式读取功能
