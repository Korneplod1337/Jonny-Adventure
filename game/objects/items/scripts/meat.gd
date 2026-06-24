extends Item

func apply_item_effect() -> void:
	player.hp_bonus += 1
	player.heal(1)
	player.max_hp = int(StatManager.get_stat(player, "hp"))
	player._emit_stats_changed()
