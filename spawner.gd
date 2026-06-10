extends Node3D

@export var num_moviles: int = 12
@export var num_estaticos: int = 48
@export var radio_cobertura: float = 50.0
@export var y_spawn: float = 0.4

func _ready() -> void:
	var markers = get_tree().get_nodes_in_group("destino")
	if markers.is_empty():
		push_warning("Spawner: no se encontraron marcadores en grupo 'destino'")
		return
	var routers: Array[Node3D] = []
	for child in get_tree().current_scene.get_children():
		if child is Node3D and "Router" in child.name:
			routers.append(child)

	call_deferred("_iniciar_rutas_y_spawn", markers, routers)

func _iniciar_rutas_y_spawn(markers: Array, routers: Array[Node3D]) -> void:
	RutaManager.registrar_rutas_existentes()

	var markers_tipados: Array[Marker3D] = []
	markers_tipados.assign(markers)

	var rutas_hub: Array[Path3D] = []
	var rutas_spoke: Array[Path3D] = []
	for clave in RutaManager._rutas:
		var p: Path3D = RutaManager._rutas[clave]
		if clave.begins_with("Entrada->"):
			rutas_hub.append(p)
		else:
			rutas_spoke.append(p)

	var spawn_count: int = 0
	var usar_hub: bool = true

	for i in num_moviles:
		if usar_hub and not rutas_hub.is_empty():
			_spawn_en_ruta(rutas_hub[i % rutas_hub.size()], markers_tipados, routers)
		elif not rutas_spoke.is_empty():
			_spawn_en_ruta(rutas_spoke[i % rutas_spoke.size()], markers_tipados, routers)
		elif not rutas_hub.is_empty():
			_spawn_en_ruta(rutas_hub[i % rutas_hub.size()], markers_tipados, routers)
		else:
			break
		usar_hub = not usar_hub
		spawn_count += 1

	for i in num_estaticos:
		_spawn_estatico(markers_tipados, routers)

func _spawn_en_ruta(path: Path3D, markers: Array[Marker3D], routers: Array[Node3D]) -> void:
	var partes = path.name.split("->")
	if partes.size() != 2:
		return
	var origen_nombre = partes[0]
	var destino_nombre = partes[1]

	var marker_origen: Marker3D = null
	var marker_destino: Marker3D = null
	for m in markers:
		if m.name == origen_nombre:
			marker_origen = m
		elif m.name == destino_nombre:
			marker_destino = m

	if marker_origen == null or marker_destino == null:
		return

	var path_follow = PathFollow3D.new()
	path_follow.name = "PathFollow_%s" % origen_nombre
	path_follow.loop = false
	path_follow.rotation_mode = 4
	path.add_child(path_follow)

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
	path_follow.add_child(est)

	est.position = Vector3.ZERO
	path_follow.progress = 0.0

	est.todos_los_markers = markers
	est.lista_routers = routers
	est.radio_cobertura = radio_cobertura
	est.marker_actual = marker_destino
	est._ubicacion_actual = origen_nombre

func _spawn_estatico(markers: Array, routers: Array[Node3D]) -> void:
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
	est.lista_routers = routers
	est.radio_cobertura = radio_cobertura

	add_child(est)
