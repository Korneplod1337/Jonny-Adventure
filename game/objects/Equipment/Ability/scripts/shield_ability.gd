## Shield — краткая неуязвимость на время эффекта в центре игрока. CD: 2 с.
class_name ShieldAbility
extends BaseAbility

const EFFECT_SCENE := preload("res://game/objects/Equipment/Ability/effects/ShieldEffect.tscn")


func _init() -> void:
	ability_id = "Shield"
	cooldown_type = CooldownType.TIME
	cooldown_time = 2.0


func activate() -> bool:
	if player.get_node_or_null("AbilityShieldEffect"):
		return false
	var fx := EFFECT_SCENE.instantiate()
	fx.name = "AbilityShieldEffect"
	player.add_child(fx)
	return true
