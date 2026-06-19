extends Control


const GAME_SCENE := "res://scenes/Game.tscn"

@onready var new_game_button: Button = $Center/Panel/VBox/NewGameButton
@onready var quit_button: Button = $Center/Panel/VBox/QuitButton


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	new_game_button.pressed.connect(_on_new_game_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_new_game_pressed() -> void:
	print("Novo Jogo selecionado.")
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_quit_pressed() -> void:
	print("Saindo do jogo.")
	get_tree().quit()
