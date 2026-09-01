extends "res://game/presets/RoomScript.gd"

const MAX_DEPOSITS := 10
const ALT_CHANCE := 0.1
const ALT2_CHANCE := 0.1

@onready var interactable_give: Area2D = $Interactable_give
@onready var interactable_spend: Area2D = $Interactable_spend
@onready var animated_ez: AnimatedSprite2D = $AnimatedEZ
@onready var animated_table: AnimatedSprite2D = $AnimatedTable
@onready var coin_counter_label: Label = $"coin counter/coin counter label"

var deposits: int = 0


func _ready() -> void:
	interactable_give.interact = _on_give
	interactable_give.interact_name = "Take 1 coin"
	interactable_spend.interact = _on_spend
	interactable_spend.interact_name = "Deposit 1 coin"

	_update_coin_label()
	_sync_table_frame()
	_update_spend_state()

	animated_ez.animation_finished.connect(_on_ez_animation_finished)
	animated_ez.play(&"default")
	GameState.bank_coins_changed.connect(_on_bank_coins_changed)

	call_deferred("init_room")


func bounds_body_entered(_body: Node2D) -> void:
	pass


func _on_bank_coins_changed(_new_value: int) -> void:
	_update_coin_label()


func _update_coin_label() -> void:
	coin_counter_label.text = str(GameState.bank_coins)


func _sync_table_frame() -> void:
	animated_table.frame = clampi(deposits, 0, MAX_DEPOSITS)


func _update_spend_state() -> void:
	interactable_spend.is_interactable = deposits < MAX_DEPOSITS


func _on_give() -> void:
	if GameState.bank_coins < 1:
		return
	if not GameState.withdraw_bank_coins(1):
		return
	GameState.add_coins(1)
	SoundManager.play_coins(1)
	_update_coin_label()


func _on_spend() -> void:
	if deposits >= MAX_DEPOSITS:
		return
	if GameState.coins < 1:
		return
	if not interactable_spend.is_interactable:
		return

	GameState.add_coins(-1)
	GameState.add_bank_coins(1)
	deposits += 1

	animated_table.frame = deposits
	SoundManager.play_coins(1)
	_update_coin_label()
	_update_spend_state()


func _on_ez_animation_finished() -> void:
	var anim := animated_ez.animation
	if anim == &"alt" or anim == &"alt2":
		_play_ez_default()
		return
	_roll_ez_next_animation()


func _roll_ez_next_animation() -> void:
	var roll := randf()
	if roll < ALT_CHANCE:
		animated_ez.play(&"alt")
	elif roll < ALT_CHANCE + ALT2_CHANCE:
		animated_ez.play(&"alt2")
	else:
		_play_ez_default()


func _play_ez_default() -> void:
	animated_ez.play(&"default")
