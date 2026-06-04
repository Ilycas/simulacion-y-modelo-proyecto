extends MeshInstance3D

@export var radio_maximo: float = 12.0
@export var tiempo_expansion: float = 2.0
@export var grosor_onda: float = 0.5
@export var retraso_inicio: float = 0.0 # <-- NUEVO: Para que las multi-ondas no salgan al mismo tiempo

func _ready() -> void:
	# Duplicamos el material para que cada onda tenga su propio ciclo de color
	if material_override:
		material_override = material_override.duplicate()
	
	# Si configuraste un retraso, la onda espera antes de empezar a latir
	if retraso_inicio > 0:
		await get_tree().create_timer(retraso_inicio).timeout
		
	animar_onda()

func animar_onda() -> void:
	scale = Vector3(0.1, grosor_onda, 0.1)
	
	var mat = material_override as StandardMaterial3D
	if mat:
		# 1. Nace fuerte: Verde puro y totalmente opaco (Alpha 1.0)
		mat.albedo_color = Color(1.0, 0.0, 0.0, 0.392) 
		
	var tween = get_tree().create_tween()
	tween.set_parallel(true) 
	
	tween.tween_property(self, "scale", Vector3(radio_maximo, grosor_onda, radio_maximo), tiempo_expansion)
	
	if mat:
		# 2. Muere débil: Rojo puro y totalmente transparente (Alpha 0.0)
		var color_final = Color(0.0, 1.0, 0.0, 0.0)
		tween.tween_property(mat, "albedo_color", color_final, tiempo_expansion).set_ease(Tween.EASE_OUT)
	
	tween.chain().tween_callback(animar_onda)
