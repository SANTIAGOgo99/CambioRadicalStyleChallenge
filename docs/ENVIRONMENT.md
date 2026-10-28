# Preparación del entorno

Fecha de revisión: **28 de octubre de 2026**.

## Carpeta y motor verificados

- Proyecto: `C:\Users\LENOVO\Documents\Videojuegos\CambioRadicalStyleChallenge`.
- Archivo de proyecto: `project.godot`, existente antes de la preparación.
- Consola: `C:\Users\LENOVO\Documents\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe`.
- Editor: `C:\Users\LENOVO\Documents\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64.exe`.
- Respuesta de `--version`: `4.7.2.stable.official.ed1daf0bf` en ambos ejecutables.
- No se encontró un comando Godot en PATH; funciona invocándolo por su ruta completa.
- Motor y lenguaje del videojuego: Godot y GDScript exclusivamente.

## Inspección inicial y Git

Se encontraron `project.godot`, `icon.svg`, `icon.svg.import`, `.editorconfig`,
`.gitattributes`, `.gitignore` y la caché `.godot/`.
No había escenas, scripts, documentación original ni instrucciones `AGENTS.md`
aplicables en la ruta inspeccionada.

`git status --short --branch` y `git rev-parse --is-inside-work-tree` confirmaron
que no existe un repositorio Git en esta carpeta ni en sus antecesores.
No se inicializó Git ni se crearon commits. Se conservaron las reglas existentes
que excluyen `.godot/` y `/android/`.

## Configuración de pantalla y escenas

- Resolución de diseño horizontal: **1920 × 1080**.
- Ventana inicial: **1280 × 720**, redimensionable.
- Escalado: `canvas_items`; relación de aspecto: `expand`.
- Orientación móvil configurada como horizontal, sin añadir plataformas de exportación.
- Renderizador: GL Compatibility.
- Escena principal: `res://scenes/main.tscn`, con raíz `Node2D` vacía.
- Interfaz: `CanvasLayer` con un `Control` de anclajes completos y sin elementos visibles.

La interfaz ocupa el área lógica disponible cuando cambia la relación de aspecto.
Los futuros controles deberán utilizar anclajes y contenedores; esta base no define
todavía menús ni HUD. Se retiraron los ajustes iniciales específicos de física 3D y
del controlador D3D12, innecesarios para esta base 2D con GL Compatibility.

Referencias oficiales:
[ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html)
y [comandos del motor](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html).

## Comprobaciones reproducibles

`tests/check_project.ps1` verifica la versión y ejecuta estos pasos con
`--headless --path <carpeta-del-proyecto> --log-file <registro>`:

| Paso | Argumentos adicionales | Resultado |
| --- | --- | --- |
| Importación y carga del editor | `--import` | Correcto |
| Análisis del script de prueba | `--script res://tests/validate_project.gd --check-only` | Correcto |
| Carga de escena e interfaz adaptable | `--script res://tests/validate_project.gd --quit-after 600` | Correcto |
| Arranque de la escena principal | `--quit-after 10` | Correcto |

La prueba de interfaz instancia la escena principal, comprueba la configuración
de pantalla y compara el tamaño y la posición de la raíz de interfaz con el viewport:

| Ventana física | Viewport lógico y tamaño de interfaz |
| --- | --- |
| 1280 × 720 | 1920 × 1080 |
| 1920 × 1080 | 1920 × 1080 |
| 2560 × 1080 | 2560 × 1080 |
| 1280 × 1024 | 1920 × 1536 |

Los cuatro pasos terminaron con código 0, sin errores ni advertencias en sus registros.
El ejecutor también comprueba el marcador de éxito de la prueba GDScript y revisa
los registros: un código 0 por sí solo no basta para considerar correcta la prueba.

Se ejecutó además el editor con ventana mediante `--editor --quit-after 10`.
Terminó con código 0 y sin errores ni advertencias registrados, utilizando
OpenGL 3.3 Compatibility sobre Intel UHD Graphics. El cierre automático es parte
de esta comprobación, no un cierre inesperado del proyecto.

El arranque con ventana de la escena principal también terminó con código 0,
sin errores ni advertencias, con `--quit-after 60 --max-fps 60` y el mismo renderizador.

## Aislamiento de las comprobaciones

El primer intento de importación encontró restricciones para escribir en el AppData
global de Godot. Las comprobaciones posteriores utilizan variables `APPDATA` y
`LOCALAPPDATA` temporales para el proceso, dirigidas a `.godot/tooling/AppData/`.
Con este aislamiento, la importación y las pruebas se completaron correctamente.
El ejecutor restaura las variables al finalizar y no modifica ajustes globales.

Registros finales: `.godot/checks/import.log`, `parse.log`, `layout.log`,
`startup.log`, `editor-window.log` y `runtime-window.log`. La caché y los registros son regenerables.
El archivo `.gd.uid` de la prueba fue generado por Godot y debe conservarse.

## Archivos creados o modificados

- Modificado: `project.godot`.
- Creados: `README.md`, `docs/ENVIRONMENT.md`, `scenes/main.tscn`,
  `scenes/ui/interface.tscn`, `tests/validate_project.gd`,
  `tests/validate_project.gd.uid` y `tests/check_project.ps1`.
- Creados ocho archivos `.gitkeep`: en `scripts/`, `assets/characters/`,
  `assets/backgrounds/`, `assets/ui/`, `assets/audio/`, `animations/`, `data/`
  y `docs/original/`.
- Godot generó caché, configuración aislada y registros bajo `.godot/`.

## Alcance pendiente

El entorno técnico está preparado para continuar. Antes de implementar el videojuego
debe revisarse su documentación original, todavía ausente en esta carpeta.
No se han definido mecánicas, personajes, niveles, historia, acciones de entrada,
dependencias externas ni configuraciones de exportación.
