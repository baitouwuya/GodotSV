# GDSV 格式与类型注解

## 基本格式

GDSV 默认使用 Tab 分隔，第一行可作为表头；无表头时请在加载器中关闭 `with_header`。

```
*id:int	name:string	active:bool=false	health:float=100
1	Alice	true	85.5
2	Bob	false	72.3
```

## 注释与空行

- 以 `#` 开头的行视为注释行，会被忽略。
- 空行会被跳过，不参与解析。

示例：

```
# 角色数据
id:int	name:string
1	Alice
```

## 类型注解语法

- `field:type`：指定类型
- `*field:type`：必需字段
- `field:type=value`：默认值
- `field:enum(val1,val2)`：枚举
- `field:Array[Type]`：数组元素类型

## 常见类型

- `int` / `float` / `bool` / `string`
- `StringName` / `Array` / `enum`
- `Texture2D` / `PackedScene` / `Resource`

更多解析细节见：`GDSVTypeAnnotationParser` 文档。

