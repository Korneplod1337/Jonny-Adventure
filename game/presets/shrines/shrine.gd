extends Node2D

const BLOOD_SHRINE_SCENE := preload("res://game/presets/shrines/bloodShrine.tscn")
const OBLATION_SHRINE_SCENE := preload("res://game/presets/shrines/OblationShrine.tscn")
const COIN_SCENE := preload("res://game/objects/coins/Coin.tscn")
const WEAK_SKULL_SCENE := preload("res://game/enemy/2-st floor pyramid/weak_skull.tscn")
const BLOOD_SHRINE_CHANCE := 0.12
const OBLATION_SHRINE_CHANCE := 0.08
const BASE_HP := 40
const HP_PER_FLOOR := 15
const KERES_MARIA_ON_BREAK := -5
const WEAK_SKULL_CHANCE := 0.25

@onready var interactable: Area2D = $Interactable
@onready var Shrn_animation: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_body: StaticBody2D = $collision

enum ShrineType {
	hp, move_speed, luck, magic,
	damage, spread, range, fire_rate
}

@export var shrine_type: int = -1
@export var flip := false
var selected_type: ShrineType
var _finalized := false

var current_hp: int = 0
var _activated := false
var _breaking := false
var _is_destroyed_look := false
var _damage_flash_token: int = 0


func _ready() -> void:
	add_to_group("shrine")
	Shrn_animation.flip_h = flip
	interactable.interact = _on_interact
	if not Shrn_animation.animation_finished.is_connected(_on_animation_finished):
		Shrn_animation.animation_finished.connect(_on_animation_finished)

	if GameState.has_level_buf("Destroyed"):
		_make_destroyed()
		_finalized = true
		return
	# Комната вызовет finalize_spawn(); если нет (тест/другой скрипт) — сам дособерётся.
	visible = false
	interactable.is_interactable = false
	call_deferred("_defer_ensure_finalize")


func _defer_ensure_finalize() -> void:
	# Второй deferred — после init_room комнаты (тоже deferred из её _ready).
	call_deferred("_ensure_finalize")


func _ensure_finalize() -> void:
	if _finalized or not is_inside_tree() or is_queued_for_deletion():
		return
	finalize_spawn()


func finalize_spawn() -> void:
	if _finalized or not is_inside_tree() or is_queued_for_deletion():
		return
	_finalized = true

	if shrine_type == -1:
		var roll := randf()
		if roll < BLOOD_SHRINE_CHANCE:
			_replace_with_scene(BLOOD_SHRINE_SCENE, "blood")
			return
		if roll < BLOOD_SHRINE_CHANCE + OBLATION_SHRINE_CHANCE:
			_replace_with_scene(OBLATION_SHRINE_SCENE, "oblation")
			return

	_setup_normal_shrine()


func _setup_normal_shrine() -> void:
	visible = true
	interactable.is_interactable = true
	_init_hp()
	if shrine_type == -1:
		selected_type = ShrineType.values()[randi() % ShrineType.size()]
	else:
		selected_type = ShrineType.values()[shrine_type]
	Shrn_animation.animation = ShrineType.keys()[selected_type]
	Shrn_animation.frame = 0
	print("Шрайн: ", ShrineType.keys()[selected_type], " HP=", current_hp)


func _make_destroyed() -> void:
	visible = true
	interactable.is_interactable = false
	_is_destroyed_look = true
	_init_hp()
	Shrn_animation.animation = "broken"
	Shrn_animation.frame = 0
	print("Шрайн: broken HP=", current_hp)


func _init_hp() -> void:
	current_hp = BASE_HP + HP_PER_FLOOR * _get_current_floor()


func _get_current_floor() -> int:
	var dungeon := get_tree().current_scene
	if dungeon != null and dungeon.get("current_floor") != null:
		return int(dungeon.current_floor)
	return 1


func _replace_with_scene(scene: PackedScene, label: String) -> void:
	var parent := get_parent()
	if parent == null:
		queue_free()
		return
	var replacement := scene.instantiate()
	replacement.position = position
	parent.add_child(replacement)
	parent.move_child(replacement, get_index())
	visible = false
	interactable.is_interactable = false
	call_deferred("queue_free")
	print("Шрайн: ", label)


func hit(amount: float, _clear := false) -> void:
	if _breaking or _activated or not visible:
		return
	if current_hp <= 0:
		return

	current_hp -= amount
	_flash_damage()
	if current_hp <= 0:
		_begin_break()


func _flash_damage() -> void:
	_damage_flash_token += 1
	var my_token := _damage_flash_token
	Shrn_animation.modulate.a = 0.55
	await get_tree().create_timer(0.08).timeout
	if my_token != _damage_flash_token or not is_instance_valid(self) or _breaking:
		return
	Shrn_animation.modulate.a = 1.0


func _begin_break() -> void:
	if _breaking:
		return
	_breaking = true
	_activated = true
	interactable.is_interactable = false
	if collision_body:
		collision_body.set_deferred("collision_layer", 0)
		collision_body.set_deferred("collision_mask", 0)

	GameState.KeresMaria += KERES_MARIA_ON_BREAK
	Shrn_animation.modulate.a = 1.0
	var destroy_anim := _get_destroy_animation()
	Shrn_animation.animation = destroy_anim
	Shrn_animation.play()
	print("Шрайн сломан (", destroy_anim, "). KeresMaria=", GameState.KeresMaria)


func _get_destroy_animation() -> StringName:
	# Destroyed-модификатор: общие broken-кадры. Обычный тип: свой *_destroy.
	if _is_destroyed_look:
		return &"broken_active"
	var type_name = ShrineType.keys()[selected_type]
	var anim := StringName(type_name + "_destroy")
	if Shrn_animation.sprite_frames.has_animation(anim):
		return anim
	return &"broken_active"


func _on_animation_finished() -> void:
	if not _breaking:
		return
	var anim := String(Shrn_animation.animation)
	if anim != "broken_active" and not anim.ends_with("_destroy"):
		return
	_try_spawn_coin_loot()
	queue_free()


func _try_spawn_coin_loot() -> void:
	if GameState.has_level_buf("Barren"):
		return
	if GameState.has_level_buf("Explosive"):
		return

	if GameState.has_level_buf("Midas"):
		_spawn_coin()
		return

	var coin_spawned := false
	var player := get_tree().get_first_node_in_group("player")
	var luck := 0.0
	if player:
		luck = StatManager.get_stat(player, "luck")
	if randf() < luck:
		_spawn_coin()
		coin_spawned = true

	if GameState.has_level_buf("Bountiful") and randf() < 0.2:
		_spawn_coin(global_position + Vector2(randf_range(-24.0, 24.0), randf_range(-24.0, 24.0)))

	if not coin_spawned and randf() < WEAK_SKULL_CHANCE:
		_spawn_weak_skull()


func _spawn_coin(at_pos: Vector2 = Vector2.INF) -> void:
	var coin := COIN_SCENE.instantiate()
	coin.global_position = global_position if at_pos == Vector2.INF else at_pos
	get_tree().current_scene.call_deferred("add_child", coin)


func _spawn_weak_skull() -> void:
	var skull := WEAK_SKULL_SCENE.instantiate()
	var room := get_parent()
	if room != null:
		skull.position = position
		room.call_deferred("add_child", skull)
		if room.has_method("connect_single_enemy"):
			room.call_deferred("connect_single_enemy", skull)
	else:
		skull.global_position = global_position
		get_tree().current_scene.call_deferred("add_child", skull)


func _on_interact():
	if _breaking or _activated or _is_destroyed_look:
		return
	var player = get_tree().get_first_node_in_group("player")
	if GameState.coins > 0 and interactable.is_interactable:
		SoundManager.play_shine()
		Shrn_animation.animation = ShrineType.keys()[selected_type] + '_active'
		Shrn_animation.play()
		interactable.is_interactable = false
		_activated = true
		GameState.add_coins(-1)
		var stat_name: String
		match selected_type:
			ShrineType.hp:          stat_name = "hp"
			ShrineType.move_speed:  stat_name = "move_speed"
			ShrineType.luck:        stat_name = "luck"
			ShrineType.magic:       stat_name = "magic"
			ShrineType.damage:      stat_name = "damage"
			ShrineType.spread:      stat_name = "spread"
			ShrineType.range:       stat_name = "range"
			ShrineType.fire_rate:   stat_name = "fire_rate"
		
		StatManager.upgrade_stat(player, stat_name, 1)
