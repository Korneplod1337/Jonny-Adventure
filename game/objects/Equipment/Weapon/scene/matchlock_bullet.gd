extends BaseGun
class_name MatchlockGun

var _did_misfire := false


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	var luck := 0.0
	if player:
		luck = StatManager.get_stat(player, "luck")
	_did_misfire = randf() < maxf(0.0, 0.3 - luck / 4.0)
	super()
	if _did_misfire:
		_misfire()


func _play_attack_sfx() -> void:
	if _did_misfire:
		SoundManager.play_misfire()
		return
	super._play_attack_sfx()


func _misfire() -> void:
	exploded = true
	explosion(1)


func _deal_hit(target: Node, amount: float) -> void:
	var info := _build_damage_info(target, amount)
	DamageDealer.deal_damage(self, target, info)
	_show_crit_effect()
	_spawn_hack_effects(target, amount)
	if enchantment and randf() < StatManager.get_stat(player, "luck") / 1.5:
		enchantment.apply_on_hit(target, info.direction, hack, info.hack_direction)
