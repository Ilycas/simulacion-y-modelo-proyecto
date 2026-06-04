extends Node3D

var destino: Vector3
var estudiante_ref : Node3D # Guardamos la conexión con el estudiante
var activo: bool = false

# Ahora recibimos la referencia directa del estudiante
func disparar(target_pos: Vector3, estudiante: Node3D) -> void:
	destino = target_pos
	estudiante_ref = estudiante
	activo = true

func _process(delta: float) -> void:
	if activo:
		# Velocidad por defecto en caso de error
		var velocidad_dinamica = 15.0 
		
		# Si el estudiante sigue existiendo en el mapa, le leemos su velocidad actual
		if is_instance_valid(estudiante_ref):
			velocidad_dinamica = estudiante_ref.velocidad_paquete_actual
		
		# Moverse usando la velocidad que tiene el estudiante EN ESTE FRAME EXACTO
		global_position = global_position.move_toward(destino, velocidad_dinamica * delta)
		
		# Si llega al destino, se elimina
		if global_position.distance_to(destino) < 0.2:
			queue_free()
