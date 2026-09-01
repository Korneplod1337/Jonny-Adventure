extends Base_equip

const SPEED_BONUS := 8
const ANIM_SPEED_BONUS := 0.2


func effect_on() -> void:
	var player := get_player()
	player.speed_bonus += SPEED_BONUS
	player.move_speed = StatManager.get_stat(player, "move_speed")
	player._emit_stats_changed()
	GameState.animated_world_speed += ANIM_SPEED_BONUS


func effect_off() -> void:
	var player := get_player()
	player.speed_bonus -= SPEED_BONUS
	player.move_speed = StatManager.get_stat(player, "move_speed")
	player._emit_stats_changed()
	GameState.animated_world_speed -= ANIM_SPEED_BONUS
