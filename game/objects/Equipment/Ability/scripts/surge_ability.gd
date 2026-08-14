## Surge — на 3 с добавляет +300 к плоской скорости (EquipMoveSpeedFlat). CD: 3 с.
class_name SurgeAbility
extends BaseAbility

const BOOST := 300.0
const DURATION := 3.0

var _surge_left: float = 0.0
var _boost_applied: bool = false


func _init() -> void:
	ability_id = "Surge"
	cooldown_type = CooldownType.TIME
	cooldown_time = 3.0


func activate() -> bool:
	if not _boost_applied:
		player.EquipMoveSpeedFlat += BOOST
		player.move_speed = StatManager.get_stat(player, "move_speed")
		_boost_applied = true
	_surge_left = DURATION
	return true


func _process(delta: float) -> void:
	super._process(delta)
	if _surge_left <= 0.0:
		return
	_surge_left -= delta
	if _surge_left <= 0.0:
		_end_surge()


func _end_surge() -> void:
	_surge_left = 0.0
	if not _boost_applied or player == null or not is_instance_valid(player):
		_boost_applied = false
		return
	player.EquipMoveSpeedFlat -= BOOST
	player.move_speed = StatManager.get_stat(player, "move_speed")
	_boost_applied = false


func _exit_tree() -> void:
	if _boost_applied:
		_end_surge()
	super._exit_tree()
