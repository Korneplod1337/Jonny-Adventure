extends Item

func apply_item_effect() -> void:
	GameState.iron_maiden_chance += effect_power #0.15
