class_name ScoreboardPanel extends Control
## Sub-panel de MatchPanel: marcador y minuto actual de un partido. Solo presentación, sin lógica de
## simulación propia -- consume MatchTickState ya resuelto por MatchSimulationService (Épica D).
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 3.1.

@onready var _home_team_label: Label = $HomeTeamLabel
@onready var _away_team_label: Label = $AwayTeamLabel
@onready var _score_label: Label = $ScoreLabel
@onready var _minute_label: Label = $MinuteLabel


func refresh(state: MatchTickState, home_team: TeamDef, away_team: TeamDef) -> void:
	if state == null:
		return
	_home_team_label.text = home_team.display_name if home_team != null else String(state.home_team_id)
	_away_team_label.text = away_team.display_name if away_team != null else String(state.away_team_id)
	_score_label.text = "%d - %d" % [state.home_goals, state.away_goals]
	_minute_label.text = "min %d" % state.current_minute
