extends EnemyRanger
class_name EnemyMimic

enum Phase { DORMANT, ACTIVATING, CHASING, PREPARING_SHOT }

@export_group("Hard Stats")
@export var hard_move_speed: float = 140.0
@export var hard_base_hp: int = 100
@export var hard_damage: int = 1
@export var hard_cooldown_time: float = 0.8
@export var hard_projectile_speed: float = 300.0
@export var hard_projectile_range: float = 350.0

const MOVE_SPEED_MED_OFFSET := -25.0
const MOVE_SPEED_EASY_OFFSET := -50.0
const HP_MED_OFFSET := -20
const HP_EASY_OFFSET := -50
const DAMAGE_MED_OFFSET := 0
const DAMAGE_EASY_OFFSET := 0
const COOLDOWN_MED_OFFSET := 0.1
const COOLDOWN_EASY_OFFSET := 0.2
const PROJECTILE_SPEED_MED_OFFSET := -50.0
const PROJECTILE_SPEED_EASY_OFFSET := -100.0
const PROJECTILE_RANGE_MED_OFFSET := -50.0
const PROJECTILE_RANGE_EASY_OFFSET := -100.0

const DOUBLE_LOOT_CHANCE := 0.5
const SHOT_AFTER_HIT_CHANCE := 0.5

var coin = preload("uid://ci05xlan24oqs")
var coinBag = preload("uid://bt02g3ohw7ksf")

var phase: Phase = Phase.DORMANT
var _room_locked := false
var _loot_tier: Array = [1]
var _loot_pool := "chest"
var _equip_tier: Array = [1]
var _equip_pool := "treasure"

@onready var interactable: Area2D = $Interactable


func _ready() -> void:
	use_pathfinding = true
	drop_coin_on_death = false
	super._ready()
	phase = Phase.DORMANT
	active = false
	deals_melee_damage = false
	interactable.interact = _on_interact
	interactable.is_interactable = true
	sprite.play("Non-active")
	blind_timer.stop()
	cooldown_timer.stop()


func _apply_level_buffs() -> void:
	move_speed = _scale_move_speed(
		hard_move_speed, MOVE_SPEED_MED_OFFSET, MOVE_SPEED_EASY_OFFSET
	)
	base_hp = _scale_hp(hard_base_hp, HP_MED_OFFSET, HP_EASY_OFFSET)
	damage = _scale_damage(hard_damage, DAMAGE_MED_OFFSET, DAMAGE_EASY_OFFSET)
	projectile_damage = _scale_damage(
		hard_projectile_damage, DAMAGE_MED_OFFSET, DAMAGE_EASY_OFFSET
	)
	cooldown_time = _scale_cooldown(
		hard_cooldown_time, COOLDOWN_MED_OFFSET, COOLDOWN_EASY_OFFSET
	)
	projectile_speed = _apply_difficulty_offset(
		hard_projectile_speed, PROJECTILE_SPEED_MED_OFFSET, PROJECTILE_SPEED_EASY_OFFSET
	)
	projectile_range = _apply_difficulty_offset(
		hard_projectile_range, PROJECTILE_RANGE_MED_OFFSET, PROJECTILE_RANGE_EASY_OFFSET
	)
	super._apply_level_buffs()
	if GameState.level_bufs[2][1]:
		projectile_damage *= 2


func _on_interact() -> void:
	if phase != Phase.DORMANT or is_dead:
		return
	if not interactable.is_interactable:
		return
	SoundManager.play_skrip()
	interactable.is_interactable = false
	_start_activation()


func _start_activation() -> void:
	phase = Phase.ACTIVATING
	active = false
	deals_melee_damage = false
	velocity = Vector2.ZERO
	_relock_room()
	sprite.play("activation")


func _relock_room() -> void:
	if _room_locked:
		return
	var room := get_parent()
	if room == null:
		return
	if room.has_method("hide_doors"):
		room.hide_doors()
	if room.has_method("connect_single_enemy"):
		room.connect_single_enemy(self, true)
	_room_locked = true


func _start_chase() -> void:
	if is_dead:
		return
	phase = Phase.CHASING
	active = true
	deals_melee_damage = true
	player_in_vision = true
	if use_pathfinding:
		_pathfind_cooldown = 0.0
	sprite.play("default")


func _start_preparing_shot() -> void:
	if is_dead or phase == Phase.PREPARING_SHOT:
		return
	phase = Phase.PREPARING_SHOT
	active = true
	deals_melee_damage = false
	velocity = Vector2.ZERO
	sprite.play("preparing shot")


func _custom_physics(_delta: float) -> void:
	if phase != Phase.CHASING or not player:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dir := get_direction_to_player()
	if dir == Vector2.ZERO:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	velocity = dir * move_speed
	sprite.flip_h = dir.x < 0
	move_and_slide()


func enemy_action() -> void:
	pass


func _on_field_view_area_body_entered(body: Node2D) -> void:
	if phase == Phase.DORMANT or phase == Phase.ACTIVATING:
		return
	if body.is_in_group("player"):
		player_in_vision = true
		if use_pathfinding:
			_pathfind_cooldown = 0.0


func _on_field_view_area_body_exited(body: Node2D) -> void:
	if phase == Phase.DORMANT or phase == Phase.ACTIVATING:
		return
	if body.is_in_group("player"):
		player_in_vision = false
		# Once awakened, keep chasing even if FOV briefly drops.


func _on_blind_timer_timeout() -> void:
	# Mimic activates only via interact, never via vision.
	pass


func hit(amount: float, clear := false) -> void:
	if is_dead:
		return
	if phase == Phase.DORMANT or phase == Phase.ACTIVATING or phase == Phase.PREPARING_SHOT:
		return

	if not clear:
		amount *= effect_protection
	_flash_damage()
	current_hp -= amount
	if current_hp <= 0:
		die()
		return

	if phase == Phase.CHASING and randf() < SHOT_AFTER_HIT_CHANCE:
		_start_preparing_shot()


func apply_knockback(direction: Vector2, force: float) -> void:
	if phase == Phase.DORMANT or phase == Phase.ACTIVATING or phase == Phase.PREPARING_SHOT:
		return
	super.apply_knockback(direction, force)


func apply_slow(mult: float, duration: float) -> void:
	if phase == Phase.DORMANT or phase == Phase.ACTIVATING:
		return
	super.apply_slow(mult, duration)


func apply_poison(effect: float) -> void:
	if phase == Phase.DORMANT or phase == Phase.ACTIVATING:
		return
	super.apply_poison(effect)


func apply_fire(
	effect: float,
	duration: float,
	hack_power: int = 0,
	hack_dir: Vector2 = Vector2.RIGHT
) -> void:
	if phase == Phase.DORMANT or phase == Phase.ACTIVATING:
		return
	super.apply_fire(effect, duration, hack_power, hack_dir)


func die() -> void:
	phase = Phase.DORMANT
	interactable.is_interactable = false
	super.die()


func _on_sprite_animation_finished() -> void:
	if is_dead or sprite.animation == "die":
		super._on_sprite_animation_finished()
		return

	match sprite.animation:
		"activation":
			_start_chase()
		"preparing shot":
			_fire_at_player()
			_start_chase()


func _fire_at_player() -> void:
	if not player or is_dead:
		return
	var dir := player.global_position - global_position
	if dir.length_squared() < 1.0:
		return
	shoot_projectile(dir)


func _try_spawn_death_loot() -> void:
	if GameState.has_level_buf("Barren"):
		return

	_spawn_chest_loot(Vector2(0, -40))
	if randf() < DOUBLE_LOOT_CHANCE:
		_spawn_chest_loot(Vector2(40, -40))
	if GameState.extra_chest_loot_chance > 0.0 and randf() < GameState.extra_chest_loot_chance:
		_spawn_chest_loot(Vector2(-40, -40))


func _spawn_chest_loot(offset: Vector2) -> void:
	var random := randi_range(1, 100)
	if random >= 90:
		EquipManager.spawn(_equip_pool, _equip_tier, global_position + offset)
	elif random >= 70:
		ItemManager.spawn(_loot_pool, _loot_tier, global_position + offset, 0)
	elif random >= 50:
		_spawn_loot_scene(coinBag, offset)
	else:
		_spawn_loot_scene(coin, offset)


func _spawn_loot_scene(scene: PackedScene, offset: Vector2) -> void:
	var inst := scene.instantiate()
	inst.position = global_position + offset
	get_tree().current_scene.add_child(inst)
