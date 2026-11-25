# Arte integrado en la entrega

Recursos originales: salón, Alex con seis poses, Ezequiel con cuatro poses/retratos,
y Sofía, Mariana y Valeria con atlas de expresiones y combinaciones de cabello/ropa.
Herramientas, accesorios e icono propios. No se utilizan las imágenes de los PDF.
Los prompts están conservados en `assets/ART_PROMPTS.json`.

Los atlas PNG se mantienen intactos. `data/character_frames.json` alinea las figuras
y localiza ojos y boca; `character_face.gdshader` anima parpadeos y habla. GDScript
anima respiración, aplicación de herramientas, transiciones, reacciones y celebración.
Los accesorios adicionales se superponen de forma independiente. El cambio de uniforme
de Alex se realiza por material. Los cambios de look se construyen con variantes de atlas.

En 1.1, `sofia_layers.png`, `mariana_layers.png` y `valeria_layers.png` añaden capas
originales de rostro/capa de salón, cabello trasero y cabello frontal. El componente
`hair_workbench.gd` modifica la longitud de mechones, dibuja los fragmentos cayendo,
aplica color y transforma el acabado. El material `hair_workbench.gdshader` anima
el rostro; herramientas y accesorios se dibujan aparte. Los PNG originales se conservan.
El antes/después y el álbum utilizan el estado real de los mechones guardados.

No faltan ilustraciones necesarias para completar la campaña. Una mejora futura sería
un rig por capas de brazos y cabello para movimientos continuos más detallados; esta
entrega utiliza poses ilustradas y animación procedural, sin rig esquelético completo.
