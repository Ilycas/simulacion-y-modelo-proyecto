extends Node3D

@export var num_moviles: int = 12
@export var num_estaticos: int = 48
@export var radio_cobertura: float = 50.0
@export var y_spawn: float = 0.4

func _ready() -> void:
	NavigationServer3D.set_debug_enabled(true)
	var markers = get_tree().get_nodes_in_group("destino")
	var router = get_node_or_null("../Router")
	if markers.is_empty():
		push_warning("Spawner: no se encontraron marcadores en grupo 'destino'")
		return
	for i in num_moviles:
		_spawn_movil(markers, router)
	for i in num_estaticos:
		_spawn_estatico(markers, router)

func _spawn_movil(markers: Array, router: Node3D) -> void:
	var est = CharacterBody3D.new()

	var mesh = MeshInstance3D.new()
	mesh.name = "MeshInstance3D"
	var capsule = CapsuleMesh.new()
	capsule.height = 1.8
	capsule.radius = 0.4
	mesh.mesh = capsule
	est.add_child(mesh)

	var col = CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var shape = CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	col.shape = shape
	est.add_child(col)

	var nav = NavigationAgent3D.new()
	nav.name = "NavigationAgent3D"
	est.add_child(nav)

	var indicador = MeshInstance3D.new()
	indicador.name = "IndicadorMovimiento"
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.25
	cone.height = 0.5
	cone.radial_segments = 8
	indicador.mesh = cone
	var mat_ind = StandardMaterial3D.new()
	mat_ind.albedo_color = Color(1.0, 0.6, 0.0)
	mat_ind.emission_enabled = true
	mat_ind.emission = Color(1.0, 0.6, 0.0)
	mat_ind.emission_energy_multiplier = 2.0
	indicador.material_override = mat_ind
	indicador.position = Vector3(0.0, 1.6, 0.0)
	est.add_child(indicador)

	est.set_script(load("res://estudiante_movil.gd"))

	var marker: Marker3D = markers.pick_random()
	var pos = marker.global_position + Vector3(randf_range(-2.0, 2.0), 0.0, randf_range(-2.0, 2.0))
	pos.y = y_spawn
	est.position = pos
	var markers_tipados: Array[Marker3D] = []
	markers_tipados.assign(markers)
	est.todos_los_markers = markers_tipados
	est.asignar_color_por_zona(pos, router, radio_cobertura)

	add_child(est)

func _spawn_estatico(markers: Array, router: Node3D) -> void:
	var est = Node3D.new()

	var mesh = MeshInstance3D.new()
	mesh.name = "MeshInstance3D"
	var capsule = CapsuleMesh.new()
	capsule.height = 1.8
	capsule.radius = 0.4
	mesh.mesh = capsule
	est.add_child(mesh)

	est.set_script(load("res://estudiante_estatico.gd"))

	var marker: Marker3D = markers.pick_random()
	var pos = marker.global_position + Vector3(randf_range(-3.0, 3.0), 0.0, randf_range(-3.0, 3.0))
	pos.y = y_spawn
	est.position = pos
	est.asignar_color_por_zona(pos, router, radio_cobertura)

	add_child(est)
