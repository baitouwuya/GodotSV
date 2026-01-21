# 故障排查

## 插件未显示

- 确认 `addons/GodotSV/plugin.cfg` 存在
- 在 `项目设置 -> 插件` 中启用

## 解析失败

- 检查文件编码与分隔符
- 查看 `resource.get_errors()` 输出
- 无表头时使用 `.with_header(false)`

## 类型转换异常

- 检查类型注解或 `with_type()` 配置
- 空值时设置默认值

## 大文件内存高

- 使用 `.stream()` 流式读取

