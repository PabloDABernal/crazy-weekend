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


func refresh_pending_bets(pending: Array[PendingBet]) -> void:
	for child in _pending_bets_list.get_children():
		child.queue_free()

	for pending_bet in pending:
		var label := Label.new()
		label.text = "%s: $%d en %s" % [String(pending_bet.match_id), pending_bet.stake, String(pending_bet.market_offer.market_id)]
		_pending_bets_list.add_child(label)


func _on_money_changed(new_amount: int, _delta: int, _reason: String) -> void:
	refresh_balance(new_amount)
