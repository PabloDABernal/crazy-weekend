class_name TopBar extends Control
## Barra superior de BettingRoot: saldo, hora/cuenta regresiva, y resumen de apuestas pendientes.
## Siempre visible durante toda la run (E.4, criterio de éxito "saldo/apuestas pendientes/hora
## siempre visibles"). Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 2.1/3.1.

@onready var _balance_display: Label = $BalanceDisplay
@onready var _hour_display: Label = $HourDisplay
@onready var _pending_bets_list: VBoxContainer = $PendingBetsSummary/PendingBetsList


func _ready() -> void:
	EventBus.money_changed.connect(_on_money_changed)
	refresh_balance(RunState.get_money())


func refresh_balance(amount: int) -> void:
	_balance_display.text = "$%d" % amount


func set_hour_text(text: String) -> void:
	_hour_display.text = text


func refresh_pending_bets(_pending: Array[PendingBet]) -> void:
	pass  # Pending bets ahora los gestiona BettingRoot directamente en RightPanel


func _resolve_match_label(match_id: StringName) -> String:
	for matchday in LeagueState.calendar:
		for fixture in matchday.matches:
			if fixture.match_id == match_id:
				var home: TeamDef = LeagueState.get_team(fixture.home_team_id)
				var away: TeamDef = LeagueState.get_team(fixture.away_team_id)
				var h: String = home.display_name if home != null else String(fixture.home_team_id)
				var a: String = away.display_name if away != null else String(fixture.away_team_id)
				return "%s vs %s" % [h, a]
	return String(match_id)


func _format_market_name(market_id: StringName) -> String:
	match String(market_id):
		"1x2": return "resultado"
		"btts": return "ambos marcan"
		"first_scorer": return "primer goleador"
		"goals_ou_1_5": return "goles +/-1.5"
		"goals_ou_2_5": return "goles +/-2.5"
		"goals_ou_3_5": return "goles +/-3.5"
		"cards_ou": return "tarjetas"
		"fouls_ou": return "faltas"
	return String(market_id)


func _on_money_changed(new_amount: int, _delta: int, _reason: String) -> void:
	refresh_balance(new_amount)
