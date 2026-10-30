extends Node

const REGEN_INTERVAL := 10.0

var _timer := 0.0


func _process(delta: float) -> void:
	var player := get_parent()
	if player == null:
		return
	if int(player.hp_list.get("black", 0)) >= 1:
		_timer = 0.0
		return
	_timer += delta
	if _timer < REGEN_INTERVAL:
		return
	_timer = 0.0
	if player.has_method("heal"):
		player.heal(0, 0, 0, 1)
