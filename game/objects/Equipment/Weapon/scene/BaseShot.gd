extends Area2D
class_name BaseShot

const BOOMERANG_MIN_CURVE_T_RATE := 0.18
const BOOMERANG_SPEED_CURVE := preload("res://game/combat/boomerang_speed_curve.tres")

var player
var speed: float = 300.0
var animaited_speed = 1
var direction: Vector2 = Vector2.RIGHT
var atk_range: float
var damage: int
var extra_reload: float = 1.0 # только для слёз множитель больше 1 1,6 MAX
@export var use_spread: bool = true
@export var pellet_count := 1
@export var self_damage_multiplier: float = 1
@export var self_speed_multiplier: float = 1
@export var self_range_multiplier: float = 1
## 0 — прямой полёт; 1 — туда + обратно; 2+ — дополнительные отрезки пути.
@export var boomerang_power: int = 0
## Множитель дальности только для первого отрезка бумеранга (до первого разворота).
@export var boomerang_first_leg_mult: float = 1.0
## Сколько прорубаний создать за целью при попадании (0 = нет).
@export var hack: int = 0
## Сколько рикошетов осталось (0 — без отскока). Пробивание имеет приоритет.
@export var ricochet: int = 0
## Число врагов, сквозь которых снаряд проходит, не исчезая (0 — остановка на первом).
@export var penetration: int = 0
## Радиус AoE при ударе (0 — только основная цель).
@export var aoe_radius: float = 0.0

var distance_travelled := 0.0
var exploded := false

var _max_boomerang_range := 0.0
var _boomerang_segment := 0
var _boomerang_segment_count := 0
var _segment_curve_t := 0.0
var _segment_trip_duration := 1.0
var _boomerang_active := false
## Множитель скорости от кривой бумеранга (1→0→1 при развороте).
var _boom_speed_scale := 1.0
var _boom_leg_travelled := 0.0

var enchantment: EnchantmentResource
## Доп. зачарование поверх оружия (например Wild_Boots).
var extra_enchantment: EnchantmentResource

var _enemy_hit_count: int = 0
## Следующий удар по врагу может восстановить HP (Steal Life).
var steal_life: bool = false

## Цели, по которым копия ближнего рикошета не бьёт повторно.
var _ricochet_ignore_ids: Array[int] = []
## Пока не вышли из оверлапа с телом, от которого только что отскочили.
var _ricochet_overlap_id: int = 0

const RICOCHET_SEPARATION := 6.0
const RICOCHET_SPREAD_DEG := 5.0
const SPREAD_SHOT_DISTANCE := 75.0
const SPREAD_SHOT_COUNT := 6
const SPREAD_SHOT_CONE_DEG := 90.0
const SPREAD_SHOT_SCALE := 0.25
const SPREAD_SHOT_DAMAGE := 0.25
const SPREAD_SHOT_MELEE_SCALE := 0.6

var spread_angle: float
var spawned_spread := false
var _spread_shot_done := false
## Сколько стаков Star Fruit навесить после дроби (ставит игрок до add_child).
var star_fruit_stacks_to_apply: int = 0
var _star_fruit_applied: bool = false

var base_crit_bonus: float = 50.0
## Добавка к spread в формуле силы крита: bonus = base_crit_bonus / (spread + offset).
var crit_spread_offset: float = 40.0
var crit_sprite: int = -1
## Critical Flower: crit_bonus *= (1 + chance * power)
var critical_flower_power: float = 0.0
## Math Circle: угол отклонения (рад) для синус-поворота; 0 = прямо
var sine_amplitude: float = 0.0
## Частота поворота по пройденной дистанции (рад / пиксель пути).
var sine_frequency: float = 0.025
## true = cos(+π/2), false = sin; оба стартуют с центра волны.
var sine_use_cos: bool = false
var _sine_forward: Vector2 = Vector2.RIGHT
var _sine_initialized: bool = false
## Отдельный счётчик фазы волны (сбрасывается при рикошете/развороте).
var _sine_path_distance: float = 0.0

## Satellite orbit (экип Satellite)
var satellite_armed: bool = false # свободный полёт до ½ радиуса
var satellite_orbit: bool = false # chase | docked
var satellite_phase: String = "free" # free | chase | docked
var satellite_slot_index: int = -1
var satellite_current_angle: float = 0.0
var satellite_orbit_sign: float = 1.0 # зеркало знака якоря (рикошет)
var satellite_time_left: float = -1.0 # <0 = вечно (дальний); >=0 таймер ближки
var satellite_spawn_order: int = 0
var _satellite_vel: Vector2 = Vector2.ZERO
var _satellite_ctrl: Node = null
var _satellite_boom_mult: float = 1.0
var _satellite_arc_travelled: float = 0.0
var _satellite_melee_life: float = -1.0 # дублирует таймер ближки на орбите
const SATELLITE_WALL_MASK_BITS := 48 # layer 5 walls + layer 6 obstacles
const SATELLITE_CAPTURE_BLEND := 5.0
const SATELLITE_DOCK_DIST := 10.0
## Множитель длины орбитального полёта ближки (было 2).
const SATELLITE_MELEE_RANGE_MULT := 4.0

enum FireSfxKind { TEAR, GUN, SLASH, NONE }
@export var fire_sfx_kind: FireSfxKind = FireSfxKind.TEAR

const CRIT_WORLD_OFFSET := Vector2(0, -60)
const DEFAULT_SHADOW_WORLD_DOWN := Vector2(0, 20)

func _ready() -> void:
	animaited_speed = GameState.animated_world_speed
	player = get_tree().get_first_node_in_group("player")
	rotation = direction.angle()
	spread_angle = StatManager.get_stat(player, "spread")
	if GameState.Surestrike:
		spread_angle = 0.0
	_align_shadow_to_world()
	_play_attack_sfx()
	if pellet_count > 1 and not spawned_spread:
		spawned_spread = true
		_spawn_spread()
	_init_boomerang()
	if not body_exited.is_connected(_on_body_exited_ricochet):
		body_exited.connect(_on_body_exited_ricochet)
	# После дроби (deferred add_child) — Star Fruit на каждую дробинку отдельно.
	call_deferred("_try_apply_star_fruit")
	call_deferred("_try_register_satellite")


func _process(_delta: float) -> void:
	_align_shadow_to_world()
	_align_crit_to_world()


func _play_attack_sfx() -> void:
	if spawned_spread:
		return
	match fire_sfx_kind:
		FireSfxKind.GUN:
			SoundManager.play_gun_shot()
		FireSfxKind.TEAR:
			SoundManager.play_tear_shot()
		FireSfxKind.SLASH:
			SoundManager.play_slash()
		FireSfxKind.NONE:
			pass

func _physics_process(delta: float) -> void:
	if exploded:
		return
	if satellite_orbit:
		_physics_process_satellite(delta)
		return
	if _boomerang_active:
		_physics_process_boomerang(delta)
	elif sine_amplitude > 0.0:
		_physics_process_sine(delta)
	else:
		_physics_process_linear(delta)


func _physics_process_linear(delta: float) -> void:
	var movement := direction.normalized() * speed * delta * self_speed_multiplier
	position += movement
	distance_travelled += movement.length()

	if not satellite_armed and distance_travelled >= atk_range * self_range_multiplier:
		exploded = true
		explosion(1)
		return
	_try_spread_shot_split()
	_try_satellite_capture_check()


func _physics_process_sine(delta: float) -> void:
	if not _sine_initialized:
		_retarget_sine_base()

	var step_len := speed * delta * self_speed_multiplier
	var angle_off := _sine_wave_angle(_sine_path_distance) * sine_amplitude
	var move_dir := _sine_forward.rotated(angle_off)
	position += move_dir * step_len
	_sine_path_distance += step_len
	distance_travelled += step_len
	direction = move_dir
	rotation = move_dir.angle()

	if not satellite_armed and distance_travelled >= atk_range * self_range_multiplier:
		exploded = true
		explosion(1)
		return
	_try_spread_shot_split()
	_try_satellite_capture_check()


func _sine_wave_angle(path_dist: float) -> float:
	var t := path_dist * sine_frequency
	if sine_use_cos:
		return cos(t + PI * 0.5)
	return sin(t)


func _retarget_sine_base() -> void:
	if sine_amplitude <= 0.0:
		return
	_sine_forward = direction.normalized()
	if _sine_forward == Vector2.ZERO:
		_sine_forward = Vector2.RIGHT
	_sine_path_distance = 0.0
	_sine_initialized = true


## Бумеранг: кривая скорости 1→0→1, в нуле плавный разворот оси.
## Math Circle — волна вокруг текущей оси direction.
func _physics_process_boomerang(delta: float) -> void:
	if _boomerang_segment >= _boomerang_segment_count:
		_finish_boomerang_path()
		return
	if _segment_curve_t >= 1.0:
		_advance_boomerang_segment()
		return

	var outbound := _boomerang_segment % 2 == 0
	var sample_t := lerpf(0.0, 0.5, _segment_curve_t) if outbound else lerpf(0.5, 1.0, _segment_curve_t)
	var mult := BOOMERANG_SPEED_CURVE.sample(sample_t)
	# Движение: |mult| (у нуля почти стоп). Прогресс кривой — отдельно, с мин. floor.
	var axis := direction.normalized()
	if axis == Vector2.ZERO:
		axis = Vector2.RIGHT
	var move_dir := axis
	if sine_amplitude > 0.0:
		if not _sine_initialized:
			_retarget_sine_base()
		_sine_forward = axis
		var angle_off := _sine_wave_angle(_sine_path_distance) * sine_amplitude
		move_dir = _sine_forward.rotated(angle_off)

	var step_len := speed * absf(mult) * delta * self_speed_multiplier
	var step := move_dir * step_len
	global_position += step
	if sine_amplitude > 0.0:
		_sine_path_distance += step_len
	distance_travelled += step_len
	rotation = move_dir.angle()

	var t_rate := maxf(absf(mult), BOOMERANG_MIN_CURVE_T_RATE)
	_segment_curve_t += (t_rate * delta) / maxf(_segment_trip_duration, 0.001)
	_segment_curve_t = minf(_segment_curve_t, 1.0)
	_boom_speed_scale = absf(mult)
	_try_spread_shot_split()
	_try_satellite_capture_check()


func _init_boomerang() -> void:
	if boomerang_power <= 0:
		_boomerang_active = false
		_boom_speed_scale = 1.0
		return

	_max_boomerang_range = atk_range * self_range_multiplier
	_boomerang_segment_count = boomerang_power + 1
	_boomerang_segment = 0
	_segment_curve_t = 0.0
	_boom_leg_travelled = 0.0
	_segment_trip_duration = _get_boomerang_segment_duration(0)
	_boom_speed_scale = 1.0
	_boomerang_active = true


func _get_boomerang_leg_range(segment: int) -> float:
	var range_len := _max_boomerang_range
	if segment == 0:
		range_len *= boomerang_first_leg_mult
	return maxf(range_len, 1.0)


func _get_boomerang_segment_duration(segment: int) -> float:
	return _get_boomerang_leg_range(segment) / maxf(speed * self_speed_multiplier, 1.0)


func _sample_boomerang_speed_scale() -> float:
	var outbound := _boomerang_segment % 2 == 0
	var sample_t := lerpf(0.0, 0.5, _segment_curve_t) if outbound else lerpf(0.5, 1.0, _segment_curve_t)
	return absf(BOOMERANG_SPEED_CURVE.sample(sample_t))


func _copy_boomerang_flight_state(source: BaseShot) -> void:
	_boomerang_active = source._boomerang_active
	_max_boomerang_range = source._max_boomerang_range
	_boomerang_segment_count = source._boomerang_segment_count
	_boomerang_segment = source._boomerang_segment
	_segment_curve_t = source._segment_curve_t
	_segment_trip_duration = source._segment_trip_duration
	_boom_leg_travelled = source._boom_leg_travelled
	_boom_speed_scale = source._boom_speed_scale
	boomerang_power = source.boomerang_power
	boomerang_first_leg_mult = source.boomerang_first_leg_mult


func _advance_boomerang_segment() -> void:
	_boomerang_segment += 1
	_segment_curve_t = 0.0
	_boom_leg_travelled = 0.0
	if _boomerang_segment >= _boomerang_segment_count:
		_finish_boomerang_path()
		return
	# В нуле кривой — разворот оси (уже почти стоим).
	direction = -direction.normalized() if direction.length_squared() > 0.0 else Vector2.LEFT
	_retarget_sine_base()
	_segment_trip_duration = _get_boomerang_segment_duration(_boomerang_segment)
	_boom_speed_scale = _sample_boomerang_speed_scale()


func _finish_boomerang_path() -> void:
	if exploded:
		return
	_boomerang_active = false
	_boom_speed_scale = 1.0
	exploded = true
	explosion(1)


func _on_body_entered(body):
	if exploded:
		return
	if body.name == "Player" or body.is_in_group("player"):
		return
	if _ricochet_overlap_id != 0 and body.get_instance_id() == _ricochet_overlap_id:
		return
	_resolve_collision(body)


func _resolve_collision(body: Node) -> void:
	if body.has_method("hit"):
		if _is_ricochet_ignored(body):
			return
		if _register_pierce_hit(body, _get_final_damage(body)):
			# Пробивание исчерпано — рикошет, иначе уничтожение.
			if not _try_ricochet(body):
				if satellite_orbit and _satellite_ctrl:
					_satellite_ctrl.unregister_shot(self)
				exploded = true
				explosion(0)
		return

	# На орбите Satellite стены/препятствия игнорируем.
	if satellite_orbit:
		return

	if not _try_ricochet(body):
		exploded = true
		explosion(0)


func _on_body_exited_ricochet(body: Node) -> void:
	if body.get_instance_id() == _ricochet_overlap_id:
		_ricochet_overlap_id = 0


func _allows_ricochet() -> bool:
	return true


func _uses_melee_ricochet() -> bool:
	return false


func _is_ricochet_ignored(body: Node) -> bool:
	return body.get_instance_id() in _ricochet_ignore_ids


func _get_flight_direction() -> Vector2:
	var dir := direction.normalized()
	if dir != Vector2.ZERO:
		return dir
	return Vector2.RIGHT


## Возвращает true, если снаряд отскочил и продолжает жить.
func _try_ricochet(body: Node) -> bool:
	if ricochet <= 0 or not _allows_ricochet():
		return false
	if _uses_melee_ricochet():
		return _perform_melee_ricochet(body)
	return _perform_projectile_ricochet(body)


func _perform_melee_ricochet(_body: Node) -> bool:
	return false


func _perform_projectile_ricochet(body: Node) -> bool:
	ricochet -= 1
	if satellite_orbit:
		# Рикошет на круге — разворот крепления/облёта.
		satellite_orbit_sign *= -1.0
		if _satellite_ctrl and _satellite_ctrl.has_method("flip_anchor_sign_for_shot"):
			_satellite_ctrl.flip_anchor_sign_for_shot(self)
		if is_instance_valid(body):
			_ricochet_overlap_id = body.get_instance_id()
		return true

	var bounce := _compute_bounce_info(body)
	var normal: Vector2 = bounce.normal
	var in_dir := _get_flight_direction()
	var out_dir := _apply_ricochet_spread(in_dir.bounce(normal))
	if out_dir.length_squared() < 0.0001:
		out_dir = _apply_ricochet_spread(-in_dir)

	direction = out_dir
	_retarget_sine_base()
	_sync_facing_after_redirect()
	global_position += normal * RICOCHET_SEPARATION
	if is_instance_valid(body):
		_ricochet_overlap_id = body.get_instance_id()
	return true


func _apply_ricochet_spread(dir: Vector2) -> Vector2:
	if dir.length_squared() < 0.0001:
		return Vector2.RIGHT
	var spread := deg_to_rad(randf_range(-RICOCHET_SPREAD_DEG, RICOCHET_SPREAD_DEG))
	return dir.normalized().rotated(spread)


## { "normal": Vector2, "point": Vector2 }
func _compute_bounce_info(body: Node) -> Dictionary:
	var in_dir := _get_flight_direction()
	var fallback_n := -in_dir
	var fallback_p := _get_weapon_hit_point()
	if body is Node2D:
		var body_2d := body as Node2D
		var away: Vector2 = global_position - body_2d.global_position
		if away.length_squared() > 0.0001:
			fallback_n = away.normalized()
		fallback_p = DamageDealer.get_hit_contact_point(self, body_2d, fallback_p)

	var space := get_world_2d().direct_space_state
	if space == null:
		return {"normal": fallback_n, "point": fallback_p}

	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col and col.shape:
		var params := PhysicsShapeQueryParameters2D.new()
		params.shape = col.shape
		params.transform = col.global_transform
		params.collision_mask = collision_mask
		params.collide_with_areas = false
		params.collide_with_bodies = true
		var rest := space.get_rest_info(params)
		if not rest.is_empty():
			var n: Vector2 = rest.get("normal", Vector2.ZERO)
			var p: Vector2 = rest.get("point", fallback_p)
			if n != Vector2.ZERO:
				return {"normal": n.normalized(), "point": p}

	var from := global_position - in_dir * 4.0
	var to := global_position + in_dir * 48.0
	var query := PhysicsRayQueryParameters2D.create(from, to)
	query.collision_mask = collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var result := space.intersect_ray(query)
	if result and result.normal != Vector2.ZERO:
		return {"normal": result.normal.normalized(), "point": result.position}

	if body is Node2D:
		var target: Vector2 = (body as Node2D).global_position
		if global_position.distance_squared_to(target) > 1.0:
			query = PhysicsRayQueryParameters2D.create(global_position, target)
			query.collision_mask = collision_mask
			query.collide_with_areas = false
			query.collide_with_bodies = true
			result = space.intersect_ray(query)
			if result and result.normal != Vector2.ZERO:
				return {"normal": result.normal.normalized(), "point": result.position}

	return {"normal": fallback_n, "point": fallback_p}


func _compute_bounce_normal(body: Node) -> Vector2:
	return _compute_bounce_info(body).normal


func _sync_facing_after_redirect() -> void:
	rotation = direction.angle()
	_align_crit_to_world()
	_align_shadow_to_world()


func _try_apply_star_fruit() -> void:
	if _star_fruit_applied or star_fruit_stacks_to_apply <= 0:
		return
	if not is_instance_valid(self) or exploded:
		return
	var stacks := star_fruit_stacks_to_apply
	star_fruit_stacks_to_apply = 0
	_star_fruit_applied = true
	var shooter := _get_player()
	if shooter and shooter.has_method("apply_star_fruit_to_shot"):
		shooter.apply_star_fruit_to_shot(self, stacks)


func _try_register_satellite() -> void:
	if not GameState.SatelliteOrbit or satellite_orbit or satellite_armed or exploded:
		return
	if not is_instance_valid(self):
		return
	var shooter := _get_player()
	if shooter == null:
		return
	var ctrl := shooter.get_node_or_null("SatelliteOrbit") as SatelliteOrbitController
	if ctrl == null:
		ctrl = SatelliteOrbitController.new()
		ctrl.name = "SatelliteOrbit"
		shooter.add_child(ctrl)
	ctrl.register_shot(self)


func arm_satellite(ctrl: Node) -> void:
	_satellite_ctrl = ctrl
	satellite_armed = true
	satellite_phase = "free"
	satellite_slot_index = -1
	satellite_orbit_sign = 1.0
	satellite_spawn_order = SatelliteOrbitController.next_spawn_order()
	satellite_time_left = -1.0


func begin_satellite_capture(ctrl: Node, slot_idx: int = -1) -> void:
	_satellite_ctrl = ctrl
	satellite_armed = false
	satellite_orbit = true
	satellite_phase = "chase"
	satellite_slot_index = slot_idx
	satellite_orbit_sign = 1.0
	_satellite_boom_mult = 1.0
	if satellite_spawn_order <= 0:
		satellite_spawn_order = SatelliteOrbitController.next_spawn_order()
	collision_mask = collision_mask & ~SATELLITE_WALL_MASK_BITS
	_boomerang_active = false

	var orbit_spd := 48.0
	if ctrl and ctrl.has_method("get_orbit_speed"):
		orbit_spd = ctrl.get_orbit_speed()

	var is_melee := _uses_melee_ricochet()
	_satellite_arc_travelled = 0.0
	if is_melee:
		_satellite_freeze_melee_sprite()
		# Дальность жизни на орбите: множитель к atk_range (дуга и таймер).
		var melee_orbit_range := atk_range * SATELLITE_MELEE_RANGE_MULT
		_satellite_melee_life = melee_orbit_range / maxf(orbit_spd, 1.0)
		satellite_time_left = _satellite_melee_life
		speed = 0.0
		var life := maxf(_satellite_melee_life, 0.05)
		var tree := get_tree()
		if tree:
			tree.create_timer(life).timeout.connect(_on_satellite_melee_timer)
	else:
		satellite_time_left = -1.0
		_satellite_melee_life = -1.0

	# Бумеранг на орбите: та же логика — плавно гасим скорость, разворот знака.
	if boomerang_power > 0:
		_max_boomerang_range = maxf(atk_range * self_range_multiplier, 1.0)
		_boomerang_segment_count = boomerang_power + 1
		_boomerang_segment = 0
		_segment_curve_t = 0.0
		_boom_leg_travelled = 0.0
		_boom_speed_scale = 1.0
		_satellite_boom_mult = 1.0
		_segment_trip_duration = _get_boomerang_leg_range(0) / maxf(orbit_spd, 1.0)

	# Вся ближка — сразу на пустом/освободившемся слоте, без подлёта.
	if is_melee and ctrl and ctrl.has_method("get_anchor_world_pos") and slot_idx >= 0:
		satellite_phase = "docked"
		global_position = ctrl.get_anchor_world_pos(slot_idx)
		_satellite_face_away_from_player()
		return

	var target := global_position
	if ctrl and ctrl.has_method("get_anchor_world_pos") and slot_idx >= 0:
		target = ctrl.get_anchor_world_pos(slot_idx)
	var to_t := target - global_position
	var fly := maxf(speed * self_speed_multiplier, orbit_spd)
	if to_t.length_squared() > 0.01:
		_satellite_vel = to_t.normalized() * fly
	elif direction.length_squared() > 0.01:
		_satellite_vel = direction.normalized() * fly
	else:
		_satellite_vel = Vector2.RIGHT * fly


func force_satellite_expire() -> void:
	if exploded:
		return
	if _satellite_ctrl and _satellite_ctrl.has_method("unregister_shot"):
		_satellite_ctrl.unregister_shot(self)
	_satellite_ctrl = null
	satellite_orbit = false
	satellite_armed = false
	satellite_phase = "free"
	satellite_slot_index = -1
	exploded = true
	monitoring = false
	set_deferred("monitorable", false)
	var spr := get_node_or_null("shot_Animated") as AnimatedSprite2D
	if spr:
		spr.stop()
		spr.hide()
	# Ближка без miss-анимации — сразу убрать с поля.
	if _uses_melee_ricochet():
		queue_free()
		return
	explosion(1)


func _on_satellite_melee_timer() -> void:
	if not is_instance_valid(self) or exploded:
		return
	force_satellite_expire()


func get_satellite_boomerang_speed_mult() -> float:
	if boomerang_power <= 0 or _boomerang_segment_count <= 0:
		return 1.0
	return _satellite_boom_mult


func notify_satellite_arc(arc_len: float, delta: float) -> void:
	if arc_len > 0.0:
		_satellite_arc_travelled += arc_len
		if _uses_melee_ricochet() and atk_range > 0.0:
			if _satellite_arc_travelled >= atk_range * SATELLITE_MELEE_RANGE_MULT:
				force_satellite_expire()
				return
	if boomerang_power <= 0 or _boomerang_segment_count <= 0:
		return
	if satellite_phase != "docked" and satellite_phase != "chase":
		return
	# Как в свободном полёте: кривая по времени → почти стоп → разворот знака орбиты.
	var orbit_spd := 48.0
	if _satellite_ctrl and _satellite_ctrl.has_method("get_orbit_speed"):
		orbit_spd = _satellite_ctrl.get_orbit_speed()
	if _segment_trip_duration <= 0.0:
		_segment_trip_duration = _get_boomerang_leg_range(_boomerang_segment) / maxf(orbit_spd, 1.0)

	var outbound := _boomerang_segment % 2 == 0
	var sample_t := lerpf(0.0, 0.5, _segment_curve_t) if outbound else lerpf(0.5, 1.0, _segment_curve_t)
	var mult := BOOMERANG_SPEED_CURVE.sample(sample_t)
	_satellite_boom_mult = absf(mult)
	_boom_speed_scale = _satellite_boom_mult

	var t_rate := maxf(absf(mult), BOOMERANG_MIN_CURVE_T_RATE)
	_segment_curve_t += (t_rate * delta) / maxf(_segment_trip_duration, 0.001)
	_segment_curve_t = minf(_segment_curve_t, 1.0)
	if _segment_curve_t < 1.0:
		return

	_segment_curve_t = 0.0
	_boom_leg_travelled = 0.0
	_boomerang_segment += 1
	if _boomerang_segment >= _boomerang_segment_count:
		_boomerang_segment_count = 0
		_satellite_boom_mult = 1.0
		_boom_speed_scale = 1.0
		return
	if _satellite_ctrl and _satellite_ctrl.has_method("flip_anchor_sign_for_shot"):
		_satellite_ctrl.flip_anchor_sign_for_shot(self)
	if _satellite_ctrl and _satellite_ctrl.has_method("get_anchor_sign"):
		satellite_orbit_sign = _satellite_ctrl.get_anchor_sign(satellite_slot_index)
	_segment_trip_duration = _get_boomerang_leg_range(_boomerang_segment) / maxf(orbit_spd, 1.0)
	_satellite_boom_mult = _sample_boomerang_speed_scale()
	_boom_speed_scale = _satellite_boom_mult


func _satellite_hard_lock() -> bool:
	return false


func _satellite_face_away_from_player() -> void:
	var shooter := _get_player()
	if shooter == null:
		return
	var away = global_position - shooter.global_position
	if away.length_squared() < 0.0001:
		away = Vector2.RIGHT
	direction = away.normalized()
	rotation = direction.angle()
	_align_shadow_to_world()
	_align_crit_to_world()


func _try_satellite_capture_check() -> void:
	if not satellite_armed or satellite_orbit or exploded:
		return
	var shooter := _get_player()
	if shooter == null or not is_instance_valid(shooter):
		return
	var half_r := SatelliteOrbitController.ORBIT_RADIUS * 0.5
	if _satellite_ctrl and _satellite_ctrl.has_method("get_half_radius"):
		half_r = _satellite_ctrl.get_half_radius()
	if global_position.distance_to(shooter.global_position) < half_r:
		return
	if _satellite_ctrl and _satellite_ctrl.has_method("begin_capture"):
		_satellite_ctrl.begin_capture(self)


func _satellite_freeze_melee_sprite() -> void:
	var spr := get_node_or_null("shot_Animated") as AnimatedSprite2D
	if spr == null:
		return
	spr.pause()
	spr.frame = 0
	if has_method("_on_frame_changed"):
		call("_on_frame_changed")


func _physics_process_satellite(delta: float) -> void:
	var shooter := _get_player()
	if shooter == null or not is_instance_valid(shooter):
		force_satellite_expire()
		return
	var orbit_spd := 48.0
	if _satellite_ctrl and _satellite_ctrl.has_method("get_orbit_speed"):
		orbit_spd = _satellite_ctrl.get_orbit_speed()

	_satellite_chase_anchor(delta, orbit_spd)

	if satellite_time_left >= 0.0:
		satellite_time_left -= delta
		if satellite_time_left <= 0.0:
			force_satellite_expire()


func _satellite_chase_anchor(delta: float, orbit_spd: float) -> void:
	if _satellite_ctrl == null or satellite_slot_index < 0:
		force_satellite_expire()
		return

	var target: Vector2 = _satellite_ctrl.get_anchor_world_pos(satellite_slot_index)
	var ang: float = 0.0
	var sgn: float = satellite_orbit_sign
	if _satellite_ctrl.has_method("get_anchor_angle"):
		ang = _satellite_ctrl.get_anchor_angle(satellite_slot_index)
	if _satellite_ctrl.has_method("get_anchor_sign"):
		sgn = _satellite_ctrl.get_anchor_sign(satellite_slot_index)
		satellite_orbit_sign = sgn

	var boom_scl := 1.0
	if _satellite_ctrl.has_method("get_anchor_omega_scale"):
		boom_scl = absf(_satellite_ctrl.get_anchor_omega_scale(satellite_slot_index))

	var to_t := target - global_position
	var dist := to_t.length()
	satellite_current_angle = ang

	var tang := Vector2.RIGHT.rotated(ang + PI * 0.5 * sgn)
	var anchor_vel := tang * orbit_spd * boom_scl

	# После стыковки — намертво на креплении (мувспид игрока не сбивает).
	if _satellite_hard_lock() or satellite_phase == "docked":
		satellite_phase = "docked"
		global_position = target
		_satellite_vel = anchor_vel
		if _satellite_hard_lock() or _uses_melee_ricochet():
			_satellite_face_away_from_player()
		else:
			direction = tang
			rotation = direction.angle()
			_align_shadow_to_world()
			_align_crit_to_world()
		return

	# Только фаза подлёта к орбите — мягкий догон с лимитом ±75%.
	var max_corr = orbit_spd * SatelliteOrbitController.SPEED_CORR_FRAC
	var catch_vel := Vector2.ZERO
	if dist > 0.01:
		catch_vel = to_t.normalized() * minf(dist / maxf(delta, 0.0001), max_corr)

	var desired := anchor_vel + catch_vel
	var min_spd = orbit_spd * (1.0 - SatelliteOrbitController.SPEED_CORR_FRAC)
	var max_spd = orbit_spd * (1.0 + SatelliteOrbitController.SPEED_CORR_FRAC)
	var dlen := desired.length()
	if dlen > 0.01:
		desired = desired.normalized() * clampf(dlen, min_spd * boom_scl, maxf(max_spd * boom_scl, min_spd))
	else:
		desired = tang * orbit_spd * boom_scl

	_satellite_vel = _satellite_vel.lerp(desired, 1.0 - exp(-SATELLITE_CAPTURE_BLEND * delta))
	var vlen := _satellite_vel.length()
	if vlen > 0.01:
		_satellite_vel = _satellite_vel.normalized() * clampf(vlen, min_spd * boom_scl, maxf(max_spd * boom_scl, min_spd))

	global_position += _satellite_vel * delta
	if dist <= SATELLITE_DOCK_DIST:
		satellite_phase = "docked"
		global_position = target
		direction = tang
		if _satellite_ctrl.has_method("on_shot_reached_orbit"):
			_satellite_ctrl.on_shot_reached_orbit(self)
	elif _satellite_vel.length_squared() > 0.01:
		direction = _satellite_vel.normalized()

	rotation = direction.angle()
	_align_shadow_to_world()
	_align_crit_to_world()


## Ближка + SpreadShot: сначала Star Fruit, потом конус (иначе клоны фрукта
## с _spread_shot_done / early-return зависают без анимации).
func _deferred_melee_star_and_spread() -> void:
	_try_apply_star_fruit()
	if not is_instance_valid(self) or exploded:
		return
	_try_spread_shot_melee()


func _get_player() -> Node:
	if player:
		return player
	return get_tree().get_first_node_in_group("player")


func _get_crit_chance() -> float:
	var shooter := _get_player()
	if shooter:
		return shooter.crit_chance_bonus
	return 0.0


func _get_final_damage(target: Node = null) -> float:
	crit_sprite = -1
	var final_damage := float(damage * self_damage_multiplier)
	for e in _get_active_enchantments():
		if e.has_method("get_damage_low"):
			final_damage *= e.get_damage_low()

	var chance := _get_crit_chance()
	var spread_val := 20.0
	var shooter := _get_player()
	if shooter:
		spread_val = StatManager.get_stat(shooter, "spread")
	var crit_bonus := base_crit_bonus / (spread_val + crit_spread_offset)
	if critical_flower_power > 0.0:
		crit_bonus *= (1.0 + chance * critical_flower_power)
	var total_crit := 1.0
	while true:
		if randf() < chance:
			crit_sprite += 1
			total_crit += crit_bonus
			chance -= 0.2
			if crit_sprite == 4:
				StatsManager.add_statistic_progress("Mega_crit", 1)
				SoundManager.play_megacrit()
				break
		else:
			break
	# Assassination: первый урон по врагу → +1 уровень крита (кап 5).
	if target != null and DamageDealer.try_assassination_first_hit(target):
		if crit_sprite < 4:
			crit_sprite += 1
			total_crit += crit_bonus
			if crit_sprite == 4:
				StatsManager.add_statistic_progress("Mega_crit", 1)
				SoundManager.play_megacrit()
	return final_damage * total_crit


func _get_active_enchantments() -> Array[EnchantmentResource]:
	var result: Array[EnchantmentResource] = []
	if enchantment:
		result.append(enchantment)
	if extra_enchantment:
		result.append(extra_enchantment)
	return result


func _copy_enchantments_to(bullet: BaseShot) -> void:
	bullet.enchantment = enchantment
	bullet.extra_enchantment = extra_enchantment


func _show_crit_effect() -> void:
	if crit_sprite < 0:
		return
	var crit_node := get_node_or_null("Crit")
	if crit_node is AnimatedSprite2D:
		crit_node.frame = crit_sprite
		crit_node.show()
		_align_crit_to_world()


func _build_damage_info(target: Node, amount: float) -> DamageInfo:
	var info := DamageInfo.new()
	info.damage = amount
	info.source = self
	var weapon_point := _get_weapon_hit_point()
	info.hit_position = DamageDealer.get_hit_contact_point(self, target, weapon_point)
	info.enchantment = enchantment
	info.extra_enchantment = extra_enchantment
	info.penetration = penetration
	info.aoe_radius = aoe_radius
	info.hack = hack
	var flight_dir := direction.normalized()
	if flight_dir == Vector2.ZERO:
		flight_dir = Vector2.RIGHT
	info.hack_direction = flight_dir
	if target is Node2D:
		info.direction = (target.global_position - weapon_point).normalized()
	return info


func _get_effective_penetration() -> int:
	var info := DamageInfo.new()
	info.penetration = penetration
	DamageDealer.apply_hit_modifiers(info)
	return info.penetration


func _register_pierce_hit(target: Node, amount: float) -> bool:
	_deal_hit(target, amount)
	_enemy_hit_count += 1
	return _enemy_hit_count > _get_effective_penetration()


func _deal_hit(target: Node, amount: float) -> void:
	DamageDealer.deal_damage(self, target, _build_damage_info(target, amount))
	_show_crit_effect()
	_spawn_hack_effects(target, amount)
	_try_steal_life_heal()


func _try_steal_life_heal() -> void:
	if not steal_life:
		return
	if player == null or not is_instance_valid(player):
		return
	if not player.steal_life_heal_ready:
		return
	player.steal_life_heal_ready = false
	steal_life = false
	var free_slots: int = player.max_hp - (player.hp_list["red"] + player.hp_list["green"])
	if free_slots > 0:
		player.heal(0, 1, 0, 0)
	else:
		player.heal(0, 0, 1, 0)


func _spawn_hack_effects(target: Node, dealt_damage: float) -> void:
	if hack <= 0 or dealt_damage <= 0.0:
		return
	if not target is Node2D or not is_instance_valid(target):
		return
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	var dir := direction.normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	HackCleave.spawn_batch(parent, target as Node2D, dir, dealt_damage * 0.5, hack)


func explosion(animation_index):
	if _satellite_ctrl and _satellite_ctrl.has_method("unregister_shot"):
		_satellite_ctrl.unregister_shot(self)
		_satellite_ctrl = null
	satellite_orbit = false
	satellite_armed = false
	speed = 0
	var anim := get_node_or_null("shot_Animated") as AnimatedSprite2D
	if anim == null:
		queue_free()
		return
	anim.speed_scale = animaited_speed
	var play_name := ""
	if animation_index == 0:
		play_name = "default"
	elif animation_index == 1:
		play_name = "miss"
	# Ближка и часть снарядов без "miss" — иначе animation_finished не придёт и узел вечный.
	if play_name == "" or anim.sprite_frames == null or not anim.sprite_frames.has_animation(play_name):
		queue_free()
		return
	anim.play(play_name)

	_start_shadow_shrink()

	if not anim.is_connected("animation_finished", Callable(self, "_on_explosion_finished")):
		anim.connect("animation_finished", Callable(self, "_on_explosion_finished"))


func _start_shadow_shrink() -> void:
	_align_shadow_to_world()
	var shadow := get_node_or_null("Shadow")
	if shadow == null or not shadow.has_method("shrink_to_zero"):
		return
	shadow.shrink_to_zero(_get_sprite_anim_duration($shot_Animated))


## Тень всегда под снарядом в мире, независимо от rotation / duplicate дробинок.
func _align_shadow_to_world() -> void:
	var shadow := get_node_or_null("Shadow") as Node2D
	if shadow == null or not is_inside_tree():
		return
	var down := DEFAULT_SHADOW_WORLD_DOWN
	if "world_down_offset" in shadow:
		down = shadow.world_down_offset
	shadow.global_rotation = 0.0
	shadow.global_position = global_position + down


## Крит всегда сверху и без переворота (как тень — через world transform).
func _align_crit_to_world() -> void:
	var crit_node := get_node_or_null("Crit") as Node2D
	if crit_node == null or not is_inside_tree():
		return
	crit_node.global_rotation = 0.0
	crit_node.global_position = global_position + CRIT_WORLD_OFFSET


func _get_sprite_anim_duration(sprite: AnimatedSprite2D) -> float:
	if sprite == null or sprite.sprite_frames == null:
		return 0.25
	var anim_name := sprite.animation
	var sf := sprite.sprite_frames
	if not sf.has_animation(anim_name):
		return 0.25
	var total := 0.0
	for i in sf.get_frame_count(anim_name):
		total += sf.get_frame_duration(anim_name, i)
	var spd := sf.get_animation_speed(anim_name) * maxf(sprite.speed_scale, 0.001)
	if spd <= 0.0:
		return 0.25
	return total / spd


func _on_explosion_finished():
	queue_free()


func _get_weapon_hit_point() -> Vector2:
	var col := get_node_or_null("CollisionShape2D")
	if col is CollisionShape2D:
		return col.global_position
	return global_position


func _spawn_spread() -> void:
	var base_dir := direction.normalized()
	var half_spread := deg_to_rad(spread_angle) / 2.0
	var is_even := pellet_count % 2 == 0

	var step: float
	var start_angle: float
	var center: int

	if is_even:
		# Чётное число — симметрично вокруг центра, без выстрела в центр
		step = deg_to_rad(spread_angle) / float(pellet_count)
		start_angle = -half_spread + step / 2.0
		center = -1
	else:
		# Нечётное число — одна дробинка в центре (текущий снаряд)
		center = pellet_count / 2
		step = deg_to_rad(spread_angle) / float(pellet_count - 1)
		start_angle = -half_spread

	for i in range(pellet_count):
		var angle := start_angle + step * i
		if not is_even and i == center:
			continue
		if is_even and i == 0:
			direction = base_dir.rotated(angle)
			rotation = direction.angle()
			_align_crit_to_world()
			_align_shadow_to_world()
			continue

		var bullet: BaseShot = duplicate()
		bullet.direction = base_dir.rotated(angle)
		bullet.rotation = bullet.direction.angle()
		# Чтобы дробинки не создавали новые дробинки
		bullet.spawned_spread = true

		# Копируем ВСЕ параметры
		bullet.damage = damage
		bullet.speed = speed
		bullet.atk_range = atk_range
		bullet.extra_reload = extra_reload
		bullet.self_damage_multiplier = self_damage_multiplier
		bullet.self_speed_multiplier = self_speed_multiplier
		bullet.self_range_multiplier = self_range_multiplier
		bullet.boomerang_power = boomerang_power
		bullet.boomerang_first_leg_mult = boomerang_first_leg_mult
		bullet.hack = hack
		bullet.ricochet = ricochet
		bullet.enchantment = enchantment
		bullet.extra_enchantment = extra_enchantment
		bullet.penetration = penetration
		bullet.aoe_radius = aoe_radius
		bullet.use_spread = use_spread
		bullet.pellet_count = pellet_count
		bullet.spread_angle = spread_angle
		bullet._ricochet_ignore_ids = _ricochet_ignore_ids.duplicate()

		bullet.base_crit_bonus = self.base_crit_bonus
		bullet.crit_spread_offset = self.crit_spread_offset
		bullet.critical_flower_power = critical_flower_power
		bullet.sine_amplitude = sine_amplitude
		bullet.sine_frequency = sine_frequency
		bullet.sine_use_cos = (randi() % 2 == 0) if sine_amplitude > 0.0 else sine_use_cos
		bullet.steal_life = steal_life
		bullet._spread_shot_done = _spread_shot_done
		bullet.star_fruit_stacks_to_apply = star_fruit_stacks_to_apply

		get_parent().add_child.call_deferred(bullet)
		bullet.global_position = global_position
		bullet.call_deferred("_align_shadow_to_world")


func _try_spread_shot_split() -> void:
	if _spread_shot_done or exploded:
		return
	if not GameState.SpreadShot:
		return
	if distance_travelled < SPREAD_SHOT_DISTANCE:
		return
	_spread_shot_done = true
	_spawn_spread_shot()


func _try_spread_shot_melee() -> void:
	if _spread_shot_done or exploded:
		return
	if not GameState.SpreadShot:
		return
	if not _uses_melee_ricochet():
		return
	if self is SwordShot and (self as SwordShot)._melee_boomerang_copy:
		return
	_spread_shot_done = true
	_spawn_spread_shot_melee()
	queue_free()


func _spread_shot_melee_origin() -> Vector2:
	var shooter := _get_player()
	if shooter:
		return shooter.global_position
	return global_position


func _spread_shot_cone_dirs() -> Array[Vector2]:
	var base_dir := direction.normalized()
	if base_dir == Vector2.ZERO:
		base_dir = Vector2.RIGHT
	var half_spread := deg_to_rad(SPREAD_SHOT_CONE_DEG) / 2.0
	var step := deg_to_rad(SPREAD_SHOT_CONE_DEG) / float(SPREAD_SHOT_COUNT)
	var start_angle := -half_spread + step / 2.0
	var dirs: Array[Vector2] = []
	for i in range(SPREAD_SHOT_COUNT):
		dirs.append(base_dir.rotated(start_angle + step * i))
	return dirs


func _spawn_spread_shot() -> void:
	scale *= SPREAD_SHOT_SCALE
	self_damage_multiplier *= SPREAD_SHOT_DAMAGE

	var parent := get_parent()
	if parent == null:
		return
	var dirs := _spread_shot_cone_dirs()
	for i in range(dirs.size()):
		if i == 0:
			direction = dirs[i]
			_sync_facing_after_redirect()
			continue
		_spawn_spread_shot_clone(parent, dirs[i])


func _spawn_spread_shot_melee() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var origin := _spread_shot_melee_origin()
	for dir in _spread_shot_cone_dirs():
		_spawn_spread_shot_melee_clone(parent, dir, origin)


func _spawn_spread_shot_melee_clone(parent: Node, dir: Vector2, origin: Vector2) -> void:
	var copy: BaseShot = duplicate()
	copy.spawned_spread = true
	copy._spread_shot_done = true
	copy.pellet_count = 1
	copy.direction = dir
	if copy is SwordShot:
		var melee := copy as SwordShot
		# Не давать клонам снова вызвать SpreadShot, но сохранить бумеранг.
		melee._melee_boomerang_copy = true
		melee._fire_direction = dir
		melee._melee_boomerang_leg_index = 0
		if boomerang_power > 0:
			melee._melee_boomerang_legs = BoomerangPath.build_legs(boomerang_power)
		else:
			melee._melee_boomerang_legs = []
	parent.add_child(copy)
	copy.global_position = origin + dir * SPREAD_SHOT_DISTANCE
	copy.direction = dir
	copy.scale = scale * SPREAD_SHOT_MELEE_SCALE
	copy.damage = damage
	copy.atk_range = atk_range
	copy.extra_reload = extra_reload
	copy.self_damage_multiplier = self_damage_multiplier * SPREAD_SHOT_DAMAGE
	copy.self_speed_multiplier = self_speed_multiplier
	copy.self_range_multiplier = self_range_multiplier
	copy.boomerang_power = boomerang_power
	copy.boomerang_first_leg_mult = boomerang_first_leg_mult
	copy.hack = hack
	copy.ricochet = ricochet
	copy.enchantment = enchantment
	copy.extra_enchantment = extra_enchantment
	copy.penetration = penetration
	copy.aoe_radius = aoe_radius
	copy.spread_angle = spread_angle
	copy._enemy_hit_count = 0
	copy._ricochet_ignore_ids = _ricochet_ignore_ids.duplicate()
	copy.base_crit_bonus = base_crit_bonus
	copy.crit_spread_offset = crit_spread_offset
	copy.critical_flower_power = critical_flower_power
	copy.sine_amplitude = sine_amplitude
	copy.sine_frequency = sine_frequency
	copy.sine_use_cos = sine_use_cos
	copy.steal_life = steal_life
	copy.star_fruit_stacks_to_apply = star_fruit_stacks_to_apply
	copy.rotation = dir.angle()
	copy._align_shadow_to_world()


func _spawn_spread_shot_clone(parent: Node, dir: Vector2) -> void:
	var bullet: BaseShot = duplicate()
	bullet.spawned_spread = true
	bullet._spread_shot_done = true
	bullet.pellet_count = 1
	# Статы ДО add_child: иначе _ready оружия (Fairy Tales и т.п.) видит нули.
	bullet.direction = dir
	bullet.scale = scale
	bullet.damage = damage
	bullet.speed = speed
	bullet.atk_range = atk_range
	bullet.extra_reload = extra_reload
	bullet.self_damage_multiplier = self_damage_multiplier
	bullet.self_speed_multiplier = self_speed_multiplier
	bullet.self_range_multiplier = self_range_multiplier
	bullet.boomerang_power = boomerang_power
	bullet.boomerang_first_leg_mult = boomerang_first_leg_mult
	bullet.hack = hack
	bullet.ricochet = ricochet
	bullet.enchantment = enchantment
	bullet.extra_enchantment = extra_enchantment
	bullet.penetration = penetration
	bullet.aoe_radius = aoe_radius
	bullet.use_spread = use_spread
	bullet.spread_angle = spread_angle
	bullet.distance_travelled = distance_travelled
	bullet._enemy_hit_count = 0
	bullet._ricochet_ignore_ids = _ricochet_ignore_ids.duplicate()
	bullet.base_crit_bonus = base_crit_bonus
	bullet.crit_spread_offset = crit_spread_offset
	bullet.critical_flower_power = critical_flower_power
	bullet.sine_amplitude = sine_amplitude
	bullet.sine_frequency = sine_frequency
	bullet.sine_use_cos = (randi() % 2 == 0) if sine_amplitude > 0.0 else sine_use_cos
	bullet.steal_life = steal_life
	bullet.star_fruit_stacks_to_apply = 0
	bullet._star_fruit_applied = true
	parent.add_child(bullet)
	bullet.global_position = global_position
	# _ready клона мог заново стартовать бумеранг — берём прогресс оригинала на момент сплита.
	if _boomerang_active:
		bullet._copy_boomerang_flight_state(self)
	elif bullet.boomerang_power > 0:
		bullet._boomerang_active = false
	# После _ready снова синхронизируем множители (оружие могло сбросить их в _ready).
	bullet.self_damage_multiplier = self_damage_multiplier
	bullet.self_speed_multiplier = self_speed_multiplier
	bullet.self_range_multiplier = self_range_multiplier
	bullet.extra_reload = extra_reload
	bullet.speed = speed
	bullet.damage = damage
	bullet.atk_range = atk_range
	if bullet.boomerang_power > 0 and _boomerang_active:
		bullet._copy_boomerang_flight_state(self)
	elif bullet.boomerang_power > 0:
		bullet._init_boomerang()
	bullet._sync_facing_after_redirect()
