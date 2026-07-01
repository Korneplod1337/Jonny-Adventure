extends Item


func apply_item_effect() -> void:
	GameState.add_coins(randi_range(-3, 6))
	player.fire_rate_bonus += 1
	player.fire_rate = StatManager.get_stat(player, "fire_rate")
	player._emit_stats_changed()
