# 性能优化实施指南

## 执行步骤总览

### 第一步：运行Profiling测试（30分钟）

1. 在Godot编辑器中运行 `tests/profiling/profiling_test.tscn`
2. 观察控制台输出，记录各阶段耗时

**预期结果模式：**

| 瓶颈阶段 | 症状 | 优化方向 |
|---------|------|---------|
| 阶段1 (文件读取) | > 50ms | 使用文件映射或调整缓冲大小（通常不是主瓶颈） |
| 阶段2 (GDScript split) | 占比 > 20% | 移除GDScript中的split，让C++直接处理 |
| 阶段3 (C++解析) | >> 阶段2 | GDExtension边界marshalling，添加批量接口 |
| 阶段4 >> 阶段3 | 差异 > 50% | 数据后续处理（_normalize_table_shape, _trim_all_cells等）|

### 第二步：选择优化方向

根据profiling结果选择：

**如果阶段2占比较高（GDScript split问题）：**
- 问题：GDScript和C++都调用split，导致重复工作
- 解决方案：让C++的 `parse_from_file` 直接读取文件，避免GDScript分割

**如果阶段3 >> 阶段2（marshalling问题）：**
- 问题：`TypedArray<PackedStringArray>` 跨越GDExtension边界昂贵
- 解决方案：添加批量接口，减少边界跨越次数

**如果阶段4 >> 阶段3（后续处理问题）：**
- 问题：`_normalize_table_shape`, `_trim_all_cells` 等重复遍历数据
- 解决方案：在C++中一次性完成，避免多次循环

### 第三步：实施代码改动

## 优化方案A：消除重复split（低风险，立即见效）

### 问题描述
当前数据流：
```
FileAccess.get_as_text() → content (String)
  ↓ GDScript: content.split("\n")
  ↓ TypedArray<PackedStringArray>
  ↓ C++: 接收后内部也按行处理
```

### 解决方案
使用C++的 `ParseFromFile` 直接读取文件：

**改动文件：** `demo/addons/GodotSV/scripts/gdsv_data_processor.gd`

**改动位置：** `load_gdsv_file` 方法，约第101-127行

**旧代码：**
```gdscript
func load_gdsv_file(file_path: String) -> bool:
    # ... 省略部分代码 ...
    var file := FileAccess.open(file_path, FileAccess.READ)
    if file == null:
        _set_error("无法打开文件: " + file_path)
        file_loaded.emit(false, last_error)
        return false

    var content := file.get_as_text()
    file.close()

    return load_gdsv_content(content, file_path)
```

**新代码：**
```gdscript
func load_gdsv_file(file_path: String) -> bool:
    _reset_error_state()

    if not FileAccess.file_exists(file_path):
        _set_error(ERROR_FILE_NOT_FOUND)
        file_loaded.emit(false, last_error)
        return false

    # 存储原始文件扩展名
    if file_path.contains("."):
        original_file_extension = "." + file_path.get_extension()
    else:
        original_file_extension = ".gdsv"

    default_delimiter = _infer_default_delimiter_for_file(file_path)

    # 优化：直接使用C++的parse_from_file，避免GDScript读取content
    var gdsv_data: Array = _gdsv_parser.parse_from_file(file_path, true, default_delimiter)

    if _gdsv_parser.has_error():
        _set_error(_gdsv_parser.get_last_error())
        file_loaded.emit(false, last_error)
        return false

    _original_header = _gdsv_parser.get_header()
    _cleaned_header = _extract_clean_header()

    var rows: Array[PackedStringArray] = []
    for row in gdsv_data:
        if row is PackedStringArray:
            rows.append(row)
    _table_data.initialize(rows, _cleaned_header)
    _normalize_table_shape()

    if auto_trim_whitespace:
        _trim_all_cells()

    last_file_path = file_path

    if not file_path.is_empty():
        if file_path.contains("."):
            original_file_extension = "." + file_path.get_extension()
        else:
            original_file_extension = ".gdsv"

    if not file_path.is_empty() and FileAccess.file_exists(file_path):
        last_file_modified_time = FileAccess.get_modified_time(file_path)

    file_loaded.emit(true, "")
    data_changed.emit("load", {"file_path": file_path})

    return true
```

**预期收益：**
- 消除一次完整的字符串拷贝
- 消除GDScript与C++之间的字符串marshalling
- 预计性能提升：10-20%

**风险：** 低
- 逻辑完全相同，只是改变数据流向
- GDSVParser已经有 `parse_from_file` 方法

---

## 优化方案B：减少边界marshalling（中等复杂度）

### 问题描述
`parse_from_string` 返回 `TypedArray<PackedStringArray>`，跨越GDExtension边界时需要marshalling。

当前每次访问行都需要跨越边界：
```cpp
TypedArray<PackedStringArray> GetRows() const {
    return rows_;  // 完整拷贝跨越边界
}
```

### 解决方案
添加批量获取接口，减少边界跨越次数：

**需要修改的C++文件：**
1. `src/gdsv/gdsv_table_data.h` - 添加新方法声明
2. `src/gdsv/gdsv_table_data.cpp` - 实现新方法
3. 需要重新编译GDExtension

**添加到 gdsv_table_data.h:**
```cpp
/// 获取所有行的原始数据（避免边界marshalling的内部使用）
TypedArray<PackedStringArray> GetRowsRaw() const { return rows_; }

/// 批量获取指定范围的行数据
TypedArray<PackedStringArray> GetRowRange(int p_start_row, int p_end_row) const;
```

**实现到 gdsv_table_data.cpp:**
```cpp
TypedArray<PackedStringArray> GDSVTableData::GetRowRange(int p_start_row, int p_end_row) const {
    TypedArray<PackedStringArray> result;

    if (p_start_row < 0 || p_end_row > rows_.size() || p_start_row >= p_end_row) {
        return result;
    }

    for (int i = p_start_row; i < p_end_row; ++i) {
        result.append(rows_[i]);
    }

    return result;
}
```

**然后在gdsv_data_processor.gd中添加新方法：**
```gdscript
## 批量获取行数据（减少边界跨越）
func get_rows_range(start_row: int, end_row: int) -> Array[PackedStringArray]:
    var raw_data: Array = _table_data.get_row_range(start_row, end_row)
    var result: Array[PackedStringArray] = []
    for row in raw_data:
        if row is PackedStringArray:
            result.append(row)
    return result
```

**注意：** 此优化需要重新编译C++扩展，适合作为第二阶段优化。

---

## 优化方案C：消除后续处理中的重复遍历（高收益）

### 问题描述
当前在 `load_gdsv_content` 中：
```gdscript
_table_data.initialize(rows, _cleaned_header)
_normalize_table_shape()        # 遍历所有行
_trim_all_cells()               # 遍历所有行（如果auto_trim_whitespace=true）
```

### 解决方案
在 `gdsv_table_data.cpp` 的 `Initialize` 方法中添加可选的处理参数：

**修改 gdsv_table_data.h:**
```cpp
/// 初始化表格数据
/// @param p_rows 表格数据（二维字符串数组）
/// @param p_header 表头数组
/// @param p_normalize_shape 是否自动规范化表格形状（默认true）
/// @param p_trim_whitespace 是否自动去除首尾空格（默认false）
void Initialize(const TypedArray<PackedStringArray> &p_rows,
                const PackedStringArray &p_header,
                bool p_normalize_shape = true,
                bool p_trim_whitespace = false);
```

**修改 gdsv_table_data.cpp 的 Initialize 实现：**
```cpp
void GDSVTableData::Initialize(const TypedArray<PackedStringArray> &p_rows,
                                const PackedStringArray &p_header,
                                bool p_normalize_shape,
                                bool p_trim_whitespace) {
    rows_ = p_rows;
    header_ = p_header;

    if (p_normalize_shape) {
        _internal_normalize_shape(p_trim_whitespace);
    } else if (p_trim_whitespace) {
        _internal_trim_all();
    }
}

void GDSVTableData::_internal_normalize_shape(bool p_trim_whitespace) {
    if (rows_.is_empty()) {
        return;
    }

    int max_columns = header_.size();

    // 先确定最大列数
    for (int i = 0; i < rows_.size(); ++i) {
        PackedStringArray row_data = rows_[i];
        if (row_data.size() > max_columns) {
            max_columns = row_data.size();
        }
    }

    // 扩展header
    while (header_.size() < max_columns) {
        header_.append("");
    }

    // 一次遍历完成规范化+trim
    for (int i = 0; i < rows_.size(); ++i) {
        PackedStringArray row_data = rows_[i];
        PackedStringArray new_row_data;

        for (int j = 0; j < max_columns; ++j) {
            String value;
            if (j < row_data.size()) {
                value = row_data[j];
                if (p_trim_whitespace) {
                    value = value.strip_edges();
                }
            }
            new_row_data.append(value);
        }

        rows_[i] = new_row_data;
    }
}

void GDSVTableData::_internal_trim_all() {
    for (int i = 0; i < rows_.size(); ++i) {
        PackedStringArray row_data = rows_[i];
        PackedStringArray new_row_data;

        for (int j = 0; j < row_data.size(); ++j) {
            new_row_data.append(row_data[j].strip_edges());
        }

        rows_[i] = new_row_data;
    }
}
```

**同时修改 gdsv_table_data.h 添加私有方法声明：**
```cpp
private:
    TypedArray<PackedStringArray> rows_;
    PackedStringArray header_;

    void _internal_normalize_shape(bool p_trim_whitespace = false);
    void _internal_trim_all();
```

**修改 gdsv_data_processor.gd:**
```gdscript
# 替换原来的：
# _table_data.initialize(rows, _cleaned_header)
# _normalize_table_shape()
# if auto_trim_whitespace:
#     _trim_all_cells()

# 改为：
_table_data.initialize(rows, _cleaned_header, true, auto_trim_whitespace)
# _normalize_table_shape()  # 已在C++中完成
# if auto_trim_whitespace:
#     _trim_all_cells()      # 已在C++中完成
```

**预期收益：**
- 将3次遍历合并为1次
- 消除多次边界跨越
- 预计性能提升：30-50%

**风险：** 中等
- 需要重新编译
- 需要仔细测试边界情况

---

## 实施顺序建议

### 阶段1：零成本优化（立即执行）
1. 运行 profing_test.gd 确定瓶颈
2. 实施方案A（使用 parse_from_file）
3. 重新测试验证改善

### 阶段2：中等成本优化
1. 实施方案C（合并遍历）
2. 重新编译GDExtension
3. 运行完整测试套件
4. 对比profiling结果

### 阶段3：可选优化
1. 如果仍有需求，实施方案B
2. 针对特定访问模式优化

---

## 验证标准

优化成功后，10K行文件的加载时间应该：
- **第一阶段：** 从当前时间降低20-30%
- **第二阶段：** 从第一阶段再降低30-40%

最终目标：10K行文件加载时间 < 500ms（在普通PC上）
