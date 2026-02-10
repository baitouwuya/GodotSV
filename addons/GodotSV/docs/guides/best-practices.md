# 最佳实践

## 数据格式

### 优先使用 GDSV 格式

- 使用 `.gdsv` 扩展名，默认 Tab 分隔
- Tab 分隔避免了逗号在向量/颜色值中的歧义
- 表头加类型注解，让解析器自动处理类型转换

```
*id:int	name:string	active:bool=false	pos:Vector2=0,0
1	Alice	true	100,200
2	Bob	false	300,400
```

### 表头设计原则

- 必需字段加 `*` 前缀
- 设置合理的默认值，减少数据冗余
- 使用 `enum()` 约束限制可选值

## Schema 优先

对于关键数据，建议定义 Schema 而非仅依赖表头注解：

```gdscript
var schema := GDSVSchema.new()
schema.add_field("id", GDSVFieldDefinition.FieldType.TYPE_INT) \
    .with_required(true) \
    .with_unique(true)

schema.add_field("name", GDSVFieldDefinition.FieldType.TYPE_STRING) \
    .with_required(true)

var resource := GDSVLoader.new() \
    .load_file("res://data/items.gdsv") \
    .with_schema(schema) \
    .parse_all()
```

Schema 提供表头注解无法实现的功能：唯一约束、正则模式验证、跨行校验。

## 大文件处理

### 流式读取

超过 1000 行的文件建议使用 `stream()` 代替 `parse_all()`：

```gdscript
var reader := GDSVLoader.new() \
    .load_file("res://data/huge.gdsv") \
    .with_header(true) \
    .stream()

while reader.has_next():
    var row: Dictionary = reader.next()
    process_row(row)

reader.close()
```

### 缓存管理

`parse_all()` 结果会自动缓存（LRU，上限 10 个文件）。需要释放内存时：

```gdscript
GDSVLoader.clear_cache()
```

## 错误处理

始终检查加载结果：

```gdscript
var resource := GDSVLoader.new() \
    .load_file(path) \
    .parse_all()

if resource.has_errors():
    for error in resource.get_errors():
        push_error("GDSV: " + error)
    return

if resource.has_warnings():
    for warning in resource.get_warnings():
        push_warning("GDSV: " + warning)
```

## 项目结构建议

```
your_project/
├── data/                           # 数据文件
│   ├── characters.gdsv
│   ├── items.gdsv
│   └── levels.gdsv
├── schemas/                        # Schema 资源
│   ├── character_schema.tres
│   └── item_schema.tres
├── custom_types/                   # 自定义类型处理器
│   ├── gdsv_type_duration.gd
│   └── gdsv_type_percent.gd
└── addons/
    └── GodotSV/                    # 插件
```

## 类型安全读取

优先使用类型安全的 getter 方法，避免手动类型转换：

```gdscript
# 推荐：类型安全
var hp: int = resource.get_int(i, "health", 100)
var name: String = resource.get_string(i, "name", "Unknown")

# 不推荐：手动转换
var hp: int = int(resource.get_value(i, "health"))
```

## 导出注意事项

- 确保 `.gdsv` / `.csv` / `.tsv` 文件未被导出设置排除
- GDExtension DLL 必须包含在导出中
- 自定义类型处理器脚本（`.gd`）也需要包含在导出中
