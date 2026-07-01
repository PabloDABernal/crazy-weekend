class_name MatchTickEvent extends Resource
## Evento discreto ocurrido dentro de un tick de 15 minutos de un partido. Ver
## .ai-studio/specs/epic-d-liga-y-partidos.md sección 4.2.

enum EventKind { GOAL, CARD, SHOT_ON_TARGET, SHOT_OFF_TARGET, CORNER, FOUL, NO_EVENT }

@export var kind: EventKind
@export var team_id: StringName            # equipo que protagoniza el evento
@export var player_id: StringName          # "" si no aplica (ej. corner sin jugador destacado)
@export var minute: int                    # minuto exacto dentro del tick (current_minute anterior + 1..15)
