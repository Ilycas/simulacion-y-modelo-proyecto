extends CanvasLayer

@export var antena_principal : Node3D

@onready var slider = $Panel/HSlider
@onready var label = $Panel/Label

func _ready() -> void:
	if is_instance_valid(slider):
		slider.min_value = 0.0
		slider.max_value = 500.0
		slider.value = 500.0
		slider.value_changed.connect(_on_slider_value_changed)
		
	if is_instance_valid(label):
		label.text = "Ancho de Banda Global: 500 Mbps"

func _on_slider_value_changed(value: float) -> void:
	if is_instance_valid(antena_principal):
		antena_principal.ancho_banda_entrada = value
	if is_instance_valid(label):
		label.text = "Ancho de Banda Global: " + str(int(value)) + " Mbps"
