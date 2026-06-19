extends Control


const CHARACTER_SELECT_SCENE_PATH := "res://scenes/ui/CharacterSelect.tscn"

@onready var new_game_button: Button = %NewGameButton
@onready var continue_button: Button = %ContinueButton
@onready var free_build_button: Button = %FreeBuildButton
@onready var settings_button: Button = %SettingsButton
@onready var exit_button: Button = %ExitButton


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	free_build_button.pressed.connect(_on_free_build_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	exit_button.pressed.connect(_on_exit_pressed)


func _on_new_game_pressed() -> void:
	print("Novo Jogo selecionado. Abrindo escolha de personagem...")
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE_PATH)


func _on_continue_pressed() -> void:
	print("Continuar selecionado. Salvamento local ainda será implementado.")


func _on_free_build_pressed() -> void:
	print("Modo Construção Livre selecionado. Modo ainda será implementado.")


func _on_settings_pressed() -> void:
	print("Configurações selecionadas. Tela ainda será implementada.")


func _on_exit_pressed() -> void:
	print("Sair selecionado. Encerrando o jogo quando permitido pela plataforma.")
	get_tree().quit()
