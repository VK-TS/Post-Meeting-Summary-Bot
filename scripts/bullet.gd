extends Area2D

var card := {}
var stats := {}
var velocity := Vector2.RIGHT
var damage := 1
var pierce_left := 0
var bullet_health := 1
var radius := 5.0
var color := Color.WHITE
var effects: Array = []
var has_homing := false
var source: Node = null
var visual_layers: Array = []
var projectile_texture: Texture2D = null
var spin_time := 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func setup(bullet_card: Dictionary, direction: Vector2, source_node: Node = null) -> void:
	card = bullet_card.duplicate(true)
	stats = BulletTypes.card_stats(card)
	velocity = direction.normalized() * float(stats["speed"])
	damage = int(stats["damage"])
	pierce_left = int(stats["pierce"])
	bullet_health = int(stats["health"])
	radius = float(stats["radius"])
	color = stats["color"]
	effects = stats["effects"]
	has_homing = bool(stats["has_homing"])
	visual_layers = stats.get("visual_layers", [])
	projectile_texture = BulletTypes.load_texture(str(stats.get("projectile_sprite", "")))
	source = source_node

func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision_shape.shape = shape
	area_entered.connect(_on_area_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	spin_time += delta
	if has_homing:
		_steer_toward_nearest_enemy(delta)

	position += velocity * delta
	queue_redraw()
	var viewport_rect := get_viewport_rect().grow(96.0)
	if not viewport_rect.has_point(position):
		queue_free()

func _draw() -> void:
	if projectile_texture != null:
		var size := Vector2.ONE * radius * 2.0
		draw_texture_rect(projectile_texture, Rect2(-size * 0.5, size), false)
	else:
		draw_circle(Vector2.ZERO, radius, color)

	for i in visual_layers.size():
		_draw_visual_layer(visual_layers[i], i)

func _on_area_entered(area: Area2D) -> void:
	if not area.has_method("take_damage"):
		return

	area.take_damage(damage, effects, source)

	bullet_health -= 1
	if pierce_left <= 0 or bullet_health <= 0:
		queue_free()
	else:
		pierce_left -= 1

func _steer_toward_nearest_enemy(delta: float) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest = null
	var nearest_distance := INF

	for enemy in enemies:
		if not is_instance_valid(enemy) or not (enemy is Node2D):
			continue

		var distance := global_position.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance

	if nearest == null:
		return

	var current_speed := velocity.length()
	var desired := global_position.direction_to(nearest.global_position) * current_speed
	velocity = velocity.lerp(desired, min(1.0, 4.0 * delta))

func _draw_visual_layer(layer: Dictionary, index: int) -> void:
	var texture := BulletTypes.load_texture(str(layer.get("sprite", "")))
	var layer_color: Color = layer.get("color", Color(1.0, 1.0, 1.0, 0.45))
	var layer_radius := radius + 3.0 + float(index * 2)

	if texture != null:
		var size := Vector2.ONE * layer_radius * 2.2
		draw_set_transform(Vector2.ZERO, spin_time * (1.5 + index), Vector2.ONE)
		draw_texture_rect(texture, Rect2(-size * 0.5, size), false, layer_color)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return

	var points := 8
	var offset := spin_time * (2.0 + index)
	for point in points:
		var angle := offset + TAU * float(point) / float(points)
		var center := Vector2.RIGHT.rotated(angle) * layer_radius
		draw_circle(center, 1.8, layer_color)

	draw_arc(Vector2.ZERO, layer_radius, offset, offset + PI * 1.35, 18, layer_color, 1.5)
