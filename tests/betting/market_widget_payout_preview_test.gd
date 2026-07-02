extends SceneTree
## Test de integración de MarketWidget (E.7): cuota por opción + PayoutPreviewLabel vivo. Ver
## .ai-studio/specs/story-e7-cuota-ganancia-potencial.md sección 3.
##
## Ejecutar headless (requiere Godot instalado en el entorno que corra el test):
##   godot --headless --path . --script res://tests/betting/market_widget_payout_preview_test.gd

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
	var offers: Array[MarketOffer] = [offer_home, offer_away]

	widget.refresh(offers)
	await process_frame

	_test_option_button_shows_odds(widget, offer_home)
	_test_preview_updates_on_stake_change(widget, offer_away)
	_test_preview_shows_range_when_probability_range(widget)
	_test_preview_collapses_to_single_value_when_fixed(widget)

	_finish()


func _build_offer(option_key: StringName, p_min: float, p_max: float) -> MarketOffer:
	var offer := MarketOffer.new()
	offer.market_id = &"1x2"
	offer.match_id = &"match_test"
	offer.option_key = option_key
	offer.displayed_probability_min = p_min
	offer.displayed_probability_max = p_max
	return offer


func _test_option_button_shows_odds(widget: MarketWidget, offer_home: MarketOffer) -> void:
	var button: Button = widget._option_buttons.get(&"home", null)
	if button == null:
		_fail("no se encontró el botón de la opción 'home'")
		return

	var odds_range: Vector2 = OddsMath.odds_range_from_probability_range(offer_home.displayed_probability_min, offer_home.displayed_probability_max)
	var expected_fragment: String = "%.2f-%.2f" % [odds_range.x, odds_range.y]
	if not button.text.contains(expected_fragment):
		_fail("el texto del botón de opción no incluye la cuota esperada '%s' (texto=%s)" % [expected_fragment, button.text])


func _test_preview_updates_on_stake_change(widget: MarketWidget, offer_away: MarketOffer) -> void:
	widget._on_option_button_pressed(&"away")
	widget._stake_input.value = 100.0
	await process_frame

	var odds_range: Vector2 = OddsMath.odds_range_from_probability_range(offer_away.displayed_probability_min, offer_away.displayed_probability_max)
	var payout_min: int = OddsMath.potential_return(100, odds_range.x)
	var payout_max: int = OddsMath.potential_return(100, odds_range.y)

	var label_text: String = widget._payout_preview_label.text
	if not (label_text.contains(str(payout_min)) and label_text.contains(str(payout_max))):
		_fail("PayoutPreviewLabel no refleja el importe recién introducido (esperado min=%d max=%d, texto=%s)" % [payout_min, payout_max, label_text])

	widget._stake_input.value = 250.0
	await process_frame
	var payout_min_2: int = OddsMath.potential_return(250, odds_range.x)
	var label_text_2: String = widget._payout_preview_label.text
	if not label_text_2.contains(str(payout_min_2)):
		_fail("PayoutPreviewLabel no se actualizó en tiempo real al cambiar el importe (texto=%s)" % label_text_2)


func _test_preview_shows_range_when_probability_range(widget: MarketWidget) -> void:
	# La opción "away" ya seleccionada tiene un rango de probabilidad no colapsado (0.2-0.3) -> el
	# formato de boleto debe mostrarse como rango, no como un único valor "neto".
	var label_text: String = widget._payout_preview_label.text
	if label_text.contains("neto"):
		_fail("con probabilidad en rango la ganancia potencial no debería mostrarse como valor único con 'neto' (texto=%s)" % label_text)


func _test_preview_collapses_to_single_value_when_fixed(widget: MarketWidget) -> void:
	var offer_fixed := _build_offer(&"draw", 0.4, 0.4)
	widget.refresh([offer_fixed])
	widget._on_option_button_pressed(&"draw")
	widget._stake_input.value = 100.0
	await process_frame

	var label_text: String = widget._payout_preview_label.text
	if not label_text.contains("neto"):
		_fail("con probabilidad fija (rango colapsado) la ganancia potencial debería mostrarse como valor único con 'neto' (texto=%s)" % label_text)


func _fail(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("[PASS] market_widget_payout_preview_test: todos los checks OK")
	else:
		push_error("[FAIL] market_widget_payout_preview_test: %d fallo(s)" % _failures.size())
		for failure in _failures:
			push_error("  - " + failure)

	quit(0 if _failures.is_empty() else 1)
