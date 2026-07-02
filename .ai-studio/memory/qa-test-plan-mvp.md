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


## 8. Fuera de alcance de esta primera ronda de pruebas

- Fases narrativas 3 y 4 del deterioro (requieren 13+ y 21+ runs jugadas — poco práctico en una sesión corta).
- Contenido narrativo real: todo el texto de comentarios, Expediente e intro está en placeholders "pendiente de redacción" — no es un bug, falta escribirlo.
- Arte/estética: todo usa controles básicos de Godot sin estilizar.

---

**Si encontrás algo que no coincide con lo descrito acá**, copiame: qué hiciste paso a paso, qué esperabas, qué pasó, y cualquier error de la consola de Godot — con eso lo mando de vuelta al estudio para que lo investiguen.
