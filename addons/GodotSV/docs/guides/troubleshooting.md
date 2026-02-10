# 故障排查

## 插件未显示

**症状**：在「项目 → 项目设置 → 插件」中看不到 GodotSV。

**排查**：
1. 确认 `addons/GodotSV/plugin.cfg` 文件存在
2. 确认目录结构正确：`addons/GodotSV/bin/` 下有对应平台的 DLL/so 文件
3. 重启 Godot 编辑器

## GDExtension DLL 加载失败

**症状**：控制台报错 `Can't resolve symbol` 或 `entry point not found`。

**排查**：
1. 确认 `addons/GodotSV/godotsv.gdextension` 中 `entry_symbol = "godotsv_library_init"`
2. 确认 `bin/` 目录下没有多余的 `.gdextension` 文件（如从模板遗留的 `example.gdextension`）
3. 确认 DLL 与当前 Godot 版本兼容（4.5+）
4. 如果有多个 `.gdextension` 文件，只保留 `addons/GodotSV/godotsv.gdextension`

## 解析失败

**症状**：`resource.has_errors()` 返回 `true`，数据为空。

**排查**：
1. 检查文件编码 — GDSV 要求 UTF-8（支持 BOM）
2. 检查分隔符 — `.gdsv` 默认 Tab，`.csv` 默认逗号
3. 无表头时使用 `.with_header(false)`
4. 查看具体错误信息：`print(resource.get_errors())`

## 分隔符错误

**症状**：所有数据挤在一列，或列对不齐。

**排查**：
1. `.gdsv` 文件默认 Tab 分隔，确认编辑器没有将 Tab 转为空格
2. 显式指定分隔符：`.with_delimiter("\t")` 或 `.with_delimiter(",")`
3. 确认文件扩展名正确 — 分隔符根据扩展名自动推断

## 类型转换异常

**症状**：字段值为 `null` 或类型不对。

**排查**：
1. 检查类型注解拼写（区分大小写）：`Vector2` 而非 `vector2`
2. 检查值格式 — 向量用逗号分隔 `1,2,3`，不要加空格
3. 空值时设置默认值：`health:float=100`
4. 使用 `*_result` 方法获取详细错误信息

## 自定义类型不可见

**症状**：类型选择器中看不到自定义类型。

**排查**：
1. 确认脚本有 `@tool` 注解（不可继承，必须显式声明）
2. 确认声明了 `class_name`
3. 确认继承 `GDSVTypeHandler`
4. 重启编辑器或调用 `GDSVTypeHandlerRegistry.get_singleton().scan_script_types()`

## 编辑器中自定义编辑器不保存

**症状**：自定义编辑器控件显示正常，但编辑后值不保存。

**排查**：
1. 确认控件有 `signal value_changed`
2. 确认控件有 `get_value() -> String` 方法
3. 确认值变化时触发了 `value_changed.emit()`

## 大文件内存过高

**症状**：加载大文件时内存飙升。

**解决**：
使用 `.stream()` 流式读取代替 `.parse_all()`：

```gdscript
var reader := GDSVLoader.new() \
    .load_file("res://data/huge.gdsv") \
    .stream()

while reader.has_next():
    var row: Dictionary = reader.next()
    process_row(row)

reader.close()
```

## 导出后文件找不到

**症状**：游戏导出后加载 GDSV 文件报错「文件不存在」。

**排查**：
1. 确认文件路径使用 `res://` 前缀
2. 在导出设置中检查 `.gdsv` / `.csv` / `.tsv` 文件是否被包含
3. 在导出设置的「资源」标签页中，添加 `*.gdsv` 到非资源导出过滤器

## 获取更多帮助

- [GitHub Issues](https://github.com/baitouwuya/better-godot-csv/issues) — 报告问题
- [API 总览](../api/index.md) — 查看完整接口文档
