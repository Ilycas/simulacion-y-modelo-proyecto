extends Node3D

var color_zona: Color = Color.WHITE

func _ready() -> void:
	_aplicar_color()

func _aplicar_color() -> void:
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh and mesh is MeshInstance3D:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color_zona
		mesh.material_override = mat

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
