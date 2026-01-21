# 搜索性能测试

本目录包含大文件搜索性能测试。

## 📋 测试内容

- **测试1**: 在10,000行数据中搜索单个字段
- **测试2**: 在50,000行数据中搜索单个字段
- **测试3**: 使用正则表达式搜索
- **测试4**: 多列搜索性能对比
- **测试5**: 大小写敏感vs不敏感搜索性能对比

## 🔧 生成测试数据

在运行测试前，需要先生成测试数据：

```bash
# 生成10,000行搜索测试数据
python tools/generate_test_data.py --preset search --rows 10000 --output GodotSV/tests/search_performance/data/search_10k.gdsv

# 生成50,000行搜索测试数据
python tools/generate_test_data.py --preset search --rows 50000 --output GodotSV/tests/search_performance/data/search_50k.gdsv
```

## 📊 运行测试

在Godot编辑器中运行 `tests/search_performance/search_performance_test.tscn`

或使用命令行：
```bash
godot --path GodotSV tests/search_performance/search_performance_test.tscn
```

## 📈 性能指标

测试将输出以下性能指标：

- 搜索执行时间（毫秒）
- 匹配结果数量
- 搜索速度（行/秒）
- 不同搜索策略的性能对比

## 📝 注意事项

- 确保已生成测试数据文件
- 大文件测试可能需要较长时间
- 建议在release模式下运行以获得准确的性能数据
