class_name MarketWidget extends VBoxContainer

const OPTION_LABELS_PATH: String = "res://resources/definitions/market/market_option_labels.tres"

signal bet_confirmed(market_id: StringName, option_key: StringName, stake: int)

@onready var _market_title_label: Label = $MarketTitleLabel
@onready var _options_container: Container = $OptionsContainer
@onready var _payout_preview_label: Label = $PayoutPreviewLabel
@onready var _disabled_overlay: Control = $DisabledOverlay
@onready var _unavailable_overlay: Control = $UnavailableOverlay
@onready var _unavailable_reason_label: Label = $UnavailableReasonLabel

var market_id: StringName = &""
var _offers_by_option: Dictionary = {}
var _option_labels: MarketOptionLabels = null
var _option_buttons: Dictionary = {}

var _current_stake: int = 50
var _minimum_stake: int = 0
var _forced_stake_amount: int = -1
var _is_restricted: bool = false
var _is_unavailable: bool = false
var _bet_placed_this_tick: bool = false


func _ready() -> void:
	if ResourceLoader.exists(OPTION_LABELS_PATH):
		_option_labels = ResourceLoader.load(OPTION_LABELS_PATH)
	_disabled_overlay.visible = false
	_unavailable_overlay.visible = false
	_unavailable_reason_label.visible = false


func refresh(offers: Array[MarketOffer]) -> void:
	if offers.is_empty():
		return

	_clear_unavailable()
	_bet_placed_this_tick = false

	market_id = offers[0].market_id
	_offers_by_option.clear()
	for offer in offers:
		_offers_by_option[offer.option_key] = offer

	_market_title_label.text = _resolve_market_title(offers[0])
	_rebuild_option_buttons(offers)
	_update_payout_preview(null)


func set_unavailable(reason: String) -> void:
	_is_unavailable = true
	_unavailable_overlay.visible = true
	_unavailable_reason_label.visible = true
	_unavailable_reason_label.text = reason
	_market_title_label.modulate = Color(1.0, 1.0, 1.0, 0.45)
	for button in _option_buttons.values():
		button.disabled = true


func _clear_unavailable() -> void:
	_is_unavailable = false
	_unavailable_overlay.visible = false
	_unavailable_reason_label.visible = false
	_market_title_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	for button in _option_buttons.values():
		button.disabled = false


## Stake global enviado por BettingRoot cada vez que el jugador cambia la cantidad.
func set_stake(amount: int) -> void:
	_current_stake = max(amount, _minimum_stake)
	_update_payout_preview(null)


func apply_forced_stake(amount: int) -> void:
	_forced_stake_amount = amount
	_current_stake = amount
	_update_payout_preview(null)


func set_minimum_stake(amount: int) -> void:
	_minimum_stake = amount
	if _forced_stake_amount < 0:
		_current_stake = max(_current_stake, amount)
	_update_payout_preview(null)


func clear_forced_stake() -> void:
	_forced_stake_amount = -1
	_current_stake = max(_current_stake, _minimum_stake)
	_update_payout_preview(null)


func set_restricted(is_restricted_value: bool) -> void:
	_is_restricted = is_restricted_value
	_disabled_overlay.visible = is_restricted_value
	for button in _option_buttons.values():
		button.disabled = is_restricted_value or _bet_placed_this_tick


func get_offer_for_option(option_key: StringName) -> MarketOffer:
	return _offers_by_option.get(option_key, null)


func _rebuild_option_buttons(offers: Array[MarketOffer]) -> void:
	for child in _options_container.get_children():
		child.queue_free()
	_option_buttons.clear()

	for offer in offers:
		var button := Button.new()
		var label_text := _resolve_option_label(offer)
		var pct_min := int(round(offer.displayed_probability_min * 100.0))
		var pct_max := int(round(offer.displayed_probability_max * 100.0))
		var odds_range: Vector2 = OddsMath.odds_range_from_probability_range(
			offer.displayed_probability_min, offer.displayed_probability_max)
		var odds_text: String = _format_odds_range(odds_range)
		button.text = "%s\n%s\n%d%%-%d%%" % [label_text, odds_text, pct_min, pct_max]
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(88, 58)
		button.add_theme_font_size_override("font_size", 12)
		button.pressed.connect(_on_option_pressed.bind(offer.option_key))
		button.mouse_entered.connect(_on_option_hovered.bind(offer.option_key))
		_options_container.add_child(button)
		_option_buttons[offer.option_key] = button


func _on_option_hovered(option_key: StringName) -> void:
	if _bet_placed_this_tick:
		return
	_update_payout_preview(_offers_by_option.get(option_key, null))


func _on_option_pressed(option_key: StringName) -> void:
	if _is_restricted or _is_unavailable or _bet_placed_this_tick:
		return

	var stake: int = _forced_stake_amount if _forced_stake_amount >= 0 else _current_stake
	if stake < _minimum_stake:
		return
	if stake > RunState.get_money():
		return

	# Marcar como apostado — desactivar todos los botones para este tick
	_bet_placed_this_tick = true
	for key in _option_buttons.keys():
		var button: Button = _option_buttons[key]
		button.disabled = key != option_key
		button.button_pressed = key == option_key

	var offer: MarketOffer = _offers_by_option.get(option_key, null)
	_update_payout_preview(offer)
	bet_confirmed.emit(market_id, option_key, stake)


func _update_payout_preview(offer: MarketOffer) -> void:
	if _payout_preview_label == null:
		return

	if offer == null:
		offer = _estimate_offer_for_preview()
	if offer == null:
		_payout_preview_label.text = ""
		return

	var stake: int = _forced_stake_amount if _forced_stake_amount >= 0 else _current_stake
	var odds_range: Vector2 = OddsMath.odds_range_from_probability_range(
		offer.displayed_probability_min, offer.displayed_probability_max)

	if is_equal_approx(odds_range.x, odds_range.y):
		var payout: int = OddsMath.potential_return(stake, odds_range.x)
		_payout_preview_label.text = "$%d → devuelve $%d" % [stake, payout]
	else:
		var lo: int = OddsMath.potential_return(stake, odds_range.x)
		var hi: int = OddsMath.potential_return(stake, odds_range.y)
		_payout_preview_label.text = "$%d → devuelve $%d–$%d" % [stake, lo, hi]

	if _bet_placed_this_tick:
		_payout_preview_label.add_theme_color_override("font_color", Color(0.067, 0.902, 0.392, 1))
	else:
		_payout_preview_label.add_theme_color_override("font_color", Color(0.55, 0.65, 0.78, 1))


func _estimate_offer_for_preview() -> MarketOffer:
	var best: MarketOffer = null
	var best_prob: float = -1.0
	for offer in _offers_by_option.values():
		var avg: float = (offer.displayed_probability_min + offer.displayed_probability_max) / 2.0
		if avg > best_prob:
			best_prob = avg
			best = offer
	return best


func _resolve_market_title(offer: MarketOffer) -> String:
	match String(offer.market_id):
		"1x2": return "Resultado final"
		"btts": return "Ambos anotan"
		"first_scorer": return "Primer goleador"
		"cards_ou": return "Tarjetas +/- %s" % _format_threshold(offer.threshold_display)
		"fouls_ou": return "Faltas +/- %s" % _format_threshold(offer.threshold_display)
		"goals_ou_1_5", "goals_ou_2_5", "goals_ou_3_5":
			return "Goles +/- %s" % _format_threshold(offer.threshold_display)
		_: return String(offer.market_id)


func _resolve_option_label(offer: MarketOffer) -> String:
	if offer.market_id == &"first_scorer":
		var player: PlayerDef = _find_player(offer.option_key)
		return player.display_name if player != null else String(offer.option_key)
	var base: String = _option_labels.get_label(offer.option_key) if _option_labels != null else String(offer.option_key)
	if offer.threshold_display >= 0.0 and (String(offer.option_key) == "over" or String(offer.option_key) == "under"):
		return "%s %s" % [base, _format_threshold(offer.threshold_display)]
	return base


func _find_player(player_id: StringName) -> PlayerDef:
	for team in LeagueState.teams:
		for player in team.squad:
			if player.player_id == player_id:
				return player
	return null


func _format_threshold(threshold: float) -> String:
	return "%.1f" % threshold


func _format_odds_range(odds_range: Vector2) -> String:
	if is_equal_approx(odds_range.x, odds_range.y):
		return "%.2f" % odds_range.x
	return "%.2f–%.2f" % [odds_range.x, odds_range.y]
