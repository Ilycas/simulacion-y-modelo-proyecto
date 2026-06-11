extends CanvasLayer

@export var antena_principal : Node3D

@onready var slider = $Panel/HSlider
@onready var label = $Panel/Label
@onready var btn_techos = $Panel/CheckButton
@onready var btn_simulacion = $Panel/ButtonIniciar

func _ready() -> void:
	if is_instance_valid(slider):
		slider.min_value = 0.0
		slider.max_value = 500.0
		slider.value = 500.0
		slider.value_changed.connect(_on_slider_value_changed)
		
	if is_instance_valid(label):
		label.text = "Ancho de Banda Global: 500 Mbps"
		
	if is_instance_valid(btn_techos):
		btn_techos.button_pressed = true
		btn_techos.text = "Techos Visibles"
		btn_techos.toggled.connect(_on_btn_techos_toggled)
		
	# Configuración del nuevo botón de simulación
	if is_instance_valid(btn_simulacion):
		btn_simulacion.text = "Iniciar Simulación"
		btn_simulacion.pressed.connect(_on_btn_simulacion_pressed)

func _on_slider_value_changed(value: float) -> void:

	if is_instance_valid(antena_principal):
		antena_principal.ancho_banda_entrada = value
	if is_instance_valid(label):
		label.text = "Ancho de Banda Global: " + str(int(value)) + " Mbps"
	

	var estudiantes = get_tree().get_nodes_in_group("grupo_estudiantes")
	
	for est in estudiantes:
		if is_instance_valid(est):
			
			if "velocidad_paquete_actual" in est:
				
				if value == 0.0:
					est.velocidad_paquete_actual = 0.0
					est.tiempo_entre_paquetes = 999999.0
				else:
					est.velocidad_paquete_actual = (value / 500.0) * 15.0
					est.tiempo_entre_paquetes = lerp(2.0, 0.2, value / 500.0)
			
				est.velocidad_paquete_actual = (value / 500.0) * 15.0
		
				est.tiempo_entre_paquetes = lerp(2.0, 0.2, value / 500.0)

func _on_btn_techos_toggled(button_pressed: bool) -> void:
	var techos = get_tree().get_nodes_in_group("grupo_techo")
	for techo in techos:
		if is_instance_valid(techo):
			techo.visible = button_pressed

func _on_btn_simulacion_pressed() -> void:
	# El botón recopila a todos los NPCs estudiantes de la institución
	var estudiantes = get_tree().get_nodes_in_group("grupo_estudiantes")
	
	for estudiante in estudiantes:
		if is_instance_valid(estudiante):
			# Aquí llamamos a la función interna que creaste en el script del estudiante.
			# Asegúrate de cambiar "empezar_envio_datos" por el nombre exacto de la función 
			# que tiene tu script de estudiante para lanzar los paquetes de red.
			if estudiante.has_method("empezar_envio_datos"):
				estudiante.empezar_envio_datos()
