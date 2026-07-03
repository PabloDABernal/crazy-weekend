class_name BettingRoot extends Control
## Escena raíz de una run (E.3/E.4): instancia MatchSimulationService (Épica D) como hijo, es dueña de
## PendingBetsTracker, MatchPanel xN, y los overlays de tutorial/Crazy Moment. Instanciada por
## GameFlowController al iniciar cada run, liberada al cerrar la run (tras mostrar RunEndScreen).
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 2.

signal run_closed(categories_unlocked_this_run: Array)

const MATCH_PANEL_SCENE: PackedScene = preload("res://scenes/betting/match_panel.tscn")
const LIVE_BET_TICKET_SCENE: PackedScene = preload("res://scenes/betting/live_bet_ticket.tscn")
const DISPLAY_MINUTES_BEFORE_KICKOFF: int = 3

@onready var _match_simulation_service: MatchSimulationService = $MatchSimulationService
@onready var _pending_bets_tracker: PendingBetsTracker = $PendingBetsTracker
@onready var _top_bar: TopBar = $MainVBox/TopBar
@onready var _match_selector: MatchSelector = $MainVBox/ContentHBox/LeftPanel/MatchSelector
@onready var _match_panel_container: Control = $MainVBox/ContentHBox/LeftPanel/MatchPanelContainer
@onready var _scoreboard_mini: VBoxContainer = $MainVBox/ContentHBox/RightPanel/RightPanelContent/ScoreboardMini
@onready var _pending_bets_panel: VBoxContainer = $MainVBox/ContentHBox/RightPanel/RightPanelContent/PendingBetsPanel
@onready var _global_status_label: Label = $MainVBox/BottomBar/GlobalStatusLabel
@onready var _continue_button: Button = $MainVBox/BottomBar/ContinueButton
@onready var _crazy_moment_overlay: CrazyMomentOverlay = $CrazyMomentOverlay
@onready var _tutorial_overlay: TutorialOverlay = $TutorialOverlay
@onready var _run_end_screen: RunEndScreen = $RunEndScreen
@onready var _resolution_feedback_overlay: ResolutionFeedbackOverlay = $ResolutionFeedbackOverlay
@onready var _empty_day_overlay: EmptyDayOverlay = $EmptyDayOverlay

var _score_labels: Dictionary = {}  # match_id (StringName) -> Label
var _live_bet_tickets: Array[LiveBetTicket] = []

var _focused_match_id: StringName = &""
var _match_panels: Dictionary = {}          # match_id (StringName) -> MatchPanel instanciado
var _matches_with_tick_open_this_cycle: Array[StringName] = []
var _active_crazy_bet: CrazyBetContext = null
var _crazy_bet_resolved_this_tick: bool = false
var _categories_unlocked_this_run: Array = []

var _display_clock_minutes_before_kickoff: int = DISPLAY_MINUTES_BEFORE_KICKOFF
var _kickoff_started: bool = false
var _landing_timer: Timer = null


func _ready() -> void:
	_run_end_screen.continue_pressed.connect(_on_run_end_continue_pressed)
	_empty_day_overlay.skip_finished.connect(_on_empty_day_skip_finished)
	_match_selector.match_focus_requested.connect(_on_match_selector_focus_requested)
	_continue_button.pressed.connect(request_advance_tick)
	_refresh_global_continue_state()

	EventBus.bet_tick_resolved.connect(_on_bet_tick_resolved)
	EventBus.bet_tick_opened.connect(_on_bet_tick_opened)
	EventBus.crazy_moment_triggered.connect(_on_crazy_moment_triggered)
	EventBus.crazy_moment_ended.connect(_on_crazy_moment_ended)
	EventBus.matchday_finished.connect(_on_matchday_finished)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.victory_category_unlocked.connect(_on_victory_category_unlocked)
	_pending_bets_tracker.bet_resolved.connect(_on_pending_bet_resolved)

	if not MetaProgress.has_completed_first_bet_tutorial():
		_tutorial_overlay.visible = true
	else:
		_tutorial_overlay.visible = false

	_start_day_and_countdown(RunState.current_day)


## E.1 — cuenta regresiva puramente visual/atmosférica de "15 minutos antes del kickoff". No bloquea
## nada, no requiere apuesta, termina automáticamente y da paso al primer advance_tick() real.
func _start_landing_countdown() -> void:
	_display_clock_minutes_before_kickoff = DISPLAY_MINUTES_BEFORE_KICKOFF
	_kickoff_started = false
	_update_hour_display()

	_landing_timer = Timer.new()
	_landing_timer.wait_time = 0.5
	_landing_timer.one_shot = false
	add_child(_landing_timer)
	_landing_timer.timeout.connect(_on_landing_timer_tick)
	_landing_timer.start()


func _on_landing_timer_tick() -> void:
	_display_clock_minutes_before_kickoff -= 1
	_update_hour_display()
	if _display_clock_minutes_before_kickoff <= 0:
		_landing_timer.stop()
		_landing_timer.queue_free()
		_landing_timer = null
		_kickoff_started = true
		_match_simulation_service.open_initial_tick()


## D.6 (sección 7): la hora de UI se formatea a partir de LeagueRules.DAY_BASE_HOUR + el reloj de
## jornada (MatchSimulationService.get_clock_minutes()), no es un dato de motor. Layout final fuera de
## alcance de esta historia (trabajo de Épica E) -- aquí solo se fija el dato mostrado.
func _update_hour_display() -> void:
	if not _kickoff_started and _display_clock_minutes_before_kickoff > 0:
		_top_bar.set_hour_text("📺 Arrancando jornada...")
	else:
		_top_bar.set_hour_text(_format_day_and_clock_label(RunState.current_day))


func _format_day_and_clock_label(day: BettingDay.Day) -> String:
	var day_label: String = _format_day_label(day)
	var base_hour: String = LeagueRules.DAY_BASE_HOUR.get(day, "")
	var clock_minutes: int = _match_simulation_service.get_clock_minutes()

	if base_hour == "" or not base_hour.contains(":"):
		return day_label

	var parts: PackedStringArray = base_hour.split(":")
	var base_total_minutes: int = int(parts[0]) * 60 + int(parts[1])
	var total_minutes: int = (base_total_minutes + clock_minutes) % (24 * 60)
	var display_time: String = "%02d:%02d" % [total_minutes / 60, total_minutes % 60]

	return "%s %s" % [day_label, display_time]


func _format_day_label(day: BettingDay.Day) -> String:
	match day:
		BettingDay.Day.FRIDAY:
			return "Viernes"
		BettingDay.Day.SATURDAY:
			return "Sábado"
		BettingDay.Day.SUNDAY:
			return "Domingo"
		_:
			return ""


## Arranca el día indicado y, si quedó con algún partido, su countdown de aterrizaje; si el día quedó
## sin ningún partido (D.6: jornada CONCENTRATED, que concentra todos los partidos en un único día),
## lo salta automáticamente en vez de esperar una apuesta obligatoria que nunca podría llegar -- misma
## invariante anti-bloqueo que motivó el Bug 1 (nunca dejar al jugador esperando algo imposible).
##
## E.10: el salto de un día vacío ya no es instantáneo -- se interpone EmptyDayOverlay (temporizador
## ~1.8s, sin capturar input) y el avance se difiere a _on_empty_day_skip_finished. Excepción: domingo
## vacío (caso teórico no alcanzable con los números reales de la liga, ver nota QA en
## _split_matches_for_day) no avanza a otro día -- cae directo en _close_run_after_sunday, así que
## conserva el salto directo para no encadenar la pantalla con la de fin de run.
func _start_day_and_countdown(day: BettingDay.Day) -> void:
	_start_day(day)
	if _match_panels.is_empty():
		if day == BettingDay.Day.SUNDAY:
			_on_matchday_finished(-1)
		else:
			_empty_day_overlay.show_empty_day(day, _next_day_with_matches(day))
	else:
		_start_landing_countdown()


## Reanuda el avance de día tras el temporizador de EmptyDayOverlay -- reproduce exactamente la
## llamada que antes de E.10 era inmediata (sección 4.3 de la spec).
func _on_empty_day_skip_finished() -> void:
	_on_matchday_finished(-1)


## Mismo mapeo que ya usa _on_matchday_finished (FRIDAY->SATURDAY, SATURDAY->SUNDAY); paso interno de
## _next_day_with_matches (E.10, sección 9 de la spec).
func _next_day_after(day: BettingDay.Day) -> BettingDay.Day:
	match day:
		BettingDay.Day.FRIDAY:
			return BettingDay.Day.SATURDAY
		BettingDay.Day.SATURDAY:
			return BettingDay.Day.SUNDAY
		_:
			return day


## Devuelve el primer día POSTERIOR a `from_day` que tiene al menos un partido, consultando el
## reparto por día ya determinista (_matches_for_day) sin arrancar ni mutar ningún día. Se usa sólo
## para poblar EmptyDayOverlay.DetailLabel con el próximo día con partidos (E.10, sección 9 de la
## spec, corrección post-commit 0a8c733). En una jornada CONCENTRATED con viernes y sábado vacíos,
## devuelve SUNDAY para ambos. Domingo (último día de la run) es el piso garantizado: en CONCENTRATED
## siempre tiene todos los partidos, así que el bucle siempre termina.
func _next_day_with_matches(from_day: BettingDay.Day) -> BettingDay.Day:
	var matchday_fixture: MatchdayFixture = LeagueState.get_current_matchday_fixture()
	var candidate: BettingDay.Day = from_day
	while candidate != BettingDay.Day.SUNDAY:
		candidate = _next_day_after(candidate)
		if matchday_fixture != null and not _matches_for_day(matchday_fixture, candidate).is_empty():
			return candidate
	return candidate


## Arranca la simulación del día indicado con el subconjunto de partidos de la jornada de liga
## correspondiente a ese día de la run. Instancia 1 MatchPanel por MatchFixture del día (todos
## ocultos salvo el enfocado por defecto). Puede dejar el día sin partidos (D.6, jornada CONCENTRATED)
## -- ver _start_day_and_countdown, que es quien decide qué hacer en ese caso.
func _start_day(day: BettingDay.Day) -> void:
	var matchday_fixture: MatchdayFixture = LeagueState.get_current_matchday_fixture()
	if matchday_fixture == null:
		return

	var matches_for_day: Array[MatchFixture] = _matches_for_day(matchday_fixture, day)

	var subset_fixture := MatchdayFixture.new()
	subset_fixture.matchday_index = matchday_fixture.matchday_index
	subset_fixture.matches = matches_for_day
	subset_fixture.schedule_kind = matchday_fixture.schedule_kind

	_clear_match_panels()
	_match_simulation_service.start_matchday(subset_fixture, day)

	for match_fixture in matches_for_day:
		_create_match_panel(match_fixture)

	if not _match_panels.is_empty():
		_set_focused_match(_match_panels.keys()[0])


## D.6 (sección 4.2): el reparto por día pasa a depender de schedule_kind. STAGGERED sigue el reparto
## en tercios de siempre (_split_matches_for_day); CONCENTRATED concentra todos los partidos en un
## único día (_concentrated_matches_for_day).
func _matches_for_day(matchday_fixture: MatchdayFixture, day: BettingDay.Day) -> Array[MatchFixture]:
	if matchday_fixture.schedule_kind == MatchdayFixture.ScheduleKind.CONCENTRATED:
		return _concentrated_matches_for_day(matchday_fixture.matches, day)
	return _split_matches_for_day(matchday_fixture.matches, day)


## Jornada especial CONCENTRATED ("Super Sunday", D.6 sección 4.2): todos los partidos caen en un único
## día (domingo, el de mayor audiencia de la run). Viernes/sábado quedan sin partidos ese fin de semana
## -- ver _start_day_and_countdown, que los salta automáticamente sin bloquear la run.
func _concentrated_matches_for_day(all_matches: Array[MatchFixture], day: BettingDay.Day) -> Array[MatchFixture]:
	if day == BettingDay.Day.SUNDAY:
		return all_matches.duplicate()
	return []


## Reparto de partidos de una jornada de liga (~10 partidos) entre los 3 días de la run (viernes,
## sábado, domingo) -- hueco de integración explícito de la spec (sección 2.3): no hay una tabla de
## contenido fijada por Épica D, se asume ~1/3 de los partidos por día. Reparto determinista por
## índice dentro de matchday_fixture.matches (no aleatorio), para que sea reproducible.
##
## Nota QA (confirmado, no aplicable): con chunk_size = ceil(total/3), el último día (domingo) queda
## sin partidos solo para total ∈ {1, 2, 4} (verificado exhaustivamente). LeagueRules.TEAM_COUNT = 20
## es una constante fija (nunca varía entre temporadas, ver LeagueState.generate_new_league()), así que
## toda jornada de liga tiene siempre exactamente 10 partidos (20 equipos / 2), y con total=10 el
## reparto real es 4/4/2 -- ningún día queda vacío. No se modifica esta función porque el caso
## problemático no es alcanzable con los números reales de la liga; si en el futuro TEAM_COUNT dejara
## de ser fijo (o impar), esta nota deja documentado que habría que revisar el reparto. (Solo se aplica
## a jornadas STAGGERED -- las CONCENTRATED usan _concentrated_matches_for_day, arriba.)
func _split_matches_for_day(all_matches: Array[MatchFixture], day: BettingDay.Day) -> Array[MatchFixture]:
	var total: int = all_matches.size()
	var day_index: int = int(day)   # FRIDAY=0, SATURDAY=1, SUNDAY=2
	var chunk_size: int = int(ceil(float(total) / 3.0))
	var start_index: int = day_index * chunk_size
	var end_index: int = min(start_index + chunk_size, total)

	var subset: Array[MatchFixture] = []
	if start_index >= total:
		return subset
	for i in range(start_index, end_index):
		subset.append(all_matches[i])
	return subset


func _create_match_panel(match_fixture: MatchFixture) -> void:
	var panel: MatchPanel = MATCH_PANEL_SCENE.instantiate()
	_match_panel_container.add_child(panel)
	panel.setup(match_fixture.match_id)
	panel.visible = false
	panel.bet_confirmed.connect(_on_match_panel_bet_confirmed)
	panel.tick_bet_requirement_satisfied.connect(_on_match_panel_tick_bet_requirement_satisfied)
	_match_panels[match_fixture.match_id] = panel

	var home_team: TeamDef = LeagueState.get_team(match_fixture.home_team_id)
	var away_team: TeamDef = LeagueState.get_team(match_fixture.away_team_id)
	var h: String = home_team.display_name if home_team != null else String(match_fixture.home_team_id)
	var a: String = away_team.display_name if away_team != null else String(match_fixture.away_team_id)
	var label: String = "%s vs %s" % [h, a]
	_match_selector.ensure_tab(match_fixture.match_id, label)

	var score_label := Label.new()
	score_label.text = "%s  0 — 0  %s  (pre)" % [h, a]
	score_label.add_theme_font_size_override("font_size", 12)
	score_label.add_theme_color_override("font_color", Color(0.780, 0.843, 0.910, 1.0))
	_scoreboard_mini.add_child(score_label)
	_score_labels[match_fixture.match_id] = score_label


func _clear_match_panels() -> void:
	for panel in _match_panels.values():
		panel.queue_free()
	_match_panels.clear()
	for lbl in _score_labels.values():
		lbl.queue_free()
	_score_labels.clear()
	_match_selector.clear_tabs()
	_focused_match_id = &""


func _set_focused_match(match_id: StringName) -> void:
	_focused_match_id = match_id
	for id in _match_panels.keys():
		var panel: MatchPanel = _match_panels[id]
		panel.visible = id == match_id
	_match_selector.set_focused(match_id)


## Conectado a MatchSelector.match_focus_requested (click en un MatchTabButton) -- permite cambiar de
## foco entre partidos en paralelo sin perder apuestas ya abiertas en otros (criterio de éxito E.3):
## los MatchPanel nunca se destruyen al cambiar visible, solo se ocultan/muestran.
func _on_match_selector_focus_requested(match_id: StringName) -> void:
	if _match_panels.has(match_id):
		_set_focused_match(match_id)


## Conectado a EventBus.bet_tick_resolved, emitido por MatchSimulationService.advance_tick()
## INMEDIATAMENTE ANTES de bet_tick_opened para este mismo match_id (fix de integración: separa la
## resolución/acreditación de apuestas pendientes de la apertura del tick nuevo). Resuelve las
## apuestas pendientes de este partido contra el MatchTickState recién cerrado -- este orden garantiza
## que RunState (conectado a bet_tick_opened) ya vea el dinero actualizado por el payout de este tick
## al evaluar StakeResolver.is_run_dead(), sin depender del orden de conexión de listeners sobre una
## misma señal (ver .ai-studio/specs/_arquitectura-base.md sección 2.1).
func _on_bet_tick_resolved(match_id: StringName, _tick_index: int) -> void:
	var match_state: MatchTickState = _match_simulation_service.get_match_tick_state(match_id)
	if match_state == null:
		return

	_pending_bets_tracker.resolve_bets_for_match(match_id, match_state, _current_matchday_id())
	_refresh_pending_bets_panel()
	_refresh_score_label(match_id, match_state)


## Enruta el context al MatchPanel correspondiente a context.available_markets[0].match_id (todas las
## entradas de un mismo BetTickContext comparten match_id). Solo puebla el panel con el nuevo contexto
## -- la resolución de apuestas pendientes de este partido ya ocurrió en _on_bet_tick_resolved, que
## MatchSimulationService garantiza que se emite antes que esta señal para el mismo match_id.
##
## D.6 (sección 6): _matches_with_tick_open_this_cycle (el gate de apuesta obligatoria) SOLO debe
## incluir partidos LIVE este ciclo -- las ofertas pre-partido (PRE_MATCH) son opcionales, no cuentan
## para el tick obligatorio. panel.on_tick_opened() se sigue llamando siempre, para todos los estados,
## así que un partido PRE_MATCH igual muestra sus mercados/odds pre-partido normalmente.
func _on_bet_tick_opened(context: BetTickContext) -> void:
	if context.available_markets.is_empty():
		return

	var match_id: StringName = context.available_markets[0].match_id
	var panel: MatchPanel = _match_panels.get(match_id, null)
	if panel == null:
		return

	var status: int = _match_simulation_service.get_match_status(match_id)
	if status == MatchSimulationService.MatchStatus.LIVE and not _matches_with_tick_open_this_cycle.has(match_id):
		_matches_with_tick_open_this_cycle.append(match_id)

	var match_state: MatchTickState = _match_simulation_service.get_match_tick_state(match_id)
	var commentary_context: TickCommentaryContext = _match_simulation_service.get_tick_commentary_context(match_id)
	var home_team: TeamDef = LeagueState.get_team(match_state.home_team_id) if match_state != null else null
	var away_team: TeamDef = LeagueState.get_team(match_state.away_team_id) if match_state != null else null

	panel.on_tick_opened(context, match_state, home_team, away_team, commentary_context)
	_update_hour_display()
	_refresh_global_continue_state()
	# E.8 -- el tick que avanza cambia el estado vivo de las apuestas abiertas de este partido (y de
	# cualquier otro ya refrescado), sin esperar a que se registre/resuelva una apuesta nueva.
	_refresh_live_bet_tickets()


## Delega a CrazyMomentOverlay y notifica a TODOS los MatchPanel activos (el Crazy Bet aplica al tick
## global, no solo al partido enfocado -- sección 3.4 de la spec). Se pasa literalmente el mismo
## CrazyBetContext (misma instancia, no una copia) a cada panel, para que BettingRoot y todos los
## MatchPanel/MarketWidget evalúen siempre el mismo contexto vigente (fix Bug 1, §7.3: fuente única de
## verdad del Crazy Bet -- combinado con el dedupe de RunState (§7.1) elimina la posibilidad de que
## dos partes del árbol de escena diverjan sobre qué contexto está activo).
func _on_crazy_moment_triggered(crazy_bet: CrazyBetContext) -> void:
	_activate_crazy_bet(crazy_bet)
	_crazy_moment_overlay.show_crazy_moment(crazy_bet)
	for panel in _match_panels.values():
		panel.apply_crazy_moment_restriction(crazy_bet)


func _on_crazy_moment_ended() -> void:
	_deactivate_crazy_bet()
	_crazy_moment_overlay.hide_crazy_moment()
	for panel in _match_panels.values():
		panel.clear_crazy_moment_restriction()


## Único punto que activa un Momento Crazy: `_active_crazy_bet` y `_crazy_bet_resolved_this_tick`
## cambian siempre juntos (fix Bug 1, §6/§7.3 -- antes se mutaban por separado en varios sitios,
## acoplamiento frágil que bastaba con reordenar para romper).
func _activate_crazy_bet(crazy_bet: CrazyBetContext) -> void:
	_active_crazy_bet = crazy_bet
	_crazy_bet_resolved_this_tick = false


## Único punto que desactiva el Momento Crazy vigente (fin de Crazy resuelto, o cambio de ciclo/día).
## Misma garantía que _activate_crazy_bet: ambos campos cambian siempre juntos.
func _deactivate_crazy_bet() -> void:
	_active_crazy_bet = null
	_crazy_bet_resolved_this_tick = false


## Fin de la jornada del día actual (viernes o sábado): transición al día siguiente. No implica fin
## de run (eso es EventBus.run_ended) -- ver sección 2.3 de la spec.
func _on_matchday_finished(_matchday_index: int) -> void:
	match RunState.current_day:
		BettingDay.Day.FRIDAY:
			RunState.current_day = BettingDay.Day.SATURDAY
			_advance_to_next_day(BettingDay.Day.SATURDAY)
		BettingDay.Day.SATURDAY:
			RunState.current_day = BettingDay.Day.SUNDAY
			_advance_to_next_day(BettingDay.Day.SUNDAY)
		BettingDay.Day.SUNDAY:
			_close_run_after_sunday()


func _advance_to_next_day(day: BettingDay.Day) -> void:
	_matches_with_tick_open_this_cycle.clear()
	_deactivate_crazy_bet()
	_start_day_and_countdown(day)


## Domingo terminado: victoria si dinero > 0, derrota (bancarrota) si llegó exactamente a 0 en la
## última resolución del domingo (sección 7.1 de la spec: evita aplicar ">= 0" por descuido).
func _close_run_after_sunday() -> void:
	if StakeResolver.is_run_dead(RunState.get_money()):
		var lost_result := RunResult.new()
		lost_result.outcome = RunResult.Outcome.LOST_BANKRUPT
		lost_result.final_money = RunState.get_money()
		lost_result.peak_money = RunState.peak_money_this_run
		lost_result.run_number = RunState.run_number
		RunState.end_run(lost_result)
		return

	if RunState.get_money() > 0:
		var won_result := RunResult.new()
		won_result.outcome = RunResult.Outcome.WON
		won_result.final_money = RunState.get_money()
		won_result.peak_money = RunState.peak_money_this_run
		won_result.run_number = RunState.run_number
		RunState.end_run(won_result)


func _on_run_ended(result: RunResult) -> void:
	_run_end_screen.show_result(result)


## Emite run_closed con las categorías desbloqueadas durante esta run -- GameFlowController es quien
## libera esta escena (queue_free()) al instanciar InterrunFlow en su lugar (ver
## GameFlowController._instantiate_and_show), evitando una doble liberación del mismo nodo.
func _on_run_end_continue_pressed() -> void:
	run_closed.emit(_categories_unlocked_this_run)


func _on_victory_category_unlocked(category_id: StringName, run_number: int) -> void:
	if run_number == RunState.run_number:
		_categories_unlocked_this_run.append(category_id)


## Único punto de entrada para pedir avanzar de tick.
func request_advance_tick() -> void:
	if not _all_matches_satisfied_this_cycle():
		return

	_matches_with_tick_open_this_cycle.clear()
	# Blindaje del gate (fix Bug 1, §7.3): request_advance_tick() solo se ejecuta si
	# _all_matches_satisfied_this_cycle() ya dio true, lo que exige que cualquier Crazy Bet del ciclo
	# saliente ya esté resuelto (_active_crazy_bet == null, ver _on_match_panel_bet_confirmed). Se
	# desactiva explícitamente aquí de todos modos para no depender de ese camino como único garante.
	_deactivate_crazy_bet()
	_match_selector.clear_bet_requirement_marks()
	_refresh_global_continue_state()
	_match_simulation_service.advance_tick()


func _refresh_global_continue_state() -> void:
	var ready: bool = _all_matches_satisfied_this_cycle()
	_continue_button.disabled = not ready

	if _matches_with_tick_open_this_cycle.is_empty():
		_global_status_label.text = "Esperando inicio de jornada..."
		return

	if ready:
		_global_status_label.text = "✓ Apuesta registrada — puedes continuar o apostar en más partidos"
	else:
		_global_status_label.text = "Apuesta en al menos 1 partido para continuar"


## Regla de apuesta: basta con 1 apuesta en cualquier partido del tick actual.
## Apostar en más partidos es opcional y aumenta la exposición/ganancia potencial.
func _all_matches_satisfied_this_cycle() -> bool:
	if _matches_with_tick_open_this_cycle.is_empty():
		return false

	if _active_crazy_bet != null and not _crazy_bet_resolved_this_tick:
		return false

	for match_id in _matches_with_tick_open_this_cycle:
		var panel: MatchPanel = _match_panels.get(match_id, null)
		if panel != null and panel.has_bet_this_tick():
			return true

	return false


func _on_match_panel_bet_confirmed(match_id: StringName, market_offer: MarketOffer, stake: int, tick_index: int) -> void:
	var was_first_bet_ever: bool = not MetaProgress.has_completed_first_bet_tutorial()

	_pending_bets_tracker.register_bet(match_id, market_offer, stake, tick_index)
	_refresh_pending_bets_panel()

	# Regla de sincronización multi-partido (sección 3.4): si hay Crazy Bet activo y esta apuesta usó
	## el mercado/monto forzoso vigente, se marca resuelto para TODO el tick global -- los demás
	## partidos vuelven a exigir solo el stake mínimo normal.
	if _active_crazy_bet != null and not _crazy_bet_resolved_this_tick:
		if _active_crazy_bet.allowed_market_ids.has(market_offer.market_id) and stake >= _active_crazy_bet.forced_stake_amount:
			_crazy_bet_resolved_this_tick = true
			EventBus.crazy_moment_ended.emit()
			for panel in _match_panels.values():
				panel.mark_crazy_bet_resolved_elsewhere()

	if was_first_bet_ever:
		_tutorial_overlay.on_first_bet_confirmed()


## Feedback visual global (no gate de avance -- eso ya lo resuelve _all_matches_satisfied_this_cycle()):
## marca el tab de MatchSelector correspondiente para que el jugador vea, aunque tenga el foco puesto
## en OTRO partido, que este ya cumplió su apuesta obligatoria del tick vigente.
func _on_match_panel_tick_bet_requirement_satisfied(match_id: StringName) -> void:
	_match_selector.mark_bet_requirement_satisfied(match_id)
	_refresh_global_continue_state()


func _refresh_score_label(match_id: StringName, state: MatchTickState) -> void:
	var lbl: Label = _score_labels.get(match_id, null)
	if lbl == null:
		return
	var home: TeamDef = LeagueState.get_team(state.home_team_id)
	var away: TeamDef = LeagueState.get_team(state.away_team_id)
	var h: String = home.display_name if home != null else String(state.home_team_id)
	var a: String = away.display_name if away != null else String(state.away_team_id)
	var min_str: String = "pre" if state.current_minute == 0 else "min %d" % state.current_minute
	lbl.text = "%s  %d — %d  %s  (%s)" % [h, state.home_goals, state.away_goals, a, min_str]

	if state.home_goals > state.away_goals:
		lbl.add_theme_color_override("font_color", Color(0.067, 0.902, 0.392, 1))
	elif state.away_goals > state.home_goals:
		lbl.add_theme_color_override("font_color", Color(0.894, 0.271, 0.271, 1))
	else:
		lbl.add_theme_color_override("font_color", Color(0.780, 0.843, 0.910, 1.0))


## E.8 -- boleto vivo: un LiveBetTicket por PendingBet abierta (ya no un resumen plano de las últimas
## 4). Se reconstruye por completo en cada alta/baja de apuestas (pending_bets_changed vía
## _on_bet_tick_resolved/_on_match_panel_bet_confirmed); el estado vivo de cada ticket ya creado se
## refresca aparte en cada bet_tick_opened, ver _refresh_live_bet_tickets.
func _refresh_pending_bets_panel() -> void:
	for child in _pending_bets_panel.get_children():
		child.queue_free()
	_live_bet_tickets.clear()

	var pending: Array[PendingBet] = _pending_bets_tracker.get_pending_bets()
	if pending.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "Sin apuestas pendientes"
		_pending_bets_panel.add_child(empty_lbl)
		return

	var total: int = 0
	for bet in pending:
		total += bet.stake
	var summary := Label.new()
	summary.text = "%d apuesta%s · $%d en juego" % [pending.size(), "s" if pending.size() != 1 else "", total]
	_pending_bets_panel.add_child(summary)

	for bet in pending:
		var ticket: LiveBetTicket = LIVE_BET_TICKET_SCENE.instantiate()
		_pending_bets_panel.add_child(ticket)
		ticket.setup(bet, _match_label_for(bet.match_id))
		_live_bet_tickets.append(ticket)

	_refresh_live_bet_tickets()


## Consulta MatchSimulationService.get_match_tick_state(match_id) por cada ticket (ya expuesto, ver
## sección 3 de la spec E.8) y le pasa el estado actual del partido para recalcular estado vivo +
## cuánto falta para su resolución.
func _refresh_live_bet_tickets() -> void:
	for ticket in _live_bet_tickets:
		var match_state: MatchTickState = _match_simulation_service.get_match_tick_state(ticket.get_match_id())
		ticket.refresh_live_state(match_state)


func _match_label_for(match_id: StringName) -> String:
	var matchday_fixture: MatchdayFixture = LeagueState.get_current_matchday_fixture()
	if matchday_fixture == null:
		return String(match_id)
	for match_fixture in matchday_fixture.matches:
		if match_fixture.match_id == match_id:
			var home_team: TeamDef = LeagueState.get_team(match_fixture.home_team_id)
			var away_team: TeamDef = LeagueState.get_team(match_fixture.away_team_id)
			var h: String = home_team.display_name if home_team != null else String(match_fixture.home_team_id)
			var a: String = away_team.display_name if away_team != null else String(match_fixture.away_team_id)
			return "%s vs %s" % [h, a]
	return String(match_id)


## Consume PendingBetsTracker.bet_resolved (E.8, señal local a la UI de apuestas) y dispara el
## feedback enérgico de resolución -- dopamina alta y consistente en cualquier fase narrativa (sección
## 4 de la spec).
func _on_pending_bet_resolved(pending_bet: PendingBet, won: bool, payout: int) -> void:
	if won:
		var net: int = payout - pending_bet.stake
		_resolution_feedback_overlay.show_win(payout, net)
	else:
		_resolution_feedback_overlay.show_loss(pending_bet.stake)


func _current_matchday_id() -> StringName:
	var matchday_fixture: MatchdayFixture = LeagueState.get_current_matchday_fixture()
	if matchday_fixture == null:
		return &""
	return StringName("matchday_%d" % matchday_fixture.matchday_index)
