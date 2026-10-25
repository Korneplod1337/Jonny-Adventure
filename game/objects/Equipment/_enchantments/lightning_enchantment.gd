class_name LightningEnchantment
extends EnchantmentResource

const CHAIN_SCENE := preload("res://game/objects/Equipment/_enchantments/lightning_chain.tscn")

func _init() -> void:
	enchant_name = "Lightning"


func _magic_t() -> float:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return 0.0
	var player := tree.get_first_node_in_group("player")
	if player == null:
		return 0.0
	return clampf(StatManager.get_stat(player, "magic") / 4.0, 0.0, 1.0)


func get_proc_chance() -> float:
	match level:
		1: return 0.20
		2: return 0.30
		3: return 0.40
		_: return 0.20


func get_piece_scale() -> float:
	match level:
		1: return 4.0
		2: return 3.0
		3: return 2.0
		_: return 4.0


func get_bounce_range() -> float:
	match level:
		1: return 800.0
		2: return 400.0
		3: return 200.0
		_: return 800.0


func get_max_bounces() -> int:
	match level:
		1: return 2
		2: return 4
		3: return 7
		_: return 2


func get_damage() -> float:
	var t := _magic_t()
	match level:
		1: return lerpf(100.0, 200.0, t)
		2: return lerpf(50.0, 100.0, t)
		3: return lerpf(25.0, 50.0, t)
		_: return lerpf(100.0, 200.0, t)


func get_bounce_chance() -> float:
	var t := _magic_t()
	match level:
		1: return lerpf(0.15, 0.55, t)
		2: return lerpf(0.25, 0.70, t)
		3: return lerpf(0.35, 0.95, t)
		_: return lerpf(0.15, 0.55, t)


func get_bounce_delay() -> float:
	var t := _magic_t()
	match level:
		1: return lerpf(0.6, 0.4, t)
		2: return lerpf(0.4, 0.2, t)
		3: return lerpf(0.2, 0.1, t)
		_: return lerpf(0.6, 0.4, t)


func apply_on_hit(
	target: Node,
	_projectile_direction: Vector2 = Vector2(0, 0),
	_hack: int = 0,
	_hack_direction: Vector2 = Vector2.ZERO
) -> void:
	if target == null or not is_instance_valid(target):
		return
	if not target.has_method("hit"):
		return
	if randf() >= get_proc_chance():
		return

	var parent: Node = target.get_tree().current_scene
	if parent == null:
		parent = target.get_parent()
	if parent == null:
		return

	var chain := CHAIN_SCENE.instantiate()
	parent.add_child(chain)
	chain.start(
		target,
		get_damage(),
		get_bounce_range(),
		get_bounce_chance(),
		get_max_bounces(),
		get_bounce_delay(),
		get_piece_scale()
	)


func get_tooltip_text() -> String:
	match level:
		1: return " with a devastating thunderstrike"
		2: return " with crackling arcs of lightning"
		3: return " with a storm of leaping sparks"
		_: return " -- !WRONG! --"


func get_name_text() -> String:
	return "storm "
