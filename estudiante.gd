extends Node3D

@export var nodo_router : Node3D
@export var nodo_raycast : RayCast3D
@export var escena_paquete : PackedScene # <-- NUEVO: Aquí cargaremos el archivo paquete.tscn
@export var radio_cobertura : float = 12.0
@export var velocidad_caminar : float = 5.0

var mesh_visual : MeshInstance3D
var material_estudiante : StandardMaterial3D

var cooldown_red : float = 0.0 # Controla la tasa de transferencia (fire rate)

func _ready() -> void:
	mesh_visual = get_node("MeshInstance3D")
	material_estudiante = StandardMaterial3D.new()
	mesh_visual.material_override = material_estudiante

func _process(delta: float) -> void:
	# --- 1. CONTROLES DE MOVIMIENTO ---
	if Input.is_physical_key_pressed(KEY_D):
		global_position.x -= velocidad_caminar * delta
	if Input.is_physical_key_pressed(KEY_A):
		global_position.x += velocidad_caminar * delta
	if Input.is_physical_key_pressed(KEY_S):
		global_position.z -= velocidad_caminar * delta
	if Input.is_physical_key_pressed(KEY_W):
		global_position.z += velocidad_caminar * delta

	# Reducir el tiempo de recarga del envío
	if cooldown_red > 0.0:
		cooldown_red -= delta

	# --- 2. CÁLCULO FÍSICO DE ATENUACIÓN ---
	var hay_obstaculo : bool = false
	var multiplicador_material : float = 1.0 
	var nombre_material : String = "Ninguno"
	
	if nodo_router and nodo_raycast:
		nodo_raycast.target_position = nodo_raycast.to_local(global_position)
		nodo_raycast.force_raycast_update()
		
		if nodo_raycast.is_colliding():
			var colisor = nodo_raycast.get_collider()
			if colisor != self:
				hay_obstaculo = true
				if colisor.is_in_group("ventana"):
					multiplicador_material = 0.90
					nombre_material = "Vidrio"
				elif colisor.is_in_group("madera"):
					multiplicador_material = 0.70
					nombre_material = "Madera"
				else:
					multiplicador_material = 0.25
					nombre_material = "Concreto"

	# --- 3. MAPA DE CALOR ---
	var distancia = 0.0
	if nodo_router:
		distancia = global_position.distance_to(nodo_router.global_position)
		var zona1_fuerte = radio_cobertura / 3.0
		var zona2_promedio = (radio_cobertura / 3.0) * 2.0
		
		if distancia <= zona1_fuerte:
			material_estudiante.albedo_color = Color(1.0, 0.0, 0.0, 1.0) if multiplicador_material > 0.5 else Color(1, 1, 0, 1)
		elif distancia <= zona2_promedio:
			material_estudiante.albedo_color = Color(1, 1, 0, 1) if multiplicador_material > 0.5 else Color(0.0, 1.0, 0.0, 1.0)
		elif distancia <= radio_cobertura:
			material_estudiante.albedo_color = Color(0.0, 1.0, 0.0, 1.0) if multiplicador_material > 0.5 else Color(0.8, 0.8, 0.8, 1)
		else:
			material_estudiante.albedo_color = Color(0.8, 0.8, 0.8, 1)

	# --- 4. ENVÍO DE DATOS CONTINUO ---
	if Input.is_physical_key_pressed(KEY_SPACE) and cooldown_red <= 0.0:
		if nodo_router and distancia <= radio_cobertura:
			
			var velocidad_paquete = 0.0
			var zona1_fuerte = radio_cobertura / 3.0
			var zona2_promedio = (radio_cobertura / 3.0) * 2.0
			
			if distancia <= zona1_fuerte:
				velocidad_paquete = 30.0
			elif distancia <= zona2_promedio:
				velocidad_paquete = 15.0
			else:
				velocidad_paquete = 5.0
			
			if hay_obstaculo:
				velocidad_paquete = velocidad_paquete * multiplicador_material
				print("Atenuación: ", nombre_material, " | Retención: ", multiplicador_material * 100, "%")
			
			# ¡AQUÍ ESTÁ LA MAGIA! Generamos un clon del paquete
			if escena_paquete:
				var nuevo_paquete = escena_paquete.instantiate()
				get_parent().add_child(nuevo_paquete) # Lo soltamos en el mundo 3D
				
				# Lo posicionamos a la altura del pecho del estudiante
				nuevo_paquete.global_position = global_position + Vector3(0, 1, 0)
				
				# Le decimos a dónde ir y a qué velocidad
				var destino_elevado = nodo_router.global_position + Vector3(0, 1, 0)
				nuevo_paquete.disparar(destino_elevado, velocidad_paquete)
				
				# Reiniciamos el tiempo para permitir el próximo envío rápido (3 paquetes por seg)
				cooldown_red = 0.3 
		else:
			print("ERROR: Fuera de cobertura.")
