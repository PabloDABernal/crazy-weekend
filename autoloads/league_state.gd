extends Node
## LeagueState (autoload) — fuente de verdad de la liga: equipos, jugadores, calendario de 38
## jornadas, standings, estadísticas de jugador acumuladas. Persiste en su propio archivo
## (user://save_league.tres), independiente de user://save_meta.tres.
## Ver .ai-studio/specs/epic-d-liga-y-partidos.md sección 2.
##
## Nota de integración con MatchSimulationService: la spec (sección 8, diagrama de secuencia)
## simplifica el disparo de apply_matchday_results como "vía suscripción" a EventBus.matchday_finished,
## pero esa señal solo lleva matchday_index (sección 9), no los Array[MatchResult] que
## apply_matchday_results necesita (sección 2, firma explícita). Se sigue el contrato de firma
## explícito: MatchSimulationService llama apply_matchday_results(results) directamente cuando
## is_matchday_finished() == true, y por separado emite EventBus.matchday_finished(matchday_index)
## para el resto de sistemas (UI). LeagueState no se suscribe a esa señal para evitar depender de un
## payload que no la lleva.

const SAVE_PATH: String = "user://save_league.tres"

var teams: Array[TeamDef] = []
var calendar: Array[MatchdayFixture] = []
var standings: Dictionary = {}                  # team_id (StringName) -> TeamStandingEntry
var current_matchday_index: int = 0             # 0-based, 0-37
var current_season_number: int = 1              # se incrementa al regenerar liga tras jornada 38

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()


## D.1: genera 20 TeamDef + plantillas de PlayerDef + calendario de 38 jornadas. Llamado al inicio
## de una campaña nueva y al completar la jornada 38 (nueva temporada).
func generate_new_league(season_number: int, rng_seed: int) -> void:
	_rng.seed = rng_seed
	current_season_number = season_number
	current_matchday_index = 0

	teams = LeagueGenerator.generate_teams(_rng)
	calendar = LeagueGenerator.generate_calendar(teams, season_number)

	standings = {}
	for team in teams:
		var entry := TeamStandingEntry.new()
		entry.team_id = team.team_id
		standings[team.team_id] = entry


func get_current_matchday_fixture() -> MatchdayFixture:
	if current_matchday_index < 0 or current_matchday_index >= calendar.size():
		return null
	return calendar[current_matchday_index]


func get_team(team_id: StringName) -> TeamDef:
	for team in teams:
		if team.team_id == team_id:
			return team
	return null


func get_standing(team_id: StringName) -> TeamStandingEntry:
	return standings.get(team_id, null)


## D.2: llamado por MatchSimulationService cuando is_matchday_finished() == true. Actualiza standings
## (puntos/GF/GC/forma) y estadísticas de jugador, avanza current_matchday_index, y dispara
## regeneración de liga si current_matchday_index supera 37 (nueva temporada).
func apply_matchday_results(results: Array[MatchResult]) -> void:
	for result in results:
		_apply_single_match_result(result)

	current_matchday_index += 1
	if current_matchday_index > LeagueRules.TOTAL_MATCHDAYS - 1:
		generate_new_league(current_season_number + 1, _rng.randi())


func _apply_single_match_result(result: MatchResult) -> void:
	var home_standing: TeamStandingEntry = get_standing(result.home_team_id)
	var away_standing: TeamStandingEntry = get_standing(result.away_team_id)
	if home_standing == null or away_standing == null:
		return

	home_standing.matches_played += 1
	away_standing.matches_played += 1
	home_standing.goals_for += result.home_goals
	home_standing.goals_against += result.away_goals
	away_standing.goals_for += result.away_goals
	away_standing.goals_against += result.home_goals

	var home_result: int
	var away_result: int
	if result.home_goals > result.away_goals:
		home_result = 3
		away_result = 0
	elif result.home_goals < result.away_goals:
		home_result = 0
		away_result = 3
	else:
		home_result = 1
		away_result = 1

	home_standing.points += home_result
	away_standing.points += away_result

	_push_last_5_result(home_standing, home_result)
	_push_last_5_result(away_standing, away_result)

	var home_team: TeamDef = get_team(result.home_team_id)
	var away_team: TeamDef = get_team(result.away_team_id)
	if home_team != null:
		home_team.current_form = _compute_current_form(home_standing)
	if away_team != null:
		away_team.current_form = _compute_current_form(away_standing)

	_apply_player_stats(result)


## last_5_results: cola FIFO de tamaño máximo 5 (append + pop_front si size() > 5).
func _push_last_5_result(standing: TeamStandingEntry, match_result: int) -> void:
	standing.last_5_results.append(match_result)
	if standing.last_5_results.size() > 5:
		standing.last_5_results.pop_front()


## current_form: promedio normalizado (0.0-1.0) de last_5_results. 3=victoria, 1=empate, 0=derrota;
## el máximo posible por resultado es 3, así que se normaliza dividiendo por 3.
func _compute_current_form(standing: TeamStandingEntry) -> float:
	if standing.last_5_results.is_empty():
		return 0.5
	var total: int = 0
	for match_result in standing.last_5_results:
		total += match_result
	var average: float = float(total) / float(standing.last_5_results.size())
	return clampf(average / 3.0, 0.0, 1.0)


func _apply_player_stats(result: MatchResult) -> void:
	for player_id in result.goal_scorers:
		var player: PlayerDef = _find_player(player_id)
		if player != null:
			player.season_goals += 1

	for player_id in result.carded_player_ids:
		var player: PlayerDef = _find_player(player_id)
		if player != null:
			player.season_cards += 1

	for team_id in [result.home_team_id, result.away_team_id]:
		var team: TeamDef = get_team(team_id)
		if team == null:
			continue
		for player in team.squad:
			player.season_matches_played += 1


func _find_player(player_id: StringName) -> PlayerDef:
	for team in teams:
		for player in team.squad:
			if player.player_id == player_id:
				return player
	return null


func save() -> void:
	var save_data := LeagueSaveData.new()
	save_data.teams = teams.duplicate()
	save_data.calendar = calendar.duplicate()
	save_data.standings = standings.duplicate()
	save_data.current_matchday_index = current_matchday_index
	save_data.current_season_number = current_season_number
	var error := ResourceSaver.save(save_data, SAVE_PATH)
	if error != OK:
		push_error("LeagueState.save() failed with error code %d" % error)


## Llamado una vez al boot; si no existe save_league.tres, llama generate_new_league().
func load_or_create() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		var loaded: Resource = ResourceLoader.load(SAVE_PATH)
		if loaded is LeagueSaveData:
			var save_data: LeagueSaveData = loaded
			teams = save_data.teams.duplicate()
			calendar = save_data.calendar.duplicate()
			standings = save_data.standings.duplicate()
			current_matchday_index = save_data.current_matchday_index
			current_season_number = save_data.current_season_number
			return
	# No existe save previo o el recurso encontrado no es válido: liga nueva.
	generate_new_league(1, _rng.randi())
