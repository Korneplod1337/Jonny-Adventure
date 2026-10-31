class_name AssassinationHitModifier
extends HitModifier

## Первый удар по цели: +stacks уровней крита (кап 5 в BaseShot).
var stacks: int = 1
var _struck: Dictionary = {}


func is_per_target() -> bool:
	return true


## Сколько уровней крита форсить на первом ударе по цели (0 если уже били).
func consume_first_hit_stacks(target: Node) -> int:
	if target == null or stacks <= 0:
		return 0
	var id := target.get_instance_id()
	if _struck.has(id):
		return 0
	_struck[id] = true
	return stacks


func apply(_info: DamageInfo) -> void:
	pass
