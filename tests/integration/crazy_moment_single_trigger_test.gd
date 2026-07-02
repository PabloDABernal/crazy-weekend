extends SceneTree
## Test de regresión Bug 1 (fix §7.1/§7.3 de .ai-studio/specs/bug-1-crazy-bet-confirm-block.md).
##
## Escenario de integración headless con una jornada real de ≥2 partidos en paralelo (viernes reparte
## 4 de los 10 partidos de la liga -- ver BettingRoot._split_matches_for_day): al llegar el tick
## marcado como Crazy en el plan de la run, EventBus.crazy_moment_triggered debe emitirse EXACTAMENTE
## una vez (antes del fix se emitía una vez por partido vivo del tick). Tras confirmar el forzoso sobre
## uno de los mercados permitidos, el botón "Continuar" (BettingRoot._all_matches_satisfied_this_cycle)
## debe habilitarse sin quedar bloqueado (deadlock descrito en §4 de la spec).
##
## Ejecutar headless (requiere Godot instalado en el entorno que corra el test):
##   godot --headless --path . --script res://tests/integration/crazy_moment_single_trigger_test.gd

const BETTING_ROOT_SCENE: PackedScene = preload("res://scenes/betting/betting_root.tscn")

var _crazy_trigger_count: int = 0
var _failures: Array[String] = []


func _init() -> void:
	# _init() de un script SceneTree corre antes de que termine de asentarse el árbol -- se difiere el
	# resto del test a _run_test(), invocado tras el primer process_frame, para que los autoloads
	# ([autoload] de project.godot, incluido RunState/EventBus) ya estén listos.
	call_deferred("_run_test")


func _run_test() -> void:
	await process_frame

	LeagueState.generate_new_league(1, 123456)
	RunState.start_new_run()

	# Fuerza el plan de Momentos Crazy de la run a un único slot determinista (viernes, tick_index=1),
	# en vez de depender del sorteo real de B.4 -- lo único que este test necesita del plan es que
	# exista un tick Crazy alcanzable de forma reproducible.
	RunState.crazy_moment_schedule = [CrazyMomentScheduler.ScheduledCrazyMoment.new(BettingDay.Day.FRIDAY, 1)]

	var betting_root: BettingRoot = BETTING_ROOT_SCENE.instantiate()
	root.add_child(betting_root)
	await process_frame

	if betting_root._match_panels.size() < 2:
		_fail("la jornada de viernes debe repartir >=2 partidos (obtenidos: %d) -- criterio de la spec §7.4" % betting_root._match_panels.size())
		_finish()
		return

	EventBus.crazy_moment_triggered.connect(_on_crazy_moment_triggered)

	# El tick inicial (pre-partido, tick_index_in_day=0) lo abre el countdown de aterrizaje real
	# (BettingRoot._start_landing_countdown) -- se espera su primera emisión real en vez de simularla,
	# para no saltarse el camino real de arranque de la escena.
	await EventBus.bet_tick_opened

	# Dispara el tick_index=1 (el marcado como Crazy) de la forma real: un advance_tick() de
	# MatchSimulationService emite bet_tick_resolved + bet_tick_opened UNA VEZ POR CADA partido vivo del
	# día, todos con el mismo tick_index_in_day -- exactamente el escenario que producía N disparos de
	# crazy_moment_triggered antes del fix de RunState (§7.1).
	betting_root._match_simulation_service.advance_tick()

	if _crazy_trigger_count != 1:
		_fail("crazy_moment_triggered se emitió %d veces (esperado: 1) con %d partidos vivos en el tick Crazy" % [_crazy_trigger_count, betting_root._match_panels.size()])

	var active_crazy_bet: CrazyBetContext = betting_root._active_crazy_bet
	if active_crazy_bet == null:
		_fail("BettingRoot._active_crazy_bet quedó null tras el tick Crazy -- no se pudo continuar el test")
		_finish()
		return

	if active_crazy_bet.allowed_market_ids.is_empty():
		_fail("CrazyBetContext.allowed_market_ids vacío -- no se pudo continuar el test")
		_finish()
		return

	# Confirma el forzoso sobre el primer mercado permitido, en el primer partido, exactamente por el
	# camino real (MarketWidget -> MatchPanel -> BettingRoot), no simulando el resultado a mano.
	var target_match_id: StringName = betting_root._match_panels.keys()[0]
	var target_panel: MatchPanel = betting_root._match_panels[target_match_id]
	var target_market_id: StringName = active_crazy_bet.allowed_market_ids[0]
	var target_widget: MarketWidget = target_panel._market_widgets_by_id.get(target_market_id, null)

	if target_widget == null:
		_fail("no se encontró MarketWidget para el mercado permitido '%s' en el partido enfocado" % target_market_id)
		_finish()
		return

	if target_widget._offers_by_option.is_empty():
		_fail("el MarketWidget del mercado permitido '%s' no tiene opciones ofertadas" % target_market_id)
		_finish()
		return

	var option_key: StringName = target_widget._offers_by_option.keys()[0]
	target_widget._on_option_button_pressed(option_key)
	target_widget._on_confirm_pressed()

	if not betting_root._all_matches_satisfied_this_cycle():
		_fail("_all_matches_satisfied_this_cycle() sigue en false tras confirmar el forzoso sobre un mercado permitido -- deadlock del gate (§4 de la spec)")

	if betting_root._continue_button.disabled:
		_fail("ContinueButton.disabled sigue en true tras confirmar el forzoso sobre un mercado permitido -- deadlock del gate (§4 de la spec)")

	_finish()


func _on_crazy_moment_triggered(_context: CrazyBetContext) -> void:
	_crazy_trigger_count += 1


func _fail(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] crazy_moment_single_trigger_test: una sola emisión de crazy_moment_triggered y Continuar se habilita tras el forzoso")
	else:
		push_error("[FAIL] crazy_moment_single_trigger_test: %d fallo(s)" % _failures.size())
		for failure in _failures:
			push_error("  - " + failure)

	quit(0 if _failures.is_empty() else 1)
