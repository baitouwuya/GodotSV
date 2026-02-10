# 安装与快速开始

## 安装

### 方式 1：从 Release 安装

1. 从 [Releases](https://github.com/baitouwuya/better-godot-csv/releases) 下载最新版本
2. 将 `addons/GodotSV/` 文件夹复制到项目目录
3. 在 Godot 中启用：**项目 → 项目设置 → 插件 → GodotSV**

### 方式 2：从源码构建

```bash
git clone --recurse-submodules https://github.com/baitouwuya/better-godot-csv.git
cd better-godot-csv
scons                           # debug 版本
scons target=template_release   # release 版本
```

构建产物自动输出到 `GodotSV/addons/GodotSV/bin/` 对应平台目录。

## 最小示例

创建一个 `.gdsv` 文件（Tab 分隔）：

```
*id:int	name:string	health:float=100
1	Alice	85.5
2	Bob	72.3
```

在 GDScript 中加载：

```gdscript
func _ready() -> void:
    var resource := GDSVLoader.new() \
        .load_file("res://data/characters.gdsv") \
        .with_header(true) \
        .parse_all()

    if resource.has_errors():
        push_error(str(resource.get_errors()))
        return

    # 遍历所有行
    for i in resource.get_row_count():
        var name: String = resource.get_string(i, "name")
        var hp: float = resource.get_float(i, "health")
        print("%s: %.1f HP" % [name, hp])

    # 按字段查找
    var alice: Dictionary = resource.find_row("name", "Alice")
    print("Alice's HP: ", alice.get("health", "N/A"))
```

## 支持的文件格式

| 扩展名 | 默认分隔符 | 说明 |
|--------|-----------|------|
| `.gdsv` | Tab (`\t`) | GodotSV 原生格式 |
| `.tsv` / `.tab` | Tab (`\t`) | 标准 Tab 分隔 |
| `.csv` | 逗号 (`,`) | 标准 CSV |
| `.psv` | 竖线 (`\|`) | 管道分隔 |
| `.asc` | Tab (`\t`) | ASCII 数据文件 |

分隔符根据文件扩展名自动推断，也可通过 `.with_delimiter()` 显式指定。

## 流式读取大文件

对于大文件，使用 `stream()` 代替 `parse_all()` 逐行读取：

```gdscript
var reader := GDSVLoader.new() \
    .load_file("res://data/huge_table.gdsv") \
    .with_header(true) \
    .stream()

while reader.has_next():
    var row: Dictionary = reader.next()
    process_row(row)

reader.close()
```

## 下一步

- [GDSV 格式与类型注解](./gdsv-format.md) — 了解类型注解语法
- [编辑器集成](./editor-integration.md) — 在 Godot 编辑器中直接编辑数据
- [API 总览](../api/index.md) — 查看完整接口文档
