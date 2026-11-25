# Audio de la campaña

- `audio/music/`: tres composiciones instrumentales originales sintetizadas: menú, salón y celebración. Se reproducen en bucle y bajan de volumen durante el diálogo.
- `audio/effects/`: nueve efectos originales sintetizados: botones, monedas, tijeras, tinte, peine, secadora, éxito, fracaso y aviso de tiempo.
- `audio/voice_mx/`: 28 clips neuronales MP3 en español de México, Microsoft `es-MX-DaliaNeural` para las clientas y `es-MX-JorgeNeural` para Alex y Ezequiel. Generados con `edge-tts` 7.3.1 y el servicio de lectura en voz alta de Microsoft Edge; el usuario autorizó expresamente enviar los textos. Ritmo/pitch varían por personaje. La herramienta de generación se utiliza solo durante el desarrollo y no es una dependencia del juego.
- `audio/voice/`: WAV originales de Sabina/Raúl conservados como respaldo. Se prefiere el MP3 mexicano; el respaldo solo se utiliza si falta el archivo nuevo.
- Textos editables en `data/dialogue.json`. Los subtítulos siguen la duración del clip; la pausa detiene voz y subtítulos juntos.
- Canales independientes Master, Music, Effects y Voice. Todo el audio está incluido y funciona sin internet.
- No hay grabaciones de actores ni audio extraído de los PDF. La música y los efectos son originales; las voces son sintéticas de Microsoft y conservan esa cualidad audible. La generación necesitó internet, pero la reproducción del juego no realiza llamadas a servicios de voz.
