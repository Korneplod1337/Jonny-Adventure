extends Item


func apply_item_effect() -> void:
	GameState.mimic_chest_chance = minf(GameState.mimic_chest_chance + 0.20, 1.0)
