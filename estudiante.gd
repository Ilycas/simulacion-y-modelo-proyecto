extends CharacterBody3D

@export var nodo_router : Node3D
@export var nodo_raycast : RayCast3D
@export var nodo_paquete : Node3D
@export var radio_cobertura : float = 12.0
@export var velocidad_caminar : float = 5.0

var mesh_visual : MeshInstance3D
var material_estudiante : StandardMaterial3D

var paquete_viajando : bool = false
var velocidad_paquete : float = 15.0

var zona1_fuerte: float
var zona2_promedio: float

func _ready() -> void:
	if not nodo_router:
		push_error("Estudiante: nodo_router no asignado")
	if not nodo_raycast:
		push_error("Estudiante: nodo_raycast no asignado")
	if not nodo_paquete:
		push_error("Estudiante: nodo_paquete no asignado")
	
	zona1_fuerte = radio_cobertura / 3.0
	zona2_promedio = (radio_cobertura / 3.0) * 2.0
	
	mesh_visual = get_node("MeshInstance3D")
	material_estudiante = StandardMaterial3D.new()
	mesh_visual.material_override = material_estudiante
	
	if nodo_paquete:
		nodo_paquete.visible = false

func _physics_process(delta: float) -> void:
	# --- 1. CONTROLES DE MOVIMIENTO ---
	var mov := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_D):
		mov.x -= 1
	if Input.is_physical_key_pressed(KEY_A):
		mov.x += 1
	if Input.is_physical_key_pressed(KEY_S):
		mov.z -= 1
	if Input.is_physical_key_pressed(KEY_W):
		mov.z += 1
	velocity = mov.normalized() * velocidad_caminar
	move_and_slide()

func _process(delta: float) -> void:

	# --- 2. CÁLCULO FÍSICO DE ATENUACIÓN (RAYCAST Y MATERIALES) ---
	var hay_obstaculo : bool = false
	var multiplicador_material : float = 1.0 # 1.0 = 100% de la señal pasa
	var nombre_material : String = "Ninguno"
	
	if nodo_router and nodo_raycast:
		nodo_raycast.target_position = nodo_raycast.to_local(global_position)
		nodo_raycast.force_raycast_update()
		
		if nodo_raycast.is_colliding():
			var colisor = nodo_raycast.get_collider()
			if colisor != self:
				hay_obstaculo = true
				print("Colisiona con: ", colisor.name, " | grupos: ", colisor.get_groups())
				
				# SISTEMA DE DETECCIÓN DE MATERIALES MEDIANTE GRUPOS
				if colisor.is_in_group("ventana"):
					multiplicador_material = 0.90 # El vidrio deja pasar el 90%
					nombre_material = "Vidrio"
				elif colisor.is_in_group("madera"):
					multiplicador_material = 0.70 # La madera deja pasar el 70%
					nombre_material = "Madera"
				else:
					# Por defecto, cualquier otra estructura (el bloque general) es concreto
					multiplicador_material = 0.25 # El concreto castiga dejando pasar solo el 25%
					nombre_material = "Concreto"

	# --- 3. MAPA DE CALOR ---
	var distancia = 0.0
	if nodo_router:
		distancia = global_position.distance_to(nodo_router.global_position)
		# Simplificamos el degradado: Si la señal es menor al 50% por culpa del material, pinta rojo.
		if distancia <= zona1_fuerte:
			material_estudiante.albedo_color = Color(1.0, 0.0, 0.0, 1.0) if multiplicador_material > 0.5 else Color(1, 1, 0, 1)
		elif distancia <= zona2_promedio:
			material_estudiante.albedo_color = Color(1, 1, 0, 1) if multiplicador_material > 0.5 else Color(0.0, 1.0, 0.0, 1.0)
		elif distancia <= radio_cobertura:
			material_estudiante.albedo_color = Color(0.0, 0.529, 0.0, 1.0) if multiplicador_material > 0.5 else Color(0.8, 0.8, 0.8, 1)
		else:
			material_estudiante.albedo_color = Color(0.8, 0.8, 0.8, 1)

	# --- 4. DISPARO DE PAQUETE ---
	if Input.is_physical_key_pressed(KEY_SPACE) and not paquete_viajando:
		if nodo_router and distancia <= radio_cobertura:
			
			if distancia <= zona1_fuerte:
				velocidad_paquete = 30.0
			elif distancia <= zona2_promedio:
				velocidad_paquete = 15.0
			else:
				velocidad_paquete = 5.0
			
			# APLICAR LA PENALIZACIÓN EXACTA DEL MATERIAL AL PAQUETE
			if hay_obstaculo:
				velocidad_paquete = velocidad_paquete * multiplicador_material
				print("-> Atenuación por ", nombre_material, ". Retención de señal: ", multiplicador_material * 100, "%")
			
			if nodo_paquete:
				nodo_paquete.global_position = global_position + Vector3(0, 1, 0)
				nodo_paquete.visible = true
				paquete_viajando = true
		else:
			print("ERROR: Fuera de cobertura.")

	# --- 5. VIAJE DEL PAQUETE ---
	if paquete_viajando and nodo_paquete and nodo_router:
		var destino_elevado = nodo_router.global_position + Vector3(0, 1, 0)
		nodo_paquete.global_position = nodo_paquete.global_position.move_toward(destino_elevado, velocidad_paquete * delta)
		
		if nodo_paquete.global_position.distance_to(destino_elevado) < 0.2:
			paquete_viajando = false
			nodo_paquete.visible = false
			print("-> [ACK] ¡Paquete recibido!")
