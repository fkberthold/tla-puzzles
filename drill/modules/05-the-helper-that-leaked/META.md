# META: 05-the-helper-that-leaked

- **Family**: modules
- **Shape**: write a shared module, a helper that imports it, and a spec that extends the helper and collides with what leaked, then stop the leak from both sides
- **Time estimate**: 8 min thinking, under 1 min of runs
- **Slowest run asked for**: any of the four, under 1 s
- **Shows TLA+ in the prompt**: no

## Constructs

Named as `drill/INVENTORY.md` field 4 writes them.

- LOCAL (definition modifier)
- LOCAL INSTANCE
- INSTANCE
- named instance
- ! (namespace lookup)
- EXTENDS (module import)

## Inventory rows

K099, K101, K100, K102, K103, K004.

## Measured on

TLC2 Version 2026.07.31.184830, through `harness/verdict.sh` with one
config per run. The table is in `ANSWER.md`. Reproduce the silent row
with

```
cd verify && tlc -workers 1 -cleanup BeltLeak -config Linked.cfg
```

The `G05*` modules are thin wrappers, one per run the drill gate
reproduces. Each extends the module it stands for and carries a copy of
the config it is named after in `ANSWER.md`. `Gearing.tla` and
`GearingLocal.tla` also start with a G and are not wrappers. Neither has
a config of its own, so the gate skips both.
