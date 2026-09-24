extends BaseGun
class_name SniperGun


func _ready() -> void:
	super()
	#self_damage_multiplier = 1.1
	base_crit_bonus = 70.0
	crit_spread_offset = 30.0
	extra_reload = 0.6
