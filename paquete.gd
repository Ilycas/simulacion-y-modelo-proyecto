extends Node3D

var destino: Vector3
var velocidad: float = 0.0
var activo: bool = false

# Esta función la llamará el estudiante al crearlo
func disparar(target_pos: Vector3, vel: float) -> void:
	destino = target_pos
	velocidad = vel
	activo = true

func _process(delta: float) -> void:
	if activo:
		# Moverse hacia el router
		global_position = global_position.move_toward(destino, velocidad * delta)
		
		# Si llega al destino, se elimina de la simulación
		if global_position.distance_to(destino) < 0.2:
			print("-> [ACK] ¡Paquete recibido en destino!")
			queue_free() # Destruye este clon del paquete
