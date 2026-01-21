class_name ReorderableItemList
extends ItemList

signal reorder_requested(from_index: int, to_index: int)

## 只允许在左侧“握把区域”触发拖拽
@export var drag_handle_width: float = 24.0


func _get_drag_data(at_position: Vector2) -> Variant:
	var from_index := get_item_at_position(at_position, true)
	if from_index < 0:
		return null

	if at_position.x > drag_handle_width:
		return null

	var preview := Label.new()
	preview.text = get_item_text(from_index)
	set_drag_preview(preview)

	return {"from": from_index}


func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if not data.has("from"):
		return false
	if typeof(data.from) != TYPE_INT:
		return false
	return get_item_count() > 1


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY or not data.has("from"):
		return

	var from_index: int = int(data.from)
	if from_index < 0 or from_index >= get_item_count():
		return

	var hover_index := get_item_at_position(at_position, true)
	var insert_at := get_item_count()

	if hover_index >= 0:
		insert_at = hover_index
		var rect := get_item_rect(hover_index)
		if at_position.y > rect.position.y + rect.size.y * 0.5:
			insert_at = hover_index + 1

	var to_index := insert_at
	if to_index > from_index:
		to_index -= 1

	to_index = clampi(to_index, 0, get_item_count() - 1)

	if to_index == from_index:
		return

	reorder_requested.emit(from_index, to_index)
