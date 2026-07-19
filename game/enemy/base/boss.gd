extends BaseEnemy
class_name Boss

## Базовый класс босса. Статы считаются из boss_* и Boss_*_buff,
## без GameState.enemy_*_multiplier обычных врагов.

@export var BossName: String = "Boss"

@export_group("Boss Base Stats")
@export var boss_base_hp: int = 100
@export var boss_damage: int = 1
@export var boss_move_speed: float = 100.0
## Базовый масштаб модельки (до Boss_model_size_buff).
@export var boss_model_scale: float = 1.0

@export_group("Boss Buffs")
@export var Boss_HP_buff: float = 1.0
@export var Boss_damage_buff: float = 1.0
@export var Boss_move_speed_buff: float = 1.0
@export var Boss_model_size_buff: float = 1.0
## Доп. время к таймеру между фазами.
@export var Boss_phase_switch_buff: float = 0.0

## База паузы между фазами (бывший hard_cooldown_time босса = 1.8).
const PHASE_SWITCH_BASE := 1.8
const VENGEFUL_SHOT_SCENE := preload("res://game/enemy/projectiles/EnemyShotBossrev.tscn")
const VENGEFUL_SHOT_SPEED := 350.0
const VENGEFUL_SHOT_RANGE := 1000.0

## Siamese: клон повторяет лидера, пока тот жив.
var is_siamese_follower := false
var siamese_leader: Boss = null
var siamese_follower: Boss = null
var siamese_offset := Vector2.ZERO
## Vengeful: ответный выстрел при получении урона.
var vengeful_enabled := false


func _apply_level_buffs() -> void:
	base_hp = int(round(float(boss_base_hp) * Boss_HP_buff))
	damage = int(round(float(boss_damage) * Boss_damage_buff))
	move_speed = boss_move_speed * Boss_move_speed_buff
	cooldown_time = get_phase_switch_time()
	_apply_boss_model_scale()
	super._apply_level_buffs()
	damage = maxi(1, damage)


func _apply_boss_model_scale() -> void:
	var s := boss_model_scale * Boss_model_size_buff
	scale = Vector2(s, s)


func get_phase_switch_time() -> float:
	return PHASE_SWITCH_BASE + Boss_phase_switch_buff


func can_act_independently() -> bool:
	return not (is_siamese_follower and is_instance_valid(siamese_leader) and not siamese_leader.is_dead)


func setup_as_siamese_follower(leader: Boss) -> void:
	is_siamese_follower = true
	siamese_leader = leader
	siamese_offset = global_position - leader.global_position
	leader.siamese_follower = self
	cooldown_timer.stop()
	blind_timer.stop()
	active = false


func release_siamese_follow() -> void:
	is_siamese_follower = false
	siamese_leader = null
	siamese_offset = Vector2.ZERO
	if player_in_vision and not is_dead:
		active = true
		if use_pathfinding:
			_pathfind_cooldown = 0.0
		_schedule_next_decision()


func _sync_siamese_visuals() -> void:
	if not is_instance_valid(siamese_leader) or not sprite or not siamese_leader.sprite:
		return
	var lead_sprite := siamese_leader.sprite
	if sprite.animation != lead_sprite.animation:
		sprite.play(lead_sprite.animation)


func _physics_process(delta: float) -> void:
	if is_siamese_follower and is_instance_valid(siamese_leader) and not siamese_leader.is_dead:
		global_position = siamese_leader.global_position + siamese_offset
		_sync_siamese_visuals()
		velocity = Vector2.ZERO
		if deals_melee_damage:
			_deal_melee_damage_to_player()
		return
	super._physics_process(delta)


## Пауза в позе ожидания перед роллом следующей фазы.
func await_phase_switch() -> void:
	var wait := get_phase_switch_time()
	if wait <= 0.01:
		await get_tree().process_frame
		return
	await get_tree().create_timer(wait).timeout


## Старт паузы между фазами: босс уже в IDLE/idle, по таймауту — enemy_action().
func _schedule_next_decision() -> void:
	if not can_act_independently():
		return
	if not active or not player_in_vision or is_dead:
		return
	var wait := get_phase_switch_time()
	if wait <= 0.0:
		enemy_action()
		return
	cooldown_timer.wait_time = wait
	cooldown_timer.start()


func _on_blind_timer_timeout() -> void:
	if not can_act_independently():
		if player_in_vision:
			active = true
		return
	if player_in_vision:
		active = true
		if use_pathfinding:
			_pathfind_cooldown = 0.0
		_schedule_next_decision()


func die() -> void:
	if is_dead:
		return
	if is_instance_valid(siamese_follower) and not siamese_follower.is_dead:
		siamese_follower.release_siamese_follow()
	super.die()


func hit(amount: float, clear := false) -> void:
	if is_dead:
		return
	super.hit(amount, clear)
	if vengeful_enabled:
		_fire_vengeful_shot()


func _fire_vengeful_shot() -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return

	var origin := global_position
	var dir := player.global_position - origin
	if dir.length_squared() < 0.01:
		return
	dir = dir.normalized()

	var shot: Node2D = VENGEFUL_SHOT_SCENE.instantiate()
	shot.global_position = origin
	shot.owner_enemy = self
	# 1 база → Boss_damage_buff / Deathly / Toxic через общий пайплайн.
	var dmg := maxi(1, int(round(1.0 * Boss_damage_buff)))
	if GameState.level_bufs[2][1]:
		dmg = maxi(1, dmg * 2)
	shot.setup(dir, _build_damage_vector(dmg), VENGEFUL_SHOT_SPEED, VENGEFUL_SHOT_RANGE)
	get_tree().current_scene.call_deferred("add_child", shot)
