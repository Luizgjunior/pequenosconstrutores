extends Node


var selected_character_id := "boy_builder"


func select_character(character_id: String) -> void:
	selected_character_id = character_id
	print("Personagem selecionado: ", character_id)
