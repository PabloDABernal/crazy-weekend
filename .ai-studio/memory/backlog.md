# Backlog

Convenciones:
- Toda historia queda lista para pasar a **Architect** (qué, por qué, criterio de éxito). Ninguna historia de este documento contiene diseño técnico ni arquitectura — eso lo define Architect historia por historia.
- Vocabulario oficial: ver `glossary.md` (Momento Crazy, Crazy Bet, Expediente, Familia A/B, Anexo).
- Fuente de diseño: `game-design.md`.

---

## Ideas

### Épica (post-MVP) — Colección extendida: Anexo de comportamiento observado
Las 4 categorías "de cómo" (Victoria de Hierro, Victoria del Ludópata, Victoria del Domingo, Victoria Fantasma) están completamente definidas en `game-design.md` (sección "Categorías adicionales") pero el propio documento las marca como opcionales para el MVP y candidatas a patch de contenido posterior. Quedan aquí como idea madura, no como épica activa, hasta que el MVP núcleo (final canónico de 8 categorías + economía de run + Expediente) esté implementado y jugable. Cuando se active, reutiliza sistemas ya existentes (amuletos, Momento Crazy, restricciones de domingo, pantalla de investigación) — no requiere contenido nuevo, solo lógica de detección + entradas en el Anexo del Expediente.

Candidatas a historia cuando se promueva:
- Historia: Detección y desbloqueo de Victoria de Hierro (run completa sin amuletos tier Absurdo).
- Historia: Detección y desbloqueo de Victoria del Ludópata (ganar un Crazy Bet apostado al 100%).
- Historia: Detección y desbloqueo de Victoria del Domingo (ganar la run apostando solo en mercados restringidos de la jornada 2/domingo).
- Historia: Detección y desbloqueo de Victoria Fantasma (ganar una run sin abrir la pantalla de estadísticas/investigación inter-run).
- Historia: Sección "Anexo — Comportamiento observado" en la pantalla Expediente (layout inferior separado, tono ligeramente más informal/inquietante).

---

## Épicas

### Épica A — Sistema de tipos de victoria y final canónico
**Qué**: implementar el sistema de colección que determina el final real del juego. Diseño completo: 8 categorías requeridas (7 de mercado + 1 slot combinado de hito económico). **Versión MVP**: 6 categorías requeridas (5 de mercado — Base, Medias, Goles, Tarjetas, Faltas — + el slot de hito económico), ya que Corners y Resultado Exacto quedan diferidos a post-MVP. Cada categoría tiene su propio reto de desbloqueo, más la condición de victoria final que se dispara al completarlas todas (ver A.9).

**Por qué**: es la win condition real del juego (ver `vision.md` y `game-design.md` → "Win condition — Escape"). Sin este sistema no existe final canónico ni razón mecánica para que el jugador persista entre runs y temporadas.

**Criterio de éxito de la épica (versión MVP)**: un jugador puede, jugando de forma persistente a través de runs y temporadas, desbloquear las 5 categorías de mercado disponibles en el MVP (Base, Medias, Goles, Tarjetas, Faltas) y el slot de hito económico, y al completarse la sexta (de 6) se dispara el final canónico — independientemente de si la run puntual en la que ocurre se gana o se pierde en dinero. La versión completa (8/8, con Corners y Resultado Exacto) es un criterio de éxito post-MVP — ver A.6, A.7 y A.9 ("versión completa").

**Decisión de alcance (resuelta)**: el Director Creativo decidió que Corners y Resultado Exacto quedan diferidos a post-MVP (no entran en el MVP de mercados definido en `game-design.md` → "Sistema de apuestas → Mercados disponibles (MVP)"). En consecuencia, el MVP de esta épica activa el final canónico con **6 de las 8 categorías totales** (5 de mercado — Base, Medias, Goles, Tarjetas, Faltas — más el slot combinado de hito económico); las 8 categorías completas (incluyendo Corners y Resultado Exacto) solo llegan con el contenido post-MVP. Ver historias A.6 y A.7 movidas a la sección post-MVP más abajo, y la nota de "versión MVP vs. versión completa" en A.9.

---

#### Historia A.1 — Detección de Victoria de Base (1X2 en partido sorpresa)
**Qué**: detectar y desbloquear la categoría "Victoria de Base" cuando el jugador acierta el mercado 1X2 (resultado final) en un partido marcado internamente como "sorpresa" (el equipo con menor probabilidad gana).
**Por qué**: es una de las 5 categorías de mercado del MVP (7 en la versión completa) requeridas para el final canónico; usa un mercado ya existente en el MVP (1X2).
**Criterio de éxito**: la categoría se marca como desbloqueada la primera vez que el jugador gana una apuesta 1X2 en un partido que el sistema clasificó como sorpresa (menor probabilidad de las opciones ganó). El desbloqueo persiste en meta-progresión y se refleja en el Expediente con fecha/run y flavor text (ver Épica C).

#### Historia A.2 — Detección de Victoria de Medias (over/under 2.5 en 3 partidos)
**Qué**: detectar y desbloquear "Victoria de Medias" cuando el jugador acierta el mercado over/under 2.5 goles en 3 partidos, consecutivos o no, dentro del alcance definido en el documento (misma jornada o jornadas distintas).
**Por qué**: categoría de mercado requerida para el final canónico; usa un mercado ya existente en el MVP.
**Criterio de éxito**: el sistema lleva la cuenta acumulada de aciertos del mercado 2.5 a lo largo del progreso del jugador (no solo dentro de una run) y desbloquea la categoría al llegar a 3 aciertos. Queda reflejado en el Expediente.
**Nota para Architect**: confirmar con el documento si el conteo es acumulado histórico (persistente) o debe reiniciarse; `game-design.md` no lo contradice pero conviene que Architect lo deje explícito en la spec técnica.

#### Historia A.3 — Detección de Victoria de Goles (5 aciertos de mercado de goles en una run)
**Qué**: detectar y desbloquear "Victoria de Goles" cuando el jugador acierta el mercado de goles totales (over/under) 5 veces dentro de una misma run.
**Por qué**: categoría de mercado requerida para el final canónico; usa un mercado ya existente en el MVP.
**Criterio de éxito**: el contador de aciertos de este mercado se resetea al inicio de cada run (a diferencia de Victoria de Medias) y la categoría se desbloquea en cuanto el contador llega a 5 dentro de la misma run, incluso si la run se pierde después.

#### Historia A.4 — Detección de Victoria de Tarjetas (tarjetas totales en 3 partidos de la misma jornada)
**Qué**: detectar y desbloquear "Victoria de Tarjetas" cuando el jugador acierta el mercado de tarjetas totales (over/under) en 3 partidos distintos dentro de la misma jornada.
**Por qué**: categoría de mercado requerida para el final canónico; usa un mercado ya existente en el MVP.
**Criterio de éxito**: el sistema identifica que los 3 aciertos pertenecen a partidos distintos y a la misma jornada (no runs distintas) antes de desbloquear.

#### Historia A.5 — Detección de Victoria de Faltas (mercado de faltas en partido "sucio")
**Qué**: detectar y desbloquear "Victoria de Faltas" cuando el jugador acierta un mercado de faltas en un partido con más de 20 faltas totales.
**Por qué**: categoría de mercado requerida para el final canónico.
**Criterio de éxito**: la categoría se desbloquea al primer acierto de un mercado de faltas en un partido cuyo total de faltas (dato ya contemplado como estadística de panel según `game-design.md`) supera 20.
**Depende de**: el mercado "Faltas totales (over/under)" — está documentado en `game-design.md` como mercado adicional necesario, derivable de estadísticas de partido ya existentes (no requiere mercado nuevo de UI compleja, a diferencia de Corners/Resultado exacto). Este mercado sí entra en el MVP (a diferencia de Corners y Resultado Exacto, diferidos a post-MVP — ver sección "Épica A (post-MVP)"). Marcar para Architect: confirmar detalle de implementación dado su bajo costo (reutiliza panel de estadísticas ya definido).

#### Historia A.8 — Slot combinado de hito económico (10K / 100K / 1M)
**Qué**: detectar y desbloquear el slot combinado de Familia B cuando el dinero del jugador supera 10.000$, 100.000$ o 1.000.000$ en cualquier momento dentro de una misma run (no acumulado histórico), sin importar si la run termina ganada o perdida.
**Por qué**: cierra el octavo slot requerido para el final canónico; por diseño, basta con alcanzar cualquiera de las tres cifras para resolver el slot completo.
**Criterio de éxito**: alcanzar cualquiera de las 3 cifras dentro de una run marca el slot combinado como resuelto para el final canónico. Las tres cifras se registran y siguen siendo "perseguibles" por separado como registro histórico visible en el Expediente (para completismo), aunque solo una sea necesaria para el final. El hito se evalúa en tiempo real dentro de la run (no solo al cierre del domingo), ya que el propio pico de dinero puede ocurrir y perderse antes del final de la run.

#### Historia A.9 — Condición de victoria final (final canónico)
**Qué**: implementar la lógica de cierre de campaña: cuando el jugador ha desbloqueado las categorías requeridas, disparar el final canónico en la run donde se completa la última, sin importar el resultado económico de esa run puntual.
**Versión MVP (activa)**: el final canónico se dispara al completar **6 de las 8 categorías totales** — las 5 categorías de mercado disponibles en el MVP (Base, Medias, Goles, Tarjetas, Faltas) más el slot combinado de hito económico. Corners y Resultado Exacto no forman parte del set evaluado en esta versión.
**Versión completa (post-MVP)**: una vez incorporado el contenido post-MVP (A.6 y A.7), el sistema debe evaluar el set completo de **8 de 8 categorías** (7 de mercado + slot de hito económico) para el final canónico. Ver nota de dependencia abajo.
**Por qué**: es el evento que cierra la experiencia completa del juego descrita en `vision.md` ("la salida existe pero hay que encontrarla").
**Criterio de éxito**: el sistema evalúa el estado de las categorías requeridas (según la versión activa, MVP o completa) tras cada resolución de apuesta/hito relevante; en cuanto se completa la última categoría pendiente, se dispara el evento de final canónico (contenido narrativo del final queda fuera de esta historia — pertenece a diseño narrativo/game-designer, esta historia cubre solo la condición y el disparo del evento).
**Depende de**: A.1–A.5 y A.8 para la versión MVP. Para la versión completa, además depende de A.6 y A.7 (post-MVP, ver sección correspondiente) — Architect debe diseñar el conteo de forma que ampliar de 6 a 8 categorías al llegar el contenido post-MVP no requiera rehacer la lógica de disparo, solo ampliar el set evaluado.

---

### Épica A (post-MVP) — Mercados y categorías diferidos: Corners y Resultado Exacto
Decisión del Director Creativo: Corners y Resultado Exacto quedan diferidos a post-MVP. El MVP lanza con el final canónico activable en su versión reducida de 6/8 categorías (ver A.9 — versión MVP); estas dos historias completan el set a 8/8 y quedan aquí como candidatas maduras para cuando se aborde el contenido post-MVP, junto con la Colección extendida (ver "Ideas" más arriba).

#### Historia A.6 — Mercado de Corners + Detección de Victoria de Corners (post-MVP)
**Qué**: añadir el mercado de apuesta "Corners (over/under)" y detectar/desbloquear "Victoria de Corners" cuando el jugador acierta corners con el umbral más alto disponible (over 9.5+) al menos una vez.
**Por qué**: categoría de mercado requerida para la versión completa (8/8) del final canónico. Diferida a post-MVP por decisión del Director Creativo — no bloquea el MVP, que lanza con la versión reducida (6/8, ver A.9).
**Criterio de éxito**: existe un mercado de corners jugable con al menos el umbral 9.5+; la categoría se desbloquea al primer acierto en ese umbral específico (no en umbrales menores).

#### Historia A.7 — Mercado de Resultado Exacto + Detección de Victoria de Resultado Exacto (post-MVP)
**Qué**: añadir el mercado de apuesta "Resultado exacto" (marcador exacto, cuota alta) y detectar/desbloquear "Victoria de Resultado Exacto" al primer acierto de ese mercado.
**Por qué**: categoría de mercado requerida para la versión completa (8/8) del final canónico. Diferida a post-MVP por decisión del Director Creativo — no bloquea el MVP, que lanza con la versión reducida (6/8, ver A.9).
**Criterio de éxito**: existe un mercado de resultado exacto jugable con probabilidad/cuota coherente con su rareza; la categoría se desbloquea en el primer acierto, sin requisito de volumen adicional (el propio mercado ya es el reto).

---

### Épica B — Economía de run
**Qué**: implementar las reglas económicas base de una run (dinero inicial, escalado por meta-progresión, stake mínimo, all-in forzoso, muerte de run por saldo cero) y la mecánica de Momento Crazy con su escalada de cadencia por fase narrativa.

**Por qué**: es el sistema central de presión y tensión del loop de apuestas (`game-design.md` → "Economía de run"); da nombre a la mecánica que titula el juego (Momento Crazy / Crazy Bet).

**Criterio de éxito de la épica**: una run nueva arranca con el dinero correcto (base + bonus de meta-progresión acumulados), cada tick obligatorio respeta stake mínimo/all-in/muerte por saldo cero, y los Momentos Crazy aparecen con la cadencia y restricciones correctas según la fase narrativa del jugador.

#### Historia B.1 — Dinero inicial de run con escalado por meta-progresión
**Qué**: toda run nueva comienza con 500$ base, más cualquier bonus permanente de meta-progresión ("+X$ al empezar") que el jugador haya desbloqueado vía logros, hitos de colección o decisiones de la fase inter-run.
**Por qué**: fija la presión económica inicial del fin de semana y conecta la progresión de largo plazo con la sensación de "el juego se vuelve más manejable" ya establecida en `game-design.md` → "Meta-progresión y persistencia".
**Criterio de éxito**: el dinero inicial de cada run nueva es siempre 500$ + suma de bonus permanentes activos del jugador en ese momento de la campaña. Los bonus son acumulativos, permanentes, y no se resetean entre runs ni entre temporadas.
**Nota para Architect**: el documento deja abierta a propósito la curva exacta de cuánto otorga cada desbloqueo ("Diseño abierto para Coordinator/Architect"); Architect debe proponer esa curva como parte de la spec técnica, no es una decisión de producto pendiente de más discusión con el usuario — es un detalle de balance delegado explícitamente.

#### Historia B.2 — Stake mínimo obligatorio, all-in forzoso y muerte de run por saldo cero
**Qué**: en cada tick obligatorio (cada 15 minutos de partido simulado), el jugador debe apostar como mínimo 50$; si tiene menos de 50$ disponibles, la apuesta obligatoria pasa a ser el 100% de lo que le queda (all-in forzoso); si llega a un tick con exactamente 0$, la run termina inmediatamente en derrota.
**Por qué**: es el mecanismo base de presión y el que define la condición de derrota de una run (`game-design.md` → "Economía de run" y "Loop principal → Derrota de run").
**Criterio de éxito**: no existe forma de pasar un tick obligatorio sin apostar al menos 50$ (o el 100% disponible si hay menos); llegar a 0$ en un tick de apuesta obligatoria dispara inmediatamente la pantalla de derrota ("Ya es lunes") sin tick de gracia.

#### Historia B.3 — Mecanismo base de Momento Crazy (Crazy Bet + restricción de mercados)
**Qué**: implementar el disparo de un Momento Crazy en un tick: fuerza el stake de la siguiente apuesta obligatoria a 50%, 70% o 100% del dinero actual del jugador (con pesos: 50% más común, 100% más raro), y restringe los mercados disponibles a 1-2 durante ese tick, excluyendo siempre el mercado más seguro/informado que el jugador tenga disponible en ese momento.
**Por qué**: es el momento de mayor intensidad mecánica y narrativa del fin de semana, y el que da nombre al juego dentro de su propia diégesis (ver `glossary.md` → Momento Crazy / Crazy Bet).
**Criterio de éxito**: al disparar un Momento Crazy, el jugador ve el sello "CRAZY" en pantalla, el stake forzoso se calcula correctamente sobre el dinero actual (no sobre el dinero inicial de la run), y el conjunto de mercados disponibles durante ese tick nunca incluye el mercado que el sistema identifica como más seguro/informado para el jugador en ese momento.
**Nota para Architect**: la presentación visual/sonora completa (parpadeo de saldo, sting de audio, contaminación visual en fases 3-4) puede spinearse en historias de UI/audio separadas si Architect lo considera necesario — esta historia cubre la lógica del mecanismo, no el pulido de presentación completo.

#### Historia B.4 — Cadencia de Momento Crazy por fase narrativa
**Qué**: la frecuencia y ventana de aparición de los Momentos Crazy escala según la fase narrativa (número de run) y la jornada de la run (viernes/sábado/domingo):
- Fases 1-2 (runs 1-12): 1 Momento Crazy garantizado por run, siempre en la jornada del sábado.
- Fase 3 (runs 13-20): 2 Momentos Crazy por run (sábado y domingo); en domingo se apila sobre las restricciones de mercado ya existentes de esa jornada.
- Fase 4 (runs 21+): Momentos Crazy en cualquier jornada incluida el viernes, con frecuencia de 2-3 por run.
- Dentro de la ventana correspondiente, el tick exacto de disparo es aleatorio, con un piso que impide que ocurra en el primer tick de la jornada.
**Por qué**: hace que la escalada de tensión se sienta ligada al progreso narrativo del jugador, no a mala suerte aleatoria (pilar de diseño "escalada coherente").
**Criterio de éxito**: jugando runs en cada una de las 4 fases, la cantidad y ubicación (jornada) de Momentos Crazy disparados coincide con la tabla anterior; el tick exacto dentro de la ventana varía entre partidas pero nunca cae en el primer tick de la jornada correspondiente.
**Depende de**: B.3.

---

### Épica C — Pantalla de colección "Tu Expediente"
**Qué**: implementar la pantalla de colección de tipos de victoria, presentada como el dossier de vigilancia interno de la casa de apuestas sobre el jugador, con su estructura visual de casillas selladas/redactadas y su progresión de deterioro ligada a la fase narrativa.

**Por qué**: es la superficie donde el jugador percibe su progreso hacia el final canónico, y el vehículo principal para el pilar de diseño "el jugador empieza a sentir que el juego le está observando" (`game-design.md` → "Pantalla de colección — Expediente de casa").

**Criterio de éxito de la épica**: el jugador puede acceder a "Tu Expediente" desde el menú inter-run y ver el estado real (bloqueado/desbloqueado) de las 8 categorías del final canónico, con el tono de dossier corporativo, y la pantalla se corrompe visiblemente conforme el jugador avanza de fase narrativa.

#### Historia C.1 — Estructura base del Expediente (grilla de categorías selladas/desbloqueadas)
**Qué**: pantalla accesible desde el menú inter-run con: grilla de 7 casillas (Familia A, una por mercado) + 1 casilla combinada más grande (Familia B, con sub-casillas para 10K/100K/1M). Cada categoría no conseguida se muestra sellada/redactada (solo nombre visible, más una pista ambigua predefinida por categoría, nunca el criterio exacto). Al desbloquearse, animación de "destape" que revela el criterio cumplido, fecha/run del logro, y una línea de flavor text en tono de vigilancia corporativa.
**Por qué**: es la superficie central de la Épica A — sin esta pantalla el jugador no tiene forma de percibir su progreso hacia el final canónico.
**Criterio de éxito**: las 8 categorías (según se vayan desbloqueando por la Épica A) se reflejan correctamente en la grilla; una categoría bloqueada nunca revela su criterio exacto, solo la pista ambigua ya definida en `game-design.md`; el slot combinado marca el final canónico como resuelto en cuanto una de las tres cifras se completa, pero sigue mostrando las otras dos como perseguibles.
**Depende de**: al menos parcialmente de Épica A (necesita eventos de desbloqueo reales para reflejar estado, aunque puede construirse con datos mock mientras A avanza en paralelo).
**Nota para Architect**: el texto de pista ambigua por categoría y el flavor text de desbloqueo son contenido narrativo — coordinar con Game Designer/narrative si hace falta redactar el set completo de textos antes de cerrar esta historia.

#### Historia C.2 — Progresión de deterioro del Expediente por fase narrativa
**Qué**: la propia pantalla del Expediente se corrompe siguiendo las fases narrativas: fase 1-2 documento limpio; fase 3 anotaciones manuscritas superpuestas en casillas ya desbloqueadas; fase 4 aparece una casilla adicional sin nombre oficial de mercado, con barras negras que nunca se levantan del todo aunque esté completada (pista visual de proximidad al final canónico).
**Por qué**: conecta la pantalla de colección con el arco de deterioro narrativo general del juego (`game-design.md` → "Arco narrativo"), reforzando que completar la colección no es lo mismo que "salir".
**Criterio de éxito**: la apariencia del Expediente cambia de forma consistente con la fase narrativa activa del jugador (mismo número de run que gobierna el resto del deterioro del juego); en fase 4, la casilla extra sin nombre aparece siempre con barras negras parcialmente levantadas, nunca completamente destapada.
**Depende de**: C.1.

---

## Historias

(Ver historias A.1–A.9 (MVP), A.6–A.7 (post-MVP, sub-sección propia), B.1–B.4, C.1–C.2 dentro de cada épica arriba. Se listan agrupadas por épica para mantener contexto; cuando una historia pase a Architect, puede moverse a un estado "en diseño" si el equipo prefiere trackear eso aquí.)

---

## Bugs
