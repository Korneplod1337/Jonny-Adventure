extends Base_equip


func effect_on() -> void:
	GameState.SpreadShot = true


func effect_off() -> void:
	GameState.SpreadShot = false
