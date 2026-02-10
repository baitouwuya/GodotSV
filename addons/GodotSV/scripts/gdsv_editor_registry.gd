## Global editor factory registry for custom cell editors
class_name GDSVEditorRegistry extends RefCounted

## Singleton instance
static var _instance: GDSVEditorRegistry = null

## Registered editor factories: {type_name: Callable}
static var _editors: Dictionary = {}

## Get singleton instance
static func get_singleton() -> GDSVEditorRegistry:
	if _instance == null:
		_instance = GDSVEditorRegistry.new()
	return _instance

## Register custom editor factory
## @param type_name: Type identifier (e.g., "int", "custom_type")
## @param factory: Callable that returns Control
##                 Signature: func(row: int, column: int, config: Dictionary) -> Control
static func register_editor(type_name: String, factory: Callable) -> void:
	_editors[type_name] = factory

## Unregister editor
static func unregister_editor(type_name: String) -> void:
	_editors.erase(type_name)

## Check if editor registered
static func has_editor(type_name: String) -> bool:
	return _editors.has(type_name)

## Create editor instance
## Returns null if no factory registered
static func create_editor(type_name: String, row: int, column: int, config: Dictionary) -> Control:
	if _editors.has(type_name):
		return _editors[type_name].call(row, column, config)
	return null

## Get all registered type names
static func get_registered_types() -> PackedStringArray:
	var types: PackedStringArray = []
	for type in _editors.keys():
		types.append(type)
	return types

## Clear all registrations (for testing)
static func clear() -> void:
	_editors.clear()
