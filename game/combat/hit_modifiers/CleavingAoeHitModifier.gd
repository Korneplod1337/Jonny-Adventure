class_name CleavingAoeHitModifier
extends HitModifier


func apply(info: DamageInfo) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var player := tree.get_first_node_in_group("player")
	var magic := 0.0
	if player:
		magic = StatManager.get_stat(player, "magic")
	var radius := 60.0 * (1.0 + magic / 2.0)
	info.aoe_radius = maxf(info.aoe_radius, radius)
