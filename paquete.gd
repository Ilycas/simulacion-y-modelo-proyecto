extends Node3D

var destino : Vector3
var estudiante_ref : Node3D
var activo : bool = false

func disparar(destino_pos: Vector3, estudiante: Node3D) -> void:
	destino = destino_pos
	estudiante_ref = estudiante
	activo = true

func _process(delta: float) -> void:
	if not activo: return

	# --- 1. VALIDACIÓN DE CONEXIÓN EN TIEMPO REAL ---
	if is_instance_valid(estudiante_ref):
		if estudiante_ref.router_conectado == null:
			queue_free()
			return
	else:
		queue_free()
		return

	# --- 2. MOVIMIENTO HACIA EL DESTINO (velocidad dinámica) ---
	var velocidad_dinamica = estudiante_ref.velocidad_paquete_actual if estudiante_ref.velocidad_paquete_actual > 0 else 15.0
	var direction = global_position.direction_to(destino)
	global_position += direction * velocidad_dinamica * delta

	# --- 3. RECEPCIÓN EXITOSA ---
	if global_position.distance_to(destino) < 0.2:
		queue_free()
