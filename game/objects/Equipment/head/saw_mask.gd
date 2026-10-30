extends Base_equip

const CUTSCENE := preload("res://game/objects/Equipment/head/saw_mask_cutscene.gd")


func effect_on() -> void:
	var player := get_player()
	if player == null:
		return
	if GameState.SawMask and player.saw_mask_active:
		return

	player.accuracy_bonus -= 8
	player.range_bonus -= 2
	player.damage_bonus += 5
	player.base_damage += 5
	player.speed_bonus -= 2
	player.magic_bonus += 5
	player.move_speed = StatManager.get_stat(player, "move_speed")
	player.magic = StatManager.get_stat(player, "magic")
	player.damage = StatManager.get_stat(player, "damage")
	player.spread = StatManager.get_stat(player, "spread")
	player.atk_range = StatManager.get_stat(player, "range")
	player._emit_stats_changed()

	# SawMask сразу — блок слота Head и баффы выстрела; hide головы только после кат-сцены
	GameState.SawMask = true

	var cut: Node = CUTSCENE.new()
	cut.run(player)


func effect_off() -> void:
	# Закреплён до конца забега — снять нельзя; no-op на случай certain_spawn.
	pass
