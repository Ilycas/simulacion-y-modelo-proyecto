extends Node3D

@export var nodo_router : Node3D
@export var nodo_raycast : RayCast3D
@export var escena_paquete : PackedScene # <-- NUEVO: Aquí cargaremos el archivo paquete.tscn
@export var radio_cobertura : float = 12.0
@export var velocidad_caminar : float = 5.0
var velocidad_paquete_actual : float = 15.0

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

	

	# --- 3. MAPA DE CALOR Y CÁLCULO DE VELOCIDAD DINÁMICA ---
	var distancia = 0.0
	if nodo_router:
		distancia = global_position.distance_to(nodo_router.global_position)
		var zona1_fuerte = radio_cobertura / 3.0
		var zona2_promedio = (radio_cobertura / 3.0) * 2.0
		
		# Calcular velocidad teórica por pura distancia
		if distancia <= zona1_fuerte:
			velocidad_paquete_actual = 30.0
			material_estudiante.albedo_color = Color(1.0, 0.0, 0.0, 1.0) if multiplicador_material > 0.5 else Color(1, 1, 0, 1)
		elif distancia <= zona2_promedio:
			velocidad_paquete_actual = 15.0
			material_estudiante.albedo_color = Color(1, 1, 0, 1) if multiplicador_material > 0.5 else Color(0.0, 1.0, 0.0, 1.0)
		elif distancia <= radio_cobertura:
			velocidad_paquete_actual = 5.0
			material_estudiante.albedo_color = Color(0.0, 1.0, 0.0, 1.0) if multiplicador_material > 0.5 else Color(0.8, 0.8, 0.8, 1)
		else:
			velocidad_paquete_actual = 0.0
			material_estudiante.albedo_color = Color(0.8, 0.8, 0.8, 1)

		# Aplicar castigo por material de inmediato si hay obstáculo
		if hay_obstaculo and distancia <= radio_cobertura:
			velocidad_paquete_actual = velocidad_paquete_actual * multiplicador_material

	# --- 4. ENVÍO DE DATOS CONTINUO ---
	if Input.is_physical_key_pressed(KEY_SPACE) and cooldown_red <= 0.0:
		if nodo_router and distancia <= radio_cobertura:
			if escena_paquete:
				var nuevo_paquete = escena_paquete.instantiate()
				get_parent().add_child(nuevo_paquete)
				nuevo_paquete.global_position = global_position + Vector3(0, 1, 0)
				
				var destino_elevado = nodo_router.global_position + Vector3(0, 1, 0)
				
				# ¡CAMBIO CLAVE!: En vez de pasarle un número fijo, le pasamos "self" (todo el estudiante)
				nuevo_paquete.disparar(destino_elevado, self)
				
				cooldown_red = 0.3
		else:
			print("ERROR: Fuera de cobertura.")
