# CambioRadicalStyleChallenge

Proyecto 2D preparado para Godot **4.7.2** y **GDScript** exclusivamente.
No utiliza Unity, C# ni dependencias externas.

La preparación incluye únicamente una escena vacía de arranque y una raíz de
interfaz adaptable. No se han implementado mecánicas, personajes, niveles ni historia.
La documentación original no estaba en la carpeta al realizar esta revisión;
debe incorporarse y revisarse antes de desarrollar el contenido del videojuego.

## Estructura

| Carpeta | Uso previsto |
| --- | --- |
| `scenes/` | Escenas Godot; `main.tscn` es el arranque vacío |
| `scenes/ui/` | Escenas de interfaz; `interface.tscn` contiene la raíz adaptable |
| `scripts/` | Código del videojuego en GDScript |
| `assets/characters/` | Recursos gráficos de personajes definidos por la documentación |
| `assets/backgrounds/` | Fondos |
| `assets/ui/` | Recursos gráficos de interfaz |
| `assets/audio/` | Música y efectos de sonido |
| `animations/` | Recursos de animación |
| `data/` | Datos y recursos de configuración del juego |
| `tests/` | Validación técnica, sin mecánicas de juego |
| `docs/` | Documentación técnica |
| `docs/original/` | Carpeta reservada para la documentación original |

Los archivos `.gitkeep` conservan las carpetas vacías cuando se utilice Git.
Actualmente esta carpeta **no es un repositorio Git**; existen `.gitignore` y
`.gitattributes`, pero no historial ni cambios que puedan consultarse con `git status`.

## Abrir y validar

Importar `project.godot` en Godot 4.7.2. F6/F5 ejecutará una escena vacía.

Desde PowerShell, en la raíz del proyecto:

```powershell
& .\tests\check_project.ps1
```

En otra instalación, indicar la ruta del ejecutable de consola:

```powershell
& .\tests\check_project.ps1 -GodotPath 'C:\ruta\Godot_v4.7.2-stable_win64_console.exe'
```

El archivo PowerShell solo automatiza las comprobaciones del motor. La prueba
del proyecto se ejecuta en Godot mediante `tests/validate_project.gd`.
Los registros y la configuración aislada del editor quedan bajo `.godot/`, que
ya está excluida de Git. No se cambia el PATH ni la configuración global de Windows.

Consultar `docs/ENVIRONMENT.md` para ver la configuración, el ejecutable detectado
y los resultados de la preparación.
