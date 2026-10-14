# META: 03-the-bank-that-vouched

- **Family**: modules
- **Shape**: write a guarded library and a client that instantiates it, then find where the guard went and restate it
- **Time estimate**: 10 min thinking, under 1 min of runs
- **Slowest run asked for**: any of the six, under 1 s
- **Shows TLA+ in the prompt**: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them.

- ASSUME
- INSTANCE
- named instance
- ! (namespace lookup)
- INSTANCE ... WITH (<- constant substitution)
- EXTENDS (module import)
- CONSTANT

## Inventory rows

K040, K100, K102, K103, K104, K004, K039.

## Measured on

TLC2 Version 2026.07.31.184830, through `harness/verdict.sh` with one
config per run. The table is in `ANSWER.md`. Reproduce the silent row
with

```
cd verify && tlc -workers 1 -cleanup PostOffice -config OfficeZero.cfg
```

and the loud one with

```
cd verify && tlc -workers 1 -cleanup LockerBank -config BankZero.cfg
```

One measurement here is the item. An assumption in an instantiated
module is not checked by TLC on this build, whether the constant is
substituted or passed through. The same assumption fires when the module
is extended. I found no statement of that rule in the TLC docs, so the
rule is my reading of the runs and the runs are what's recorded.

The `G03*` modules are thin wrappers, one per run the drill gate
reproduces. Each extends the module it stands for and carries a copy of
the config it is named after in `ANSWER.md`.
