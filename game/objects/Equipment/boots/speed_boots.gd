extends Base_equip

const SPEED_BONUS := 8


func effect_on() -> void:
	var player := get_player()
	player.speed_bonus += SPEED_BONUS
	player.move_speed = StatManager.get_stat(player, "move_speed")
	player._emit_stats_changed()


func effect_off() -> void:
	var player := get_player()
	player.speed_bonus -= SPEED_BONUS
	player.move_speed = StatManager.get_stat(player, "move_speed")
	player._emit_stats_changed()
