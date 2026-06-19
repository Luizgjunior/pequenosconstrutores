extends Control


const GAME_SCENE_PATH := "res://scenes/Game.tscn"

const CHARACTERS := [
	{
		"id": "boy_builder",
		"name": "Menino Construtor",
		"color": Color(0.23, 0.39, 0.50, 1)
	},
	{
		"id": "girl_builder",
		"name": "Menina Construtora",
		"color": Color(0.30, 0.46, 0.56, 1)
	}
]

@onready var grid: GridContainer = %CharacterGrid
@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	_create_character_buttons()


func _create_character_buttons() -> void:
	for character in CHARACTERS:
		var button := Button.new()
		button.custom_minimum_size = Vector2(260, 124)
		button.text = "%s\nConstrução e exploração" % character.name
		button.tooltip_text = "Escolher %s" % character.name
		button.pressed.connect(_on_character_pressed.bind(character.id))
		grid.add_child(button)

		var swatch := ColorRect.new()
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		swatch.color = character.color
		swatch.custom_minimum_size = Vector2(0, 22)
		button.add_child(swatch)
		swatch.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		swatch.offset_left = 24
		swatch.offset_right = -24
		swatch.offset_top = -34
		swatch.offset_bottom = -12


func _on_character_pressed(character_id: String) -> void:
	GameState.select_character(character_id)
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
