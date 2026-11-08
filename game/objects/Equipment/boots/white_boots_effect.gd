extends Node

const IDLE_BEFORE_BOOST := 3.0
const SPEED_MULT := 1.25

var _time_since_shot := 999.0
var _boosted := false


func _ready() -> void:
	_time_since_shot = IDLE_BEFORE_BOOST
	_sync_boost()


func _process(delta: float) -> void:
	_time_since_shot += delta
	_sync_boost()


func on_shot() -> void:
	_time_since_shot = 0.0
	_sync_boost()


func _sync_boost() -> void:
	var player := get_parent()
	if player == null:
		return
	var want := _time_since_shot >= IDLE_BEFORE_BOOST
	if want == _boosted:
		return
	_boosted = want
	player.EquipMoveSpeedMult = SPEED_MULT if want else 1.0
	player.move_speed = StatManager.get_stat(player, "move_speed")
	if player.has_method("_emit_stats_changed"):
		player._emit_stats_changed()


func _exit_tree() -> void:
	var player := get_parent()
	if player == null:
		return
	if _boosted:
		player.EquipMoveSpeedMult = 1.0
		player.move_speed = StatManager.get_stat(player, "move_speed")
		if player.has_method("_emit_stats_changed"):
			player._emit_stats_changed()
