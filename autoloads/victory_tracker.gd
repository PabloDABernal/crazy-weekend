extends Node
## VictoryTracker (autoload) — evaluador genérico del sistema de tipos de victoria y final canónico.
## No conoce el sistema de partidos/apuestas: se suscribe únicamente a señales de EventBus
## (market_bet_resolved, money_changed, run_started). Lee/escribe VictoryCategoryState vía MetaProgress.
## Ver .ai-studio/specs/epic-a-tipos-de-victoria.md sección 4.
##
## Orden de carga en project.godot: después de MetaProgress y RunState (necesita leer ambos), y después
## de EconomyRules/LeagueRules/LeagueState (Épica D), ya que no depende de ellos pero así queda agrupado
## al final del orden de autoloads existentes sin reordenar los ya registrados por Épica D.

## Asignado en editor: victory_requirement_set_mvp.tres en MVP. Cambiar esta única referencia (no la
## lógica de _check_final_ending()) es lo que permite pasar de 6 a 8 categorías en post-MVP.
@export var active_requirement_set: VictoryRequirementSet

const REQUIREMENT_SET_PATH: String = "res://resources/definitions/victory/victory_requirement_set_mvp.tres"


func _ready() -> void:
	if active_requirement_set == null:
		active_requirement_set = ResourceLoader.load(REQUIREMENT_SET_PATH)
	EventBus.market_bet_resolved.connect(_on_market_bet_resolved)
	EventBus.money_changed.connect(_on_money_changed)
	EventBus.run_started.connect(_on_run_started)


## Conectado a EventBus.market_bet_resolved. Solo actúa cuando won == true: fallar una apuesta nunca
## puede cumplir un reto de desbloqueo (ver epic-a-tipos-de-victoria.md sección 2.1).
func _on_market_bet_resolved(result: MarketBetResult) -> void:
	if not result.won:
		return
	if active_requirement_set == null:
		return

	for def in active_requirement_set.required_categories:
		if def.family != VictoryCategoryDef.Family.MARKET:
			continue
		var state: VictoryCategoryState = MetaProgress.get_victory_category_state(def.category_id)
		if state.unlocked:
			continue
		if VictoryCategoryEvaluator.evaluate_market_bet_result(def, state, result):
			_unlock_category(def.category_id)
		else:
			# La evaluación pudo haber mutado contadores (persistent_hit_count, per_run_hit_count,
			# matchday_hits) sin llegar a desbloquear todavía: persistir igual para no perder progreso.
			MetaProgress.save_victory_category_state(state)


## Conectado a EventBus.money_changed (A.8). Evalúa el slot combinado de hito económico en tiempo
## real, dentro de una run activa, sin importar si la run termina ganada o perdida.
func _on_money_changed(new_amount: int, _delta: int, _reason: String) -> void:
	if active_requirement_set == null:
		return

	for def in active_requirement_set.required_categories:
		if def.criterion_type != VictoryCategoryDef.CriterionType.MONEY_THRESHOLD_ANY:
			continue
		var state: VictoryCategoryState = MetaProgress.get_victory_category_state(def.category_id)
		var newly_resolved: bool = VictoryCategoryEvaluator.evaluate_money_threshold(def, state, new_amount)
		if newly_resolved:
			_unlock_category(def.category_id)
		else:
			MetaProgress.save_victory_category_state(state)


## Conectado a EventBus.run_started. Resetea per_run_hit_count de las categorías PER_RUN (en MVP:
## victory_goles). matchday_hits no se resetea aquí: solo se limpia por cambio de jornada (ver
## VictoryCategoryEvaluator._evaluate_market_hit_distinct_matchday).
func _on_run_started(_starting_money: int, _run_number: int) -> void:
	if active_requirement_set == null:
		return

	for def in active_requirement_set.required_categories:
		if def.criterion_type != VictoryCategoryDef.CriterionType.MARKET_HIT_COUNT:
			continue
		if def.counter_scope != VictoryCategoryDef.CounterScope.PER_RUN:
			continue
		var state: VictoryCategoryState = MetaProgress.get_victory_category_state(def.category_id)
		state.per_run_hit_count = 0
		MetaProgress.save_victory_category_state(state)


## Marca la categoría como desbloqueada, persiste, emite victory_category_unlocked y comprueba si esto
## completa el final canónico.
func _unlock_category(category_id: StringName) -> void:
	var state: VictoryCategoryState = MetaProgress.get_victory_category_state(category_id)
	if state.unlocked:
		return

	state.unlocked = true
	state.unlocked_at_run_number = RunState.run_number
	state.unlocked_at_date = Time.get_datetime_string_from_system(true)
	MetaProgress.save_victory_category_state(state)
	# Fix QA (persistencia): un desbloqueo de categoría es progreso duradero -- se guarda en el acto,
	# no solo al cerrar la run, para no perderlo si el jugador cierra el juego a mitad de una run.
	MetaProgress.save()

	EventBus.victory_category_unlocked.emit(category_id, RunState.run_number)
	_check_final_ending()


## A.9 — disparo del final canónico. Ciego a qué/cuántas categorías componen active_requirement_set:
## solo itera required_categories y comprueba unlocked. El final se dispara en la run donde se completa
## la última categoría, sin importar si esa run se gana o se pierde en dinero.
func _check_final_ending() -> void:
	if MetaProgress.is_final_ending_triggered():
		return
	if active_requirement_set == null:
		return

	for def in active_requirement_set.required_categories:
		if not MetaProgress.get_victory_category_state(def.category_id).unlocked:
			return

	MetaProgress.mark_final_ending_triggered(RunState.run_number)
	EventBus.final_ending_triggered.emit(RunState.run_number)
