extends Node3D

@export var antena_principal : Node3D
@export var porcentaje_asignacion : float = 0.5 

var ancho_banda_central : float = 0.0

func _process(_delta: float) -> void:
	if is_instance_valid(antena_principal):
		ancho_banda_central = antena_principal.ancho_banda_entrada * porcentaje_asignacion
	else:
		ancho_banda_central = 0.0

func obtener_ancho_banda_modem() -> float:
	return ancho_banda_central
