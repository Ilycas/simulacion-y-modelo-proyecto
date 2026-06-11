extends CharacterBody3D

@export var velocidad: float = 5.0
@export var tiempo_espera_en_destino: float = 2.0

var color_zona: Color = Color.WHITE
var marker_actual: Marker3D = null
var esperando: bool = false
var tiempo_espera_restante: float = 0.0
var todos_los_markers: Array[Marker3D] = []
var _debug_timer: float = 0.0
var _trail_timer: float = 0.0

var lista_routers: Array[Node3D] = []
var radio_cobertura: float = 50.0
var router_conectado: Node3D = null
var calidad_red_actual: float = 0.0
var _scan_timer: float = 0.0

var _ubicacion_actual: String = ""
var _cola_rutas: Array[String] = []
var _ruta_actual_idx: int = 0
var path_follow: PathFollow3D = null
var _ultimos_visitados: Array[String] = []

var velocidad_paquete_actual: float = 15.0

func _ready() -> void:
	if path_follow == null and get_parent() is PathFollow3D:
		path_follow = get_parent() as PathFollow3D
	_actualizar_conexion()

func _aplicar_color() -> void:
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh and mesh is MeshInstance3D:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_zona
		mesh.material_override = mat
	else:
		push_warning("[%s] no se encontro MeshInstance3D" % name)

func _actualizar_conexion() -> void:
	router_conectado = null
	calidad_red_actual = 0.0
	var mejor_calidad = 0.0
	var mejor_router: Node3D = null

	for router in lista_routers:
		if not is_instance_valid(router):
			continue
		var dist = global_position.distance_to(router.global_position)
		if dist > radio_cobertura:
			continue
		var calidad = 1.0 - (dist / radio_cobertura)
		if calidad < 0.0:
			calidad = 0.0
		if calidad > mejor_calidad:
			mejor_calidad = calidad
			mejor_router = router

	router_conectado = mejor_router
	calidad_red_actual = mejor_calidad

	if router_conectado:
		if calidad_red_actual > 0.6:
			color_zona = Color(0.0, 1.0, 0.0)
		elif calidad_red_actual > 0.25:
			color_zona = Color(1.0, 1.0, 0.0)
		else:
			color_zona = Color(1.0, 0.0, 0.0)
	else:
		color_zona = Color(0.5, 0.5, 0.5)

	_aplicar_color()

func _registrar_visita(nombre: String) -> void:
	_ultimos_visitados.append(nombre)
	if _ultimos_visitados.size() > 2:
		_ultimos_visitados.pop_front()

func _elegir_siguiente_destino() -> void:
	if todos_los_markers.is_empty():
		return

	var disponibles: Array[String] = []
	for m in todos_los_markers:
		if m.name != _ubicacion_actual:
			disponibles.append(m.name)

	if disponibles.is_empty():
		return

	var candidatos: Array[String] = []
	for nombre in disponibles:
		if nombre == "Entrada" or not nombre in _ultimos_visitados:
			candidatos.append(nombre)

	if candidatos.is_empty():
		candidatos = disponibles

	var nombre_destino: String = candidatos.pick_random()
	_cola_rutas = RutaManager.obtener_cadena_rutas(_ubicacion_actual, nombre_destino)
	_ruta_actual_idx = 0

	if _cola_rutas.is_empty():
		return

	var marker_destino: Marker3D = null
	for m in todos_los_markers:
		if m.name == nombre_destino:
			marker_destino = m
			break

	if marker_destino:
		marker_actual = marker_destino

	_iniciar_ruta_actual()
	print("[%s] ruta: %s -> %s (cadena: %s) recientes=%s" % [name, _ubicacion_actual, nombre_destino, str(_cola_rutas), str(_ultimos_visitados)])

func _iniciar_ruta_actual() -> void:
	if _ruta_actual_idx >= _cola_rutas.size():
		return
	var nombre_ruta: String = _cola_rutas[_ruta_actual_idx]
	var path: Path3D = RutaManager.obtener_ruta(
		RutaManager.obtener_origen_de_ruta(nombre_ruta),
		RutaManager.obtener_destino_de_ruta(nombre_ruta)
	)
	if path == null:
		return
	_mover_a_path(path)

func _mover_a_path(path: Path3D) -> void:
	if path_follow and is_instance_valid(path_follow):
		path_follow.remove_child(self)
		path_follow.queue_free()

	var nuevo_pf = PathFollow3D.new()
	nuevo_pf.loop = false
	nuevo_pf.rotation_mode = 4
	nuevo_pf.progress = 0.0
	path.add_child(nuevo_pf)
	nuevo_pf.add_child(self)
	path_follow = nuevo_pf

func _crear_marca_rastro() -> void:
	var marca = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.1
	sphere.height = 0.2
	marca.mesh = sphere
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.0, 1.0, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.0, 1.0)
	mat.emission_energy_multiplier = 1.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	marca.material_override = mat
	marca.position = global_position + Vector3(0, -0.3, 0)
	var scene = get_tree().current_scene
	if scene:
		scene.add_child(marca)
		var tween = marca.create_tween()
		tween.tween_property(mat, "albedo_color", Color(1.0, 0.0, 1.0, 0.0), 4.0)
		tween.tween_callback(marca.queue_free)

func _physics_process(delta: float) -> void:
	if path_follow == null or not is_instance_valid(path_follow):
		path_follow = get_parent() as PathFollow3D
		if path_follow == null:
			return

	_debug_timer += delta
	if _debug_timer >= 2.0:
		_debug_timer = 0.0
		print("[%s] pos=%s ubicacion=%s wp_ratio=%.2f esperando=%s cola=%d" % [name, global_position, _ubicacion_actual, path_follow.progress_ratio, esperando, _cola_rutas.size() - _ruta_actual_idx])

	var indicador = get_node_or_null("IndicadorMovimiento")
	if indicador:
		indicador.visible = not esperando

	if esperando:
		tiempo_espera_restante -= delta
		if tiempo_espera_restante <= 0.0:
			esperando = false
			_elegir_siguiente_destino()
		return

	if path_follow == null or not is_instance_valid(path_follow):
		return

	path_follow.progress += velocidad * delta

	if path_follow.progress_ratio >= 1.0:
		if not _cola_rutas.is_empty() and _ruta_actual_idx < _cola_rutas.size():
			_ubicacion_actual = RutaManager.obtener_destino_de_ruta(_cola_rutas[_ruta_actual_idx])
			_ruta_actual_idx += 1
			if _ruta_actual_idx < _cola_rutas.size():
				_iniciar_ruta_actual()
				return

		_registrar_visita(_ubicacion_actual)
		esperando = true
		tiempo_espera_restante = tiempo_espera_en_destino
		print("[%s] llegado a %s recientes=%s" % [name, _ubicacion_actual, str(_ultimos_visitados)])
		return

	_trail_timer += delta
	if _trail_timer >= 0.3:
		_trail_timer = 0.0
		_crear_marca_rastro()

	_scan_timer += delta
	if _scan_timer >= 0.5:
		_scan_timer = 0.0
		_actualizar_conexion()
		

var simulacion_activa: bool = false
var tiempo_entre_paquetes: float = 0.8 # 


func empezar_envio_datos() -> void:
	
	if simulacion_activa:
		return
		
	simulacion_activa = true
	
	
	while simulacion_activa:
		_instanciar_un_paquete()
		
		
		await get_tree().create_timer(tiempo_entre_paquetes).timeout


func _instanciar_un_paquete() -> void:
	var distancia_minima: float = radio_cobertura
	router_conectado = null 
	
	for router in lista_routers:
		if is_instance_valid(router):
			var dist = global_position.distance_to(router.global_position)
			if dist < distancia_minima:
				distancia_minima = dist
				router_conectado = router

	if router_conectado != null:
		var paquete_escena = load("res://paquete.tscn") 
		if paquete_escena:
			var paquete = paquete_escena.instantiate()
			get_tree().current_scene.add_child(paquete)
			paquete.global_position = global_position
			
			if paquete.has_method("disparar"):
				paquete.disparar(router_conectado.global_position, self)
