class_name SpeedBoostOnHitModifier
extends HitModifier

const BUFF_NODE := "Kaliya_boots_buff"
const BUFF_SCRIPT := preload("res://game/objects/Equipment/boots/kaliya_boots_buff.gd")


func is_per_target() -> bool:
	return true


func apply(info: DamageInfo) -> void:
	if info.target == null:
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var player := tree.get_first_node_in_group("player")
	var buff := player.get_node_or_null(BUFF_NODE)
	if buff == null:
		buff = BUFF_SCRIPT.new()
		buff.name = BUFF_NODE
		player.add_child(buff)
	buff.add_stack()
