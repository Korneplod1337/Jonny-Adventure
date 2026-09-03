extends Base_equip


func effect_on() -> void:
	var player := get_player()
	if player == null:
		return
	player.revival_count += 1


func effect_off() -> void:
	var player := get_player()
	if player == null:
		return
	player.revival_count = maxi(0, player.revival_count - 1)
