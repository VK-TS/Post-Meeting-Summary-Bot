extends CharacterBody2D

signal ammo_changed(hand: Array, selected_index: int, stored_cards: Array, loadout: Array, inventory: Array, components: Array)
signal health_changed(current_health: int, max_health: int)
signal died

@export var speed := 280.0
@export var max_health := 100

const MAGAZINE_SIZE := 5
const LOADOUT_SIZE := 12

var loadout: Array = []
var inventory: Array = []
var component_inventory: Array[String] = []
var magazine: Array = []
var selected_index := 0
var stored_cards: Array = []
var radius := 18.0
var current_health := max_health
var is_dead := false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var bullet_scene := preload("res://scenes/bullet.tscn")

func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision_shape.shape = shape
	current_health = max_health
	for i in range(LOADOUT_SIZE):
		loadout.append(BulletTypes.random_bullet_card())
	reload()
	_emit_health_changed()
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		return

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * speed
	move_and_slide()
	var viewport := get_viewport_rect()
	global_position.x = clampf(global_position.x, radius, viewport.size.x - radius)
	global_position.y = clampf(global_position.y, radius, viewport.size.y - radius)

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			shoot()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			store_selected_bullet()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			cycle_selection(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cycle_selection(1)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.9, 0.92, 1.0))
	draw_line(Vector2.ZERO, Vector2.RIGHT * 26.0, Color(0.1, 0.1, 0.14), 4.0)

func _process(_delta: float) -> void:
	if is_dead:
		return
	look_at(get_global_mouse_position())

func shoot() -> void:
	if not _has_active_cards():
		reload()
		return

	selected_index = _nearest_active_index(selected_index)
	if selected_index == -1:
		reload()
		return

	var slot: Dictionary = magazine[selected_index]
	var bullet_card: Dictionary = slot["card"].duplicate(true)
	var bullet = bullet_scene.instantiate()
	var direction := global_position.direction_to(get_global_mouse_position())
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT.rotated(rotation)

	bullet.global_position = global_position + direction * (radius + 8.0)
	bullet.setup(bullet_card, direction, self)
	get_tree().current_scene.add_child(bullet)

	slot["state"] = "fired"
	magazine[selected_index] = slot

	if _hand_resolved():
		reload()
	else:
		selected_index = _nearest_active_index(selected_index)
		_emit_ammo_changed()

func cycle_selection(offset: int) -> void:
	if not _has_active_cards():
		return
	selected_index = _active_index_from(selected_index, offset)
	_emit_ammo_changed()

func select_hand_index(index: int) -> void:
	if index < 0 or index >= magazine.size():
		return
	if str(magazine[index].get("state", "")) != "active":
		return

	selected_index = index
	_emit_ammo_changed()

func store_selected_bullet() -> void:
	if not _has_active_cards():
		return

	selected_index = _nearest_active_index(selected_index)
	if selected_index == -1:
		return

	var slot: Dictionary = magazine[selected_index]
	stored_cards.append(slot["card"].duplicate(true))
	slot["state"] = "stored"
	magazine[selected_index] = slot

	if _hand_resolved():
		reload()
	else:
		selected_index = _nearest_active_index(selected_index)
		_emit_ammo_changed()

func reload() -> void:
	magazine.clear()

	for card in stored_cards:
		magazine.append(_make_hand_slot(card))
	stored_cards.clear()

	while magazine.size() < MAGAZINE_SIZE:
		magazine.append(_make_hand_slot(loadout.pick_random()))

	selected_index = 0
	_emit_ammo_changed()

func add_bullet_type(type_id: String) -> void:
	add_drop(BulletTypes.create_card(type_id))

func add_drop(drop_data: Dictionary) -> void:
	if drop_data.get("kind", "bullet") == "component":
		component_inventory.append(str(drop_data.get("component_id", "")))
	else:
		inventory.append(drop_data.duplicate(true))

	_emit_ammo_changed()

func swap_inventory_with_loadout(inventory_index: int, loadout_index: int) -> void:
	if inventory_index < 0 or inventory_index >= inventory.size():
		return
	if loadout_index < 0 or loadout_index >= loadout.size():
		return
	print("Swapping",inventory_index,loadout_index)
	print("Inventory",BulletTypes.card_name(inventory[inventory_index]))
	print("Loadout",BulletTypes.card_name(loadout[loadout_index]))
	var old_loadout_bullet : Dictionary = loadout[loadout_index].duplicate(true)
	loadout[loadout_index] = inventory[inventory_index]
	inventory[inventory_index] = old_loadout_bullet
	_emit_ammo_changed()

func apply_component_to_loadout(component_index: int, loadout_index: int, drop_position) -> void:
	if component_index < 0 or component_index >= component_inventory.size():
		return
	if loadout_index < 0 or loadout_index >= loadout.size():
		return

	var component_id : String = component_inventory.pop_at(component_index)
	loadout[loadout_index] = BulletTypes.add_component(loadout[loadout_index], component_id, drop_position)
	_emit_ammo_changed()

func apply_component_to_inventory(component_index: int, inventory_index: int, drop_position) -> void:
	if component_index < 0 or component_index >= component_inventory.size():
		return
	if inventory_index < 0 or inventory_index >= inventory.size():
		return

	var component_id : String = component_inventory.pop_at(component_index)
	inventory[inventory_index] = BulletTypes.add_component(inventory[inventory_index], component_id, drop_position)
	_emit_ammo_changed()

func remove_component_from_loadout(loadout_index: int, component_index: int) -> void:
	if loadout_index < 0 or loadout_index >= loadout.size():
		return

	var card: Dictionary = loadout[loadout_index].duplicate(true)
	var components: Array = card.get("components", [])
	if component_index < 0 or component_index >= components.size():
		return

	var component_entry: Variant = components.pop_at(component_index)
	var component_id := BulletTypes.component_entry_id(component_entry)
	if component_id.is_empty():
		component_id = str(component_entry)
	component_inventory.append(component_id)
	card["components"] = components
	loadout[loadout_index] = card
	_emit_ammo_changed()

func remove_component_from_inventory(inventory_index: int, component_index: int) -> void:
	if inventory_index < 0 or inventory_index >= inventory.size():
		return

	var card: Dictionary = inventory[inventory_index].duplicate(true)
	var components: Array = card.get("components", [])
	if component_index < 0 or component_index >= components.size():
		return

	var component_entry: Variant = components.pop_at(component_index)
	var component_id := BulletTypes.component_entry_id(component_entry)
	if component_id.is_empty():
		component_id = str(component_entry)
	component_inventory.append(component_id)
	card["components"] = components
	inventory[inventory_index] = card
	_emit_ammo_changed()

func take_damage(amount: int) -> void:
	if is_dead:
		return

	current_health = max(0, current_health - max(0, amount))
	_emit_health_changed()

	if current_health <= 0:
		is_dead = true
		died.emit()

func heal(amount: int) -> void:
	if is_dead:
		return

	current_health = min(max_health, current_health + max(0, amount))
	_emit_health_changed()

func _make_hand_slot(card: Dictionary) -> Dictionary:
	return {
		"card": card.duplicate(true),
		"state": "active",
	}

func _has_active_cards() -> bool:
	for slot in magazine:
		if str(slot.get("state", "")) == "active":
			return true
	return false

func _hand_resolved() -> bool:
	return not _has_active_cards()

func _nearest_active_index(from_index: int) -> int:
	if magazine.is_empty():
		return -1

	var index := clampi(from_index, 0, magazine.size() - 1)
	if str(magazine[index].get("state", "")) == "active":
		return index

	return _active_index_from(index, 1)

func _active_index_from(from_index: int, offset: int) -> int:
	if magazine.is_empty():
		return -1

	var direction := 1 if offset >= 0 else -1
	var index := from_index
	for i in magazine.size():
		index = wrapi(index + direction, 0, magazine.size())
		if str(magazine[index].get("state", "")) == "active":
			return index

	return -1

func _emit_ammo_changed() -> void:
	if _has_active_cards():
		selected_index = _nearest_active_index(selected_index)
	else:
		selected_index = -1
	ammo_changed.emit(magazine, selected_index, stored_cards, loadout, inventory, component_inventory)

func _emit_health_changed() -> void:
	health_changed.emit(current_health, max_health)
