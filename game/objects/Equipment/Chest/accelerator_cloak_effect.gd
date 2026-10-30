extends Node

const MAX_SPEED := 600.0
const MIN_BOOST := 1.0
const MAX_BOOST := 0.5
const LINGER_SEC := 1.0

var _linger_left := 0.0
var _held_boost := MIN_BOOST


func _process(delta: float) -> void:
	var player := get_parent()
	if player == null:
		return
	var speed: float = player.now_move_direction.length()
	if speed > 1.0:
		var t := clampf(speed / MAX_SPEED, 0.0, 1.0)
		_held_boost = lerpf(MIN_BOOST, MAX_BOOST, t)
		_linger_left = LINGER_SEC
		player.EquipFireRateBoost = _held_boost
		return
	if _linger_left > 0.0:
		_linger_left = maxf(0.0, _linger_left - delta)
		player.EquipFireRateBoost = _held_boost
		return
	player.EquipFireRateBoost = MIN_BOOST


func update_boost() -> void:
	# Kept for fire() callers; continuous update is in _process.
	_process(0.0)
