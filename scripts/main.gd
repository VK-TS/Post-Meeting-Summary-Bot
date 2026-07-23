extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var spawn_timer: Timer = $SpawnTimer
@onready var ammo_label: Label = $Hud/AmmoLabel
@onready var health_bar: ProgressBar = $Hud/HealthBar
@onready var health_label: Label = $Hud/HealthLabel
@onready var card_hand: HBoxContainer = $Hud/CardHand
@onready var stored_label: Label = $Hud/StoredLabel
@onready var loadout_title: Label = $Hud/LoadoutTitle
@onready var loadout_grid: GridContainer = $Hud/LoadoutGrid
@onready var inventory_title: Label = $Hud/InventoryTitle
@onready var inventory_grid: GridContainer = $Hud/InventoryGrid
@onready var component_title: Label = $Hud/ComponentTitle
@onready var component_grid: GridContainer = $Hud/ComponentGrid
@onready var editor_title: Label = $Hud/EditorTitle
@onready var editor_stats: Label = $Hud/EditorStats
@onready var editor_card_preview: Panel = $Hud/EditorCardPreview
@onready var applied_component_grid: GridContainer = $Hud/AppliedComponentGrid
@onready var death_panel: Panel = $Hud/DeathPanel
@onready var restart_button: Button = $Hud/DeathPanel/RestartButton

const DROP_CHANCE := 0.35
const SPAWN_MARGIN := 40.0
const MIN_SPAWN_TIME := 0.35
const SPAWN_ACCELERATION := 0.985
const SLOT_SIZE := Vector2(106, 34)
const HAND_SLOT_SIZE := Vector2(112, 138)
const EDITOR_CARD_SIZE := Vector2(208, 218)

var card_slot_scene := preload("res://scenes/cardSlot.tscn")
var component_slot_scene := preload("res://scenes/componentSlot.tscn")

var enemy_scene := preload("res://scenes/enemy.tscn")
var drop_scene := preload("res://scenes/bullet_drop.tscn")

var spawned_count := 0
var selected_inventory_index := -1
var selected_loadout_index := -1
var selected_component_index := -1
var inventory_open := false

var component_preview_panel: Panel
var component_preview_title: Label
var component_preview_description: Label
var component_preview_stats: Label
var component_preview_sticker_container: Control
var editor_drop_hint: Label


func _ready() -> void:
	player.ammo_changed.connect(_on_ammo_changed)
	player.health_changed.connect(_on_health_changed)
	player.died.connect(_on_player_died)
	spawn_timer.timeout.connect(_spawn_enemy)
	restart_button.pressed.connect(_restart_run)
	death_panel.visible = false
	_build_editor_ui()
	_set_inventory_open(false)
	_on_health_changed(player.current_health, player.max_health)
	refresh_ui()


func _unhandled_input(event: InputEvent) -> void:
	if _is_tab_pressed(event):
		_set_inventory_open(not inventory_open)
		get_viewport().set_input_as_handled()


func _set_inventory_open(open: bool) -> void:
	inventory_open = open
	loadout_title.visible = inventory_open
	loadout_grid.visible = inventory_open
	inventory_title.visible = inventory_open
	inventory_grid.visible = inventory_open
	component_title.visible = inventory_open
	component_grid.visible = inventory_open
	editor_title.visible = inventory_open
	editor_stats.visible = inventory_open
	editor_card_preview.visible = inventory_open
	applied_component_grid.visible = inventory_open
	if component_preview_panel != null:
		component_preview_panel.visible = inventory_open

	if not inventory_open:
		clear_selection()
		_render_editor()


func refresh_ui() -> void:
	call_deferred("_refresh_ui")


func _refresh_ui() -> void:
	_on_ammo_changed(
		player.magazine,
		player.selected_index,
		player.stored_cards,
		player.loadout,
		player.inventory,
		player.component_inventory
	)


func clear_selection() -> void:
	selected_inventory_index = -1
	selected_loadout_index = -1
	selected_component_index = -1


func _spawn_enemy() -> void:
	var enemy = enemy_scene.instantiate()

	enemy.target = player
	enemy.speed += min(spawned_count * 2.0, 80.0)
	enemy.health = 1 + int(spawned_count / 12)
	enemy.global_position = _random_spawn_position()
	enemy.died.connect(_on_enemy_died)

	add_child(enemy)

	spawned_count += 1
	spawn_timer.wait_time = max(
		MIN_SPAWN_TIME,
		spawn_timer.wait_time * SPAWN_ACCELERATION
	)


func _random_spawn_position() -> Vector2:
	var rect := get_viewport_rect()

	match randi_range(0, 3):
		0:
			return Vector2(randf_range(0.0, rect.size.x), -SPAWN_MARGIN)
		1:
			return Vector2(rect.size.x + SPAWN_MARGIN, randf_range(0.0, rect.size.y))
		2:
			return Vector2(randf_range(0.0, rect.size.x), rect.size.y + SPAWN_MARGIN)
		_:
			return Vector2(-SPAWN_MARGIN, randf_range(0.0, rect.size.y))


func _on_enemy_died(death_position: Vector2) -> void:
	if randf() > DROP_CHANCE:
		return

	var drop = drop_scene.instantiate()
	drop.global_position = death_position
	drop.setup(BulletTypes.random_drop())

	add_child(drop)


func _on_ammo_changed(
	hand: Array,
	selected_index: int,
	stored_cards: Array,
	loadout: Array,
	inventory: Array,
	components: Array
) -> void:
	_render_hand_slots(hand, selected_index)
	ammo_label.text = "Cards"
	stored_label.text = "Stored this hand: %d" % stored_cards.size()

	_render_card_slots(loadout_grid, loadout, selected_loadout_index, true)
	_render_card_slots(inventory_grid, inventory, selected_inventory_index, false)
	_render_component_slots(component_grid, components, selected_component_index)
	_render_editor()

func _on_component_sticker_dropped(data: Dictionary) -> void:
	var component_id: String = str(data.get("component_id", ""))
	if component_id.is_empty():
		return

	var drop_position: Vector2 = data.get("position", Vector2.ZERO)
	var selected_card: Dictionary = _selected_editor_card()
	if selected_card.is_empty():
		return

	var component_index := selected_component_index
	if component_index < 0 or component_index >= player.component_inventory.size():
		component_index = _find_component_inventory_index(component_id)
	if component_index < 0 or component_index >= player.component_inventory.size():
		return

	if selected_loadout_index != -1:
		player.apply_component_to_loadout(component_index, selected_loadout_index, drop_position)
	elif selected_inventory_index != -1:
		player.apply_component_to_inventory(component_index, selected_inventory_index, drop_position)
	else:
		return

	refresh_ui()


func _render_hand_slots(hand: Array, selected_index: int) -> void:
	for child in card_hand.get_children():
		child.queue_free()

	for i in hand.size():
		var slot: Dictionary = hand[i]
		var card: Dictionary = slot.get("card", {})
		var state := str(slot.get("state", "active"))
		
		var card_slot := card_slot_scene.instantiate()
		card_slot.setup(card, i, false, i == selected_index)
		card_slot.custom_minimum_size = HAND_SLOT_SIZE
		card_slot.mouse_filter = Control.MOUSE_FILTER_STOP if state == "active" else Control.MOUSE_FILTER_IGNORE
		card_slot.card_clicked.connect(_on_hand_slot_pressed.bind(i))
		card_hand.add_child(card_slot)


func _render_card_slots(
	grid: GridContainer,
	cards: Array,
	selected_index: int,
	is_loadout: bool
) -> void:
	for child in grid.get_children():
		child.queue_free()

	for i in cards.size():
		var slot := card_slot_scene.instantiate()
		
		slot.setup(
			cards[i],
			i,
			is_loadout,
			i == selected_index
		)
		
		if is_loadout:
			slot.card_clicked.connect(_on_loadout_slot_pressed)
		else:
			slot.card_clicked.connect(_on_inventory_slot_pressed)
		grid.add_child(slot)

func _render_component_slots(
	grid: GridContainer,
	components: Array,
	selected_index: int,
) -> void:
	for child in grid.get_children():
		child.queue_free()

	for i in components.size():
		var slot = component_slot_scene.instantiate()
		slot.set_component(str(components[i]))
		slot.set_selected(i == selected_index)
		slot.component_clicked.connect(_on_component_slot_pressed.bind(i))
		grid.add_child(slot)

func _hand_slot_text(index: int, card: Dictionary, state: String, selected: bool) -> String:
	var marker := ">" if selected else " "
	var state_label := state.capitalize()
	return "%s %d\n%s\n%s" % [
		marker,
		index + 1,
		BulletTypes.card_name(card),
		state_label,
	]


func _card_slot_text(index: int, card: Dictionary, selected: bool) -> String:
	var prefix := ">" if selected else ""
	return "%s%d %s" % [prefix, index + 1, BulletTypes.card_name(card)]


func _component_slot_text(index: int, component_id: String, selected: bool) -> String:
	var prefix := ">" if selected else ""
	return "%s%d %s" % [prefix, index + 1, BulletTypes.component_name(component_id)]


# Removed _make_card_button - use CardSlot scene instead


# Removed _make_component_button - use ComponentSlot scene instead


## Old preview rendering functions removed - now using CardSlot and ComponentSlot scenes

func _ignore_mouse_recursive(node: Control):
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		if child is Control:
			_ignore_mouse_recursive(child)

func _make_projectile_icon(stats: Dictionary) -> Control:
	var texture := BulletTypes.load_texture(str(stats.get("projectile_sprite", "")))
	if texture != null:
		var rect := TextureRect.new()
		rect.texture = texture
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		return rect

	var block := ColorRect.new()
	block.color = stats.get("color", Color.WHITE)
	return block


func _add_card_layer_previews(root: Control, card_layers: Array) -> void:
	var max_layers := mini(card_layers.size(), 7)
	for i in max_layers:
		var layer: Dictionary = card_layers[i]
		var texture := BulletTypes.load_texture(str(layer.get("sprite", "")))
		var layer_node: Control

		if texture != null:
			var sticker := TextureRect.new()
			sticker.texture = texture
			sticker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			sticker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			layer_node = sticker
		else:
			var sticker_block := ColorRect.new()
			sticker_block.color = _with_alpha(layer.get("color", Color.WHITE), 0.58)
			layer_node = sticker_block

		var column := i % 3
		var row := i / 3
		layer_node.anchor_left = 0.1 + float(column) * 0.29
		layer_node.anchor_top = 0.08 + float(row) * 0.16
		layer_node.anchor_right = layer_node.anchor_left
		layer_node.anchor_bottom = layer_node.anchor_top
		layer_node.offset_left = 0.0
		layer_node.offset_top = 0.0
		layer_node.offset_right = 22.0
		layer_node.offset_bottom = 22.0
		root.add_child(layer_node)


func _add_component_stickers(root: Control, components: Array) -> void:
	for component in components:
		var component_id := BulletTypes.component_entry_id(component)
		if component_id.is_empty():
			continue

		var position: Vector2 = BulletTypes.component_entry_offset(component)
		var data := BulletTypes.component_data(component_id)
		var texture := BulletTypes.load_texture(str(data.get("card_sticker", "")))

		if texture == null:
			continue

		var sticker := TextureRect.new()
		sticker.texture = texture
		sticker.position = position
		sticker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sticker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

		root.add_child(sticker)


func _with_alpha(value, alpha: float) -> Color:
	var color: Color = value
	color.a = alpha
	return color


func _card_tooltip(card: Dictionary) -> String:
	var stats := BulletTypes.card_stats(card)
	return "Damage %d | Speed %d | Size %d | Value %d | Type %s" % [
		int(stats["damage"]),
		int(stats["speed"]),
		int(stats["radius"]),
		int(stats["value"]),
		str(stats["damage_type"])
	]


func _on_hand_slot_pressed(index: int) -> void:
	player.select_hand_index(index)


func _on_inventory_slot_pressed(index: int) -> void:
	selected_inventory_index = index
	selected_loadout_index = -1
	refresh_ui()


func _on_loadout_slot_pressed(index: int) -> void:
	selected_loadout_index = index
	selected_inventory_index = -1
	refresh_ui()


func _on_component_slot_pressed(index: int) -> void:
	selected_component_index = index
	refresh_ui()


func _build_editor_ui() -> void:
	if component_preview_panel != null:
		return

	component_preview_panel = Panel.new()
	component_preview_panel.name = "ComponentPreviewPanel"
	component_preview_panel.visible = false
	component_preview_panel.position = Vector2(416.0, 406.0)
	component_preview_panel.size = Vector2(200.0, 230.0)
	$Hud.add_child(component_preview_panel)

	var preview_root := VBoxContainer.new()
	preview_root.name = "PreviewRoot"
	preview_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_root.offset_left = 12.0
	preview_root.offset_top = 12.0
	preview_root.offset_right = -12.0
	preview_root.offset_bottom = -12.0
	component_preview_panel.add_child(preview_root)

	var preview_title_container := HBoxContainer.new()
	preview_title_container.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_root.add_child(preview_title_container)
	component_preview_title = Label.new()
	component_preview_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	component_preview_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	component_preview_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	component_preview_title.text = "Select a component"
	preview_title_container.add_child(component_preview_title)

	component_preview_sticker_container = CenterContainer.new()
	component_preview_sticker_container.custom_minimum_size = Vector2(0.0, 98.0)
	component_preview_sticker_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_root.add_child(component_preview_sticker_container)

	component_preview_description = Label.new()
	component_preview_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	component_preview_description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	component_preview_description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	component_preview_description.size_flags_vertical = Control.SIZE_EXPAND_FILL
	component_preview_description.text = "Choose a component to inspect it before applying it."
	preview_root.add_child(component_preview_description)

	component_preview_stats = Label.new()
	component_preview_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	component_preview_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	component_preview_stats.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	component_preview_stats.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_root.add_child(component_preview_stats)

	# CardSlot scenes now handle drop targets via their component_dropped signal
	editor_card_preview.mouse_filter = Control.MOUSE_FILTER_PASS

	editor_drop_hint = Label.new()
	editor_drop_hint.name = "DropHint"
	editor_drop_hint.set_anchors_preset(Control.PRESET_FULL_RECT)
	editor_drop_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	editor_drop_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	editor_drop_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	editor_drop_hint.text = "Select a card, then drag a sticker here."
	editor_drop_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	editor_card_preview.add_child(editor_drop_hint)


func _render_editor() -> void:
	for child in applied_component_grid.get_children():
		child.queue_free()
	for child in editor_card_preview.get_children():
		if child.name != "DropHint":
			child.queue_free()

	_render_component_preview()

	var selected_card := _selected_editor_card()
	if not inventory_open or selected_card.is_empty():
		editor_title.text = "Card Editor"
		editor_stats.text = "Select a card to edit."
		editor_drop_hint.visible = true
		return

	var card: Dictionary = selected_card
	var stats := BulletTypes.card_stats(card)
	
	# Render card using CardSlot
	var card_slot = card_slot_scene.instantiate()
	card_slot.setup(card, 
		selected_loadout_index if selected_loadout_index >= 0 else selected_inventory_index,
		selected_loadout_index >= 0,
		true
	)
	card_slot.custom_minimum_size = EDITOR_CARD_SIZE
	card_slot.mouse_filter = Control.MOUSE_FILTER_STOP
	# Connect drop signal to handler
	if not card_slot.component_dropped.is_connected(Callable(self, "_on_component_sticker_dropped")):
		card_slot.component_dropped.connect(_on_component_sticker_dropped)
	editor_card_preview.add_child(card_slot)

	editor_title.text = "Editing %s: %s" % [_selected_editor_label(), BulletTypes.card_name(card)]
	editor_stats.text = "Damage %d\nSpeed %d\nSize %d\nValue %d\nType %s" % [
		int(stats["damage"]),
		int(stats["speed"]),
		int(stats["radius"]),
		int(stats["value"]),
		str(stats["damage_type"]),
	]
	editor_drop_hint.visible = false

	var components: Array = card.get("components", [])
	if components.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No components yet."
		applied_component_grid.add_child(empty_label)
		return

	for i in components.size():
		var component_data: Variant = components[i]
		var component_id := BulletTypes.component_entry_id(component_data)
		
		# Render component using ComponentSlot
		var component_slot := component_slot_scene.instantiate()
		component_slot.set_component(component_id)
		component_slot.custom_minimum_size = SLOT_SIZE
		component_slot.component_clicked.connect(_on_applied_component_pressed.bind(i))
		applied_component_grid.add_child(component_slot)



func _on_applied_component_pressed(component_index: int) -> void:
	if selected_loadout_index != -1:
		player.remove_component_from_loadout(selected_loadout_index, component_index)
		refresh_ui()
		return

	if selected_inventory_index != -1:
		player.remove_component_from_inventory(selected_inventory_index, component_index)
		refresh_ui()


func _render_component_preview() -> void:
	if component_preview_panel == null:
		return

	component_preview_panel.visible = inventory_open
	for child in component_preview_sticker_container.get_children():
		child.queue_free()

	var component_id := _selected_component_id()
	if component_id.is_empty():
		component_preview_title.text = "Select a component"
		component_preview_description.text = "Choose a component from the inventory to inspect it before applying it."
		component_preview_stats.text = ""
		return

	var data := BulletTypes.component_data(component_id)
	component_preview_title.text = BulletTypes.component_name(component_id)
	component_preview_description.text = BulletTypes.component_description(component_id)
	component_preview_stats.text = "Value %d\nType %s" % [int(data.get("value", 0)), str(data.get("damage_type", "physical"))]

	var sticker_path := str(data.get("card_sticker", ""))
	var texture := BulletTypes.load_texture(sticker_path)
	print("Loading sticker for ", component_id, " from path: ", sticker_path, " - loaded: ", texture != null)
	var sticker: Control
	if texture != null:
		sticker = TextureRect.new()
		(sticker as TextureRect).texture = texture
		(sticker as TextureRect).stretch_mode = TextureRect.STRETCH_SCALE
	else:
		sticker = ColorRect.new()
		# Use a bright visible color as fallback
		(sticker as ColorRect).color = Color(0.3, 0.3, 0.3, 0.9)

	# Wrap the sticker inside a draggable container so the visual stays intact
	var container := Control.new()
	container.custom_minimum_size = Vector2(64.0, 64.0)
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Make sticker fill the container
	sticker.anchor_left = 0.0
	sticker.anchor_top = 0.0
	sticker.anchor_right = 1.0
	sticker.anchor_bottom = 1.0
	sticker.offset_left = 0.0
	sticker.offset_top = 0.0
	sticker.offset_right = 0.0
	sticker.offset_bottom = 0.0
	sticker.mouse_filter = Control.MOUSE_FILTER_IGNORE

	container.add_child(sticker)

	container.set_script(preload("res://scripts/draggable_component_sticker.gd"))
	container.set("component_id", component_id)
	container.set("component_name", BulletTypes.component_name(component_id))

	component_preview_sticker_container.add_child(container)


func _selected_component_id() -> String:
	if selected_component_index >= 0 and selected_component_index < player.component_inventory.size():
		return str(player.component_inventory[selected_component_index])
	return ""


func _find_component_inventory_index(component_id: String) -> int:
	for i in range(player.component_inventory.size()):
		if str(player.component_inventory[i]) == component_id:
			return i
	return -1


func _selected_editor_card() -> Dictionary:
	if selected_loadout_index >= 0 and selected_loadout_index < player.loadout.size():
		return player.loadout[selected_loadout_index]
	if selected_inventory_index >= 0 and selected_inventory_index < player.inventory.size():
		return player.inventory[selected_inventory_index]
	return {}


func _selected_editor_label() -> String:
	if selected_loadout_index != -1:
		return "Loadout"
	if selected_inventory_index != -1:
		return "Inventory"
	return "Card"


func _on_health_changed(current_health: int, max_health: int) -> void:
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_label.text = "%d / %d" % [current_health, max_health]


func _on_player_died() -> void:
	spawn_timer.stop()
	death_panel.visible = true


func _restart_run() -> void:
	get_tree().reload_current_scene()


func _is_tab_pressed(event: InputEvent) -> bool:
	return event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB
