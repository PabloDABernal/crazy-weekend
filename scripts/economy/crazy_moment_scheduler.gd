class_name CrazyMomentScheduler extends RefCounted
## Lógica pura de B.4 — decide en qué jornada(s) de una run habrá Momento Crazy y cuántos, según la
## fase narrativa, más el sorteo del tick exacto dentro de la jornada elegida (piso que excluye el
## primer tick). Se invoca una vez al inicio de cada run (RunState.start_new_run()).
## Ver .ai-studio/specs/epic-b-economia-de-run.md sección B.4.
##
## D.6: `tick_index` (aquí y en ScheduledCrazyMoment) se compara siempre contra RunState.
## current_tick_index, que desde D.6 se puebla con BetTickContext.clock_cycle (el ciclo de reloj
## GLOBAL de la jornada), NO con el tick_index_in_day propio de un partido -- ver comentario de
## RunState._crazy_moment_triggered_clock_cycle. El rango de sorteo (EconomyRules.
## CRAZY_MOMENT_MIN_TICK_INDEX .. TICKS_PER_DAY-1) sigue pensado para el modelo lockstep pre-D.6;
## Game Designer/Architect deberían revisarlo si la duración real de una jornada en ciclos de reloj
## (que ahora puede superar TICKS_PER_DAY con kickoffs muy escalonados) diverge del rango sorteado.


## Un slot planificado: qué día y qué ciclo de reloj GLOBAL de ese día disparará Momento Crazy.
class ScheduledCrazyMoment extends RefCounted:
	var day: BettingDay.Day
	var tick_index: int   # D.6: ciclo de reloj global (BetTickContext.clock_cycle), no tick de un partido concreto

	func _init(p_day: BettingDay.Day = BettingDay.Day.FRIDAY, p_tick_index: int = 0) -> void:
		day = p_day
		tick_index = p_tick_index


## Mapea NarrativePhase.Phase a la clave de cadencia de EconomyRules.CRAZY_MOMENT_SCHEDULE_BY_PHASE.
## PHASE_1 y PHASE_2 comparten la clave "phase_1_2" (ver nota en _arquitectura-base.md sección 2.3).
static func _schedule_key_for_phase(phase: NarrativePhase.Phase) -> String:
	match phase:
		NarrativePhase.Phase.PHASE_1, NarrativePhase.Phase.PHASE_2:
			return "phase_1_2"
		NarrativePhase.Phase.PHASE_3:
			return "phase_3"
		_:
			return "phase_4"


## Genera el plan completo de Momentos Crazy para una run nueva, a partir de la fase narrativa activa.
static func build_schedule_for_run(phase: NarrativePhase.Phase, rng: RandomNumberGenerator) -> Array[ScheduledCrazyMoment]:
	var schedule_key: String = _schedule_key_for_phase(phase)
	var schedule_config: Dictionary = EconomyRules.CRAZY_MOMENT_SCHEDULE_BY_PHASE[schedule_key]

	var allowed_days: Array = schedule_config["allowed_days"]

	var count: int
	if schedule_config.has("count"):
		count = schedule_config["count"]
	else:
		count = rng.randi_range(schedule_config["count_min"], schedule_config["count_max"])

	# Nunca el mismo día recibe 2 Momentos Crazy: se eligen `count` días distintos de allowed_days sin repetición.
	var chosen_days: Array = _pick_unique_days(allowed_days, count, rng)

	var schedule: Array[ScheduledCrazyMoment] = []
	for day in chosen_days:
		var tick_index: int = rng.randi_range(EconomyRules.CRAZY_MOMENT_MIN_TICK_INDEX, EconomyRules.TICKS_PER_DAY - 1)
		schedule.append(ScheduledCrazyMoment.new(day, tick_index))
	return schedule


## Elige `count` días distintos entre allowed_days sin repetición, preservando el orden de allowed_days
## cuando count == allowed_days.size() (caso sin ambigüedad); en el resto de casos elige por rng.
static func _pick_unique_days(allowed_days: Array, count: int, rng: RandomNumberGenerator) -> Array:
	var pool: Array = allowed_days.duplicate()
	if count >= pool.size():
		return pool

	var chosen: Array = []
	for i in range(count):
		var random_index: int = rng.randi_range(0, pool.size() - 1)
		chosen.append(pool[random_index])
		pool.remove_at(random_index)
	return chosen


## Consultado en cada bet_tick_opened: ¿el ciclo de reloj global actual coincide con algún slot
## planificado? (D.6: `tick_index` recibido aquí es RunState.current_tick_index, poblado desde
## BetTickContext.clock_cycle, no desde tick_index_in_day de un partido concreto).
static func is_crazy_moment_tick(schedule: Array[ScheduledCrazyMoment], day: BettingDay.Day, tick_index: int) -> bool:
	for slot in schedule:
		if slot.day == day and slot.tick_index == tick_index:
			return true
	return false
