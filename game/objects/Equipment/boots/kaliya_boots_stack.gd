extends Node

const SPEED_FLAT := 20.0
const DURATION := 3.0

var _applied := false


func _ready() -> void:
	var player := _player()
	if player == null:
		queue_free()
		return
	player.EquipMoveSpeedFlat += SPEED_FLAT * (0.5 + StatManager.get_stat(player, 'magic')/2)
	_applied = true
	_recalc_speed(player)
	var timer := Timer.new()
	timer.wait_time = DURATION
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(_on_timeout)
	timer.start()


func _on_timeout() -> void:
	expire_now()
	queue_free()


func expire_now() -> void:
	if not _applied:
		return
	_applied = false
	var player := _player()
	if player == null:
		return
	player.EquipMoveSpeedFlat -= SPEED_FLAT * (0.5 + StatManager.get_stat(player, 'magic')/2)
	_recalc_speed(player)


func _player() -> Node:
	var container := get_parent()
	if container == null:
		return null
	return container.get_parent()


func _recalc_speed(player: Node) -> void:
	player.move_speed = StatManager.get_stat(player, "move_speed")
	player._emit_stats_changed()
