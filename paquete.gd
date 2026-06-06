extends Node3D

var destino_final : Vector3
var estudiante_emisor : Node3D
var velocidad_vuelo : float = 8.0

# Esta función es la que llama el estudiante al presionar Espacio
func disparar(destino: Vector3, emisor: Node3D) -> void:
	destino_final = destino
	estudiante_emisor = emisor

func _process(delta: float) -> void:
	# --- 1. VALIDACIÓN DE CONEXIÓN EN TIEMPO REAL ---
	if is_instance_valid(estudiante_emisor):
		# Si el estudiante se quedó sin router en pleno vuelo...
		if estudiante_emisor.router_conectado == null:
			print("❌ PAQUETE DESCARTADO: Se perdió la conexión en pleno tránsito.")
			queue_free() # Destruye el paquete inmediatamente
			return # Corta la ejecución para que no intente moverse
			
	# --- 2. MOVIMIENTO HACIA EL DESTINO ---
	# Si seguimos conectados, el paquete vuela normalmente
	var direccion = global_position.direction_to(destino_final)
	global_position += direccion * velocidad_vuelo * delta
	
	# --- 3. RECEPCIÓN EXITOSA ---
	# Si el paquete llega a menos de medio metro del router, se consume
	if global_position.distance_to(destino_final) < 0.5:
		# Aquí podrías sumar puntos o estadísticas en el futuro
		queue_free()
