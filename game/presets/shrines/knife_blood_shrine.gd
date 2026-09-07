extends Node2D

const FLY_SPEED := 550.0
const HIT_DISTANCE := 20.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var flying := false
var _player_near := false
var _hit := false


func _ready() -> void:
	sprite.play("default")


func set_player_near(near: bool) -> void:
	if flying or _hit:
		return
	if near == _player_near:
		return
	_player_near = near
	sprite.play("active" if near else "default")


func launch() -> void:
	flying = true


func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return

	_point_at(player.global_position)

	if not flying or _hit:
		return

	var to_player = player.global_position - global_position
	var dist = to_player.length()
	if dist <= HIT_DISTANCE:
		_on_hit(player)
		return

	global_position += to_player / dist * FLY_SPEED * delta
	if global_position.distance_to(player.global_position) <= HIT_DISTANCE:
		_on_hit(player)


func _point_at(target: Vector2) -> void:
	var dir := target - global_position
	if dir.length_squared() < 0.0001:
		return
	# Sprite default faces up (rotation 0).
	rotation = dir.angle() + PI / 2.0


func _on_hit(player: Node) -> void:
	if _hit:
		return
	_hit = true
	flying = false

	if player.has_method("take_damage"):
		player.take_damage(1)

	var shrine := get_parent()
	if shrine != null and shrine.has_method("on_sacrifice_complete"):
		shrine.on_sacrifice_complete()

	queue_free()
