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

	# --- 2. CÁLCULO FÍSICO DE ATENUACIÓN ACUMULATIVA (RAYCAST SEGURO POR RID) ---
	var multiplicador_senal_total : float = 1.0 
	
	if nodo_router and nodo_raycast:
		# APUNTAR AL PECHO: Sumamos 1 metro en Y para que el rayo no raspe el piso
		nodo_raycast.target_position = nodo_raycast.to_local(global_position + Vector3(0, 1, 0))
		
		var evaluando_trayectoria : bool = true
		var excepciones_del_frame : Array = []
		
		var limite_seguridad : int = 5 # Lo bajamos a 5. Rara vez hay 5 paredes seguidas.
		var iteracion : int = 0
		
		while evaluando_trayectoria and iteracion < limite_seguridad:
			iteracion += 1 
			nodo_raycast.force_raycast_update()
			
			if nodo_raycast.is_colliding():
				var colisor = nodo_raycast.get_collider()
				
				# Protecciones de choque amigo
				if colisor == self or colisor == nodo_router:
					evaluando_trayectoria = false
				else:
					if colisor.is_in_group("ventana"):
						multiplicador_senal_total *= 0.90
					elif colisor.is_in_group("madera"):
						multiplicador_senal_total *= 0.70
					else:
						multiplicador_senal_total *= 0.25
					
					# TRUCO DE OPTIMIZACIÓN: Usar el RID en lugar del nodo
					var rid_colision = nodo_raycast.get_collider_rid()
					nodo_raycast.add_exception_rid(rid_colision)
					excepciones_del_frame.append(rid_colision)
			else:
				evaluando_trayectoria = false
				
			if iteracion >= limite_seguridad:
				evaluando_trayectoria = false # Abortamos en silencio
		
		# Limpiamos el rayo para el siguiente frame usando los RIDs
		for rid in excepciones_del_frame:
			nodo_raycast.remove_exception_rid(rid)

	

# --- 3. CÁLCULO DE CALIDAD DE RED (DISTANCIA + OBSTÁCULOS) ---
	var distancia = 0.0
	var calidad_red = 0.0 
	
	if nodo_router:
		distancia = global_position.distance_to(nodo_router.global_position)
		
		# Calculamos la fuerza base de la señal según qué tan lejos estás
		var fuerza_distancia = 1.0 - (distancia / radio_cobertura)
		if fuerza_distancia < 0.0:
			fuerza_distancia = 0.0
			
		# LA FÓRMULA MÁGICA: Distancia combinada con los materiales que atravesó
		var atenuacion_real = max(multiplicador_senal_total, 0.10)
		calidad_red = fuerza_distancia * atenuacion_real
		
		if distancia <= radio_cobertura:
			# La velocidad ahora es súper dinámica (máximo 30 Mbps)
			velocidad_paquete_actual = 30.0 * calidad_red
			
			if velocidad_paquete_actual < 2.0:
				velocidad_paquete_actual = 2.0 # Seguro anti-congelamiento de paquetes
				
			# Colores dinámicos basados en la Calidad Total
			if calidad_red > 0.5:
				material_estudiante.albedo_color = Color(0, 1, 0, 1) # Verde (Óptimo)
			elif calidad_red > 0.15:
				material_estudiante.albedo_color = Color(1, 1, 0, 1) # Amarillo (Medio)
			else:
				material_estudiante.albedo_color = Color(1, 0, 0, 1) # Rojo (Crítico/Lento)
		else:
			velocidad_paquete_actual = 0.0
			material_estudiante.albedo_color = Color(0.8, 0.8, 0.8, 1) # Gris (Sin cobertura)
			
# Aplicar el castigo combinado de todas las paredes atravesadas
		if distancia <= radio_cobertura:
			velocidad_paquete_actual = velocidad_paquete_actual * multiplicador_senal_total
			
			# NUEVO: Evitar que el paquete se congele. Si va muy lento, forzamos a 2.0
			if velocidad_paquete_actual < 2.0:
				velocidad_paquete_actual = 2.0
	# --- 4. ENVÍO DE DATOS (CON PÉRDIDA DE PAQUETES Y LAG) ---
	if Input.is_physical_key_pressed(KEY_SPACE) and cooldown_red <= 0.0:
		if nodo_router and distancia <= radio_cobertura:
			
			# 1. SIMULACIÓN DE LAG (JITTER): 
			# Señal perfecta = 0.2s de retardo. Señal pésima = hasta 1.2s de retardo entre paquetes.
			var lag_adicional = (1.0 - calidad_red) * 1.0 
			cooldown_red = 0.2 + lag_adicional
			
			# 2. SIMULACIÓN DE PÉRDIDA DE PAQUETES (Packet Loss):
			var probabilidad_perdida = 0.0
			
			if calidad_red > 0.5:
				probabilidad_perdida = 0.0 # Zona Verde: 0% de pérdida (Conexión estable)
			elif calidad_red > 0.15:
				probabilidad_perdida = 0.3 # Zona Amarilla: 30% de probabilidad de perder el paquete
			else:
				probabilidad_perdida = 0.7 # Zona Roja: 70% de probabilidad de pérdida (Conexión crítica)
				
			# 3. TIRAR LOS DADOS: randf() genera un número aleatorio entre 0.0 y 1.0
			if randf() > probabilidad_perdida:
				# EL PAQUETE SOBREVIVIÓ A LA INTERFERENCIA
				if escena_paquete:
					var nuevo_paquete = escena_paquete.instantiate()
					get_parent().add_child(nuevo_paquete)
					nuevo_paquete.global_position = global_position + Vector3(0, 1, 0)
					
					var destino_elevado = nodo_router.global_position + Vector3(0, 1, 0)
					nuevo_paquete.disparar(destino_elevado, self)
			else:
				# EL PAQUETE FUE DESTRUIDO POR MALA SEÑAL
				# Aquí podrías instanciar un efecto visual de chispas rojas, por ahora lo vemos en consola
				print("❌ ¡Packet Loss! El paquete se corrompió antes de llegar al router.")
