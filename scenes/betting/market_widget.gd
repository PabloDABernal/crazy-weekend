class_name MarketWidget extends VBoxContainer
## Componente único de mercado, parametrizado por MarketDef.kind (E.4). Reutilizado para los 8
## MarketDef.kind del catálogo MVP -- no hay una escena por mercado.
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 3.3.

const OPTION_LABELS_PATH: String = "res://resources/definitions/market/market_option_labels.tres"

signal bet_confirmed(market_id: StringName, option_key: StringName, stake: int)

@onready var _market_title_label: Label = $MarketTitleLabel
@onready var _options_container: Container = $OptionsContainer
@onready var _stake_input: SpinBox = $BetRow/StakeInput
@onready var _confirm_bet_button: Button = $BetRow/ConfirmBetButton
@onready var _payout_preview_label: Label = $PayoutRow/PayoutPreviewLabel
@onready var _disabled_overlay: Control = $DisabledOverlay
@onready var _unavailable_overlay: Control = $UnavailableOverlay
@onready var _unavailable_reason_label: Label = $UnavailableReasonLabel

var market_id: StringName = &""
var _offers_by_option: Dictionary = {}   # option_key (StringName) -> MarketOffer
var _option_labels: MarketOptionLabels = null
var _selected_option_key: StringName = &""
var _option_buttons: Dictionary = {}     # option_key (StringName) -> Button

var _minimum_stake: int = 0
var _forced_stake_amount: int = -1       # -1 = sin stake forzoso vigente (no Crazy Bet)
var _is_restricted: bool = false
var _is_unavailable: bool = false        # E.9 -- mercado retirado por D.7 (resuelto/imposible)


func _ready() -> void:
	_confirm_bet_button.pressed.connect(_on_confirm_pressed)
	_stake_input.value_changed.connect(_on_stake_value_changed)
	if ResourceLoader.exists(OPTION_LABELS_PATH):
		_option_labels = ResourceLoader.load(OPTION_LABELS_PATH)
	_disabled_overlay.visible = false
	_unavailable_overlay.visible = false
	_unavailable_reason_label.visible = false


## Puebla el widget con las ofertas vigentes de este mercado para el tick actual.
func refresh(offers: Array[MarketOffer]) -> void:
	if offers.is_empty():
		return

	_clear_unavailable()

	market_id = offers[0].market_id
	_offers_by_option.clear()
	for offer in offers:
		_offers_by_option[offer.option_key] = offer

	_market_title_label.text = _resolve_market_title(offers[0])
	_rebuild_option_buttons(offers)
	_selected_option_key = &""
	_update_confirm_button_enabled()
	_update_payout_preview()


## E.9 -- estado "retirado con razón" de un mercado que D.7 dejó de ofertar (resuelto/imposible),
## distinto de set_restricted (restricción narrativa de Momento Crazy: no reutiliza el mismo overlay
## para no confundir las dos causas). Deshabilita opciones/confirm y deja el título atenuado + la
## razón visible; el contrato es "nunca ofertable, razón visible" (sección 3.1 de la spec).
func set_unavailable(reason: String) -> void:
	_is_unavailable = true
	_selected_option_key = &""
	_unavailable_overlay.visible = true
	_unavailable_reason_label.visible = true
	_unavailable_reason_label.text = reason
	_market_title_label.modulate = Color(1.0, 1.0, 1.0, 0.5)
	_stake_input.editable = false
	for key in _option_buttons.keys():
		var button: Button = _option_buttons[key]
		button.button_pressed = false
		button.disabled = true
	_update_confirm_button_enabled()


func _clear_unavailable() -> void:
	_is_unavailable = false
	_unavailable_overlay.visible = false
	_unavailable_reason_label.visible = false
	_market_title_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	for key in _option_buttons.keys():
		var button: Button = _option_buttons[key]
		button.disabled = false


func apply_forced_stake(amount: int) -> void:
	_forced_stake_amount = amount
	_stake_input.value = float(amount)
	_stake_input.editable = false
	_update_confirm_button_enabled()
	_update_payout_preview()


func set_minimum_stake(amount: int) -> void:
	_minimum_stake = amount
	if _forced_stake_amount < 0:
		_stake_input.editable = true
		_stake_input.min_value = float(amount)
		if _stake_input.value < float(amount):
			_stake_input.value = float(amount)
	_update_confirm_button_enabled()
	_update_payout_preview()


## Limpia cualquier stake forzoso vigente (Momento Crazy terminado) y restaura edición normal.
func clear_forced_stake() -> void:
	_forced_stake_amount = -1
	_stake_input.editable = true
	_stake_input.min_value = float(_minimum_stake)
	if _stake_input.value < float(_minimum_stake):
		_stake_input.value = float(_minimum_stake)
	_update_confirm_button_enabled()
	_update_payout_preview()


func set_restricted(is_restricted_value: bool) -> void:
	_is_restricted = is_restricted_value
	_disabled_overlay.visible = is_restricted_value
	_update_confirm_button_enabled()


## Devuelve el MarketOffer vigente para un option_key ya poblado por el último refresh(). Usado por
## MatchPanel para recuperar el MarketOffer completo al recibir bet_confirmed (que solo lleva
## option_key, no el MarketOffer completo).
func get_offer_for_option(option_key: StringName) -> MarketOffer:
	return _offers_by_option.get(option_key, null)


func _rebuild_option_buttons(offers: Array[MarketOffer]) -> void:
	for child in _options_container.get_children():
		child.queue_free()
	_option_buttons.clear()

	for offer in offers:
		var button := Button.new()
		var label := _resolve_option_label(offer)
		var pct_min := int(round(offer.displayed_probability_min * 100.0))
		var pct_max := int(round(offer.displayed_probability_max * 100.0))
		var odds_range: Vector2 = OddsMath.odds_range_from_probability_range(offer.displayed_probability_min, offer.displayed_probability_max)
		var odds_text: String = _format_odds_range(odds_range)
		# Jerarquía de lectura (game-design "Jerarquía de lectura"): cuota como dato principal, la
		# probabilidad de apoyo -- la cuota va en su propia línea, con más peso visual (etiqueta en
		# negrita simulada con mayúsculas/tamaño delegado al layout de implementación).
		button.text = "%s\n%s\n%d%%-%d%%" % [label, odds_text, pct_min, pct_max]
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(80, 52)
		button.pressed.connect(_on_option_button_pressed.bind(offer.option_key))
		_options_container.add_child(button)
		_option_buttons[offer.option_key] = button


## "<cuota_min>-<cuota_max>" o una sola cuota si el rango colapsa (probabilidad fija, ya investigada).
func _format_odds_range(odds_range: Vector2) -> String:
	if is_equal_approx(odds_range.x, odds_range.y):
		return "%.2f" % odds_range.x
	return "%.2f-%.2f" % [odds_range.x, odds_range.y]


func _resolve_market_title(offer: MarketOffer) -> String:
	match String(offer.market_id):
		"1x2":
			return "Resultado final"
		"btts":
			return "Ambos anotan"
		"first_scorer":
			return "Primer goleador"
		"cards_ou":
			return "Tarjetas +/- %s" % _format_threshold(offer.threshold_display)
		"fouls_ou":
			return "Faltas +/- %s" % _format_threshold(offer.threshold_display)
		"goals_ou_1_5", "goals_ou_2_5", "goals_ou_3_5":
			return "Goles +/- %s" % _format_threshold(offer.threshold_display)
		_:
			return String(offer.market_id)


func _resolve_option_label(offer: MarketOffer) -> String:
	if offer.market_id == &"first_scorer":
		var player: PlayerDef = _find_player(offer.option_key)
		return player.display_name if player != null else String(offer.option_key)

	var base_label: String = _option_labels.get_label(offer.option_key) if _option_labels != null else String(offer.option_key)
	if offer.threshold_display >= 0.0 and (String(offer.option_key) == "over" or String(offer.option_key) == "under"):
		return "%s %s" % [base_label, _format_threshold(offer.threshold_display)]
	return base_label


func _find_player(player_id: StringName) -> PlayerDef:
	for team in LeagueState.teams:
		for player in team.squad:
			if player.player_id == player_id:
				return player
	return null


func _format_threshold(threshold: float) -> String:
	return "%.1f" % threshold


func _on_option_button_pressed(option_key: StringName) -> void:
	_selected_option_key = option_key
	for key in _option_buttons.keys():
		var button: Button = _option_buttons[key]
		button.button_pressed = key == option_key
	_update_confirm_button_enabled()
	_update_payout_preview()


func _on_stake_value_changed(_new_value: float) -> void:
	_update_payout_preview()


func _update_confirm_button_enabled() -> void:
	var has_selection: bool = _selected_option_key != &""
	_confirm_bet_button.disabled = _is_restricted or _is_unavailable or not has_selection


## E.7 -- ganancia potencial viva en formato boleto, ligada al importe introducido y a la opción
## seleccionada. Ver .ai-studio/specs/story-e7-cuota-ganancia-potencial.md sección 3.
func _update_payout_preview() -> void:
	if _payout_preview_label == null:
		return

	var offer: MarketOffer = _offers_by_option.get(_selected_option_key, null)
	if offer == null:
		offer = _estimate_offer_for_preview()
	if offer == null:
		_payout_preview_label.text = ""
		return

	var stake: int = int(_stake_input.value)
	var odds_range: Vector2 = OddsMath.odds_range_from_probability_range(offer.displayed_probability_min, offer.displayed_probability_max)

	if is_equal_approx(odds_range.x, odds_range.y):
		var payout: int = OddsMath.potential_return(stake, odds_range.x)
		var net: int = OddsMath.potential_net(stake, odds_range.x)
		_payout_preview_label.text = "Apuestas $%d → devuelve $%d (neto +$%d)" % [stake, payout, net]
	else:
		var payout_min: int = OddsMath.potential_return(stake, odds_range.x)
		var payout_max: int = OddsMath.potential_return(stake, odds_range.y)
		_payout_preview_label.text = "Apuestas $%d → devuelve $%d–$%d" % [stake, payout_min, payout_max]


## Sin opción seleccionada, estima con la opción de mayor probabilidad mostrada (decisión de UX menor
## delegada a implementación por la spec, sección 3).
func _estimate_offer_for_preview() -> MarketOffer:
	var best_offer: MarketOffer = null
	var best_avg_probability: float = -1.0
	for offer in _offers_by_option.values():
		var avg_probability: float = (offer.displayed_probability_min + offer.displayed_probability_max) / 2.0
		if avg_probability > best_avg_probability:
			best_avg_probability = avg_probability
			best_offer = offer
	return best_offer


func _on_confirm_pressed() -> void:
	if _is_restricted or _is_unavailable or _selected_option_key == &"":
		return

	var stake: int = int(_stake_input.value)
	var required: int = _forced_stake_amount if _forced_stake_amount >= 0 else _minimum_stake
	if stake < required:
		return
	# Defensa de UI (el punto de validación real y bloqueante es MatchPanel, que conoce RunState) --
	# nunca se emite una apuesta con stake mayor al dinero disponible.
	if stake > RunState.get_money():
		return

	bet_confirmed.emit(market_id, _selected_option_key, stake)
