extends Item

func apply_item_effect() -> void:
	GameState.enemy_hp_multiplier *= effect_power #0.95
	var floor: int = get_tree().current_scene.current_floor
	player.luck_bonus += int(floor / 2) + 1
	player.luck = StatManager.get_stat(player, "luck")
	player._emit_stats_changed()
