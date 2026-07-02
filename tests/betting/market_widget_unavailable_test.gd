extends SceneTree
## Test de integración de MarketWidget (E.9): estado "retirado con razón" cuando D.7 deja de ofertar
## un mercado, distinto de set_restricted (Momento Crazy), y repintado de cuota en cada refresh(). Ver
## .ai-studio/specs/story-e9-ui-mercados-dinamicos.md secciones 3.1 y 3.2.
##
## Ejecutar headless (requiere Godot instalado en el entorno que corra el test):
##   godot --headless --path . --script res://tests/betting/market_widget_unavailable_test.gd

const MARKET_WIDGET_SCENE: PackedScene = preload("res://scenes/betting/market_widget.tscn")

var _failures: Array[String] = []


func _init() -> void:
	call_deferred("_run_test")


func _run_test() -> void:
	await process_frame

	var widget: MarketWidget = MARKET_WIDGET_SCENE.instantiate()
	root.add_child(widget)
	await process_frame

	var offer_home := _build_offer(&"home", 0.3, 0.5)
	var offer_away := _build_offer(&"away", 0.2, 0.3)
	widget.refresh([offer_home, offer_away])
	await process_frame

	_test_set_unavailable_disables_interaction(widget)
	_test_set_unavailable_shows_reason_and_dims_title(widget)
	_test_set_unavailable_distinct_from_set_restricted(widget)

	# Recuperar el mercado (D.7 no debería hacerlo en la práctica para estos casos, pero refresh()
	# vuelve a poblar el widget, así que el estado "retirado" no debe quedar pegado tras un refresh
	# con ofertas frescas).
	widget.refresh([_build_offer(&"home", 0.4, 0.6), _build_offer(&"away", 0.1, 0.2)])
	await process_frame
	_test_refresh_clears_unavailable_state(widget)

	_test_odds_repaint_on_each_tick(widget)

	_finish()


func _build_offer(option_key: StringName, p_min: float, p_max: float) -> MarketOffer:
	var offer := MarketOffer.new()
	offer.market_id = &"1x2"
	offer.match_id = &"match_test"
	offer.option_key = option_key
	offer.displayed_probability_min = p_min
	offer.displayed_probability_max = p_max
	return offer


func _test_set_unavailable_disables_interaction(widget: MarketWidget) -> void:
	widget.set_unavailable("resuelto: ya hubo gol")

	if widget._confirm_bet_button.disabled != true:
		_fail("ConfirmBetButton debería quedar deshabilitado tras set_unavailable")
	if widget._stake_input.editable:
		_fail("StakeInput debería quedar no editable tras set_unavailable")
	for key in widget._option_buttons.keys():
		var button: Button = widget._option_buttons[key]
		if not button.disabled:
			_fail("el botón de opción '%s' debería quedar deshabilitado tras set_unavailable" % key)


func _test_set_unavailable_shows_reason_and_dims_title(widget: MarketWidget) -> void:
	if not widget._unavailable_overlay.visible:
		_fail("UnavailableOverlay debería quedar visible tras set_unavailable")
	if widget._unavailable_reason_label.text != "resuelto: ya hubo gol":
		_fail("UnavailableReasonLabel debería mostrar la razón pasada, obtenido '%s'" % widget._unavailable_reason_label.text)
	if widget._market_title_label.modulate.a >= 1.0:
		_fail("el título del mercado debería quedar atenuado (modulate.a < 1.0) en estado no disponible")


## set_unavailable no debe reutilizar el mismo overlay que set_restricted (Momento Crazy) -- son
## causas distintas y deben ser distinguibles en pantalla (sección 3.1 de la spec).
func _test_set_unavailable_distinct_from_set_restricted(widget: MarketWidget) -> void:
	if widget._disabled_overlay.visible:
		_fail("DisabledOverlay (restricción de Momento Crazy) no debería activarse por set_unavailable")

	widget.set_restricted(true)
	if not widget._disabled_overlay.visible:
		_fail("set_restricted debería activar DisabledOverlay, distinto de UnavailableOverlay")
	widget.set_restricted(false)


func _test_refresh_clears_unavailable_state(widget: MarketWidget) -> void:
	if widget._unavailable_overlay.visible:
		_fail("UnavailableOverlay debería limpiarse tras un refresh() con ofertas frescas")
	if widget._unavailable_reason_label.visible:
		_fail("UnavailableReasonLabel debería limpiarse tras un refresh() con ofertas frescas")
	if widget._market_title_label.modulate.a < 1.0:
		_fail("el título del mercado debería recuperar opacidad completa tras un refresh() con ofertas frescas")
	if widget._confirm_bet_button.disabled and widget._selected_option_key != &"":
		_fail("tras refresh() con ofertas frescas el mercado debería volver a ser interactuable")


## E.9 sección 3.2: la cuota por opción debe repintarse en cada refresh() del tick, sin desfase.
func _test_odds_repaint_on_each_tick(widget: MarketWidget) -> void:
	var tick_1_offer := _build_offer(&"home", 0.5, 0.5)
	widget.refresh([tick_1_offer, _build_offer(&"away", 0.1, 0.1)])
	await process_frame
	var button: Button = widget._option_buttons.get(&"home", null)
	if button == null:
		_fail("no se encontró el botón de la opción 'home' en el tick 1")
		return
	var odds_tick_1: float = OddsMath.odds_from_probability(0.5)
	if not button.text.contains("%.2f" % odds_tick_1):
		_fail("la cuota mostrada en el tick 1 no coincide con OddsMath (texto=%s)" % button.text)

	var tick_2_offer := _build_offer(&"home", 0.25, 0.25)
	widget.refresh([tick_2_offer, _build_offer(&"away", 0.4, 0.4)])
	await process_frame
	var button_tick_2: Button = widget._option_buttons.get(&"home", null)
	var odds_tick_2: float = OddsMath.odds_from_probability(0.25)
	if not button_tick_2.text.contains("%.2f" % odds_tick_2):
		_fail("la cuota mostrada no se repintó en el tick 2 (texto=%s, esperado que contenga %.2f)" % [button_tick_2.text, odds_tick_2])


func _fail(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] market_widget_unavailable_test: todos los checks OK")
	else:
		push_error("[FAIL] market_widget_unavailable_test: %d fallo(s)" % _failures.size())
		for failure in _failures:
			push_error("  - " + failure)

	quit(0 if _failures.is_empty() else 1)
