extends CharacterBody3D

@export var velocidad: float = 5.0
@export var tiempo_espera_en_destino: float = 2.0

var color_zona: Color = Color.WHITE
var marker_actual: Marker3D = null
var esperando: bool = false
var tiempo_espera_restante: float = 0.0
var todos_los_markers: Array[Marker3D] = []
var markers_visitados: Array[Marker3D] = []
var _debug_timer: float = 0.0
var _trail_timer: float = 0.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	nav_agent.path_desired_distance = 0.3
	nav_agent.target_desired_distance = 0.5
	nav_agent.avoidance_enabled = false
	nav_agent.radius = 0.4
	nav_agent.height = 1.8
	nav_agent.path_max_distance = 50.0
	_aplicar_color()
	for i in 10:
		await get_tree().physics_frame
	_elegir_siguiente_destino()

func _aplicar_color() -> void:
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh and mesh is MeshInstance3D:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_zona
		mesh.material_override = mat
	else:
		push_warning("[%s] no se encontró MeshInstance3D" % name)

func asignar_color_por_zona(posicion: Vector3, router: Node3D, radio: float = 50.0) -> void:
	if not router:
		color_zona = Color(1.0, 0.0, 0.0)
	else:
		var dist = posicion.distance_to(router.global_position)
		if dist > radio:
			color_zona = Color(1.0, 0.0, 0.0)
		else:
			var calidad = 1.0 - (dist / radio)
			if calidad > 0.6:
				color_zona = Color(0.0, 1.0, 0.0)
			elif calidad > 0.25:
				color_zona = Color(1.0, 1.0, 0.0)
			else:
				color_zona = Color(1.0, 0.0, 0.0)
	if is_inside_tree():
		_aplicar_color()

func _elegir_siguiente_destino() -> void:
	if todos_los_markers.is_empty():
		return
	if markers_visitados.size() >= todos_los_markers.size():
		markers_visitados.clear()
	var disponibles: Array[Marker3D] = []
	for m in todos_los_markers:
		if m in markers_visitados:
			continue
		if _marker_ocupado(m):
			continue
		disponibles.append(m)
	if disponibles.is_empty():
		await get_tree().create_timer(1.0).timeout
		_elegir_siguiente_destino()
		return
	marker_actual = disponibles.pick_random()
	markers_visitados.append(marker_actual)
	nav_agent.target_position = marker_actual.global_position
	print("[%s] destino: %s en %s" % [name, marker_actual.name, marker_actual.global_position])

func _marker_ocupado(marker: Marker3D) -> bool:
	var area = marker.get_node_or_null("Area3D")
	if not area:
		return false
	return area.get_overlapping_bodies().size() > 0

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
	var padre = get_parent()
	if padre:
		padre.add_child(marca)
		var tween = marca.create_tween()
		tween.tween_property(mat, "albedo_color", Color(1.0, 0.0, 1.0, 0.0), 4.0)
		tween.tween_callback(marca.queue_free)

func _physics_process(delta: float) -> void:
	_debug_timer += delta
	if _debug_timer >= 2.0:
		_debug_timer = 0.0
		var current_path = nav_agent.get_current_navigation_path()
		print("[%s] pos=%s path_size=%d esperando=%s" % [name, global_position, current_path.size(), esperando])

	var indicador = get_node_or_null("IndicadorMovimiento")
	if indicador:
		indicador.visible = not esperando

	if esperando:
		tiempo_espera_restante -= delta
		if tiempo_espera_restante <= 0.0:
			esperando = false
			_elegir_siguiente_destino()
		return

	if marker_actual == null:
		_elegir_siguiente_destino()
		return

	var destino = marker_actual.global_position
	destino.y = global_position.y
	var distancia = global_position.distance_to(destino)

	if distancia < 0.5:
		esperando = true
		tiempo_espera_restante = tiempo_espera_en_destino
		print("[%s] llegado a %s" % [name, marker_actual.name])
		return

	var punto = destino
	var current_path = nav_agent.get_current_navigation_path()
	if not current_path.is_empty() and not nav_agent.is_navigation_finished():
		punto = nav_agent.get_next_path_position()

	var direccion = (punto - global_position)
	direccion.y = 0.0
	if direccion.length() < 0.01:
		return
	direccion = direccion.normalized()
	global_position += direccion * velocidad * delta
	_crear_marca_rastro()
