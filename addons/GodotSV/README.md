# GodotSV

<img src="./GodotSV.png" width="160" alt="GodotSV">

Godot Data Separated Values（GDSV）高性能表格数据插件。

## 功能概览

- 📊 多格式支持：gdsv / csv / tsv / tab / psv / asc
- ⚡ C++ 核心解析 + GDScript 高级 API
- 🧩 Schema 验证、类型转换、搜索与替换
- 🌊 流式读取大文件，控制内存占用
- 📝 内置可视化编辑器（双击 .gdsv 直接编辑）

## 适用场景

- 角色/道具/配置表的结构化数据加载
- 需要类型注解与默认值的表格数据
- 大文件离线处理（流式读取）
- 美术/策划在编辑器内直接维护数据

## 快速开始

```gdscript
var resource := GDSVLoader.new()
	.load_file("res://data/characters.gdsv")
	.with_header(true)
	.parse_all()

if resource.has_errors():
	print(resource.get_errors())
	return

print(resource.headers)
print(resource.get_string(0, "name"))
```

## 典型工作流程

1. 使用 GDSV 格式（或 CSV/TSV）准备数据。
2. 如需强校验，创建 `GDSVSchema` 并配置字段规则。
3. 通过 `GDSVLoader` 解析为 `GDSVResource`。
4. 运行时使用 `get_int/get_float/get_bool` 安全读取。

## GDSV 语法速览

GDSV 使用 Tab 分隔符，表头支持类型注解：

```
*id:int	name:string	active:bool=false	health:float=100
1	Alice	true	85.5
2	Bob	false	72.3
```

常用注解：
- `field:type`：类型
- `*field:type`：必需字段
- `field:type=value`：默认值
- `field:enum(val1,val2)`：枚举

完整语法见：[`docs/guides/gdsv-format.md`](./docs/guides/gdsv-format.md)

## 注意事项

- 默认使用 Tab 分隔，CSV 建议通过导入器或设置分隔符。
- 大文件请优先使用 `stream()` 流式读取。
- 如需强校验，建议配置 `GDSVSchema`。
- 类型注解仅影响表头解析，数据仍以字符串解析后再转换。

## 文档

- 指南入口：[`docs/index.md`](./docs/index.md)
- GDSV 语法：[`docs/guides/gdsv-format.md`](./docs/guides/gdsv-format.md)
- API 目录：[`docs/api/index.md`](./docs/api/index.md)
- 故障排查：[`docs/guides/troubleshooting.md`](./docs/guides/troubleshooting.md)
- 完整 API 入口：[`API_REFERENCE.md`](./API_REFERENCE.md)

## 许可

MIT License
