extends SceneTree
## Test de regresión (bug bloqueante D.7+E.9 reportado por Reviewer): un mercado ya retirado por D.7
## (set_unavailable, ej. first_scorer tras el primer gol) no debe quedar también marcado como
## set_restricted cuando un Momento Crazy se dispara en ESE MISMO tick. Antes del fix,
## MatchPanel.apply_crazy_moment_restriction iteraba los 8 MarketWidget fijos del catálogo en vez de
## solo los presentes en offers_by_market del tick (ya calculado por on_tick_opened), así que un
## widget ya "no disponible" también terminaba con DisabledOverlay visible. Ver
## .ai-studio/specs/story-e9-ui-mercados-dinamicos.md sección 3.1.
##
## Ejecutar headless (requiere Godot instalado en el entorno que corra el test):
##   godot --headless --path . --script res://tests/betting/match_panel_crazy_moment_vs_unavailable_test.gd

const MATCH_PANEL_SCENE: PackedScene = preload("res://scenes/betting/match_panel.tscn")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	await process_frame

	RunState.start_new_run()

	var panel: MatchPanel = MATCH_PANEL_SCENE.instantiate()
	root.add_child(panel)
	await process_frame

	panel.setup(&"match_test")

	var match_state := MatchTickState.new()
	match_state.match_id = &"match_test"
	match_state.home_team_id = &"home_team"
	match_state.away_team_id = &"away_team"
	match_state.current_tick_index = 2
	match_state.current_minute = 30
	match_state.home_goals = 1
	match_state.goal_scorers = [&"some_player"]

	# Simula el tick tal como lo deja D.7: "first_scorer" ya se retiró de available_markets tras el
	# primer gol, así que no aparece aquí (a diferencia de "1x2", que sigue vigente).
	var context := BetTickContext.new()
	context.day = BettingDay.Day.FRIDAY
	context.tick_index_in_day = 2
	context.available_markets = [
		_build_offer(&"1x2", &"home"),
		_build_offer(&"1x2", &"draw"),
		_build_offer(&"1x2", &"away"),
	]

	panel.on_tick_opened(context, match_state, null, null, null)
	await process_frame

	var first_scorer_widget: MarketWidget = panel._market_widgets_by_id[&"first_scorer"]
	var market_1x2_widget: MarketWidget = panel._market_widgets_by_id[&"1x2"]

	if not first_scorer_widget._is_unavailable:
		_fail("first_scorer debería quedar set_unavailable tras on_tick_opened sin oferta para ese mercado")
		_finish()
		return

	# Un Momento Crazy se dispara en este mismo tick, y "first_scorer" (ya retirado) no está entre los
	# mercados permitidos del Crazy Bet -- exactamente el escenario que reproducía el bug.
	var crazy_bet := CrazyBetContext.new()
	crazy_bet.stake_percentage = CrazyBetContext.StakePercentage.FIFTY
	crazy_bet.forced_stake_amount = 100
	crazy_bet.allowed_market_ids = [&"1x2"]
	crazy_bet.excluded_market_id = &"first_scorer"

	panel.apply_crazy_moment_restriction(crazy_bet)
	await process_frame

	if first_scorer_widget._disabled_overlay.visible:
		_fail("first_scorer (ya set_unavailable por D.7) no debería recibir también set_restricted/DisabledOverlay del Momento Crazy")
	if not first_scorer_widget._unavailable_overlay.visible:
		_fail("first_scorer debería seguir mostrando UnavailableOverlay tras apply_crazy_moment_restriction")
	if first_scorer_widget._is_restricted:
		_fail("first_scorer no debería quedar marcado _is_restricted -- la causa real es D.7, no el Momento Crazy")

	# El mercado sí vigente pero no permitido por el Crazy Bet debe quedar restringido normalmente (no
	# se rompe el comportamiento ya aprobado del Momento Crazy).
	if not market_1x2_widget._is_restricted:
		_fail("1x2 SÍ está permitido por el Crazy Bet -- no debería quedar restringido")
	if market_1x2_widget._disabled_overlay.visible:
		_fail("1x2 está permitido por el Crazy Bet -- DisabledOverlay no debería estar visible")

	_finish()


func _build_offer(market_id: StringName, option_key: StringName) -> MarketOffer:
	var offer := MarketOffer.new()
	offer.market_id = market_id
	offer.match_id = &"match_test"
	offer.option_key = option_key
	offer.displayed_probability_min = 0.3
	offer.displayed_probability_max = 0.4
	return offer


func _fail(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] match_panel_crazy_moment_vs_unavailable_test: todos los checks OK")
	else:
		push_error("[FAIL] match_panel_crazy_moment_vs_unavailable_test: %d fallo(s)" % _failures.size())
		for failure in _failures:
			push_error("  - " + failure)

	quit(0 if _failures.is_empty() else 1)
