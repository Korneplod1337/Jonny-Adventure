extends Base_equip

const EXPLODE_CHANCE := 0.25


func effect_on() -> void:
	GameState.iron_maiden_chance += EXPLODE_CHANCE


func effect_off() -> void:
	GameState.iron_maiden_chance -= EXPLODE_CHANCE
