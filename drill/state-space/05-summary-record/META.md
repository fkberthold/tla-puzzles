# META: 05-summary-record

- **Family**: state-space
- **Shape**: one record, four keywords, four measured outcomes, and the question of which one states anything
- **Time estimate**: 10 min thinking, under 1 min of runs
- **Slowest run asked for**: any of the nine, 0.4 s
- **Shows TLA+ in the prompt**: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them.

- Invariant (as a TLA+ operator, checked at every state)
- CONSTANT
- ASSUME
- model value
- symmetry set

## Inventory rows

K034, K039, K040, K041, K043.

The `PROPERTY` row (K064) is touched as a one-line wrong answer and not
drilled, so it isn't declared.

## Keywords with no inventory row

Named as the `.cfg` keyword spells them. The inventory has no row for
either, and this item is where the first gets drilled.

- ALIAS
- VIEW

## Measured on

TLC2 Version 2026.07.31.184830, `-workers 1`, one config per run. The
full table is in `ANSWER.md`. Reproduce the exit 75 with

```
cd verify && tlc -workers 1 -cleanup MCWarehouse -config InvariantRecord.cfg
```

The `G05*` modules are thin wrappers, one per run the drill gate
reproduces. Each extends `MCWarehouse` and carries a copy of the config
it is named after in `ANSWER.md`.
