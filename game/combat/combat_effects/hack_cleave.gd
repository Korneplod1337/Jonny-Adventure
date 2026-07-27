extends Area2D
class_name HackCleave

const SCENE := preload("res://game/combat/combat_effects/HackCleave.tscn")
const EXTRA_MARGIN := 8.0

var damage: float = 0.0
var _exclude: Node = null
var _hit_bodies: Array[Node] = []

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


static func spawn_batch(
	parent: Node,
	enemy: Node2D,
	flight_dir: Vector2,
	hack_damage: float,
	hack_count: int
) -> void:
	if parent == null or not is_instance_valid(enemy) or hack_count <= 0 or hack_damage <= 0.0:
		return
	var dir := flight_dir.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	var pos := _position_behind_enemy(enemy, dir)
	for _i in hack_count:
		var inst: HackCleave = SCENE.instantiate()
		inst.damage = hack_damage
		inst._exclude = enemy
		inst.rotation = dir.angle()
		parent.call_deferred('add_child', inst)
		inst.global_position = pos


static func _position_behind_enemy(enemy: Node2D, dir: Vector2) -> Vector2:
	var extent := _enemy_extent_along(enemy, dir)
	return enemy.global_position + dir * extent


static func _enemy_extent_along(enemy: Node2D, dir: Vector2) -> float:
	var col := enemy.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null or col.shape == null:
		return 40.0 + EXTRA_MARGIN

	var shape_scale := col.global_scale
	var shape := col.shape
	if shape is CircleShape2D:
		var circle := shape as CircleShape2D
		return circle.radius * maxf(absf(shape_scale.x), absf(shape_scale.y)) + EXTRA_MARGIN

	if shape is RectangleShape2D:
		var rect := shape as RectangleShape2D
		var half := rect.size * 0.5
		half = Vector2(absf(half.x * shape_scale.x), absf(half.y * shape_scale.y))
		var local_dir := dir.rotated(-enemy.global_rotation).normalized()
		return absf(local_dir.x) * half.x + absf(local_dir.y) * half.y + EXTRA_MARGIN

	return 40.0 + EXTRA_MARGIN


func setup(pos: Vector2, flight_dir: Vector2, hack_damage: float, exclude: Node) -> void:
	damage = hack_damage
	_exclude = exclude
	rotation = flight_dir.angle()
	if is_inside_tree():
		global_position = pos
	else:
		position = pos


func _ready() -> void:
	# magic: 0..4, luck: ~0.1..2.0 => scale_factor: 1 + (magic + luck)/3
	var shooter := get_tree().get_first_node_in_group("player")
	var magic := StatManager.get_stat(shooter, "magic") if shooter else 0.0
	var luck := StatManager.get_stat(shooter, "luck") if shooter else 0.0
	var scale_factor := 1.0 + (magic + luck) / 3.0
	scale = Vector2.ONE * scale_factor
	_sprite.speed_scale = GameState.animated_world_speed
	_sprite.play("default")
	call_deferred("_strike_overlapping")


func _strike_overlapping() -> void:
	if not is_instance_valid(self):
		return
	for body in get_overlapping_bodies():
		_try_hit(body)


func _on_body_entered(body: Node) -> void:
	_try_hit(body)


func _try_hit(body: Node) -> void:
	if body == null or body in _hit_bodies:
		return
	if body == _exclude:
		return
	if body.is_in_group("player") or body.name == "Player":
		return
	if not body.has_method("hit"):
		return
	_hit_bodies.append(body)
	# Без модификаторов / зачарований / вложенного hack
	body.hit(damage, true)


func _on_animation_finished() -> void:
	queue_free()
