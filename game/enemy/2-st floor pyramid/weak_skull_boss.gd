extends Boss
class_name EnemyWeakSkullBoss

## Ивентовый босс на базе WeakSkull (chase продублирован, не наследует EnemyWeakSkull).

enum Phase {
	CHASE,
	MIND_CONTROL,
	INVIS_PREP,
	INVIS_FADE_OUT,
	INVIS_HIDDEN,
	INVIS_FADE_IN,
}

const ABILITY_COOLDOWN := 6.0
const MIND_DURATION := 1.5
const MIND_SPEED_MULT := 2.5
const MIND_ON_HIT_CHANCE := 0.1
const INVIS_PREP_TIME := 2.0
const INVIS_FADE_OUT_TIME := 0.5
const INVIS_HIDDEN_TIME := 5.0
const INVIS_FADE_IN_TIME := 2.0
const MIN_HP_SIZE_RATIO := 0.25
const SIZE_SHRINK_FACTOR := 4.0

@export_group("Behavior")
@export var hard_vision_radius: float = -1.0

var phase := Phase.CHASE
var _phase_timer := 0.0
var _mind_control_active := false
var _mind_token := 0
var _invis_token := 0
var _ability_busy := false
var _base_modulate_a := 1.0
var _fade_tween: Tween

@onready var _field_view_shape: CollisionShape2D = get_node_or_null(
	"FieldViewArea/Field_of_View"
) as CollisionShape2D


func _ready() -> void:
	BossName = "Big Weak Skull"
	use_base_move_towards_player = false
	# Иначе при касании встаёт в игроке и лупит, пока тот не умрёт.
	stop_on_melee_hit = false
	deals_melee_damage = true
	super._ready()
	_apply_vision_radius()
	_base_modulate_a = modulate.a
	_update_size_from_hp()
	_update_locomotion_animation()


func _apply_level_buffs() -> void:
	super._apply_level_buffs()
	base_move_speed = move_speed


func get_phase_switch_time() -> float:
	return ABILITY_COOLDOWN / maxf(GameState.time_flow_mult, 0.01)


func _apply_vision_radius() -> void:
	if hard_vision_radius <= 0.0 or _field_view_shape == null:
		return
	if not (_field_view_shape.shape is CircleShape2D):
		return
	var circle := (_field_view_shape.shape as CircleShape2D).duplicate()
	circle.radius = hard_vision_radius
	_field_view_shape.shape = circle


func _on_blind_timer_timeout() -> void:
	if not can_act_independently():
		if player_in_vision:
			active = true
		return
	if player_in_vision:
		active = true
		_update_locomotion_animation()
		_schedule_next_decision()


func _on_field_view_area_body_entered(body: Node2D) -> void:
	super._on_field_view_area_body_entered(body)
	if body.is_in_group("player") and active and can_act_independently():
		if cooldown_timer.is_stopped() and not _ability_busy:
			_schedule_next_decision()


func _on_field_view_area_body_exited(body: Node2D) -> void:
	super._on_field_view_area_body_exited(body)
	_update_locomotion_animation()


func enemy_action() -> void:
	if not can_act_independently() or is_dead or not active:
		return
	if _ability_busy:
		return
	if randf() < 0.5:
		_start_mind_control(false)
	else:
		_start_invisibility()


func _custom_physics(delta: float) -> void:
	if not can_act_independently():
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Mind-control может идти параллельно с invis — движение всегда от WASD.
	if _mind_control_active:
		_process_mind_control(delta)
		if _is_invis_phase():
			_tick_invis(delta)
		return

	match phase:
		Phase.MIND_CONTROL:
			_process_mind_control(delta)
		Phase.INVIS_PREP, Phase.INVIS_FADE_OUT, Phase.INVIS_HIDDEN, Phase.INVIS_FADE_IN:
			_tick_invis(delta)
		_:
			if active and player:
				_chase_player()
			else:
				velocity = Vector2.ZERO
				move_and_slide()


func _tick_invis(delta: float) -> void:
	# Движение: mind-control уже сдвинул; иначе prep стоит / остальные фазы chase.
	if not _mind_control_active:
		if phase == Phase.INVIS_PREP:
			velocity = Vector2.ZERO
			move_and_slide()
		else:
			_chase_player()

	_phase_timer -= delta
	if _phase_timer > 0.0:
		return

	match phase:
		Phase.INVIS_PREP:
			_begin_invis_fade_out()
		Phase.INVIS_FADE_OUT:
			phase = Phase.INVIS_HIDDEN
			_phase_timer = INVIS_HIDDEN_TIME
			modulate.a = 0.0
		Phase.INVIS_HIDDEN:
			_begin_invis_fade_in()
		Phase.INVIS_FADE_IN:
			modulate.a = _base_modulate_a
			_finish_scheduled_ability()
		_:
			_finish_scheduled_ability()


func _chase_player() -> void:
	if not player:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var dir := get_direction_to_player()
	if dir == Vector2.ZERO:
		velocity = Vector2.ZERO
		move_and_slide()
		_update_locomotion_animation()
		return
	velocity = dir * move_speed
	_update_walk_from_dir(dir)
	move_and_slide()


func _process_mind_control(_delta: float) -> void:
	var dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)
	if dir.length_squared() > 0.01:
		dir = dir.normalized()
		velocity = dir * move_speed
		_update_walk_from_dir(dir)
	else:
		velocity = Vector2.ZERO
		_play_idle()
	move_and_slide()


func _start_mind_control(from_hit_proc: bool) -> void:
	if is_dead:
		return
	if from_hit_proc and _mind_control_active:
		return

	_mind_token += 1
	var token := _mind_token
	_mind_control_active = true
	move_speed = base_move_speed * MIND_SPEED_MULT
	_update_locomotion_animation()
	_lock_player_walk(true)

	if not from_hit_proc:
		_ability_busy = true
		phase = Phase.MIND_CONTROL
		_start_ability_cooldown()

	_finish_mind_control_later(token, from_hit_proc)


func _finish_mind_control_later(token: int, from_hit_proc: bool) -> void:
	await get_tree().create_timer(MIND_DURATION).timeout
	if token != _mind_token or is_dead:
		return
	_end_mind_control(from_hit_proc)


func _end_mind_control(from_hit_proc: bool) -> void:
	_mind_control_active = false
	_lock_player_walk(false)
	move_speed = base_move_speed

	if from_hit_proc:
		if phase == Phase.MIND_CONTROL:
			phase = Phase.CHASE
		_update_locomotion_animation()
		return

	if phase == Phase.MIND_CONTROL:
		_finish_scheduled_ability()


func _start_invisibility() -> void:
	if is_dead or _ability_busy:
		return
	_ability_busy = true
	_invis_token += 1
	phase = Phase.INVIS_PREP
	_phase_timer = INVIS_PREP_TIME
	velocity = Vector2.ZERO
	_start_ability_cooldown()
	_play_anim_if_has("invis_cast")


func _begin_invis_fade_out() -> void:
	phase = Phase.INVIS_FADE_OUT
	_phase_timer = INVIS_FADE_OUT_TIME
	_update_locomotion_animation()
	_kill_fade_tween()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, INVIS_FADE_OUT_TIME)


func _begin_invis_fade_in() -> void:
	phase = Phase.INVIS_FADE_IN
	_phase_timer = INVIS_FADE_IN_TIME
	_update_locomotion_animation()
	_kill_fade_tween()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", _base_modulate_a, INVIS_FADE_IN_TIME)


func _start_ability_cooldown() -> void:
	cooldown_timer.wait_time = ABILITY_COOLDOWN
	cooldown_timer.start()


func _finish_scheduled_ability() -> void:
	_ability_busy = false
	phase = Phase.CHASE
	if not _mind_control_active:
		move_speed = base_move_speed
	_update_locomotion_animation()
	# Кулдаун мог закончиться раньше длинной абилки — сразу следующий ролл.
	if active and player_in_vision and not is_dead and cooldown_timer.is_stopped():
		enemy_action()


func _is_invis_phase() -> bool:
	return phase == Phase.INVIS_PREP \
		or phase == Phase.INVIS_FADE_OUT \
		or phase == Phase.INVIS_HIDDEN \
		or phase == Phase.INVIS_FADE_IN


func hit(amount: float, clear := false) -> void:
	if is_dead:
		return
	super.hit(amount, clear)
	if is_dead:
		return
	_update_size_from_hp()
	if randf() < MIND_ON_HIT_CHANCE:
		_start_mind_control(true)


func _update_size_from_hp() -> void:
	if base_hp <= 0:
		return
	var hp_ratio := clampf(float(current_hp) / float(base_hp), 0.0, 1.0)
	var t := clampf((hp_ratio - MIN_HP_SIZE_RATIO) / (1.0 - MIN_HP_SIZE_RATIO), 0.0, 1.0)
	var min_scale := boss_model_scale / SIZE_SHRINK_FACTOR
	var model := lerpf(min_scale, boss_model_scale, t)
	var s := model * Boss_model_size_buff * GameState.boss_size_multiplier
	scale = Vector2(s, s)


func _lock_player_walk(locked: bool) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_walk_input_locked"):
		player.set_walk_input_locked(locked)


func _kill_fade_tween() -> void:
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = null


func die() -> void:
	_mind_token += 1
	_invis_token += 1
	_kill_fade_tween()
	_lock_player_walk(false)
	modulate.a = _base_modulate_a
	super.die()


func _update_locomotion_animation() -> void:
	if is_dead or sprite == null or sprite.sprite_frames == null:
		return
	if phase == Phase.INVIS_PREP:
		_play_anim_if_has("invis_cast")
		return
	if active or _mind_control_active:
		_update_active_walk_animation()
	elif sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")


func _update_active_walk_animation() -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if _mind_control_active:
		var dir := Vector2(
			Input.get_axis("move_left", "move_right"),
			Input.get_axis("move_up", "move_down")
		)
		if dir.length_squared() < 0.01:
			_play_idle()
			return
		_update_walk_from_dir(dir.normalized())
		return
	if not player:
		_play_walk_side()
		return
	var to_player := player.global_position - global_position
	if to_player.length_squared() < 1.0:
		_play_idle()
		return
	_update_walk_from_dir(to_player.normalized())


func _update_walk_from_dir(dir: Vector2) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if absf(dir.y) > absf(dir.x):
		var anim := "up" if dir.y < 0.0 else "down"
		if sprite.sprite_frames.has_animation(anim):
			sprite.play(anim)
		sprite.flip_h = false
		return
	_play_walk_side(dir.x < 0.0)


func _play_walk_side(flip_left: bool = false) -> void:
	if sprite.sprite_frames.has_animation("default"):
		sprite.play("default")
	sprite.flip_h = flip_left


func _play_idle() -> void:
	_play_anim_if_has("idle")


func _play_anim_if_has(anim_name: StringName) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name:
			sprite.play(anim_name)
