extends Item

func apply_item_effect() -> void:
	player.hack_bonus += 1
	player.damage_bonus += 1
	player.accuracy_bonus += 1
	player.damage = StatManager.get_stat(player, "damage")
	player.spread = StatManager.get_stat(player, "spread")
	player._emit_stats_changed()
