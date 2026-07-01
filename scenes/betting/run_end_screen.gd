class_name RunEndScreen extends Control
## Cierre de run (E.5): pantalla mínima de victoria ("Fin de semana cerrado") o derrota ("Ya es
## lunes"). No muestra resumen de categorías desbloqueadas ni eventos de domingo -- eso es
## responsabilidad exclusiva de InterrunFlow (E.6).
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 7.

signal continue_pressed()

@onready var _victory_content: Control = $VictoryContent
@onready var _final_money_label: Label = $VictoryContent/FinalMoneyLabel
@onready var _victory_continue_button: Button = $VictoryContent/ContinueButton

@onready var _bankruptcy_content: Control = $BankruptcyContent
@onready var _bankruptcy_continue_button: Button = $BankruptcyContent/ContinueButton


func _ready() -> void:
	visible = false
	_victory_continue_button.pressed.connect(_on_continue_pressed)
	_bankruptcy_continue_button.pressed.connect(_on_continue_pressed)


func show_result(result: RunResult) -> void:
	visible = true
	var is_victory: bool = result.outcome == RunResult.Outcome.WON
	_victory_content.visible = is_victory
	_bankruptcy_content.visible = not is_victory

	if is_victory:
		_final_money_label.text = "Dinero final: $%d" % result.final_money


func _on_continue_pressed() -> void:
	continue_pressed.emit()
