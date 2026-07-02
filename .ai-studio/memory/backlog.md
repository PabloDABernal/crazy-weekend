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

### Épica D — Simulación de liga y partidos (motor de tick)
**Qué**: implementar el motor que genera la liga ficticia (20 equipos, atributos internos, calendario de jornadas) y simula cada partido en curso por ticks de 15 minutos, calculando estadísticas, probabilidades por mercado y comentarios textuales, y anunciando cada tick obligatorio de apuesta al resto del sistema. Esta épica es la que materializa formalmente el contrato `BettingTickService` que `_arquitectura-base.md` (sección 4) deja fijado como pendiente: nombres de recursos (`BetTickContext`, `MarketOffer`) y señal (`EventBus.bet_tick_opened`) ya están decididos y no se rediseñan aquí, solo se implementan. Incluye también el calendario de horarios escalonados por partido, con soporte a jornadas especiales concentradas (ver D.6), y el recalculo de mercados/cuotas por minuto de partido (ver D.7) — ambos confirmados como prioridad por el Director Creativo tras el playtest run 1.

**Por qué**: sin esta épica no existe partido que simular ni probabilidad que apostar — es el motor de datos que alimenta tanto la pantalla de apuestas (Épica E) como los mercados que Épica A necesita para detectar tipos de victoria. Es, junto con Épica E, el núcleo de "jugable" que faltaba en el backlog pese a que Épicas A/B/C ya tenían spec técnica completa.

**Criterio de éxito de la épica**: dado un fin de semana de juego, el sistema genera automáticamente la jornada correspondiente (partidos, equipos, jugadores con atributos internos) con horarios de kickoff escalonados por partido (sin techo fijo de partidos solapados, y con soporte a jornadas especiales que concentran partidos — ver D.6), simula cada partido en ticks de 15 minutos hasta el minuto 90, actualiza estadísticas, probabilidades, cuotas y ganancia potencial de los 6 mercados MVP en cada tick retirando los mercados ya resueltos/imposibles (ver D.7), genera 2-3 líneas de comentario textual por tick, y emite `EventBus.bet_tick_opened` con un `BetTickContext` válido (jornada, índice de tick, `MarketOffer` por mercado disponible) en el momento correcto para que Épica B (Momento Crazy) y Épica E (UI) reaccionen sin necesitar ningún cambio de contrato.

**Decisión de alcance (tomada por Coordinator, sin preguntar)**: la generación de liga para el MVP se limita a una generación semi-aleatoria simple al inicio de la campaña (20 equipos, atributos internos básicos: ofensiva/defensiva/forma/factor local; jugadores con media de goles/probabilidad de tarjeta/posición) y su evolución jornada a jornada dentro de la temporada activa. Deliberadamente **fuera de esta épica**: la fase de investigación inter-run que colapsa el rango de probabilidad mostrado (`game-design.md` → "Cómo informan las probabilidades", "con investigación máxima el jugador ve el valor calculado con ±5% de ruido") y el historial completo de temporadas/regeneración de liga en jornada 38. Para el MVP, el jugador siempre ve el rango ancho sin investigación (ej. "entre 40% y 65%") — es una simplificación válida porque el propio documento de diseño define el rango ancho como el estado *base* del sistema (el estado "sin investigación" ya es jugable de por sí, la investigación solo lo refina). Ver Historia D.5 y el hito de roadmap correspondiente para el gap de la fase inter-run completa.

#### Historia D.1 — Generación de liga (20 equipos, atributos internos, calendario de 38 jornadas)
**Qué**: generar, al inicio de una campaña nueva (o de una temporada nueva tras la jornada 38), 20 equipos ficticios con nombres distorsionados de equipos reales de LaLiga, cada uno con atributos internos (ofensiva, defensiva, forma actual, factor local) y una plantilla de jugadores ficticios (media de goles por partido, probabilidad de tarjeta, posición), con peso hacia una jerarquía reconocible (algunos equipos "estrella"). Genera también el calendario de 38 jornadas (~10 partidos por jornada, todos los equipos juegan cada jornada).
**Por qué**: es la base de datos que alimenta toda probabilidad de mercado; sin esto no hay partido que simular.
**Criterio de éxito**: cada campaña nueva produce 20 equipos con atributos distintos entre sí (no todos iguales), un calendario válido de 38 jornadas donde cada equipo juega exactamente una vez por jornada, y la jerarquía de "equipos estrella" es perceptible en los atributos generados (no es una distribución uniforme).
**Nota para Architect**: `RunState`/`MetaProgress` ya existen (Épica B) — esta historia decide si la liga vive en un nuevo autoload (`LeagueState`, análogo a `RunState` pero de vida más larga que una run) o en `MetaProgress`; `_arquitectura-base.md` no lo resuelve todavía porque esta épica no existía cuando se escribió, así que Architect tiene libertad aquí siempre que reutilice el mismo autoload de persistencia (no crear un segundo sistema de guardado).

#### Historia D.2 — Standings y estadísticas persistentes por jornada
**Qué**: tras resolverse todos los partidos de una jornada, actualizar la tabla de posiciones (puntos, goles a favor/en contra, forma últimos 5) y las estadísticas acumuladas por jugador (goles, tarjetas, partidos jugados).
**Por qué**: es la memoria de la liga que hace que "la liga evoluciona jornada a jornada" (`game-design.md` → "Standings y estadísticas visibles") y la base sobre la que se calculan probabilidades de jornadas futuras.
**Criterio de éxito**: al terminar una jornada, los standings reflejan correctamente los resultados de esa jornada y persisten para la siguiente; el jugador puede consultar esta información desde la fase inter-run (la pantalla de consulta en sí puede ser una historia de UI menor, a criterio de Architect, pero los datos deben existir y ser correctos desde esta historia).
**Depende de**: D.1.

#### Historia D.3 — Simulación de partido por ticks de 15 minutos (motor + `BettingTickService`)
**Qué**: implementar el motor de simulación de un partido en curso: 6 ticks de 15 minutos hasta completar 90 minutos, actualizando en cada tick el marcador, minuto, estadísticas acumuladas (posesión, tiros a puerta, tarjetas, corners, faltas) y probabilidades de los 6 mercados MVP a partir de los atributos de equipo/jugador (D.1) y el estado acumulado del propio partido. Al llegar a cada tick, emite `EventBus.bet_tick_opened(context: BetTickContext)` con `available_markets: Array[MarketOffer]` poblado (incluyendo `confidence` por mercado, campo que Épica B.3 ya depende de que exista). Varios partidos de la misma jornada corren en paralelo; el jugador puede tener apuestas abiertas en varios a la vez.
**Por qué**: es el corazón del loop principal (`game-design.md` → "Sistema de tiempo semi-pausado") y el que materializa el contrato `BettingTickService` que `_arquitectura-base.md` deja pendiente explícitamente en su sección 4.
**Criterio de éxito**: un partido avanza correctamente por sus 6 ticks hasta el minuto 90 con un resultado final coherente con los atributos de los equipos (no puramente aleatorio, ponderado por ofensiva/defensiva/forma/factor local); en cada tick se emite `bet_tick_opened` con un `BetTickContext` completo y válido según el contrato ya fijado (mismos nombres de campo, mismo tipo `MarketOffer`); las probabilidades mostradas se actualizan de forma consistente con lo ocurrido en los ticks previos del mismo partido (un equipo que va ganando 2-0 no puede mostrar probabilidad de 2.5 goles totales sin subir, por ejemplo).
**Depende de**: D.1. Es la historia técnicamente más central de la épica — Épica B (B.2, B.3, B.4) y Épica E dependen todas de que esta historia cumpla exactamente el contrato ya escrito en `_arquitectura-base.md` sección 4.
**Nota para Architect**: el contrato (`BetTickContext`, `MarketOffer`, señal `bet_tick_opened`) ya está fijado — no rediseñar, solo implementar. Confirmar con B.3 cómo se calcula `confidence` (0.0-1.0) por mercado, ya que hoy esa spec asume el campo pero no fija su fórmula.

#### Historia D.4 — Comentarios textuales generados por tick
**Qué**: generar 2-3 líneas de comentario textual por tick de partido, coherentes con lo ocurrido en ese tick (gol, tarjeta, tiro fallado, tramo sin eventos), con el tono correspondiente a la fase narrativa activa (deportivo estándar en fase 1, hasta surrealista/directo al jugador en fase 3-4, según `game-design.md` → "Arco narrativo").
**Por qué**: es "el canal narrativo principal" del juego según el propio documento de diseño — sin esto el partido es solo números, y se pierde el vehículo principal de tono y deterioro narrativo del núcleo de juego.
**Criterio de éxito**: cada tick simulado produce 2-3 líneas de comentario relacionadas con los eventos de ese tick específico (no genéricas); el registro de los comentarios cambia de forma consistente con `NarrativePhase.get_current_phase()`; durante un Momento Crazy, el comentario cambia de registro para dirigirse directamente al jugador (ya especificado en Épica B.3, este comentario es el mismo canal, no un sistema aparte).
**Depende de**: D.3.
**Nota para Architect**: el contenido específico de los comentarios (banco de frases, plantillas) es contenido narrativo — puede requerir coordinación con Game Designer para el set de textos por fase, pero la lógica de selección/inserción de comentarios sí es alcance de esta historia.

#### Historia D.5 — Probabilidades en rango (sin investigación) por mercado
**Qué**: exponer, para cada `MarketOffer` de cada mercado MVP, un rango visible pero impreciso de probabilidad (`displayed_probability_min`/`displayed_probability_max`, campos ya definidos en `_arquitectura-base.md` sección 4.4) derivado del valor real interno más un margen de casa no constante (varía por mercado y puede subir en runs avanzadas).
**Por qué**: es el mecanismo base de opacidad informada del pilar de diseño "ilusión de control" — el jugador ve suficiente para decidir, nunca el número exacto.
**Criterio de éxito**: cada mercado ofertado en un tick muestra un rango (no un valor único) cuyo ancho es consistente entre partidos similares; el margen de casa aplicado nunca queda expuesto al jugador como tal (el jugador solo ve el rango ya "cocinado"). El colapso de este rango vía investigación inter-run queda **fuera de esta historia y de este MVP** — ver gap señalado en `roadmap.md`.
**Depende de**: D.3.

#### Historia D.6 — Calendario de jornada con horarios escalonados (kickoffs variables + jornadas especiales concentradas)
**Qué**: generar, para cada jornada, una hora de kickoff propia por partido, distribuida en el tiempo (patrón escalonado: ej. viernes 16:45; sábado 17:00/18:30/20:00...), gobernada por el reloj de la interfaz. La generación **no fija un techo global de partidos solapados**: lo habitual es el patrón escalonado con pocos partidos vivos a la vez, pero el generador debe permitir jornadas especiales (ej. última jornada de liga, "Super Sunday") donde varios o todos los partidos arrancan a la misma hora o se concentran en un único día.
**Por qué**: da forma dramática a la jornada (arranque/pico/cola) y evita que la atención del jugador sea un recurso plano; las jornadas especiales dan variedad de ritmo entre fines de semana. Es la segunda prioridad de las historias nuevas confirmadas por el Director tras el playtest run 1.
**Criterio de éxito**: una jornada normal genera horas de kickoff escalonadas con ventanas donde predominan 1-2 partidos vivos simultáneamente; el sistema soporta al menos un tipo de jornada especial marcada donde varios/todos los partidos comparten hora de kickoff; en ningún caso el motor impone un límite fijo/hardcodeado de partidos solapados; el reloj de interfaz sigue gobernando qué partidos han empezado/terminan, igual que en el resto del sistema.
**Depende de**: D.1 (calendario de jornadas), D.3 (motor de tick por partido).
**Nota resuelta**: `game-design.md` → "Calendario de jornada — horarios escalonados" ya fue actualizado (sin techo fijo de partidos solapados, con soporte a jornadas especiales). El documento es spec definitiva para esta historia.
**Nota de balance (ya presente en game-design.md)**: el escalonado interactúa con el stake mínimo obligatorio por tick — verificar que al inicio de una jornada exista siempre al menos un mercado legal disponible para cumplir el tick obligatorio (relacionado con Bug 1, ver sección "Bugs").

#### Historia D.7 — Recalculo de mercados y cuotas por minuto de partido
**Qué**: recalcular en cada tick, a partir del estado vivo del partido (marcador, minuto, estadísticas), tanto la probabilidad como la cuota comercial y la ganancia potencial de cada mercado; retirar de la oferta los mercados ya resueltos o matemáticamente imposibles (ej. "primer goleador" tras el primer gol; over/under con umbral ya inalcanzable) como comportamiento base del sistema, independiente de las restricciones narrativas de Momento Crazy o de domingo, que se apilan encima de esta capa base.
**Por qué**: hace del minuto de partido una variable de decisión real (apostar temprano = más mercados, menos información; esperar = más certeza, cuotas menos jugosas) — feedback de playtest run 1, tercer bloque de prioridad confirmado por el Director.
**Criterio de éxito**: en cada tick, las probabilidades/cuotas de los mercados aún ofertados varían de forma coherente con lo ocurrido en el partido hasta ese momento; un mercado ya decidido o imposible desaparece de la oferta de ese partido (o queda con cuota residual coherente, según el caso) sin intervención manual; el efecto es visible como capa base incluso cuando no hay Momento Crazy ni restricciones de domingo activas.
**Depende de**: D.3, D.5 (extiende el cálculo de rango ya definido en D.5 para que también cubra cuota y ganancia potencial, no solo probabilidad).
**Nota para Architect**: coordinar con Historia E.7 (UI de cuota/ganancia potencial) para que el contrato de `MarketOffer` incluya los campos de cuota/ganancia potencial que esa historia consume, evitando dos fuentes de verdad para el mismo dato.

---

### Épica E — Pantalla de apuestas e interacción de tick
**Qué**: implementar la interfaz jugable de apuestas (estilo casa de apuestas fría, tipo bwin), el flujo de resolución de cada tick obligatorio, el flujo mínimo de inicio (pantalla "APOSTAR", intro narrativa, tutorial de primera apuesta integrado), y el cierre de run (pantalla de domingo con victoria/derrota, conectando con `RunState`/`EventBus` ya definidos en Épica B). Es la capa de UI que consume las señales que Épica D (motor) y Épica B (economía) ya emiten — no rediseña ningún contrato, solo lo consume. Incluye también la visualización de cuota comercial y ganancia potencial antes de confirmar apuesta, el boleto vivo con estado en tiempo real y feedback de resolución, y la UI de mercados dinámicos por minuto (ver E.7, E.8, E.9) — el bloque de mayor prioridad señalado por el Director tras el playtest run 1.

**Por qué**: es la superficie con la que el jugador realmente interactúa en cada run; junto con Épica D, cierra el gap identificado por el Director del Estudio entre "hay spec técnica de A/B/C" y "el juego es jugable de punta a punta". Sin esta épica, Épicas A/B/C/D existen como lógica sin forma de que el jugador las toque.

**Criterio de éxito de la épica**: un jugador nuevo puede abrir el juego, ver la intro narrativa, llegar a la pantalla de apuestas 15 minutos antes del primer partido del viernes, completar el tutorial integrado de su primera apuesta, apostar en cada tick obligatorio en al menos uno de los 6 mercados MVP durante los partidos en curso viendo siempre la cuota y la ganancia potencial antes de confirmar (ver E.7), ver el panel de partido, los comentarios y la oferta de mercados actualizarse tick a tick (incluyendo mercados que se retiran por minuto, ver E.9), ver el estado vivo de sus apuestas abiertas y recibir feedback enérgico al resolverse cada una (ver E.8), reaccionar a un Momento Crazy cuando ocurre, llegar al domingo (o a la pantalla de derrota "Ya es lunes" si su saldo llega a 0$ antes) cerrando la run correctamente vía `RunState.end_run()` / `EventBus.run_ended`, y pasar por la fase inter-run mínima (resumen de lunes + una decisión conversacional simplificada, ver E.6) antes de aterrizar en la siguiente run con el dinero inicial correcto.

**Decisión de alcance (actualizada — ver historial de decisión más abajo)**: la fase inter-run completa (lunes-jueves, 3 decisiones conversacionales de martes/miércoles/jueves, draft de amuletos, tienda, investigación) **no entra en el MVP de esta iteración** y queda como épica candidata post-MVP (ver `roadmap.md`). Sin embargo, tras consulta del Coordinator al Director Creativo sobre si el MVP debía encadenar runs sueltas en bucle sin ninguna fase inter-run real, la respuesta fue que sí quiere **un mínimo de fase inter-run ya en esta iteración** — no las 3 decisiones completas, pero sí más que una pantalla de "continuar" vacía. Esto se cubre con la nueva Historia E.6 (ver abajo): una pantalla de resumen de lunes real (no mockeada) más una única decisión conversacional simplificada con un beneficio antes de empezar la siguiente run. El sistema de amuletos completo (`game-design.md` → "Sistema de amuletos") sigue fuera de esta épica y de este MVP: depende de un draft/tienda que la versión mínima de E.6 no incluye.

#### Historia E.1 — Pantalla de inicio, intro narrativa y aterrizaje en la jornada del viernes
**Qué**: implementar la pantalla de inicio con el botón "APOSTAR" (nunca "Jugar"), la introducción narrativa en pantalla negra con el texto ya definido en `game-design.md` → "Primer minuto y onboarding", y el aterrizaje del jugador en la pantalla de apuestas 15 minutos antes del primer partido del viernes (partidos listados, hora actual visible, apuestas ya disponibles).
**Por qué**: es el primer contacto del jugador con el juego; fija el tono frío/funcional desde el segundo uno, tal como especifica el documento de diseño.
**Criterio de éxito**: desde el arranque del juego, un jugador nuevo llega a la pantalla de apuestas del viernes pasando por la pantalla de inicio y la intro narrativa (texto exacto ya escrito en `game-design.md`, sin necesidad de redacción adicional); la hora mostrada corresponde a 15 minutos antes del kickoff del primer partido de la jornada.
**Depende de**: D.1 (necesita que exista al menos una jornada generada).

#### Historia E.2 — Tutorial mínimo integrado de primera apuesta
**Qué**: en la primera run del jugador, integrar un tutorial no bloqueante en la propia pantalla de apuestas que explica cómo leer probabilidades y qué se puede apostar, y no se considera completo hasta que el jugador realiza su primera apuesta real (monto fijo pequeño, ~50$, ya definido en el documento).
**Por qué**: es el único tutorial del juego; sin él, un jugador nuevo se enfrenta a una interfaz deliberadamente fría (estilo bwin) sin ningún andamiaje.
**Criterio de éxito**: el tutorial aparece únicamente en la primera run de una campaña nueva, no bloquea la pantalla con un modal separado (vive integrado en la UI de apuestas normal), y se marca completo en el instante en que el jugador confirma su primera apuesta de ~50$. No vuelve a aparecer en runs posteriores.
**Depende de**: E.1, E.3.

#### Historia E.3 — Panel de partido y resolución de tick obligatorio (UI)
**Qué**: implementar la UI que consume `EventBus.bet_tick_opened`: panel de partido (marcador, minuto, estadísticas, probabilidades en rango, comentarios) para el partido enfocado, selector de partido cuando hay varios en paralelo, y el flujo de apuesta obligatoria por tick (el jugador no puede avanzar al siguiente tick sin apostar al menos el stake mínimo vigente, incluyendo el caso de all-in forzoso y Momento Crazy ya definidos en Épica B).
**Por qué**: es la interfaz central del loop de juego — el punto donde el motor (Épica D) y la economía (Épica B) se vuelven interacción real para el jugador.
**Criterio de éxito**: en cada tick, el jugador ve el panel actualizado del partido enfocado, puede cambiar de foco entre partidos en paralelo sin perder apuestas ya abiertas en otros, no puede avanzar de tick sin cumplir la apuesta obligatoria vigente (mínimo, all-in, o Crazy Bet según corresponda), y la UI refleja visualmente un Momento Crazy cuando `EventBus.crazy_moment_triggered` se dispara (sello "CRAZY", cambio de color, mercados restringidos deshabilitados en pantalla).
**Depende de**: D.3, D.4, D.5, B.2, B.3 (consume sus señales/contratos, no los rediseña).

#### Historia E.4 — Interfaz de los 6 mercados MVP (1X2, goles 2.5, primer goleador, ambos marcan, tarjetas, faltas)
**Qué**: implementar la UI de apuesta específica de cada uno de los 6 mercados del MVP: selección de opción, monto de stake, confirmación, y reflejo en la lista de "apuestas pendientes" siempre visible junto al saldo.
**Por qué**: son los mercados ya definidos como MVP en `game-design.md` (incluye faltas, que Épica A ya asume disponible en A.5); sin su interfaz de apuesta, ninguna de las historias de Épica A puede dispararse en la práctica.
**Criterio de éxito**: el jugador puede apostar en cualquiera de los 6 mercados ofertados en un tick, ve su saldo y sus apuestas pendientes actualizarse en tiempo real, y al resolverse un tick, las apuestas pendientes de ese tick pasan a ganadas/perdidas reflejándose en el saldo vía `RunState.set_money()` (nunca mutando el saldo por otra vía, según regla ya fijada en `_arquitectura-base.md`).
**Depende de**: E.3.

#### Historia E.5 — Cierre de run: victoria (domingo, dinero > 0) y derrota ("Ya es lunes")
**Qué**: implementar la pantalla de cierre de run en ambos desenlaces: llegar al domingo con dinero > 0 (victoria de run) dispara resumen de fin de semana; llegar a 0$ en cualquier tick obligatorio dispara inmediatamente la pantalla "Ya es lunes" sin eventos de domingo. Ambos casos llaman a `RunState.end_run(result: RunResult)` y reaccionan a `EventBus.run_ended`.
**Por qué**: cierra el loop principal de punta a punta (`game-design.md` → "Loop principal", ambas ramas de salida) y es el punto de conexión formal con Épica B (`RunState`/`RunResult`, ya definidos, no se rediseñan aquí).
**Criterio de éxito**: una run que llega al domingo con saldo positivo dispara la pantalla de victoria de run con el resumen correspondiente; una run que llega a 0$ antes del domingo dispara inmediatamente (mismo tick, sin tick de gracia) la pantalla "Ya es lunes"; en ambos casos `RunState.end_run()` se invoca con el `RunResult` correcto (`Outcome.WON` o `Outcome.LOST_BANKRUPT`, `final_money`, `peak_money`, `run_number`) y el juego queda en condiciones de pasar a la fase inter-run mínima (Historia E.6) en vez de arrancar la siguiente run directamente.
**Depende de**: E.3, B.2 (muerte de run), y el contrato `RunResult`/`EventBus.run_ended` ya fijado en `_arquitectura-base.md` sección 3.1.
**Nota para Architect**: esta historia entrega el `RunResult` de cierre; qué pantalla ve el jugador *después* de esa entrega (resumen de lunes + decisión) es responsabilidad de E.6, no de esta historia — E.5 no debe asumir ni implementar esa transición.

#### Historia E.6 — Fase inter-run mínima: resumen de lunes + una decisión conversacional simplificada
**Qué**: implementar una versión mínima (no mockeada) de la fase inter-run entre el cierre de una run (Historia E.5) y el inicio de la siguiente, compuesta por dos pantallas secuenciales:
1. **Resumen de lunes**: pantalla que muestra lo ocurrido en el fin de semana recién cerrado — resultado de la run (victoria/derrota), dinero final, categorías de tipos de victoria desbloqueadas en esa run si las hubo (Épica A/C). Si hubo derrota, se aterriza aquí directamente sin narrativa de domingo, tal como ya especifica `game-design.md` → "Fase inter-run (lunes-jueves)" para el caso de derrota.
2. **Una única decisión conversacional simplificada**: una sola pantalla de texto (tono breve y directo, igual que el resto del juego) que presenta al jugador una elección entre 2-3 opciones con un beneficio de **dinero extra directo** (el tipo de beneficio más simple de los 4 listados en el documento de diseño), que se suma al dinero inicial de la siguiente run. No hay objeto de un solo uso, investigación, ni pista narrativa en esta versión — esos 3 tipos de beneficio y las decisiones de martes/miércoles/jueves completas quedan en la versión post-MVP de la fase inter-run (ver `roadmap.md`).
**Por qué**: el Director Creativo, consultado explícitamente sobre si el MVP debía encadenar runs sueltas en bucle sin fase inter-run real, pidió un mínimo de fase inter-run ya en esta iteración — ni la versión completa de 3 decisiones/día, ni un simple botón "continuar". Esta historia es ese mínimo: suficiente para que el jugador sienta una transición real entre runs (se entera de lo que pasó, toma una decisión con consecuencia) sin construir el draft de amuletos, tienda o investigación completos.
**Criterio de éxito**: tras el cierre de cualquier run (victoria o derrota, vía E.5), el jugador ve primero el resumen de lunes con los datos correctos de la run recién cerrada; luego se le presenta la decisión conversacional simplificada con 2-3 opciones, cada una con un monto de dinero extra distinto (y con criterio de diseño razonable, alguna opción puede incluir una pequeña compensación narrativa, pero el efecto mecánico de esta versión es siempre dinero); al confirmar su elección, el monto elegido se suma al dinero inicial de la siguiente run (500$ base + bonus de meta-progresión ya definido en B.1 + el monto de esta decisión), y el juego aterriza en la pantalla de inicio de la nueva run (E.1) con ese dinero inicial correcto. La decisión no es opcional/salteable — el jugador debe elegir una opción para continuar, igual que el resto de decisiones conversacionales del documento de diseño.
**Depende de**: E.5 (recibe el cierre de run), B.1 (el monto de esta decisión se suma al mismo cálculo de dinero inicial que ya contempla bonus de meta-progresión — no es una vía paralela de modificar dinero), A/C (para mostrar categorías desbloqueadas en el resumen de lunes, si las hubo esa run).
**Nota para Architect**: decidir si el monto/opciones de la decisión son fijos o varían por fase narrativa/run — el documento de diseño no lo exige para esta versión mínima, es un detalle de balance delegado. Igual que B.1, el diseño abierto de "cuánto otorga cada opción" es un detalle de balance, no una decisión de producto pendiente. Esta historia no incluye draft de amuletos ni tienda: si en el futuro la fase inter-run completa se promueve a épica, esta historia debe poder ampliarse (más días, más tipos de beneficio) sin rehacer el resumen de lunes ni el contrato de "dinero inicial de la siguiente run" ya usado por B.1.

#### Historia E.7 — Cuota comercial y ganancia potencial visible antes de confirmar (payout)
**Qué**: en la interfaz de cada mercado apostable, mostrar siempre la cuota comercial (multiplicador, ej. "2.10") junto al porcentaje/rango de probabilidad, y al introducir un importe, mostrar en tiempo real la ganancia potencial de esa apuesta concreta en formato tipo boleto ("Apuestas 100$ → devuelve 210$, ganancia neta 110$"), visible **antes** de confirmar. Cuando la probabilidad es un rango (sin investigación), la cuota y la ganancia potencial también se muestran como rango.
**Por qué**: es la corrección de mayor prioridad señalada por el Director tras el playtest — el jugador veía probabilidad pero no cuánto ganaría, lo que dejaba el loop de apuesta sin gancho emocional (`game-design.md` → "Ganancia potencial visible"). Prioridad 1 (junto con E.8) de las historias nuevas confirmadas por el Director.
**Criterio de éxito**: para cualquier mercado ofertado en un tick, el jugador ve cuota + ganancia potencial antes de confirmar la apuesta, no después; el número se actualiza en tiempo real al cambiar el importe introducido; con probabilidad en rango, cuota y ganancia potencial se muestran también como rango; el tono visual es frío/funcional (dato de boleto, sin celebración ni decoración), coherente con "Principios de usabilidad de la interfaz".
**Depende de**: E.3, E.4, D.7 (consume las cuotas/ganancia potencial que D.7 calcula por tick).

#### Historia E.8 — Boleto vivo: estado en tiempo real de apuestas abiertas + feedback de resolución
**Qué**: el panel de apuestas pendientes (ya previsto en E.4) muestra, para cada apuesta abierta, el mercado, importe, cuota fijada al apostar, ganancia potencial, y un **estado vivo** respecto al partido en curso (ej. "vas ganando esta" / "vas perdiendo esta" / "aún indeciso"), junto con cuánto falta para su resolución (minuto/tick de cierre). Este estado se muestra **siempre** mientras el partido corre, sin condicionarlo al nivel de investigación del jugador. Al resolverse una apuesta, se da un feedback explícito e inmediato del resultado (ganancia concreta si se ganó, pérdida concreta si se perdió), con una **dopamina alta y consistente en cualquier fase narrativa de la run** (no solo en fases tempranas) — coherente con el tono "esto es Crazy Weekend, el feedback debe ser loco" que pidió el Director.
**Por qué**: es la segunda mitad del feedback de resolución señalado por el Director tras el playtest — sin esto el loop se siente "siguiente, siguiente" sin retorno emocional (`game-design.md` → "Boleto vivo y feedback de resolución"). Prioridad 1 (junto con E.7) de las historias nuevas confirmadas por el Director.
**Criterio de éxito**: mientras un partido está en curso, cada apuesta abierta sobre ese partido muestra su estado vivo actualizado en cada tick, siempre visible sin necesidad de investigación previa; al resolverse (ganada o perdida), el cambio de saldo es legible y atribuible a esa apuesta concreta, con un feedback notablemente enérgico/vistoso (no una confirmación seca ni un salto silencioso de balance), de forma consistente en cualquier fase narrativa — desde la run 1 hasta fases avanzadas, sin que el nivel de dopamina baje con el tiempo.
**Depende de**: E.3, E.4, D.3 (estado vivo del partido).
**Nota resuelta**: `game-design.md` → "Boleto vivo y feedback de resolución → resolución" ya fue actualizado (dopamina alta y consistente siempre, sin condicionarla a fase narrativa). El documento es spec definitiva para esta historia.

#### Historia E.9 — UI de mercados dinámicos por minuto (aparición/retirada + cuotas variables en pantalla)
**Qué**: reflejar en la interfaz de apuesta, tick a tick, los cambios calculados por D.7: mercados que dejan de ofertarse (ya resueltos o imposibles) desaparecen de la lista o se marcan como no disponibles con una razón breve, y las cuotas/ganancia potencial visibles se actualizan en cada tick sin que el jugador tenga que refrescar manualmente.
**Por qué**: cierra el tercer bloque de prioridad confirmado por el Director — el minuto de partido debe sentirse como variable de decisión real también en pantalla, no solo en el motor.
**Criterio de éxito**: al pasar de un tick a otro, la lista de mercados ofertados en el partido enfocado refleja exactamente el conjunto calculado por D.7 (ningún mercado ya resuelto/imposible queda ofertable en pantalla); las cuotas y ganancias potenciales mostradas coinciden con el recalculo de ese tick sin desfase perceptible.
**Depende de**: D.7, E.3, E.7.

#### Historia E.10 — Pantalla breve "no hay partidos hoy" en días vacíos de jornada concentrada
**Qué**: cuando el jugador aterriza en un día sin partidos programados (posible en una jornada CONCENTRATED de D.6, ej. "Super Sunday", donde viernes y/o sábado quedan sin partidos porque todos se concentran en domingo), mostrar una pantalla breve explícita tipo "no hay partidos hoy" antes de avanzar automáticamente al siguiente día con partidos, en vez del salto silencioso e instantáneo actual.
**Por qué**: decisión de producto del Director Creativo (ver `.ai-studio/specs/story-d6-calendario-horarios-escalonados.md` sección 11.2). El salto instantáneo implementado en D.6 es técnicamente correcto y seguro (no reintroduce el riesgo del Bug 1), pero un día vacío sin ningún feedback se siente como un vacío de contenido accidental. Una pantalla breve refuerza que la concentración de partidos ("Super Sunday" u otras jornadas especiales) es un evento narrativo/de ritmo deliberado.
**Criterio de éxito**: al entrar `BettingRoot._start_day_and_countdown` en un día sin partidos programados (jornada CONCENTRATED), el jugador ve una pantalla/mensaje breve indicando que no hay partidos ese día antes de avanzar al siguiente día con partidos; el avance sigue siendo automático (no requiere input obligatorio del jugador) y no reintroduce ningún gate de apuesta ni countdown de mercado (se mantiene la invariante anti-bloqueo del Bug 1: nunca se espera una apuesta obligatoria que no puede llegar); si varios días consecutivos están vacíos (ej. viernes y sábado), cada uno muestra su propia pantalla breve en cascada antes de llegar al día con partidos.
**Depende de**: D.6 (ya implementada; la detección de días vacíos ya existe en `betting_root.gd` vía `_start_day_and_countdown` / `_on_matchday_finished(-1)`). No reabre ni modifica el motor de D.6, es una capa de UI que se apoya en el mismo salto ya implementado.
**Alcance**: historia de pulido de UI, tamaño pequeño. No bloqueante para el resto del bloque de playtest (E.7/E.8/D.7/E.9, ya cerradas) ni para ninguna otra historia activa — puede priorizarse de forma independiente.
**Nota para Architect**: el texto exacto de la pantalla (contenido narrativo, ej. "No hay partidos hoy. El fin de semana se juega entero el domingo.") es responsabilidad de Game Designer/narrative, no de esta historia ni de Architect; esta historia solo fija el disparo, el dato (qué día está vacío, qué día es el siguiente con partidos) y el contrato de UI (pantalla breve + avance automático), no la redacción final ni el diseño visual detallado.

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

(Ver historias A.1–A.9 (MVP), A.6–A.7 (post-MVP, sub-sección propia), B.1–B.4, C.1–C.2, D.1–D.7, E.1–E.9 dentro de cada épica arriba. Se listan agrupadas por épica para mantener contexto; cuando una historia pase a Architect, puede moverse a un estado "en diseño" si el equipo prefiere trackear eso aquí.)

---

## Bugs

### Bug 1 — Bloqueo al confirmar apuesta obligatoria del 50% en un Momento Crazy
**Qué**: reportado por el Director Creativo durante un playtest. Con saldo de 831$, el sistema mostró un input de apuesta con el texto "50% obligatorio ($416)" superpuesto sobre la pestaña del partido en curso (Osasuna Rojilla 1-0 Sevilla FC, minuto 30), junto con un tinte visual rojo/vino cubriendo toda la pantalla. El botón "Continuar →" permaneció deshabilitado y el juego no dejó avanzar ni completar la apuesta forzosa, interrumpiendo la sesión de playtest en ese punto.
**Por qué (pista para Architect, no diagnóstico)**: el texto "50% obligatorio ($416)" y el tinte visual coinciden con el disparo de un Momento Crazy / Crazy Bet (mecanismo ya documentado en la Historia B.3 — fuerza el stake al 50%/70%/100% del dinero actual). Todo apunta a que el Momento Crazy se disparó correctamente, pero algo en el flujo de captura/validación de esa apuesta forzosa está bloqueando el input o la habilitación del botón "Continuar →", impidiendo cerrar el tick. La causa exacta en el código queda por aislar — no se ha investigado a nivel de implementación.
**Severidad/Prioridad**: bloqueante — impidió continuar jugando y cortó la sesión de playtest. Prioridad alta.
**Criterio de éxito (de la corrección)**: al dispararse un Momento Crazy con stake forzoso (50%, 70% o 100%), el jugador puede confirmar la apuesta obligatoria y el botón "Continuar →" se habilita correctamente al cumplirse la condición de stake, permitiendo avanzar de tick sin bloqueos.
**Estado**: causa raíz aislada por Architect (spec `.ai-studio/specs/bug-1-crazy-bet-confirm-block.md`), fix implementado por Programmer y revisado por Reviewer sin hallazgos bloqueantes. Tests automatizados de regresión escritos pero no ejecutados (sin binario de Godot en el entorno de desarrollo). QA dejó un plan de verificación manual en `.ai-studio/memory/qa-test-plan-mvp.md` → sección 5.
**Siguiente paso**: pendiente de que el Director ejecute la verificación manual (y, si tiene Godot, los tests automatizados) antes de cerrar definitivamente el bug.
