## Maria, the goddess of life Call — заготовка: должно призывать ангела (логика пока не реализована).
class_name MariaCallAbility
extends BaseAbility


func _init() -> void:
	ability_id = "MariaCall"
	cooldown_type = CooldownType.FLOOR


func activate() -> bool:
	# TODO: spawn angel near the player.
	return true
