class_name OddsMath extends RefCounted
## Fuente única de verdad de la aritmética de cuota/payout comercial. Consumida por E.7 (UI de
## cuota/ganancia potencial), `PayoutCalculator` (pago real) y E.8 (boleto vivo) para no duplicar la
## conversión probabilidad -> cuota en varios sitios. Ver
## .ai-studio/specs/story-e7-cuota-ganancia-potencial.md sección 2.

const MIN_P: float = 0.01   # mismo sentinel que ya usaba PayoutCalculator antes de este refactor.


## Cuota comercial a partir de una probabilidad mostrada (ya incluye margen de casa, ver
## epic-d §5.2). = 1 / max(p, MIN_P).
static func odds_from_probability(shown_probability: float) -> float:
	return 1.0 / max(shown_probability, MIN_P)


## Cuota como rango (a partir del rango de probabilidad mostrado). Menor probabilidad implica mayor
## cuota, por eso el mínimo de cuota se deriva del máximo de probabilidad y viceversa.
static func odds_range_from_probability_range(p_min: float, p_max: float) -> Vector2:
	var odds_from_p_min: float = odds_from_probability(p_min)
	var odds_from_p_max: float = odds_from_probability(p_max)
	return Vector2(min(odds_from_p_min, odds_from_p_max), max(odds_from_p_min, odds_from_p_max))


## Cuota "congelada" de una oferta de mercado (misma fórmula usada para pagar y para mostrar):
## 1 / punto medio del rango de probabilidad mostrado. Fuente única para `PayoutCalculator` y
## `LiveBetTicket` -- evita que la cuota mostrada en el boleto y la usada al pagar diverjan.
static func frozen_odds_for_offer(offer: MarketOffer) -> float:
	var shown_center: float = (offer.displayed_probability_min + offer.displayed_probability_max) / 2.0
	return odds_from_probability(shown_center)


## Ganancia potencial (devolución total, stake incluido) de un stake a una cuota dada.
static func potential_return(stake: int, odds: float) -> int:
	return int(ceil(stake * odds))


## Ganancia potencial neta (devolución total menos el stake apostado).
static func potential_net(stake: int, odds: float) -> int:
	return potential_return(stake, odds) - stake
