## CardSlot - Reusable card renderer
## Displays: card art, component stickers, stats overlay, selection highlight
## Replaces duplicated card rendering logic across Main.gd

extends PanelContainer

signal card_clicked(index: int)
signal component_dropped(data: Dictionary)
signal card_selected(card_data: Dictionary)

@export var card_size: Vector2 = Vector2(208, 218)

var card: Dictionary = {}
var card_index := -1
var is_loadout := false
var selected := false

var background: TextureRect
var stickers_container: Control


func _ready() -> void:
	custom_minimum_size = card_size
	_ensure_nodes_initialized()
	# Click to select
	gui_input.connect(_on_gui_input)


func setup(card_data: Dictionary, index: int, loadout: bool, is_selected: bool) -> void:
	card = card_data.duplicate(true)
	card_index = index
	is_loadout = loadout
	selected = is_selected
	_ensure_nodes_initialized()
	_update_display()


func _ensure_nodes_initialized() -> void:
	if background == null:
		background = TextureRect.new()
		background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		background.stretch_mode = TextureRect.STRETCH_KEEP
		background.anchor_right = 1.0
		background.anchor_bottom = 1.0
		add_child(background)
	
	if stickers_container == null:
		stickers_container = Control.new()
		stickers_container.anchor_right = 1.0
		stickers_container.anchor_bottom = 1.0
		stickers_container.mouse_filter = Control.MOUSE_FILTER_PASS
		add_child(stickers_container)


func _update_display() -> void:
	if card.is_empty():
		return
	
	# Load and display card background
	var card_id = card.get("base_id", "")
	var card_info = BulletTypes.data(card_id)
	var card_art_path = str(card_info.get("card_art", ""))
	var card_art = BulletTypes.load_texture(card_art_path)
	
	if card_art:
		background.texture = card_art
	else:
		# Fallback background
		background.self_modulate = Color(0.2, 0.2, 0.2, 1.0)
	
	# Clear and render stickers
	for child in stickers_container.get_children():
		child.queue_free()
	
	var components: Array = card.get("components", [])
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
			stickers_container.add_child(sticker)
	
	# Update selection visual
	_update_selection_visual()


func _update_selection_visual() -> void:
	self_modulate = Color.WHITE if not selected else Color(1.2, 1.2, 1.2, 1.0)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		selected = not selected
		_update_selection_visual()
		card_clicked.emit(card_index)
		card_selected.emit(card)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.has("kind") and data["kind"] == "component_sticker"


func _drop_data(at_position: Vector2, data: Variant) -> void:
	component_dropped.emit({
		"component_id": data.get("component_id", ""),
		"component_name": data.get("component_name", ""),
		"position": at_position,
		"card_index": card_index,
		"loadout": is_loadout
	})
