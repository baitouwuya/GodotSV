# 安装与快速开始

## 安装

1. 将 `addons/GodotSV` 放入项目的 `addons/` 目录。
2. 在 Godot 打开：`项目 -> 项目设置 -> 插件`，启用 GodotSV。

## 最小示例

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

## 下一步

- [GDSV 格式与类型注解](./gdsv-format.md)
- [API 总览](../api/index.md)

