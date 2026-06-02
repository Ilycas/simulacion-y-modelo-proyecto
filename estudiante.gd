extends Node3D

@export var nodo_router : Node3D
@export var nodo_paquete : Node3D
@export var radio_cobertura : float = 12.0
@export var velocidad_caminar : float = 5.0

var mesh_visual : MeshInstance3D
var material_estudiante : StandardMaterial3D

var paquete_viajando : bool = false
var velocidad_paquete : float = 15.0

func _ready() -> void:
	mesh_visual = get_node("MeshInstance3D")
	material_estudiante = StandardMaterial3D.new()
	mesh_visual.material_override = material_estudiante
	if nodo_paquete:
		nodo_paquete.visible = false

func _process(delta: float) -> void:
	# --- 1. CONTROLES DE MOVIMIENTO DIRECTOS (W, A, S, D) ---
	if Input.is_physical_key_pressed(KEY_D):
		global_position.x += velocidad_caminar * delta
	if Input.is_physical_key_pressed(KEY_A):
		global_position.x -= velocidad_caminar * delta
	if Input.is_physical_key_pressed(KEY_S):
		global_position.z += velocidad_caminar * delta
	if Input.is_physical_key_pressed(KEY_W):
		global_position.z -= velocidad_caminar * delta
		
	# --- 2. MAPA DE CALOR ---
	var distancia = 0.0
	if nodo_router:
		distancia = global_position.distance_to(nodo_router.global_position)
		var zona1_fuerte = radio_cobertura / 3.0
		var zona2_promedio = (radio_cobertura / 3.0) * 2.0
		
		if distancia <= zona1_fuerte:
			material_estudiante.albedo_color = Color(1, 0, 0, 1)
		elif distancia <= zona2_promedio:
			material_estudiante.albedo_color = Color(1, 1, 0, 1)
		elif distancia <= radio_cobertura:
			material_estudiante.albedo_color = Color(0, 1, 0, 1)
		else:
			material_estudiante.albedo_color = Color(0.8, 0.8, 0.8, 1)

	# --- 3. DISPARO DE PAQUETE (BARRA ESPACIADORA) ---
	if Input.is_physical_key_pressed(KEY_SPACE) and not paquete_viajando:
		if nodo_router and distancia <= radio_cobertura:
			print("¡PING! Generando paquete...")
			var zona1_fuerte = radio_cobertura / 3.0
			var zona2_promedio = (radio_cobertura / 3.0) * 2.0
			
			if distancia <= zona1_fuerte:
				velocidad_paquete = 30.0 
			elif distancia <= zona2_promedio:
				velocidad_paquete = 15.0 
			else:
				velocidad_paquete = 5.0  
			
			if nodo_paquete:
				# Dispara desde la altura del pecho
				nodo_paquete.global_position = global_position + Vector3(0, 1, 0)
				nodo_paquete.visible = true
				paquete_viajando = true
		else:
			print("ERROR: Fuera de cobertura.")

	# --- 4. VIAJE DEL PAQUETE ---
	if paquete_viajando and nodo_paquete and nodo_router:
		var destino_elevado = nodo_router.global_position + Vector3(0, 1, 0)
		nodo_paquete.global_position = nodo_paquete.global_position.move_toward(destino_elevado, velocidad_paquete * delta)
		if nodo_paquete.global_position.distance_to(destino_elevado) < 0.2:
			paquete_viajando = false
			nodo_paquete.visible = false
			print("-> [ACK] ¡Paquete recibido!")
