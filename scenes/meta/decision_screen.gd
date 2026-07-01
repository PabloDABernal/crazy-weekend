class_name DecisionScreen extends Control
## Decisión conversacional simplificada de la fase inter-run (E.6): 2-3 opciones de dinero extra, sin
## botón de "saltar" (decisión no opcional). Usa MetaProgress.unlock_money_bonus_with_explicit_amount
## -- no reinventa el mecanismo de bonus de dinero de B.1.
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 8.3/8.4.

signal decision_confirmed(bonus_amount: int)

@onready var _options_container: Container = $OptionsContainer

var _options: Array[InterrunDecisionOption] = []


func setup(options: Array[InterrunDecisionOption]) -> void:
	_options = options
	for child in _options_container.get_children():
		child.queue_free()

	for option in options:
		var button := Button.new()
		var label_text: String = option.prompt_text
		if not option.flavor_text.is_empty():
			label_text += "\n%s" % option.flavor_text
		button.text = label_text
		button.pressed.connect(_on_option_selected.bind(option))
		_options_container.add_child(button)


func _on_option_selected(option: InterrunDecisionOption) -> void:
	var bonus_id := StringName("interrun_decision_%s_run_%d" % [option.option_id, RunState.run_number])
	MetaProgress.unlock_money_bonus_with_explicit_amount(bonus_id, option.money_bonus_amount)
	decision_confirmed.emit(option.money_bonus_amount)
