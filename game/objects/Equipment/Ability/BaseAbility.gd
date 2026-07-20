class_name BaseAbility
extends Node

enum CooldownType { TIME, KILLS }

var ability_id: String = ""
var cooldown_type: CooldownType = CooldownType.TIME
var cooldown_time: float = 5.0
var cooldown_kills: int = 5

var player: Node = null

var _on_cooldown: bool = false
var _cd_time_left: float = 0.0
var _cd_kills_left: int = 0


func setup(p: Node) -> void:
	player = p
	if not StatsManager.stat_changed.is_connected(_on_stat_changed):
		StatsManager.stat_changed.connect(_on_stat_changed)
	_update_hud_cooldown()


func _exit_tree() -> void:
	if StatsManager.stat_changed.is_connected(_on_stat_changed):
		StatsManager.stat_changed.disconnect(_on_stat_changed)


func get_magic() -> float:
	if player == null:
		return 0.0
	return StatManager.get_stat(player, "magic")


func can_activate() -> bool:
	if player == null:
		return false
	if player.movement_locked:
		return false
	if _on_cooldown:
		return false
	return true


func try_activate() -> bool:
	if not can_activate():
		return false
	if not activate():
		return false
	start_cooldown()
	return true


## Override in child abilities. Return true if cast succeeded.
func activate() -> bool:
	return false


## Override to drive player movement (e.g. dash). Return true while controlling movement.
func process_movement(_delta: float) -> bool:
	return false


func start_cooldown() -> void:
	_on_cooldown = true
	match cooldown_type:
		CooldownType.TIME:
			_cd_time_left = cooldown_time
		CooldownType.KILLS:
			_cd_kills_left = cooldown_kills
	_update_hud_cooldown()


func get_cooldown_state() -> Dictionary:
	return {
		"on_cooldown": _on_cooldown,
		"cooldown_type": cooldown_type,
		"time_left": _cd_time_left,
		"kills_left": _cd_kills_left,
		"cooldown_time": cooldown_time,
		"cooldown_kills": cooldown_kills,
	}


func apply_cooldown_state(state: Dictionary) -> void:
	if state.is_empty():
		_on_cooldown = false
		_cd_time_left = 0.0
		_cd_kills_left = 0
		_update_hud_cooldown()
		return
	_on_cooldown = bool(state.get("on_cooldown", false))
	_cd_time_left = float(state.get("time_left", 0.0))
	_cd_kills_left = int(state.get("kills_left", 0))
	if not _on_cooldown:
		_cd_time_left = 0.0
		_cd_kills_left = 0
		_update_hud_cooldown()
	elif cooldown_type == CooldownType.TIME and _cd_time_left <= 0.0:
		_finish_cooldown()
	elif cooldown_type == CooldownType.KILLS and _cd_kills_left <= 0:
		_finish_cooldown()
	else:
		_update_hud_cooldown()


## 1.0 = just entered cooldown (fully locked), 0.0 = ready.
func get_cooldown_ratio() -> float:
	if not _on_cooldown:
		return 0.0
	match cooldown_type:
		CooldownType.TIME:
			if cooldown_time <= 0.0:
				return 0.0
			return clampf(_cd_time_left / cooldown_time, 0.0, 1.0)
		CooldownType.KILLS:
			if cooldown_kills <= 0:
				return 0.0
			return clampf(float(_cd_kills_left) / float(cooldown_kills), 0.0, 1.0)
	return 0.0


func _process(delta: float) -> void:
	if not _is_equipped():
		return
	if not _on_cooldown or cooldown_type != CooldownType.TIME:
		return
	_cd_time_left -= delta
	if _cd_time_left <= 0.0:
		_finish_cooldown()
	else:
		_update_hud_cooldown()


func notify_enemy_killed() -> void:
	if not _is_equipped():
		return
	if not _on_cooldown or cooldown_type != CooldownType.KILLS:
		return
	_cd_kills_left -= 1
	if _cd_kills_left <= 0:
		_finish_cooldown()
	else:
		_update_hud_cooldown()


func _on_stat_changed(stat_name: String, _new_value: float) -> void:
	if stat_name == "kills":
		notify_enemy_killed()


func _finish_cooldown() -> void:
	_on_cooldown = false
	_cd_time_left = 0.0
	_cd_kills_left = 0
	_update_hud_cooldown()


func _is_equipped() -> bool:
	return player != null and is_instance_valid(player) and player.current_ability == self


func _update_hud_cooldown() -> void:
	if not _is_equipped() or not player.is_inside_tree():
		return
	var hud = player.get_tree().get_first_node_in_group("HUD")
	if hud == null or hud.AbilitySlot == null:
		return
	hud.AbilitySlot.set_cooldown_progress(get_cooldown_ratio())
