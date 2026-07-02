extends Node
## RunState (autoload) — fuente de verdad del estado de la run activa. Se resetea en cada run_started,
## no persiste (ver game-design.md -> "Qué no persiste"). Ningún otro script muta current_money
## directamente: toda escena de apuestas llama a RunState.set_money(...).
## Ver .ai-studio/specs/_arquitectura-base.md sección 2.4 y .ai-studio/specs/epic-b-economia-de-run.md.

var current_money: int = 0
var run_number: int = 0                       # copia de MetaProgress.get_current_run_number() al iniciar la run
var current_day: BettingDay.Day = BettingDay.Day.FRIDAY
var current_tick_index: int = 0               # índice global de tick dentro de la jornada actual, reinicia por día
var peak_money_this_run: int = 0              # máximo histórico alcanzado en la run

## Plan de Momentos Crazy de la run activa (B.4). No persistente, se regenera en cada start_new_run().
var crazy_moment_schedule: Array[CrazyMomentScheduler.ScheduledCrazyMoment] = []

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _run_ended: bool = false

## Dedupe de disparo de Momento Crazy por tick (fix Bug 1, §7.1): bet_tick_opened se emite una vez por
## cada partido vivo del día, todos con el mismo (day, tick_index_in_day) cuando el tick es Crazy.
## Sin este recuerdo, _on_bet_tick_opened construiría y emitiría un CrazyBetContext distinto (re-sorteado)
## por cada partido, violando el contrato de "un único CrazyBetContext por tick" (epic-e §3.4 / epic-b B.3).
## -1 = todavía no se disparó ningún Momento Crazy en la run activa.
var _crazy_moment_triggered_day: int = -1
var _crazy_moment_triggered_tick_index: int = -1


func _ready() -> void:
	_rng.randomize()
	EventBus.bet_tick_opened.connect(_on_bet_tick_opened)


## Calcula dinero inicial (B.1: BASE_STARTING_MONEY + bonus de meta-progresión), genera el plan de
## Momentos Crazy de la run (B.4) y emite run_started.
func start_new_run() -> void:
	run_number = MetaProgress.get_current_run_number()
	current_money = EconomyRules.BASE_STARTING_MONEY + MetaProgress.get_total_starting_money_bonus()
	peak_money_this_run = current_money
	current_day = BettingDay.Day.FRIDAY
	current_tick_index = 0
	_run_ended = false
	_crazy_moment_triggered_day = -1
	_crazy_moment_triggered_tick_index = -1

	var phase: NarrativePhase.Phase = NarrativePhase.get_current_phase()
	crazy_moment_schedule = CrazyMomentScheduler.build_schedule_for_run(phase, _rng)

	EventBus.run_started.emit(current_money, run_number)


## Única vía de mutar dinero. Emite money_changed y actualiza peak_money_this_run. No evalúa muerte
## de run aquí: esa comprobación (B.2) ocurre al abrir el siguiente tick obligatorio, en
## _on_bet_tick_opened, coherente con "no hay tick de gracia".
func set_money(new_amount: int, reason: String) -> void:
	var delta: int = new_amount - current_money
	current_money = new_amount
	if current_money > peak_money_this_run:
		peak_money_this_run = current_money
	EventBus.money_changed.emit(current_money, delta, reason)


func get_money() -> int:
	return current_money


func end_run(result: RunResult) -> void:
	_run_ended = true
	EventBus.run_ended.emit(result)


## Orquestación de B.2/B.3/B.4 en cada tick obligatorio de apuesta.
func _on_bet_tick_opened(context: BetTickContext) -> void:
	if _run_ended:
		return

	current_day = context.day
	current_tick_index = context.tick_index_in_day

	# B.2: la comprobación de muerte de run ocurre al abrir el tick, antes de pedir ninguna apuesta.
	if StakeResolver.is_run_dead(current_money):
		var result := RunResult.new()
		result.outcome = RunResult.Outcome.LOST_BANKRUPT
		result.final_money = current_money
		result.peak_money = peak_money_this_run
		result.run_number = run_number
		end_run(result)
		return

	# B.4: ¿el tick actual coincide con algún slot planificado de Momento Crazy? Se dispara como máximo
	# una vez por (day, tick_index_in_day): advance_tick() emite bet_tick_opened una vez por cada
	# partido vivo del día, todos con el mismo tick_index_in_day, así que sin este dedupe este bloque
	# se ejecutaría N veces por tick (fix Bug 1, §7.1).
	var already_triggered_this_tick: bool = (
		_crazy_moment_triggered_day == int(current_day)
		and _crazy_moment_triggered_tick_index == current_tick_index
	)
	if not already_triggered_this_tick and CrazyMomentScheduler.is_crazy_moment_tick(crazy_moment_schedule, current_day, current_tick_index):
		_crazy_moment_triggered_day = int(current_day)
		_crazy_moment_triggered_tick_index = current_tick_index
		var phase: NarrativePhase.Phase = NarrativePhase.get_current_phase()
		var crazy_bet: CrazyBetContext = CrazyBetResolver.build_context(current_money, phase, context.available_markets, _rng)
		EventBus.crazy_moment_triggered.emit(crazy_bet)
	# Si no es Momento Crazy, el flujo normal de B.2 (StakeResolver.compute_required_stake) queda a
	# cargo de la escena de apuestas, que consulta current_money bajo demanda.
