class_name PayoutCalculator extends RefCounted
## Lógica pura de E.4 — calcula el dinero a pagar si una apuesta pendiente resulta ganadora.
## MarketBetResultBuilder (Épica D) no calcula payout: solo arma el contrato ganó/perdió + tags para
## Épica A. El payout se calcula a partir de la cuota implícita en el rango mostrado al jugador en el
## momento de apostar (cuota "congelada" al confirmar, no al resolver).
## Ver .ai-studio/specs/epic-e-pantalla-de-apuestas.md sección 4.4.
##
## Reexpresado sobre `OddsMath` (E.7, .ai-studio/specs/story-e7-cuota-ganancia-potencial.md sección 2)
## para que la cuota mostrada al apostar y la usada al pagar sean idénticas por construcción -- misma
## fórmula que antes de este refactor, ningún resultado cambia.


## Cuota mostrada al jugador en el momento de apostar = 1 / p_shown_center, usando el punto medio del
## rango mostrado (displayed_probability_min/max) como cuota "congelada" al momento de apostar.
static func compute_payout(pending_bet: PendingBet) -> int:
	var shown_center: float = (pending_bet.market_offer.displayed_probability_min + pending_bet.market_offer.displayed_probability_max) / 2.0
	var implied_odds: float = OddsMath.odds_from_probability(shown_center)
	return OddsMath.potential_return(pending_bet.stake, implied_odds)
