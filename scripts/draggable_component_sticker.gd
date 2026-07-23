extends Control

var component_id: String = ""
var component_name: String = ""

func set_component_data(id: String, name: String = "") -> void:
	component_id = id
	component_name = name

func _get_drag_data(_position: Vector2) -> Variant:
	var preview := Control.new()
	preview.custom_minimum_size = Vector2(72, 72)

	# If this control contains a TextureRect child, use its texture for the drag preview
	var found_tex: Texture2D = null
	for child in get_children():
		if child is TextureRect:
			found_tex = (child as TextureRect).texture
			break

	if found_tex != null:
		var tex_rect := TextureRect.new()
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex_rect.texture = found_tex
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.add_child(tex_rect)
	else:
		var preview_rect := ColorRect.new()
		preview_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		preview_rect.color = Color(1.0, 1.0, 1.0, 0.45)
		preview.add_child(preview_rect)

		var preview_label := Label.new()
		preview_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		preview_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		preview_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		preview_label.text = component_name if not component_name.is_empty() else component_id
		preview.add_child(preview_label)

	set_drag_preview(preview)
	return {
		"kind": "component_sticker",
		"component_id": component_id,
		"component_name": component_name,
	}
