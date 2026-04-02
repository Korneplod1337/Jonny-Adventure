extends Base_equip

func effect_on() -> void:
	GameState.test_chest = true

func effect_off() -> void:
	GameState.test_chest = false
