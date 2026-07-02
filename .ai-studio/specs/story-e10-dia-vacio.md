# Spec técnica — Historia E.10: Pantalla breve "no hay partidos hoy" en días vacíos

Historia pequeña de pulido de UI. No reabre ni modifica el motor de D.6. Añade una capa de
presentación sobre el salto de día vacío **que ya existe** en `betting_root.gd`.

Ref: backlog `Historia E.10`; spec D.6 sección 11.2; patrón reutilizado E.8 `ResolutionFeedbackOverlay`.

---

## 1. Estado actual (lo que ya existe, no se toca su lógica)

En `scenes/betting/betting_root.gd`:

```gdscript
func _start_day_and_countdown(day: BettingDay.Day) -> void:
    _start_day(day)
    if _match_panels.is_empty():
        _on_matchday_finished(-1)      # <- salto silencioso e instantáneo
    else:
        _start_landing_countdown()
```

- La detección de día vacío ya está resuelta: tras `_start_day(day)`, si `_match_panels.is_empty()`
  el día no tiene partidos (jornada CONCENTRATED, `_concentrated_matches_for_day` devuelve `[]` para
  viernes/sábado).
- `_on_matchday_finished(-1)` es sincrónico: computa el día siguiente desde `RunState.current_day`
  (FRIDAY→SATURDAY, SATURDAY→SUNDAY) y vuelve a llamar a `_start_day_and_countdown` para ese día. Por
  eso hoy la cascada de días vacíos ocurre en un solo frame, sin feedback.

**Único cambio de comportamiento de E.10**: interponer una pantalla breve (con temporizador) entre la
detección del día vacío y la llamada a `_on_matchday_finished(-1)`. Nada más de la cadena cambia: el
avance sigue disparándose solo, no se abre ningún tick, no hay gate de apuesta ni countdown de mercado.

---

## 2. Nodo/escena nueva a crear

Nueva escena `scenes/betting/empty_day_overlay.tscn` + `scenes/betting/empty_day_overlay.gd`,
`class_name EmptyDayOverlay extends Control`.

Se modela **calcada sobre `ResolutionFeedbackOverlay`** (E.8), que ya resuelve exactamente este tipo
de "overlay atmosférico breve con temporizador que no bloquea input":

- Raíz `Control`, `anchors_preset = 15` (pantalla completa), `mouse_filter = 2` (IGNORE) en la raíz y
  en todos los hijos. Esto es requisito duro anti-Bug-1: el overlay nunca captura input; el ritmo no
  depende de que el jugador haga click (ver sección 5).
- `visible = false` por defecto; se enciende al mostrarse y se apaga en el timeout.
- Un `Timer` interno `one_shot`, creado en `_ready()`, exactamente como en `ResolutionFeedbackOverlay`.

Nodos hijos (Labels centrados, mismo patrón de anclaje 8 que `ResolutionFeedbackOverlay`):

| Nodo | Tipo | Contenido |
|---|---|---|
| `TitleLabel` | `Label` | Placeholder: `"No hay partidos hoy"` |
| `DetailLabel` | `Label` | Placeholder: `"Vuelve el <día siguiente>"` |

**El texto es placeholder.** La redacción narrativa final (p.ej. "El fin de semana se juega entero el
domingo") la define Game Designer por separado — Architect solo fija que existen dos labels
poblables. El script debe recibir los datos (día vacío + día siguiente) y formatear con esos
placeholders; sustituir el string literal es trivial cuando llegue el copy.

---

## 3. Interfaz de `EmptyDayOverlay`

```gdscript
class_name EmptyDayOverlay extends Control

## Emitida cuando termina el temporizador y el overlay se oculta. BettingRoot la usa para
## reanudar el avance de día (llamar a _on_matchday_finished(-1)).
signal skip_finished

const DISPLAY_DURATION_SECONDS: float = 1.8   # rango sugerido 1.5–2.0; alinear con la sensación
                                              # de ResolutionFeedbackOverlay (1.6)

## Muestra la pantalla breve para un día sin partidos y arranca el temporizador de auto-cierre.
## empty_day  = día que quedó sin partidos (para el título/formato de UI)
## next_day   = día inmediatamente siguiente al que avanzará la run (para DetailLabel)
func show_empty_day(empty_day: BettingDay.Day, next_day: BettingDay.Day) -> void
```

Comportamiento interno de `show_empty_day`:
1. Formatea `TitleLabel`/`DetailLabel` con los placeholders (reutilizar el mapa de nombres de día;
   ver sección 6, `_format_day_label` ya existe en `betting_root.gd` — el overlay puede recibir los
   strings ya formateados o replicar el mapeo; delegado a implementación).
2. `visible = true`, `_display_timer.start()`.
3. En el `timeout`: `visible = false`, `emit_signal("skip_finished")`.

No hay cola (`_queue`) como en `ResolutionFeedbackOverlay`: los días vacíos se procesan de forma
estrictamente secuencial (cada pantalla se dispara sólo cuando la anterior ya emitió `skip_finished`,
ver sección 4), así que nunca hay dos pendientes a la vez.

---

## 4. Integración en `BettingRoot` (disparo + cascada)

### 4.1 Wiring

- Añadir la instancia del overlay al árbol de `betting_root.tscn` como hijo directo de la raíz
  `BettingRoot` (hermano de `ResolutionFeedbackOverlay`, `CrazyMomentOverlay`, etc.), para que quede
  por encima del contenido.
- Añadir `@onready var _empty_day_overlay: EmptyDayOverlay = $EmptyDayOverlay`.
- En `_ready()`: `_empty_day_overlay.skip_finished.connect(_on_empty_day_skip_finished)`.

### 4.2 Modificar `_start_day_and_countdown`

```gdscript
func _start_day_and_countdown(day: BettingDay.Day) -> void:
    _start_day(day)
    if _match_panels.is_empty():
        if day == BettingDay.Day.SUNDAY:
            # Domingo vacío no es alcanzable con los números reales de la liga (ver nota QA en
            # _split_matches_for_day) y NO avanza a otro día: cae en _close_run_after_sunday.
            # Mostrar "no hay partidos hoy" seguido de la pantalla de fin de run sería incoherente,
            # así que se preserva el salto directo actual para ese caso teórico.
            _on_matchday_finished(-1)
        else:
            _empty_day_overlay.show_empty_day(day, _next_day_after(day))
    else:
        _start_landing_countdown()
```

### 4.3 Handler de reanudación

```gdscript
func _on_empty_day_skip_finished() -> void:
    _on_matchday_finished(-1)
```

Esto reproduce **exactamente** la llamada que hoy es inmediata, sólo que diferida al fin del
temporizador. `_on_matchday_finished(-1)` sigue siendo el único punto que decide el día siguiente y
sigue pasando por `_advance_to_next_day` → `_start_day_and_countdown`, que limpia el ciclo
(`_matches_with_tick_open_this_cycle.clear()`, `_deactivate_crazy_bet()`). No se toca ese método.

### 4.4 Cascada (viernes y sábado vacíos antes de domingo)

La cascada es **automática y por reentrada**, sin código extra:

```
_start_day_and_countdown(FRIDAY)
  viernes vacío -> _empty_day_overlay.show_empty_day(FRIDAY, SATURDAY)  [timer 1.8s]
    -> skip_finished -> _on_matchday_finished(-1) -> current_day = SATURDAY
       -> _advance_to_next_day(SATURDAY) -> _start_day_and_countdown(SATURDAY)
         sábado vacío -> _empty_day_overlay.show_empty_day(SATURDAY, SUNDAY)  [timer 1.8s]
           -> skip_finished -> _on_matchday_finished(-1) -> current_day = SUNDAY
              -> _advance_to_next_day(SUNDAY) -> _start_day_and_countdown(SUNDAY)
                domingo con partidos -> _start_landing_countdown()  (flujo normal)
```

Cada día vacío muestra **su propia** pantalla con su propio temporizador, en serie. La misma instancia
de overlay se reutiliza (no se instancia una por día): al reentrar `show_empty_day`, se re-pueblan los
labels y se reinicia el timer.

---

## 5. Duración / cierre (contrato de ritmo)

- **Cierre por temporizador automático**, no por click. El criterio de éxito exige "avance automático
  (no requiere input obligatorio del jugador)". Un cierre por click reintroduciría dependencia de
  input y chocaría con `mouse_filter = IGNORE`; se descarta.
- Duración: `DISPLAY_DURATION_SECONDS = 1.8` (ajustable en el rango 1.5–2.0 tras playtest; se elige
  ligeramente por encima de los 1.6 de `ResolutionFeedbackOverlay` porque aquí el jugador está leyendo
  texto, no un número). Valor de balance/feel, delegado a Programmer/Playtester el ajuste fino.
- Click-para-saltar-antes queda **fuera de alcance** (posible mejora futura; requeriría capturar input
  y por tanto revisar el `mouse_filter`, no se hace en esta historia).

---

## 6. Detalle delegado a implementación

- Mapeo día→nombre para los labels: ya existe `_format_day_label(day)` en `betting_root.gd`. Se puede
  extraer/reutilizar; decidir si el overlay recibe strings ya formateados o el enum `BettingDay.Day`
  es libre para Programmer (ambas opciones son triviales; recomendado pasar el enum y que el overlay
  formatee, para que el overlay sea autónomo).
- `_next_day_after(day)`: helper trivial nuevo en `BettingRoot` (FRIDAY→SATURDAY, SATURDAY→SUNDAY),
  mismo mapeo que ya usa `_on_matchday_finished`. Sólo se usa para poblar `DetailLabel`.
- Estilos/tipografía del overlay: seguir lo que ya usan los otros overlays de `betting_root.tscn`;
  no se especifica look final (fuera de alcance de esta historia, igual que en E.8).

---

## 7. Fuera de alcance / invariantes preservadas

- No se modifica: `_start_day`, `_matches_for_day`, `_concentrated_matches_for_day`,
  `_split_matches_for_day`, `_on_matchday_finished`, `_advance_to_next_day` ni el motor de D.6.
- No se abre ningún tick, no se instancia ningún `MatchPanel`, no hay countdown de aterrizaje en un
  día vacío. Se mantiene la invariante anti-Bug-1: nunca se espera una apuesta obligatoria imposible.
- El texto narrativo final es de Game Designer; esta spec sólo fija estructura, disparo, datos y
  temporización.

---

## 8. Checklist para Programmer

1. Crear `scenes/betting/empty_day_overlay.tscn` + `.gd` (`class_name EmptyDayOverlay`), calcado del
   patrón de `ResolutionFeedbackOverlay` (Control pantalla completa, `mouse_filter = 2`, Timer
   `one_shot`), con señal `skip_finished`, método `show_empty_day(empty_day, next_day)` y dos labels
   con texto placeholder.
2. Instanciar `EmptyDayOverlay` en `betting_root.tscn` como hijo de la raíz; añadir `@onready`.
3. Conectar `skip_finished → _on_empty_day_skip_finished` en `_ready()`.
4. Modificar `_start_day_and_countdown` (sección 4.2) y añadir `_on_empty_day_skip_finished`
   (sección 4.3) y `_next_day_after` (sección 6).
5. Verificar cascada viernes+sábado vacíos → domingo con partidos: dos pantallas en serie, luego
   flujo normal, sin quedar bloqueado ni abrir tick en días vacíos.
