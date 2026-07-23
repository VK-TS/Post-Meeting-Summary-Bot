extends Area2D

var drop_data := {}
var radius := 10.0
var color := Color.WHITE

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func setup(data: Dictionary) -> void:
	drop_data = data.duplicate(true)
	if drop_data.get("kind", "bullet") == "component":
		color = Color(0.95, 0.65, 1.0)
	else:
		var info := BulletTypes.card_stats(drop_data)
		color = info["color"]

func _ready() -> void:
	call_deferred("_initialize_drop_shape")
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _initialize_drop_shape() -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision_shape.shape = shape

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius + 3.0, 0.0, TAU, 24, Color.WHITE, 2.0)
	if drop_data.get("kind", "bullet") == "component":
		draw_line(Vector2(-5, 0), Vector2(5, 0), Color.WHITE, 2.0)
		draw_line(Vector2(0, -5), Vector2(0, 5), Color.WHITE, 2.0)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("add_drop"):
		body.add_drop(drop_data)
		queue_free()
