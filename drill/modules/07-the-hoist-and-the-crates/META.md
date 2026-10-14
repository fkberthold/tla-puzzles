# META: 07-the-hoist-and-the-crates

- **Family**: modules
- **Shape**: write a spec whose invariant needs a recursive sum over a set, with the sum and its helper defined inside the operator that uses them
- **Time estimate**: 8 min thinking, under 1 min of runs
- **Slowest run asked for**: any of the five, under 1 s
- **Shows TLA+ in the prompt**: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them.

- RECURSIVE
- LET-IN
- Operator definition
- CHOOSE
- CONSTANT
- Invariant (as a TLA+ operator, checked at every state)

## Inventory rows

K071, K021, K001, K020, K039, K034.

This item carries no modules-family row. It's filed here because the
brief spread the recursive and higher-order definition forms across this
family's eight, and the hoist is where a recursive operator is forced
rather than decorative.

## Also exercised, not declared

The recursive function form in `HoistFn.tla` (K076). It's the variant,
not the answer.

## Measured on

TLC2 Version 2026.07.31.184830, through `harness/verdict.sh` with one
config per run. The table is in `ANSWER.md`. Reproduce the answer with

```
cd verify && tlc -workers 1 -cleanup Hoist -config Heavy.cfg
```

The `G07*` modules are thin wrappers, one per run the drill gate
reproduces. Each extends the module it stands for and carries a copy of
the config it is named after in `ANSWER.md`.
