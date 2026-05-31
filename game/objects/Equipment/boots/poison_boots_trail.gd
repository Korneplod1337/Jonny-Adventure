extends Node

const POISON_PUDDLE_SCENE := preload("res://game/combat/combat_effects/poison_puddle.tscn")

@export var step_distance: float = 500.0

var _distance_since_last: float = 0.0
var _prev_foot_pos: Vector2
var _player: CharacterBody2D


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if _player:
		_prev_foot_pos = _foot_position()


func _process(delta: float) -> void:
	if _player == null:
		return

	var move_dir = _player.now_move_direction
	var moved = move_dir.length() * delta
	if moved < 0.5:
		return

	_distance_since_last += moved
	var magic := StatManager.get_stat(_player, "magic")
	if _distance_since_last >= step_distance / (1.0 + magic):
		_spawn_puddle(_prev_foot_pos)
		_distance_since_last = 0.0

	_prev_foot_pos = _foot_position()


func _foot_position() -> Vector2:
	return _player.global_position + Vector2(0, 16.0 * _player.scale.y)


func _spawn_puddle(at_position: Vector2) -> void:
	var puddle: CombatPoisonPuddle = POISON_PUDDLE_SCENE.instantiate()
	puddle.global_position = at_position
	get_tree().current_scene.add_child(puddle)
