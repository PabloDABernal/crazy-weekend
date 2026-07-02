# Historia E.8 — Boleto vivo: estado en tiempo real + feedback de resolución — spec técnica

Fuente: `.ai-studio/memory/backlog.md` → E.8 (+ nota importante: el Director confirmó **dopamina alta y
consistente en cualquier fase**, contradiciendo el "confirmación seca" que aún describe `game-design.md` —
pendiente que Game Designer actualice esas frases; esta spec ya asume la versión confirmada). Diseño:
`game-design.md` → "Boleto vivo y feedback de resolución". Reutiliza
`.ai-studio/specs/epic-e-pantalla-de-apuestas.md` §4 (`PendingBetsTracker`, `PendingBet`) y `epic-d` §4.1
(`MatchTickState`). No contiene GDScript final.

---

## 1. Objetivo

Dos entregables sobre el panel de apuestas pendientes:
1. **Estado vivo** por apuesta abierta: mercado, importe, cuota fijada, ganancia potencial, un indicador
   `vas ganando / vas perdiendo / indeciso` respecto al partido en curso, y cuánto falta para su resolución
   (minuto/tick de cierre). Siempre visible, sin condicionar a investigación.
2. **Feedback de resolución** enérgico e inmediato al ganarse/perderse una apuesta (importe concreto,
   atribuible a esa apuesta), con intensidad **alta y consistente en cualquier fase narrativa**.

## 2. Estado vivo — lógica pura reutilizable

La evaluación "¿esta apuesta va ganando ahora mismo?" es exactamente `PendingBetsTracker._is_bet_won(offer,
match_state)` aplicada al `MatchTickState` **actual** (no final). Se promueve esa lógica a un helper puro y
tri-estado para poder distinguir "indeciso" (mercados aún no decidibles):

```gdscript
class_name LiveBetEvaluator extends RefCounted   # res://scripts/betting/live_bet_evaluator.gd

enum LiveStatus { WINNING, LOSING, UNDECIDED }

## Estado vivo de una apuesta contra el estado actual (parcial) del partido.
static func evaluate(market_offer: MarketOffer, match_state: MatchTickState) -> LiveStatus

## Ticks restantes hasta la resolución de este mercado (0 = se resuelve este tick).
## first_scorer se cierra al primer gol; el resto al minuto 90 (coherente con
## PendingBetsTracker.is_market_resolved_this_tick).
static func ticks_until_resolution(market_offer: MarketOffer, match_state: MatchTickState) -> int
```

Regla de `UNDECIDED`: mercados cuya condición aún puede caer a ambos lados (p. ej. `btts` con 0-0 en curso,
over/under con margen todavía alcanzable). `WINNING`/`LOSING` = el resultado actual ya cae de ese lado
(over ya superado = WINNING para "over"; imposible ya = LOSING). La refactorización debe dejar
`PendingBetsTracker._is_bet_won` (resolución final) y `LiveBetEvaluator.evaluate` (estado vivo) apoyándose en
la **misma** tabla de reglas por `market_id` para no duplicar criterios.

## 3. Panel de boleto vivo — UI

Hoy `BettingRoot._refresh_pending_bets_panel()` pinta un resumen plano (contador + últimas 4 líneas
`$stake · mercado`) en `RightPanel/PendingBetsPanel`. Se sustituye por un componente por apuesta.

Nuevo componente reutilizable (patrón `MarketWidget`): `LiveBetTicket` (escena+script en
`scenes/betting/live_bet_ticket.tscn`), un ticket por `PendingBet`:
- Labels: partido (abreviado, sin recortar — reglas de usabilidad), mercado+opción, importe, cuota fijada
  (`OddsMath` de E.7 sobre `market_offer` congelado), ganancia potencial.
- `StatusBadge`: color/texto según `LiveBetEvaluator.LiveStatus` (verde/rojo/neutro).
- `ResolutionLabel`: "cierra en min X" / "cierra este tick" según `ticks_until_resolution`.

`BettingRoot` instancia/actualiza los tickets:
- Se refresca en cada `pending_bets_changed` (alta/baja de apuestas) **y** en cada `bet_tick_opened`
  (avanza el partido → cambia el estado vivo). Para el estado vivo, cada ticket consulta el
  `MatchTickState` de su `match_id` vía `MatchSimulationService.get_match_tick_state(match_id)` (ya expuesto).

## 4. Feedback de resolución (dopamina alta y consistente)

`PendingBetsTracker._resolve_single_bet()` ya calcula el `payout` y ajusta `RunState.set_money`, pero solo
emite `EventBus.market_bet_resolved(result)` (contrato de Épica A, `MarketBetResult` no lleva importe). Para
el feedback E.8 se añade una señal **propia de la UI de apuestas**, sin tocar el contrato cross-épica:

```gdscript
# PendingBetsTracker (señal nueva, local a la escena de apuestas)
signal bet_resolved(pending_bet: PendingBet, won: bool, payout: int)
    # payout = dinero acreditado (0 si perdida). stake vive en pending_bet.stake.
```

Emitida en `_resolve_single_bet` junto a `market_bet_resolved`. `BettingRoot` la consume y dispara un overlay
de feedback:

Nuevo overlay: `ResolutionFeedbackOverlay` (escena+script en
`scenes/betting/resolution_feedback_overlay.tscn`, hijo de `BettingRoot`, `mouse_filter = IGNORE` en todos
los nodos — igual que `CrazyMomentOverlay`, para no reintroducir el patrón de bloqueo del Bug 1):
```gdscript
class_name ResolutionFeedbackOverlay extends Control
func show_win(amount_returned: int, net: int) -> void
func show_loss(amount_lost: int) -> void
```
- **Enérgico**: animación breve + número grande claro ("+$Y" ganado / "−$X" perdido), atribuible a la
  apuesta. Sin condicionar la intensidad a `NarrativePhase` (dopamina alta siempre; ver nota del backlog).
- En fases avanzadas (3-4) el mensaje puede "hablarle" al jugador (canal de deterioro) — es contenido
  narrativo, coordinar con Game Designer; la lógica de selección puede reutilizar `NarrativePhase` igual que
  `CommentaryResolver`, pero **la intensidad visual no baja**.
- Resoluciones múltiples en un mismo tick (varias apuestas cierran a la vez): encolar o agregar en un único
  overlay ("+$total") para no solapar animaciones (decisión de UX menor, delegada a implementación; el
  contrato es que cada resolución sea legible y atribuible).

## 5. Interfaces tocadas (resumen)

| Elemento | Tipo | Cambio |
|---|---|---|
| `LiveBetEvaluator` | `RefCounted` nuevo | estado vivo tri-estado + ticks restantes |
| `PendingBetsTracker` | `Node` existente | nueva señal `bet_resolved`; reusar tabla de reglas con `LiveBetEvaluator` |
| `LiveBetTicket` | escena+script nuevos | ticket por apuesta con estado vivo |
| `ResolutionFeedbackOverlay` | escena+script nuevos | feedback enérgico (mouse IGNORE) |
| `BettingRoot` | existente | instanciar tickets, refrescar en tick, consumir `bet_resolved` |

No se toca: `MarketBetResult`/`EventBus.market_bet_resolved` (contrato de Épica A), `RunState`.

## 6. Diagrama

```mermaid
flowchart TD
    BTO[bet_tick_opened] --> BR[BettingRoot]
    PBC[pending_bets_changed] --> BR
    BR --> LT["LiveBetTicket x N (usa LiveBetEvaluator + MatchTickState)"]
    RT[bet_tick_resolved] --> PBT[PendingBetsTracker.resolve_bets_for_match]
    PBT -->|ganada/perdida| BRES[signal bet_resolved]
    BRES --> RFO[ResolutionFeedbackOverlay.show_win/show_loss]
```

## 7. Dependencias y orden

- Depende de E.3/E.4 (pending bets, `MatchSimulationService.get_match_tick_state`) y D.3 (estado vivo).
- Comparte `OddsMath` con E.7 para la cuota/ganancia del ticket (implementar E.7 primero o en paralelo).
- Independiente de D.6/D.7. Puede ir justo después de E.7 (orden de producto).

## 8. Criterio de éxito

Cada apuesta abierta muestra su estado vivo actualizado en cada tick, siempre visible; al resolverse, el
cambio de saldo es legible y atribuible a esa apuesta con feedback enérgico, consistente en cualquier fase
narrativa. El overlay de feedback nunca bloquea input (mouse IGNORE, lección del Bug 1).
