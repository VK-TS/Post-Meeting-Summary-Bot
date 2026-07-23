## ComponentSlot - Reusable component renderer
## Displays: sticker, component name, rarity
## Used in component inventory grids

extends PanelContainer

signal component_clicked(component_id: String)
signal component_selected(component_id: String)

@export var slot_size: Vector2 = Vector2(80, 80)

var component_id: String = ""
var selected: bool = false

var sticker_rect: TextureRect
var name_label: Label


func _ready() -> void:
	custom_minimum_size = slot_size
	
	# Sticker display
	sticker_rect = TextureRect.new()
	sticker_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sticker_rect.stretch_mode = TextureRect.STRETCH_SCALE
	sticker_rect.anchor_right = 1.0
	sticker_rect.anchor_bottom = 1.0
	add_child(sticker_rect)
	
	# Component name label
	name_label = Label.new()
	name_label.text = ""
	name_label.anchor_right = 1.0
	name_label.anchor_bottom = 1.0
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(name_label)
	
	# Click to select
	gui_input.connect(_on_gui_input)


func set_component(new_component_id: String) -> void:
	component_id = new_component_id
	_update_display()


func _update_display() -> void:
	if component_id.is_empty():
		return
	
	# Load sticker
	var component_data = BulletTypes.component_data(component_id)
	var sticker_path = str(component_data.get("card_sticker", ""))
	var sticker_texture = BulletTypes.load_texture(sticker_path)
	
	if sticker_texture:
		sticker_rect.texture = sticker_texture
	else:
		sticker_rect.self_modulate = Color(0.4, 0.4, 0.4, 1.0)
	
	# Display name
	var component_name = BulletTypes.component_name(component_id)
	name_label.text = component_name
	
	_update_selection_visual()


func _update_selection_visual() -> void:
	self_modulate = Color.WHITE if not selected else Color(1.5, 1.5, 0.8, 1.0)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		selected = not selected
		_update_selection_visual()
		component_clicked.emit(component_id)
		component_selected.emit(component_id)


func set_selected(is_selected: bool) -> void:
	selected = is_selected
	_update_selection_visual()
