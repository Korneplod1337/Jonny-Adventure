extends Node2D

## Odds as fractions: [symbol, numerator, denominator]. Easy to tweak.
const SYMBOL_ODDS: Array = [
	["money", 3, 9],
	["apple", 3, 9],
	["cherry", 2, 9],
	["7", 1, 9]
]

## "7" jackpot: each of 3 prizes rolls with these odds.
const SEVEN_PRIZE_ODDS: Array = [
	["money", 1, 2], # 50%
	["apple", 1, 4], # 25%
	["cherry", 1, 4] # 25%
]

const TIMER_START := 2.0
const TIMER_STEP := 0.15
const TIMER_MIN := 0.5
const ANIM_FPS_NORMAL := 4.0
const ANIM_FPS_FAST := 5.0
const BASE_HP := 50
const DAMAGE_BLOCK := 40

const COIN_SCENE := preload("res://game/objects/coins/Coin.tscn")
const COIN_BAG_SCENE := preload("res://game/objects/coins/CoinBag.tscn")

@onready var interactable: Area2D = $Interactable
@onready var machine_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var rolling_timer: Timer = $"Rolling timer"
@onready var win_marker: Marker2D = $"Win Marker"
@onready var static_body: StaticBody2D = $StaticBody2D
@onready var roll_sprites: Array[AnimatedSprite2D] = [
	$"Slot machine roll 1/AnimatedSprite2D",
	$"Slot machine roll 2/AnimatedSprite2D",
	$"Slot machine roll 3/AnimatedSprite2D",
]

var player: CharacterBody2D
var GS := GameState
var _is_spinning: bool = false
var _rolled_symbols: Array[String] = ["", "", ""]
var _revealed_count: int = 0
var _uses_count: int = 0
var _fast_anims: bool = false
var current_hp: int = BASE_HP
var is_dead: bool = false
var _damage_flash_token: int = 0


func _ready() -> void:
	current_hp = BASE_HP
	interactable.interact = _on_interact
	machine_sprite.animation_finished.connect(_on_machine_animation_finished)
	machine_sprite.frame_changed.connect(_on_machine_frame_changed)
	rolling_timer.timeout.connect(_on_rolling_timer_timeout)
	rolling_timer.wait_time = TIMER_START
	#machine_sprite.play("win")
	_set_all_rolls("default")


func hit(amount: float, _clear := false) -> void:
	if is_dead:
		return
	amount = maxf(0.0, amount - DAMAGE_BLOCK)
	_flash_damage()
	current_hp -= amount
	print("Слот-машина HP: %.0f / %d (урон после блока: %.0f)" % [current_hp, BASE_HP, amount])
	if current_hp <= 0:
		_begin_break()


func _flash_damage() -> void:
	_damage_flash_token += 1
	var my_token := _damage_flash_token
	machine_sprite.modulate.a = 0.4
	await get_tree().create_timer(0.1).timeout
	if my_token != _damage_flash_token or not is_instance_valid(self):
		return
	machine_sprite.modulate.a = 1.0


func _begin_break() -> void:
	if is_dead:
		return
	is_dead = true
	interactable.is_interactable = false
	rolling_timer.stop()
	_is_spinning = false

	# Instant free roll — no spin animations.
	_rolled_symbols = [_roll_symbol(), _roll_symbol(), _roll_symbol()]
	for i in 3:
		roll_sprites[i].play(_rolled_symbols[i])

	var result := _evaluate_result(_rolled_symbols)
	print(
		"Слот-машина сломана: [%s | %s | %s] → %s"
		% [_rolled_symbols[0], _rolled_symbols[1], _rolled_symbols[2], result]
	)
	_grant_result(result)
	_play_die()


func _on_interact() -> void:
	if _is_spinning or is_dead:
		return

	player = get_tree().get_first_node_in_group("player")
	if not player:
		print("Слот машина не видит игрока")
		return

	if GS.coins >= ((1 + GS.cost_plus) * GS.cost_multiplier):
		GS.add_coins((-1 - GS.cost_plus) * GS.cost_multiplier)
		use_machine()


func use_machine() -> void:
	_is_spinning = true
	interactable.is_interactable = false
	_rolled_symbols = ["", "", ""]
	_revealed_count = 0
	machine_sprite.play("activation")


func _on_machine_animation_finished() -> void:
	match machine_sprite.animation:
		&"activation":
			_start_spinning()
		&"show":
			_finish_spin()
		&"die":
			queue_free()


func _start_spinning() -> void:
	if is_dead:
		return
	_set_all_rolls("default")
	machine_sprite.play("spinning")
	rolling_timer.start()


func _on_rolling_timer_timeout() -> void:
	if is_dead:
		return
	_revealed_count = 0
	machine_sprite.play("show")
	# First frame of show may not emit frame_changed — reveal reel 1 now.
	_reveal_reel(0)


func _on_machine_frame_changed() -> void:
	if is_dead or machine_sprite.animation != &"show":
		return
	# Frames 1 and 2 reveal reels 2 and 3 (frame 0 was handled on play).
	if machine_sprite.frame >= 1:
		_reveal_reel(machine_sprite.frame)


func _reveal_reel(index: int) -> void:
	if index < 0 or index > 2:
		return
	if _rolled_symbols[index] != "":
		return

	var symbol := _roll_symbol()
	_rolled_symbols[index] = symbol
	roll_sprites[index].play(symbol)
	_revealed_count += 1
	print("Слот %d: %s" % [index + 1, symbol])


func _finish_spin() -> void:
	if is_dead:
		return

	var result := _evaluate_result(_rolled_symbols)
	print(
		"Результат слот-машины: [%s | %s | %s] → %s"
		% [_rolled_symbols[0], _rolled_symbols[1], _rolled_symbols[2], result]
	)
	_grant_result(result)
	_after_use()
	machine_sprite.play("win")
	_is_spinning = false
	interactable.is_interactable = true


func _play_die() -> void:
	for sprite in roll_sprites:
		sprite.play('default')
	rolling_timer.stop()
	_is_spinning = false
	interactable.is_interactable = false
	if static_body:
		static_body.set_deferred("collision_layer", 0)
	machine_sprite.play("die")


func _roll_symbol() -> String:
	return _weighted_pick(SYMBOL_ODDS)


func _weighted_pick(odds: Array) -> String:
	var total_weight := 0.0
	var weights: Array[float] = []
	for entry in odds:
		var weight: float = float(entry[1]) / float(entry[2])
		weights.append(weight)
		total_weight += weight

	var roll := randf() * total_weight
	var cumulative := 0.0
	for i in weights.size():
		cumulative += weights[i]
		if roll <= cumulative:
			return String(odds[i][0])

	return String(odds[-1][0])


func _evaluate_result(symbols: Array[String]) -> String:
	if symbols[0] == symbols[1] and symbols[1] == symbols[2]:
		print("Выигрыш! Три одинаковых: %s" % symbols[0])
		return "win_%s" % symbols[0]

	var money_count := 0
	for s in symbols:
		if s == "money":
			money_count += 1
	if money_count == 2:
		print("Мини-выигрыш: mini money (2 монетки)")
		return "mini_money"

	print("Поражение")
	return "loss"


func _grant_result(result: String) -> void:
	match result:
		"mini_money":
			_spawn_prize("mini_money")
		"win_money":
			_spawn_prize("money")
		"win_apple":
			_spawn_prize("apple")
		"win_cherry":
			_spawn_prize("cherry")
		"win_7":
			_spawn_seven_prizes()
		_:
			pass


func _spawn_seven_prizes() -> void:
	for i in 3:
		var prize := _weighted_pick(SEVEN_PRIZE_ODDS)
		print("7-приз %d: %s" % [i + 1, prize])
		_spawn_prize_deferred(prize, i * 0.12)


func _spawn_prize_deferred(prize: String, delay: float) -> void:
	if delay <= 0.0:
		_spawn_prize(prize)
		return
	get_tree().create_timer(delay).timeout.connect(
		func() -> void:
			if is_inside_tree():
				_spawn_prize(prize)
	)


func _spawn_prize(prize: String) -> void:
	match prize:
		"mini_money":
			_eject_node(COIN_SCENE.instantiate())
		"money":
			_eject_node(COIN_BAG_SCENE.instantiate())
		"apple":
			_spawn_item_prize()
		"cherry":
			_spawn_equip_prize()


func _spawn_item_prize() -> void:
	var item := ItemManager.random_pick("treasure", [1, 2, 3, 4])
	if item.is_empty():
		print("Слот-машина: нет item в treasure [1,2,3,4]")
		return
	var inst = item.scene.instantiate()
	inst.where = "treasure"
	inst.cost = 0
	_eject_node(inst)


func _spawn_equip_prize() -> void:
	var equipment := EquipManager.random_pick("treasure", [1, 2, 3])
	if equipment.is_empty():
		print("Слот-машина: нет equip в treasure [1,2,3]")
		return
	var inst = equipment["scene"].instantiate()
	inst.cost = 0
	_eject_node(inst)


func _eject_node(node: Node2D) -> void:
	var start := win_marker.global_position
	var end := start + Vector2(
		randf_range(-95.0, -40.0),
		randf_range(20.0, 65.0)
	)
	var apex := start.lerp(end, 0.4) + Vector2(
		randf_range(-12.0, 12.0),
		randf_range(-50.0, -28.0)
	)

	get_tree().current_scene.call_deferred('add_child', node)
	node.global_position = start
	_set_pickup_collectable(node, false)

	var tween := create_tween()
	tween.tween_method(
		func(t: float) -> void:
			if is_instance_valid(node):
				node.global_position = _quad_bezier(start, apex, end, t),
		0.0,
		1.0,
		0.4
	)
	tween.tween_callback(
		func() -> void:
			if is_instance_valid(node):
				_set_pickup_collectable(node, true)
	)


func _quad_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u * u * p0 + 2.0 * u * t * p1 + t * t * p2


func _set_pickup_collectable(node: Node, enabled: bool) -> void:
	if node is Area2D:
		var interact: Area2D = node.get_node_or_null("Interactable") as Area2D
		if interact:
			interact.is_interactable = enabled
		node.monitoring = enabled
		return

	var area := node.get_node_or_null("Area2D") as Area2D
	if area:
		area.monitoring = enabled
		area.set_deferred("monitorable", enabled)


func _after_use() -> void:
	_uses_count += 1
	rolling_timer.wait_time = maxf(TIMER_MIN, TIMER_START - TIMER_STEP * _uses_count)
	print("Слот-машина: spinning wait = %.2fс" % rolling_timer.wait_time)

	if not _fast_anims and rolling_timer.wait_time <= TIMER_MIN:
		_fast_anims = true
		_set_all_animation_fps(ANIM_FPS_FAST)
		print("Слот-машина: анимации ускорены до %d fps" % int(ANIM_FPS_FAST))


func _set_all_animation_fps(fps: float) -> void:
	_set_sprite_fps(machine_sprite, fps)
	# Roll sprites share one SpriteFrames resource — update once.
	if not roll_sprites.is_empty():
		_set_sprite_fps(roll_sprites[0], fps)


func _set_sprite_fps(sprite: AnimatedSprite2D, fps: float) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	for anim_name in sprite.sprite_frames.get_animation_names():
		sprite.sprite_frames.set_animation_speed(anim_name, fps)


func _set_all_rolls(anim_name: String) -> void:
	for sprite in roll_sprites:
		sprite.play(anim_name)
