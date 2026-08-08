extends Item

func apply_item_effect() -> void:
	player.incoming_damage_cap = int(effect_power) #1
	player.immune_time_bonus += 0.1
	player.magic_bonus += 1
	player.magic = StatManager.get_stat(player, "magic")
	player._emit_stats_changed()
