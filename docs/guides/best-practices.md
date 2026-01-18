# 最佳实践

## 推荐 GDSV 结构

- 使用 Tab 分隔符
- 表头加类型注解
- 合理默认值

```
id:int	name:string	active:bool=false
```

## Schema 先行

```gdscript
var schema := GDSVSchema.new()
schema.add_field("id", GDSVFieldDefinition.FieldType.TYPE_INT).with_required(true)
```

## 大文件处理

使用流式读取：

```gdscript
var stream := GDSVLoader.new().load_file(path).with_header(true).stream()
while stream.has_next():
	var row = stream.next()
```

## 错误处理

```gdscript
if resource.has_errors():
	push_error(str(resource.get_errors()))
```

