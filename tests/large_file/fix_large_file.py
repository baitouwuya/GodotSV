import re

with open('large_file_test.gd', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix test1 - file not found case: add [失败] before return
content = re.sub(
    r'(TestOutputLogger\.log\("  python tools/generate_test_data\.py --preset large --output %s" % FILE_10K\))(\n\treturn)',
    r'\1\n\t\tTestOutputLogger.log("  [失败] 测试文件不存在")\2',
    content
)

# Fix test1 - add [失败] after "加载失败"
content = re.sub(
    r'(TestOutputLogger\.log\("\n加载失败: %s" % processor\.last_error\))(\n\t})',
    r'\1\n\t\tTestOutputLogger.log("  [失败] 文件加载失败")\2',
    content
)

# Fix test2 - add [通过] after 吞吐量 line
content = re.sub(
    r'(TestOutputLogger\.log\("  吞吐量: %.2f MB/秒" \(%\(file_size / 1024\.0 / 1024\.0\) / \(load_time_ms / 1000\.0\) if load_time_ms > 0 else 0\)\))(\n\t})',
    r'\1\n\t\tTestOutputLogger.log("  [通过] 成功读取超大文件")\2',
    content
)

# Fix test3 - add [失败] after 写入失败
content = re.sub(
    r'(TestOutputLogger\.log\("\n写入失败: %s" % processor\.last_error\))(\n\t})',
    r'\1\n\t\tTestOutputLogger.log("  [失败] 文件写入失败")\2',
    content
)

# Fix test3 - add [失败] for data consistency failure
content = re.sub(
    r'(TestOutputLogger\.log\("  数据一致性: 失败 .*?" % \[row_count, column_count, verify_row_count, verify_column_count\]\))(\n\t\telse:)',
    r'\1\n\t\t\t\tTestOutputLogger.log("  [失败] 数据一致性检查失败")\2',
    content
)

# Fix test3 - add [失败] for verification failure
content = re.sub(
    r'(TestOutputLogger\.log\("\n验证失败: %s" % verify_processor\.last_error\))(\n\telse:)',
    r'\1\n\t\t\tTestOutputLogger.log("  [失败] 文件验证失败")\2',
    content
)

# Fix test4 - file not found: add [失败] before return
content = re.sub(
    r'(TestOutputLogger\.log\("  python tools/generate_test_data\.py --preset large --output %s" % FILE_10K\))(\n\treturn)',
    r'\1\n\t\tTestOutputLogger.log("  [失败] 测试文件不存在")\2',
    content
)

# Fix test4 - add [失败] for open file failed
content = re.sub(
    r'(TestOutputLogger\.log\("\n打开文件失败: %s" % stream_reader\.get_last_error\(\)\))(\n\treturn)',
    r'\1\n\t\tTestOutputLogger.log("  [失败] 无法打开流式读取器")\2',
    content
)

# Fix test4 - add [通过] after batch sizes loop
content = re.sub(
    r'(\n\tTestOutputLogger\.log\("\s+批量大小 %4d: 读取时间 %\.2f ms, 速度 %\.2f 行/秒" %\s+\[batch, batch_read_time_ms, batch_line_count / \(batch_read_time_ms / 1000\.0\) if batch_read_time_ms > 0 else 0\]\)\s*\n\t))(\n#endregion)',
    r'\1\n\tTestOutputLogger.log("  [通过] 流式读取性能测试完成")\2',
    content
)

# Fix test5 - file not found: add [失败] before return
content = re.sub(
    r'(TestOutputLogger\.log\("  python tools/generate_test_data\.py --preset large --output %s" % FILE_10K\))(\n\treturn)',
    r'\1\n\t\tTestOutputLogger.log("  [失败] 测试文件不存在")\2',
    content
)

# Fix test5 - add [通过] after conclusion
content = re.sub(
    r'(TestOutputLogger\.log\("\n  结论: 流式读取在大文件处理时更有利于内存管理"\))(\n#endregion)',
    r'\1\n\tTestOutputLogger.log("  [通过] 内存占用测试完成")\n\n\2',
    content
)

with open('large_file_test.gd', 'w', encoding='utf-8') as f:
    f.write(content)

print('large_file_test.gd updated successfully')
