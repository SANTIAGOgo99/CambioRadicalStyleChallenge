# Cambio Radical: Style Challenge

Videojuego académico 2D de Creación de Videojuegos, desarrollado en **Godot 4.7.2 y GDScript**. Funciona sin internet. Rama de trabajo: `develop`; `main` contiene la entrega estable.

## Jugar en Windows

Abrir `Entrega_Final/CambioRadicalStyleChallenge.exe`. Incluye los recursos en el propio ejecutable y no requiere instalar Godot. La entrega descargable también se publica en Releases de GitHub.

1. Elegir **Nueva partida** y escuchar a Ezequiel y a cada clienta.
2. Probar una opción de corte/color o peinado: la vista previa es gratuita. **Confirmar** cobra el servicio y descuenta su tiempo.
3. Arrastrar la herramienta a las zonas del cabello 1, 2 y 3. También se puede usar **Tab** y **Enter/Espacio**.
4. Revisar el antes/después y entregar el look. Conseguir al menos dos estrellas desbloquea el siguiente reto.

**Esc** abre la pausa; **F11** alterna pantalla completa. Ajustes permite controlar volumen general, música, efectos, voces y subtítulos. La pausa detiene el reloj y el diálogo. **Continuar partida** recupera el reto guardado, incluidos los servicios aplicados. Nueva partida solicita confirmación antes de borrar el progreso.

## Campaña incluida

| Nivel | Clienta | Objetivo |
| --- | --- | --- |
| Primera impresión | Sofía | Entrevista: conservar largo, acabado natural y profesional |
| Evento especial | Mariana | Graduación: elegancia juvenil y accesorios discretos |
| Cambio Radical | Valeria | Transformación visible de corte, color y peinado |

Incluye introducción, éxito/fracaso, reintentos, estrellas, monedas, insignias, kit profesional, espejo de vista previa, cupones, fichas de tendencia, uniforme alternativo y reconocimiento final de Alex como Hair Designer. Repetir un nivel recompensa únicamente las mejoras de puntuación.

Los diseños de Alex, Ezequiel y las tres clientas son originales. Hay poses, parpadeos y movimiento facial procedural, animaciones de herramientas, reacciones y celebración. Audio: 28 clips de voz sintética en español, tres temas instrumentales y ocho efectos originales. Las voces pueden sustituirse por interpretación humana conservando los textos de `data/dialogue.json`.

## Editar y exportar

Importar **project.godot** con Godot 4.7.2 y pulsar **F5**. El proyecto editable permanece en esta carpeta; no está dentro del ejecutable. `scenes/` y `scripts/` contienen el juego, `data/` los retos y diálogos, `assets/` el arte y audio. Los PDF fuente están en `docs/original/`; sus imágenes no se distribuyen como arte del juego. Decisiones breves en `docs/GAME_BRIEF.md` y procedencia en `assets/ART_PROMPTS.json` y `assets/AUDIO_SOURCES.md`.

El preset **Windows Desktop** usa las plantillas oficiales 4.7.2, Windows x86_64 y PCK integrado:

```powershell
& 'C:\ruta\Godot_v4.7.2-stable_win64_console.exe' --headless --path . --export-release 'Windows Desktop' 'Entrega_Final/CambioRadicalStyleChallenge.exe'
```

Comprobación básica del proyecto: `& .\tests\check_project.ps1` (acepta `-GodotPath`). Los registros temporales quedan en `.godot/checks/`, excluida de Git. Los binarios de entrega se publican como archivos de Release y se excluyen del historial de Git por su tamaño.

Las partidas y preferencias se guardan en `%APPDATA%\Godot\app_userdata\CambioRadicalStyleChallenge\`. El ejecutable no tiene firma digital. Licencias del motor y dependencias incluidas en `Entrega_Final/`.

[Repositorio](https://github.com/SANTIAGOgo99/CambioRadicalStyleChallenge)
