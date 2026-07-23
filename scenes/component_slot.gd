extends Button

var component_id: String = ""
var inventory_index := -1
var selected := false

func setup(id: String, index: int, is_selected: bool) -> void:
	component_id = id
	inventory_index = index
	selected = is_selected

	# Update appearance if selected
	if selected:
		modulate = Color(1, 1, 0.8)
	else:
		modulate = Color.WHITE

func _get_drag_data(_position: Vector2) -> Variant:
	var preview := duplicate()
	set_drag_preview(preview)

	return {
		"component": component_id,
		"inventory_index": inventory_index
	}
