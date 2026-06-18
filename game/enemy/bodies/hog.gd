extends BaseEnemy
class_name EnemyHog

enum State { IDLE, AIMING, RESTING, CHARGING, RECOVERING }

const STATS := {
	"easy": {
		"base_hp": 100,
		"charge_damage": 1,
		"charge_speed": 350.0,
		"cooldown_time": 2.0,
		"aim_time": 1.0,
		"rest_time": 1.0,
		"recover_time": 0.0,
	},
	"med": {
		"base_hp": 200,
		"charge_damage": 2,
		"charge_speed": 500.0,
		"cooldown_time": 1.6,
		"aim_time": 1.0,
		"rest_time": 0.75,
		"recover_time": 0.0,
	},
	"hard": {
		"base_hp": 250,
		"charge_damage": 2,
		"charge_speed": 650.0,
		"cooldown_time": 1.2,
		"aim_time": 1.0,
		"rest_time": 0.5,
		"recover_time": 0.0,
	},
}

var charge_speed: float
var charge_damage: int
var aim_time: float
var rest_time: float
var recover_time: float

var state := State.IDLE
var phase_timer := 0.0
var charge_direction := Vector2.RIGHT

@onready var charge_sprite: AnimatedSprite2D = $Charge


func _ready() -> void:
	super._ready()
	deals_melee_damage = false
	knockback_friction += 200.0
	sprite.play("default")
	_hide_charge_indicator()
	


func _setup_enemy_stats() -> void:
	var key: String = DungeonManager.difficulty
	if key not in STATS:
		key = "easy"

	var s: Dictionary = STATS[key]
	base_hp = int(s.base_hp * GameState.enemy_hp_multiplier)
	charge_damage = clampi(int(s.charge_damage * GameState.enemy_dmg_multiplier), 1, 4)
	charge_speed = s.charge_speed * GameState.enemy_ms_multiplier
	cooldown_time = s.cooldown_time * GameState.enemy_cooldown_multiplier
	aim_time = s.aim_time
	rest_time = s.rest_time
	recover_time = s.recover_time

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
	velocity = Vector2.ZERO
	deals_melee_damage = true

	sprite.play("charge")
	charge_sprite.play("Charge")
	_update_charge_direction(false)


func _process_charging(_delta: float) -> void:
	velocity = charge_direction * charge_speed
	sprite.flip_h = charge_direction.x < 0.0

	var prev_position := global_position
	move_and_slide()

	if _hit_wall(prev_position):
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


func _hit_wall(prev_position: Vector2) -> bool:
	if get_slide_collision_count() == 0:
		return false

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		if collision == null:
			continue

		var collider = collision.get_collider()
		if collider and collider.is_in_group("player"):
			continue

		return true

	if velocity.length_squared() > 0.0 and global_position.distance_squared_to(prev_position) < 0.25:
		return true

	return false
