extends MeshInstance3D

@export var nodo_origen : Node3D   
@export var nodo_destino : Node3D  
@export var grosor_cable : float = 0.08

var material_enlace : StandardMaterial3D

func _ready() -> void:
	if mesh is BoxMesh:
		mesh.size = Vector3(grosor_cable, grosor_cable, 1.0) 
	
	material_enlace = StandardMaterial3D.new()
	material_enlace.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	var color_laser = Color(0.0, 0.8, 1.0, 0.6) 
	material_enlace.albedo_color = color_laser
	material_enlace.emission_enabled = true
	material_enlace.emission = color_laser
	material_enlace.emission_energy_multiplier = 2.0
	
	self.material_override = material_enlace

func _process(_delta: float) -> void:
	if is_instance_valid(nodo_origen) and is_instance_valid(nodo_destino):
		var punto_A = nodo_origen.global_position + Vector3(0, 4.5, 0)
		var punto_B = nodo_destino.global_position + Vector3(0, 0.5, 0)
		
		global_position = punto_A.lerp(punto_B, 0.5)
		look_at(punto_B, Vector3.UP)
		
		var distancia_real = punto_A.distance_to(punto_B)
		scale.z = distancia_real
