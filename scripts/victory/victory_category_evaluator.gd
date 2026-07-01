class_name VictoryCategoryEvaluator extends RefCounted
## Lógica pura de evaluación de una VictoryCategoryDef contra su VictoryCategoryState, sin estado propio
## ni dependencia de autoloads — testeable de forma aislada. VictoryTracker delega aquí el switch sobre
## CriterionType; VictoryTracker se encarga solo de leer/escribir MetaProgress y emitir señales.
## Ver .ai-studio/specs/epic-a-tipos-de-victoria.md sección 4.1 (_evaluate_category).
##
## Nota de reconciliación de market_id (goles): Épica D emite market_id específicos por umbral
## ("goals_ou_1_5", "goals_ou_2_5", "goals_ou_3_5"), pero Victoria de Goles (A.3) usa el criterio
## genérico "mercado de goles" con market_id="goals_ou". El matching aplica prefijo: un
## MarketBetResult.market_id hace match con def.market_id == "goals_ou" si empieza con "goals_ou_".
## Para el resto de mercados (market_id exacto, ej. "1x2", "goals_ou_2_5", "cards_ou", "fouls_ou") el
## matching sigue siendo igualdad exacta.
const GENERIC_GOALS_MARKET_ID: StringName = &"goals_ou"
const GENERIC_GOALS_MARKET_PREFIX: String = "goals_ou_"


## true si el market_id de un MarketBetResult resuelto corresponde al market_id del criterio de la
## categoría, aplicando la regla de prefijo para el mercado genérico de goles.
static func market_id_matches(def_market_id: StringName, result_market_id: StringName) -> bool:
	if def_market_id == GENERIC_GOALS_MARKET_ID:
		return String(result_market_id).begins_with(GENERIC_GOALS_MARKET_PREFIX)
	return def_market_id == result_market_id


## Evalúa si un MarketBetResult (ya sabido won == true) desbloquea la categoría, según su criterion_type.
## No muta state directamente salvo los contadores/estructuras que forman parte de la evaluación misma
## (persistent_hit_count, per_run_hit_count, matchday_hits) — el flag `unlocked` lo decide y aplica
## VictoryTracker una vez que esta función devuelve true, vía _unlock_category().
static func evaluate_market_bet_result(def: VictoryCategoryDef, state: VictoryCategoryState, result: MarketBetResult) -> bool:
	if state.unlocked:
		return false
	if not market_id_matches(def.market_id, result.market_id):
		return false

	match def.criterion_type:
		VictoryCategoryDef.CriterionType.MARKET_HIT_WITH_TAG:
			return _evaluate_market_hit_with_tag(def, result)
		VictoryCategoryDef.CriterionType.MARKET_HIT_COUNT:
			return _evaluate_market_hit_count(def, state)
		VictoryCategoryDef.CriterionType.MARKET_HIT_DISTINCT_MATCHDAY:
			return _evaluate_market_hit_distinct_matchday(def, state, result)
		_:
			return false


static func _evaluate_market_hit_with_tag(def: VictoryCategoryDef, result: MarketBetResult) -> bool:
	return def.required_tag in result.context_tags


static func _evaluate_market_hit_count(def: VictoryCategoryDef, state: VictoryCategoryState) -> bool:
	if def.counter_scope == VictoryCategoryDef.CounterScope.PERSISTENT:
		state.persistent_hit_count += 1
		return state.persistent_hit_count >= def.required_count
	else:
		state.per_run_hit_count += 1
		return state.per_run_hit_count >= def.required_count


## matchday_hits se resetea por jornada (no por run): si matchday_id cambió respecto a la jornada ya
## registrada, se limpia antes de insertar el nuevo match_id. Cuenta partidos únicos, no aciertos.
static func _evaluate_market_hit_distinct_matchday(def: VictoryCategoryDef, state: VictoryCategoryState, result: MarketBetResult) -> bool:
	var matchday_key: StringName = result.matchday_id

	# Si matchday_hits tiene datos de otra jornada distinta, se limpian primero (solo se sigue una
	# jornada "activa" a la vez para esta categoría). Se copian las claves antes de iterar para no
	# mutar el Dictionary mientras se recorre.
	var existing_keys: Array = state.matchday_hits.keys().duplicate()
	for existing_key in existing_keys:
		if existing_key != matchday_key:
			state.matchday_hits.erase(existing_key)

	var current_hits: Array = state.matchday_hits.get(matchday_key, [])
	if not (result.match_id in current_hits):
		current_hits.append(result.match_id)
	state.matchday_hits[matchday_key] = current_hits

	return current_hits.size() >= def.required_count


## A.8 — MONEY_THRESHOLD_ANY. Para cada umbral en def.money_thresholds: si new_amount >= umbral y aún
## no estaba marcado, se marca. Devuelve true si el slot pasa a resuelto en esta llamada (algún umbral
## se cumplió por primera vez), independientemente de si el slot ya estaba unlocked antes (los demás
## umbrales se siguen marcando para completismo del Expediente incluso con el slot ya resuelto).
static func evaluate_money_threshold(def: VictoryCategoryDef, state: VictoryCategoryState, new_amount: int) -> bool:
	var newly_reached_any: bool = false
	for threshold in def.money_thresholds:
		var already_reached: bool = state.milestone_reached.get(threshold, false)
		if not already_reached and new_amount >= threshold:
			state.milestone_reached[threshold] = true
			newly_reached_any = true

	if state.unlocked:
		return false
	return newly_reached_any
