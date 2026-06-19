extends Base_equip


func effect_on() -> void:
	GameState.Surestrike = true

func effect_off() -> void:
	GameState.Surestrike = false
