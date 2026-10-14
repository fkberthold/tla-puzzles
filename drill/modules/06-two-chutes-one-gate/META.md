# META: 06-two-chutes-one-gate

- **Family**: modules
- **Shape**: write a module with an operator-valued constant and a spec that instantiates it twice, supplying each operator in place
- **Time estimate**: 10 min thinking, under 1 min of runs
- **Slowest run asked for**: any of the four, under 1 s
- **Shows TLA+ in the prompt**: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them.

- LAMBDA
- Higher-order operator parameter
- INSTANCE
- named instance
- ! (namespace lookup)
- INSTANCE ... WITH (<- constant substitution)
- CONSTANT
- Invariant (as a TLA+ operator, checked at every state)

## Inventory rows

K073, K072, K100, K102, K103, K104, K039, K034.

## Measured on

TLC2 Version 2026.07.31.184830, through `harness/verdict.sh` with one
config per run. The table is in `ANSWER.md`. Reproduce the answer with

```
cd verify && tlc -workers 1 -cleanup SortingLine -config Line.cfg
```

The `G06*` modules are thin wrappers, one per run the drill gate
reproduces. Each extends the module it stands for and carries a copy of
the config it is named after in `ANSWER.md`.
