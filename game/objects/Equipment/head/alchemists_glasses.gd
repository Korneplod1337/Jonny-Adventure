extends Base_equip


func effect_on() -> void:
	GameState.AlchemistsGlasses = true

func effect_off() -> void:
	GameState.AlchemistsGlasses = false
