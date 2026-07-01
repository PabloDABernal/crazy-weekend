class_name StatsPanel extends Control
## Sub-panel de MatchPanel: estadísticas acumuladas de un partido (posesión, tiros, tarjetas,
## corners, faltas). Corners es solo estadística de panel, no genera mercado (ver decisión 6 de
## epic-d-liga-y-partidos.md).
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 3.1.

@onready var _possession_bar: ProgressBar = $PossessionBar
@onready var _shots_on_target_label: Label = $ShotsOnTargetLabel
@onready var _cards_label: Label = $CardsLabel
@onready var _corners_label: Label = $CornersLabel
@onready var _fouls_label: Label = $FoulsLabel


func refresh(state: MatchTickState) -> void:
	if state == null:
		return
	_possession_bar.value = state.possession_home_pct
	_shots_on_target_label.text = "Tiros a puerta: %d - %d" % [state.shots_on_target_home, state.shots_on_target_away]
	_cards_label.text = "Tarjetas: %d - %d" % [state.cards_home, state.cards_away]
	_corners_label.text = "Corners: %d - %d" % [state.corners_home, state.corners_away]
	_fouls_label.text = "Faltas: %d - %d" % [state.fouls_home, state.fouls_away]
