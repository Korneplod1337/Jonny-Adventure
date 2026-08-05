extends Boss
class_name EnemyMimicBoss

## Временный ивентовый босс. Дублирует логику Mimic + босс-статы.

enum Phase { DORMANT, ACTIVATING, CHASING, PREPARING_SHOT }

@export_group("Boss Combat Stats")
@export var boss_projectile_damage: int = 1
@export var boss_projectile_speed: float = 500.0
@export var boss_projectile_range: float = 350.0
@export var projectile_scene: PackedScene = preload("res://game/enemy/projectiles/MimicShot.tscn")

const DOUBLE_LOOT_CHANCE := 0.5
const SHOT_AFTER_HIT_CHANCE := 0.5
const CHAIN_SHOT_CHANCE := 0.4
const ACTIVATION_SCALE_MULT := 1.5
const ACTIVATION_SCALE_DURATION := 0.5

var coin = preload("uid://ci05xlan24oqs")
var coinBag = preload("uid://bt02g3ohw7ksf")

var phase: Phase = Phase.DORMANT
var projectile_damage: int = 1
var projectile_speed: float = 500.0
var projectile_range: float = 350.0
var _loot_tier: Array = [1]
var _loot_pool := "chest"
var _equip_tier: Array = [1]
var _equip_pool := "treasure"

@onready var interactable: Area2D = $Interactable


func _ready() -> void:
	use_pathfinding = true
	drop_coin_on_death = false
	BossName = "Just a ...chest?"
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
	super._apply_level_buffs()
	projectile_damage = maxi(1, int(round(float(boss_projectile_damage) * Boss_damage_buff)))
	projectile_speed = boss_projectile_speed
	projectile_range = boss_projectile_range
	if GameState.level_bufs[2][1]:
		projectile_damage = maxi(1, projectile_damage * 2)


func get_projectile_damage() -> Vector3i:
	# Всегда магический урон (phy=0, mag=projectile_damage).
	return Vector3i(0, projectile_damage, 0)


func _on_interact() -> void:
	if phase != Phase.DORMANT or is_dead:
		return
	if not interactable.is_interactable:
		return
	SoundManager.play_mimic_boss_roar()
	interactable.is_interactable = false
	_start_activation()


func _start_activation() -> void:
	phase = Phase.ACTIVATING
	active = false
	deals_melee_damage = false
	velocity = Vector2.ZERO
	sprite.play("activation")
	_tween_activation_scale()


func _tween_activation_scale() -> void:
	var from_scale := scale
	var to_scale := from_scale * ACTIVATION_SCALE_MULT
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", to_scale, ACTIVATION_SCALE_DURATION)


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
	if is_dead:
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


func _on_blind_timer_timeout() -> void:
	# Активируется только через Interactable.
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

	if vengeful_enabled:
		_fire_vengeful_shot()

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
			if is_dead:
				return
			if randf() < CHAIN_SHOT_CHANCE:
				_start_preparing_shot()
			else:
				_start_chase()


func _fire_at_player() -> void:
	if not player or is_dead:
		return
	var dir := player.global_position - global_position
	if dir.length_squared() < 1.0:
		return
	_shoot_projectile(dir)


func _shoot_projectile(direction: Vector2) -> void:
	if not projectile_scene or direction == Vector2.ZERO:
		return
	var shot: Node2D = projectile_scene.instantiate()
	var dir := direction.normalized()
	shot.global_position = global_position + dir * 12.0
	shot.owner_enemy = self
	shot.setup(dir, get_projectile_damage(), projectile_speed, projectile_range)
	get_tree().current_scene.add_child(shot)
	sprite.flip_h = dir.x < 0


func _try_spawn_death_loot() -> void:
	if GameState.has_level_buf("Barren"):
		return

	_spawn_chest_loot(Vector2(0, -80))
	if randf() < DOUBLE_LOOT_CHANCE:
		_spawn_chest_loot(Vector2(40, -80))
	if GameState.extra_chest_loot_chance > 0.0 and randf() < GameState.extra_chest_loot_chance:
		_spawn_chest_loot(Vector2(-40, -80))


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
