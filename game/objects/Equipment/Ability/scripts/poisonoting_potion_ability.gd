## Poisonoting Potion — меняет случайное зелье в текущей комнате на чёрное.
## CD при успехе: 5 комнат ИЛИ этаж. Если менять нечего — каст не срабатывает.
class_name PoisonotingPotionAbility
extends BaseAbility

const BLACK_POTION_SCENE := preload("res://game/objects/items/scenes/tier 0/Potion Death.tscn")
const CONVERTIBLE_IDS: Array[String] = ["heal", "healalt", "healbig"]
const SUCCESS_ROOMS := 5


func _init() -> void:
	ability_id = "PoisonotingPotion"
	cooldown_type = CooldownType.ROOMS
	cooldown_rooms = SUCCESS_ROOMS


func activate() -> bool:
	var potions := _find_convertible_potions()
	if potions.is_empty():
		return false
	_replace_with_black(potions[randi() % potions.size()])
	return true


func notify_floor_advanced() -> void:
	if not _is_equipped():
		return
	if _on_cooldown and cooldown_type == CooldownType.ROOMS:
		_finish_cooldown()
		return
	super.notify_floor_advanced()


func _find_convertible_potions() -> Array[Item]:
	var result: Array[Item] = []
	var room_root := _get_room_scene()
	var room_rect := _get_room_rect(room_root)
	var scan_root: Node = player.get_tree().current_scene
	if scan_root == null:
		return result

	var stack: Array[Node] = [scan_root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Item and is_instance_valid(n):
			var item := n as Item
			if _is_convertible_potion(item) and _is_in_current_room(item, room_root, room_rect):
				result.append(item)
		for child in n.get_children():
			stack.append(child)
	return result


func _is_convertible_potion(item: Item) -> bool:
	if CONVERTIBLE_IDS.has(item.item_id):
		return true
	var script: Script = item.get_script()
	if script == null:
		return false
	var path := script.resource_path
	if path.ends_with("Poison Black.gd"):
		return false
	return path.ends_with("Poison Red.gd") \
		or path.ends_with("Poison Green.gd") \
		or path.ends_with("potion_red_big.gd")


func _is_in_current_room(item: Item, room_root: Node, room_rect: Rect2) -> bool:
	if room_root != null and room_root.is_ancestor_of(item):
		return true
	if room_rect.has_area() and room_rect.has_point(item.global_position):
		return true
	return false


func _get_room_scene() -> Node2D:
	var dungeon = player.get_tree().current_scene
	if dungeon == null or not ("rooms" in dungeon) or not ("current_room_pos" in dungeon):
		return null
	if not dungeon.rooms.has(dungeon.current_room_pos):
		return null
	var room = dungeon.rooms[dungeon.current_room_pos]
	return room.scene as Node2D


func _get_room_rect(room_root: Node2D) -> Rect2:
	if room_root == null:
		return Rect2()
	var bounds_node := room_root.get_node_or_null("CameraBounds") as Area2D
	if bounds_node == null:
		return Rect2()
	var shape_node := bounds_node.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return Rect2()
	var rect_shape := shape_node.shape as RectangleShape2D
	if rect_shape == null:
		return Rect2()
	var center := bounds_node.global_position
	var size := rect_shape.size
	return Rect2(center - size * 0.5, size)


func _replace_with_black(old: Item) -> void:
	var parent := old.get_parent()
	if parent == null:
		return
	var global_pos := old.global_position
	var saved_cost: int = int(old.cost)
	var saved_where: String = str(old.where)

	var black: Item = BLACK_POTION_SCENE.instantiate()
	parent.add_child(black)
	black.global_position = global_pos
	black.where = saved_where
	black.cost = saved_cost
	_refresh_interact_label(black)

	old.queue_free()


func _refresh_interact_label(item: Item) -> void:
	var interactable = item.get_node_or_null("Interactable")
	if interactable == null:
		return
	var gs = GameState
	if item.cost < 1:
		interactable.interact_name = item.item_name
	else:
		var shown_cost: int = int((item.cost + gs.cost_plus) * gs.cost_multiplier)
		interactable.interact_name = "%s by %s coins" % [item.item_name, shown_cost]
