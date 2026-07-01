extends Item

func apply_item_effect() -> void:
	GameState.enemy_hp_multiplier *= effect_power #0.9
