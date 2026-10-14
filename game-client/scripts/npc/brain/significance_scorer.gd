## significance_scorer.gd
## Calculates the significance (0.0–1.0) of a memory event.
## Significance determines whether a memory is stored long-term and how fast it decays.
class_name SignificanceScorer

## ──────────────────────────────────────────────
##  Scoring Factors
## ──────────────────────────────────────────────

## Base significance from event type (0.0–1.0)
static func base_score(event_type: int) -> float:
	return MemoryEventType.get_base_significance(event_type)

## Emotional intensity modifier (0.0–1.0 → 0.0–0.3 boost)
static func emotional_modifier(event_type: int, details: Dictionary) -> float:
	var base_emotion := absf(MemoryEventType.get_base_emotional_weight(event_type))
	# If details contain explicit emotional context, blend
	if details.has("emotional_intensity"):
		var explicit := clamp(float(details["emotional_intensity"]), 0.0, 1.0)
		return (base_emotion + explicit) * 0.5 * 0.3
	return base_emotion * 0.3

## Relationship strength modifier (0.0–1.0 → 0.0–0.2 boost)
static func relationship_modifier(relationship_score: float) -> float:
	# Closer relationships make events more significant
	return clamp(relationship_score, 0.0, 1.0) * 0.2

## Recency/novelty modifier — first interaction with this entity is more significant
static func novelty_modifier(interaction_count: int) -> float:
	if interaction_count == 0:
		return 0.15  # First meeting
	elif interaction_count < 5:
		return 0.08  # Early interactions
	elif interaction_count < 20:
		return 0.03
	return 0.0  # Routine

## Context modifier — events in special locations or with witnesses
static func context_modifier(details: Dictionary) -> float:
	var mod := 0.0
	if details.has("witness_count") and int(details["witness_count"]) > 0:
		mod += 0.05  # Public events are more memorable
	if details.has("location_significance"):
		mod += clamp(float(details["location_significance"]), 0.0, 0.1)
	if details.has("monetary_value"):
		mod += clamp(float(details["monetary_value"]) / 10000.0, 0.0, 0.1)
	return mod

## ──────────────────────────────────────────────
##  Final Score
## ──────────────────────────────────────────────

## Calculate final significance score (0.0–1.0)
static func calculate(
	event_type: int,
	details: Dictionary,
	relationship_score: float = 0.0,
	interaction_count: int = 0
) -> float:
	var score := base_score(event_type)
	score += emotional_modifier(event_type, details)
	score += relationship_modifier(relationship_score)
	score += novelty_modifier(interaction_count)
	score += context_modifier(details)
	return clamp(score, 0.0, 1.0)

## Determine memory retention tier based on significance
## Returns: "flash" (< 0.2), "short_term" (0.2–0.5), "long_term" (0.5–0.8), "core" (> 0.8)
static func get_retention_tier(significance: float) -> String:
	if significance < 0.2:
		return "flash"
	elif significance < 0.5:
		return "short_term"
	elif significance < 0.8:
		return "long_term"
	return "core"
