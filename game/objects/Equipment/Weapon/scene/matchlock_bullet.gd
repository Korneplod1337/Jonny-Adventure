extends BaseGun
class_name MatchlockGun

func _ready() -> void:
	super()
	var luck := StatManager.get_stat(player, "luck")
	if randf() < maxf(0.0, 0.3 - luck / 4.0):
		_misfire()

func _misfire() -> void:
	exploded = true
	explosion(1)

func _deal_hit(target: Node, amount: float) -> void:
	var info := _build_damage_info(target, amount)
	DamageDealer.deal_damage(self, target, info)
	if enchantment and randf() < StatManager.get_stat(player, "luck") / 1.5:
		enchantment.apply_on_hit(target, info.direction)
