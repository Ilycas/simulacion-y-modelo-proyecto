# PROYECTO: Simulación Escolar 3D con NPCs Autónomos — Estado Completo

## CONTEXTO
- Godot 4.6, Jolt Physics, GL Compatibility renderer
- Working dir: `C:\Users\Juan\Desktop\simulacion-y-modelo-proyecto\simulacion-y-modelo-proyecto\`
- Escena principal: `escuela.tscn` (uid `uid://dlf5sdhwkuqdn`)
- Idioma del usuario: español (responder en español)

## OBJETIVO
NPCs autónomos 3D en escuela con `NavigationAgent3D`. 10–15 móviles (CharacterBody3D) + 45–55 estáticos (Node3D). Móviles navegan entre 7 marcadores, esperan 2s, repiten. Estáticos fijos. Color por zona de señal (verde/amarillo/rojo según distancia al Router).

## RESTRICCIONES DECIDIDAS
- Velocidad móvil: 5.0 m/s (NO cambiar)
- `avoidance_enabled = false`
- `tiempo_espera_en_destino = 2.0` fijo
- Spawner por código (no PackedScene pre-instanciado)
- Color por zona al spawn (NO dinámico, fijo)
- Marcadores: `Entrada`, `Patio`, `Banos`, `AulaCentral`, `BloqueOeste`, `BloqueSur`, `BloqueBaños`
- Cada Marker3D tiene hijo Area3D + CollisionShape3D con SphereShape3D (radio 1.0) para detección de ocupación
- Móvil espera fuera si marker ocupado (queue via `_marker_ocupado()`)
- Móvil visita los 7 en orden aleatorio, reinicia ciclo al completar
- NO eliminar WASD del jugador (es testing)
- Grupo `"destino"` en markers para que spawner los encuentre
- `radio_cobertura = 50.0` para NPCs (el del jugador sigue en 12.0)
- Spawn offset: móviles ±2.0m, estáticos ±3.0m
- y_spawn = 0.4 (centro de cápsula sobre NavMesh a y=-0.5)
- Cada móvil lleva cono naranja brillante encima (IndicadorMovimiento: CylinderMesh top_radius=0, bottom_radius=0.25, height=0.5, posición y=1.6, emission activada)
- Cono visible solo cuando `not esperando`
- Al moverse, crea esfera magenta brillante en pies cada 0.3s (rastro), se desvanece en 4s vía tween de albedo_color.a
- `NavigationServer3D.set_debug_enabled(true)` para ver NavMesh y paths

## FASES COMPLETADAS

### FASE 1: NavRegion + Pisos_Nav (1.0 + 1.5)
- `NavigationRegion3D` añadido a escuela.tscn con `NavigationMesh_fase1`:
  - `cell_size=0.25, cell_height=0.25, agent_radius=0.4, agent_height=1.8, agent_max_climb=0.3, agent_max_slope=45.0`
  - `geometry_parsed_geometry_type=2` (BOTH), `geometry_source_geometry_mode=1` (GROUPS_WITH_CHILDREN)
  - `geometry_source_group_name=&"navigation_mesh_source_group"`
- Piso_Pasillo1, Piso_Pasillo2: CSGBox3D directos en grupo
- Piso_Patio (-18.94, -0.55, 21.90) size 80.57×0.1×65.20
- Piso_Banos_Ninios (-45.70, -0.55, -15.25) size 11.13×0.1×9.76
- Piso_Banos_Adolescentes (26.38, -0.55, 41.12) size 9.79×0.1×10.79
- Piso_Aulas_Central (36.48, -0.55, -2.86) size 10.44×0.1×99.01
- Piso_Aulas_Oeste (48.06, -0.55, 0.65) size 12.82×0.1×106.02
- Piso_Aulas_Sur (-10.16, -0.55, -36.23) size 83.64×0.1×32.30
- Piso_Pasillo_Bloque_Oeste (32.14, -0.55, 50.65) rotación 90° Y, size 8.08×0.1×21.72
- Todos `visible=false, cast_shadow=false`, en grupo `navigation_mesh_source_group`
- Bake verificado: malla continua, aulas conectan a pasillos por puertas

### FASE 2: 7 Marker3D
- `Destinos` (Node3D, unique_id=3000000020)
- Cada Marker3D en grupo `"destino"` con hijo Area3D → CollisionShape3D (SphereShape3D radio 1.0)
- Posiciones iniciales (usuario las ajustó manualmente después):
  - Entrada (-9.28, 0, -20.08), Patio (-18.94, 0, 21.90), Banos (-45.70, 0, -15.25)
  - AulaCentral (36.48, 0, -2.86), BloqueOeste (48.06, 0, 0.65)
  - BloqueSur (-10.16, 0, -36.23), BloqueBaños (26.38, 0, 41.12)
- `SphereShape3D_destino` (sub_resource, radio 1.0)

### FASE 3: Scripts + Spawner
Archivos creados:
- `estudiante_estatico.gd` (extends Node3D): cápsula coloreada, no se mueve
- `estudiante_movil.gd` (extends CharacterBody3D): navega con NavigationAgent3D
- `spawner.gd` (extends Node3D): instancia 12 móviles + 48 estáticos en `_ready()`

Nodo añadido a escuela.tscn:
- `Spawner` (Node3D, unique_id=3000000050) con `script = ExtResource("13_spawner")`

## ESTADO ACTUAL (FASE 4 EN PROGRESO)

### Bug 1 (resuelto): "Invalid assignment of property 'todos_los_markers' with value of type 'Array[Node]'"
- `get_nodes_in_group()` devuelve `Array[Node]`, no se puede asignar a `Array[Marker3D]`
- Fix: `var markers_tipados: Array[Marker3D] = []; markers_tipados.assign(markers); est.todos_los_markers = markers_tipados`

### Bug 2 (resuelto): "Identifier 'ConeMesh' not declared"
- `ConeMesh` no existe en Godot 4.6
- Fix: usar `CylinderMesh` con `top_radius = 0`

### Bug 3 (resuelto): "tweened property 'modulate:a' does not exist"
- `MeshInstance3D` no tiene `modulate` (es de CanvasItem)
- Fix: tween sobre `mat.albedo_color` con `mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA`

### Issues de movimiento (RESUELTOS)
- Causa raíz: usar `global_position +=` en vez de `velocity + move_and_slide()`
- Fix: `velocity = direccion * velocidad; move_and_slide()` — CharacterBody3D requiere move_and_slide() para physics
- Fix adicional: `_trail_timer` ahora se incrementa y el rastro magenta se crea cada 0.3s (antes se creaba en cada frame ~60fps)
- Los Area3D de los marcadores ahora detectan overlaps correctamente (ocupación funcional)

### Auto-route a mejor router (IMPLEMENTADO)
- `lista_routers: Array[Node3D]` en ambos tipos de NPC
- `_actualizar_conexion()` escanea todos los routers cada 0.5s (móviles) o una vez (estáticos)
- Color dinámico: verde (>0.6 calidad), amarillo (0.25–0.6), rojo (<0.25), gris (sin cobertura)
- `router_conectado` y `calidad_red_actual` accesibles para consulta externa
- Spawner busca routers por nombre "Router" en hijos de Escena
- Compatible con múltiples routers (cuando se agreguen)

## ARCHIVOS FINALES (estado al cierre)

### escuela.tscn (nodos clave)
ext_resource type="Script" path="res://spawner.gd" id="13_spawner"
sub_resource type="SphereShape3D" id="SphereShape3D_destino" radius=1.0
sub_resource type="NavigationMesh" id="NavigationMesh_fase1" ... (ver arriba)
Escuela/
├── Pisos_Nav/
│   ├── Piso_Patio, Piso_Banos_Ninios, Piso_Banos_Adolescentes
│   ├── Piso_Aulas_Central, Piso_Aulas_Oeste, Piso_Aulas_Sur
│   └── Piso_Pasillo_Bloque_Oeste
├── Destinos/
│   ├── Entrada, Patio, Banos, AulaCentral, BloqueOeste, BloqueSur, BloqueBaños
│   │   (cada uno con Area3D → CollisionShape3D con SphereShape3D_destino)
├── NavigationRegion3D
└── Spawner (script: spawner.gd)

### estudiante_estatico.gd
```gdscript
extends Node3D
var color_zona: Color = Color.WHITE
func _ready() -> void: _aplicar_color()
func _aplicar_color() -> void:
    var mesh = get_node_or_null("MeshInstance3D")
    if mesh: mat.albedo_color = color_zona; mesh.material_override = mat
func asignar_color_por_zona(posicion, router, radio=50.0) -> void:
    # verde <20m, amarillo <37.5m, rojo >=37.5m o sin router
    # llama _aplicar_color() si is_inside_tree()
estudiante_movil.gd (versión actual, FASE 4)
extends CharacterBody3D
@export var velocidad: float = 5.0
@export var tiempo_espera_en_destino: float = 2.0
var color_zona, marker_actual, esperando, tiempo_espera_restante
var todos_los_markers: Array[Marker3D] = []
var markers_visitados: Array[Marker3D] = []
var _debug_timer, _trail_timer

@onready var nav_agent = $NavigationAgent3D

func _ready() -> void:
    nav_agent.path_desired_distance=0.3; target_desired_distance=0.5
    avoidance_enabled=false; radius=0.4; height=1.8; path_max_distance=50.0
    _aplicar_color()
    for i in 10: await get_tree().physics_frame
    _elegir_siguiente_destino()

func _elegir_siguiente_destino() -> void:
    # filtra no visitados y no ocupados
    # si disponibles vacío: await 1s, retry
    # elige uno random, set target_position, print destino

func _marker_ocupado(marker) -> bool:
    var area = marker.get_node_or_null("Area3D")
    return area and area.get_overlapping_bodies().size() > 0

func _crear_marca_rastro() -> void:
    # SphereMesh radio 0.1, material magenta con emission
    # TRANSPARENCY_ALPHA, posición en pies, tween albedo_color a 0 en 4s

func _physics_process(delta) -> void:
    # actualiza indicador.visible = not esperando
    # crea rastro cada 0.3s si not esperando
    # debug print cada 2s con pos, path_size, esperando
    # si esperando: decrementa timer, si 0 elige nuevo destino
    # si marker_actual null: elige destino
    # calcula destino = marker.global_position con y=actual
    # si distancia < 0.5: llegó, esperando=true
    # punto = destino o nav_agent.get_next_path_position() si path disponible
    # global_position += direccion.normalized() * velocidad * delta
spawner.gd (versión actual)
extends Node3D
@export var num_moviles: int = 12
@export var num_estaticos: int = 48
@export var radio_cobertura: float = 50.0
@export var y_spawn: float = 0.4

func _ready() -> void:
    NavigationServer3D.set_debug_enabled(true)  # debug visual
    var markers = get_tree().get_nodes_in_group("destino")
    var router = get_node_or_null("../Router")
    for i in num_moviles: _spawn_movil(markers, router)
    for i in num_estaticos: _spawn_estatico(markers, router)

func _spawn_movil(markers, router) -> void:
    # CharacterBody3D
    # MeshInstance3D con CapsuleMesh(h=1.8, r=0.4)
    # CollisionShape3D con CapsuleShape3D(h=1.8, r=0.4)
    # NavigationAgent3D
    # IndicadorMovimiento: MeshInstance3D con CylinderMesh(top=0, bottom=0.25, h=0.5)
    #   posición y=1.6, material naranja con emission_energy=2.0
    # set_script(load("res://estudiante_movil.gd"))
    # pos = marker.global + random(-2,2) en xz, y=y_spawn
    # markers_tipados.assign(markers)
    # asignar_color_por_zona(pos, router, radio_cobertura)
    # add_child(est)

func _spawn_estatico(markers, router) -> void:
    # Node3D
    # MeshInstance3D con CapsuleMesh(h=1.8, r=0.4)
    # set_script(load("res://estudiante_estatico.gd"))
    # pos = marker.global + random(-3,3) en xz, y=y_spawn
    # asignar_color_por_zona(pos, router, radio_cobertura)
    # add_child(est)
PENDIENTE / SIGUIENTE PASO (FASE 4)
1. Usuario prueba con Play y revisa consola
2. Verificar prints: [#XXX] pos=... path_size=N esperando=...
- Si path_size=0 constantemente: problema con NavAgent → verificar NavMesh bake
- Si path_size>0 y pos cambia: funciona, solo es percepción visual
3. Si NO se mueve:
- Verificar que el destino no esté en marker_ocupado (queue infinito)
- Verificar que el marker tiene Area3D funcional
- Considerar usar move_and_slide() en vez de global_position += (puede que physics esté bloqueando)
4. Si SÍ se mueve pero no se ve:
- Mover jugador con WASD más cerca de la acción
- El rastro magenta debería hacerlo obvio
DECISIONES PENDIENTES / NO IMPLEMENTADAS
- Congestion-aware routing (los NPCs ya tienen `router_conectado` y `calidad_red_actual`)
- Save/load de posiciones
- Limpiar WASD de estudiante.gd del jugador (decidido: dejarlo por testing)
- Quitar el SPACE→packet (decidido: dejarlo por testing)
- Pasar los NPCs a grupo para que router/antena los detecte

---
