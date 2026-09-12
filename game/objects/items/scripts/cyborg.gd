extends Item

const MAX_CONVERT := 4


func apply_item_effect() -> void:
	var live := int(player.hp_list["red"]) + int(player.hp_list["green"])
	var empty := maxi(0, int(player.max_hp) - live)
	var converted := 0

	# 1) Сначала пустые слоты max HP → щиты
	var from_empty := mini(MAX_CONVERT, empty)
	if from_empty > 0:
		player.base_max_hp -= from_empty
		player.hp_list["black"] += from_empty
		converted += from_empty

	# 2) Если не хватило — забираем заполненные сердца вместе с max HP
	var still_need := MAX_CONVERT - converted
	if still_need > 0:
		var red := int(player.hp_list["red"])
		var green := int(player.hp_list["green"])
		var from_filled := mini(still_need, red + green)
		if from_filled > 0:
			var to_remove := from_filled
			var take_red := mini(red, to_remove)
			player.hp_list["red"] -= take_red
			to_remove -= take_red
			player.hp_list["green"] -= to_remove
			player.base_max_hp -= from_filled
			player.hp_list["black"] += from_filled
			converted += from_filled

	if converted <= 0:
		return

	player.max_hp = maxi(0, int(StatManager.get_stat(player, "hp")))
	live = int(player.hp_list["red"]) + int(player.hp_list["green"])
	if live > player.max_hp:
		var overflow = live - player.max_hp
		var take_green := mini(int(player.hp_list["green"]), overflow)
		player.hp_list["green"] -= take_green
		overflow -= take_green
		player.hp_list["red"] = maxi(0, int(player.hp_list["red"]) - overflow)

	player.base_damage += effect_power * converted #10
	player.damage = StatManager.get_stat(player, "damage")
	player._emit_hp_visual_changed()
	player._emit_stats_changed()
