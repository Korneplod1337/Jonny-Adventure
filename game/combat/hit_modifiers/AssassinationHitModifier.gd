class_name AssassinationHitModifier
extends HitModifier

## Первый удар по цели: BaseShot форсит +1 уровень крита (см. DamageDealer.try_assassination_first_hit).
var _struck: Dictionary = {}


func is_per_target() -> bool:
	return true


func should_force_crit(target: Node) -> bool:
	if target == null:
		return false
	var id := target.get_instance_id()
	if _struck.has(id):
		return false
	_struck[id] = true
	return true


func apply(_info: DamageInfo) -> void:
	pass
