@tool
extends Node2D

const TEXTURES: Array[Texture2D] = [
	null,
	preload("res://image/objects/shadow/backlight1.png"),
	preload("res://image/objects/shadow/backlight2.png"),
	preload("res://image/objects/shadow/backlight3.png"),
	preload("res://image/objects/shadow/backlight4.png"),
]

const DURATION_TIER1 := 3.0
const DURATION_DEFAULT := 5.0
const ROTATE_SPEED := 0.7
const PULSE_MIN := 0.9
const PULSE_MAX := 1.1
const PULSE_HALF_PERIOD := 0.9

var _tier := 1
var _triggered := false
var _glowing := false
var _pulse_tween: Tween

@export_range(1, 4) var tier: int:
	get:
		return _tier
	set(value):
		_tier = clampi(value, 1, 4)
		_apply_tier()


func _ready() -> void:
	_apply_tier()
	if Engine.is_editor_hint():
		return
	var sprite := _sprite()
	if sprite:
		sprite.visible = false
	var notifier := _notifier()
	if notifier == null:
		return
	if not notifier.screen_entered.is_connected(_on_screen_entered):
		notifier.screen_entered.connect(_on_screen_entered)
	# Уже в камере при спавне.
	if notifier.is_on_screen():
		_on_screen_entered()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not _glowing:
		return
	rotation += ROTATE_SPEED * delta


func _apply_tier() -> void:
	var sprite := _sprite()
	if sprite == null:
		return
	if _tier >= 1 and _tier < TEXTURES.size() and TEXTURES[_tier] != null:
		sprite.texture = TEXTURES[_tier]


func _on_screen_entered() -> void:
	if _triggered or Engine.is_editor_hint():
		return
	_triggered = true
	_start_glow()


func _start_glow() -> void:
	_glowing = true
	var sprite := _sprite()
	if sprite:
		sprite.visible = true
	_start_pulse()
	var duration := DURATION_TIER1 if _tier == 1 else DURATION_DEFAULT
	var tree := get_tree()
	if tree == null:
		_stop_glow()
		return
	var self_ref: WeakRef = weakref(self)
	tree.create_timer(duration, false, true).timeout.connect(
		func() -> void:
			var node = self_ref.get_ref()
			if node != null:
				node._stop_glow(),
		CONNECT_ONE_SHOT
	)


func _start_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	var base := scale
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(self, "scale", base * PULSE_MAX, PULSE_HALF_PERIOD)
	_pulse_tween.tween_property(self, "scale", base * PULSE_MIN, PULSE_HALF_PERIOD)


func _stop_glow() -> void:
	_glowing = false
	set_process(false)
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
		_pulse_tween = null
	var sprite := _sprite()
	if sprite:
		sprite.visible = false
	var notifier := _notifier()
	if notifier and notifier.screen_entered.is_connected(_on_screen_entered):
		notifier.screen_entered.disconnect(_on_screen_entered)


func _sprite() -> Sprite2D:
	return get_node_or_null("Sprite2D") as Sprite2D


func _notifier() -> VisibleOnScreenNotifier2D:
	return get_node_or_null("VisibleOnScreenNotifier2D") as VisibleOnScreenNotifier2D
