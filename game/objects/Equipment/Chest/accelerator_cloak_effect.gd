extends Node

const MAX_SPEED := 700.0
const MIN_BOOST := 1.0
const MAX_BOOST := 0.5


func update_boost() -> void:
	var player := get_parent()
	if player == null:
		return
	var speed: float = player.now_move_direction.length()
	var t := clampf(speed / MAX_SPEED, 0.0, 1.0)
	player.EquipFireRateBoost = lerpf(MIN_BOOST, MAX_BOOST, t)
