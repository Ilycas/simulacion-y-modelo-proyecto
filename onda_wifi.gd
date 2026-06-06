extends MeshInstance3D

@export var radio_maximo : float = 12.0 
@export var velocidad_expansion : float = 5.0

@export var escala_actual : float = 0.1
var material_onda : StandardMaterial3D

func _ready() -> void:
	# Como ya declaramos que somos un MeshInstance3D, Godot compilará esto sin chistar
	material_onda = self.get_active_material(0).duplicate()
	self.material_override = material_onda

func _process(delta: float) -> void:
	# 1. Expandir la onda
	escala_actual += velocidad_expansion * delta
	scale = Vector3(escala_actual, 1.0, escala_actual)
	
	var porcentaje_distancia = escala_actual / radio_maximo
	
	# 2. SISTEMA DE MAPA DE CALOR (Rojo -> Amarillo -> Verde)
	var color_actual = Color(1, 1, 1) 
	
	if porcentaje_distancia < 0.33:
		color_actual = Color(0.8, 0.1, 0.1) # Rojo (Fuerte)
	elif porcentaje_distancia < 0.66:
		color_actual = Color(0.8, 0.8, 0.1) # Amarillo (Promedio)
	else:
		color_actual = Color(0.1, 0.8, 0.1) # Verde (Débil)
	
	# 3. Calcular el desvanecimiento y aplicarlo
	var porcentaje_vida = 1.0 - porcentaje_distancia
	if porcentaje_vida < 0.0: porcentaje_vida = 0.0
	color_actual.a = porcentaje_vida 
	
	if material_onda:
		material_onda.albedo_color = color_actual
		
	# 4. Reiniciar el bucle
	if escala_actual >= radio_maximo:
		escala_actual = 0.1
