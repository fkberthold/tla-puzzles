# META: 04-clean-run-colleague-deadlock

- **Family**: state-space
- **Shape**: two verdicts on identical files, then a six-cell table and a judgment call
- **Time estimate**: 10 min thinking, under 1 min of runs
- **Slowest run asked for**: any of the ten, 0.4 s
- **Shows TLA+ in the prompt**: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them.

- deadlock (checking)
- CONSTANT
- ASSUME
- set of model values
- model value
- Invariant (as a TLA+ operator, checked at every state)

## Inventory rows

K059, K039, K040, K042, K041, K034.

The `Terminating` disjunct in question 3 is K092, which the inventory
files under `pluscal` on purpose. This item uses it in raw TLA+ and
doesn't drill it.

## Measured on

TLC2 Version 2026.07.31.184830, `-workers 1`, one config per run. The
six-cell table is in `ANSWER.md`. Reproduce the hazard row with

```
cd verify && tlc -workers 1 -cleanup -deadlock MCLocks -config OppositeTrue.cfg
```

and the colleague's row by dropping `-deadlock`.

The `G04*` modules are thin wrappers, one per run the drill gate
reproduces through `harness/verdict.sh`. That channel passes `-deadlock`
on every run, so the rc it records for each wrapper is the rc under that
flag, which is the item's own subject. See the gate table in `ANSWER.md`.
