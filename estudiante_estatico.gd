extends Node3D

var color_zona: Color = Color.WHITE
var lista_routers: Array[Node3D] = []
var radio_cobertura: float = 50.0
var router_conectado: Node3D = null
var calidad_red_actual: float = 0.0
var _scan_timer: float = 0.0

func _ready() -> void:
	_actualizar_conexion()

func _aplicar_color() -> void:
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh and mesh is MeshInstance3D:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_zona
		mesh.material_override = mat

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
