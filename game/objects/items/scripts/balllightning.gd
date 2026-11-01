extends Item

const PROC_BONUS_PER_STACK := 0.10


func apply_item_effect() -> void:
	player.fire_rate_bonus += 2
	player.magic_bonus += 2
	player.ball_lightning_proc_bonus += PROC_BONUS_PER_STACK
	player.fire_rate = StatManager.get_stat(player, "fire_rate")
	player.magic = StatManager.get_stat(player, "magic")
	player._emit_stats_changed()
