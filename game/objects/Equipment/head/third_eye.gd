extends Base_equip


func effect_on() -> void:
	var player := get_player()
	if player == null:
		return
	player.minimap += 1
	var dungeon := get_tree().current_scene
	if dungeon and dungeon.has_method("refresh_minimap"):
		dungeon.refresh_minimap()


func effect_off() -> void:
	var player := get_player()
	if player == null:
		return
	player.minimap = maxi(1, player.minimap - 1)
	var dungeon := get_tree().current_scene if is_inside_tree() else null
	if dungeon == null:
		var tree := Engine.get_main_loop() as SceneTree
		if tree:
			dungeon = tree.current_scene
	if dungeon and dungeon.has_method("refresh_minimap"):
		dungeon.refresh_minimap()
