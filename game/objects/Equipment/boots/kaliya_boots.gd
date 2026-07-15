extends Base_equip

const MODIFIER_ID := "Kaliya_boots"


func effect_on() -> void:
	var modifier := SpeedBoostOnHitModifier.new()
	DamageDealer.add_modifier(modifier, MODIFIER_ID)


func effect_off() -> void:
	DamageDealer.remove_modifier_by_id(MODIFIER_ID)
	var player := get_player()
	if player == null:
		return
	var buff := player.get_node_or_null(SpeedBoostOnHitModifier.BUFF_NODE)
	if buff:
		buff.queue_free()
