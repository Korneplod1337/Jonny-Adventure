extends Item

func apply_item_effect() -> void:
	if DungeonManager.selected_character == "Joab":
		player.hp_bonus += 5
		player.heal(0, 0, 0, 5)
	else:
		player.hp_bonus -= 5
	player.max_hp = int(StatManager.get_stat(player, "hp"))
	player._emit_stats_changed()
