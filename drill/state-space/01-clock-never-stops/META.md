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
