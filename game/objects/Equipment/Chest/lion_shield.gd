extends Base_equip


func effect_on() -> void:
	var player := get_player()
	if player == null:
		return
	if player.has_method("add_revival"):
		player.add_revival(false, 2.0)
	else:
		player.revival_count += 1


func effect_off() -> void:
	var player := get_player()
	if player == null:
		return
	if player.has_method("consume_revival_charge"):
		player.consume_revival_charge()
	else:
		player.revival_count = maxi(0, player.revival_count - 1)
