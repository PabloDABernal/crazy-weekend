# Plan de pruebas manuales — MVP jugable (Crazy Weekend)

Diseñado por QA tras la implementación y revisión de las 5 épicas del MVP (base + B economía,
D liga/partidos, A tipos de victoria, C Expediente, E pantalla de apuestas). No hay entorno con Godot
instalado durante el desarrollo, así que nada de esto se ejecutó todavía — es la primera vez que se prueba.

## 0. Cómo abrir el proyecto

1. Instalá **Godot 4.3** (o compatible con 4.x) si no lo tenés: https://godotengine.org/download
2. Abrí Godot, "Import", seleccioná la carpeta del repo (`project.godot` está en la raíz).
3. F5 (o botón Play) para correr. La escena principal (`scenes/main/main.tscn`) ya está configurada como main scene.
4. Mirá la consola de salida (pestaña "Output" abajo) mientras jugás — cualquier error/warning de GDScript va a aparecer ahí. Si algo no carga o crashea, copiame el error de consola tal cual.

## Prioridad de ejecución recomendada

0. **Bug 1 — Momento Crazy bloqueante** (sección 5, nueva) — es el fix más reciente y el único que motivó una sesión de playtest interrumpida. Probalo primero.
1. **Cerrar y reabrir el juego después de jugar una run** (sección 3.1) — valida el fix de persistencia que se corrigió durante el desarrollo (antes no se guardaba nada).
2. **Intentar apostar más dinero del que tenés** (sección 3.2) — valida el fix de validación de stake.
3. Después, el resto en orden: golden path → casos extremos → errores.

---

## 1. Golden path (casos normales)

1. **Arranque**: F5 → pantalla "APOSTAR" → intro narrativa (avanza con click) → aterriza en la pantalla de apuestas 15 min antes del primer partido del viernes. Saldo inicial debe ser **500$** exactos en la primera partida.
2. **Cuenta regresiva**: el reloj baja hasta 0 y abre el primer tick automáticamente. El tutorial debe aparecer superpuesto (no bloqueante) señalando dónde apostar.
3. **Tutorial**: apostá el mínimo (50$) en cualquier mercado del primer partido — el tutorial se cierra solo. Si hay más de un partido en paralelo, todos deben recibir apuesta antes de poder avanzar el tick.
4. **Avanzar días**: completá los 6 ticks del viernes → pasa a sábado automáticamente → completá sábado → pasa a domingo.
5. **Victoria de run**: llegar al cierre del domingo con dinero > 0 → pantalla de cierre ("Fin de semana cerrado") → resumen de lunes → elegir una de las 3 decisiones de dinero extra (no hay opción de saltar) → arranca la run siguiente con el bonus ya sumado.
6. **Derrota de run**: si el dinero llega a 0$ en algún punto, la run **no** termina en el instante — termina recién en el siguiente tick obligatorio ("Ya es lunes"), sin mostrar ninguna apuesta de ese tick.

## 2. Casos extremos

- **All-in forzoso**: con saldo entre 1$ y 49$, el próximo tick debe exigir apostar el 100% de lo que queda (no 50$).
- **Momento Crazy**: eventualmente (siempre en sábado en las primeras runs, tick aleatorio pero nunca el primero) va a aparecer un sello "CRAZY" forzando apostar el 50%, 70% o 100% del dinero actual y restringiendo a 1-2 mercados. Si hay varios partidos en paralelo, resolverlo en cualquiera de ellos debe liberar a los demás (no debe quedar "pegado" pidiendo el monto forzoso en un segundo partido).
- **Desbloqueo de categoría de victoria**: jugando varias runs, revisá el Expediente (menú inter-run) — las categorías bloqueadas muestran solo nombre + pista ambigua, nunca el criterio exacto; al desbloquear, aparece la fecha/run y un texto (todavía placeholder, contenido narrativo pendiente).
- **Hito económico**: si en algún momento de una run el dinero supera 10.000$, el slot combinado del Expediente debe reflejarlo (incluida la sub-casilla de "10K" individual).
- **Expediente vacío**: al empezar, deben verse siempre 7 casillas de mercado + 1 combinada (2 de esas 7 son "reservadas" para contenido post-MVP — Corners y Resultado Exacto — y deben verse visualmente distintas de las bloqueadas normales, sin pista ni nombre real).

## 3. Casos que validan bugs corregidos durante el desarrollo (los más importantes de probar)

### 3.1 Persistencia entre sesiones
Jugá 1-2 runs, desbloqueá algo (una categoría o un bonus), **cerrá el juego del todo** y volvé a abrirlo. El número de run, los bonus acumulados y las categorías desbloqueadas deben seguir ahí. (Esto estaba roto — nunca se guardaba nada — y se corrigió durante el desarrollo; es el caso más importante de confirmar.)

### 3.2 No se puede apostar más dinero del que tenés
Con cualquier saldo, intentá escribir en el campo de apuesta un número mayor a tu saldo actual y confirmar. Debe rechazarse (no debería poder confirmarse esa apuesta). El caso límite —apostar exactamente todo el saldo (all-in voluntario)— sí debe permitirse.

### 3.3 Pago acreditado antes de evaluar bancarrota
Si tenés una apuesta pendiente que se resuelve favorablemente justo en el mismo tick en que tu saldo llegaría a 0 sin ese pago, el juego no debería declararte en bancarrota — el pago se acredita antes de esa evaluación. Es difícil de forzar a propósito; si en algún momento te "salva" un pago en el último segundo, es la señal de que funciona. Si en cambio ves que perdés la run a pesar de tener un pago pendiente que debería haberte salvado, es un bug a reportar.

## 4. Escenarios de error a probar deliberadamente

- Con 2+ partidos en paralelo, apostar en uno solo e intentar avanzar el tick — no debería avanzar hasta apostar en todos.
- Cambiar de foco entre partidos en medio de un Momento Crazy — la restricción debe aplicar a todos los partidos, no solo al que tenías enfocado originalmente.
- Cerrar el juego a mitad de una jornada (no en el cierre de un día) y reabrir — no debería haber crash ni estado roto; lo esperable es que arranque de nuevo desde el principio (no hay guardado a mitad de run, es una limitación conocida del MVP, no un bug).

## 5. Bug 1 — Momento Crazy bloqueante (verificación del fix)

El fix ya está commiteado (código + tests automatizados), pero los tests no se pudieron ejecutar en el entorno de desarrollo (sin Godot instalado) — esto es lo primero que deberías probar en tu máquina.

1. **Disparo único por tick**: llegá a un Momento Crazy con 2+ partidos vivos a la vez (overlay rojo/vino, sello "CRAZY"). Anotá el % forzoso y el importe exacto mostrado. Dejá pasar varios ticks de esos partidos sin apostar todavía — el overlay **no debe cambiar** (mismo %, mismo importe, mismos mercados permitidos). Antes del fix, cambiaba con cada partido que resolvía.
2. **"Continuar" se habilita**: apostá el importe forzoso en un mercado permitido y confirmá. El botón "Continuar →" debe habilitarse de inmediato. Este es el bloqueo exacto que interrumpió tu sesión de playtest.
3. **Mercado único no se bloquea**: si en algún Momento Crazy solo ves 1 mercado permitido, ese mercado nunca debe aparecer como restringido — siempre tiene que quedar al menos una opción para poder apostar.
4. **Dos Crazy en la misma run**: si te toca un Momento Crazy en viernes y otro en sábado, el segundo debe dispararse con normalidad (no debe quedar "inhibido" por haberse disparado ya uno antes).

Si alguno de estos falla, copiame qué viste paso a paso — probablemente hace falta otra vuelta de Programmer.

## 6. E.7 y E.8 — Cuota visible, ganancia potencial y boleto vivo (pruebas manuales)

Los tests automatizados en `tests/betting/` (ejecutables con Godot) validan la aritmética y lógica de estado vivo; esta sección documenta casos de integración y UX que solo se pueden verificar en la máquina del Director dentro del juego.

**Nota:** Los tests automatizados cubren:
- **odds_math_test.gd**: aritmética de OddsMath (odds_from_probability, odds_range, potential_return, potential_net, consistencia con PayoutCalculator).
- **market_widget_payout_preview_test.gd**: botones de opción muestran cuota, PayoutPreviewLabel se actualiza en tiempo real, muestra rango vs. valor único correctamente.
- **live_bet_evaluator_test.gd**: estado vivo tri-estado (WINNING/LOSING/UNDECIDED), incluida la regla especial de 1x2 (nunca UNDECIDED), y consistencia con PendingBetsTracker._is_bet_won.
- **resolution_feedback_overlay_test.gd**: overlay oculto por defecto, mouse_filter=IGNORE (lección del Bug 1), show_win/show_loss muestran importes, encola resoluciones múltiples.
- **live_bet_ticket_test.gd**: setup() muestra stake/cuota/ganancia, refresh_live_state() actualiza estado y ticks hasta resolución.
- **pending_bets_tracker_resolution_test.gd**: bet_resolved emite con won/payout correctos.

**Casos manuales a probar en Godot:**

### 6.1 Cuota visible antes de apostar (E.7)

**Objetivo:** Verificar que cada opción de mercado muestre su cuota (multiplicador) de forma clara, y que la ganancia potencial calculada en la UI coincida con la que efectivamente se cobra al resolverse. Este fue el bug central que se corrigió durante el desarrollo (bug de divergencia de cuota en `PayoutCalculator`), así que es el caso más importante de validar en la práctica real del motor.

**Setup:**
- Llega a la pantalla de apuestas en cualquier jornada (viernes, sábado o domingo).
- Selecciona un partido con al menos 2-3 mercados ofertados (ej. 1x2, over/under, btts).

**Pasos:**

1. **Leer cuota en cada botón de opción:**
   - Cada opción (home, away, draw en 1x2; over, under en over/under) debe mostrar una **cuota numérica clara**, ej. `2.45–2.87` (rango si la probabilidad es un rango).
   - Si la probabilidad es fija (rango colapsado), debe mostrar una sola cuota, ej. `1.50`.
   - **Señal de fallo:** Si ves `%`, números de probabilidad en lugar de cuota, o cuota ausente → bug de E.7.

2. **Ingresar un stake y verificar ganancia potencial:**
   - Selecciona una opción (ej. "over" en 2.5 goles).
   - Escribe un importe en el campo "Apuestas" (ej. 100$).
   - Busca el label de "ganancia potencial" (debe decir algo como `"Apuestas $100 → devuelve $XXX"` o `"Apuestas $100 → devuelve $XXX–$YYY"` si es rango).
   - **Anota el número de devolución mostrado** (p. ej. 287$ si cuota es 2.87 y stake es 100).
   - **Señal de fallo:** Si falta el label de ganancia potencial, si muestra solo "neto" sin el total, o si el número no corresponde a cuota × stake → bug de E.7.

3. **Confirma la apuesta y espera a que se resuelva:**
   - Juega hasta que el partido termine y se resuelva la apuesta.
   - Cuando se resuelva, observa el overlay de feedback de resolución (E.8, sección 6.4).
   - **El número que aparece en el overlay como "total acreditado" debe coincidir exactamente con el que viste en el boleto antes de apostar** (dentro del rango si es rango).
   - Ej. si el boleto decía "devuelve $287", el overlay debe decir "+$287" como número principal.
   - **Señal de fallo:** Si el overlay muestra un número diferente (ej. "devuelve" dice 287 pero el feedback dice 312) → bug de divergencia de cuota; investigar qué cambió entre "confirmar apuesta" y "pagar".

4. **Caso extremo — rango de cuota:**
   - Intenta una opción con probabilidad en rango (ej. 35%–45% de home en 1x2).
   - El botón debería mostrar `cuota_min–cuota_max` (ej. `2.22–2.86`).
   - El label de ganancia potencial debería mostrar `"Apuestas $100 → devuelve $222–$286"` (rango).
   - Al resolver, el payout acreditado debe estar dentro de ese rango (no fuera).
   - **Señal de fallo:** Rango que no se muestra, o payout fuera del rango mostrado.

### 6.2 Boleto vivo con estado en tiempo real (E.8)

**Objetivo:** Mientras un partido está en curso, cada apuesta abierta debe mostrar su estado actual (ganando/perdiendo/indeciso) actualizado en cada tick, sin que el Director tenga que investigar o mirar detalles del partido. El estado debe cambiar automáticamente conforme el marcador avanza.

**Setup:**
- Coloca apuestas en al menos 2 tipos de mercados diferentes:
  - **Un mercado 1x2** (home/away/draw): debe reflejar **siempre** el marcador en curso, nunca estar "indeciso".
  - **Un mercado monótono** (over/under de goles, btts, first_scorer): puede estar "indeciso" si la condición aún no se ha cumplido.
- Apunta el estado inicial visible en cada boleto (deberá actualizarse a medida que juegues).

**Pasos:**

1. **Mercado 1x2 — estado en curso:**
   - Apostaste a "home" en 1x2. El partido empieza con home 1–0 arriba.
   - Mira el panel de "Apuestas pendientes" (derecha de la pantalla) → debe mostrar el boleto con estado `"vas ganando esta"` (o equivalente).
   - Avanza ticks: home sigue 1–0 → estado debe seguir siendo `"vas ganando esta"` (sin cambiar).
   - El rival iguala: 1–1 → estado debe cambiar inmediatamente a `"aún indeciso"` o `"vas perdiendo esta"` (porque tu selección "home" ya no coincide con el resultado en curso).
   - Home vuelve a adelantarse: 2–1 → estado vuelve a `"vas ganando esta"`.
   - **Señal de fallo:** Si el estado no se actualiza en el próximo tick tras cambios en el marcador, o si aparece "indeciso" para 1x2 cuando hay un marcador claro.

2. **Over/under o btts — estado indeciso permitido:**
   - Apostaste a "over 2.5" (más de 2.5 goles totales).
   - Partido en curso 0–0 en minuto 15 → estado debe ser `"aún indeciso"` (el over aún puede caer a ambos lados).
   - Marcador sube a 2–1 (3 goles totales) → estado debe cambiar inmediatamente a `"vas ganando esta"` (3 > 2.5, irreversible).
   - Si el partido terminara 1–0 (1 gol total) → estado sería `"vas perdiendo esta"` (nunca alcanzó 2.5).
   - **Señal de fallo:** Over/under apareciendo como WINNING/LOSING cuando aún es posible que caiga al otro lado; o mostrando como UNDECIDED después de que la condición ya se haya cumplido irreversiblemente.

3. **Cuánto falta para cierre (ticks_until_resolution):**
   - Cada boleto debe mostrar algo como `"cierra en min 87"` o `"cierra este tick"`.
   - A medida que avanzan ticks, el minuto de cierre debe acercarse (ej. "min 87" → "min 75" → "min 63", etc.).
   - Un mercado como "first_scorer" debe mostrar `"cierra este tick"` apenas se marque el primer gol (no espera al minuto 90).
   - **Señal de fallo:** Minuto de cierre que no avanza, o que salta de repente.

### 6.3 Feedback de resolución enérgico (E.8)

**Objetivo:** Al resolverse una apuesta (ganada o perdida), debe aparecer un overlay con feedback claro y enérgico (visual, no bloquea input). El número principal debe ser el **total acreditado** (exactamente el que viste en el boleto), con la ganancia neta como detalle secundario. La intensidad debe ser **consistente** independientemente de la fase narrativa.

**Pasos:**

1. **Victoria — números correctos y jerarquía:**
   - Una apuesta de **100$ a cuota 2.87** gana → el overlay debe mostrar:
     - **Número grande/principal:** `"+$287"` (el total acreditado, exactamente lo que el boleto mostraba como "devuelve").
     - **Detalle secundario:** `"neto +$187"` o similar (ganancia neta = 287 - 100).
   - El overlay debe estar **"arriba" de la pantalla de juego, visible pero no bloqueando los botones de avance** (lección del Bug 1).
   - **Señal de fallo:** Si el número principal muestra `"+$187"` (neto) en lugar de `"+$287"` (total), o si el overlay bloquea input.

2. **Derrota — claro y atribuible:**
   - Una apuesta de **100$ a cuota 2.50** pierde → el overlay debe mostrar:
     - **Número grande:** `"−$100"` o `"−$100"` (la pérdida, el stake hundido).
     - Sin detalles secundarios (no hay ganancia neta, solo la pérdida).
   - El overlay debe sentirse "serio" pero no deprimido (tono consistente con victoria, no más apagado).
   - **Señal de fallo:** Si no hay feedback en caso de derrota, o si la intensidad/tono baja en fases narrativas avanzadas.

3. **Resoluciones múltiples en un tick:**
   - Si 2+ apuestas se resuelven en el mismo tick, no deben solapar los overlays (riesgo de que el Director no vea ambos o se confunda).
   - Deben aparecer de forma secuencial: primero un overlay, espera brevemente, desaparece, aparece el siguiente.
   - **Señal de fallo:** Overlays superpuestos o que desaparecen demasiado rápido.

### 6.4 Consistencia numérica boleto vivo → resolución

**Objetivo:** Confirmar que el número ancla mostrado en el boleto vivo antes de la resolución **es exactamente el mismo que el que aparece en el overlay de feedback al ganar**. Esto valida que no haya "sorpresas" entre lo que ves apostando y lo que ves cobrando.

**Pasos:**

1. **Anota el número del boleto:**
   - Colocas una apuesta de 50$ a "home" en 1x2 con cuota mostrada 3.50 → boleto debe decir `"Apuestas $50 → devuelve $175"`.
   - Anota "175" en un papel o mental.

2. **Espera a que el partido termine y se resuelva:**
   - Si home gana, la apuesta se resuelve en el minuto 90 (FINAL_TICK).
   - El overlay de feedback debe mostrar `"+$175"` como número principal.
   - **Si coincide:** OK. Si no coincide (ej. muestra 180 o 170) → **bug grave de divergencia de cuota**, reportar.

3. **Repite con rango:**
   - Apuestas a "away" en 1x2 con cuota 1.80–2.00 → boleto muestra `"Apuestas $100 → devuelve $180–$200"`.
   - Si away gana, el feedback debe mostrar uno de esos dos números (depende exactamente qué cuota se usó internamente).
   - Debe estar **dentro del rango mostrado**, no fuera.
   - **Señal de fallo:** Feedback fuera del rango (ej. rango era 180–200, feedback muestra 210).

---

**Resumen de señales de fallo críticas:**
- Cuota ausente o mal mostrada en botones de opción.
- Ganancia potencial no se actualiza al cambiar stake.
- Número del boleto no coincide con el del overlay de feedback.
- Payout fuera del rango mostrado (si es rango).
- Estado vivo (WINNING/LOSING/UNDECIDED) no se actualiza tras cambios en el marcador.
- 1x2 apareciendo como UNDECIDED cuando hay un marcador claro.
- Over/under bloqueado en WINNING después de que el evento ya ocurrió (debería seguir siendo WINNING, no cambiar).
- Overlay de feedback bloqueando input o desapareciendo demasiado rápido.
- Feedback con intensidad reducida en fases narrativas 3–4 (debería ser igual en todas las fases).
## 7. D.7 y E.9 — Retirada dinámmica de mercados por minuto y UI actualizada

Los tests automatizados en `tests/` (ejecutables con Godot) validan la lógica de `MarketAvailabilityResolver` (decisiones de retirada) e integración con `MatchPanel`; esta sección documenta casos de integración UI y comportamiento en el juego que solo pueden verificarse en la máquina del Director.

**Contexto:** D.7 retira automáticamente mercados que han quedado resueltos o matemáticamente imposibles (ej. "primer goleador" después del primer gol, o "over 2.5 goles" cuando ya hay 3 goles y minutos insuficientes para más). E.9 refleja esto en la UI: los mercados retirados desaparecen o se muestran como "no disponible" con una razón breve, y los mercados vigentes siguen actualizando cuota/ganancia en cada tick.

### 7.1 Retirada de mercado tras evento decisivo

**Objetivo:** Verificar que los mercados que logran un resultado definitivo o imposible se retiran automáticamente de la oferta y no permiten nuevas apuestas.

**Setup:**
- Llega a un partido en cualquier fase (antes de que haya acción del tipo que resuelve un mercado, ej. ningún gol aún).

**Pasos — Caso A: First Scorer (resuelto por primer gol):**

1. Apunta que "primer goleador" está disponible en la oferta (debe verse entre los mercados).
2. Avanza ticks sin que se marque gol (mercado debe seguir disponible).
3. Llega a un tick donde se marca el **primer gol del partido** (cualquier equipo, cualquier jugador).
4. **Inmediatamente después** (antes de avanzar otro tick), mira la lista de mercados disponibles.
   - **Si es correcto:** "primer goleador" desaparece o aparece atenuado con etiqueta "no disponible — ya hubo gol" (o similar). Nunca puedes seleccionar una opción en ese mercado.
   - **Señal de fallo:** "primer goleador" sigue apostable después del primer gol, o sigue visible como si nada pasara.

**Pasos — Caso B: Over/Under resuelto por marcador inevitable:**

1. Busca un mercado "over/under" de goles ofertado (ej. "over 1.5 goles", "under 3.5 goles").
2. Anota el minuto actual y el umbral del mercado (ej. estamos en min 30, mercado es "over 2.5").
3. Avanza ticks. El marcador sube a **3 goles totales**.
4. A continuación, observa el mercado "over 2.5":
   - **Si es correcto:** Desaparece o muestra "no disponible — ya se cumplió el over" (porque 3 > 2.5, es irreversible).
   - **Señal de fallo:** "over 2.5" sigue apostable aunque el resultado ya está decidido.
5. **Caso complementario:** Si el partido tiene pocos minutos restantes y 0 goles, busca "over 3.5":
   - A min 85 con 0 goles totales, "over 3.5" es **imposible** (solo quedan 5 minutos, es poco probable marcar 4 goles en ese tiempo).
   - **Si D.7 aplica correctamente:** El mercado debería retirarse o marcarse como imposible con una razón similar.
   - **Nota:** Esta regla es heurística (depende del criterio que Programmer elegir para "imposible"); lo importante es que, si se retira, la razón sea clara.

### 7.2 Mercados 1x2 y BTTS nunca se retiran

**Objetivo:** Confirmar que los mercados 1x2 (resultado del partido) y BTTS (ambos equipos marcan) **nunca desaparecen**, sin importar el marcador ni el minuto.

**Setup:**
- Juega un partido cualquiera desde el minuto 0 al 90.

**Pasos:**

1. **1x2:**
   - Verifica que al inicio hay 3 opciones: "home", "away", "draw".
   - Avanza a min 30, marcador 2–0 para home. Mira la oferta.
     - **Si es correcto:** 1x2 sigue visible con sus 3 opciones (aunque probabilísticamente "home" sea casi seguro, sigue siendo ofertable).
   - Avanza a min 85, sigue 2–0. 1x2 debe seguir ofertándose.
   - **Señal de fallo:** 1x2 desaparece en algún punto; o una opción (ej. "draw") desaparece mientras las otras quedan.

2. **BTTS:**
   - Busca "BTTS" (ambos equipos marcan) si está en la lista de mercados.
   - Marcador 1–0 en min 20. BTTS debe seguir disponible (el segundo equipo aún puede marcar).
   - Marcador sigue 1–0 en min 85, minutos casi finales. BTTS debe seguir siendo ofertable (aunque poco probable, matemáticamente posible).
   - **Señal de fallo:** BTTS desaparece antes de que termine el partido.

### 7.3 Ninguna oferta nunca queda vacía

**Objetivo:** Garantizar que en cualquier momento de un partido LIVE, siempre hay al menos un mercado disponible para apostar (relación directa con el Bug 1 y la garantía de no-bloqueo).

**Setup:**
- Juega partidos variados en diferentes jornadas y marcadores.

**Pasos:**

1. En cualquier tick donde el partido siga LIVE:
   - Mira la pantalla de apuestas y cuenta **cuántos mercados están disponibles** (no atenuados, no con overlay de "no disponible").
   - **Si es correcto:** Siempre hay al menos 1 mercado apostable. Como mínimo 1x2 ó BTTS (o ambos) deben estar disponibles.
   - **Señal de fallo:** En algún tick ves que todos los mercados están atenuados/no disponibles, el tribunal aparece vacío, y no puedes apostar nada (bloqueo total).

2. **Caso especial — muchos mercados retirados a la vez:**
   - Si en un tick múltiples mercados se retiran (ej. first_scorer + varios over/under), verifica que al menos uno sigue ofertable.
   - Si resulta que `1x2` y `BTTS` se ven afectados por restricciones de Momento Crazy en ese mismo tick, verifica que **al menos uno de los dos** sigue disponible (nunca ambos restringidos).

### 7.4 Distinción visual entre "no disponible" (D.7) y "restringido por Momento Crazy" (B.3)

**Objetivo:** Verificar que los overlays/estados visuales de retirada por minuto y restricción por Momento Crazy **no se solapan** — el usuario ve claramente cuál es la razón de que un mercado no sea apostable.

**Contexto:** Este es el bug exacto que se corrigió: un mercado retirado (ej. "primer goleador" tras un gol) coincidía visualmente con un Momento Crazy activo en el mismo tick, resultando en un overlay doble y confuso. El fix asegura que **una vez retirado, nunca se muestra el overlay rojo de Crazy**.

**Setup:**
- Juega hasta que coincida un **Momento Crazy** (overlay rojo/vino, sello "CRAZY", restricción de mercados) con un tick en el que algún mercado se retira.
- Esto puede ocurrir por azar en varias runs; si quieres forzarlo, anota qué jornada/minuto típicamente activa Crazy y planifica para que coincida con un evento resolutivo (ej. un gol).

**Pasos:**

1. **Overlay único:**
   - Cuando el Crazy está activo, mira un mercado que **ya fue retirado en un tick anterior** (ej. "primer goleador" porque ya hubo gol hace 3 ticks).
   - **Si es correcto:** El mercado muestra solo la etiqueta de "no disponible — ya hubo gol" (estado de D.7). No hay overlay rojo de Crazy superpuesto.
   - **Señal de fallo:** Ves un overlay rojo + la etiqueta de razón juntos, o solo el overlay rojo sin la razón.

2. **Contraste — mercado sí restringido por Crazy:**
   - En el mismo Crazy, mira un mercado que **no está retirado por minuto**, pero **sí está restringido por Crazy** (ej. "over/under" que Crazy permite escoger, pero reduce la cantidad a 1-2 opciones).
   - **Si es correcto:** Ves el overlay rojo/vino (indicador de Crazy) sin la etiqueta de "no disponible". Las opciones restringidas se ven claramente.
   - **Señal de fallo:** Ves la misma presentación que en el caso anterior (confusión), o no hay diferencia visual entre retirado y restringido.

3. **Ambos casos en la misma pantalla:**
   - Si en un tick ves 4-5 mercados al mismo tiempo, algunos retirados y algunos restringidos:
     - Los retirados deben tener un estilo o etiqueta consistente ("no disponible + razón").
     - Los restringidos (si no son retirados) deben tener el overlay rojo de Crazy.
     - Nunca un mercado retirado debe tener el overlay rojo superpuesto.

### 7.5 Apuesta ya colocada no se ve afectada

**Objetivo:** Confirmar que una apuesta hecha **antes de que el mercado se retire** sigue resolviéndose con normalidad al final del partido, aunque el mercado ya no aparezca en la oferta disponible.

**Setup:**
- Coloca una apuesta en un mercado "destinado a retirarse" (ej. "primer goleador: Jugador X") **antes de que el evento resolutivo ocurra**.

**Pasos:**

1. **Apuesta en first_scorer:**
   - Marca "primer goleador: Jugador X" (cualquier jugador), apuesta 50$.
   - Confirma. El boleto debe aparecer en "Apuestas pendientes" con estado inicial (ej. "aún indeciso" o "vas perdiendo").
   - Avanza ticks. En algún momento se marca el **primer gol del partido** (por Jugador Y, no X).
   - Mira "Apuestas pendientes": el boleto de Jugador X debe seguir ahí, con estado actualizado a "vas perdiendo esta" (porque el mercado se decidió sin la selección).
   - Avanza hasta min 90 (final del partido).
   - El boleto debe mostrar "PERDIÓ" y restar 50$ del saldo (o si Jugador X marcó el gol después que otro, la resolución correcta según el orden).
   - **Si es correcto:** La apuesta se resuelve normalmente aunque "primer goleador" ya no esté en la oferta.
   - **Señal de fallo:** El boleto desaparece cuando el mercado se retira, o no se resuelve al final del partido.

2. **Apuesta en over/under:**
   - Apuesta 100$ a "over 2.5 goles". Confirmá.
   - Avanza ticks. Marcador llega a 3 goles totales (over se cumple, mercado se retira).
   - El boleto debe cambiar a estado "vas ganando esta" (porque ya se cumplió el over, es irreversible).
   - Avanza hasta el final.
   - El boleto se resuelve como "GANÓ" y suma 100$ × cuota al saldo.
   - **Señal de fallo:** El boleto se comporta de forma errática (desaparece, no se resuelve, muestra estado incorrecto).

---

**Resumen de señales de fallo críticas para D.7/E.9:**
- Mercado resuelto (first_scorer tras gol, over tras cumplimiento) sigue apostable.
- 1x2 o BTTS desaparece antes de final del partido.
- Algún tick quedan cero mercados apostables (bloqueo total).
- Overlay rojo de Crazy aparece sobre un mercado ya retirado.
- Apuesta colocada antes de retirada no se resuelve.
- Razón de "no disponible" no aparece o es incomprensible.


## 8. D.6 — Calendario de jornada con horarios escalonados (verificación manual)

Los cambios técnicos clave de D.6 (reloj de jornada, kickoff_offset_minutes, dedupe de Momento Crazy basado en clock_cycle) ya están implementados y fueron revisados por Architect. Esta sección documenta los casos de integración y comportamiento del juego que deben verificarse manualmente en la máquina del Director, enfocándose en los dos cambios de mayor riesgo: la transición de partidos que no arrancaban bloqueantes → partidos PRE_MATCH no bloqueantes, y el cambio de dedupe del Crazy de tick_index_in_day → clock_cycle.

### 8.1 Horario escalonado en una jornada normal

**Objetivo:** Verificar que los kickoffs ocurren a horas distintas según los offsets configurados en LeagueRules, creando una ventana de mercados vigentes en lugar de que todos arranquen a la vez.

**Setup:**
- Abre una jornada cualquiera (ej. viernes o sábado) en una run nueva o en progreso.
- Anota mentalmente (o en papel) las horas de kickoff de los ~10 partidos del día (si el selector de partidos muestra kickoff_offset_minutes, perfecto; si muestra hora bonita, aprunta esa).

**Pasos:**

1. **Kickoff 0 (arranca primero):**
   - En el instante en que entra en la jornada, debe haber ≥1 partido **ya LIVE** (estado "en juego", tick 0 abierto).
   - Los demás partidos deben verse en estado **PRE_MATCH** con hora de kickoff futura (no "en juego").
   - **Señal de éxito:** TopBar muestra reloj de jornada (ej. "sábado 16:15" / "min 0 del día"); al menos un partido en rojo LIVE, otros en gris PRE_MATCH.
   - **Señal de fallo:** Todos los partidos aparecen LIVE a la vez, o TopBar no muestra hora de jornada.

2. **Avanza ticks y observa cambios de estado:**
   - Juega 1-2 ticks del primer partido LIVE (debe resolver su tick 0, luego tick 1).
   - Aprunta en qué "minuto de jornada" esté cuando el reloj avanzo (TopBar debe subir: min 0 → 15 → 30, etc.).
   - **Observación clave:** Si los offsets están distribuidos en [0, 15, 15, 30, 45, 60, 75, 90, 90, 105] (o similar), entonces:
     - Min 0–14: solo 1 partido LIVE (offset 0).
     - Min 15–29: ahora 2–3 partidos LIVE (offsets 0, 15, 15 se activan).
     - Min 30–44: 2–3 LIVE (offsets 30 se suma, offsets 15 terminan sus ticks → FINISHED).
     - Y así sucesivamente, creando un patrón "arranque, pico, cola".
   - **Señal de éxito:** La lista de estados (PRE_MATCH/LIVE/FINISHED) cambia a medida que avanzan ticks. En algún momento ves 2–3 partidos LIVE simultáneamente (el "pico").
   - **Señal de fallo:** Siempre hay solo 1 partido LIVE, o de repente todos se vuelven LIVE a la vez en min 0.

3. **Fin de jornada:**
   - Avanza hasta que todos los partidos sean FINISHED (incluyendo el de offset 105, que LIVE en ciclos 7–12).
   - El siguiente click en "Continuar" debe abrir la jornada siguiente (p. ej. sábado si estabas en viernes) sin bloquear.
   - **Señal de éxito:** Transición suave de jornada sin pausa anormal.
   - **Señal de fallo:** Bloqueo esperando un partido que nunca arrancó, o crash.

### 8.2 Ningún partido PRE_MATCH bloquea antes de su kickoff

**Objetivo:** Verificar que un partido que todavía no ha hecho kickoff (estado PRE_MATCH) no interfiere con la progresión del juego — no genera ticks obligatorios, no exige apuesta obligatoria, no emite comentarios.

**Setup:**
- Entra a una jornada donde haya al menos 2–3 partidos con offsets distintos (ej. offset 0 y offset 30).
- Aprunta cuál es el primer partido LIVE (offset 0) y cuál está PRE_MATCH (offset 30).

**Pasos:**

1. **Partido PRE_MATCH no requiere apuesta:**
   - En el primer tick (min 0–15), cambia el foco al partido con offset 30 (todavía PRE_MATCH).
   - Mira la UI de apuestas: debe mostrar mercados de "pre-partido" (marcador inicial 0-0, min 0), pero **SIN etiqueta de "apuesta obligatoria"** ni overlay de "debes apostar".
   - Intenta avanzar el tick sin hacer ninguna apuesta en ese partido PRE_MATCH.
   - **Señal de éxito:** El botón "Continuar →" se habilita solo con la apuesta en el partido LIVE (offset 0), ignorando el PRE_MATCH.
   - **Señal de fallo:** El botón no se habilita, o aparece un mensaje "debes apostar en todos los partidos" (indicaría que PRE_MATCH cuenta erróneamente como LIVE).

2. **Partido PRE_MATCH no genera comentarios ni acción:**
   - Mientras el partido PRE_MATCH sigue en ese estado, mira la zona de comentarios/acciones.
   - **Si es correcto:** No hay comentarios específicos del partido PRE_MATCH, solo del partido LIVE (offset 0).
   - **Señal de fallo:** Ves comentarios del partido PRE_MATCH como si estuviera en juego ("Saca del fondo...", "Arranca por la banda...").

3. **Cambio a LIVE — tick 0 emitido en el momento exacto:**
   - Juega hasta que el reloj llegue al minuto en que el partido con offset 30 debe hacerse LIVE (min 30 = ciclo 2).
   - En el `advance_tick()` que cruza esa línea:
     - El partido debe emitir su **tick 0 (kickoff)** inmediatamente.
     - Debe pasar a status LIVE.
     - Debe aparecer en la UI como "en juego, min 0" (no "pre-partido").
   - **Señal de éxito:** Transición suave, sin bloqueo, sin tick duplicado.
   - **Señal de fallo:** El partido no emite tick 0 en ese ciclo, o se salta, o bloquea.

### 8.3 Botón "Continuar" nunca se bloquea esperando un partido que no ha empezado

**Objetivo:** Validar el gate de avance de tick (§6 de la spec, `_matches_with_tick_open_this_cycle` y `_all_matches_satisfied_this_cycle`): solo cuentan partidos LIVE, nunca PRE_MATCH.

**Setup:**
- Simula una jornada con 3 partidos: offset 0 (LIVE desde ciclo 0), offset 30 (PRE_MATCH ciclos 0–1, LIVE desde ciclo 2), offset 60 (PRE_MATCH ciclos 0–3, LIVE desde ciclo 4).

**Pasos:**

1. **Ciclos 0–1 (solo offset 0 LIVE):**
   - Cíclo 0 (min 0–15): solo 1 partido (offset 0) está LIVE. Apuesta el mínimo (50$) en ese partido.
   - Click "Continuar →" → debe habilitarse de inmediato (no debe esperar a que offset 30 y 60 arranquen).
   - Avanza a ciclo 1 (min 15–30).
   - **Señal de éxito:** Sin bloqueo. El gate ignora los otros partidos PRE_MATCH.
   - **Señal de fallo:** El botón dice "esperando apuestas en X partidos" refiriéndose a los PRE_MATCH.

2. **Ciclo 2 (offset 0 LIVE, offset 30 acaba de empezar LIVE, offset 60 PRE_MATCH):**
   - Min 30–45 (ciclo 2): ahora 2 partidos LIVE (offsets 0 y 30).
   - Apuesta en ambos. Click "Continuar →".
   - **Señal de éxito:** Se habilita sin esperar al offset 60 (que sigue PRE_MATCH).
   - **Señal de fallo:** Bloqueo, o mensaje mencionando "3 partidos" en lugar de "2".

3. **Ciclo 4 (todos LIVE):**
   - Min 60–75 (ciclo 4): los 3 están LIVE.
   - Apuesta en los 3. Click "Continuar →".
   - **Señal de éxito:** Botón se habilita normalmente.
   - **Señal de fallo:** Algún comportamiento raro diferente a ciclos anteriores (no debería haber diferencia).

### 8.4 Jornada especial concentrada (CONCENTRATED schedule)

**Objetivo:** Verificar que en una jornada marcada CONCENTRATED (ej. última jornada de la temporada, "Super Sunday"), todos o casi todos los partidos comparten kickoff, y que el reparto por días (viernes/sábado/domingo) se ajusta correctamente — los días vacíos se saltan sin bloquear.

**Setup:**
- Juega hasta la **última jornada de la temporada** (jornada 38 u otra, dependiendo de TOTAL_MATCHDAYS en LeagueRules).
- O, si quieres forzar, edita manualmente `LeagueRules.SPECIAL_MATCHDAY_EVERY_N` para que una jornada anterior sea marcada CONCENTRATED (aunque no es recomendado en una sesión de test manual, es solo para debugging).

**Pasos:**

1. **Todos/casi todos los partidos comparten offset:**
   - Entra en la jornada especial.
   - Anota los offsets de los ~10 partidos del día (o mirá el selector de partidos para ver kickoffs).
   - **Si es correcto:** Todos (o la mayoría) tienen el mismo offset, ej. todos con offset 0.
   - **Señal de éxito:** En min 0 del día, **todos los ~10 partidos son LIVE a la vez** (no 1–3 como en escalonado).
   - **Señal de fallo:** Offsets sigue siendo [0, 15, 15, 30, ...] (escalonado normal), cuando debería ser [0, 0, 0, ...] (concentrado).

2. **Días vacíos se saltan sin bloqueo:**
   - Si la jornada CONCENTRATED tiene todos los partidos en **solo 1 día** (ej. todo en domingo), entonces viernes y sábado estarán vacíos.
   - Entra a viernes. Debe estar **completamente vacío** — 0 partidos LIVE, 0 partidos PRE_MATCH.
   - Click "Continuar →" en viernes vacío.
   - **Si es correcto:** El juego **salta instantáneamente** a sábado (o al primer día con partidos) sin mostrar ninguna pantalla de "no hay partidos", sin countdown, sin bloqueo.
   - **Nota según sección 11.2 de spec:** La Historia E.10 (pantalla "No hay partidos hoy") aún no está implementada. Por eso el salto es silencioso — **esto es lo esperado, NO es un bug**. Si ves una pantalla de descanso o aviso, eso sería implementación de E.10, fuera del scope de D.6 (reporte informativo, no fallo).
   - **Señal de fallo:** Bloqueo en viernes vacío, o crash, o que no avance a sábado.

3. **Todos los partidos LIVE a la vez, con pico de apuestas:**
   - Una vez en el día con partidos (domingo), todos los ~10 están LIVE (offset 0).
   - Intenta jugar 1–2 ticks: debería haber apuesta obligatoria en **todos** los 10 partidos (mucho más trabajo que un día escalonado).
   - **Señal de éxito:** La UI muestra "10 partidos LIVE", selector múltiple, apuesta obligatoria repartida. Sin bloqueo, sin error.
   - **Señal de fallo:** Partidos que no aparecen en la oferta, o crash al intentar cambiar entre 10 partidos LIVE.

### 8.5 Momento Crazy con partidos en horarios distintos — verificación de regresión del dedupe (clock_cycle)

**Objetivo:** Validar el fix del Momento Crazy que se coordina con D.6: el dedupe cambió de `tick_index_in_day` (que era común a todos, cuando todos arrancaban a la vez) a `clock_cycle` (el ciclo de reloj global, independiente de cuándo arranca cada partido). **Este es el caso de regresión más importante de D.6**, porque el cambio de base técnica fue lo que habilitó la feature.

**Contexto técnico (§9 y §11.1 de spec):**
- Antes: Todos los partidos tenían `tick_index` común en lockstep. Deduplicación: si `tick_index_in_day == X`, Crazy dispara una sola vez.
- Ahora: Partidos arrancan en ciclos distintos con `kickoff_offset`, cada uno tiene su `current_tick_index`. Deduplicación: se basa en `(day, clock_cycle)` de `BetTickContext`, que es el ciclo del reloj global (0–5 típicamente, solapado con todos los ticks de todos los partidos).

**Setup:**
- Juega varias runs hasta que se active un **Momento Crazy** en una jornada donde haya múltiples partidos con offsets distintos (ej. una jornada STAGGERED normal).
- Ej. offset 0, 15, 30, ... — el ideal es que al dispararse Crazy, haya partidos recién arrancados, a mitad, etc.

**Pasos:**

1. **Crazy dispara exactamente una sola vez (no múltiples veces por el mismo ciclo):**
   - Llega a un tick donde se activa Momento Crazy (overlay rojo/vino, sello "CRAZY", % forzoso visible).
   - Anota el **% forzoso** mostrado (ej. 50%, 70%) y el **importe exacto** (ej. 200$ si saldo es 400).
   - Ahora, **sin apostar aún**, cambia el foco entre partidos en distintas fases:
     - Partido A: offset 0, ya en tick 2 (mitad del match).
     - Partido B: offset 15, recién emitió tick 0 (kickoff).
     - Partido C: offset 30, todavía PRE_MATCH (no está LIVE aún).
   - Mira en cada uno si el overlay rojo de Crazy sigue siendo **idéntico** (mismo %, mismo importe, mismos mercados permitidos).
   - **Señal de éxito:** Overlay invariante entre partidos. El % y el importe NO cambian cuando cambias de partido. (Esto valida que el Crazy se dispara UNA sola vez por `clock_cycle`, no por partido.)
   - **Señal de fallo:** Overlay cambia entre partidos (ej. en A es 50%, en B es 70%) — indica que se está disparando múltiples veces incorrectamente, dedupe roto.

2. **"Continuar" se habilita tras apostar el monto en un solo partido:**
   - Apostá el importe forzoso en uno de los partidos LIVE (ej. Partido A).
   - El botón "Continuar →" debe habilitarse de inmediato.
   - **Señal de éxito:** Sin bloqueo. Esto es exactamente lo que se corrigió en el Bug 1.
   - **Señal de fallo:** Botón sigue deshabilitado, o pide apuesta también en otros partidos.

3. **Mercados permitidos son los mismos en todos los partidos:**
   - Durante el mismo Crazy, mira qué mercados están permitidos para apostar (Crazy restringe a 1–2 mercados típicamente).
   - Ej. "solo 1x2 y BTTS" o "solo 1x2".
   - Cambia entre partidos: la restricción debe ser **idéntica** (mismos mercados permitidos, mismos bloqueados).
   - **Señal de éxito:** Restricción uniforme.
   - **Señal de fallo:** En Partido A puedes usar "1x2 y BTTS", en Partido B solo "1x2" — inconsistencia indica que el Crazy se está evaluando por partido, no globalmente.

4. **Dos Crazy en la misma run, en ciclos distintos:**
   - Si tienes suerte y te toca un segundo Momento Crazy en la misma run (ej. viernes y sábado), verifica que el segundo se dispare correctamente.
   - Debe mostrar un overlay rojo nuevo (puede ser % diferente, importe diferente — eso es normal, es otro Crazy sorteado).
   - **Señal de éxito:** Segundo Crazy dispara sin problema, sin "quedarse inhibido" por el primero.
   - **Señal de fallo:** Segundo Crazy no aparece, o aparece pero está "pegado" al anterior.

5. **Invariante de arranque — siempre hay LIVE en el rango sorteado:**
   - **Contexto:** Según la decisión 11.1, el sorteo de Crazy elige un `clock_cycle` en `[1, 5]` (ciclos medios de la jornada). La invariante implementada en `assign_staggered_offsets` garantiza que siempre hay ≥1 partido con offset 0, que LIVE en ciclos 0–5. Por tanto, cualquier ciclo sorteado en `[1, 5]` tiene ≥1 partido LIVE que emite su tick en ese ciclo → Crazy siempre dispara, nunca se pierde silenciosamente.
   - **Cómo verificar:** Juega varias runs (10–20) en jornadas STAGGERED. En cada una, verifica que **Crazy siempre dispara** (al menos una vez por run, aunque puede ser ninguno si el sorteo no activa en esa run). Nunca debe ocurrir una situación donde "estoy en sábado, debería haber Crazy pero no aparece nada y el día termina".
   - **Señal de éxito:** Crazy dispara consistentemente cuando se espera (a veces sí, a veces no, pero nunca desaparece silenciosamente sin razón).
   - **Señal de fallo:** Juega 5–10 runs sin ver ningún Crazy (improbable, ~8% de chance por day × 3 days = ~22% por run; si no ves ninguno en 10 runs es sospechoso). O ves que un día debería tener Crazy pero no aparece (auditar la consola de Godot).

---

**Resumen de señales de fallo críticas para D.6:**
- Todos los partidos LIVE a la vez en una jornada STAGGERED (debería haber escalonado 1–3 máximo).
- Partido PRE_MATCH requiere apuesta obligatoria (debe permitir avanzar sin apostar).
- Botón "Continuar →" bloqueado esperando un partido que aún no ha arrancado (PRE_MATCH).
- Jornada CONCENTRATED no concentra kickoffs (offsets siguen siendo [0, 15, 30, ...]).
- Día vacío en jornada concentrada no se salta (bloqueo).
- Momento Crazy cambia de % o importe cuando cambias entre partidos (dedupe roto).
- Momento Crazy no se habilita "Continuar" tras apostar en un partido (Bug 1 reintroducido).
- Mercados permitidos por Crazy son distintos entre partidos (Crazy evaluado por partido, no globalmente).
- Momento Crazy desaparece silenciosamente en una jornada STAGGERED (invariante de arranque violada).

## 9. E.10 — Pantalla breve "no hay partidos hoy" en días vacíos (jornadas concentradas)

Contexto: Historia pequeña de pulido UI que añade una pantalla breve con desaparición automática cuando la run detecta un día sin partidos en una jornada concentrada (ej. "Super Sunday" — última jornada de liga donde todos los partidos se concentran en domingo, dejando viernes/sábado vacíos).

Ref: spec técnica `.ai-studio/specs/story-e10-dia-vacio.md`.

**Corrección post-implementación (sección 9 de la spec):** El texto de la pantalla debe mostrar el **próximo día CON partidos** (ej. "domingo"), no el día inmediatamente siguiente en el calendario. En un "Super Sunday" con viernes y sábado vacíos, la pantalla de viernes y la de sábado deben ambas decir "domingo", no "sábado/domingo" respectivamente.

### 9.1 Pantalla aparece en jornada concentrada, día vacío

**Objetivo:** Verificar que cuando se llega a un día sin partidos en una jornada CONCENTRATED (ej. viernes en "Super Sunday"), la pantalla breve aparece con un aviso antes de que la run continúe.

**Setup:**
- Juega hasta llegar a la **última jornada de la temporada** (jornada 38 o equivalente, según `TOTAL_MATCHDAYS` en `LeagueRules`), o la que esté marcada como SPECIAL/CONCENTRATED.
- Verifica que esa jornada tiene todos (o casi todos) los partidos el mismo día (ej. domingo), dejando viernes y sábado vacíos.

**Pasos:**

1. Al avanzar desde el jueves a viernes (de la jornada concentrada), el juego carga el día.
   - No hay partidos en viernes (es un día vacío en esta jornada).
2. **Señal de éxito:** Inmediatamente (antes de que aparezca el countdown de aterrizaje ni ningún partido LIVE) aparece una pantalla breve superpuesta diciendo algo como:
   - **Título:** `"No hay partidos hoy"`
   - **Detalle:** `"La jornada se concentra en [día]."` (ej. `"La jornada se concentra en domingo."`)
   - La pantalla es gris/atenuada, no interactiva (no pide click).
3. La pantalla desaparece automáticamente tras ~2 segundos (ver sección 9.3 para duración exacta).
4. Después de que desaparece, la run avanza automáticamente a sábado (día siguiente, que también está vacío).
5. **Señal de fallo:**
   - La pantalla no aparece en viernes vacío → la run no muestra feedback, solo salta.
   - La pantalla aparece pero necesita un click para cerrar → bloquea el ritmo (Bug 1).
   - El texto dice un día incorrecto (ej. "se concentra en sábado" cuando debería decir "domingo").

### 9.2 Pantalla NO aparece en jornada normal

**Objetivo:** Confirmar que en una jornada STAGGERED normal (con partidos escalonados a lo largo de viernes/sábado/domingo), la pantalla de "no hay partidos" nunca aparece.

**Setup:**
- Juega una jornada normal (cualquiera excepto la última, o si la última no está marcada como CONCENTRATED).
- Verifica que esa jornada tiene partidos distribuidos a lo largo de viernes, sábado y domingo (offsets [0, 15, 15, 30, ...]).

**Pasos:**

1. Avanza a viernes de esa jornada normal.
2. Espera a ver el countdown de aterrizaje y los primeros partidos LIVE.
3. **Señal de éxito:** La pantalla breve de "no hay partidos" nunca aparece. Ves directamente el countdown y los partidos.
4. Juega viernes completo → avanza a sábado → la pantalla breve nunca aparece.
5. **Señal de fallo:**
   - La pantalla aparece en una jornada normal (indica error en la lógica de detección de día vacío).
   - Algún día que debería tener partidos se ve como vacío.

### 9.3 Cierre automático sin necesidad de click

**Objetivo:** Validar que la pantalla se cierra sola tras un tiempo breve, manteniendo el ritmo del juego sin requerir input del jugador.

**Setup:**
- Llega a un día vacío en una jornada concentrada (como en 9.1).

**Pasos:**

1. La pantalla aparece.
2. **Sin hacer nada** (no muevas el ratón, no hagas click, no toques nada):
   - Cronometra mentalmente cuánto tarda en desaparecer.
   - **Señal de éxito:** Desaparece automáticamente en ~1.5–2.0 segundos (rango especificado: 1.8 es el default, 1.5–2.0 es aceptable).
   - La pantalla está posicionada donde no interfiere con botones (ej. centrada, no sobre "Continuar").
   - No hay overlay adicional (ej. no aparece un botón de "cerrar" u overlay bloqueante).
3. Si intentas hacer click **sobre la pantalla** durante esos ~2 segundos:
   - **Si es correcto:** El click se ignora (pasa por la pantalla sin efecto, `mouse_filter = IGNORE` en la spec).
   - **Señal de fallo:** El click interactúa con algo detrás (hace que desaparezca antes, o selecciona un botón).

### 9.4 [día] apunta al próximo día CON partidos, no al siguiente en calendario

**Objetivo:** Verificar el fix clave de E.10: en una jornada concentrada con múltiples días vacíos consecutivos, la pantalla de cada día vacío dice el **primer día que sí tiene partidos**, no el día calendario siguiente.

**Setup:**
- Último matchday (ej. jornada 38) con todos los partidos en domingo.
- Viernes y sábado ambos están vacíos.

**Pasos:**

1. Avanza a **viernes** de esa jornada concentrada.
2. La pantalla aparece. Anota el texto exacto, especialmente la parte de "[día]".
   - **Señal de éxito:** Dice `"La jornada se concentra en domingo."` (no "sábado").
   - **Señal de fallo:** Dice `"La jornada se concentra en sábado."` (es el error que se corrigió en la sección 9 de la spec).
3. Espera a que desaparezca. La run avanza a sábado.
4. En **sábado** (que también está vacío), aparece la pantalla de nuevo.
5. Anota nuevamente el texto.
   - **Señal de éxito (crítica):** También dice `"La jornada se concentra en domingo."` (mismo que viernes).
   - **Señal de fallo:** Dice `"La jornada se concentra en domingo para sábado"` o algo inconsistente. **Esto indicaría que sábado tiene una referencia diferente, un bug en el lookahead `_next_day_with_matches`.**
6. Espera a que desaparezca. La run avanza a domingo, donde hay partidos → flujo normal.

### 9.5 Cascada correcta: múltiples pantallas en secuencia

**Objetivo:** Verificar que si hay 2+ días vacíos seguidos (viernes y sábado), se ven 2+ pantallas breves en secuencia, sin bloqueos, cada una cerrándose antes de que aparezca la siguiente.

**Setup:**
- Mismo que en 9.4: jornada concentrada con viernes y sábado vacíos.

**Pasos:**

1. Entra a viernes vacío.
   - Pantalla 1 aparece: `"No hay partidos hoy"` / `"La jornada se concentra en domingo."`
   - Cronometra: desaparece en ~2 segundos.
2. Inmediatamente (sin pause manual), aparece la **Pantalla 2** (sábado vacío):
   - `"No hay partidos hoy"` / `"La jornada se concentra en domingo."` (mismo texto que viernes, porque ambos apuntan a domingo).
   - Desaparece en otros ~2 segundos.
3. Inmediatamente después, la run llega a **domingo con partidos** → ves el countdown y los partidos LIVE (flujo normal).

**Señal de éxito:**
- Las 2 pantallas aparecen en secuencia clara: viernes, espera, desaparece; sábado, espera, desaparece; domingo aparece.
- No hay superposición de pantallas.
- El texto es consistente (ambas dicen "domingo").
- Tiempo total: ~4–5 segundos desde que entras a viernes hasta que ves domingo.

**Señal de fallo:**
- Las pantallas se solapan (confusión visual).
- Una pantalla desaparece instantáneamente antes de ser legible.
- El texto cambia entre viernes y sábado (indica lookahead incorrecto).
- Bloqueo en algún punto (indicaría que la cascada no está automatizada).

### 9.6 No reintroduce Bug 1: sin gate de apuesta obligatoria en días vacíos

**Objetivo:** Garantizar que durante el salto de días vacíos (cuando aparecen las pantallas breves), no se abre ningún tick, no hay mercados, y por tanto no hay apuesta obligatoria que bloquee el botón "Continuar".

**Setup:**
- Mismo que en 9.4/9.5: jornada concentrada, viernes y sábado vacíos.

**Pasos:**

1. Entra a viernes vacío. Pantalla breve aparece.
2. Mira la UI de apuestas:
   - **Si es correcto:** No hay mercados visibles, no hay overlay de "debes apostar", no hay partidos en la lista.
   - La pantalla de "no hay partidos hoy" es lo único que se muestra (además del background del juego).
3. Intenta mirar si el botón "Continuar →" está habilitado o deshabilitado:
   - **Esperado:** El botón debe estar **deshabilitado** (porque técnicamente no hay partidos en viernes para apostar), PERO **no debe mostrar un mensaje de espera** como "esperando apuestas en X partidos".
   - **Alternativa aceptable:** Si el botón está **habilitado** directamente durante la pantalla breve (ignorando viernes por ser vacío), es correcto también.
4. Espera a que la pantalla desaparezca automáticamente (sin requerir apuesta, sin bloqueo).
5. La run avanza a sábado → repite lo mismo.
6. Llega a domingo → ves la apuesta obligatoria normal.

**Señal de éxito:**
- Ninguna pantalla "estás en bancarrota" ni "obligatorio apostar" durante viernes/sábado vacíos.
- El botón "Continuar" no dice "esperando apuestas en viernes" cuando estás en viernes vacío.
- La transición es automática sin intervención del jugador.

**Señal de fallo (Critical):**
- Aparece el gate de apuesta obligatoria en un día vacío (Bug 1 reintroducido).
- El botón "Continuar" se bloquea esperando una apuesta en viernes/sábado vacío.
- Hay un overlay de apuesta obligatoria que no se cierra automáticamente.

---

**Resumen de señales de fallo críticas para E.10:**
- Pantalla no aparece en día vacío de jornada concentrada.
- Pantalla aparece en día CON partidos (falsa positiva).
- Pantalla no desaparece automáticamente (requiere click o queda pegada).
- Texto muestra día incorrecto (ej. "sábado" en lugar de "domingo" en un Super Sunday).
- Pantallas múltiples se solapan o desaparecen demasiado rápido para ser leídas.
- Gate de apuesta obligatoria aparece en día vacío (Bug 1 reintroducido).
- Cascada no es secuencial (varios días vacíos no se procesan en orden).
- Texto inconsistente entre pantallas de viernes y sábado (indicaría lookahead quebrado).


## 10. Fuera de alcance de esta primera ronda de pruebas

- Fases narrativas 3 y 4 del deterioro (requieren 13+ y 21+ runs jugadas — poco práctico en una sesión corta).
- Contenido narrativo real: todo el texto de comentarios, Expediente e intro está en placeholders "pendiente de redacción" — no es un bug, falta escribirlo.
- Arte/estética: todo usa controles básicos de Godot sin estilizar.

---

**Si encontrás algo que no coincide con lo descrito acá**, copiame: qué hiciste paso a paso, qué esperabas, qué pasó, y cualquier error de la consola de Godot — con eso lo mando de vuelta al estudio para que lo investiguen.
