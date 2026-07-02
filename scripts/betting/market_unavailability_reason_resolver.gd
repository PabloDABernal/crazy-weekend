class_name MarketUnavailabilityReasonResolver extends RefCounted
## Deriva la razón breve (E.9) de por qué un mercado dejó de ofertarse este tick, a partir del
## market_id y el MatchTickState vivo del partido -- sin ampliar el contrato de BetTickContext (D.7
## no expone un motivo explícito). Ver .ai-studio/specs/story-e9-ui-mercados-dinamicos.md sección 3.1.
## Recomendación mínima de la spec: E deriva la razón por market_id + estado con un helper de texto.


static func resolve_reason(market_id: StringName, _state: MatchTickState) -> String:
	match String(market_id):
		"first_scorer":
			return "resuelto: ya hubo gol"
		"goals_ou_1_5", "goals_ou_2_5", "goals_ou_3_5":
			return "imposible con el marcador actual"
		"cards_ou":
			return "imposible con las tarjetas ya mostradas"
		"fouls_ou":
			return "imposible con las faltas ya mostradas"
		_:
			return "ya no disponible"
