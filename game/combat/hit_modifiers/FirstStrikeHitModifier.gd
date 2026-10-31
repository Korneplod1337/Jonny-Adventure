class_name FirstStrikeHitModifier
extends HitModifier

## Суммарный бонус первого удара (Guillotine 0.15, Ballista 0.30, стакается).
var bonus: float = 0.0

var _struck: Dictionary = {}


func is_per_target() -> bool:
	return true


func apply(info: DamageInfo) -> void:
	if info.target == null or bonus <= 0.0:
		return
	var id := info.target.get_instance_id()
	if _struck.has(id):
		return
	_struck[id] = true
	info.damage *= (1.0 + bonus)
