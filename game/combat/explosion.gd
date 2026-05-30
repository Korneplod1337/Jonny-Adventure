extends Area2D
class_name CombatExplosion

@export var base_collision_radius: float = 15.0
@export var magic_damage_per_point: float = 15.0

var radius: float = 80.0
var _damaged: Array[Node] = []

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func setup(explosion_radius: float) -> void:
	radius = explosion_radius


func _ready() -> void:
	collision_mask = 4

	var scale_factor := radius / base_collision_radius
	scale = Vector2.ONE * scale_factor

	_sprite.speed_scale = GameState.animated_world_speed
	_sprite.play("default")

	for body in get_overlapping_bodies():
		_damage_body(body)


func _on_body_entered(body: Node2D) -> void:
	_damage_body(body)


func _damage_body(body: Node) -> void:
	if body in _damaged or not _can_damage(body):
		return
	_damaged.append(body)

	var player := get_tree().get_first_node_in_group("player")
	var magic := StatManager.get_stat(player, "magic") if player else 0.0
	var amount := magic * magic_damage_per_point
	body.hit(amount, true)


func _can_damage(body: Node) -> bool:
	return body != null and body.has_method("hit") and body.name != "Player"


func _on_animation_finished() -> void:
	queue_free()
