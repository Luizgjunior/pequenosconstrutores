extends Node


var selected_character_id := "explorer"


func select_character(character_id: String) -> void:
	selected_character_id = character_id
	print("Personagem selecionado: ", character_id)
