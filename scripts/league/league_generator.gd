class_name LeagueGenerator extends RefCounted
## Lógica pura de D.1 — genera los 20 TeamDef (con plantillas de PlayerDef) y el calendario de 38
## jornadas (round-robin) de una temporada nueva. Invocada por LeagueState.generate_new_league().
## Ver .ai-studio/specs/epic-d-liga-y-partidos.md secciones 2.3 y 2.4.

# Nombres ficticios inspirados en LaLiga pero distorsionados (game-design.md -> "Liga ficticia").
# Lista fija de 20 para que la generación sea determinista dado el mismo rng_seed (el único
# componente aleatorio de D.1 es el orden inicial de equipos antes del round-robin y los atributos).
const TEAM_NAME_POOL: Array[String] = [
	"Real Madrileño", "FC Barceloneta", "Atlético de Madriz", "Seviya FC", "Valencia Naranja",
	"Real Betis Andaluz", "Villareal Amarillo", "Athletic de Bildao", "Real Sociedad Vasca",
	"Celta de Vig", "Deportivo Coruñes", "Español Perico", "Getafón CF", "Rayo Vallecano Obrero",
	"Osasuna Rojilla", "Girondés FC", "Mallorquín RCD", "Alavesón CD", "Cadista SC", "Elxense CF",
]

const POSITION_DISTRIBUTION: Dictionary = {
	PlayerDef.Position.GOALKEEPER: 2,
	PlayerDef.Position.DEFENDER: 6,
	PlayerDef.Position.MIDFIELDER: 6,
	PlayerDef.Position.FORWARD: 4,
}


## Genera los 20 equipos con sus plantillas. STAR_TEAM_COUNT equipos (elegidos por rng entre el pool
## barajado) se marcan is_star_team = true y muestrean offense/defense del rango alto.
static func generate_teams(rng: RandomNumberGenerator) -> Array[TeamDef]:
	var shuffled_indices: Array[int] = []
	for i in range(TEAM_NAME_POOL.size()):
		shuffled_indices.append(i)
	_shuffle_array(shuffled_indices, rng)

	var star_indices: Array[int] = shuffled_indices.slice(0, LeagueRules.STAR_TEAM_COUNT)

	var teams: Array[TeamDef] = []
	for i in range(TEAM_NAME_POOL.size()):
		var is_star: bool = star_indices.has(i)
		var team := TeamDef.new()
		team.team_id = _slugify(TEAM_NAME_POOL[i])
		team.display_name = TEAM_NAME_POOL[i]
		team.is_star_team = is_star

		var offense_defense_range: Vector2 = LeagueRules.OFFENSE_DEFENSE_RANGE_STAR if is_star else LeagueRules.OFFENSE_DEFENSE_RANGE_NORMAL
		team.offense = rng.randf_range(offense_defense_range.x, offense_defense_range.y)
		team.defense = rng.randf_range(offense_defense_range.x, offense_defense_range.y)

		# current_form inicial: ruido pequeño alrededor de 0.5, independiente de is_star_team.
		team.current_form = clampf(0.5 + rng.randf_range(-0.1, 0.1), 0.0, 1.0)

		# home_advantage: rango más estrecho, no correlacionado con is_star_team.
		team.home_advantage = rng.randf_range(0.05, 0.25)

		team.squad = generate_squad(team.team_id, rng)
		teams.append(team)

	return teams


## Genera una plantilla de LeagueRules.SQUAD_SIZE_PER_TEAM jugadores con distribución de posiciones fija.
static func generate_squad(team_id: StringName, rng: RandomNumberGenerator) -> Array[PlayerDef]:
	var squad: Array[PlayerDef] = []
	var player_index: int = 0
	for position in POSITION_DISTRIBUTION.keys():
		var count: int = POSITION_DISTRIBUTION[position]
		for _i in range(count):
			var player := PlayerDef.new()
			player.player_id = StringName("%s_p%d" % [team_id, player_index])
			player.display_name = "Jugador %d" % (player_index + 1)
			player.team_id = team_id
			player.position = position
			player.avg_goals_per_match = _generate_avg_goals(position, rng)
			player.card_probability = rng.randf_range(0.02, 0.15)
			squad.append(player)
			player_index += 1
	return squad


## FORWARD/MIDFIELDER tienen avg_goals_per_match más alto que DEFENDER/GOALKEEPER (usado por D.3 al
## atribuir goles a un jugador concreto, ponderado por este valor).
static func _generate_avg_goals(position: PlayerDef.Position, rng: RandomNumberGenerator) -> float:
	match position:
		PlayerDef.Position.FORWARD:
			return rng.randf_range(0.25, 0.55)
		PlayerDef.Position.MIDFIELDER:
			return rng.randf_range(0.05, 0.25)
		PlayerDef.Position.DEFENDER:
			return rng.randf_range(0.0, 0.05)
		_:
			return 0.0


## Algoritmo de round-robin estándar (círculo de rotación, 1 equipo fijo + resto rotando) para 38
## jornadas (19 ida + 19 vuelta) con 20 equipos, garantizando que cada equipo juega exactamente una
## vez por jornada. Ver .ai-studio/specs/epic-d-liga-y-partidos.md sección 2.3.
static func generate_calendar(teams: Array[TeamDef], season_number: int) -> Array[MatchdayFixture]:
	var team_ids: Array[StringName] = []
	for team in teams:
		team_ids.append(team.team_id)

	var team_count: int = team_ids.size()
	var rounds_first_leg: int = team_count - 1  # 19 jornadas de ida

	# Círculo de rotación: team_ids[0] queda fijo, el resto rota una posición por jornada.
	var rotating: Array[StringName] = team_ids.slice(1, team_count)

	var calendar: Array[MatchdayFixture] = []
	var matchday_index: int = 0

	for leg in range(2):  # 0 = ida, 1 = vuelta (equipos local/visitante invertidos)
		for round_number in range(rounds_first_leg):
			var round_teams: Array[StringName] = [team_ids[0]]
			round_teams.append_array(rotating)

			var matches: Array[MatchFixture] = []
			var half: int = team_count / 2
			for i in range(half):
				var team_a: StringName = round_teams[i]
				var team_b: StringName = round_teams[team_count - 1 - i]
				var home_id: StringName
				var away_id: StringName
				# Alterna local/visitante por ronda para repartir factor local, e invierte en la vuelta.
				if (round_number % 2 == 0) == (leg == 0):
					home_id = team_a
					away_id = team_b
				else:
					home_id = team_b
					away_id = team_a

				var match_fixture := MatchFixture.new()
				match_fixture.match_id = StringName("s%d_md%d_m%d" % [season_number, matchday_index, i])
				match_fixture.home_team_id = home_id
				match_fixture.away_team_id = away_id
				matches.append(match_fixture)

			var matchday := MatchdayFixture.new()
			matchday.matchday_index = matchday_index
			matchday.matches = matches
			calendar.append(matchday)

			matchday_index += 1
			# Rota: el último elemento pasa a ser el segundo (el primero de round_teams queda fijo).
			rotating.push_front(rotating.pop_back())

	return calendar


static func _shuffle_array(array: Array, rng: RandomNumberGenerator) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = array[i]
		array[i] = array[j]
		array[j] = tmp


static func _slugify(display_name: String) -> StringName:
	var slug: String = display_name.to_lower()
	slug = slug.replace(" ", "_")
	slug = slug.replace("á", "a").replace("é", "e").replace("í", "i").replace("ó", "o").replace("ú", "u")
	slug = slug.replace("ñ", "n")
	return StringName(slug)
