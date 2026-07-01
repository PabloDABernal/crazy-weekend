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
  └─ Cada 15 min de partido: pausa obligatoria, el jugador DEBE apostar algo (mínimo 50$, o all-in si tiene menos — ver "Economía de run")
  └─ Posible Momento Crazy (stake forzoso 50/70/100% + mercados restringidos — ver "Economía de run")
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

El final real del juego no se activa ganando dinero. Se activa acumulando victorias de distintos **tipos** a lo largo de múltiples runs y temporadas. Hay dos familias de tipos de victoria: **de mercado** y **de hito económico**. Ambas cuentan para el mismo set de colección.

### Familia A — Tipos de victoria de mercado

Cada mercado de apuesta (ver "Sistema de apuestas") es también una categoría de colección, pero **ganar una apuesta suelta de ese mercado no la desbloquea**. Eso convertiría la colección en un subproducto pasivo del loop normal, y no queremos eso: la colección tiene que sentirse como un logro, no como una casilla que se marca sola.

**Criterio de desbloqueo**: cada categoría de mercado se desbloquea cumpliendo un **reto específico de ese mercado**, no solo "ganar N veces". El reto siempre combina volumen + dificultad, para que cada tipo de victoria tenga su propia identidad y su propio "momento eureka":

| Categoría | Mercado base | Reto de desbloqueo |
|---|---|---|
| **Victoria de Goles** | Goles totales (over/under) | Acertar el mercado de goles 5 veces en una misma run |
| **Victoria de Corners** | Corners (nuevo mercado a incorporar) | Acertar corners con el umbral más alto disponible (over 9.5+) al menos una vez |
| **Victoria de Faltas** | Faltas/tarjetas relacionadas | Acertar un mercado de faltas en un partido con más de 20 faltas totales (partido "sucio") |
| **Victoria de Tarjetas** | Tarjetas totales (over/under) | Acertar tarjetas totales en 3 partidos distintos de la misma jornada |
| **Victoria de Resultado Exacto** | Marcador exacto (nuevo mercado, alta cuota) | Acertar un resultado exacto una sola vez — el mercado ya es lo bastante difícil para ser su propio reto |
| **Victoria de Medias** ("goles de media") | Over/under con umbral específico 2.5 | Acertar el over/under de 2.5 en 3 partidos consecutivos (misma jornada o jornadas distintas) |
| **Victoria de Base** ("resultado base", 1X2) | Resultado final (1X2) | Acertar el 1X2 en un partido marcado como "sorpresa" (el equipo con menor probabilidad gana) |

Esto obliga a decidir en Architect/Programmer si "corners" y "resultado exacto" se añaden formalmente a la lista de mercados MVP o quedan para una expansión post-MVP — quedan anotados aquí como necesarios para que la colección tenga sentido completo, aunque el MVP podría lanzar solo con los mercados ya definidos y añadir estos dos más adelante.

### Familia B — Tipos de victoria por hito económico

Independientes del mercado: se desbloquean por la cantidad de dinero acumulada **dentro de una misma run** (no acumulado histórico), en cualquier momento del fin de semana, aunque la run termine perdiéndose después:

| Categoría | Hito |
|---|---|
| **Victoria del Cuatro Cifras** | Superar los 10.000$ en una run |
| **Victoria del Cien Mil** | Superar los 100.000$ en una run |
| **Victoria del Millón** | Superar los 1.000.000$ en una run |

Nota de diseño: estas categorías premian al jugador que apuesta agresivo y deja correr la suerte, en tensión directa con el jugador conservador que busca las categorías de mercado. Es una decisión de diseño intencionada — el juego no debería tener un único camino "correcto" hacia la colección completa.

### Categorías adicionales (propuesta del Game Designer)

El pilar de "cada run es autónoma, cada run cambia algo" y la escala de runs/temporadas dejan espacio para categorías que no dependen de mercado ni de dinero, sino del **cómo** de la run. Estas categorías dan variedad a largo plazo y refuerzan el tono narrativo sin necesitar contenido nuevo (reutilizan sistemas ya existentes):

| Categoría | Condición | Por qué existe |
|---|---|---|
| **Victoria de Hierro** | Terminar una run entera sin usar ningún amuleto de tier Absurdo | Premia jugar "limpio" en runs avanzadas donde el ruido narrativo es más fuerte — tensión entre poder y cordura |
| **Victoria del Ludópata** ("Doble o Nada") | Sobrevivir un momento **Crazy** (ver Economía de run) apostando el 100% forzoso y ganar la apuesta | Convierte el momento más tenso del juego en su propio logro coleccionable |
| **Victoria del Domingo** | Ganar la run apostando exclusivamente en mercados restringidos de domingo durante la jornada 2 completa | Recompensa dominar la fase más dura del fin de semana |
| **Victoria Fantasma** | Ganar una run sin consultar ni una vez la pantalla de estadísticas/investigación inter-run | Categoría "de culto": premia jugar a ciegas, puro feeling — la clase de logro absurdo que un jugador de Balatro/Slay the Spire compartiría en redes |

Estas cuatro son opcionales para el MVP (se pueden introducir en un patch de contenido), pero quedan definidas aquí porque cierran el diseño de la colección completa: dan variedad de "cómo" ganar, no solo "qué" ganar, alargando la vida del juego sin inflar el número de mercados necesarios.

### Número de categorías necesarias para el final canónico

**El final canónico requiere 8 categorías**: las **7 de la Familia A** (mercado) más **las 3 de la Familia B** (hito económico) cuentan como **un solo slot combinado** — basta con conseguir cualquiera de las tres de hito económico para cerrar ese slot. Esto da: 7 (mercado) + 1 (cualquier hito económico) = **8 categorías totales para el final**.

Razón de diseño: si exigiéramos las 3 categorías de hito económico por separado, el final quedaría gateado casi enteramente por la suerte de una sola run explosiva, penalizando al jugador táctico. Al fusionarlas en un slot, cualquier estilo de juego (agresivo o conservador) tiene un camino razonable hacia el final, y las categorías "de cómo" (Hierro, Ludópata, Domingo, Fantasma) quedan como **colección extendida**: no cuentan para el final canónico, pero se muestran en la misma pantalla como contenido 100%-completion para el jugador que quiere exprimir el juego después de haber escapado.

### Pantalla de colección
Ver sección dedicada más abajo ("Pantalla de colección — Expediente de casa").

### Condición de victoria final
Cuando el jugador acumula las 8 categorías requeridas (7 de mercado + 1 de hito económico, cualquiera de las tres), se activa el final canónico, en la run donde se complete la octava categoría, sin importar si esa run individualmente se gana o se pierde en dinero — completar la colección tiene prioridad narrativa sobre el resultado económico de la run puntual.

---

## Pantalla de colección — Expediente de casa

### Concepto
La colección se presenta como el **expediente interno de la casa de apuestas sobre el propio jugador** — no un álbum de logros que el jugador posee, sino un dossier que "ellos" llevan sobre él. Esto convierte una pantalla de meta-progresión estándar (que en Balatro es celebratoria y cálida) en algo coherente con el tono de Crazy Weekend: frío, corporativo, y con una vigilancia implícita que conecta directamente con el pilar "el jugador empieza a sentir que el juego le está observando".

Nombre en UI: **"Tu Expediente"** (accesible desde el menú inter-run, junto a standings de liga e investigación).

### Estructura visual
- Layout tipo ficha/formulario burocrático: una grilla de 7 casillas (Familia A, mercado) + 1 casilla combinada más grande (Familia B, hito económico) + una sección inferior separada visualmente para las categorías "de cómo" (Hierro, Ludópata, Domingo, Fantasma) marcada como **"Anexo — Comportamiento observado"**.
- Cada categoría no conseguida se muestra como una casilla sellada con el mismo look de un documento con datos tachados/redactados (barras negras estilo documento desclasificado), mostrando solo el nombre del mercado, nunca el criterio exacto de desbloqueo — el jugador debe descubrir el reto jugando, no leerlo en un tooltip completo. Solo una pista ambigua está visible (ej. bajo "Resultado Exacto": *"Un acierto. Uno solo. ¿Cuándo te atreverás?"*).
- Al desbloquearse, la casilla se "destapa": la redacción negra se levanta con una animación breve tipo sello de aprobado, revela el criterio completo ya cumplido, la fecha/run en la que se logró, y una línea de flavor text escrita en el mismo tono de vigilancia corporativa (ej: *"Expediente actualizado. El sujeto acertó un resultado exacto el 14/03. Se ha tomado nota."*).
- El slot combinado de hito económico muestra las tres cifras (10K/100K/1M) como sub-casillas dentro de una sola celda — al completarse cualquiera, toda la celda se marca como resuelta para el final canónico, pero las otras dos siguen visibles y "perseguibles" por separado como registro histórico (para el jugador que sí quiere las tres por completismo, aunque el final no las exija).
- El Anexo de categorías "de cómo" usa el mismo lenguaje de vigilancia pero con un tono ligeramente más informal/inquietante, coherente con fases narrativas avanzadas — encaja con que estas categorías son contenido extendido, no núcleo del final.

### Progresión de deterioro de la propia pantalla
Igual que el resto de la interfaz, el Expediente se corrompe con las fases narrativas (ver "Arco narrativo"):
- **Fase 1-2**: documento limpio, tipografía de formulario oficial, sin errores.
- **Fase 3**: alguna casilla ya desbloqueada empieza a mostrar anotaciones manuscritas superpuestas a mano, como si alguien (algo) hubiera intervenido el documento oficial.
- **Fase 4**: el expediente incluye una casilla adicional sin nombre oficial de mercado, con las barras negras nunca levantándose del todo aunque esté completada — esta es la pista visual de que el final canónico (la colección completa) está cerca, y de que ganar la colección no es lo mismo que "salir".

### Por qué funciona con el tono
La pantalla de colección más memorable de referencia (Balatro) celebra al jugador. Aquí invertimos la emoción: cuantas más casillas destapa el jugador, más evidente es que hay una entidad que lo observa y lleva la cuenta por él. El mismo sistema de progresión que en otros juegos genera orgullo, en Crazy Weekend genera la primera grieta real de inquietud — de forma puramente visual, sin una sola línea de texto moralizante.

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

### Mercados requeridos por la Win condition (evaluar para MVP o expansión)
La colección de tipos de victoria (ver "Win condition — Escape") necesita dos mercados adicionales para poder cerrarse por completo. Quedan documentados aquí como requisito de diseño; Architect/Coordinator deciden si entran en el MVP o en un patch posterior:
- **Corners (over/under)**: necesario para la categoría "Victoria de Corners".
- **Resultado exacto**: necesario para la categoría "Victoria de Resultado Exacto". Mercado de cuota alta por naturaleza (baja probabilidad), coherente con que su propio reto de desbloqueo sea "acertarlo una sola vez".
- **Faltas totales (over/under)**: necesario para la categoría "Victoria de Faltas". Puede derivarse de las mismas estadísticas de partido ya contempladas (posesión, tiros a puerta, tarjetas, corners) sumando faltas al panel de información.

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

### Dinero inicial
- **Dinero inicial base de una run nueva: 500$.**
- Este valor es deliberadamente ajustado: alcanza para cubrir varios ticks obligatorios al stake mínimo, pero no todo el viernes con margen — el jugador siente presión desde el primer tick, no solo al final del fin de semana.
- El dinero inicial **escala con la meta-progresión**: ciertos desbloqueos de la fase inter-run (investigación, logros, hitos de colección) otorgan mejoras permanentes del tipo "empezás con +X$" que se acumulan entre runs. Esto conecta directamente con "Meta-progresión y persistencia" — ver más abajo cómo se integra.
- El principio de diseño original (calcular el inicial en función del calendario exacto del viernes) queda descartado a favor de un número fijo y legible: 500$ es fácil de comunicar al jugador, fácil de balancear contra el stake mínimo (ver abajo), y escala de forma predecible con los desbloqueos.

### Apuesta obligatoria y stake mínimo
- **Stake mínimo por apuesta: 50$.**
- En cada tick obligatorio (cada 15 minutos de partido simulado) el jugador **debe** apostar como mínimo 50$ en algún mercado disponible. No existe la opción de pasar sin apostar.
- **All-in forzoso**: si el jugador tiene menos de 50$ disponibles al llegar a un tick obligatorio, la apuesta mínima pasa a ser el 100% de lo que le queda — apuesta todo, sin excepción.
- **Muerte de run por saldo cero**: si el jugador llega a un tick de apuesta obligatoria con exactamente 0$, la run termina inmediatamente en derrota (ver "Loop principal → Derrota de run"). No hay tick de gracia ni excepción — el 0$ es un muro duro, no una advertencia.
- Con 500$ iniciales y 50$ de stake mínimo, el jugador parte con margen para 10 apuestas mínimas exactas antes de tocar fondo — suficiente para sentir que tiene decisiones, no tantas como para sentirse a salvo.

### Momentos Crazy — apuesta forzada de alto stake

Mecanismo nuevo de tensión: en determinados ticks, el juego no pide el stake mínimo sino un **porcentaje forzoso del dinero actual del jugador**, y restringe qué mercados están disponibles durante ese tick. Es el momento de mayor intensidad mecánica y narrativa del fin de semana, y da nombre oficial al título del juego dentro de su propia diégesis.

**Cuándo ocurren:**
- Un momento Crazy **no es puramente aleatorio**: está ligado a la combinación de fase narrativa (número de run) y jornada de la run (viernes/sábado/domingo), para que se sienta como una escalada de tensión y no como mala suerte.
  - **Fases 1-2 (runs 1-12)**: un (1) momento Crazy garantizado por run, siempre en la jornada del sábado (el punto medio del fin de semana, cuando el jugador ya tiene algo que perder pero todavía puede recuperarse).
  - **Fase 3 (runs 13-20)**: dos momentos Crazy por run — sábado y domingo. En domingo, el momento Crazy se apila sobre las restricciones de mercado ya existentes de esa jornada, intensificando el efecto embudo.
  - **Fase 4 (runs 21+)**: los momentos Crazy pueden disparar en cualquier jornada, incluido el viernes, y su frecuencia sube a 2-3 por run — reflejo mecánico de que el sistema "ya no espera" al jugador.
- Dentro de estas ventanas, el tick exacto en que dispara el momento Crazy sí es aleatorio (con un piso para que nunca sea el primer tick de la jornada) — así el jugador nunca puede planificar con certeza absoluta, solo prepararse.

**Qué exige:**
- Al disparar, el juego fuerza el stake de la siguiente apuesta obligatoria a **50%, 70% o 100%** del dinero actual del jugador (elegido con peso: 50% es el más común, 100% el más raro, escalando en probabilidad con la fase narrativa — en fase 4, el 100% es tan probable como el 50%).
- Simultáneamente, **restringe el acceso a mercados**: durante ese tick solo quedan disponibles 1-2 mercados (nunca el mercado más seguro/informado que el jugador tenga en ese momento — el juego "te saca la opción cómoda de la mesa" deliberadamente).

**Cómo se distingue (presentación):**
- La interfaz, normalmente fría y funcional estilo bwin, sufre una intrusión momentánea: el panel se tiñe de un rojo/ámbar de alerta, el saldo parpadea, y el nombre del modo aparece explícitamente en pantalla como sello: **"CRAZY"**.
- El comentario textual del tick cambia de registro: en vez de comentar el partido, el "comentarista" se dirige directamente al jugador con una frase corta y perentoria (ej: *"No hay tiempo para pensar. 70% o nada."*). Esto es coherente con el canal narrativo ya establecido en los comentarios de partido.
- Un sonido/sting distintivo (a definir en producción de audio) marca la entrada y salida del momento Crazy, para que sea reconocible incluso sin leer el texto.
- En fases narrativas avanzadas (3-4), la distorsión visual del momento Crazy se contamina con los mismos efectos de corrupción ya descritos en "Arco narrativo" (fuente cambia, colores invertidos) — el momento Crazy deja de ser un evento mecánico aislado y empieza a sentirse como una manifestación directa del deterioro del juego.

**Término oficial**: este mecanismo se llama **Momento Crazy** (o **Crazy Bet** para la apuesta forzosa en sí). Ver `glossary.md`.

### Integración con meta-progresión
- Los desbloqueos de dinero inicial ("+X$ al empezar") se compran/obtienen igual que el resto de la progresión permanente: mediante logros, hitos de colección de tipos de victoria, o decisiones específicas de la fase inter-run.
- Estos bonus son acumulativos y permanentes dentro de la campaña del jugador (no se resetean entre runs ni entre temporadas), igual que el resto del pool de meta-progresión ya documentado.
- Diseño abierto para Coordinator/Architect: definir la curva exacta de cuánto dinero extra otorga cada desbloqueo — este documento fija el principio (existe, es permanente, se acumula) y fija la base de 500$/50$ sobre la que escalar.

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

1. **Riesgo de diversión — ritmo del viernes**: la entrada 15 minutos antes del primer partido puede no ser suficientemente tensa. Alternativa en consideración: mostrar partidos en directo en lugar de sistema de ticks. Requiere prototipo para validar cuál genera más tensión. (Pendiente de prototipo — sin resolver a propósito.)
