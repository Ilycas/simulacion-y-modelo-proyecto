extends MeshInstance3D

@export var nodo_modem : Node3D
@export var nodo_repetidor : Node3D
@export var grosor_cable : float = 0.05

var material_enlace : StandardMaterial3D

func _ready() -> void:
	if mesh is BoxMesh:
		mesh.size = Vector3(grosor_cable, grosor_cable, 1.0)
	
	material_enlace = StandardMaterial3D.new()
	material_enlace.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	var color_cable = Color(0.0, 1.0, 0.4, 0.6) 
	material_enlace.albedo_color = color_cable
	material_enlace.emission_enabled = true
	material_enlace.emission = color_cable
	material_enlace.emission_energy_multiplier = 1.5
	
	self.material_override = material_enlace

func _process(_delta: float) -> void:
	if is_instance_valid(nodo_modem) and is_instance_valid(nodo_repetidor):
		var punto_A = nodo_modem.global_position + Vector3(0, 0.5, 0)
		var punto_B = nodo_repetidor.global_position + Vector3(0, 0.5, 0)
		
		global_position = punto_A.lerp(punto_B, 0.5)
		look_at(punto_B, Vector3.UP)
		
		var distancia_real = punto_A.distance_to(punto_B)
		scale.z = distancia_real
