# META: 08-the-database-you-did-not-need

- **Family**: state-space
- **Shape**: a growth curve, a knob that reports a false clean, and the answer is a different abstraction
- **Time estimate**: 10 min thinking, about 1 min of runs if the mechanism model is given, longer if written
- **Slowest run asked for**: `Mechanism5.cfg`, 7.1 s, rc 12
- **Shows TLA+ in the prompt**: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them.

- CONSTANT
- ASSUME
- set of model values
- Invariant (as a TLA+ operator, checked at every state)
- deadlock (checking)

## Inventory rows

K039, K040, K042, K034, K059.

## Keywords with no inventory row

Named as the `.cfg` keyword spells it.

- CONSTRAINT

## Measured on

TLC2 Version 2026.07.31.184830, `-workers 1`, one config per run. The
full table is in `ANSWER.md`. The 405,673,796 figure is cited from
`sources/README.md:110`, not reproduced. Reproduce the false clean with

```
cd verify && tlc -workers 1 -cleanup MCMVCC -config Mechanism3Ts4.cfg
```

and the 21 with

```
cd verify && tlc -workers 1 -cleanup OnCallOracle -config Oracle2.cfg
```

Don't run the mechanism at six doctors on a shared box. Five took 7.1 s
and 637,658 states, and the ratio to the oracle was doubling per size.

The `G08*` modules are thin wrappers, one per run the drill gate
reproduces. Each extends the module it names and carries a copy of the
config it is named after in `ANSWER.md`.
