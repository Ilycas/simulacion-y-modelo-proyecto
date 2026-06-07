extends Node3D

@export var antena_principal : Node3D

var ancho_banda_central : float = 300.0

func _process(_delta: float) -> void:
	if is_instance_valid(antena_principal):
		ancho_banda_central = antena_principal.ancho_banda_entrada
	else:
		ancho_banda_central = 0.0

func obtener_ancho_banda_modem() -> float:
	return ancho_banda_central
