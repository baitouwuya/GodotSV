# 编辑器集成与导入

## 打开 GDSV 文件

在 Godot 的文件系统面板中双击 `.gdsv` 文件，自动打开内置表格编辑器。

## 表格编辑器功能

### 基本编辑

- **单元格编辑** — 双击单元格直接编辑，支持自定义类型编辑器
- **行操作** — 插入行、删除行、移动行（拖拽排序）
- **列操作** — 插入列、删除列、移动列、重命名列
- **撤销/重做** — 完整的 Ctrl+Z / Ctrl+Y 支持

### 搜索与替换

- **搜索** — 全表搜索或按列搜索，支持大小写敏感和正则表达式
- **替换** — 单个替换或全部替换
- **过滤** — 按条件过滤显示行

### 数据验证

- **实时验证** — 编辑时自动检查类型约束
- **批量验证** — 全表验证，高亮错误单元格
- **类型注解** — 表头显示字段类型信息

### 列设置

右键点击表头打开列设置对话框，可配置：

- 列名
- 数据类型（从 35 种内置类型 + 自定义类型中选择）
- 必填标记
- 默认值
- 约束条件（最小值/最大值、长度限制、正则模式、枚举值）
- 数组元素类型

## CSV/TSV 导入

将 `.csv` 或 `.tsv` 文件拖入项目，导入插件自动处理：

1. 根据扩展名推断分隔符（`.csv` → `,`，`.tsv` → `\t`）
2. 解析文件内容
3. 导入为 Godot Resource，可在代码中通过 `GDSVLoader` 加载

### 导入设置

在导入面板中可配置：

- 是否有表头
- 分隔符覆盖
- Schema 绑定

## Schema 管理

### 代码创建 Schema

```gdscript
var schema := GDSVSchema.new()

schema.add_field("id", GDSVFieldDefinition.FieldType.TYPE_INT) \
    .with_required(true) \
    .with_unique(true)

schema.add_field("name", GDSVFieldDefinition.FieldType.TYPE_STRING) \
    .with_required(true)

schema.add_field("price", GDSVFieldDefinition.FieldType.TYPE_FLOAT) \
    .with_range(0, 99999)
```

### 表头内联注解（无需 Schema）

更轻量的方式，在 GDSV 表头中直接标注类型：

```
*id:int	name:string	price:float=0	rarity:enum(common,rare,epic)
```

这两种方式可以混用 — 表头注解提供基本类型信息，Schema 提供更复杂的验证规则。

## 自定义类型编辑器

自定义类型可以注册专用的编辑器控件。例如，`duration` 类型的三栏 SpinBox 编辑器：

```gdscript
GDSVEditorRegistry.register_editor("duration",
    func(row: int, column: int, config: Dictionary) -> Control:
        return MyDurationEditor.new()
)
```

详见：[自定义类型处理器](./custom-type-handler.md)

## 下一步

- [最佳实践](./best-practices.md) — 数据组织和性能建议
- [自定义类型处理器](./custom-type-handler.md) — 扩展类型系统
