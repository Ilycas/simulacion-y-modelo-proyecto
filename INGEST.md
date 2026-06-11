# INGEST — Simulación Escolar 3D con WiFi (Godot 4.6)

## 1. Overview

3D school simulation where autonomous NPCs navigate between 7 destinations. NPCs change color based on WiFi signal quality from routers. Built in **Godot 4.6** with **Jolt Physics** and **GL Compatibility** renderer.

- **60 NPCs total**: 12 mobile (CharacterBody3D) + 48 static (Node3D)
- **7 destinations**: Entrance, Patio, Restrooms, Central Classroom, West Block, South Block, Restroom Block
- **Navigation**: Path3D-based fixed routes (replaced NavMesh system)
- **WiFi simulation**: NPCs scan routers, color changes by signal quality

---

## 2. File Structure

```
├── escuela.tscn              # Main scene (school layout)
├── estudiante_movil.gd       # Mobile NPC script (CharacterBody3D)
├── estudiante_estatico.gd    # Static NPC script (Node3D)
├── spawner.gd                # Spawns all NPCs at runtime
├── RutaManager.gd            # Autoload: route registry & lookup
├── antena_principal.gd       # WiFi antenna logic
├── onda_wifi.gd              # WiFi wave visualization
├── router.gd                 # Router node logic
├── estudiante.gd             # Player character (WASD control)
├── paquete.gd                # Packet delivery item
├── Bloque_sur.tscn           # South building (CSGCombiner3D)
├── bloque_oeste.tscn         # West building
├── bloque_central.tscn       # Central building
├── bloque_banos_patio.tscn   # Patio restrooms
├── baños_adolescentes.tscn   # Adolescent restrooms
├── bloque_patio.tscn         # Patio block
├── paquete.tscn              # Packet scene
├── Puerta_Baño.tscn          # Bathroom door
└── project.godot             # Project config
```

---

## 3. Architecture

### 3.1 Autoload Singleton

**RutaManager** (`RutaManager.gd`) — registered in `project.godot` as autoload. Central route registry.

### 3.2 Scene Tree (escuela.tscn)

```
Escuela/
├── Pisos_Nav/                    # Invisible floor meshes for NavMesh (legacy)
│   ├── Piso_Patio
│   ├── Piso_Banos_Ninios
│   ├── Piso_Banos_Adolescentes
│   ├── Piso_Aulas_Central
│   ├── Piso_Aulas_Oeste
│   ├── Piso_Aulas_Sur
│   └── Piso_Pasillo_Bloque_Oeste
├── Destinos/                     # 7 Marker3D nodes (group: "destino")
│   ├── Entrada
│   ├── Patio
│   ├── Banos
│   ├── AulaCentral
│   ├── BloqueOeste
│   ├── BloqueSur
│   └── BloqueBaños
├── Rutas/                        # Path3D nodes (one per origin→destination pair)
│   ├── Entrada->Patio
│   ├── Patio->Banos
│   └── ... (all directed pairs)
├── NavigationRegion3D            # Legacy NavMesh (not used for movement now)
└── Spawner                       # Node3D with spawner.gd
```

### 3.3 Building Geometry

Buildings are **CSGCombiner3D** with `use_collision = true`. Walls, doors, windows are CSG subtraction operations (`operation = 2`). Floor nodes in `Pisos_Nav/` are invisible CSGBox3D in `navigation_mesh_source_group`.

---

## 4. Core Systems

### 4.1 Spawner (`spawner.gd`)

**Config:**
- `num_moviles = 12`, `num_estaticos = 48`
- `radio_cobertura = 50.0`, `y_spawn = 0.4`

**Flow:**
1. `_ready()` → finds all nodes in group `"destino"` and all nodes with "Router" in name
2. `call_deferred("_iniciar_rutas_y_spawn")` → ensures scene is ready
3. Calls `RutaManager.registrar_rutas_existentes()` to load Path3D routes
4. Distributes mobile NPCs evenly across available routes
5. Spawns static NPCs near random markers

**Mobile NPC structure (created by code):**
```
PathFollow3D (loop=false, rotation_mode=4)
└── CharacterBody3D (estudiante_movil.gd)
    ├── MeshInstance3D (CapsuleMesh: h=1.8, r=0.4)
    ├── CollisionShape3D (CapsuleShape3D: h=1.8, r=0.4)
    └── IndicadorMovimiento (CylinderMesh: cone, y=1.6, orange emission)
```

**Static NPC structure:**
```
Node3D (estudiante_estatico.gd)
├── MeshInstance3D (CapsuleMesh: h=1.8, r=0.4)
```

### 4.2 RutaManager (`RutaManager.gd`)

Autoload singleton. Manages predefined Path3D routes.

**Data:**
- `_rutas: Dictionary` — key: `"Origin->Destination"`, value: `Path3D` node
- `_marker_nombres: Array[String]` — names of all destination markers

**Key functions:**
- `registrar_rutas_existentes()` — scans `Rutas/` node for Path3D children, populates `_rutas` dict
- `obtener_ruta(origen, destino) -> Path3D` — returns Path3D for a specific route
- `obtener_destinos_desde(origen) -> Array[String]` — returns all reachable destinations from origin

### 4.3 Mobile NPC (`estudiante_movil.gd`)

**State variables:**
- `marker_actual: Marker3D` — current destination
- `esperando: bool` — waiting at destination
- `tiempo_espera_restante: float` — countdown timer
- `path_follow: PathFollow3D` — parent node controlling progress along Path3D
- `router_conectado: Node3D` — closest router
- `calidad_red_actual: float` — signal quality (0.0–1.0)
- `_destino_anterior: String` — last destination name (for anti-regression)

**Movement logic (`_physics_process`):**
1. If `esperando` → decrement timer → when 0, call `_elegir_siguiente_destino()`
2. If no `path_follow` → try to get parent as PathFollow3D
3. Increment `path_follow.progress += velocidad * delta` (5.0 m/s)
4. When `progress_ratio >= 1.0` → arrived, set `esperando = true`, wait 2.0s
5. Create trail (magenta sphere) every 0.3s while moving
6. Scan WiFi routers every 0.5s

**Route selection (`_elegir_siguiente_destino`):**
1. Get available destinations from `RutaManager.obtener_destinos_desde(_destino_anterior)`
2. Pick random destination
3. Get Path3D from `RutaManager.obtener_ruta()`
4. Create new PathFollow3D, reparent self to new path

**WiFi scanning (`_actualizar_conexion`):**
- Iterates all routers, calculates quality = `1.0 - (dist / radio_cobertura)`
- Color: green (>0.6), yellow (0.25–0.6), red (<0.25), gray (no router)

### 4.4 Static NPC (`estudiante_estatico.gd`)

- Extends `Node3D` (no movement)
- Same WiFi scanning logic as mobile
- Colors by zone at spawn (static, doesn't change)

---

## 5. Destination Markers

7 Marker3D nodes in group `"destino"`. Each has:
- `Area3D` child with `CollisionShape3D` (SphereShape3D, radius=1.0)
- Used for occupancy detection and spawn points

| Name | Approx Position |
|------|----------------|
| Entrada | (-9.28, 0, -20.08) |
| Patio | (-18.94, 0, 21.90) |
| Banos | (-45.70, 0, -15.25) |
| AulaCentral | (36.48, 0, -2.86) |
| BloqueOeste | (48.06, 0, 0.65) |
| BloqueSur | (-10.16, 0, -36.23) |
| BloqueBaños | (26.38, 0, 41.12) |

---

## 6. Configuration Constants

| Parameter | Value | Location |
|-----------|-------|----------|
| NPC speed | 5.0 m/s | `estudiante_movil.gd` |
| Wait time at destination | 2.0s | `estudiante_movil.gd` |
| Coverage radius | 50.0 | `spawner.gd` |
| Spawn Y | 0.4 | `spawner.gd` |
| Trail interval | 0.3s | `estudiante_movil.gd` |
| WiFi scan interval | 0.5s | `estudiante_movil.gd` |
| Debug print interval | 2.0s | `estudiante_movil.gd` |
| Green threshold | >0.6 | WiFi quality |
| Yellow threshold | 0.25–0.6 | WiFi quality |
| Red threshold | <0.25 | WiFi quality |

---

## 7. Key Design Decisions

1. **Path3D over NavMesh**: Original NavMesh caused NPCs to get stuck on walls. Fixed routes (Path3D + PathFollow3D) provide deterministic movement.
2. **Spawner by code**: NPCs created at runtime via `spawner.gd`, not pre-instanced scenes.
3. **Color = WiFi signal**: Static coloring at spawn, dynamic scanning for quality.
4. **Player preserved**: WASD player character kept for testing purposes.
5. **Language**: Spanish (neutral accent, no regionalisms).

---

## 8. Dependencies

- Godot 4.6
- Jolt Physics engine
- GL Compatibility renderer
- No external addons

---

## 9. How to Modify

- **Add routes**: Create Path3D nodes under `Rutas/` in `escuela.tscn`, name format `"Origin->Destination"`
- **Add destinations**: Add Marker3D to `Destinos/` group, add Path3D routes from/to it
- **Adjust NPC count**: Change `num_moviles`/`num_estaticos` exports on Spawner node
- **Add routers**: Add Node3D with "Router" in name to scene root; NPCs auto-detect
- **Change WiFi zones**: Edit thresholds in `_actualizar_conexion()` in both NPC scripts
