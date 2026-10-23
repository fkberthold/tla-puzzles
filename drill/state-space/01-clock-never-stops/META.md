# META: 01-clock-never-stops

- **Family**: state-space
- **Shape**: a measured growth curve, then which knob and why
- **Time estimate**: 10 min thinking, about 2 min of runs
- **Slowest run asked for**: `Unbounded.cfg`, killed by `timeout` at 30 s, rc 124
- **Shows TLA+ in the prompt**: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them.

- CONSTANT
- ASSUME
- Invariant (as a TLA+ operator, checked at every state)
- deadlock (checking)

## Inventory rows

K039, K040, K034, K059.

## Keywords with no inventory row

Named as the `.cfg` keyword spells them. The inventory has no row for
either, and this item is where they get drilled.

- CONSTRAINT
- ACTION_CONSTRAINT

## Measured on

TLC2 Version 2026.07.31.184830, `-workers 1`, one config per run. The
full table is in `ANSWER.md`. Reproduce any row with

```
cd verify && tlc -workers 1 -cleanup MCHeartbeat -config Constraint12.cfg
```

The `G01*` modules are thin wrappers, one per run the drill gate
reproduces. Each extends the module it names and carries a copy of the
config it is named after in `ANSWER.md`.

## Parameters the prompt states

Added 2026-10-23 under bead `tla-sfgm`. The published counts are a
function of all three, so the prompt names them rather than leaving a
reader to guess.

- `Timeout = 2`
- one standby, one variable over two values
- deadlock checking off in the five capped runs

The third one is the one to think twice about before touching. Leave it
out and the spec-side route at cap 12 gives 217 and rc 11 against the
published 237. Half the readers would hit a count mismatch that isn't
theirs, which is the defect the bead was filed for.

`G01CapDeadlock` and `G01CutDeadlock` are the gated control pair for that
rc 11 against rc 0, added the same day. They differ in where the cap
lives and in nothing else, so the opposite verdicts are about that alone.
Both cfgs write `CHECK_DEADLOCK TRUE`, which is what makes the gate ask
for the check, and `ANSWER.md` says what happens to the row without it.
