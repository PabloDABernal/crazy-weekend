class_name OddsDisclosureResolver extends RefCounted
## Capa de presentación/opacidad (D.5): aplica margen de casa sobre p_real y ensancha el rango
## visible, produciendo el MarketOffer final. Puro, sin estado.
## Ver .ai-studio/specs/epic-d-liga-y-partidos.md sección 5.2/5.3.


## Aplica margen de casa (nunca expuesto) sobre p_real, y calcula el rango visible ancho.
## displayed_probability_min/max SIEMPRE contienen el valor real ajustado por margen en algún punto
## interior del rango (nunca fuera de rango) para que el rango sea honesto aunque impreciso.
##
## Nota de implementación: la firma fijada por la spec (sección 5.2) no lista `day` ni `rng` como
## parámetros, pero la fórmula de texto que la misma sección fija sí depende de `day`
## ("SUNDAY_MULTIPLIER si day==SUNDAY") y compute_range_width necesita una fuente de aleatoriedad
## para la variación +/- (sección 5.2, ODDS_DISPLAY_RANGE_WIDTH_VARIATION). Se añaden ambos como
## parámetros explícitos en vez de ignorar la fórmula fijada o acceder a estado global oculto.
static func build_market_offer(market: MarketDef, option_key: String, p_real: float, house_margin: float,
		match_id: StringName, phase: NarrativePhase.Phase, day: BettingDay.Day, rng: RandomNumberGenerator) -> MarketOffer:
	var effective_margin: float = compute_effective_margin(house_margin, phase, day)
	var p_shown_center: float = clampf(p_real * (1.0 - effective_margin), 0.0, 1.0)

	var range_width: float = compute_range_width(market, phase, rng)
	var half_width: float = range_width * 0.5

	var range_min: float = clampf(p_shown_center - half_width, 0.0, 1.0)
	var range_max: float = clampf(p_shown_center + half_width, 0.0, 1.0)

	# Si el recorte a [0.0, 1.0] dejó a p_shown_center fuera del rango (extremos), se re-ancla el
	# límite correspondiente para que el centro siempre quede dentro (rango honesto, ver contrato).
	if p_shown_center < range_min:
		range_min = p_shown_center
	if p_shown_center > range_max:
		range_max = p_shown_center

	var offer := MarketOffer.new()
	offer.market_id = market.market_id
	offer.match_id = match_id
	offer.displayed_probability_min = range_min
	offer.displayed_probability_max = range_max
	offer.confidence = compute_confidence(market, phase, rng)
	offer.option_key = StringName(option_key)
	offer.threshold_display = market.threshold if _is_over_under(market.kind) else -1.0

	return offer


## Fórmula fijada en la spec sección 5.2:
## effective_margin = base_margin_por_mercado * (SUNDAY_MULTIPLIER si day==SUNDAY else 1.0) + phase_increment
static func compute_effective_margin(base_margin: float, phase: NarrativePhase.Phase, day: BettingDay.Day) -> float:
	var sunday_multiplier: float = LeagueRules.HOUSE_MARGIN_SUNDAY_MULTIPLIER if day == BettingDay.Day.SUNDAY else 1.0
	var phase_increment: float = LeagueRules.HOUSE_MARGIN_PHASE_INCREMENT[phase]
	return base_margin * sunday_multiplier + phase_increment


## Ancho del rango mostrado. Constante base + variación leve, NUNCA colapsa en esta épica (la
## investigación que estrecha el rango es una épica futura, fuera de alcance).
static func compute_range_width(_market: MarketDef, _phase: NarrativePhase.Phase, rng: RandomNumberGenerator) -> float:
	var variation: float = rng.randf_range(-LeagueRules.ODDS_DISPLAY_RANGE_WIDTH_VARIATION, LeagueRules.ODDS_DISPLAY_RANGE_WIDTH_VARIATION)
	return max(LeagueRules.ODDS_DISPLAY_RANGE_WIDTH_BASE + variation, 0.01)


## confidence = 1.0 - compute_range_width(market, phase) / ODDS_DISPLAY_RANGE_WIDTH_MAX_POSSIBLE
## En el MVP (sin investigación inter-run), varía solo por mercado y fase narrativa, no por progreso
## del jugador — ver sección 5.3 de la spec.
static func compute_confidence(market: MarketDef, phase: NarrativePhase.Phase, rng: RandomNumberGenerator) -> float:
	var range_width: float = compute_range_width(market, phase, rng)
	return clampf(1.0 - range_width / LeagueRules.ODDS_DISPLAY_RANGE_WIDTH_MAX_POSSIBLE, 0.0, 1.0)


static func _is_over_under(kind: MarketDef.MarketKind) -> bool:
	return kind == MarketDef.MarketKind.GOALS_OVER_UNDER or kind == MarketDef.MarketKind.CARDS_OVER_UNDER or kind == MarketDef.MarketKind.FOULS_OVER_UNDER
