extends SceneTree
## Test de integración de EmptyDayOverlay en BettingRoot (E.10) -- ver
## .ai-studio/specs/story-e10-dia-vacio.md secciones 4, 5 y 7.
##
## Cubre el criterio de éxito de la historia con el camino real end-to-end (LeagueState +
## RunState + BettingRoot, jornada CONCENTRATED real, "Super Sunday", última de la temporada):
##   1. El overlay NO aparece en un día con partidos (jornada STAGGERED normal).
##   2. El overlay SÍ aparece cuando BettingRoot aterriza en un día sin partidos.
##   3. Se cierra solo tras el temporizador (nunca por click -- se simula el timeout como
##      empty_day_overlay_test.gd, mismo patrón que resolution_feedback_overlay_test.gd).
##   4. La cascada de 2 días vacíos consecutivos (viernes + sábado de una jornada CONCENTRATED)
##      muestra el overlay dos veces, en serie, antes de llegar al domingo con partidos -- sin abrir
##      ningún gate de apuesta ni tick obligatorio en el proceso (invariante anti-Bug-1: nunca se abre
##      un tick que no puede resolverse porque no hay ningún MatchPanel escuchando).
##   5. Corrección post-commit 0a8c733 (spec sección 9): en ese caso doble-vacío, DetailLabel debe
##      anunciar el próximo día CON partidos (domingo) en AMBAS pantallas -- la de viernes NO debe decir
##      "sábado" (día inmediatamente siguiente pero también vacío), porque contradice lo que el jugador
##      ve justo después.
##
## Ejecutar headless (requiere Godot instalado en el entorno que corra el test):
##   godot --headless --path . --script res://tests/integration/empty_day_cascade_test.gd

const BETTING_ROOT_SCENE: PackedScene = preload("res://scenes/betting/betting_root.tscn")

var _failures: Array[String] = []
var _bet_tick_opened_count: int = 0


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	await process_frame

	_test_no_overlay_on_a_day_with_matches()
	_test_cascade_two_empty_days_before_matches_no_gate_opened()

	_finish()


## Jornada STAGGERED normal (matchday 0): viernes reparte partidos reales (D.6 §4.2), así que
## BettingRoot no debería mostrar EmptyDayOverlay ni saltar el día.
func _test_no_overlay_on_a_day_with_matches() -> void:
	LeagueState.generate_new_league(1, 111)
	LeagueState.current_matchday_index = 0
	RunState.start_new_run()

	var betting_root: BettingRoot = BETTING_ROOT_SCENE.instantiate()
	root.add_child(betting_root)
	await process_frame

	if betting_root._match_panels.is_empty():
		_fail("día con partidos (STAGGERED, matchday 0): _match_panels no debería quedar vacío")
	if betting_root._empty_day_overlay.visible:
		_fail("día con partidos: EmptyDayOverlay no debería mostrarse")

	betting_root.queue_free()
	await process_frame


## Jornada CONCENTRATED (última de la temporada, "Super Sunday", D.6 §4.2): viernes y sábado quedan
## sin partidos, domingo concentra todos. Verifica la cascada completa de la spec §4.4.
func _test_cascade_two_empty_days_before_matches_no_gate_opened() -> void:
	LeagueState.generate_new_league(1, 222)
	LeagueState.current_matchday_index = LeagueRules.TOTAL_MATCHDAYS - 1
	RunState.start_new_run()

	_bet_tick_opened_count = 0
	EventBus.bet_tick_opened.connect(_on_bet_tick_opened_track_count)

	var betting_root: BettingRoot = BETTING_ROOT_SCENE.instantiate()
	root.add_child(betting_root)
	await process_frame

	# --- Viernes vacío: primera pantalla de la cascada ---
	if RunState.current_day != BettingDay.Day.FRIDAY:
		_fail("debería arrancar en viernes, obtenido %d" % RunState.current_day)
	if not betting_root._match_panels.is_empty():
		_fail("viernes de una jornada CONCENTRATED debería quedar sin partidos (_match_panels vacío)")
	if not betting_root._empty_day_overlay.visible:
		_fail("viernes vacío: EmptyDayOverlay debería mostrarse (1ª pantalla de la cascada)")
	# Corrección post-0a8c733 (spec §9): en esta jornada sábado TAMBIÉN está vacío, así que el próximo
	# día CON partidos es domingo, no sábado -- DetailLabel debe decir "domingo", nunca "sábado".
	if not betting_root._empty_day_overlay._detail_label.text.contains("domingo"):
		_fail("viernes vacío: DetailLabel debería anunciar 'domingo' (próximo día CON partidos, no el inmediatamente siguiente), texto=%s" % betting_root._empty_day_overlay._detail_label.text)
	if betting_root._empty_day_overlay._detail_label.text.contains("sábado"):
		_fail("viernes vacío: DetailLabel NO debería mencionar 'sábado' (también vacío en esta jornada CONCENTRATED), texto=%s" % betting_root._empty_day_overlay._detail_label.text)
	if not betting_root._matches_with_tick_open_this_cycle.is_empty():
		_fail("viernes vacío: no debería haber ningún tick obligatorio abierto (invariante anti-Bug-1)")
	if _bet_tick_opened_count != 0:
		_fail("viernes vacío: no debería haberse emitido ningún bet_tick_opened, obtenido %d" % _bet_tick_opened_count)

	# Cierre por temporizador (nunca por click, spec §5) -- se simula el timeout directamente.
	betting_root._empty_day_overlay._on_display_timer_timeout()

	# --- Sábado vacío: segunda pantalla de la cascada, por reentrada natural (spec §4.4) ---
	if RunState.current_day != BettingDay.Day.SATURDAY:
		_fail("tras cerrar la pantalla de viernes debería avanzar a sábado, obtenido %d" % RunState.current_day)
	if not betting_root._match_panels.is_empty():
		_fail("sábado de esta jornada CONCENTRATED debería quedar sin partidos (_match_panels vacío)")
	if not betting_root._empty_day_overlay.visible:
		_fail("sábado vacío: EmptyDayOverlay debería mostrarse de nuevo (2ª pantalla de la cascada)")
	if not betting_root._empty_day_overlay._detail_label.text.contains("domingo"):
		_fail("sábado vacío: DetailLabel debería anunciar 'domingo' (día siguiente), texto=%s" % betting_root._empty_day_overlay._detail_label.text)
	if not betting_root._matches_with_tick_open_this_cycle.is_empty():
		_fail("sábado vacío: no debería haber ningún tick obligatorio abierto (invariante anti-Bug-1)")
	if _bet_tick_opened_count != 0:
		_fail("tras 2 días vacíos en cascada no debería haberse emitido ningún bet_tick_opened todavía, obtenido %d" % _bet_tick_opened_count)

	# Cierre de la 2ª pantalla -- debería llegar al domingo, que en esta jornada concentra los partidos.
	betting_root._empty_day_overlay._on_display_timer_timeout()

	# --- Domingo con partidos: fin de la cascada, flujo normal ---
	if RunState.current_day != BettingDay.Day.SUNDAY:
		_fail("tras 2 días vacíos debería llegar a domingo, obtenido %d" % RunState.current_day)
	if betting_root._match_panels.is_empty():
		_fail("domingo de la jornada CONCENTRATED debería concentrar todos los partidos (_match_panels no vacío)")
	if betting_root._empty_day_overlay.visible:
		_fail("domingo con partidos: EmptyDayOverlay debería quedar oculto")

	EventBus.bet_tick_opened.disconnect(_on_bet_tick_opened_track_count)
	betting_root.queue_free()
	await process_frame


func _on_bet_tick_opened_track_count(_context: BetTickContext) -> void:
	_bet_tick_opened_count += 1


func _fail(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] empty_day_cascade_test: todos los checks OK")
	else:
		push_error("[FAIL] empty_day_cascade_test: %d fallo(s)" % _failures.size())
		for failure in _failures:
			push_error("  - " + failure)

	quit(0 if _failures.is_empty() else 1)
