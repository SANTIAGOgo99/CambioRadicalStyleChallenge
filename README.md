# Cambio Radical: Style Challenge

Videojuego académico 2D de Creación de Videojuegos, desarrollado en **Godot 4.7.2 y GDScript**. Funciona sin internet. Rama de trabajo: `develop`; `main` contiene la entrega estable.

## Jugar en Windows

Abrir `Entrega_Final/CambioRadicalStyleChallenge-1.1.1.exe`. Incluye los recursos en el propio ejecutable y no requiere instalar Godot. La entrega descargable también se publica en Releases de GitHub. Se conservan los EXE anteriores como respaldo.

1. Elegir **Nueva partida** y escuchar a Ezequiel y a cada clienta.
2. Probar una opción de corte/color o peinado: la vista previa es gratuita. **Confirmar** cobra el servicio y descuenta su tiempo.
3. En el espejo, **cortar con clics sobre el cabello** a la altura de la guía; cada clic recorta mechones y los fragmentos caen. Se puede deshacer el último corte. Con la brocha, mantener presionado y pintar: cada pasada deja producto húmedo visible solo en esa zona, incluso al conservar el color natural. Las marcas coral indican lo pendiente. El producto se retira al terminar el servicio y se conserva el tono elegido. En peinado, pasar el peine hacia abajo y recorrer el cabello con la secadora.
4. Completar las dos herramientas del servicio y pulsar **Terminar servicio**. Revisar el resultado con el deslizador antes/después y entregar el look. La precisión influye en las estrellas; cortar demasiado también puede hacerte fallar aunque las opciones sean correctas. Conseguir al menos dos estrellas desbloquea el siguiente reto.

En el espejo también se puede usar **Tab**, herramientas **1/2/3/4**, flechas y **Espacio**. Con brocha, las flechas permiten recorrer tanto el ancho como el largo del cabello. El botón explica qué tarea falta cuando está desactivado. La cobertura considera el cabello visible que queda tras cortar; se conservan las pinceladas al guardar. El álbum conserva el mejor look de cada clienta con sus estrellas y precisión.

**Esc** abre la pausa; **F11** alterna pantalla completa. Ajustes permite controlar volumen general, música, efectos, voces y subtítulos. La pausa detiene el reloj y el diálogo. **Continuar partida** recupera el reto guardado, incluidos los servicios aplicados. Nueva partida solicita confirmación antes de borrar el progreso.

## Campaña incluida

| Nivel | Clienta | Objetivo |
| --- | --- | --- |
| Primera impresión | Sofía | Entrevista: conservar largo, acabado natural y profesional |
| Evento especial | Mariana | Graduación: elegancia juvenil y accesorios discretos |
| Cambio Radical | Valeria | Transformación visible de corte, color y peinado |

Incluye introducción, éxito/fracaso, reintentos, estrellas, monedas, insignias, kit profesional, espejo de vista previa, cupones, fichas de tendencia, uniforme alternativo y reconocimiento final de Alex como Hair Designer. Repetir un nivel recompensa únicamente las mejoras de puntuación.

Los diseños de Alex, Ezequiel y las tres clientas son originales. Las clientas tienen nuevas capas de rostro, cabello trasero y cabello frontal para los servicios interactivos. Hay poses, parpadeos y movimiento facial procedural, animaciones de herramientas, reacciones y celebración. Audio: 28 clips de voz neuronal en **español de México** (Dalia y Jorge), tres temas instrumentales y nueve efectos originales. Se conservan los WAV anteriores como respaldo; el juego utiliza los nuevos MP3 locales de `assets/audio/voice_mx/`.

## Editar y exportar

Importar **project.godot** con Godot 4.7.2 y pulsar **F5**. El proyecto editable permanece en esta carpeta; no está dentro del ejecutable. `scenes/` y `scripts/` contienen el juego, `data/` los retos y diálogos, `assets/` el arte y audio. Los PDF fuente están en `docs/original/`; sus imágenes no se distribuyen como arte del juego. Decisiones breves en `docs/GAME_BRIEF.md` y procedencia en `assets/ART_PROMPTS.json` y `assets/AUDIO_SOURCES.md`.

El preset **Windows Desktop** usa las plantillas oficiales 4.7.2, Windows x86_64 y PCK integrado:

```powershell
& 'C:\ruta\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --export-release 'Windows Desktop' 'Entrega_Final/CambioRadicalStyleChallenge-1.1.1.exe'
```

Comprobación básica del proyecto: `& .\tests\check_project.ps1` (acepta `-GodotPath`). Los registros temporales quedan en `.godot/checks/`, excluida de Git. Los binarios de entrega se publican como archivos de Release y se excluyen del historial de Git por su tamaño.

Las partidas y preferencias se guardan en `%APPDATA%\Godot\app_userdata\CambioRadicalStyleChallenge\`. El ejecutable no tiene firma digital. Licencias del motor y dependencias incluidas en `Entrega_Final/`.

[Repositorio](https://github.com/SANTIAGOgo99/CambioRadicalStyleChallenge)
