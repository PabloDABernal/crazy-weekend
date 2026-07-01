class_name CrazyBetResolver extends RefCounted
## Lógica pura de B.3 — cálculo del stake forzoso (50/70/100% del dinero actual, con pesos por fase)
## y selección de qué mercados quedan disponibles durante el tick marcado como Crazy.
## Ver .ai-studio/specs/epic-b-economia-de-run.md sección B.3.


## Elige el porcentaje forzoso según los pesos de la fase narrativa actual.
static func roll_stake_percentage(phase: NarrativePhase.Phase, rng: RandomNumberGenerator) -> CrazyBetContext.StakePercentage:
	var weights: Dictionary = EconomyRules.CRAZY_BET_WEIGHTS_BY_PHASE[phase]
	var total_weight: int = 0
	for weight in weights.values():
		total_weight += weight

	var roll: float = rng.randf() * float(total_weight)
	var cumulative: float = 0.0
	# Orden fijo y determinista de recorrido, derivado (no duplicado) de las keys de la tabla de
	# pesos de EconomyRules, y ordenado explícitamente para no depender del orden de inserción del Dictionary.
	var ordered_percentages: Array = weights.keys()
	ordered_percentages.sort()
	for percentage in ordered_percentages:
		cumulative += float(weights[percentage])
		if roll < cumulative:
			return percentage as CrazyBetContext.StakePercentage

	# Fallback numérico por seguridad ante errores de coma flotante: último valor de la tabla.
	return ordered_percentages[-1] as CrazyBetContext.StakePercentage


## Calcula el monto absoluto forzoso. Redondeo hacia arriba (ceil) al entero de dinero más cercano,
## para que nunca se pida "menos" del porcentaje anunciado por redondeo hacia abajo.
static func compute_forced_amount(current_money: int, percentage: CrazyBetContext.StakePercentage) -> int:
	var raw_amount: float = float(current_money) * float(percentage) / 100.0
	return int(ceil(raw_amount))


## Selecciona 1-2 mercados disponibles excluyendo siempre el de mayor confidence.
## Si hay empate de mayor confidence, se excluyen todos los empatados si al hacerlo sigue quedando
## al menos 1 mercado disponible; si excluir todos los empatados deja 0 mercados, se excluye solo
## uno de ellos (elegido por rng) para garantizar CRAZY_BET_MIN_ALLOWED_MARKETS.
static func select_restricted_markets(available: Array[MarketOffer], rng: RandomNumberGenerator) -> Dictionary:
	# Precondición: siempre hay al menos un mercado disponible en un tick (el sistema de partidos,
	# fuera de alcance de Épica B, garantiza esto). Sin al menos un mercado no hay tick de apuesta
	# que ofrecer, y esta función no tiene forma válida de garantizar CRAZY_BET_MIN_ALLOWED_MARKETS
	# a partir de una lista vacía.
	assert(not available.is_empty(), "select_restricted_markets requiere al menos un MarketOffer disponible")

	var highest_confidence: float = -1.0
	for market in available:
		if market.confidence > highest_confidence:
			highest_confidence = market.confidence

	var tied_for_highest: Array[MarketOffer] = []
	for market in available:
		if is_equal_approx(market.confidence, highest_confidence):
			tied_for_highest.append(market)

	var excluded_markets: Array[MarketOffer] = []
	var remaining_after_exclusion: int = available.size() - tied_for_highest.size()

	if remaining_after_exclusion >= EconomyRules.CRAZY_BET_MIN_ALLOWED_MARKETS:
		excluded_markets = tied_for_highest
	else:
		# Excluir a todos los empatados dejaría 0 (o menos del mínimo) mercados disponibles:
		# se excluye solo uno de ellos, elegido por rng.
		var random_index: int = rng.randi_range(0, tied_for_highest.size() - 1)
		excluded_markets = [tied_for_highest[random_index]]

	var excluded_ids: Array[StringName] = []
	for market in excluded_markets:
		excluded_ids.append(market.market_id)

	var allowed: Array[StringName] = []
	for market in available:
		if not excluded_ids.has(market.market_id):
			allowed.append(market.market_id)
			if allowed.size() >= EconomyRules.CRAZY_BET_MAX_ALLOWED_MARKETS:
				break

	return {
		"allowed": allowed,
		"excluded": excluded_ids[0] if excluded_ids.size() > 0 else &"",
	}


## Punto de entrada único: arma el CrazyBetContext completo para el tick actual.
static func build_context(current_money: int, phase: NarrativePhase.Phase, available_markets: Array[MarketOffer], rng: RandomNumberGenerator) -> CrazyBetContext:
	var percentage: CrazyBetContext.StakePercentage = roll_stake_percentage(phase, rng)
	var forced_amount: int = compute_forced_amount(current_money, percentage)
	var market_selection: Dictionary = select_restricted_markets(available_markets, rng)

	var context := CrazyBetContext.new()
	context.stake_percentage = percentage
	context.forced_stake_amount = forced_amount
	context.allowed_market_ids = market_selection["allowed"]
	context.excluded_market_id = market_selection["excluded"]
	return context
