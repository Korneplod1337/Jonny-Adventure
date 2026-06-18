extends Item

func apply_item_effect() -> void:
	GameState.enemy_ms_multiplier *= 0.1
	print(GameState.enemy_ms_multiplier)
