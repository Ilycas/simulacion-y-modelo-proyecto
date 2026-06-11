# Contexto del Proyecto: Simulación de Escuela 3D con WiFi

## Resumen General

Juego/simulación en **Godot 4.6** con **Jolt Physics** y renderer **GL Compatibility** donde 60 NPCs (12 móviles + 48 estáticos) navegan por una escuela 3D con 7 marcadores de destino. Los NPCs escanean dinámicamente routers WiFi y cambian de color según la calidad de señal. **El problema principal es que los NPCs móviles se quedan atascados contra las paredes** al navegar entre destinos.

---

## Estructura del Proyecto

```
simulacion-y-modelo-proyecto/
├── escuela.tscn                    # Escena principal
├── estudiante_movil.gd             # Script NPC móvil (CharacterBody3D)
├── estudiante_estatico.gd          # Script NPC estático (Node3D)
├── spawner.gd                      # Generador de NPCs por código
├── RutaManager.gd                  # Autoload: genera waypoints predefinidos
├── estudiante.gd                   # NPC player (no relevante)
├── antena_principal.gd             # Antena WiFi
├── onda_wifi.gd                    # Visualización de ondas
├── Bloque_sur.tscn                 # Edificio bloque sur
├── bloque_oeste.tscn               # Edificio bloque oeste
├── bloque_central.tscn             # Edificio bloque central
├── bloque_banos_patio.tscn         # Baños del patio
├── baños_adolescentes.tscn         # Baños adolescentes
├── bloque_patio.tscn               # Bloque del patio
├── paquete.tscn                    # Paquete para el player
├── Puerta_Baño.tscn                # Puerta de baño
└── project.godot                   # Configuración del proyecto
```

---

## Configuración del Proyecto (project.godot)

- **Motor**: Godot 4.6
- **Físicas**: Jolt Physics
- **Renderer**: GL Compatibility
- **Autoloads**: `RutaManager` (res://RutaManager.gd)
- **Grupos**: `destino` (Marker3D), `navigation_mesh_source_group` (edificios/pisos)

---

## Configuración del NavMesh (escuela.tscn)

### Sub-resource NavigationMesh_fase1 (ACTUALIZADO)

```ini
[sub_resource type="NavigationMesh" id="NavigationMesh_fase1"]
geometry_source_geometry_mode = 1          # SCENE_ROOTS
geometry_parsed_geometry_type = 2          # PARSED_MESH + PARSED_COLLIDERS
cell_size = 0.5
cell_height = 0.5
agent_height = 1.8
agent_radius = 0.5
agent_max_climb = 0.3
agent_max_slope = 45.0
```

### Configuración anterior (PRE-VUELTA ATRÁS)

```ini
vertices = PackedVector3Array(-51.725, -0.0802449, -51.879997, ...)  # 10 puntos
polygons = [PackedInt32Array(1, 0, 2), ...]                          # 8 triángulos
geometry_source_geometry_mode = 1
agent_height = 1.8
agent_radius = 0.5
agent_max_climb = 0.3
# SIN cell_size, cell_height, geometry_parsed_geometry_type
```

**Problema**: Solo 8 triángulos para toda la escuela (~112x106 unidades). Las paredes, pasillos y puertas NO están representadas en el NavMesh.

### Nodos en navigation_mesh_source_group

1. `Bloque_sur` (instancia)
2. `Bloque_Oeste` (instancia)
3. `Bloque_Central` (instancia)
4. `Baños_Niño_Niña` (instancia)
5. `Baños_Adolescentes` (instancia)
6. `Bloque_Patio` (instancia)
7. `Piso_Pasillo1` (CSGBox3D)
8. `Piso_Pasillo2` (CSGBox3D)
9. `Piso_Patio` (CSGBox3D bajo Pisos_Nav)
10. `Piso_Banos_Ninios` (CSGBox3D bajo Pisos_Nav)
11. `Piso_Banos_Adolescentes` (CSGBox3D bajo Pisos_Nav)
12. `Piso_Aulas_Central` (CSGBox3D bajo Pisos_Nav)
13. `Piso_Aulas_Oeste` (CSGBox3D bajo Pisos_Nav)
14. `Piso_Aulas_Sur` (CSGBox3D bajo Pisos_Nav)
15. `Piso_Pasillo_Bloque_Oeste` (CSGBox3D bajo Pisos_Nav)

---

## Estructura de los Edificios (Ejemplo: Bloque_sur.tscn)

Los edificios son **CSGCombiner3D** con `use_collision = true`:

```
Bloque_Sur (CSGCombiner3D, use_collision=true)
├── Pared_Madera_Sur_1 (StaticBody3D) → CollisionShape3D (BoxShape3D)
├── Pared_Madera_Sur_2 (StaticBody3D) → CollisionShape3D (BoxShape3D)
├── Pared_Madera_Sur_3 (StaticBody3D) → CollisionShape3D (BoxShape3D)
├── Pared_Madera_Sur_4 (StaticBody3D) → CollisionShape3D (BoxShape3D)
├── Bloque_Sur (CSGBox3D) → base del edificio
│   ├── Recepcion (CSGBox3D, operation=2) → resta CSG
│   ├── Hueco_Aula1 (CSGBox3D, operation=2) → resta CSG
│   ├── Control_estudio (CSGBox3D, operation=2) → resta CSG
│   ├── Hueco_Aula2 (CSGBox3D, operation=2) → resta CSG
│   ├── Hueco_Aula3 (CSGBox3D, operation=2) → resta CSG
│   ├── Hueco_Aula4 (CSGBox3D, operation=2) → resta CSG
│   └── Hueco_Aula5 (CSGBox3D, operation=2) → resta CSG
├── Puerta_recepcion (CSGBox3D, operation=2)
├── Puerta_Aula5 (CSGBox3D, operation=2)
├── Puerta_Aula6 (CSGBox3D, operation=2)
├── Puerta_Control_estudio (CSGBox3D, operation=2)
├── Puerta_Aula1 (CSGBox3D, operation=2)
├── Puerta_Aula2 (CSGBox3D, operation=2)
├── Puerta_Aula3 (CSGBox3D, operation=2)
├── Puerta_Aula4 (CSGBox3D, operation=2)
├── Puerta_Aula7 (CSGBox3D, operation=2)
├── Puerta_recepcion2 (CSGBox3D, operation=2)
└── Ventana1-10 (CSGBox3D, operation=2)
```

**Nota**: `operation = 2` = CSG subtraction (resta de geometría, crea huecos/puertas).

---

## 7 Marcadores de Destino (Marker3D)

| Nombre | Posición (aprox) | Descripción |
|--------|-------------------|-------------|
| Entrada | (23.6, 0, -34.9) | Entrada principal |
| Patio | (11.3, -19.9, 23.9) | Patio interior |
| Banos | (-38.5, 0, -15.3) | Baños generales |
| AulaCentral | (36.5, 0, 15.4) | Aula central |
| BloqueOeste | (50.8, 0, 25.8) | Bloque oeste |
| BloqueSur | (-10.2, 0, -34.4) | Bloque sur |
| BloqueBanos | (25.8, 0.3, 33.1) | Bloque de baños |

Cada Marker3D tiene:
- Hijo `Area3D` con `CollisionShape3D` (SphereShape3D radius=1.0)
- Grupo `destino`

---

## Spawner (spawner.gd)

### Configuración
```gdscript
@export var num_moviles: int = 12
@export var num_estaticos: int = 48
@export var radio_cobertura: float = 50.0
@export var y_spawn: float = 0.4
```

### Flujo
1. `_ready()` → Habilita debug de NavigationServer3D
2. Busca markers en grupo `destino`
3. Busca routers (nodos con "Router" en el nombre)
4. `call_deferred("_iniciar_rutas_y_spawn")` → Asegura que la escena está lista

### NPC Móvil (creado por código)
```
CharacterBody3D
├── MeshInstance3D (CapsuleMesh: height=1.8, radius=0.4)
├── CollisionShape3D (CapsuleShape3D: radius=0.4, height=1.8)
├── NavigationAgent3D
└── IndicadorMovimiento (CylinderMesh: cono naranja en y=1.6)
```

### Spawn Seguro (ACTUALIZADO)
- Usa `NavigationServer3D.map_get_closest_point()` para posicionar en el NavMesh
- Offset aleatorio ±2.0m del marker
- y_spawn = 0.4

### Spawn Anterior (PROBLEMA)
- Solo offset aleatorio sin verificar NavMesh
- Podía colocar NPCs dentro de paredes

---

## NPC Móvil (estudiante_movil.gd)

### Variables de Estado
```gdscript
var velocidad: float = 5.0                    # Velocidad constante
var tiempo_espera_en_destino: float = 2.0     # Espera entre destinos
var marker_actual: Marker3D                   # Destino actual
var esperando: bool                           # Esperando en destino
var markers_visitados: Array[Marker3D]        # Anti-regreso
var _waypoints: Array[Vector3]                # Ruta predefinida
var _waypoint_actual_idx: int                 # Índice actual
var _usando_ruta_predefinida: bool            # Modo waypoints vs NavAgent
var _destino_anterior: String                 # Último destino (anti-regreso)
var _posicion_anterior: Vector3               # Para detectar atasco
var _tiempo_atascado: float                   # Timer de atasco
var _intentos_recuperacion: int               # Intentos de recuperación
```

### Constantes
```gdscript
const WAYPOINT_LLEGADA_RADIO: float = 1.5    # Radio para llegar a waypoint
const WAYPOINT_LOOKAHEAD: float = 2.0        # Lookahead (no usado activamente)
const UMBRAL_ATASCO: float = 0.1             # < 0.1m = atascado
const TIEMPO_ATASCO_MAX: float = 2.0         # 2 segundos para recuperar
const MAX_INTENTOS_RECUPERACION: int = 3      # Max intentos antes de fallback
```

### Configuración NavAgent
```gdscript
nav_agent.path_desired_distance = 0.3
nav_agent.target_desired_distance = 0.5
nav_agent.avoidance_enabled = false
nav_agent.radius = 0.4
nav_agent.height = 1.8
nav_agent.path_max_distance = 50.0
floor_block_on_wall = false
```

### Flujo de Movimiento (_physics_process)

```
1. Si esperando → decrementar timer → elegir siguiente destino
2. Si marker_actual == null → elegir siguiente destino
3. Calcular distancia al destino
4. Si distancia < 0.5 → llegar, esperar 2s
5. Determinar objetivo:
   a. Si usando_ruta_predefinida → siguiente waypoint
   b. Si no → NavAgent.get_next_path_position()
6. Calcular dirección (ignorar Y)
7. Si dirección muy corta → incrementar timer atasco
8. Aplicar velocity = lerp(velocity, dir * speed, 0.3)
9. move_and_slide()
10. Si is_on_wall() → velocity.slide(wall_normal) * 0.8
11. Detectar atasco → recuperar_de_atasco()
```

### Función _recuperar_de_atasco()

```
1. Incrementar intentos_recuperacion
2. Reset timer atasco y velocity
3. Si usando ruta predefinida:
   → Saltar waypoint actual
   → Si no hay más waypoints → fallback NavAgent
4. Si intentos >= MAX_INTENTOS_RECUPERACION:
   → Forzar fallback NavAgent
5. Si no → reintentar ruta (elegir nuevo destino)
```

---

## RutaManager (RutaManager.gd)

### Autoload
- Se registra en `project.godot` como autoload
- Se llama `RutaManager.regenerar_rutas()` desde spawner via `call_deferred`

### Variables
```gdscript
var _rutas: Dictionary = {}          # "Origen->Destino" → [waypoints]
var _markers: Array[Marker3D] = []
var _marker_nombres: Array[String] = []
var _ultimo_destino: Dictionary = {}  # NPC → último destino
```

### Flujo de Generación

```
regenerar_rutas()
→ _generar_rutas()
  → Esperar a que la escena esté lista
  → Buscar NavigationRegion3D
  → Esperar grupo "destino" (máx 30 frames)
  → Para cada par de markers (i → j):
    → map_get_path(origen_pos, destino_pos, optimize=true)
    → _muestrear_waypoints(path)
    → Guardar en _rutas["Origen->Destino"]
```

### Muestreo de Waypoints (_muestrear_waypoints)

```gdscript
var paso = 2.0  # Reducido de 3.0 para waypoints más densos

# Primer waypoint =起点 del path
waypoints.append(path[0])

# Muestrear cada 2.0 unidades a lo largo del path
for segmento in path:
    distancia_acumulada += longitud
    while distancia_acumulada >= paso:
        punto = interpolar(segmento, t)
        waypoints.append(punto)

# Asegurar último waypoint
if waypoints[-1].distance_to(path[-1]) > 0.5:
    waypoints.append(path[-1])  # Fix: usa waypoints[-1].y
```

### Funciones Públicas
```gdscript
obtener_ruta(origen_nombre, destino_nombre, evitar_regreso) → Array[Vector3]
obtener_todos_los_destinos(origen_nombre, evitar) → Array[String]
registrar_ultimo_destino(npc_id, destino)
obtener_ultimo_destino(npc_id) → String
```

---

## NPC Estático (estudiante_estatico.gd)

- Extiende `Node3D` (no CharacterBody3D)
- Solo calcula calidad de señal WiFi y aplica color
- No tiene movimiento
- Misma lógica de escaneo de routers que el móvil

---

## Análisis de Causas Raíz del Atasco

### Problema 1: NavMesh Demasiado Grueso (CRÍTICO)
- Solo 8 triángulos para ~112x106 unidades
- Las paredes, pasillos y puertas NO están representadas
- Los waypoints se generan sobre este NavMesh impreciso
- **Causa**: `geometry_parsed_geometry_type = 0` (default) no parsea colliders de CSG

### Problema 2: Sin Detección de Atasco
- No hay `is_on_wall()` check
- No hay reset de velocidad al chocar
- No hay timeout de recuperación
- Una vez atascado, se queda para siempre

### Problema 3: Waypoints Saltan Esquinas
- Con `paso = 3.0`, el muestreo puede poner waypoints al otro lado de una esquina
- El NPC camina directamente hacia un punto que está detrás de una pared

### Problema 4: Velocidad No Resetea al Chocar
- `velocity.lerp()` acumula velocidad hacia la pared
- `move_and_slide()` resuelve la colisión pero el NPC empuja contra la pared cada frame

### Problema 5: Spawn Dentro de Paredes
- Offset aleatorio ±2m puede colocar NPCs dentro de geometría

---

## Historial de Intentos de Solución

### Intento 1: Aumentar agent_radius (0.4 → 0.5)
- **Resultado**: Margen insuficiente, NPCs siguen atascados

### Intento 2: Cambiar global_position += a move_and_slide()
- **Resultado**: ✅ Fix necesario para que Area3D detecte overlaps y NPCs se muevan físicamente

### Intento 3: Agregar NavigationAgent3D delay (await nav_agent)
- **Resultado**: ❌ NPCs no se movían, revertido

### Intento 4: Cambiar collision layers (NPCs mask=1 → mask=2)
- **Resultado**: ❌ NPCs no se movían, revertido

### Intento 5: RutaManager con waypoints predefinidos
- **Resultado**: ⚠️ Mejora parcial, pero waypoints sobre NavMesh impreciso

### Intento 6: Aumentar WAYPOINT_LLEGADA_RADIO (0.5 → 1.5)
- **Resultado**: ⚠️ Menos atascos en waypoints pero no resuelve paredes

### Intento 7: Agregar floor_block_on_wall = false
- **Resultado**: ⚠️ Previene que paredes se traten como suelo

### Intento 8: NavMesh con buildings en source_group + re-bake
- **Resultado**: ❌ Se revirtió al estado anterior (8 triángulos)

### Intento 9: Configurar geometry_parsed_geometry_type = 2
- **Resultado**: Pendiente de re-bake en Godot

---

## Cambios Implementados (Última Sesión)

### 1. escuela.tscn — NavMesh Config
```diff
- geometry_parsed_geometry_type no estaba (default=0)
+ geometry_parsed_geometry_type = 2  # meshes + colliders
+ cell_size = 0.5
+ cell_height = 0.5
+ agent_max_slope = 45.0
- vertices/polygons hardcodeados (8 triángulos)
+ Eliminados (requiere re-bake)
```

### 2. RutaManager.gd
```diff
- map_get_path(..., false)
+ map_get_path(..., true)  # optimize=true
- paso = 3.0
+ paso = 2.0  # waypoints más densos
- final.y = waypoints[0].y
+ final.y = waypoints[-1].y  # fix Y del último waypoint
```

### 3. estudiante_movil.gd
```diff
+ var _posicion_anterior: Vector3
+ var _tiempo_atascado: float
+ var _intentos_recuperacion: int
+ const UMBRAL_ATASCO = 0.1
+ const TIEMPO_ATASCO_MAX = 2.0
+ const MAX_INTENTOS_RECUPERACION = 3

+ if is_on_wall():
+     var wall_normal = get_wall_normal()
+     velocity = velocity.slide(wall_normal) * 0.8

+ func _recuperar_de_atasco():
+     saltar waypoint → fallback NavAgent → reintentar ruta
```

### 4. spawner.gd
```diff
- var pos = marker.global_position + Vector3(randf_range(-2,2), 0, randf_range(-2,2))
+ pos = NavigationServer3D.map_get_closest_point(map_rid, pos)
+ pos.y = y_spawn
```

---

## Acción Requerida

**RE-BAKEAR EL NAVMESH EN GODOT:**
1. Abrir `escuela.tscn` en el editor Godot
2. Seleccionar nodo `NavigationRegion3D`
3. En Inspector → NavigationMesh:
   - Verificar `geometry_parsed_geometry_type` = **Parsed Meshes + Colliders**
   - Verificar `cell_size` = 0.5
   - Verificar `cell_height` = 0.5
4. Click botón **"Bake Navigation Mesh"**
5. Verificar que el NavMesh tenga huecos para paredes/puertas

---

## Reglas del Proyecto

- **Idioma**: Responder en español
- **Acento**: NO usar acento argentino
- **Velocidad NPC**: 5.0 m/s (fija)
- **avoidance_enabled**: false
- **tiempo_espera_en_destino**: 2.0s
- **Spawner**: Por código (no PackedScene)
- **Colores**: Verde (>0.6), Amarillo (0.25-0.6), Rojo (<0.25)
- **Renderer**: GL Compatibility
- **Físicas**: Jolt Physics
