class_name MarketOptionLabels extends Resource
## Contenido de presentación puro: traduce option_key (StringName) de los mercados MVP a texto
## legible en pantalla. No aplica a "first_scorer" (option_key es un player_id, resuelto por
## MatchWidget consultando LeagueState/PlayerDef.display_name en vez de este diccionario estático).
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 3.3.

## labels_by_option_key: { option_key (String) -> texto legible (String) }
@export var labels_by_option_key: Dictionary = {}


func get_label(option_key: StringName) -> String:
	return labels_by_option_key.get(String(option_key), String(option_key))
