# PlayerEquip.gd
extends Node

signal equipment_changed(equipped: Dictionary)

var equipped := {
	EquipManager.SlotType.HEAD: null,
	EquipManager.SlotType.GLOVES: null,
	EquipManager.SlotType.ARMOR: null,
	EquipManager.SlotType.WEAPON: null,
}

func equip_item(item: Node) -> void:
	var slot = item.slot_type
	var player := get_parent()
	var old_item = equipped[slot]

	if old_item and old_item.drop_scene:
		_drop(old_item, player.global_position)

	equipped[slot] = item
	if item.has_method("on_equipped"):
		item.on_equipped(player)
	equipment_changed.emit(equipped)

func _drop(item: Node, pos: Vector2) -> void:
	var scene = item.drop_scene
	if not scene:
		return
	var inst = scene.instantiate()
	inst.position = pos
	get_tree().current_scene.add_child(inst)
