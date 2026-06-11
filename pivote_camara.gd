extends Node3D

@export var velocidad_paneo : float = 0.2

func _process(delta: float) -> void:
	rotation.y += velocidad_paneo * delta
