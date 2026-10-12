# META: 06-liveness-at-the-fence

- **Family**: state-space
- **Shape**: cold. Four verdicts on one system, and which to trust
- **Time estimate**: 10 min thinking, about 1 min of runs
- **Slowest run asked for**: `Unbounded.cfg`, killed by `timeout` at 30 s, rc 124
- **Shows TLA+ in the prompt**: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them.

- PROPERTY (TLC model config: register a temporal property)
- deadlock (checking)

## Inventory rows

K064, K059.

The fairness conjuncts the item turns on are K095 and K096, which the
inventory files under `temporal`. This item reads them and doesn't drill
them.

## Keywords with no inventory row

Named as the `.cfg` keyword spells it.

- CONSTRAINT

## Measured on

TLC2 Version 2026.07.31.184830, `-workers 1`, one config per run. The
full table is in `ANSWER.md`. Reproduce the clean-under-the-cut row with

```
cd verify && tlc -workers 1 -cleanup MCRetransmit -config Constraint.cfg
```

The `G06*` modules are thin wrappers, one per run the drill gate
reproduces. Each extends the module it names and carries a copy of the
config it is named after in `ANSWER.md`.
