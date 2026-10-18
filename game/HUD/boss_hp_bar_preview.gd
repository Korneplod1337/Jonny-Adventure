@tool
extends Control

## Превью общего HP-бара. Shared Style = boss_hp_bar_template.tres

const SHARED_STYLE_PATH := "res://game/HUD/styles/boss_hp_bar_template.tres"

@export var shared_style: BossHpBarStyle:
	set(value):
		shared_style = value
		_apply()

@onready var _bar: BossHpBar = $Panel/VBox/BossHpBar
@onready var _slider: HSlider = $Panel/VBox/SliderRow/HpSlider
@onready var _label: Label = $Panel/VBox/SliderRow/HpLabel


func _ready() -> void:
	if shared_style == null:
		shared_style = load(SHARED_STYLE_PATH) as BossHpBarStyle
	if _slider and not _slider.value_changed.is_connected(_on_slider_changed):
		_slider.value_changed.connect(_on_slider_changed)
	_apply()
	call_deferred("_apply")


func _apply() -> void:
	if _bar == null:
		_bar = get_node_or_null("Panel/VBox/BossHpBar") as BossHpBar
	if _bar == null:
		return
	if shared_style == null:
		shared_style = load(SHARED_STYLE_PATH) as BossHpBarStyle
	_bar.style = shared_style
	_bar.custom_minimum_size = Vector2(520, 28)
	_bar.size = Vector2(520, 28)
	if _slider:
		_bar.preview_ratio = clampf(_slider.value / 100.0, 0.0, 1.0)
	_bar.queue_redraw()


func _on_slider_changed(value: float) -> void:
	var ratio := clampf(value / 100.0, 0.0, 1.0)
	if _bar:
		_bar.preview_ratio = ratio
	if _label:
		_label.text = "%d%%" % int(round(ratio * 100.0))
