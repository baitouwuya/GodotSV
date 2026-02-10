@tool
class_name Gold
extends RefCounted
## 游戏金币数据类
##
## 独立数据类，不继承 GDSVTypeHandler。
## 通过 GoldHandler 桥接注册到 GDSV 类型系统（模式 B 示例）。

var amount: int = 0


func _init(p_amount: int = 0) -> void:
	amount = p_amount


func _to_string() -> String:
	return "%dg" % amount
