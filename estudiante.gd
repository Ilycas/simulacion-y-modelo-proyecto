extends Node3D

@export var lista_routers : Array[Node3D]
@export var escena_paquete : PackedScene
@export var radio_cobertura : float = 12.0
@export var velocidad_caminar : float = 5.0

var mesh_visual : MeshInstance3D
var material_estudiante : StandardMaterial3D
var cooldown_red : float = 0.0

var velocidad_paquete_actual : float = 15.0
var router_conectado : Node3D = null
var calidad_red_actual : float = 0.0

func _ready() -> void:
	mesh_visual = get_node("MeshInstance3D")
	material_estudiante = StandardMaterial3D.new()
	mesh_visual.material_override = material_estudiante

func _process(delta: float) -> void:
	# --- 1. CONTROLES DE MOVIMIENTO ---
	if Input.is_physical_key_pressed(KEY_D): global_position.x -= velocidad_caminar * delta
	if Input.is_physical_key_pressed(KEY_A): global_position.x += velocidad_caminar * delta
	if Input.is_physical_key_pressed(KEY_S): global_position.z -= velocidad_caminar * delta
	if Input.is_physical_key_pressed(KEY_W): global_position.z += velocidad_caminar * delta

	if cooldown_red > 0.0: cooldown_red -= delta

	# --- 2. ESCANEO DE REDES POR DISTANCIA (ROAMING FLUIDO) ---
	var mejor_calidad = 0.0
	var mejor_router = null

	for router in lista_routers:
		if not is_instance_valid(router): continue
		
		var dist = global_position.distance_to(router.global_position)
		if dist > radio_cobertura: continue # Ignorar si está fuera de cobertura

		# La calidad decae linealmente con la distancia (1.0 pegado al router, 0.0 en el borde)
		var calidad_evaluada = 1.0 - (dist / radio_cobertura)
		if calidad_evaluada < 0.0: calidad_evaluada = 0.0
		
		# Elección automática de la señal más potente
		if calidad_evaluada > mejor_calidad:
			mejor_calidad = calidad_evaluada
			mejor_router = router

	# --- 3. CONEXIÓN AUTOMÁTICA (HANDOVER) ---
	router_conectado = mejor_router
	calidad_red_actual = mejor_calidad
	
	if router_conectado:
		# La velocidad escala de forma matemática limpia hasta 30 Mbps
		velocidad_paquete_actual = 30.0 * calidad_red_actual
		if velocidad_paquete_actual < 4.0: velocidad_paquete_actual = 4.0 # Velocidad mínima
			
		# Gradiente visual limpio por zonas de distancia
		if calidad_red_actual > 0.6:
			material_estudiante.albedo_color = Color(1.0, 0.0, 0.0, 1.0) # Verde: Excelente
		elif calidad_red_actual > 0.25:
			material_estudiante.albedo_color = Color(1, 1, 0, 1) # Amarillo: Media
		else:
			material_estudiante.albedo_color = Color(0.0, 1.0, 0.0, 1.0) # Rojo: Crítica
	else:
		velocidad_paquete_actual = 0.0
		material_estudiante.albedo_color = Color(0.8, 0.8, 0.8, 1) # Gris: Sin señal

	# --- 4. ENVÍO DE DATOS DINÁMICO (LAG Y PÉRDIDA POR DISTANCIA) ---
	if Input.is_physical_key_pressed(KEY_SPACE) and cooldown_red <= 0.0:
		if router_conectado:
			# El lag aumenta de forma proporcional conforme te alejas
			var lag_adicional = (1.0 - calidad_red_actual) * 0.6
			cooldown_red = 0.15 + lag_adicional
			
			# Probabilidad de pérdida basada en la distancia del router elegido
			var prob_perdida = 0.0
			if calidad_red_actual > 0.6:
				prob_perdida = 0.0 # 0% pérdidas cerca
			elif calidad_red_actual > 0.25:
				prob_perdida = 0.25 # 25% pérdidas a media distancia
			else:
				prob_perdida = 0.55 # 55% pérdidas en el extremo
				
			if randf() > prob_perdida:
				if escena_paquete:
					var nuevo_paquete = escena_paquete.instantiate()
					get_parent().add_child(nuevo_paquete)
					nuevo_paquete.global_position = global_position + Vector3(0, 1, 0)
					
					var destino_elevado = router_conectado.global_position + Vector3(0, 1, 0)
					nuevo_paquete.disparar(destino_elevado, self)
