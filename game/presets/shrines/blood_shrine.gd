extends Node2D

const SHRINE_SCENE := preload("res://game/presets/shrines/shrine.tscn")

@onready var interactable: Area2D = $Interactable
@onready var knife: Node2D = $knife
@onready var marker_chest: Marker2D = $MarkerChest

var _activated := false
var _loot: Node = null


func _ready() -> void:
	interactable.interact = _on_interact
	if GameState.has_level_buf("Destroyed"):
		visible = false
		interactable.is_interactable = false
		call_deferred("_replace_with_destroyed_shrine")
		return
	_spawn_locked_loot()


func _replace_with_destroyed_shrine() -> void:
	var parent := get_parent()
	if parent == null:
		queue_free()
		return
	var broken := SHRINE_SCENE.instantiate()
	broken.position = position
	parent.add_child(broken)
	parent.move_child(broken, get_index())
	queue_free()


func _process(_delta: float) -> void:
	if _activated or not is_instance_valid(knife):
		return
	knife.set_player_near(_is_player_in_interact_range())


func _is_player_in_interact_range() -> bool:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return false
	var comps := player.get_node_or_null("InteractingComponents")
	if comps == null:
		return false
	return interactable in comps.current_interactions


func _on_interact() -> void:
	if _activated or not interactable.is_interactable:
		return
	if not is_instance_valid(knife):
		return

	_activated = true
	interactable.is_interactable = false
	SoundManager.play_shine()
	knife.launch()


func on_sacrifice_complete() -> void:
	_unlock_loot()


func _spawn_locked_loot() -> void:
	var inst := _create_loot_instance()
	if inst == null:
		return
	add_child(inst)
	inst.position = marker_chest.position
	_set_pickup_collectable(inst, false)
	_loot = inst


func _unlock_loot() -> void:
	if is_instance_valid(_loot):
		_set_pickup_collectable(_loot, true)


func _create_loot_instance() -> Node2D:
	var player := get_tree().get_first_node_in_group("player")
	if randf() < 0.5:
		return _create_treasure_chest_loot(player)
	return _create_big_chest_loot(player)


func _create_treasure_chest_loot(player: Node) -> Node2D:
	# chest_treasure.gd: 75% item treasure/[1], 25% equip treasure/[1]
	var item_tiers: Array = [1]
	var eq_tiers: Array = [1]
	if player and player.has_method("get_chest_item_tiers"):
		item_tiers = player.get_chest_item_tiers([1])
	if player and player.has_method("get_chest_equip_tiers"):
		eq_tiers = player.get_chest_equip_tiers([1])

	if randi_range(1, 100) >= 75:
		var equip := _instantiate_equip("treasure", eq_tiers)
		if equip != null:
			return equip
		return _instantiate_item("treasure", item_tiers)
	var item := _instantiate_item("treasure", item_tiers)
	if item != null:
		return item
	return _instantiate_equip("treasure", eq_tiers)


func _create_big_chest_loot(player: Node) -> Node2D:
	# chest_big.gd without coins: non-coin weight is 20 item + 10 equip
	var item_tiers: Array = [1]
	var eq_tiers: Array = [1]
	if player and player.has_method("get_chest_item_tiers"):
		item_tiers = player.get_chest_item_tiers([1])
	if player and player.has_method("get_chest_equip_tiers"):
		eq_tiers = player.get_chest_equip_tiers([1])

	if randi_range(1, 30) > 20:
		var equip := _instantiate_equip("treasure", eq_tiers)
		if equip != null:
			return equip
		return _instantiate_item("chest", item_tiers)
	var item := _instantiate_item("chest", item_tiers)
	if item != null:
		return item
	return _instantiate_equip("treasure", eq_tiers)


func _instantiate_item(pool: String, tiers: Array) -> Node2D:
	var item := ItemManager.random_pick(pool, tiers)
	if item.is_empty():
		return null
	var inst: Node2D = item.scene.instantiate()
	if "where" in inst:
		inst.where = pool
	inst.set("cost", 0)
	return inst


func _instantiate_equip(pool: String, tiers: Array) -> Node2D:
	var equipment := EquipManager.random_pick(pool, tiers)
	if equipment.is_empty():
		return null
	var inst: Node2D = equipment["scene"].instantiate()
	if inst.get("type") == "weapon":
		inst.enchantment = EquipManager.roll_enchantment()
	inst.set("cost", 0)
	return inst


func _set_pickup_collectable(node: Node, enabled: bool) -> void:
	if node is Area2D:
		var interact: Area2D = node.get_node_or_null("Interactable") as Area2D
		if interact:
			interact.is_interactable = enabled
			interact.monitoring = enabled
			interact.set_deferred("monitorable", enabled)
		(node as Area2D).monitoring = enabled
		(node as Area2D).set_deferred("monitorable", enabled)
		return

	var area := node.get_node_or_null("Area2D") as Area2D
	if area:
		area.monitoring = enabled
		area.set_deferred("monitorable", enabled)
