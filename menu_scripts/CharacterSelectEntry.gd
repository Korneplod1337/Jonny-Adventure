class_name CharacterSelectEntry
extends Resource

## ID для DungeonManager.selected_character (например "Jonny").
@export var id: String = ""
## Текст имени, если name_texture не задан.
@export var display_name: String = ""
## Портрет в боковых слотах и у заблокированных.
@export var portrait: Texture2D
## Портрет выбранного персонажа в центре.
@export var portrait_selected: Texture2D
## Своя иконка замка; если пусто — берётся lock_portrait из меню.
@export var portrait_locked: Texture2D
## Картинка имени вместо Label (char_select_name_*.png).
@export var name_texture: Texture2D
## Можно ли выбрать персонажа и начать игру.
@export var unlocked: bool = true
