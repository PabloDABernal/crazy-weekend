class_name TickCommentaryContext extends Resource
## Contrato de datos de entrada para D.4 (comentarios). No es copy narrativo — solo transporta los
## datos que CommentaryResolver necesita para elegir/resolver plantillas.
## Ver .ai-studio/specs/epic-d-liga-y-partidos.md sección 7.

@export var match_id: StringName
@export var tick_index_in_day: int
@export var phase: NarrativePhase.Phase          # tono a aplicar, ya resuelto por NarrativePhase.get_current_phase()
@export var is_crazy_moment: bool                # true si EventBus.crazy_moment_triggered está activo este tick (ver Épica B.3)
@export var events: Array[MatchTickEvent] = []    # copia de MatchTickState.tick_events de este tick (sección 4.2)
@export var score_home: int
@export var score_away: int
@export var home_team_display_name: String
@export var away_team_display_name: String
