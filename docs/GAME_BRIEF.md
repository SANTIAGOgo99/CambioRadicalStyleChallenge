# Cambio Radical: especificación breve

Juego académico 2D de simulación creativa para Windows, Godot 4.7.2 y GDScript.
Fuentes: los tres PDF conservados en `docs/original/`. Sus imágenes son referencias
académicas y **no se incorporan como gráficos del juego**. Se crea arte original.

## Propuesta que se conserva

Alex empieza como estilista y aspira a ser Hair Designer. Ezequiel es el dueño y
mentor. El salón moderno tiene zonas de corte, color, peinado y revisión final.
El jugador interpreta peticiones, selecciona servicios y aplica pequeñas acciones
con el ratón. Cada servicio consume presupuesto y tiempo. Se evalúan las condiciones
del cliente y se entregan estrellas y monedas; se puede repetir un reto fallido.

La progresión prevista desbloquea herramientas, cortes, colores, peinados, accesorios
y uniformes de Alex. Incluye insignias y objetos especiales: kit profesional,
espejo de prueba, cupón de producto, ficha de tendencia y estrella dorada. Al superar
el reto final, Alex recibe el reconocimiento como Hair Designer; el modo libre es
una ampliación opcional. Estas funciones pertenecen al alcance completo, no todas
están implementadas en el primer nivel.

| Nivel | Cliente y objetivo | Condiciones |
| --- | --- | --- |
| 1. Primera impresión | Sofía: entrevista de trabajo | Profesional y natural, conservar largo, presupuesto limitado; mínimo 2/3 estrellas |
| 2. Evento especial | Mariana: graduación o evento especial | Elegante y juvenil, accesorios discretos, presupuesto limitado; mínimo 2 estrellas |
| 3. Cambio Radical | Valeria: transformación completa | Combinar corte, color y peinado dentro de tiempo y presupuesto |

Alex necesita poses de espera, diálogo, corte, color, secado y celebración.
Ezequiel necesita poses de conversación, explicación, observación y felicitación.
Las clientas tienen reacciones y variantes de antes/después. El arte será cartoon
2D moderno, expresivo, sin pixel art, con cabello detallado y una paleta coherente.

## Diferencias y decisiones de implementación

- Las dos propuestas son equivalentes en contenido; cambia parte de la portada.
- El ejemplo visual acorta el cabello de Sofía aunque el texto exige conservarlo:
  prevalece la petición escrita. Las soluciones correctas mantienen el largo.
- Mariana aparece asociada a graduación o boda; se conserva «evento especial»
  hasta concretar el segundo nivel, sin añadir historia nueva.
- El boceto muestra $500 y 5:00 para Sofía: se utilizan como valores iniciales.
  Los tiempos de servicios y los umbrales finos de puntuación son balance ajustable,
  no cifras que los documentos definan como definitivas.
- El nivel 3 no fija un umbral numérico ni un evento preciso; quedan por concretar.
- La prioridad actual es completar el primer nivel con su ciclo jugable completo.
  Los niveles 2 y 3 se conservan en el alcance y no se anuncian como terminados.

## Primer nivel

Ficha de Sofía → corte/color → peinado/vestimenta → revisión → resultado.
Vista previa gratuita, confirmación de servicios, interacción con herramientas,
reloj, presupuesto, éxito/fracaso, reintento y guardado de mejor puntuación.
Se integran arte original, animaciones de poses e interfaz, música y efectos.
Las voces sintéticas españolas se generaron localmente: Sabina para Sofía y Raúl
para Ezequiel. Los subtítulos duran hasta el final de cada clip; las grabaciones
pueden sustituirse después por interpretación humana sin cambiar las escenas.

Desarrollo directo en `develop`, GitHub como respaldo y comprobaciones básicas.
