# META: 02-signal-and-the-ticker

- **Family**: modules
- **Shape**: write an abstract machine, a concrete machine, the refinement mapping between them and the config line that makes TLC check it, all from prose
- **Time estimate**: 10 to 12 min thinking, under 1 min of runs
- **Slowest run asked for**: any of the five, under 1 s
- **Shows TLA+ in the prompt**: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them.

- INSTANCE
- named instance
- ! (namespace lookup)
- INSTANCE ... WITH (<- constant substitution)
- VARIABLE / VARIABLES
- Init / Next / Spec (the pure-TLA+ spec skeleton)

## Inventory rows

K100, K102, K103, K104, K081, K083.

The K104 row is named for constant substitution. Here the substituted
symbol is the abstract module's variable, which is the refinement
mapping. Same keyword, same arrow.

## Also exercised, not declared

`PROPERTY` in the config (K064). Its inventory cell yields the token
`TLC`, and this prompt names TLC in prose, so declaring it would trip
the telegraph check on a word that gives nothing away. `THEOREM` has no
inventory row.

## Measured on

TLC2 Version 2026.07.31.184830, through `harness/verdict.sh` with one
config per run. The table is in `ANSWER.md`. Reproduce the answer with

```
cd verify && tlc -workers 1 -cleanup Ticker -config Refines.cfg
```

The `G02*` modules are thin wrappers, one per run the drill gate
reproduces. Each extends the module it stands for and carries a copy of
the config it is named after in `ANSWER.md`.
