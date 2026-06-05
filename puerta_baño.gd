extends Node3D
@onready var animacion_puerta: AnimationPlayer = $Animacion_Puerta


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		animacion_puerta.play("Abrir")


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		animacion_puerta.play("Cerrar")
