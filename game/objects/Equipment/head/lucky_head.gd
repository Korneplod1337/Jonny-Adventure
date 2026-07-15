extends Base_equip


func effect_on() -> void:
	GameState.LuckyHead = true


func effect_off() -> void:
	GameState.LuckyHead = false
