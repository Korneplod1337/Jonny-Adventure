## Tattered Trade — в shop/armory снижает цену всех платных предметов в комнате на 1. Вне магазина — пустой каст. CD: этаж.
class_name TatteredTradeAbility
extends BaseAbility


func _init() -> void:
	ability_id = "TatteredTrade"
	cooldown_type = CooldownType.FLOOR


func activate() -> bool:
	if _is_in_shop_or_armory():
		_discount_by_scan(player.get_tree().current_scene)
	return true


func _is_in_shop_or_armory() -> bool:
	var dungeon = player.get_tree().current_scene
	if dungeon == null or not ("rooms" in dungeon) or not ("current_room_pos" in dungeon):
		return false
	if not dungeon.rooms.has(dungeon.current_room_pos):
		return false
	var room = dungeon.rooms[dungeon.current_room_pos]
	var room_type: int = int(room.type)
	return room_type == int(dungeon.RoomType.SHOP) \
		or room_type == int(dungeon.RoomType.ARMORY)


func _discount_by_scan(root: Node) -> void:
	if root == null:
		return
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		_try_discount(n)
		for child in n.get_children():
			stack.append(child)


func _try_discount(node: Node) -> void:
	if not ("cost" in node):
		return
	var c: int = int(node.cost)
	if c < 1:
		return
	node.cost = c - 1
	_refresh_interact_label(node)


func _refresh_interact_label(node: Node) -> void:
	var interactable = node.get_node_or_null("Interactable")
	if interactable == null:
		return
	var gs = GameState
	var shown_cost: int = int((node.cost + gs.cost_plus) * gs.cost_multiplier)
	if node is Item:
		if node.cost < 1:
			interactable.interact_name = node.item_tooltip
		else:
			interactable.interact_name = "%s by %s coins" % [node.item_tooltip, shown_cost]
		return
	if "interact_name" in node:
		var base_name: String = str(node.interact_name)
		if node.cost < 1:
			interactable.interact_name = "Take " + base_name
		else:
			interactable.interact_name = "Take " + base_name + " by %s coins" % shown_cost
