extends Area2D

signal died(position: Vector2)

@export var speed := 100.0
@export var health := 2
@export var contact_damage := 15

var target: Node2D
var radius := 15.0
var active_effects: Array = []
var is_dead := false

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("enemies")
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision_shape.shape = shape
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if is_dead or not is_instance_valid(target):
		return
	if _has_blocking_status():
		return

	var direction := global_position.direction_to(target.global_position)
	global_position += direction * speed * delta

func _process(delta: float) -> void:
	if is_dead:
		return

	_tick_status_effects(delta)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.25, 0.95, 0.5))
	draw_circle(Vector2(-5, -4), 2.5, Color.BLACK)
	draw_circle(Vector2(5, -4), 2.5, Color.BLACK)

func take_damage(amount: int, effects: Array = [], source: Node = null) -> void:
	if is_dead:
		return

	health -= amount
	for effect in effects:
		_apply_status_effect(effect, source)

	if health <= 0:
		_die()

func _apply_status_effect(effect: Dictionary, source: Node = null) -> void:
	var lifespan := float(effect.get("lifespan", 0.0))
	if lifespan <= 0.0:
		health -= int(effect.get("damage", 0))
		return

	active_effects.append({
		"id": str(effect.get("id", "")),
		"damage": int(effect.get("damage", 0)),
		"lifespan": lifespan,
		"remaining": lifespan,
		"tick_interval": float(effect.get("tick_interval", 1.0)),
		"tick_timer": 0.0,
		"source": source,
	})

func _tick_status_effects(delta: float) -> void:
	for i in range(active_effects.size() - 1, -1, -1):
		var effect: Dictionary = active_effects[i]
		effect["remaining"] = float(effect["remaining"]) - delta
		effect["tick_timer"] = float(effect["tick_timer"]) - delta

		if float(effect["tick_timer"]) <= 0.0:
			effect["tick_timer"] = float(effect["tick_interval"])
			health -= int(effect["damage"])
			_apply_lifesteal(effect)

		if float(effect["remaining"]) <= 0.0:
			active_effects.remove_at(i)
		else:
			active_effects[i] = effect

		if health <= 0:
			_die()
			return

func _apply_lifesteal(effect: Dictionary) -> void:
	if str(effect.get("id", "")) != "lifesteal":
		return

	var source = effect.get("source", null)
	if source != null and is_instance_valid(source) and source.has_method("heal"):
		source.heal(int(effect.get("damage", 0)))

func _has_blocking_status() -> bool:
	for effect in active_effects:
		var id := str(effect.get("id", ""))
		if id == "stun" or id == "sleep" or id == "freeze":
			return true
	return false

func _on_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body.has_method("take_damage"):
		body.take_damage(contact_damage)
		is_dead = true
		queue_free()

func _die() -> void:
	if is_dead:
		return

	is_dead = true
	died.emit(global_position)
	queue_free()
