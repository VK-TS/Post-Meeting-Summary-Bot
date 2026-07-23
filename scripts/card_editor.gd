## CardEditor - Persistent card editor scene
## Responsibilities:
## - Display selected card
## - Accept component sticker drops
## - Apply stickers to cards with placement data
## - Display applied components

extends PanelContainer

signal sticker_dropped_on_card(component_id: String, card_index: int, position: Vector2, is_loadout: bool)

@export var card_display_size: Vector2 = Vector2(208, 218)

var selected_card: Dictionary = {}
var selected_card_index: int = -1
var selected_card_is_loadout: bool = false

var card_display: Control


func _ready() -> void:
	custom_minimum_size = card_display_size
	
	# Drop target setup
	
	# Card display area
	card_display = Control.new()
	card_display.custom_minimum_size = card_display_size
	card_display.anchor_right = 1.0
	card_display.anchor_bottom = 1.0
	add_child(card_display)


func set_card(card_data: Dictionary, card_index: int, is_loadout: bool) -> void:
	selected_card = card_data.duplicate(true)
	selected_card_index = card_index
	selected_card_is_loadout = is_loadout
	_update_card_display()


func _update_card_display() -> void:
	# Clear previous display
	for child in card_display.get_children():
		child.queue_free()
	
	if selected_card.is_empty():
		return
	
	# Load card background
	var card_id = selected_card.get("base_id", "")
	var card_info = BulletTypes.data(card_id)
	var card_art = BulletTypes.load_texture(str(card_info.get("card_art", "")))
	
	var background = TextureRect.new()
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP
	background.anchor_right = 1.0
	background.anchor_bottom = 1.0
	if card_art:
		background.texture = card_art
	card_display.add_child(background)
	
	# Render stickers
	var components: Array = selected_card.get("components", [])
	for i in range(components.size()):
		var component_entry = components[i]
		var component_id = BulletTypes.component_entry_id(component_entry)
		var offset = BulletTypes.component_entry_offset(component_entry)
		
		var sticker_data = BulletTypes.component_data(component_id)
		var sticker_path = str(sticker_data.get("card_sticker", ""))
		var texture = BulletTypes.load_texture(sticker_path)
		
		if texture:
			var sticker = TextureRect.new()
			sticker.texture = texture
			sticker.custom_minimum_size = Vector2(32, 32)
			sticker.stretch_mode = TextureRect.STRETCH_SCALE
			sticker.position = offset
			sticker.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card_display.add_child(sticker)


## Accept sticker drops
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind") == "component_sticker"


## Handle sticker drop
func _drop_data(at_position: Vector2, data: Variant) -> void:
	var component_id = data.get("component_id", "")
	
	# Store placement data in card
	var placement = {
		"id": component_id,
		"offset": at_position
	}
	
	# Add to components array (or replace if already exists)
	var components: Array = selected_card.get("components", [])
	var existing_index = -1
	for i in range(components.size()):
		if BulletTypes.component_entry_id(components[i]) == component_id:
			existing_index = i
			break
	
	if existing_index >= 0:
		components[existing_index] = placement
	else:
		components.append(placement)
	
	selected_card["components"] = components
	_update_card_display()
	
	# Signal that sticker was dropped
	sticker_dropped_on_card.emit(component_id, selected_card_index, at_position, selected_card_is_loadout)


func get_edited_card() -> Dictionary:
	return selected_card.duplicate(true)
