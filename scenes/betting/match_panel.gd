class_name MatchPanel extends Control
## Panel de partido + interfaz de mercados (E.3/E.4). Instanciado una vez por MatchFixture del día
## actual, con visible controlado por BettingRoot según el partido enfocado -- nunca se destruye al
## cambiar de foco (preserva apuestas ya abiertas en otros partidos en paralelo).
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 3.

const COMMENTARY_PHRASE_BANK_PATH: String = "res://resources/definitions/commentary/commentary_phrase_bank_mvp.tres"

## Orden fijo en el que se buscan los MarketWidget_<market_id> hijos de MarketsContainer.
const MARKET_WIDGET_NODE_NAMES: Dictionary = {
	"1x2": "MarketWidget_1x2",
	"goals_ou_1_5": "MarketWidget_goals_ou_1_5",
	"goals_ou_2_5": "MarketWidget_goals_ou_2_5",
	"goals_ou_3_5": "MarketWidget_goals_ou_3_5",
	"first_scorer": "MarketWidget_first_scorer",
	"btts": "MarketWidget_btts",
	"cards_ou": "MarketWidget_cards_ou",
	"fouls_ou": "MarketWidget_fouls_ou",
}

signal bet_confirmed(match_id: StringName, market_offer: MarketOffer, stake: int, tick_index: int)
signal tick_bet_requirement_satisfied(match_id: StringName)

@onready var _scoreboard_panel: ScoreboardPanel = $VBox/ScoreboardPanel
@onready var _stats_panel: StatsPanel = $VBox/StatsPanel
@onready var _commentary_panel: CommentaryPanel = $VBox/CommentaryPanel
@onready var _markets_container: Container = $VBox/MarketsScroll/MarketsContainer
@onready var _tick_status_label: Label = $VBox/TickStatusLabel

var match_id: StringName = &""
var _current_tick_index: int = 0
var _has_bet_this_tick: bool = false
var _market_widgets_by_id: Dictionary = {}       # market_id (StringName) -> MarketWidget
var _active_crazy_bet: CrazyBetContext = null
var _phrase_bank: CommentaryPhraseBank = null
var _current_tick_market_ids: Array[StringName] = []  # mercados con oferta vigente este tick (ver E.9 fix)


func _ready() -> void:
	for market_id in MARKET_WIDGET_NODE_NAMES.keys():
		var node_name: String = MARKET_WIDGET_NODE_NAMES[market_id]
		var widget: MarketWidget = _markets_container.get_node_or_null(NodePath(node_name))
		if widget != null:
			_market_widgets_by_id[StringName(market_id)] = widget
			widget.bet_confirmed.connect(_on_market_widget_bet_confirmed)
	if ResourceLoader.exists(COMMENTARY_PHRASE_BANK_PATH):
		_phrase_bank = ResourceLoader.load(COMMENTARY_PHRASE_BANK_PATH)


func setup(match_id_value: StringName) -> void:
	match_id = match_id_value


## Llamado por BettingRoot cuando llega un BetTickContext para este match_id.
func on_tick_opened(context: BetTickContext, match_state: MatchTickState, home_team: TeamDef, away_team: TeamDef, commentary_context: TickCommentaryContext) -> void:
	_current_tick_index = context.tick_index_in_day

	_scoreboard_panel.refresh(match_state, home_team, away_team)
	_stats_panel.refresh(match_state)

	if _phrase_bank != null and commentary_context != null:
		# MatchSimulationService (Épica D) no conoce el concepto de Momento Crazy -- is_crazy_moment se
		# sobrescribe aquí con el estado ya resuelto por BettingRoot/B.3 antes de invocar CommentaryResolver.
		commentary_context.is_crazy_moment = _active_crazy_bet != null
		var lines: Array[String] = CommentaryResolver.resolve_commentary_lines(commentary_context, _phrase_bank, home_team.team_id if home_team != null else &"", away_team.team_id if away_team != null else &"")
		_commentary_panel.refresh(lines)

	var offers_by_market: Dictionary = _group_offers_by_market(context.available_markets)
	_current_tick_market_ids.assign(offers_by_market.keys())
	for market_id in _market_widgets_by_id.keys():
		var widget: MarketWidget = _market_widgets_by_id[market_id]
		if offers_by_market.has(market_id):
			widget.refresh(offers_by_market[market_id])
			widget.visible = true
			widget.set_minimum_stake(StakeGate.compute_required_amount(RunState.get_money(), _active_crazy_bet))
		else:
			# D.7 ya retiró este mercado de available_markets (resuelto/imposible) -- E.9: mostrarlo
			# "retirado con razón" en vez de ocultarlo en seco (nunca queda apostable).
			widget.visible = true
			widget.set_unavailable(MarketUnavailabilityReasonResolver.resolve_reason(market_id, match_state))

	if _active_crazy_bet != null:
		apply_crazy_moment_restriction(_active_crazy_bet)

	_has_bet_this_tick = false
	_tick_status_label.text = "⬇ Apuesta algo en este partido"


## Aplica la restricción de mercados/stake forzoso del Momento Crazy vigente a los MarketWidget con
## oferta vigente en el tick actual (_current_tick_market_ids, poblado por on_tick_opened). Los
## mercados ya retirados por D.7 (fuera de _current_tick_market_ids) se dejan intactos en su estado
## set_unavailable -- Reviewer, bug bloqueante D.7+E.9: iterar los 8 widgets fijos del catálogo
## marcaba set_restricted(true) también sobre mercados ya "no disponibles", mostrando ambos overlays
## simultáneamente cuando la causa real era solo D.7 (ver E.9 sección 3.1: overlays distinguibles).
func apply_crazy_moment_restriction(crazy_bet: CrazyBetContext) -> void:
	_active_crazy_bet = crazy_bet
	for market_id in _current_tick_market_ids:
		var widget: MarketWidget = _market_widgets_by_id[market_id]
		if crazy_bet.allowed_market_ids.has(market_id):
			widget.apply_forced_stake(crazy_bet.forced_stake_amount)
			widget.set_restricted(false)
		else:
			widget.set_restricted(true)


## Limpia la restricción de Momento Crazy (crazy_moment_ended) -- vuelve al stake mínimo normal.
func clear_crazy_moment_restriction() -> void:
	_active_crazy_bet = null
	for market_id in _market_widgets_by_id.keys():
		var widget: MarketWidget = _market_widgets_by_id[market_id]
		widget.clear_forced_stake()
		widget.set_restricted(false)
		widget.set_minimum_stake(StakeGate.compute_required_amount(RunState.get_money(), null))


## true si este partido ya cumplió su apuesta obligatoria del tick vigente (incluida la condición de
## Crazy Bet resuelto si aplicaba -- ver BettingRoot, que es quien marca el Crazy Bet como resuelto).
func has_bet_this_tick() -> bool:
	return _has_bet_this_tick


func set_global_stake(amount: int) -> void:
	for widget in _market_widgets_by_id.values():
		widget.set_stake(amount)


## Invocado por BettingRoot cuando el Crazy Bet vigente ya fue resuelto por CUALQUIER MatchPanel (no
## necesariamente este) -- si este panel todavía no apostó, solo se le exige a partir de ahora el
## stake mínimo normal (ver sección 3.4 de la spec: el forzoso aplica una sola vez por tick global).
func mark_crazy_bet_resolved_elsewhere() -> void:
	clear_crazy_moment_restriction()


func _group_offers_by_market(offers: Array[MarketOffer]) -> Dictionary:
	var grouped: Dictionary = {}
	for offer in offers:
		if not grouped.has(offer.market_id):
			grouped[offer.market_id] = [] as Array[MarketOffer]
		grouped[offer.market_id].append(offer)
	return grouped


func _on_market_widget_bet_confirmed(market_id: StringName, option_key: StringName, stake: int) -> void:
	var widget: MarketWidget = _market_widgets_by_id.get(market_id, null)
	if widget == null:
		return

	var required: int = StakeGate.compute_required_amount(RunState.get_money(), _active_crazy_bet)
	if stake < required:
		return
	# Bug QA: la única validación previa era contra el mínimo/monto forzoso -- faltaba bloquear un
	# stake mayor al dinero disponible, que dejaría RunState.current_money en negativo (un estado no
	# contemplado por ninguna spec, ya que StakeResolver.is_run_dead() no lo detectaría a tiempo).
	if stake > RunState.get_money():
		return

	var market_offer: MarketOffer = _find_offer_for_option(widget, option_key)
	if market_offer == null:
		return

	bet_confirmed.emit(match_id, market_offer, stake, _current_tick_index)

	_has_bet_this_tick = true
	_tick_status_label.text = "✓ Apostado"
	tick_bet_requirement_satisfied.emit(match_id)


func _find_offer_for_option(widget: MarketWidget, option_key: StringName) -> MarketOffer:
	return widget.get_offer_for_option(option_key)


