extends Area2D
class_name CombatPoisonPuddle

@export var base_collision_radius: float = 15.0
@export var magic_damage_per_point: float = 15.0
@export var lifetime: float = 2.0

var radius: float = 50.0
var _active: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _damage_timer: Timer = $Timer


func setup(explosion_radius: float) -> void:
	radius = explosion_radius


func _ready() -> void:
	monitoring = false

	var scale_factor := radius / base_collision_radius
	scale = Vector2.ONE * scale_factor

	_sprite.speed_scale = GameState.animated_world_speed
	_sprite.play("spawn")


func _on_body_entered(body: Node2D) -> void:
	if _active and _can_damage(body):
		_damage_body(body)


func _on_damage_timer_timeout() -> void:
	_tick_damage()


func _tick_damage() -> void:
	if not _active:
		return
	for body in get_overlapping_bodies():
		if _can_damage(body):
			_damage_body(body)


func _damage_body(body: Node) -> void:
	var player := get_tree().get_first_node_in_group("player")
	var magic := StatManager.get_stat(player, "magic") if player else 0.0
	var amount := (1 + magic) * magic_damage_per_point
	if amount <= 0.0:
		return
	body.hit(amount, true)


func _can_damage(body: Node) -> bool:
	return body != null and body.has_method("hit") and not body.is_in_group("player")


func _activate() -> void:
	_active = true
	monitoring = true
	_sprite.play("default")
	_damage_timer.start()
	get_tree().create_timer(lifetime).timeout.connect(_start_end)
	call_deferred("_tick_damage")


func _start_end() -> void:
	if not _active:
		return
	_active = false
	_damage_timer.stop()
	set_deferred("monitoring", false)
	_sprite.play("end")


func _on_animation_finished() -> void:
	match _sprite.animation:
		&"spawn":
			_activate()
		&"end":
			queue_free()
