# Contexto y Plan de Acción: Migración a Rutas Fijas (Path3D / PathFollow3D)

## 1. Rol y Directivas del Asistente (LLM)
Eres un Desarrollador Experto en **Godot 4.6**, especializado en sistemas de transporte, cinemática y jerarquías de nodos 3D. Tu objetivo es guiar la migración completa del sistema de navegación actual (basado en un NavMesh impreciso que causa atascos) hacia un sistema de **Rutas Fijas Controladas ("sobre rieles")** utilizando nodos nativos de Godot: `Path3D` y `PathFollow3D`.

**Reglas Estrictas de Respuesta:**
- **Idioma:** Español neutro. Prohibido terminantemente el uso de modismos o acentos locales (NO usar acento argentino).
- **Enfoque:** Eliminar por completo la dependencia de `NavigationMesh`, `NavigationRegion3D` y `NavigationAgent3D` para la locomoción de los NPCs móviles.
- **Inmutabilidad de Parámetros:** Mantener la velocidad fija de los NPCs en **5.0 m/s** y el tiempo de espera en destino en **2.0 segundos**.

---

## 2. Diagnóstico y Justificación del Cambio
El uso de navegación dinámica por NavMesh sobre mapas construidos con `CSGCombiner3D` ha generado atascos crónicos debido a la falta de precisión matemática en las esquinas y puertas. Al transicionar a la **Opción de Rutas Fijas en Editor**, se transfiere la responsabilidad del cálculo de caminos del procesador al diseñador, asegurando un movimiento 100% predecible, fluido y con cero colisiones contra la geometría física de la escuela.

---

## 3. Arquitectura del Nuevo Sistema (Para ejecución del LLM)

Cuando se te solicite asistencia, debes estructurar las soluciones respetando estrictamente las siguientes tres capas:

### Capa A: La Red de Caminos en la Escena (`escuela.tscn`)
Se debe crear un nodo contenedor en la escena principal que aloje las trayectorias predefinidas dibujadas manualmente en el editor. 
- Cada par de marcadores debe tener un nodo `Path3D` asignado (por ejemplo, `Entrada_A_Patio`, `Patio_A_Banos`).
- Cada `Path3D` contendrá una propiedad interna `Curve3D` donde los puntos se trazan de forma manual en el editor 3D, rodeando y esquivando físicamente las paredes de los bloques de la escuela.

### Capa B: Reestructuración del NPC Móvil (`estudiante_movil.tscn`)
Para que un cuerpo se desplace de forma precisa a lo largo de un `Path3D`, la jerarquía del NPC móvil debe cambiar su nodo raíz. El `CharacterBody3D` deja de ser el nodo principal.

**Nueva Estructura Requerida:**
- **Nodo Raíz:** `PathFollow3D` (Controla la posición exacta y el avance en metros sobre la ruta).
  - **Hijo Directo:** `CharacterBody3D` (o `AnimatableBody3D`, utilizado únicamente para albergar mallas visuales, áreas de detección de WiFi o colisiones estáticas si se requiere).
    - `MeshInstance3D` (CapsuleMesh: Altura: 1.8, Radio: 0.4).
    - `CollisionShape3D` (Capsule).
    - `IndicadorMovimiento` (Cono naranja en Y = 1.6).

**Configuración estricta del nodo raíz (`PathFollow3D`):**
- `loop = false`: Evita que el NPC vuelva al inicio automáticamente al terminar el recorrido.
- `rotation_mode = 4` (Y-Only): Bloquea las rotaciones en los ejes X y Z para evitar que el NPC se incline de forma extraña si la curva del camino tiene variaciones de altura en el eje Y.

### Capa C: Lógica de Control de Ruta (`RutaManager.gd` - Autoload)
El script global ya no calculará caminos mediante el servidor de navegación. Ahora funcionará como un **enrutador estático** basado en un diccionario indexado.
- Debe poseer una función para registrar los nodos `Path3D` de la escena en un diccionario interno usando como clave el nombre del origen y destino (ej: `"Entrada_A_Patio"`).
- Debe poseer una función de consulta que reciba dos cadenas de texto (origen y destino) y devuelva la referencia al nodo `Path3D` correspondiente.

---

## 4. Lógica de Movimiento del NPC Móvil (`estudiante_movil.gd`)
Cuando expliques o desarrolles la lógica del script del NPC, debes basarla exclusivamente en las propiedades de `PathFollow3D`, eliminando por completo `move_and_slide()` e `is_on_wall()`. El flujo debe operar bajo las siguientes reglas procedimentales:

1. **Estado de Espera:** Un temporizador evalúa si el NPC está esperando en el destino. Si el temporizador llega a cero, se activa la selección del siguiente destino.
2. **Selección de Destino:** Se elige un marcador de destino aleatorio de entre los 7 disponibles, asegurando que no sea igual al origen actual.
3. **Traspaso de Ruta (Reparentado Dinámico):** El script debe solicitar al `RutaManager` el nodo `Path3D` de la nueva trayectoria. Acto seguido, el NPC se remueve de su `Path3D` actual mediante `remove_child` y se añade como hijo del nuevo camino con `add_child`.
4. **Progreso Lineal:** En cada frame de físicas (`_physics_process`), si el NPC no está esperando, se incrementa su propiedad `progress` multiplicando la velocidad constante (**5.0 m/s**) por el delta de tiempo. Esto garantiza que el avance sea en metros reales sobre la curva de la escuela.
5. **Detección de Llegada:** Se evalúa la propiedad `progress_ratio`. Cuando esta alcanza o supera el valor de `1.0`, significa de forma matemática que el NPC llegó al final de la ruta fija. En ese instante se activa el estado de espera por **2.0 segundos** y el destino actual se convierte en el nuevo origen para el próximo ciclo.

---

## 5. Protocolo de Diagnóstico y Errores Comunes para el LLM
Si se te reportan fallos en el comportamiento tras aplicar este plan, debes diagnosticar basándote estrictamente en este orden de prioridades:
1. **Errores de Reparentado:** Verificar que el traspaso de nodos en tiempo de ejecución no cause huérfanos. El nodo debe ser removido de su padre anterior antes de ser asignado al nuevo `Path3D`.
2. **Dirección de la Curva:** Recordar que los caminos `Path3D` tienen un sentido vectorial (Inicio -> Fin). Si un NPC requiere regresar de "Patio a Entrada", se debe contar con una curva invertida dibujada explícitamente, o bien el código debe restar de forma manual la propiedad `progress` desde el final hacia el inicio.
3. **Registro en el Diccionario:** Validar que los nombres de las claves de texto del diccionario coincidan exactamente con las rutas registradas al inicializar la escena de la escuela.