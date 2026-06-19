extends Control


const GAME_SCENE_PATH := "res://scenes/Game.tscn"

const CHARACTERS := [
	{"id": "explorer", "name": "Explorador", "color": Color(0.12, 0.45, 0.32, 1)},
	{"id": "princess", "name": "Princesa", "color": Color(0.95, 0.45, 0.75, 1)},
	{"id": "helmet", "name": "Capacete", "color": Color(0.95, 0.65, 0.18, 1)},
	{"id": "blue", "name": "Aventureira Azul", "color": Color(0.20, 0.58, 0.85, 1)},
	{"id": "red", "name": "Corajoso Vermelho", "color": Color(0.88, 0.23, 0.18, 1)},
	{"id": "pink", "name": "Heroína Rosa", "color": Color(0.95, 0.35, 0.82, 1)},
	{"id": "black", "name": "Vigia", "color": Color(0.08, 0.08, 0.09, 1)},
	{"id": "green", "name": "Construtor Verde", "color": Color(0.25, 0.78, 0.36, 1)},
	{"id": "builder", "name": "Construtor", "color": Color(0.18, 0.55, 0.82, 1)}
]

@onready var grid: GridContainer = %CharacterGrid
@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_create_character_buttons()


func _create_character_buttons() -> void:
	for character in CHARACTERS:
		var button := Button.new()
		button.custom_minimum_size = Vector2(180, 92)
		button.text = "%s\n" % character.name
		button.tooltip_text = "Escolher %s" % character.name
		button.pressed.connect(_on_character_pressed.bind(character.id))
		grid.add_child(button)

		var swatch := ColorRect.new()
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		swatch.color = character.color
		swatch.custom_minimum_size = Vector2(0, 16)
		button.add_child(swatch)
		swatch.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		swatch.offset_left = 18
		swatch.offset_right = -18
		swatch.offset_top = -24
		swatch.offset_bottom = -8


func _on_character_pressed(character_id: String) -> void:
	GameState.select_character(character_id)
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
