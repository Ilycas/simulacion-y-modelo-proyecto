extends CharacterBody3D

@export var nodo_router : Node3D
@export var nodo_raycast : RayCast3D
@export var escena_paquete : PackedScene
@export var radio_cobertura : float = 12.0
@export var velocidad_caminar : float = 5.0
var velocidad_paquete_actual : float = 15.0

var mesh_visual : MeshInstance3D
var material_estudiante : StandardMaterial3D

var cooldown_red : float = 0.0
var routers: Array[Node3D] = []
var router_raycasts: Dictionary = {}

func _ready() -> void:
	mesh_visual = get_node("MeshInstance3D")
	material_estudiante = StandardMaterial3D.new()
	mesh_visual.material_override = material_estudiante
	for child in get_parent().get_children():
		if child is Node3D and child.name.begins_with("Router"):
			routers.append(child)
			var ray = child.get_node("Router/RayCast3D") as RayCast3D
			if ray:
				router_raycasts[child] = ray

func get_nearest_router() -> Node3D:
	var nearest: Node3D = null
	var nearest_dist_sq: float = INF
	for router in routers:
		var d_sq = global_position.distance_squared_to(router.global_position)
		if d_sq < nearest_dist_sq:
			nearest_dist_sq = d_sq
			nearest = router
	return nearest

func _physics_process(delta: float) -> void:
	var input_dir := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_D):
		input_dir.x -= 1
	if Input.is_physical_key_pressed(KEY_A):
		input_dir.x += 1
	if Input.is_physical_key_pressed(KEY_S):
		input_dir.z -= 1
	if Input.is_physical_key_pressed(KEY_W):
		input_dir.z += 1

	if input_dir != Vector3.ZERO:
		input_dir = input_dir.normalized()

	velocity = input_dir * velocidad_caminar
	move_and_slide()

func _process(delta: float) -> void:
	if cooldown_red > 0.0:
		cooldown_red -= delta

	var router = get_nearest_router()
	if not router:
		return

	var ray: RayCast3D = router_raycasts.get(router)

	var multiplicador_senal_total : float = 1.0

	if ray:
		ray.target_position = ray.to_local(global_position + Vector3(0, 1, 0))

		var evaluando_trayectoria : bool = true
		var excepciones_del_frame : Array = []

		var limite_seguridad : int = 5
		var iteracion : int = 0

		while evaluando_trayectoria and iteracion < limite_seguridad:
			iteracion += 1
			ray.force_raycast_update()

			if ray.is_colliding():
				var colisor = ray.get_collider()

				if colisor == self or colisor == router:
					evaluando_trayectoria = false
				else:
					if colisor.is_in_group("ventana"):
						multiplicador_senal_total *= 0.90
					elif colisor.is_in_group("madera"):
						multiplicador_senal_total *= 0.70
					else:
						multiplicador_senal_total *= 0.25

					var rid_colision = ray.get_collider_rid()
					ray.add_exception_rid(rid_colision)
					excepciones_del_frame.append(rid_colision)
			else:
				evaluando_trayectoria = false

			if iteracion >= limite_seguridad:
				evaluando_trayectoria = false

		for rid in excepciones_del_frame:
			ray.remove_exception_rid(rid)

	var distancia = 0.0
	var calidad_red = 0.0

	distancia = global_position.distance_to(router.global_position)

	var fuerza_distancia = 1.0 - (distancia / radio_cobertura)
	if fuerza_distancia < 0.0:
		fuerza_distancia = 0.0

	calidad_red = fuerza_distancia * multiplicador_senal_total

	if distancia <= radio_cobertura:
		velocidad_paquete_actual = 30.0 * calidad_red
		if velocidad_paquete_actual < 2.0:
			velocidad_paquete_actual = 2.0

		if calidad_red > 0.5:
			material_estudiante.albedo_color = Color(1.0, 0.0, 0.0, 1.0)
		elif calidad_red > 0.15:
			material_estudiante.albedo_color = Color(1.0, 1.0, 0.0, 1.0)
		else:
			material_estudiante.albedo_color = Color(0.0, 1.0, 0.0, 1.0)
	else:
		velocidad_paquete_actual = 0.0
		material_estudiante.albedo_color = Color(0.8, 0.8, 0.8, 1)

	if distancia <= radio_cobertura:
		velocidad_paquete_actual = velocidad_paquete_actual * multiplicador_senal_total
		if velocidad_paquete_actual < 2.0:
			velocidad_paquete_actual = 2.0

	if Input.is_physical_key_pressed(KEY_SPACE) and cooldown_red <= 0.0:
		if distancia <= radio_cobertura:
			var lag_adicional = (1.0 - calidad_red) * 1.0
			cooldown_red = 0.2 + lag_adicional

			var probabilidad_perdida = 0.0

			if calidad_red > 0.5:
				probabilidad_perdida = 0.0
			elif calidad_red > 0.15:
				probabilidad_perdida = 0.3
			else:
				probabilidad_perdida = 0.7

			if randf() > probabilidad_perdida:
				if escena_paquete:
					var nuevo_paquete = escena_paquete.instantiate()
					get_parent().add_child(nuevo_paquete)
					nuevo_paquete.global_position = global_position + Vector3(0, 1, 0)

					var destino_elevado = router.global_position + Vector3(0, 1, 0)
					nuevo_paquete.disparar(destino_elevado, self)
			else:
				print("❌ ¡Packet Loss! El paquete se corrompió antes de llegar al router.")
