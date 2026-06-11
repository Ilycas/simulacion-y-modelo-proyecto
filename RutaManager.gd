extends Node

var _rutas: Dictionary = {}
var _marker_nombres: Array[String] = []

signal rutas_listas

func _ready() -> void:
	pass

func registrar_rutas_existentes() -> void:
	var scene = get_tree().current_scene
	if not scene:
		push_error("RutaManager: current_scene es null")
		return

	var nodes: Array[Node] = scene.get_tree().get_nodes_in_group("destino")
	_marker_nombres.clear()
	for n in nodes:
		if n is Marker3D:
			_marker_nombres.append(n.name)

	if _marker_nombres.is_empty():
		push_error("RutaManager: No hay markers en grupo 'destino'")
		return

	_rutas.clear()

	var carpeta_rutas = scene.get_node_or_null("Rutas")
	if carpeta_rutas == null:
		push_error("RutaManager: No se encontro nodo 'Rutas' en la escena")
		return

	for child in carpeta_rutas.get_children():
		if child is Path3D:
			_rutas[child.name] = child

	print("RutaManager: %d rutas cargadas" % _rutas.size())
	for clave in _rutas.keys():
		print("  - %s" % clave)

	emit_signal("rutas_listas")

func obtener_ruta(origen_nombre: String, destino_nombre: String) -> Path3D:
	var clave = "%s->%s" % [origen_nombre, destino_nombre]
	return _rutas.get(clave, null)

func obtener_destinos_desde(origen_nombre: String) -> Array[String]:
	var destinos: Array[String] = []
	for nombre in _marker_nombres:
		if nombre == origen_nombre:
			continue
		if _rutas.has("%s->%s" % [origen_nombre, nombre]):
			destinos.append(nombre)
	return destinos

func obtener_cadena_rutas(origen: String, destino: String) -> Array[String]:
	if origen == destino:
		return []
	if _rutas.has("%s->%s" % [origen, destino]):
		return ["%s->%s" % [origen, destino]]
	if _rutas.has("%s->Entrada" % [origen]) and _rutas.has("Entrada->%s" % [destino]):
		return ["%s->Entrada" % [origen], "Entrada->%s" % [destino]]
	return []

func obtener_destino_de_ruta(nombre_ruta: String) -> String:
	if nombre_ruta.is_empty():
		return ""
	var partes = nombre_ruta.split("->")
	if partes.size() == 2:
		return partes[1]
	return ""

func obtener_origen_de_ruta(nombre_ruta: String) -> String:
	var partes = nombre_ruta.split("->")
	if partes.size() == 2:
		return partes[0]
	return ""

func obtener_todos_los_nombres() -> Array[String]:
	return _marker_nombres
