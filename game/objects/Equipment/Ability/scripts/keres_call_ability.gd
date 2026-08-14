## Keres' Call — заготовка: должно призывать демона (логика пока не реализована).
class_name KeresCallAbility
extends BaseAbility


func _init() -> void:
	ability_id = "KeresCall"
	cooldown_type = CooldownType.FLOOR


func activate() -> bool:
	# TODO: spawn demon near the player.
	return true
