extends Node3D


func _ready() -> void:
	_setup_environment()
	print("Mundo simples carregado.")


func _setup_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.67, 0.82, 0.95, 1)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.9, 0.82, 0.68, 1)
	environment.ambient_light_energy = 0.9

	var world_environment := $Environment/WorldEnvironment as WorldEnvironment
	world_environment.environment = environment
