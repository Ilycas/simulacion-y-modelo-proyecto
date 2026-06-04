extends MeshInstance3D

@export var radio_maximo: float = 12.0 # Debe coincidir con tu radio_cobertura
@export var tiempo_expansion: float = 2.0 # Segundos que tarda en desaparecer
@export var grosor_onda: float = 0.5 # Qué tan alto es el anillo

func _ready() -> void:
	# Asegurarnos de que el material es único para poder animar su transparencia
	if material_override:
		material_override = material_override.duplicate()
	animar_onda()

func animar_onda() -> void:
	# 1. Reiniciar la onda al centro (tamaño pequeño)
	scale = Vector3(0.1, grosor_onda, 0.1)
	
	# 2. Reiniciar la opacidad al 100%
	var mat = material_override as StandardMaterial3D
	if mat:
		mat.albedo_color.a = 1.0 
		
	# 3. Crear el animador (Tween)
	var tween = get_tree().create_tween()
	tween.set_parallel(true) # Hace que el tamaño y la transparencia se animen AL MISMO TIEMPO
	
	# 4. Crecer el anillo hasta el radio máximo
	tween.tween_property(self, "scale", Vector3(radio_maximo, grosor_onda, radio_maximo), tiempo_expansion)
	
	# 5. Desvanecer el anillo a medida que crece (Alpha llega a 0)
	if mat:
		tween.tween_property(mat, "albedo_color:a", 0.0, tiempo_expansion).set_ease(Tween.EASE_OUT)
	
	# 6. Cuando termine la animación, volver a llamarse a sí misma (Bucle infinito)
	tween.chain().tween_callback(animar_onda)
