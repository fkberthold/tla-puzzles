# META: 01-two-tanks-one-hose

- **Family**: modules
- **Shape**: write a reusable one-variable module and a composite that instantiates it twice under two names, substituting a constant and a variable in each
- **Time estimate**: 10 min thinking, under 1 min of runs
- **Slowest run asked for**: any of the six, under 1 s
- **Shows TLA+ in the prompt**: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them.

- INSTANCE
- named instance
- ! (namespace lookup)
- INSTANCE ... WITH (<- constant substitution)
- CONSTANT
- VARIABLE / VARIABLES
- Invariant (as a TLA+ operator, checked at every state)

## Inventory rows

K100, K102, K103, K104, K039, K081, K034.

The K104 row is named for constant substitution. The same keyword
substitutes the tank's variable here, and that half is the one the
item is really about.

## Measured on

TLC2 Version 2026.07.31.184830, through `harness/verdict.sh` with one
config per run. The table is in `ANSWER.md`. Reproduce the answer with

```
cd verify && tlc -workers 1 -cleanup TankPair -config Pair.cfg
```

The `G01*` modules are thin wrappers, one per run the drill gate
reproduces. Each extends the module it stands for and carries a copy of
the config it is named after in `ANSWER.md`.
