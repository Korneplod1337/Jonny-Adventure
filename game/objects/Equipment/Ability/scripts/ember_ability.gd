## Ember — заготовка fireball-заклинания (логика пока не реализована).
class_name EmberAbility
extends BaseAbility


func _init() -> void:
	ability_id = "Ember"
	cooldown_type = CooldownType.TIME
	cooldown_time = 5.0


func activate() -> bool:
	# TODO: fireball — направить снаряд/взрыв по направлению выстрела/движения.
	return true
