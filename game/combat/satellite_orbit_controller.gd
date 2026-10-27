extends Node
class_name SatelliteOrbitController

const BASE_SLOTS := 2
const ORBIT_RADIUS := 150.0
const REDISTRIBUTE_TIME := 2.0
## |Δскорости| при догоне/перераспределении ≤ этой доли базовой.
const SPEED_CORR_FRAC := 0.75
## Math Circle на орбите: "radial" = дыхание радиуса; "angular" = старый wobble по дуге.
const MATH_CIRCLE_ORBIT_MODE := "angular"
## amp 0.5 → ±~34 px при R=150; радиус клампится, чтобы не залезать в игрока.
const MATH_CIRCLE_RADIAL_SCALE := 0.45

## Якоря-крепления: угол крутится сам; shot — занявший снаряд или null.
var _anchors: Array = []
## Свободный полёт до захвата (слот ещё не занят).
var _pending: Array = []


func get_max_slots() -> int:
	return maxi(BASE_SLOTS + GameState.satellite_bonus_slots, 1)


func get_radius() -> float:
	return ORBIT_RADIUS


func get_half_radius() -> float:
	return ORBIT_RADIUS * 0.5


func get_orbit_speed() -> float:
	var p := _player()
	if p == null:
		return 48.0
	return maxf(float(p.atk_range) * 0.5, 32.0)


func get_anchor_world_pos(slot_idx: int) -> Vector2:
	var p := _player()
	var center = p.global_position if p else Vector2.ZERO
	if slot_idx < 0 or slot_idx >= _anchors.size():
		return center + Vector2.RIGHT * ORBIT_RADIUS
	var a: Dictionary = _anchors[slot_idx]
	var ang: float = float(a.get("angle", 0.0))
	var r := ORBIT_RADIUS
	# Math Circle — на креплении: радиус (новый) или угол (старый).
	if MATH_CIRCLE_ORBIT_MODE == "angular":
		ang += _anchor_sine_offset(a)
	else:
		r = _anchor_sine_radius(a)
	return center + Vector2.RIGHT.rotated(ang) * r


func get_anchor_angle(slot_idx: int) -> float:
	if slot_idx < 0 or slot_idx >= _anchors.size():
		return 0.0
	var a: Dictionary = _anchors[slot_idx]
	var ang: float = float(a.get("angle", 0.0))
	# В radial-режиме угол чистый — тангент/facing не дёргаются.
	if MATH_CIRCLE_ORBIT_MODE == "angular":
		ang += _anchor_sine_offset(a)
	return ang


func get_anchor_sign(slot_idx: int) -> float:
	if slot_idx < 0 or slot_idx >= _anchors.size():
		return 1.0
	return float(_anchors[slot_idx].get("sign", 1.0))


func get_anchor_omega_scale(slot_idx: int) -> float:
	## Бумеранг: кривая скорости (может быть ~0 на развороте).
	if slot_idx < 0 or slot_idx >= _anchors.size():
		return 1.0
	var shot = _anchors[slot_idx].get("shot")
	if shot != null and is_instance_valid(shot) and shot.has_method("get_satellite_boomerang_speed_mult"):
		return float(shot.get_satellite_boomerang_speed_mult())
	return 1.0


func flip_anchor_sign_for_shot(shot: Node) -> void:
	for a in _anchors:
		if a.get("shot") == shot:
			a["sign"] = -float(a.get("sign", 1.0))
			return


func _anchor_sine_wave(a: Dictionary) -> float:
	## sin/cos ∈ [-1, 1] × amp; 0 если нет Math Circle.
	var shot = a.get("shot")
	if shot == null or not is_instance_valid(shot):
		return 0.0
	var amp := float(shot.get("sine_amplitude"))
	if amp <= 0.0:
		return 0.0
	var path := float(a.get("sine_path", 0.0))
	var freq := float(shot.get("sine_frequency"))
	if freq <= 0.0:
		freq = 0.025
	var t := path * freq
	var wave := cos(t + PI * 0.5) if bool(shot.get("sine_use_cos")) else sin(t)
	return wave * amp


func _anchor_sine_offset(a: Dictionary) -> float:
	## Старый режим: угловой offset (рад).
	return _anchor_sine_wave(a)


func _anchor_sine_radius(a: Dictionary) -> float:
	## Новый режим: R ± wave·scale, без ухода в игрока.
	var wave := _anchor_sine_wave(a)
	if wave == 0.0:
		return ORBIT_RADIUS
	var r := ORBIT_RADIUS + wave * ORBIT_RADIUS * MATH_CIRCLE_RADIAL_SCALE
	return clampf(r, ORBIT_RADIUS * 0.4, ORBIT_RADIUS * 1.6)


func _player() -> Node:
	return get_parent()


func _physics_process(delta: float) -> void:
	_ensure_anchor_count()
	_purge_invalid()
	var radius := ORBIT_RADIUS
	var orbit_spd := get_orbit_speed()
	var base_omega := orbit_spd / maxf(radius, 1.0)
	var max_corr := absf(base_omega) * SPEED_CORR_FRAC

	for i in _anchors.size():
		var a: Dictionary = _anchors[i]
		var sgn := float(a.get("sign", 1.0))
		var boom_mult := get_anchor_omega_scale(i)
		var omega := base_omega * sgn * boom_mult
		var corr := 0.0
		var left: float = float(a.get("redistrib_left", 0.0))
		if left > 0.0:
			var ang: float = float(a.get("angle", 0.0))
			var tgt: float = float(a.get("target_angle", ang))
			tgt += omega * delta
			var gap := angle_difference(ang, tgt)
			corr = clampf(gap / left, -max_corr, max_corr)
			a["target_angle"] = tgt
			a["redistrib_left"] = maxf(0.0, left - delta)
		var d_ang := (omega + corr) * delta
		a["angle"] = float(a.get("angle", 0.0)) + d_ang
		# Длина дуги для sine / бумеранга снаряда.
		var arc := absf(d_ang) * radius
		a["sine_path"] = float(a.get("sine_path", 0.0)) + arc
		var shot = a.get("shot")
		if shot != null and is_instance_valid(shot) and shot.has_method("notify_satellite_arc"):
			shot.notify_satellite_arc(arc, delta)


func _ensure_anchor_count() -> void:
	var need := get_max_slots()
	var changed := false
	while _anchors.size() < need:
		var ang := 0.0
		if _anchors.size() > 0:
			ang = float(_anchors[0].get("angle", 0.0))
		_anchors.append({
			"angle": ang,
			"target_angle": ang,
			"redistrib_left": 0.0,
			"sign": 1.0,
			"shot": null,
			"sine_path": 0.0,
		})
		changed = true
	while _anchors.size() > need:
		var last: Dictionary = _anchors.pop_back()
		var s = last.get("shot")
		if s != null and is_instance_valid(s):
			s.force_satellite_expire()
		changed = true
	if changed:
		# Все крепления (и пустые) — равномерно. Иначе Solaris/слоты плывут хаотично.
		_start_redistribute()


func register_shot(shot: Node) -> void:
	if shot == null or not is_instance_valid(shot):
		return
	_ensure_anchor_count()
	_purge_invalid()
	var melee = shot.has_method("_uses_melee_ricochet") and shot._uses_melee_ricochet()
	if melee:
		_assign_and_capture(shot)
	else:
		if not _pending.has(shot):
			_pending.append(shot)
		if shot.has_method("arm_satellite"):
			shot.arm_satellite(self)


func begin_capture(shot: Node) -> void:
	if shot == null or not is_instance_valid(shot):
		return
	_assign_and_capture(shot)


func _assign_and_capture(shot: Node) -> void:
	_ensure_anchor_count()
	_purge_invalid()
	_pending.erase(shot)

	for a in _anchors:
		if a.get("shot") == shot:
			return

	var idx := _find_empty_anchor()
	if idx < 0:
		# Нет пустого — освобождаем самый старый слот под новый.
		idx = _oldest_occupied_index()
		if idx >= 0:
			var old = _anchors[idx].get("shot")
			_anchors[idx]["shot"] = null
			if old != null and is_instance_valid(old):
				old.force_satellite_expire()
		else:
			idx = 0

	var melee = shot.has_method("_uses_melee_ricochet") and shot._uses_melee_ricochet()
	if melee:
		# Ближка садится на уже ровный слот — угол крепления не сбиваем.
		_anchors[idx]["shot"] = shot
		_anchors[idx]["sign"] = 1.0
		_anchors[idx]["sine_path"] = 0.0
	else:
		# Дальний: крепление появляется со стороны выстрела, потом redistribute.
		var entry_ang := float(_anchors[idx].get("angle", 0.0))
		var p := _player()
		if p != null and is_instance_valid(shot) and shot is Node2D:
			var away: Vector2 = (shot as Node2D).global_position - p.global_position
			if away.length_squared() > 0.01:
				entry_ang = away.angle()
		_anchors[idx]["angle"] = entry_ang
		_anchors[idx]["target_angle"] = entry_ang
		_anchors[idx]["redistrib_left"] = 0.0
		_anchors[idx]["sine_path"] = 0.0
		_anchors[idx]["shot"] = shot
		_anchors[idx]["sign"] = 1.0
	if shot.has_method("begin_satellite_capture"):
		shot.begin_satellite_capture(self, idx)
	_start_redistribute()


func on_shot_reached_orbit(_shot: Node) -> void:
	pass


func unregister_shot(shot: Node) -> void:
	_pending.erase(shot)
	for a in _anchors:
		if a.get("shot") == shot:
			a["shot"] = null
			return


func clear_all() -> void:
	for s in _pending.duplicate():
		if s != null and is_instance_valid(s):
			s.force_satellite_expire()
	_pending.clear()
	for a in _anchors:
		var s = a.get("shot")
		if s != null and is_instance_valid(s):
			s.force_satellite_expire()
		a["shot"] = null
	_anchors.clear()


func _start_redistribute() -> void:
	_purge_invalid()
	var n := _anchors.size()
	if n <= 0:
		return
	# Все слоты (занятые и пустые) — равномерно по кругу.
	var order: Array = []
	for i in n:
		order.append(i)
	order.sort_custom(func(ia, ib): return float(_anchors[ia]["angle"]) < float(_anchors[ib]["angle"]))
	var sum_adj := 0.0
	for k in n:
		var ang: float = float(_anchors[order[k]]["angle"])
		sum_adj += ang - TAU * float(k) / float(n)
	var base := sum_adj / float(n)
	for k in n:
		var i: int = order[k]
		_anchors[i]["target_angle"] = base + TAU * float(k) / float(n)
		_anchors[i]["redistrib_left"] = REDISTRIBUTE_TIME


## Мгновенно выровнять все крепления (для Solaris / смены числа слотов).
func snap_even_layout() -> void:
	_ensure_anchor_count()
	var n := _anchors.size()
	if n <= 0:
		return
	var base := float(_anchors[0].get("angle", 0.0))
	for i in n:
		var ang := base + TAU * float(i) / float(n)
		_anchors[i]["angle"] = ang
		_anchors[i]["target_angle"] = ang
		_anchors[i]["redistrib_left"] = 0.0
		_anchors[i]["sign"] = 1.0


func _find_empty_anchor() -> int:
	for i in _anchors.size():
		var s = _anchors[i].get("shot")
		if s == null or not is_instance_valid(s):
			_anchors[i]["shot"] = null
			return i
	return -1


func _oldest_occupied_index() -> int:
	var best_i := -1
	var best_order := 9223372036854775807
	for i in _anchors.size():
		var s = _anchors[i].get("shot")
		if s == null or not is_instance_valid(s):
			continue
		var order: int = int(s.get("satellite_spawn_order"))
		if order < best_order:
			best_order = order
			best_i = i
	return best_i


func _purge_invalid() -> void:
	var kept: Array = []
	for s in _pending:
		if s != null and is_instance_valid(s):
			kept.append(s)
	_pending = kept
	for a in _anchors:
		var s = a.get("shot")
		if s != null and not is_instance_valid(s):
			a["shot"] = null


static var _spawn_seq: int = 0

static func next_spawn_order() -> int:
	_spawn_seq += 1
	return _spawn_seq
