# CambioRadicalStyleChallenge

Proyecto 2D preparado para Godot **4.7.2** y **GDScript** exclusivamente.
No utiliza Unity, C# ni dependencias externas.

Videojuego académico de la materia Creación de Videojuegos. Se desarrolla
directamente en `develop`; GitHub se utiliza como respaldo de los avances.
La prioridad es completar el juego y exportarlo para Windows, con comprobaciones
básicas, sin pipelines ni procesos de gestión adicionales.

La base actual incluye interfaz adaptable, ajustes de volumen guardables,
canales de música, efectos y voces, y un componente reutilizable de subtítulos.
La documentación original todavía no está en la carpeta: las mecánicas, personajes,
niveles, historia y recursos definitivos se implementarán respetándola.

## Estructura

| Carpeta | Uso previsto |
| --- | --- |
| `scenes/` | Escenas Godot; `main.tscn` es el punto de entrada |
| `scenes/ui/` | Interfaz adaptable, ajustes y subtítulos reutilizables |
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

Los archivos `.gitkeep` conservan las carpetas vacías en Git. El repositorio de
respaldo es https://github.com/SANTIAGOgo99/CambioRadicalStyleChallenge.

## Abrir y validar

Importar `project.godot` en Godot 4.7.2 y pulsar F5. El botón **Ajustes** o **Esc**
abre el panel de audio y subtítulos; permite usar ratón o teclado. **Guardar y volver**
conserva las preferencias en `user://settings.cfg`.

Las voces se reproducen mediante el componente de subtítulos: `show_line()` recibe
texto, nombre opcional y audio; sin audio utiliza una duración indicada. No contiene
diálogos ni grabaciones de ejemplo. La música y los efectos futuros deben utilizar
los canales `Music` y `Effects`, respectivamente.

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

`docs/ENVIRONMENT.md` conserva el informe histórico de la preparación inicial.
