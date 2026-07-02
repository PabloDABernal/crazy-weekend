class_name LiveBetTicket extends VBoxContainer
## Ticket de boleto vivo: un componente por `PendingBet` abierta (patrón `MarketWidget`, reutilizable,
## no una escena por mercado). Muestra partido, mercado+opción, importe, cuota fijada, ganancia
## potencial, estado vivo (`LiveBetEvaluator`) y cuánto falta para su resolución.
## Ver .ai-studio/specs/story-e8-boleto-vivo.md sección 3.

const MARKET_NAMES_BY_ID: Dictionary = {
	"1x2": "resultado",
	"btts": "ambos marcan",
	"first_scorer": "1er goleador",
	"goals_ou_1_5": "goles >1.5",
	"goals_ou_2_5": "goles >2.5",
	"goals_ou_3_5": "goles >3.5",
	"cards_ou": "tarjetas",
	"fouls_ou": "faltas",
}

@onready var _match_label: Label = $MatchLabel
@onready var _market_label: Label = $MarketLabel
@onready var _stake_label: Label = $StakeLabel
@onready var _status_badge: Label = $StatusBadge
@onready var _resolution_label: Label = $ResolutionLabel

var _pending_bet: PendingBet = null


## Puebla el ticket con los datos fijos de la apuesta (no cambian hasta resolverse): partido, mercado,
## importe, cuota fijada (OddsMath de E.7 sobre el market_offer congelado) y ganancia potencial.
func setup(pending_bet: PendingBet, match_label_text: String) -> void:
	_pending_bet = pending_bet
	_match_label.text = match_label_text

	var offer: MarketOffer = pending_bet.market_offer
	_market_label.text = "%s · %s" % [_format_market_name(offer.market_id), String(offer.option_key)]

	var odds_center: float = OddsMath.frozen_odds_for_offer(offer)
	var potential_return: int = PayoutCalculator.compute_payout(pending_bet)
	_stake_label.text = "$%d @ %.2f → $%d" % [pending_bet.stake, odds_center, potential_return]


## Refresca el estado vivo y el "cuánto falta" contra el MatchTickState actual de este partido.
func refresh_live_state(match_state: MatchTickState) -> void:
	if _pending_bet == null or match_state == null:
		return

	var status: LiveBetEvaluator.LiveStatus = LiveBetEvaluator.evaluate(_pending_bet.market_offer, match_state)
	match status:
		LiveBetEvaluator.LiveStatus.WINNING:
			_status_badge.text = "vas ganando esta"
			_status_badge.modulate = Color(0.2, 0.85, 0.2)
		LiveBetEvaluator.LiveStatus.LOSING:
			_status_badge.text = "vas perdiendo esta"
			_status_badge.modulate = Color(0.85, 0.2, 0.2)
		LiveBetEvaluator.LiveStatus.UNDECIDED:
			_status_badge.text = "aún indeciso"
			_status_badge.modulate = Color(0.7, 0.7, 0.7)

	var ticks_left: int = LiveBetEvaluator.ticks_until_resolution(_pending_bet.market_offer, match_state)
	if ticks_left <= 0:
		_resolution_label.text = "cierra este tick"
	else:
		var closing_minute: int = match_state.current_minute + ticks_left * LeagueRules.MATCH_MINUTES_PER_TICK
		_resolution_label.text = "cierra en min %d" % closing_minute


func get_match_id() -> StringName:
	return _pending_bet.match_id if _pending_bet != null else &""


func _format_market_name(market_id: StringName) -> String:
	return MARKET_NAMES_BY_ID.get(String(market_id), String(market_id))
