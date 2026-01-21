# GDSV 测试套件

本目录包含 GodotSV 插件的测试文件和测试场景。

## 📁 目录结构

```
tests/
├── README.md                        # 本文件
├── test_runner_main.gd              # 主测试UI脚本 ⭐NEW
├── test_runner_main.tscn            # 主测试UI场景 ⭐NEW
├── test_main.gd                     # 基础GDSV加载测试
├── test_main.tscn                   # 基础测试场景
├── basic_io/                        # 基础IO测试套件 ⭐NEW
│   ├── basic_io_test.gd             # 基础读写测试(5个测试用例)
│   ├── basic_io_test.tscn           # 测试场景
│   └── data/                        # 测试数据
├── multi_format/                    # 多格式测试套件 ⭐NEW
│   ├── multi_format_test.gd         # CSV/TSV/GDSV格式测试(6个测试用例)
│   ├── multi_format_test.tscn       # 测试场景
│   └── data/                        # 测试数据
├── large_file/                      # 大文件性能测试 ⭐NEW
│   ├── large_file_test.gd           # 大文件读写测试(5个测试用例)
│   ├── large_file_test.tscn         # 测试场景
│   ├── README.md                    # 使用说明
│   └── data/                        # 大文件测试数据(需生成)
├── search_performance/              # 搜索性能测试 ⭐NEW
│   ├── search_performance_test.gd   # 搜索性能测试(5个测试用例)
│   ├── search_performance_test.tscn # 测试场景
│   ├── README.md                    # 使用说明
│   └── data/                        # 搜索测试数据(需生成)
├── search/                          # 搜索功能测试套件
│   ├── README.md                    # 搜索测试说明
│   ├── TEST_SUMMARY.md              # 测试规格文档
│   ├── simple_search_test.gd        # 搜索功能自动化测试(12个测试用例)
│   ├── simple_search_test.tscn      # 搜索测试场景
│   └── data/                        # 搜索测试数据
│       ├── basic_search.gdsv
│       ├── case_sensitivity.gdsv
│       ├── regex.gdsv
│       └── edge_cases.gdsv
└── docs/                            # 历史文档和报告
    ├── TEST_RESULTS.md              # 测试执行结果
    ├── FINAL_REPORT.md              # 完整审查报告
    └── BUG_FIX_REPORT.md            # Bug修复报告

../test_data/                    # 共享测试数据(项目根级别)
├── basic.gdsv
├── advanced.gdsv
├── compatibility.csv
├── compatibility.tsv
├── error_handling.gdsv
├── extra_fields.gdsv
├── unknown_types.gdsv
└── search_data.gdsv
```

## 🧪 测试套件概览

### 🎯 主测试UI (`test_runner_main.tscn`) ⭐NEW

**运行方式:** 在Godot编辑器中运行 `tests/test_runner_main.tscn`

**功能特性:**
- 图形化测试运行界面
- 左侧按钮选择测试类别
- 右侧实时显示测试结果
- 统计信息显示（通过/失败/总数）
- 进度条显示测试进度

**包含的测试类别:**
1. 基础格式读写测试
2. 多格式读写测试
3. 大文件读写测试
4. 搜索性能测试
5. 现有搜索功能测试

---

### 1. 基础格式读写测试 (`basic_io/`) ⭐NEW

**运行方式:** 在Godot编辑器中运行 `tests/basic_io/basic_io_test.tscn`

**测试内容:** (5个测试用例)
- ✅ 测试1: 读取基本GDSV文件
- ✅ 测试2: 验证字段类型转换（int, float, bool, string）
- ✅ 测试3: 写入GDSV文件并读取验证
- ✅ 测试4: 测试空文件处理
- ✅ 测试5: 测试特殊字符处理

**测试数据:** 使用 `test_data/basic.gdsv` 等共享测试数据

---

### 2. 多格式读写测试 (`multi_format/`) ⭐NEW

**运行方式:** 在Godot编辑器中运行 `tests/multi_format/multi_format_test.tscn`

**测试内容:** (6个测试用例)
- ✅ 测试1: 读取CSV文件
- ✅ 测试2: 读取TSV文件
- ✅ 测试3: 读取GDSV文件
- ✅ 测试4: CSV转GDSV格式转换
- ✅ 测试5: TSV转GDSV格式转换
- ✅ 测试6: 验证不同格式的数据一致性

**测试数据:** 使用 `test_data/compatibility.csv`, `compatibility.tsv`, `basic.gdsv`

---

### 3. 大文件读写测试 (`large_file/`) ⭐NEW

**运行方式:** 在Godot编辑器中运行 `tests/large_file/large_file_test.tscn`

**测试内容:** (5个测试用例)
- ✅ 测试1: 读取10,000行GDSV文件
- ✅ 测试2: 读取50,000行GDSV文件
- ✅ 测试3: 写入10,000行数据并验证
- ✅ 测试4: 测试流式读取性能（CSVStreamReader）
- ✅ 测试5: 测试内存占用情况

**性能指标:**
- 记录读取/写入时间
- 计算处理速度（行/秒）
- 测量吞吐量（MB/秒）
- 对比完整加载vs流式读取

**注意:** 需要先生成测试数据（见下方"数据生成脚本"部分）

---

### 4. 搜索性能测试 (`search_performance/`) ⭐NEW

**运行方式:** 在Godot编辑器中运行 `tests/search_performance/search_performance_test.tscn`

**测试内容:** (5个测试用例)
- ✅ 测试1: 在10,000行数据中搜索单个字段
- ✅ 测试2: 在50,000行数据中搜索单个字段
- ✅ 测试3: 使用正则表达式搜索
- ✅ 测试4: 多列搜索性能对比
- ✅ 测试5: 大小写敏感vs不敏感搜索性能对比

**性能指标:**
- 记录搜索执行时间（毫秒）
- 计算搜索速度（行/秒）
- 统计匹配结果数量
- 对比不同搜索策略性能

**注意:** 需要先生成测试数据（见下方"数据生成脚本"部分）

---

### 5. 基础加载测试 (`test_main.gd`)

**运行方式:** 在Godot编辑器中运行 `tests/test_main.tscn`

**测试内容:**
- 加载 `res://test_data/basic.gdsv`
- 验证行数和列数

**代码示例:**
```gdscript
extends Node

func _ready() -> void:
    var data_processor := GDSVDataProcessor.new()
    var success := data_processor.load_gdsv_file("res://test_data/basic.gdsv")

    if success:
        print("加载成功: 行数=%d, 列数=%d" % [
            data_processor.get_row_count(),
            data_processor.get_column_count()
        ])
```

---

### 6. 搜索功能测试套件 (`search/`)

**运行方式:** 在Godot编辑器中运行 `tests/search/simple_search_test.tscn`

**测试统计:**
- 总测试数: 12
- 通过率: 91.7% (11/12)
- 执行时间: ~0.008秒

**测试覆盖:**
- ✅ 基础文本搜索
- ✅ 大小写敏感/不敏感
- ✅ 正则表达式搜索
- ✅ 列过滤搜索
- ✅ 多结果处理
- ✅ 空结果处理

详见: [`search/README.md`](search/README.md)

## 📝 添加新测试

### 推荐的测试组织方式

每个独立的测试功能应该:
1. 创建独立的子目录(如 `tests/my_feature/`)
2. 包含测试场景(.tscn)和脚本(.gd)
3. 如需专用测试数据,放在子目录的`data/`文件夹
4. 添加README.md说明测试目的和运行方式

### 示例结构

```
tests/
└── my_feature/
    ├── README.md                # 测试说明
    ├── my_feature_test.gd       # 测试脚本
    ├── my_feature_test.tscn     # 测试场景
    └── data/                    # (可选)专用测试数据
        └── test_file.gdsv
```

## 🔧 测试数据位置

### 共享测试数据: `GodotSV/test_data/`

所有测试共享的数据文件应放在项目根级别的 `test_data/` 目录:

| 文件 | 用途 |
|------|------|
| `basic.gdsv` | 基础格式测试 |
| `advanced.gdsv` | 高级特性测试 |
| `compatibility.csv` | CSV兼容性测试 |
| `compatibility.tsv` | TSV兼容性测试 |
| `error_handling.gdsv` | 错误处理测试 |
| `extra_fields.gdsv` | 额外字段测试 |
| `unknown_types.gdsv` | 未知类型测试 |
| `search_data.gdsv` | 搜索功能测试 |

### 专用测试数据: `tests/<category>/data/`

如果某个测试需要特定的数据文件,应放在该测试的子目录中。

## 📊 运行测试

### 方法1: 使用主测试UI（推荐） ⭐NEW

1. 在Godot编辑器中打开 `GodotSV/` 项目
2. 运行 `tests/test_runner_main.tscn` 场景（F6）
3. 点击左侧按钮选择要运行的测试类别
4. 查看右侧测试结果和统计信息

### 方法2: 运行单个测试场景

1. 在Godot编辑器中打开 `GodotSV/` 项目
2. 在文件系统面板找到测试场景(.tscn文件)
3. 双击打开场景
4. 点击运行按钮(F6)或右键选择"运行场景"

### 方法3: 命令行运行

```bash
# 在demo目录下
godot --path . tests/test_runner_main.tscn          # 运行主测试UI
godot --path . tests/basic_io/basic_io_test.tscn    # 运行基础IO测试
godot --path . tests/multi_format/multi_format_test.tscn   # 运行多格式测试
godot --path . tests/large_file/large_file_test.tscn       # 运行大文件测试
godot --path . tests/search_performance/search_performance_test.tscn  # 运行搜索性能测试
godot --path . tests/search/simple_search_test.tscn        # 运行搜索功能测试
```

---

## 🔧 测试数据生成脚本 ⭐NEW

项目包含一个强大的Python数据生成脚本，用于生成各种规模和格式的测试数据。

### 脚本位置

```
tools/generate_test_data.py
```

### 基本用法

```bash
# 查看帮助
python tools/generate_test_data.py --help

# 使用预设配置生成数据
python tools/generate_test_data.py --preset basic
python tools/generate_test_data.py --preset search
python tools/generate_test_data.py --preset large
python tools/generate_test_data.py --preset errors

# 自定义行数和格式
python tools/generate_test_data.py --rows 1000 --format gdsv --output my_test.gdsv
python tools/generate_test_data.py --rows 5000 --format csv --output my_test.csv
python tools/generate_test_data.py --rows 10000 --format tsv --output my_test.tsv
```

### 为大文件测试生成数据

```bash
# 生成10,000行测试数据
python tools/generate_test_data.py --preset large --rows 10000 --output GodotSV/tests/large_file/data/large_10k.gdsv

# 生成50,000行测试数据
python tools/generate_test_data.py --rows 50000 --output GodotSV/tests/large_file/data/large_50k.gdsv
```

### 为搜索性能测试生成数据

```bash
# 生成10,000行搜索测试数据
python tools/generate_test_data.py --preset search --rows 10000 --output GodotSV/tests/search_performance/data/search_10k.gdsv

# 生成50,000行搜索测试数据
python tools/generate_test_data.py --preset search --rows 50000 --output GodotSV/tests/search_performance/data/search_50k.gdsv
```

### 支持的预设配置

| 预设 | 描述 | 适用场景 |
|------|------|----------|
| `basic` | 基础测试数据（小规模） | 基础功能测试 |
| `search` | 搜索测试数据（含多种字段类型） | 搜索功能测试 |
| `large` | 大规模测试数据 | 性能测试 |
| `errors` | 包含错误的测试数据 | 错误处理测试 |
| `types` | 多类型字段测试数据 | 类型转换测试 |

### 支持的数据类型

- `int` - 整数
- `float` - 浮点数
- `bool` - 布尔值
- `string` - 字符串
- `StringName` - Godot StringName
- `Array` - 数组
- `NULL` - 空值

### 支持的文件格式

- `gdsv` - Godot CSV格式（带类型注解）
- `csv` - 标准CSV格式
- `tsv` - 制表符分隔格式

---

## 📚 相关文档

- **插件API文档:** [`addons/GodotSV/README.md`](../addons/GodotSV/README.md)
- **搜索测试文档:** [`search/TEST_SUMMARY.md`](search/TEST_SUMMARY.md)
- **测试结果报告:** [`docs/TEST_RESULTS.md`](docs/TEST_RESULTS.md)
- **完整审查报告:** [`docs/FINAL_REPORT.md`](docs/FINAL_REPORT.md)
- **Bug修复记录:** [`docs/BUG_FIX_REPORT.md`](docs/BUG_FIX_REPORT.md)

## 💡 测试最佳实践

### 1. 测试脚本规范

```gdscript
extends Node

## 测试名称和描述
##
## 测试内容:
## - 测试项1
## - 测试项2

#region 测试配置
var test_data_path: String = "res://test_data/basic.gdsv"
var expected_row_count: int = 3
#endregion

func _ready() -> void:
    _run_tests()

func _run_tests() -> void:
    print("=" * 60)
    print("开始测试: <测试名称>")
    print("=" * 60)

    _test_case_1()
    _test_case_2()

    print("\\n测试完成!")

func _test_case_1() -> void:
    print("\\n[测试1] <描述>")
    # 测试逻辑
    var passed := true  # 测试结果
    _print_result("Test 1", passed)

func _print_result(test_name: String, passed: bool) -> void:
    var status := "PASS" if passed else "FAIL"
    var color := "[color=green]" if passed else "[color=red]"
    print("%s%s[/color]: %s" % [color, status, test_name])
```

### 2. 测试数据命名

- 使用描述性文件名: `basic_types.gdsv`, `large_dataset.gdsv`
- 按功能分类: `search_*.gdsv`, `format_*.csv`
- 标注规模: `small_`, `medium_`, `large_`

### 3. 测试输出

- 使用清晰的分隔符
- 打印测试统计(通过/失败/总数)
- 在失败时输出详细信息
- 记录执行时间(性能测试)

## 🐛 已知问题

1. **空字符串搜索** - 搜索空字符串返回空结果(设计行为)
   - 详见: `docs/TEST_RESULTS.md` 测试4.2

## 🔮 未来改进

### 已完成的测试 ✅

- ✅ 大文件性能测试(10,000+行) - 已实现 `large_file/`
- ✅ 流式读取测试 - 已实现在 `large_file/` 中
- ✅ 搜索性能测试 - 已实现 `search_performance/`
- ✅ 多格式兼容性测试 - 已实现 `multi_format/`
- ✅ 测试数据生成脚本 - 已实现 `tools/generate_test_data.py`
- ✅ 图形化测试运行器 - 已实现 `test_runner_main.tscn`

### 计划中的测试

- [ ] 并发读写测试
- [ ] 无效正则表达式处理测试
- [ ] 国际化字符测试(Emoji, Unicode)
- [ ] Schema验证测试
- [ ] 数据导入/导出测试
- [ ] 数据转换管道测试

### 测试自动化

考虑添加:
- [ ] 命令行测试运行器（批量运行所有测试）
- [ ] 自动化测试脚本（CI/CD集成）
- [ ] 测试覆盖率报告
- [ ] 性能回归测试

## 📧 反馈

如有测试相关问题或建议,请提交Issue到项目仓库。

---

**最后更新:** 2026-01-19
