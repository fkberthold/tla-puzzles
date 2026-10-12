# META: 03-view-hides-the-bug

- **Family**: state-space
- **Shape**: two clean verdicts, one false, with the counts that give it away
- **Time estimate**: 10 min thinking, about 1 min of runs
- **Slowest run asked for**: `AuditFixed.cfg`, killed by `timeout` at 30 s, rc 124
- **Shows TLA+ in the prompt**: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them.

- CONSTANT
- ASSUME
- Invariant (as a TLA+ operator, checked at every state)

## Inventory rows

K039, K040, K034.

## Keywords with no inventory row

Named as the `.cfg` keyword spells them. The inventory has no row for
either, and this item is where the first gets drilled.

- VIEW
- CONSTRAINT

## Measured on

TLC2 Version 2026.07.31.184830, `-workers 1`, one config per run. The
full table is in `ANSWER.md`. Reproduce the false clean with

```
cd verify && tlc -workers 1 -cleanup RetryHistory -config HistoryView.cfg
```

The `G03*` modules are thin wrappers, one per run the drill gate
reproduces. Each extends the module it names and carries a copy of the
config it is named after in `ANSWER.md`.
