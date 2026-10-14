## memory_decay.gd
## Handles memory decay and forgetting. Memories lose strength over time;
## low-significance memories fade faster. Core memories persist indefinitely.
class_name MemoryDecay

## ──────────────────────────────────────────────
##  Decay Configuration
## ──────────────────────────────────────────────

## Base decay rate per in-game hour (before significance modifier)
const BASE_DECAY_PER_HOUR := 0.01

## Retention tier multipliers — higher tier = slower decay
const TIER_MULTIPLIERS := {
	"flash": 8.0,       # Fades 8x faster
	"short_term": 3.0,  # Fades 3x faster
	"long_term": 1.0,   # Normal rate
	"core": 0.1,        # Near-permanent
}

## Minimum strength before a memory is eligible for pruning
const PRUNE_THRESHOLD := 0.05

## ──────────────────────────────────────────────
##  Decay Calculation
## ──────────────────────────────────────────────

## Calculate decay for a memory over a given time period.
## significance: 0.0–1.0 (higher = slower decay)
## tier: retention tier string
## hours_elapsed: in-game hours since memory was created/last accessed
## returns: new strength value (0.0–1.0)
static func calculate_decay(
	current_strength: float,
	significance: float,
	tier: String,
	hours_elapsed: float
) -> float:
	var tier_mult: float = TIER_MULTIPLIERS.get(tier, 1.0)
	# Significance reduces decay — high significance memories decay slower
	var sig_factor := 1.0 - (significance * 0.5)
	var decay_amount := BASE_DECAY_PER_HOUR * tier_mult * sig_factor * hours_elapsed
	return clamp(current_strength - decay_amount, 0.0, 1.0)

## Check if a memory should be pruned (forgotten entirely)
static func should_prune(strength: float) -> bool:
	return strength <= PRUNE_THRESHOLD

## ──────────────────────────────────────────────
##  Reinforcement
## ──────────────────────────────────────────────

## When a memory is recalled or a similar event recurs, reinforce it.
## returns: new strength value
static func reinforce(current_strength: float, significance: float) -> float:
	# Reinforcement adds back a fraction of significance
	var boost := significance * 0.15
	return clamp(current_strength + boost, 0.0, 1.0)

## ──────────────────────────────────────────────
##  Batch Processing
## ──────────────────────────────────────────────

## Process decay for a list of memories. Returns list of memory IDs to prune.
## memories: Array of Dictionaries with keys: id, strength, significance, tier, last_accessed_game_time
## current_game_time: current game time in seconds
static func process_batch(memories: Array, current_game_time: float) -> PackedStringArray:
	var to_prune: PackedStringArray = []
	var hours_per_sec := 1.0 / 3600.0
	
	for memory in memories:
		var last_accessed: float = memory.get("last_accessed_game_time", current_game_time)
		var hours_elapsed := (current_game_time - last_accessed) * hours_per_sec
		if hours_elapsed <= 0.0:
			continue
		
		var new_strength := calculate_decay(
			memory.get("strength", 1.0),
			memory.get("significance", 0.5),
			memory.get("tier", "short_term"),
			hours_elapsed
		)
		memory["strength"] = new_strength
		memory["last_accessed_game_time"] = current_game_time
		
		if should_prune(new_strength):
			to_prune.append(memory.get("id", ""))
	
	return to_prune
