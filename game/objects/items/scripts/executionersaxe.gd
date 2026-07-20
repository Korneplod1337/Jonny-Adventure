extends Item

func apply_item_effect() -> void:
	player.damage_bonus += 3
	player.accuracy_bonus += 1
	player.damage = StatManager.get_stat(player, "damage")
	player.spread = StatManager.get_stat(player, "spread")
	player._emit_stats_changed()
