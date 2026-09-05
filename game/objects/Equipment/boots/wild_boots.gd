extends Base_equip


func effect_on() -> void:
	GameState.WildBoots = true


func effect_off() -> void:
	GameState.WildBoots = false
