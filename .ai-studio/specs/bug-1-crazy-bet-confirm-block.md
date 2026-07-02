# Bug 1 — Bloqueo al confirmar la apuesta forzosa de un Momento Crazy — spec de fix

Estado: diagnóstico de Architect a partir de lectura del código. **No implementa el fix** — deja para
Programmer qué está mal y qué debe cambiar. No contiene GDScript final, solo contratos/firmas afectadas.

Reporte origen: `.ai-studio/memory/backlog.md` → "## Bugs → Bug 1". Contrato de referencia:
`.ai-studio/specs/epic-e-pantalla-de-apuestas.md` sección 3.4 y `.ai-studio/specs/epic-b-economia-de-run.md`
B.3.

---

## 1. Síntoma reportado

Saldo 831$. Se dispara un Momento Crazy (tinte rojo/vino a pantalla completa + sello "CRAZY" + texto
"50% obligatorio ($416)"). El jugador no consigue completar la apuesta forzosa y el botón `Continuar →`
permanece deshabilitado — la run queda atascada en ese tick.

---

## 2. Ruta de código recorrida (evidencia)

- `MatchSimulationService.advance_tick()` (`scenes/betting/match_simulation_service.gd`) itera **todos los
  partidos activos del día** y por cada uno emite `EventBus.bet_tick_resolved` seguido de
  `EventBus.bet_tick_opened(context)`. Todos los partidos del día avanzan en lockstep, así que **comparten el
  mismo `context.tick_index_in_day`**.
- `RunState._on_bet_tick_opened()` (`autoloads/run_state.gd`) está suscrito a `bet_tick_opened` y, si
  `CrazyMomentScheduler.is_crazy_moment_tick(schedule, day, tick_index)` es `true`, construye un
  `CrazyBetContext` con `CrazyBetResolver.build_context(...)` y emite `EventBus.crazy_moment_triggered`.
- `BettingRoot._on_crazy_moment_triggered()` (`scenes/betting/betting_root.gd`) guarda
  `_active_crazy_bet`, pone `_crazy_bet_resolved_this_tick = false`, muestra el overlay y aplica la
  restricción a **todos** los `MatchPanel`.
- El gate de avance vive en `BettingRoot._all_matches_satisfied_this_cycle()`:
  ```
  if _active_crazy_bet != null and not _crazy_bet_resolved_this_tick:
      return false            # <- mientras esto sea cierto, "Continuar" nunca se habilita
  ```
- `_crazy_bet_resolved_this_tick` solo pasa a `true` en `BettingRoot._on_match_panel_bet_confirmed()` si:
  ```
  _active_crazy_bet.allowed_market_ids.has(market_offer.market_id)
      and stake >= _active_crazy_bet.forced_stake_amount
  ```

---

## 3. Causa raíz (defecto primario) — el Momento Crazy se dispara N veces por tick, una por partido

`is_crazy_moment_tick()` compara solo `(day, tick_index)`, y `advance_tick()` emite un `bet_tick_opened`
**por cada partido vivo del día** con el mismo `tick_index_in_day`. Resultado: en un tick marcado como Crazy,
`RunState._on_bet_tick_opened()` se ejecuta una vez por partido y **emite `crazy_moment_triggered` N veces**
(N = nº de partidos vivos), cada emisión con un `CrazyBetContext` **re-sorteado de forma independiente**
(`CrazyBetResolver.roll_stake_percentage` usa `rng` en cada llamada, y `select_restricted_markets` sortea la
exclusión).

Esto **viola el contrato ya fijado** (`epic-e` §3.4: *"B.3 calcula un único `CrazyBetContext` por tick
disparado"*; `epic-b` B.3: *"la siguiente apuesta obligatoria", en singular*).

Consecuencias observables, todas coherentes con el síntoma reportado:

1. **El % forzoso y el importe cambian bajo el jugador.** El overlay y el estado aplicado terminan reflejando
   el *último* sorteo. Con una jornada de varios partidos (el caso normal: viernes reparte ~4 partidos, ver
   `BettingRoot._split_matches_for_day`), el jugador ve un valor que puede saltar (p. ej. de 50% a 100%)
   respecto al primer flash.
2. **El conjunto de mercados permitidos cambia entre sorteos.** Un mercado que quedó permitido y quizá ya
   seleccionado por el jugador en el primer contexto puede pasar a `set_restricted(true)` en el último
   (`MatchPanel.apply_crazy_moment_restriction` marca restringidos los no permitidos **sin** limpiar el
   forced stake previo). El jugador percibe "no me deja apostar aquí" y el botón sigue deshabilitado.
3. **Riesgo de divergencia de estado.** Hoy el "for todos los paneles" de `_on_crazy_moment_triggered`
   mantiene `BettingRoot._active_crazy_bet` y cada `MatchPanel._active_crazy_bet` sincronizados en el último
   contexto — pero es un invariante frágil repartido entre 3 archivos (`betting_root.gd`, `match_panel.gd`,
   `market_widget.gd`). Cualquier reordenación de señales lo rompe y produce exactamente el deadlock de §4.

---

## 4. Deadlock latente confирmado en el gate (a blindar en el fix)

`_all_matches_satisfied_this_cycle()` se queda en `false` **para siempre** si el jugador coloca una apuesta
que NO satisface la condición de resolución del Crazy (`allowed_market_ids.has(mid) and stake >= forced`)
mientras `_active_crazy_bet != null` y `_crazy_bet_resolved_this_tick == false`. Es decir: basta con que la
apuesta aceptada por `MatchPanel` no coincida con `BettingRoot._active_crazy_bet` (mercado no incluido en el
contexto vigente, o stake por debajo del forzoso vigente) para que:

- `panel.has_bet_this_tick()` sea `true` (el jugador cree que ya apostó), pero
- `_crazy_bet_resolved_this_tick` siga `false` → botón deshabilitado sin salida.

El único motivo por el que hoy "no debería ocurrir" es que `MarketWidget`/`MatchPanel` fuerzan el stake y
restringen mercados según *su* contexto — pero ese contexto puede divergir del de `BettingRoot` por el
defecto primario (§3.3). **El fix debe eliminar la posibilidad estructural de este estado, no solo el
disparador actual.**

---

## 5. Defecto secundario — `select_restricted_markets` opera sobre ofertas por-opción, no por-mercado

`CrazyBetResolver.select_restricted_markets(available, rng)` recibe `context.available_markets`, que es
`Array[MarketOffer]` con **una entrada por opción apostable** (3 para `1x2`, 2 para cada over/under, N para
`first_scorer`...). El algoritmo:

- calcula `highest_confidence` sobre *ofertas individuales* (una sola opción, no el mercado);
- construye `allowed` haciendo `allowed.append(market.market_id)` recorriendo ofertas y cortando en
  `CRAZY_BET_MAX_ALLOWED_MARKETS` (=2).

Como las ofertas llegan agrupadas por mercado, `allowed` termina siendo **dos copias del mismo `market_id`**
(p. ej. `["1x2","1x2"]`), de modo que un Momento Crazy ofrece de hecho **un solo mercado**, no los 1-2
previstos por B.3, y "el mercado más seguro" que se excluye se decide por la confidence de **una opción**
suelta, no del mercado. Esto reduce la salida del jugador a un único mercado (a veces incómodo) y agrava la
percepción de bloqueo.

---

## 6. Fragilidad adicional (no bloqueante, corregir de paso)

`BettingRoot._on_crazy_moment_ended()` pone `_crazy_bet_resolved_this_tick = false` **y**
`_active_crazy_bet = null`. Funciona hoy solo porque ambos cambian a la vez; el flag "resuelto" y el ciclo de
vida de `_active_crazy_bet` deberían gestionarse en un único lugar para no depender de ese acoplamiento.

---

## 7. Qué debe cambiar (para Programmer) — sin implementar aquí

### 7.1 Un único `CrazyBetContext` por tick (fix del defecto primario)
Garantizar que un tick marcado como Crazy dispare `crazy_moment_triggered` **exactamente una vez**, aunque
`bet_tick_opened` se emita N veces (una por partido). Opciones válidas, a criterio de Programmer:

- **Recomendada (mínima):** en `RunState`, deduplicar por `(day, tick_index_in_day)` — recordar el último
  tick para el que ya se disparó el Crazy y no volver a construir/emitir hasta que `tick_index_in_day`
  avance. El `CrazyBetContext` se construye con las `available_markets` del **primer** `bet_tick_opened`
  elegible de ese tick (los `market_id` son homogéneos entre partidos; ver §5). `forced_stake_amount` se
  calcula sobre `current_money` en ese instante (tras el payout de ese partido), coherente con B.3.
- Alternativa: mover el disparo del Crazy fuera del handler per-partido a un único punto por ciclo de
  `advance_tick`. Más limpio pero de mayor alcance; solo si Programmer lo prefiere.

Criterio: con una jornada de 2, 4 y 10 partidos vivos en el mismo tick Crazy, `crazy_moment_triggered` se
emite una sola vez y el importe/mercados mostrados por el overlay coinciden con los que enforced el gate.

### 7.2 `select_restricted_markets` por mercado, no por opción (fix del defecto secundario)
Reescribir la selección para operar sobre el **conjunto de `market_id` distintos** presentes en
`available_markets`: derivar una confidence representativa por mercado (p. ej. la máxima de sus opciones),
excluir el **mercado** más seguro/informado, y permitir hasta `CRAZY_BET_MAX_ALLOWED_MARKETS` mercados
**distintos** (respetando `CRAZY_BET_MIN_ALLOWED_MARKETS`). `allowed_market_ids` no debe contener duplicados.
La firma pública de `CrazyBetResolver.build_context(...)` y `CrazyBetContext` no cambian.

### 7.3 Blindar el gate contra el deadlock (fix del defecto de §4)
Hacer imposible el estado "apuesta colocada + Crazy sin resolver + botón bloqueado":
- Fuente única de verdad del contexto Crazy vigente (que `MatchPanel`/`MarketWidget` y `BettingRoot`
  compartan literalmente el mismo `CrazyBetContext`, no copias que puedan divergir), y
- Que cualquier apuesta aceptada por `MatchPanel` durante un Crazy activo **solo** pueda confirmarse si
  satisface el forzoso sobre un mercado permitido (ya se valida en `MatchPanel._on_market_widget_bet_confirmed`
  vía `StakeGate`; verificar que use el mismo contexto que evalúa la resolución en `BettingRoot`).
- Consolidar el ciclo de vida de `_active_crazy_bet` + `_crazy_bet_resolved_this_tick` (§6).

### 7.4 Regresión (obligatoria)
Añadir test(s) puros sobre la lógica aislada (patrón ya usado en el repo: `RefCounted` testeables):
- `CrazyBetResolver.select_restricted_markets`: con `available_markets` por-opción de los 8 mercados MVP,
  `allowed_market_ids` no tiene duplicados y respeta min/max.
- Escenario de integración (headless): jornada con ≥2 partidos, tick Crazy → una sola emisión de
  `crazy_moment_triggered`; tras confirmar el forzoso sobre un mercado permitido, `Continuar` se habilita.

---

## 8. Criterio de éxito del fix (del backlog)

Al dispararse un Momento Crazy con stake forzoso (50/70/100%), el jugador puede confirmar la apuesta
obligatoria una sola vez, sobre uno de los 1-2 mercados **distintos** permitidos, y `Continuar →` se habilita
al cumplirse la condición de stake, permitiendo avanzar de tick sin bloqueos — con 1, 2 o N partidos vivos.

## 9. Archivos afectados (probable, a confirmar por Programmer)

- `autoloads/run_state.gd` — dedupe de disparo Crazy por tick (§7.1).
- `scripts/economy/crazy_bet_resolver.gd` — selección por mercado (§7.2).
- `scenes/betting/betting_root.gd` — fuente única de contexto Crazy + ciclo de vida del flag (§7.3/§6).
- (Posible) `scenes/betting/match_panel.gd` / `scenes/betting/market_widget.gd` — solo si hace falta para
  compartir el mismo contexto; no rediseñar sus contratos.
