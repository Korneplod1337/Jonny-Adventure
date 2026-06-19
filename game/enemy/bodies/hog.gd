extends BaseEnemy
class_name EnemyHog

enum State { IDLE, AIMING, RESTING, CHARGING, RECOVERING }

@export_group("Hard Stats")
@export var hard_base_hp: int = 250
@export var hard_charge_damage: int = 2
@export var hard_charge_speed: float = 650.0
@export var hard_cooldown_time: float = 1.2
@export var hard_aim_time: float = 1.0
@export var hard_rest_time: float = 0.5
@export var hard_recover_time: float = 0.0
@export var charge_max_duration: float = 5.0

const HP_MED_OFFSET := -50
const HP_EASY_OFFSET := -150
const CHARGE_DAMAGE_MED_OFFSET := -1
const CHARGE_DAMAGE_EASY_OFFSET := -1
const CHARGE_SPEED_MED_OFFSET := -150.0
const CHARGE_SPEED_EASY_OFFSET := -300.0
const COOLDOWN_MED_OFFSET := 0.4
const COOLDOWN_EASY_OFFSET := 0.8
const REST_TIME_MED_OFFSET := 0.25
const REST_TIME_EASY_OFFSET := 0.5

var charge_speed: float
var charge_damage: int
var aim_time: float
var rest_time: float
var recover_time: float

var state := State.IDLE
var phase_timer := 0.0
var charge_timer := 0.0
var charge_direction := Vector2.RIGHT

@onready var charge_sprite: AnimatedSprite2D = $Charge


func _apply_difficulty_offset(hard_value: float, med_offset: float, easy_offset: float) -> float:
	match DungeonManager.difficulty:
		"hard":
			return hard_value
		"med":
			return hard_value + med_offset
		_:
			return hard_value + easy_offset


func _ready() -> void:
	super._ready()
	deals_melee_damage = false
	knockback_friction += 200.0
	sprite.play("default")
	_hide_charge_indicator()


func _setup_enemy_stats() -> void:
	base_hp = int(_apply_difficulty_offset(
		float(hard_base_hp), float(HP_MED_OFFSET), float(HP_EASY_OFFSET)
	) * GameState.enemy_hp_multiplier)
	charge_damage = clampi(int(_apply_difficulty_offset(
		float(hard_charge_damage),
		float(CHARGE_DAMAGE_MED_OFFSET),
		float(CHARGE_DAMAGE_EASY_OFFSET)
	) * GameState.enemy_dmg_multiplier), 1, 4)
	charge_speed = _apply_difficulty_offset(
		hard_charge_speed, CHARGE_SPEED_MED_OFFSET, CHARGE_SPEED_EASY_OFFSET
	) * GameState.enemy_ms_multiplier
	cooldown_time = _apply_difficulty_offset(
		hard_cooldown_time, COOLDOWN_MED_OFFSET, COOLDOWN_EASY_OFFSET
	) * GameState.enemy_cooldown_multiplier
	aim_time = hard_aim_time
	rest_time = _apply_difficulty_offset(
		hard_rest_time, REST_TIME_MED_OFFSET, REST_TIME_EASY_OFFSET
	)
	recover_time = hard_recover_time

	super._setup_enemy_stats()


func get_attack_damage() -> Vector3i:
	if state == State.CHARGING:
		return Vector3i(charge_damage, 0, 0)
	return Vector3i(0, 0, 0)


func enemy_action() -> void:
	_start_aim_phase()


func _custom_physics(delta: float) -> void:
	if not active:
		_reset_attack_state()
		return

	match state:
		State.IDLE:
			_process_idle()
		State.AIMING:
			_process_aiming(delta)
		State.RESTING:
			_process_resting(delta)
		State.CHARGING:
			_process_charging(delta)
		State.RECOVERING:
			_process_recovering(delta)


func _process_idle() -> void:
	velocity = Vector2.ZERO
	if cooldown_timer.is_stopped():
		_start_aim_phase()


func _start_aim_phase() -> void:
	if not player or not active:
		state = State.IDLE
		return

	state = State.AIMING
	phase_timer = aim_time
	velocity = Vector2.ZERO
	deals_melee_damage = false

	sprite.animation = "charge"
	sprite.stop()
	sprite.frame = 0

	_show_charge_indicator()
	charge_sprite.play("Charge")
	_update_charge_direction(true)


func _process_aiming(delta: float) -> void:
	velocity = Vector2.ZERO
	_update_charge_direction(true)
	phase_timer -= delta

	if phase_timer <= 0.0:
		_start_rest_phase()


func _start_rest_phase() -> void:
	state = State.RESTING
	phase_timer = rest_time
	velocity = Vector2.ZERO
	deals_melee_damage = false

	sprite.animation = "charge"
	sprite.stop()
	sprite.frame = 0

	charge_sprite.play("Charge")


func _process_resting(delta: float) -> void:
	velocity = Vector2.ZERO
	phase_timer -= delta

	if phase_timer <= 0.0:
		_start_charge_phase()


func _start_charge_phase() -> void:
	state = State.CHARGING
	phase_timer = 0.0
	charge_timer = 0.0
	velocity = Vector2.ZERO
	deals_melee_damage = true

	sprite.play("charge")
	charge_sprite.play("Charge")
	_update_charge_direction(false)


func _process_charging(delta: float) -> void:
	charge_timer += delta
	velocity = charge_direction * charge_speed
	sprite.flip_h = charge_direction.x < 0.0

	move_and_slide()

	if charge_timer >= charge_max_duration or _hit_wall():
		_start_recover_phase()


func _start_recover_phase() -> void:
	state = State.RECOVERING
	phase_timer = recover_time
	velocity = Vector2.ZERO
	deals_melee_damage = false

	sprite.play("default")
	charge_sprite.play("default")
	_hide_charge_indicator()


func _process_recovering(delta: float) -> void:
	velocity = Vector2.ZERO
	phase_timer -= delta

	if phase_timer <= 0.0:
		state = State.IDLE
		_hide_charge_indicator()
		cooldown_timer.start()


func _update_charge_direction(track_player: bool) -> void:
	var direction := charge_direction

	if track_player and player:
		direction = player.global_position - global_position

	if direction.length_squared() < 0.01:
		return

	charge_direction = direction.normalized()
	charge_sprite.rotation = charge_direction.angle()
	sprite.flip_h = charge_direction.x < 0.0


func _show_charge_indicator() -> void:
	charge_sprite.visible = true


func _hide_charge_indicator() -> void:
	charge_sprite.visible = false
	charge_sprite.stop()


func _reset_attack_state() -> void:
	state = State.IDLE
	velocity = Vector2.ZERO
	deals_melee_damage = false
	_hide_charge_indicator()
	sprite.play("default")


func _hit_wall() -> bool:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision == null:
			continue

		var collider = collision.get_collider()
		if collider == null:
			continue

		if collider.is_in_group("player") or collider.is_in_group("Enemy"):
			continue

		if collider is RigidBody2D:
			continue

		if collider is StaticBody2D and (collider.collision_layer & 16):
			return true

	return false
