extends Base_equip


func effect_on() -> void:
	GameState.LuckyGoldShield = true


func effect_off() -> void:
	GameState.LuckyGoldShield = false
