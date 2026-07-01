class_name MarketDef extends Resource
## Definición de un mercado de apuesta del catálogo MVP (dato de diseño, editable en editor).
## Ver .ai-studio/specs/epic-d-liga-y-partidos.md sección 3.

enum MarketKind { MATCH_RESULT_1X2, GOALS_OVER_UNDER, FIRST_SCORER, BOTH_TEAMS_SCORE, CARDS_OVER_UNDER, FOULS_OVER_UNDER }

@export var market_id: StringName        # "1x2", "goals_ou_2_5", "goals_ou_1_5", "goals_ou_3_5",
                                          # "first_scorer", "btts", "cards_ou", "fouls_ou"
@export var kind: MarketKind
@export var threshold: float              # solo relevante para *_OVER_UNDER (1.5/2.5/3.5 goles, umbral de tarjetas/faltas)
@export var base_house_margin: float      # margen de casa base 0.0-1.0, ver sección 5.2
