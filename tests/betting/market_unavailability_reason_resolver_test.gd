extends SceneTree
## Test de MarketUnavailabilityReasonResolver (E.9) -- razón breve mostrada cuando D.7 retira un
## mercado, derivada solo de market_id (+ MatchTickState, sin ampliar BetTickContext). Ver
## .ai-studio/specs/story-e9-ui-mercados-dinamicos.md sección 3.1.
##
## Ejecutar headless (requiere Godot instalado en el entorno que corra el test):
##   godot --headless --path . --script res://tests/betting/market_unavailability_reason_resolver_test.gd

func _init() -> void:
	var failures: Array[String] = []
	var state := MatchTickState.new()

	_expect_reason(&"first_scorer", state, "resuelto: ya hubo gol", failures)
	_expect_reason(&"goals_ou_1_5", state, "imposible con el marcador actual", failures)
	_expect_reason(&"goals_ou_2_5", state, "imposible con el marcador actual", failures)
	_expect_reason(&"goals_ou_3_5", state, "imposible con el marcador actual", failures)
	_expect_reason(&"cards_ou", state, "imposible con las tarjetas ya mostradas", failures)
	_expect_reason(&"fouls_ou", state, "imposible con las faltas ya mostradas", failures)

	var unknown_reason: String = MarketUnavailabilityReasonResolver.resolve_reason(&"unknown_market", state)
	if unknown_reason.is_empty():
		failures.append("un market_id desconocido debería devolver una razón genérica no vacía")

	if failures.is_empty():
		print("[PASS] market_unavailability_reason_resolver_test: todos los checks OK")
	else:
		push_error("[FAIL] market_unavailability_reason_resolver_test: %d fallo(s)" % failures.size())
		for failure in failures:
			push_error("  - " + failure)

	quit(0 if failures.is_empty() else 1)


func _expect_reason(market_id: StringName, state: MatchTickState, expected: String, failures: Array[String]) -> void:
	var reason: String = MarketUnavailabilityReasonResolver.resolve_reason(market_id, state)
	if reason != expected:
		failures.append("razón para '%s' esperada '%s', obtenida '%s'" % [market_id, expected, reason])
