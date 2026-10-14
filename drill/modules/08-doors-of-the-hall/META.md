# META: 08-doors-of-the-hall

- **Family**: modules
- **Shape**: write a shared one-constant module and a spec that instantiates it once per element of a set, with the constant bound by the quantifier
- **Time estimate**: 7 min thinking, under 1 min of runs
- **Slowest run asked for**: any of the four, under 1 s
- **Shows TLA+ in the prompt**: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them.

- partial parameterization
- INSTANCE ... WITH (<- constant substitution)
- ! (namespace lookup)
- CONSTANT
- Invariant (as a TLA+ operator, checked at every state)

## Inventory rows

K105, K104, K103, K039, K034.

## Measured on

TLC2 Version 2026.07.31.184830, through `harness/verdict.sh` with one config
per run. The table is in `ANSWER.md`. Reproduce the answer with

```
cd verify && tlc -workers 1 -cleanup Hall -config Narrow.cfg
```

The `G08*` modules are thin wrappers, one per run the drill gate
reproduces. Each extends the module it stands for and carries a copy of
the config it is named after in `ANSWER.md`.
