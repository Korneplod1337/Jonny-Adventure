extends Base_equip

const DAMAGE_CAP := 1


func effect_on() -> void:
	var player := get_player()
	if player:
		player.incoming_damage_cap = DAMAGE_CAP


func effect_off() -> void:
	var player := get_player()
	if player:
		player.incoming_damage_cap = -1
