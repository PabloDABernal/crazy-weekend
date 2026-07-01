# Glossary

Aquí se almacenan los términos oficiales del proyecto.

Su objetivo es que todos los agentes utilicen siempre el mismo vocabulario.

---

## Momento Crazy
Evento de tensión que ocurre en ticks concretos del fin de semana. Fuerza al jugador a apostar un porcentaje de su dinero actual (50%, 70% o 100% — ver "Crazy Bet") en lugar del stake mínimo habitual, y restringe temporalmente los mercados disponibles. Su frecuencia y ventana de aparición escalan con la fase narrativa (ver `game-design.md` → "Economía de run"). Se distingue visualmente por un sello "CRAZY" en pantalla y un cambio de registro en los comentarios de partido.

## Crazy Bet
La apuesta forzosa en sí, dentro de un Momento Crazy: el stake obligatorio calculado como 50%, 70% o 100% del dinero actual del jugador.

## Expediente (pantalla)
Nombre en UI de la pantalla de colección de tipos de victoria: "Tu Expediente". Se presenta como el dossier interno que la casa de apuestas lleva sobre el jugador, no como un álbum de logros propiedad del jugador. Ver `game-design.md` → "Pantalla de colección — Expediente de casa".

## Tipos de victoria — Familia A (mercado)
Categorías de colección ligadas a un mercado de apuesta y un reto de desbloqueo específico (no simple acumulación de aciertos):
- **Victoria de Goles**
- **Victoria de Corners**
- **Victoria de Faltas**
- **Victoria de Tarjetas**
- **Victoria de Resultado Exacto**
- **Victoria de Medias** (over/under 2.5, "goles de media")
- **Victoria de Base** (1X2, "resultado base")

## Tipos de victoria — Familia B (hito económico)
Categorías de colección ligadas al dinero acumulado dentro de una misma run, sin importar el resultado final de esa run. Cuentan como un solo slot combinado para el final canónico (basta con una de las tres):
- **Victoria del Cuatro Cifras** (10.000$+ en una run)
- **Victoria del Cien Mil** (100.000$+ en una run)
- **Victoria del Millón** (1.000.000$+ en una run)

## Tipos de victoria — Anexo (comportamiento observado)
Categorías extendidas, no requeridas para el final canónico, ligadas al "cómo" de la run en vez de al mercado o al dinero:
- **Victoria de Hierro** (run completa sin amuletos Absurdos)
- **Victoria del Ludópata** ("Doble o Nada": ganar un Crazy Bet al 100%)
- **Victoria del Domingo** (ganar la run apostando solo en mercados restringidos de domingo)
- **Victoria Fantasma** (ganar una run sin consultar estadísticas/investigación)
