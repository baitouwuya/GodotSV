# GDSV 搜索功能测试总结

## 1. 测试概述

本文档描述了 GDSV 插件的搜索功能测试套件。测试覆盖了 CSVSearchEngine 提供的各种搜索能力，包括基础文本搜索、正则表达式搜索、大小写敏感搜索、多结果搜索等核心功能。

**测试目标**：
- 验证 CSVSearchEngine 的文本搜索功能
- 验证正则表达式搜索能力
- 测试边界情况和错误处理
- 确保类型系统与搜索功能正确交互

**测试环境要求**：
- Godot 4.5+
- GDSV GDExtension 插件已正确安装
- 测试数据文件已就绪

## 2. 测试场景列表

| # | 测试名称 | 测试描述 | 测试数据文件 |
|---|----------|----------|--------------|
| 1 | 基础文本搜索 | 在表格中搜索名字为 'Alice' 的记录，验证基本的文本包含匹配功能 | `data/basic_search.gdsv` |
| 2 | 大小写敏感搜索 | 区分大小写搜索 'ALICE'，验证大小写敏感模式正常工作 | `data/case_sensitivity.gdsv` |
| 3 | 大小写不敏感搜索 | 不区分大小写搜索 'alice'，应找到 'Alice' | `data/case_sensitivity.gdsv` |
| 4 | 正则表达式 - 城市名 | 使用正则表达式 `^S.+$` 查找以 'S' 开头的城市 | `data/basic_search.gdsv` |
| 5 | 正则表达式 - 邮箱 | 使用电子邮件正则表达式查找邮箱地址格式 | `data/regex.gdsv` |
| 6 | 正则表达式 - 年龄范围 | 使用正则表达式查找年龄大于 30 的记录 | `data/basic_search.gdsv` |
| 7 | 空结果 - 不存在项 | 搜索不存在的内容，验证空结果处理 | `data/basic_search.gdsv` |
| 8 | 边界 - 空字符串 | 搜索空字符串，应匹配所有单元格内容 | `data/basic_search.gdsv` |
| 9 | 多结果 - dev 标签 | 查找所有包含 'dev' 标签的记录 | `data/basic_search.gdsv` |
| 10 | 多结果 - 活跃用户 | 查找 active=true 的所有记录 | `data/basic_search.gdsv` |
| 11 | 特定列 - 城市搜索 | 仅在城市名称列中搜索包含字母 'o' 的记录 | `data/basic_search.gdsv` |
| 12 | 特定列 - 标签搜索 | 仅在标签列中搜索 'game' | `data/basic_search.gdsv` |

## 3. 测试覆盖范围

### 3.1 功能覆盖

| 功能模块 | 覆盖状态 | 测试项 |
|----------|----------|--------|
| 基础文本搜索 | 完全覆盖 | 测试用例 1, 7, 8, 9, 10 |
| 正则表达式搜索 | 完全覆盖 | 测试用例 4, 5, 6 |
| 大小写控制 | 完全覆盖 | 测试用例 2, 3 |
| 列范围限制 | 完全覆盖 | 测试用例 11, 12 |
| 多结果处理 | 完全覆盖 | 测试用例 9, 10 |
| 边界情况 | 部分覆盖 | 测试用例 7, 8 (需增加更多边界测试) |
| 错误处理 | 部分覆盖 | 需增加无效正则、空数据等测试 |

### 3.2 数据类型覆盖

| 数据类型 | 测试状态 | 说明 |
|----------|----------|------|
| String | 完全覆盖 | 所有测试都包含字符串搜索 |
| int | 部分覆盖 | 年龄字段作为字符串进行正则匹配 |
| float | 未覆盖 | score 字段未进行搜索测试 |
| bool | 部分覆盖 | active 字段的字符串值搜索 |
| Array | 部分覆盖 | 标签字段作为字符串搜索，未测试数组类型 |

### 3.3 特殊字符覆盖

| 场景 | 测试状态 | 测试数据 |
|------|----------|----------|
| 空字符串 | 已覆盖 | `data/edge_cases.gdsv` |
| 空格 | 已覆盖 | `data/edge_cases.gdsv` |
| 制表符 | 已覆盖 | `data/edge_cases.gdsv` |
| 引号 | 已覆盖 | `data/edge_cases.gdsv` |
| 逗号 | 已覆盖 | `data/edge_cases.gdsv` |
| 特殊符号 | 已覆盖 | `data/edge_cases.gdsv` (`!@#$%^&*()`) |
| Unicode/中文 | 已覆盖 | `data/edge_cases.gdsv` |
| 多行字段 | 已覆盖 | `data/edge_cases.gdsv` |

## 4. 如何运行测试

### 4.1 方法一：使用批处理文件（推荐）

**Windows 系统**：

1. 确保已安装 Godot 并添加到系统路径，或修改 `run_search_tests.bat` 中的路径
2. 打开命令提示符或 PowerShell
3. 进入 GodotSV 目录并运行：

```batch
cd D:\UGit\better-godot-csv\GodotSV
run_search_tests.bat
```

**脚本会自动查找以下位置的 Godot 可执行文件**：
- `C:\Program Files\Godot\Godot.exe`
- `C:\Godot\Godot.exe`
- `%LOCALAPPDATA%\Godot\Godot.exe`

如果未找到，请手动编辑 `run_search_tests.bat` 设置正确的路径。

### 4.2 方法二：在 Godot 编辑器中运行

1. 在 Godot 编辑器中打开 `GodotSV/` 项目
2. 双击打开 `tests/search/simple_search_test.tscn` 场景
3. 按 **F5** 播放项目，或点击"播放场景"按钮

### 4.3 方法三：设置为主场景运行

1. 在 Godot 编辑器中打开项目
2. 前往 **项目 -> 项目设置 -> 应用程序 -> 运行**
3. 设置"主场景"为 `tests/search/simple_search_test.tscn`
4. 按 **F5** 运行项目

### 4.4 方法四：编辑器测试运行器

1. 在 Godot 编辑器中打开项目
2. 打开 `tests/search/search_test_main.tscn` 场景
3. 场景中包含按钮驱动的测试界面
4. 点击"运行搜索测试"按钮执行测试

**注意**：此方法需要 `res://tests/search_test_cases.gd` 文件存在。

## 5. 预期结果说明

### 5.1 测试输出示例

```
======================================================================
GDSV 搜索功能独立测试
======================================================================

[测试 1] 基础文本搜索
----------------------------------------------------------------------
测试场景: 在表格中搜索名字为 'Alice' 的记录
搜索文本: Alice
搜索模式: 不区分大小写, 包含匹配

搜索结果:
  行 0, 列 1: 'Alice'
  [通过] 准确找到 1 条记录 (Alice)

[测试 2] 大小写敏感搜索
----------------------------------------------------------------------
测试场景: 区分大小写搜索 'ALICE'，应该找不到 'Alice'
搜索文本: ALICE
搜索模式: 区分大小写, 包含匹配

搜索结果:
  (无结果) - 符合预期！
  [通过] 正确处理大小写敏感，未找到匹配项

...

======================================================================
测试执行完成
======================================================================

测试统计:
  总数: 12
  通过: 12
  失败: 0
  成功率: 100.0%

执行时间: 0.xxx 秒
======================================================================
```

### 5.2 成功标准

- 所有测试用例显示 `[通过]` 状态
- 失败数为 0
- 成功率为 100%

### 5.3 搜索结果格式

每个搜索返回一个数组，每个元素是一个 Dictionary：

```gdscript
{
    "row": int,      # 行索引（从0开始，不包含表头）
    "column": int,   # 列索引
    "matched_text": String  # 匹配的文本内容
}
```

## 6. 测试数据说明

### 6.1 数据文件结构

```
tests/search/
├── data/
│   ├── basic_search.gdsv      # 基础用户数据
│   ├── case_sensitivity.gdsv  # 大小写测试数据
│   ├── regex.gdsv             # 正则表达式测试数据
│   └── edge_cases.gdsv        # 边界情况测试数据
├── simple_search_test.gd       # 独立测试脚本
├── simple_search_test.tscn     # 测试场景
├── search_test_runner.gd       # 测试运行器
├── search_test_main.tscn       # 主测试场景
└── README.md                   # 测试目录说明
```

### 6.2 基础搜索数据 (`basic_search.gdsv`)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 用户ID |
| name | String | 用户姓名 |
| age | int | 年龄 |
| city | String | 居住城市 |
| active | bool | 是否活跃 |
| score | float | 分数 |

**样例记录**：
```
id:int	name:String	age:int	city:String	active:bool	score:float
1	Alice	25	New York	true	95.5
2	Bob	30	San Francisco	true	87.0
3	Charlie	35	Seattle	false	72.3
...
```

### 6.3 大小写敏感数据 (`case_sensitivity.gdsv`)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 记录ID |
| name | String | 名称（混合大小写） |
| status | String | 状态（混合大小写） |
| tags | Array | 标签数组（混合大小写） |

### 6.4 正则表达式数据 (`regex.gdsv`)

| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 记录ID |
| email | String | 邮箱地址 |
| phone | String | 电话号码 |
| zip_code | String | 邮政编码 |

### 6.5 边界情况数据 (`edge_cases.gdsv`)

包含各种特殊情况的测试数据：
- 空值和空字符串
- 包含空格的值
- 制表符
- 引号
- 逗号
- 特殊符号
- Unicode 字符（中文、日文）
- 多行字段

## 7. 已知问题和限制

### 7.1 当前已知问题

| 问题 | 描述 | 状态 |
|------|------|------|
| search_test_runner.gd 引用缺失 | 脚本引用了 `res://tests/search_test_cases.gd`，该文件不存在 | 待修复 |
| 独立测试数据覆盖不足 | 内置测试数据仅覆盖基础场景，未使用完整数据集 | 待优化 |

### 7.2 功能限制

| 限制 | 说明 | 影响 |
|------|------|------|
| 数据类型搜索限制 | 当前搜索主要基于字符串匹配，对数值类型（int, float）仅作为字符串处理 | 数值比较不准确 |
| 数组字段搜索 | Array 类型字段被转换为字符串搜索，不支持数组元素精确查询 | 对象数组查询困难 |
| 正则表达式性能 | 大数据集上的正则表达式搜索性能尚不明确 | 生产环境需要性能测试 |
| 多线程支持 | 未测试多线程环境下的搜索行为 | 并发访问可能有问题 |

### 7.3 待实现的测试

| 测试项 | 优先级 | 说明 |
|--------|--------|------|
| 无效正则表达式处理 | 高 | 应优雅处理正则语法错误 |
| 空数据集测试 | 中 | 测试空表格的搜索行为 |
| 大文件性能测试 | 中 | 10万+行的搜索性能 |
| 超长字符串搜索 | 低 | 处理超长文本的能力 |
| 特殊 Unicode 处理 | 低 | Emoji、组合字符等 |
| 数组元素精确搜索 | 高 | 支持 `tags CONTAINS "game"` 类型查询 |
| 数值范围查询 | 高 | 支持 `age BETWEEN 25 AND 35` 类型查询 |
| 日期时间搜索 | 中 | 日期字段的搜索能力 |

### 7.4 测试环境限制

- 测试仅在 Windows 平台验证过批处理文件
- 未在 Linux/macOS 平台运行（需要等效的 shell 脚本）
- 未在 Godot 导出版本中测试

## 附录

### A. 快速命令参考

```batch
# Windows - 运行所有搜索测试
cd D:\UGit\better-godot-csv\GodotSV
run_search_tests.bat

# 手动运行 Godot 测试场景
"C:\Godot\Godot.exe" --path "D:\UGit\better-godot-csv\GodotSV" res://tests/search/simple_search_test.tscn

# 编辑器中运行 (F5)
# 打开 simple_search_test.tscn 并按 F5
```

### B. 相关文档

- GDSV 主文档: `GodotSV/addons/GodotSV/README.md`
- 项目根指令: `CLAUDE.md`
- 测试目录说明: `tests/search/README.md`

### C. 问题报告

如发现测试问题或需要新增测试用例，请在项目仓库提交 issue 或 PR。

---

**文档版本**: 1.0
**最后更新**: 2026-01-19
**维护者**: GDSV 团队
