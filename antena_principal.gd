extends MeshInstance3D

@export var ancho_banda : float = 500.0

var ancho_banda_entrada : float = 500.0

func _ready() -> void:
	ancho_banda_entrada = ancho_banda

func obtener_ancho_banda_global() -> float:
	return ancho_banda_entrada
