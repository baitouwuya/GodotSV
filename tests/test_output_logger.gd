extends Node

## TestOutputLogger
##
## Autoload 单例，用于在测试期间输出日志消息。
## 发射信号信号 message_emitted，允许 GUI 或其他节点接收测试输出。

## 当日志消息发送时发射
signal message_emitted(message: String)

## 记录一条消息
## @param message 要记录的消息内容（可以是 String 或其他 Variant 类型）
func log(message: Variant) -> void:
	message_emitted.emit(str(message))
