# META: 02-four-identical-workers

- **Family**: state-space
- **Shape**: a measured growth curve, then which knob, its two conditions, and a wrong knob measured
- **Time estimate**: 10 min thinking, under 1 min of runs
- **Slowest run asked for**: `NoSym6.cfg`, 0.4 s, rc 0
- **Shows TLA+ in the prompt**: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them.

- symmetry set
- set of model values
- model value
- CONSTANT
- Invariant (as a TLA+ operator, checked at every state)
- PROPERTY (TLC model config: register a temporal property)

## Inventory rows

K043, K042, K041, K039, K034, K064.

## Keywords with no inventory row

Named as the `.cfg` keyword spells it.

- CONSTRAINT

## Measured on

TLC2 Version 2026.07.31.184830, `-workers 1`, one config per run. The
full table is in `ANSWER.md`. Reproduce any row with

```
cd verify && tlc -workers 1 -cleanup MCPool -config SymLastWorker.cfg
```

The `G02*` modules are thin wrappers, one per run the drill gate
reproduces. Each extends `MCPool` and carries a copy of the config it is
named after in `ANSWER.md`.
