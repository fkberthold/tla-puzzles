# META: 07-sentinel-and-the-roster

- **Family**: state-space
- **Shape**: write the config from prose, then break each constant and read what TLC does
- **Time estimate**: 10 min thinking, under 1 min of runs
- **Slowest run asked for**: any of the eleven, 0.4 s
- **Shows TLA+ in the prompt**: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them.

- CONSTANT
- ASSUME
- model value
- set of model values
- symmetry set
- Invariant (as a TLA+ operator, checked at every state)

## Inventory rows

K039, K040, K041, K042, K043, K034.

## Measured on

TLC2 Version 2026.07.31.184830, `-workers 1`, one config per run. The
full table is in `ANSWER.md`. Reproduce the green-and-wrong row with

```
cd verify && tlc -workers 1 -cleanup RosterNoAssume -config CollidesNoAssume.cfg
```

One measurement here disagrees with the brief this item was written
under, which said a model value compared against a string exits 255.
On this build it exits 0 (`SentinelString.cfg`, `SentinelNumber.cfg`).
The 255 I could produce is `SYMMETRY` over strings.

The `G07*` modules are thin wrappers, one per run the drill gate
reproduces. Each extends the module it names and carries a copy of the
config it is named after in `ANSWER.md`.
