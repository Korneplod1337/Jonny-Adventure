class_name CoinRouletteAbility
extends BaseAbility

const SUCCESS_CHANCE := 0.6


func _init() -> void:
	ability_id = "CoinRoulette"
	cooldown_type = CooldownType.TIME
	cooldown_time = 1.0


func activate() -> bool:
	if randf() < SUCCESS_CHANCE:
		GameState.add_coins(1)
	else:
		player.take_damage(1)
	return true
