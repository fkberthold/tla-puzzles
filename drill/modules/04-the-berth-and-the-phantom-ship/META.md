# META: 04-the-berth-and-the-phantom-ship

- **Family**: modules
- **Shape**: write a spec with a sentinel constant and the guard that keeps it out of the set, a model wrapper that extends it, and the configs that show the guard working and deleted
- **Time estimate**: 10 min thinking, under 1 min of runs
- **Slowest run asked for**: any of the six, under 1 s
- **Shows TLA+ in the prompt**: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them.

- ASSUME
- CONSTANT
- model value
- set of model values
- symmetry set
- EXTENDS (module import)
- Invariant (as a TLA+ operator, checked at every state)

## Inventory rows

K040, K039, K041, K042, K043, K004, K034.

## Measured on

TLC2 Version 2026.07.31.184830, through `harness/verdict.sh` with one
config per run. The table is in `ANSWER.md`. Reproduce the green-and-
wrong row with

```
cd verify && tlc -workers 1 -cleanup DockNoAssume -config PhantomNoAssume.cfg
```

One measurement here corrects a sentence in a sibling's answer.
`drill/state-space/07-sentinel-and-the-roster/ANSWER.md` says a config
can't put the sentinel model value in the set without the assumption
seeing it. With the assumption deleted it can, and the run is clean at 3
states. The sibling's measurement was of strings. This one is of model
values.

The `G04*` modules are thin wrappers, one per run the drill gate
reproduces. Each extends the module it stands for and carries a copy of
the config it is named after in `ANSWER.md`.
