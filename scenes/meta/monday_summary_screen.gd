class_name MondaySummaryScreen extends Control
## Resumen de lunes (E.6): resultado de la run recién cerrada y categorías de tipo de victoria
## desbloqueadas durante esa run. No decide qué se desbloqueó -- recibe la lista ya recolectada por
## BettingRoot mientras la run estaba activa (ver epic-e-pantalla-de-apuestas.md sección 8.2.1).
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 8.2.

const FLAVOR_DEFINITIONS_DIR: String = "res://resources/definitions/victory_flavor/"

signal continue_pressed()

@onready var _outcome_label: Label = $OutcomeLabel
@onready var _final_money_label: Label = $FinalMoneyLabel
@onready var _unlocked_categories_list: VBoxContainer = $UnlockedCategoriesList
@onready var _continue_button: Button = $ContinueButton


func _ready() -> void:
	_continue_button.pressed.connect(_on_continue_pressed)


func setup(result: RunResult, unlocked_this_run: Array) -> void:
	_outcome_label.text = "Victoria" if result.outcome == RunResult.Outcome.WON else "Derrota"
	_final_money_label.text = "Dinero final: $%d" % result.final_money

	for child in _unlocked_categories_list.get_children():
		child.queue_free()

	for category_id in unlocked_this_run:
		var label := Label.new()
		label.text = _resolve_display_name(category_id)
		_unlocked_categories_list.add_child(label)


func _resolve_display_name(category_id: StringName) -> String:
	var path: String = FLAVOR_DEFINITIONS_DIR + String(category_id) + ".tres"
	if not ResourceLoader.exists(path):
		return String(category_id)
	var flavor: VictoryCategoryFlavor = ResourceLoader.load(path)
	return flavor.display_name if flavor != null else String(category_id)


func _on_continue_pressed() -> void:
	continue_pressed.emit()
