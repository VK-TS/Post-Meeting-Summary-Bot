extends Control

var drop_handler: Callable = Callable()

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind") == "component_sticker"

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if drop_handler.is_valid():
		drop_handler.call(data, at_position)
