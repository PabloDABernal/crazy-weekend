# Game Design — Crazy Weekend

Documento de referencia de mecánicas. Fuente de verdad para Architect y Programmer.
Actualizar cuando una decisión de diseño cambie — no antes.

---

## Pilares de diseño

1. **Ilusión de control**: el jugador siempre tiene información y siempre tiene decisiones. El sistema es opaco, no injusto.
2. **Ciclo legible, propósito oculto**: la estructura de run es clara y satisfactoria; el arco narrativo real se descubre, no se anuncia.
3. **Sátira sin sermón**: la crítica a las apuestas vive en el humor absurdo y en las mecánicas, nunca en texto explicativo.
4. **Escalada coherente**: la dificultad, la rareza de los amuletos y la intensidad narrativa suben juntas — el jugador no puede notar cuál de las tres está cambiando primero.
5. **Cada run es autónoma, cada run cambia algo**: sin contexto de runs previas el fin de semana es jugable; con él, el juego tiene otro significado.

---

## Loop principal

```
[LUNES–JUEVES] Fase inter-run
  └─ Lunes: resumen de lo desbloqueado + eventos de lore que devoran ganancias
  └─ Mar-Jue: 1 decisión conversacional por día → 1 beneficio (dinero, objeto, investigación o pista narrativa)
  └─ El jueves el jugador recibe dinero base para el siguiente fin de semana

[VIERNES] Inicio de run
  └─ Draft de amuletos (elegir N de M ofertados)
  └─ Primera jornada de partidos disponible
  └─ El jugador entra 15 minutos antes del primer partido

[VIERNES → SÁBADO] Jornada 1 de apuestas
  └─ Partidos de la liga ficticia en curso
  └─ Cada 15 min de partido: pausa obligatoria, el jugador DEBE apostar algo
  └─ Al final del sábado: draft de amuletos entre jornadas

[SÁBADO → DOMINGO] Jornada 2 de apuestas
  └─ Partidos más difíciles / mercados más restrictivos
  └─ Apuestas con mayores penalizaciones por error

[DOMINGO — FIN DE RUN]
  └─ Se resuelve la última apuesta
  └─ Win condition de run: dinero > 0
  └─ Comprobar si se han acumulado nuevos tipos de victoria
  └─ Voz interna / evento narrativo (intensidad según número de run)
  └─ Paso a la fase inter-run del lunes

[DERROTA DE RUN — si dinero llega a 0$ antes del domingo]
  └─ Pantalla: "Ya es lunes" — el jugador pierde la noción del tiempo
  └─ Sin recompensas, sin eventos de lore del domingo
  └─ Pasa directamente a la fase inter-run
```

Nota: una "jornada de liga" no equivale a un fin de semana real. La liga tiene 38 jornadas; el juego avanza una jornada por fin de semana jugado. Al llegar a la jornada 38 sin haber acumulado todos los tipos de victoria necesarios, se genera una nueva temporada y el loop continúa. El estado del jugador (meta-progresión) persiste entre temporadas.

---

## Win condition — Escape

El final real del juego no se activa ganando dinero. Se activa acumulando victorias de distintos **tipos** a lo largo de múltiples runs y temporadas.

Un "tipo de victoria" es una categoría de apuesta ganada (analogía directa con tipos de mano en Balatro):
- Victoria por goles (apostar correctamente resultado de goles)
- Victoria por corners
- Victoria por faltas
- Victoria por tarjetas
- Victoria por resultado exacto
- (otros tipos por definir)

### Pantalla de colección
Los tipos de victoria conseguidos se muestran en una pantalla visual tipo "colección" — el jugador puede ver qué categorías tiene cubiertas y cuáles le faltan. El diseño visual concreto está pendiente.

### Condición de victoria final
Cuando el jugador acumula un tipo de victoria de cada categoría requerida, se activa el final canónico. El número exacto de categorías necesarias está pendiente de definir, pero el sistema está cerrado.

---

## Sistema de tiempo semi-pausado

- Un partido dura 90 minutos de tiempo de partido, dividido en 6 ticks de 15 minutos.
- Tras cada tick, el juego pausa y muestra el panel de estado actualizado.
- El jugador DEBE realizar al menos una apuesta antes de poder avanzar al siguiente tick. No existe opción de pasar sin apostar.
- Varios partidos corren en paralelo. El jugador decide en qué partido focalizar su atención en cada tick (no puede ver todos a la vez con el mismo detalle).
- El jugador puede tener apuestas abiertas en múltiples partidos simultáneamente.
- No hay simulación visual del partido. Solo el panel informativo.

Panel de información por partido (actualizado en cada tick):
- Marcador actual
- Minuto del partido
- Estadísticas acumuladas: posesión, tiros a puerta, tarjetas, corners
- Probabilidades actualizadas de todos los mercados
- Comentarios textuales generados (2-3 líneas por tick) — estos comentarios son el canal narrativo principal

---

## Sistema de apuestas

### Mercados disponibles (MVP)
- Resultado final (1X2)
- Goles totales (over/under, umbral variable: 1.5 / 2.5 / 3.5)
- Primer goleador
- Ambos equipos marcan (sí/no)
- Tarjetas totales (over/under)

### Odds y cuotas
- Las probabilidades se muestran como porcentajes (ej: "Real Madrileño gana: 62%").
- Las cuotas (multiplicador de ganancia) se derivan de las probabilidades con margen de casa integrado — el jugador nunca ve la cuota "justa".
- El margen de casa no es constante: varía por mercado y por run avanzada (puede subir como elemento de presión).
- Sin investigación previa, las probabilidades tienen un rango visible pero impreciso (ej: "entre 40% y 70%"). La investigación inter-run colapsa ese rango hacia el valor real.

### Presentación
- Interfaz de casas de apuestas real: diseño deliberadamente funcional y frío, estilo bwin — no "jugable".
- El saldo visible en todo momento. Las apuestas pendientes también.
- La hora actual visible en la interfaz.
- Restricciones del domingo: ciertos mercados desaparecen, los márgenes de casa aumentan, algunas apuestas tienen stake mínimo obligatorio.

---

## Sistema de amuletos

### Obtención
- **Draft in-run**: entre viernes-sábado y sábado-domingo aparece un draft de 3 amuletos, el jugador elige 1.
- **Tienda inter-run (lun-jue)**: amuletos disponibles para comprar con dinero. Stock limitado y aleatorio cada semana.
- **Logros/meta-progresión**: ganar runs y cumplir objetivos específicos desbloquea nuevos amuletos que entran al pool de aparición de runs futuras.

### Límite por run
El jugador puede acumular un máximo de **6 amuletos por run**. El total entre drafts in-run y compras en tienda inter-run no puede superar 6. No existe límite de amuletos activos simultáneos — todos los amuletos obtenidos están activos.

### Tipos de efectos (de menos a más raro)
| Tier | Ejemplo de efecto |
|------|-------------------|
| Comun | +10% al multiplicador de apuestas en goles totales |
| Raro | Revelar el marcador exacto del siguiente tick antes de apostar |
| Epico | Un partido por run tiene resultado garantizado (el jugador no sabe cuál) |
| Absurdo | El comentarista menciona tu nombre. Las probabilidades de un equipo suben 20% sin justificación estadística. |

- Los amuletos de tier Absurdo aparecen solo en runs avanzadas (vinculados al deterioro narrativo).
- Los amuletos no se preservan entre runs — cada run comienza sin amuletos.
- Lo que sí persiste: qué amuletos han sido desbloqueados (pool de aparición), no los amuletos en sí.

### Interacción entre amuletos
- Los conflictos entre efectos se resuelven por orden de adquisición.
- No hay sinergias explícitas en UI — el jugador las descubre.

---

## Fase inter-run (lunes–jueves)

Aventura conversacional ligera. Es un puente narrativo y de preparación, no el núcleo del juego.

### Estructura por día
- **Lunes**: aparece lo que desbloqueaste durante el fin de semana. Eventos de lore que consumen las ganancias de forma absurda (el ruso del préstamo, la multa inexplicable). Si hubo derrota de run, no hay eventos del domingo — se aterriza directamente aquí.
- **Martes**: 1 decisión conversacional → 1 beneficio.
- **Miércoles**: 1 decisión conversacional → 1 beneficio.
- **Jueves**: 1 decisión conversacional → 1 beneficio. El jugador recibe el dinero base para el siguiente fin de semana.

### Tipos de beneficio por decisión
- Dinero extra directo
- Objeto de un solo uso (tipo pociones de Slay the Spire)
- Investigación: mejora la precisión de probabilidades visibles en la siguiente run
- Pista narrativa: fragmento del arco de historia

### Tono
Corta y directa. Los textos son breves. No hay exploración libre ni mapas. El jugador lee, elige, avanza.

---

## Meta-progresión y persistencia

### Qué persiste entre runs
- Número de run (determina la fase de deterioro narrativo)
- Standings de liga y estadísticas de equipos/jugadores (la liga evoluciona jornada a jornada)
- Pool de amuletos desbloqueados (más amuletos disponibles para aparecer en futuras runs)
- Pool de objetos de un solo uso desbloqueados

### Qué no persiste
- Los amuletos activos de la run anterior
- El dinero (cada run comienza con el dinero base del jueves)

### Cómo funciona la progresión
Ganar runs y completar objetivos específicos desbloquea contenido nuevo. Cuanto más contenido desbloqueado, más herramientas tiene el jugador: el juego se vuelve progresivamente más manejable. El desafío disminuye con el tiempo de forma intencionada — el bucle recompensa la persistencia.

### Temporadas
- 1 temporada = 38 jornadas = 38 runs completadas (o intentadas).
- Si al acabar la jornada 38 no se han acumulado todos los tipos de victoria necesarios, comienza una nueva temporada.
- La liga se regenera al inicio de cada temporada (nueva generación semi-aleatoria con peso hacia equipos estrella).
- La meta-progresión del jugador persiste entre temporadas.

---

## Primer minuto y onboarding

### Pantalla de inicio
El botón principal dice **"APOSTAR"** — no "Jugar" ni "Inicio".

### Introducción narrativa
Pantalla negra. Solo texto. Narración en primera persona, breve y directa:

> "Tienes dinero fresco y llega el fin de semana. Solo tienes un objetivo: ganar, ganar, ganar. Para ello entras en tu portal de apuestas de confianza..."

### Primera pantalla de juego
Se abre una UI estilo casa de apuestas real — diseño frío y funcional, inspirado en bwin. Lista de partidos disponibles. Hora actual visible en pantalla. El jugador aterriza **15 minutos antes del primer partido** — ya hay apuestas disponibles pero los partidos aún no han comenzado.

### Tutorial mínimo integrado
- Aparece en la primera run, de forma integrada — no hay pantalla de tutorial separada.
- Explica cómo leer probabilidades y qué se puede apostar.
- El jugador avanza manualmente: el tutorial no termina hasta que realiza su primera apuesta.
- La apuesta inicial es una cantidad fija pequeña (aproximadamente **50$**) elegida para enseñar el loop sin riesgo percibido.

---

## Economía de run

### Principio de diseño
El dinero inicial de la run debe calcularse para que el jugador pueda apostar exactamente los mínimos en todos los ticks obligatorios del viernes entero — ni más ni menos. La cantidad concreta depende del número de partidos del viernes y del stake mínimo por apuesta, ambos pendientes de definir.

### Efecto buscado
- El jugador empieza con lo justo para sobrevivir el viernes.
- Todo lo ganado sobre ese mínimo es el margen real con el que juega el resto del fin de semana.
- Todo lo perdido por debajo de ese mínimo lo acerca a la muerte de run antes del domingo.

### Números pendientes
El dinero inicial exacto se define cuando el calendario del viernes esté cerrado.

---

## Liga ficticia

### Generación
La liga se genera de forma **semi-aleatoria al inicio de cada nueva campaña** (nueva partida de jugador). No es igual para todos los jugadores — no hay liga fija global. La generación tiene peso hacia equipos y jugadores "estrella" (internamente con mejores atributos) para que haya jerarquía reconocible.

La liga se regenera al inicio de cada nueva temporada (tras la jornada 38), pero la meta-progresión del jugador no se resetea.

### Estructura
- 20 equipos ficticios con nombres inspirados en equipos reales de LaLiga pero distorsionados.
  - Ejemplos: "Real Madrileño", "FC Barceloneta", "Atlético de Madriz", "Seviya FC", "Valencia Naranja".
- 38 jornadas. Una jornada por fin de semana jugado.
- ~10 partidos por jornada (todos los equipos juegan cada jornada).

### Datos de equipos y jugadores
- Cada equipo tiene atributos internos: ofensiva, defensiva, forma actual, factor local.
- Cada jugador ficticio tiene: media goles por partido, probabilidad de tarjeta, posición.
- Estos datos son la fuente real de las probabilidades — el jugador no los ve directamente.
- Con investigación inter-run el jugador desbloquea acceso parcial a estas estadísticas (no los números internos, sino indicadores: "el delantero centro lleva 3 goles en los últimos 4 partidos").

### Cómo informan las probabilidades
- El motor calcula probabilidades base a partir de los atributos + historial de jornadas anteriores.
- Sin investigación: el jugador ve rangos anchos ("entre 40% y 65%").
- Con investigación máxima: el jugador ve el valor calculado con ±5% de ruido.
- El margen de casa se aplica siempre por encima del valor calculado.

### Standings y estadísticas visibles
- Tabla de posiciones actualizada después de cada jornada.
- Estadísticas por equipo: puntos, goles a favor, goles en contra, forma (últimos 5).
- Estadísticas por jugador: goles, tarjetas, partidos jugados.
- El jugador puede consultar esto desde la fase inter-run para informar sus apuestas.

---

## Arco narrativo — Fases de deterioro

El número de run determina la fase. Las transiciones son graduales, no hay cut escena.

### Fase 1 — Runs 1 a 5: superficie normal
- Comentarios de partido: tono deportivo estándar con humor leve.
- Voces internas: solo aparecen al final del domingo y solo si el jugador pierde. Son breves ("la próxima vez seguro").
- Lore inter-run: absurdo pero ligero (el ruso del préstamo, la multa inexplicable).

### Fase 2 — Runs 6 a 12: grietas
- Comentarios empiezan a mezclar información del partido con frases que no encajan ("el delantero centra, como cuando llamaste a tu padre").
- Voces internas aparecen también al ganar, con un tono levemente incómodo.
- Un amuleto por run tiene descripción que rompe la cuarta pared levemente.
- El lore inter-run menciona eventos de runs anteriores.

### Fase 3 — Runs 13 a 20: deterioro abierto
- Comentarios claramente surrealistas. El comentarista parece saber que el jugador está jugando.
- Las probabilidades de un mercado por partido se muestran "corruptas" (valores que no suman 100%).
- Los amuletos Absurdos aparecen con frecuencia y sus efectos afectan la presentación del juego (fuente cambia, colores invertidos, un partido desaparece del panel).
- Las voces internas se vuelven un personaje: tienen continuidad entre runs.

### Fase 4 — Runs 21+: ruptura
- El sistema empieza a ofrecer salidas explícitas pero disfrazadas de penalizaciones.
- La win condition real (acumular todos los tipos de victoria) se vuelve accesible para jugadores persistentes.
- Una run completada con el set completo de tipos de victoria desencadena el final canónico.

---

## Preguntas de diseño abiertas

1. **Número exacto de tipos de victoria necesarios**: cuántas categorías distintas debe acumular el jugador para activar el final. El sistema está definido; el número concreto no.

2. **Cantidad exacta de dinero inicial de run**: depende de cerrar el calendario del viernes (número de partidos y stake mínimo por tick). El principio está definido; el número no.

3. **Diseño visual de la colección de tipos de victoria**: cómo se presenta esta pantalla en UI. Pendiente de diseño gráfico.

4. **Riesgo de diversión — ritmo del viernes**: la entrada 15 minutos antes del primer partido puede no ser suficientemente tensa. Alternativa en consideración: mostrar partidos en directo en lugar de sistema de ticks. Requiere prototipo para validar cuál genera más tensión.
