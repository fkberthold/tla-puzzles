# Overnight run, 2026-09-06

Frank set this loose after the second direction change. Bead `tla-frpu`, drawer
`drawer_tla_puzzles_decisions_b7a27607e6ff319cbc6efb1c`.

Brief, verbatim: source from documented failures and prose behavioural specs, own
systems allowed but not prioritised, see what you can get.

## Order of work

1. Survey the source families. This is the instrument, and it is first because
   skipping it is what produced two wrong directions in two days.
2. Build a candidate table with a shared shape vocabulary.
3. Spike a small number. Measure difficulty rather than predicting it.
4. Statement from the source alone, never seeing the spike.
5. Consistency check across source, spike and statement.
6. Deliver, capture, push.

Build a few properly rather than many at once. The last two directions both failed
after building ahead of the check.

## Shape vocabulary

Every candidate gets one of these, so results from different surveys compare.

- `lifecycle` an entity moves through states, some transitions forbidden
- `two-store` two places hold related data that must agree
- `delivery` at-least-once, at-most-once, ordering, deduplication
- `expiry` leases, TTLs, timeouts, anything whose validity depends on a clock
- `rollout` versioned config or code moving across a fleet
- `concurrency` interleaved operations over shared state
- `resource` quota, rate limit, capacity, allocation
- `workflow` multi-step operation with compensation or rollback

## Recovery

Everything lands under this directory as it happens. If the session dies, the
survey files and the spike outputs survive and the drawer carries the decisions.
