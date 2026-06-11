extends Node3D

@export var lista_routers : Array[Node3D]
@export var escena_paquete : PackedScene
@export var radio_cobertura : float = 12.0
@export var velocidad_movimiento : float = 5.0

var router_conectado : Node3D = null
var calidad_red_actual : float = 0.0
var velocidad_paquete_actual : float = 0.0
var cooldown_red : float = 0.0
var _material_mesh : StandardMaterial3D = null

func _ready() -> void:
	add_to_group("usuarios_red")
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh and mesh.mesh:
		_material_mesh = StandardMaterial3D.new()
		mesh.material_override = _material_mesh

func _process(delta: float) -> void:
	var direccion = Vector3.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		direccion.z += 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		direccion.z -= 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		direccion.x += 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		direccion.x -= 1
		
	if direccion != Vector3.ZERO:
		direccion = direccion.normalized()
		global_position += direccion * velocidad_movimiento * delta

	if cooldown_red > 0.0: 
		cooldown_red -= delta

	var mejor_calidad = 0.0
	var mejor_router = null

	for router in lista_routers:
		if not is_instance_valid(router): continue
		var dist = global_position.distance_to(router.global_position)
		if dist > radio_cobertura: continue 

		var calidad_evaluada = 1.0 - (dist / radio_cobertura)
		if calidad_evaluada < 0.0: calidad_evaluada = 0.0
		
		if calidad_evaluada > mejor_calidad:
			mejor_calidad = calidad_evaluada
			mejor_router = router

	router_conectado = mejor_router
	calidad_red_actual = mejor_calidad
	_actualizar_visual_conexion()

	if Input.is_physical_key_pressed(KEY_SPACE) and cooldown_red <= 0.0:
		if router_conectado:
		
			var factor_congestion = 1.0
			if router_conectado.limite_ancho_banda > 0:
				factor_congestion = router_conectado.ancho_banda_disponible / router_conectado.limite_ancho_banda
			
			
			velocidad_paquete_actual = router_conectado.ancho_banda_disponible * calidad_red_actual
			if velocidad_paquete_actual < 4.0: velocidad_paquete_actual = 4.0 # Piso mínimo
			
			
			var lag_distancia = (1.0 - calidad_red_actual) * 0.6
			var lag_saturacion = (1.0 - factor_congestion) * 1.5 
			cooldown_red = 0.15 + lag_distancia + lag_saturacion
			
			
			var prob_perdida = 0.0
			if calidad_red_actual > 0.6: prob_perdida = 0.0
			elif calidad_red_actual > 0.25: prob_perdida = 0.25
			else: prob_perdida = 0.55
				
			
			prob_perdida += (1.0 - factor_congestion) * 0.8 
			
			if randf() > prob_perdida:
				if escena_paquete:
					var nuevo_paquete = escena_paquete.instantiate()
					get_parent().add_child(nuevo_paquete)
					
					# Disparamos desde el pecho/cabeza hacia el router
					nuevo_paquete.global_position = global_position + Vector3(0, 1, 0)
					var destino_elevado = router_conectado.global_position + Vector3(0, 1, 0)
					nuevo_paquete.disparar(destino_elevado, self)
			else:
				print("PÉRDIDA DE PAQUETE: La red fallo")

func _actualizar_visual_conexion() -> void:
	if not _material_mesh: return
	if router_conectado == null:
		_material_mesh.albedo_color = Color(0.8, 0.8, 0.8)
	elif calidad_red_actual > 0.6:
		_material_mesh.albedo_color = Color(0, 1, 0)
	elif calidad_red_actual > 0.25:
		_material_mesh.albedo_color = Color(1, 1, 0)
	else:
		_material_mesh.albedo_color = Color(1, 0, 0)
