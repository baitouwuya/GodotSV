<p align="center">
  <img src="addons/GodotSV/GodotSV.png" width="128" alt="GodotSV">
</p>

# GodotSV

Godot Data Separated Values (GDSV) — 高性能表格数据插件，适用于 Godot 4.5+。

> **[详细文档 / Documentation](addons/GodotSV/README.md)**

## 功能概览

- **多格式支持** — `.gdsv` / `.csv` / `.tsv` / `.tab` / `.psv` / `.asc`
- **C++ 核心 + GDScript API** — 高性能解析 + 链式调用
- **35 种内置类型** — int, float, bool, Vector2/3/4, Color, Rect2, Transform, PackedArray 等
- **可扩展类型系统** — 用 GDScript 自定义类型处理器
- **Schema 验证** — 必填、范围、枚举、正则、唯一约束
- **流式读取** — 逐行处理大文件，控制内存占用
- **内置编辑器** — 双击 `.gdsv` 文件直接编辑，支持撤销/搜索/验证

## 快速开始

```gdscript
var resource := GDSVLoader.new() \
    .load_file("res://data/items.gdsv") \
    .with_header(true) \
    .parse_all()

for i in resource.get_row_count():
    print(resource.get_string(i, "name"))
```

## 安装

1. 将 `addons/GodotSV/` 复制到你的 Godot 项目
2. 启用：**项目 → 项目设置 → 插件 → GodotSV**

## 更新日志

### 0.2.0-alpha (2025-01)

**架构升级**：类型系统重构为可扩展 Handler 模式。

- 新增 25 种类型处理器（Vector4, Rect2, Quaternion, Transform, PackedArray 等），总计 35 种
- GDScript 自定义类型处理器支持（`@tool` + `class_name` + `extends GDSVTypeHandler`）
- `GDSVTypeHandlerRegistry.scan_script_types()` 自动扫描注册
- `GDSVEditorRegistry` 自定义编辑器控件支持
- 编辑器类型图标、独立编辑面板
- `GDSVTypeHandlerRegistry` 线程安全
- macOS / iOS 构建支持，release DLL 导出兼容
- 中英双语文档（30 个文档文件）
- 移除 `GDSVColumnParser`，统一为 `GDSVTypeAnnotationParser`
- 修复 9 个 bug（含 4 个 Critical 级别）

### 0.1.0-alpha (2024-12)

- 初始发布
- GDSV/CSV/TSV 解析（兼容 RFC 4180）
- 10 种基础类型处理器
- GDScript 高级 API：`GDSVLoader`、`GDSVResource`、`GDSVSchema`
- Godot 编辑器集成与导入插件
- 大文件流式读取

## 许可

[Unlicense](LICENSE) — 公共领域，随意使用。
