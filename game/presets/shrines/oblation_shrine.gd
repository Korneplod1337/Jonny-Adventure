extends Node2D

const LVLUP_SCENE := preload("res://game/objects/items/scenes/tier 0/LvlupRandom.tscn")
const POTION_HEAL_SCENE := preload("res://game/objects/items/scenes/tier 0/Potion Red.tscn")
const REWARD_TIERS := [0, 1, 2, 3]
const ITEM_CHANCE := 0.75

@onready var interactable: Area2D = $Interactable
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var marker: Marker2D = $MarkerChest

var coin_cost: int = 1
var coins_paid: int = 0
var _activated := false


func _ready() -> void:
	if GameState.has_level_buf("Destroyed"):
		visible = false
		interactable.is_interactable = false
		call_deferred("_replace_with_destroyed_shrine")
		return

	coin_cost = randi_range(1, 6)
	coins_paid = 0
	interactable.interact = _on_interact
	sprite.animation = "completion"
	sprite.frame = 0
	sprite.pause()
	print("Шрайн: oblation (cost ", coin_cost, ")")


func _replace_with_destroyed_shrine() -> void:
	var parent := get_parent()
	if parent == null:
		queue_free()
		return
	var broken := preload("res://game/presets/shrines/shrine.tscn").instantiate()
	broken.position = position
	parent.add_child(broken)
	parent.move_child(broken, get_index())
	queue_free()


func _on_interact() -> void:
	if _activated or not interactable.is_interactable:
		return
	if GameState.coins < 1:
		return
	GameState.add_coins(-1)
	coins_paid += 1

	if coins_paid >= coin_cost:
		SoundManager.play_shine()
		_activate()
	else:
		sprite.animation = "completion"
		sprite.frame = mini(coins_paid, sprite.sprite_frames.get_frame_count("completion") - 1)
		sprite.pause()


func _activate() -> void:
	_activated = true
	interactable.is_interactable = false
	sprite.animation = "active"
	sprite.play()

	if coin_cost == 1:
		_eject_node(_make_free_item(LVLUP_SCENE.instantiate()) as Node2D, -18.0)
		_eject_node(_make_free_item(POTION_HEAL_SCENE.instantiate()) as Node2D, 18.0)
	else:
		_eject_random_reward()


func _make_free_item(inst: Node) -> Node:
	if "skip_base_price" in inst:
		inst.skip_base_price = true
	inst.set("cost", 0)
	if "where" in inst:
		inst.where = "shrine"
	return inst


func _prepare_free_drop(inst: Node) -> void:
	if "skip_base_price" in inst:
		inst.skip_base_price = true
	inst.set("cost", 0)
	if "where" in inst:
		inst.where = "treasure"


func _eject_random_reward() -> void:
	var inst: Node2D = null
	if randf() < ITEM_CHANCE:
		var item := ItemManager.random_pick("treasure", REWARD_TIERS)
		if not item.is_empty():
			inst = item.scene.instantiate()
			_prepare_free_drop(inst)
	else:
		var equipment := EquipManager.random_pick("treasure", REWARD_TIERS)
		if not equipment.is_empty():
			inst = equipment["scene"].instantiate()
			_prepare_free_drop(inst)

	if inst == null:
		var item := ItemManager.random_pick("treasure", REWARD_TIERS)
		if not item.is_empty():
			inst = item.scene.instantiate()
			_prepare_free_drop(inst)
		else:
			inst = _make_free_item(LVLUP_SCENE.instantiate()) as Node2D

	_eject_node(inst)


func _eject_node(node: Node2D, side_offset: float = 0.0) -> void:
	if node == null:
		return

	var player := get_tree().get_first_node_in_group("player")
	var start := marker.global_position
	var toward := Vector2.DOWN
	if player != null:
		toward = (player.global_position - start).normalized()
		if toward.length_squared() < 0.001:
			toward = Vector2.DOWN

	var perpendicular := Vector2(-toward.y, toward.x)
	var end := start + toward * randf_range(45.0, 75.0) + perpendicular * (side_offset + randf_range(-10.0, 10.0))
	var apex := start.lerp(end, 0.4) + Vector2(randf_range(-10.0, 10.0), randf_range(-40.0, -22.0))

	var host := get_tree().current_scene
	host.add_child(node)
	node.global_position = start
	_set_pickup_collectable(node, false)

	# Tween на дропе + weakref: без capture freed Object (shrine/item).
	var node_ref: WeakRef = weakref(node)
	var p0 := start
	var p1 := apex
	var p2 := end
	var tween := node.create_tween()
	tween.tween_method(
		func(t: float) -> void:
			var n := node_ref.get_ref() as Node2D
			if n == null:
				return
			var u := 1.0 - t
			n.global_position = u * u * p0 + 2.0 * u * t * p1 + t * t * p2,
		0.0,
		1.0,
		0.4
	)
	tween.tween_callback(
		func() -> void:
			var n := node_ref.get_ref() as Node
			if n == null:
				return
			if n is Area2D:
				var interact: Area2D = n.get_node_or_null("Interactable") as Area2D
				if interact:
					interact.is_interactable = true
				(n as Area2D).monitoring = true
	)


func _set_pickup_collectable(node: Node, enabled: bool) -> void:
	if node is Area2D:
		var interact: Area2D = node.get_node_or_null("Interactable") as Area2D
		if interact:
			interact.is_interactable = enabled
		(node as Area2D).monitoring = enabled
