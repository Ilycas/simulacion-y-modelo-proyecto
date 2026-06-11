extends Camera3D

@export var velocidad_zoom: float = 5.0
@export var fov_minimo: float = 20.0  # El límite máximo de qué tan cerca puedes ver
@export var fov_maximo: float = 100.0 # El límite máximo de qué tan lejos puedes ver

func _input(event: InputEvent) -> void:
	# Detectamos si el evento es un clic/movimiento de los botones del mouse
	if event is InputEventMouseButton and event.pressed:
		
		# Rueda hacia arriba (Acercar)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			fov = clamp(fov - velocidad_zoom, fov_minimo, fov_maximo)
			
		# Rueda hacia abajo (Alejar)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			fov = clamp(fov + velocidad_zoom, fov_minimo, fov_maximo)
