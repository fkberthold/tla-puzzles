# Tiles

A corridor of `Wall` cells is tiled from one end. The tile length is picked when
the job starts and never changes, and each tile butts up against the one before
it. A tile that runs off the end is clipped. `laid` is the set of cells covered
so far, and `next` is where the following tile starts.

`work/Claims.tla` is the file you edit. It declares the state, gives you
`TypeOK`, and holds one small library module `Tile` instantiated twice. `Here` is
the tile about to be laid. `Whole` is the corridor read as a single tile the full
way across. Two claims under that are missing.

**Claim 1.** The tile about to be laid covers no cell that has been laid already.

**Claim 2.** Once the next tile would start past the end of the corridor, every
cell of the corridor has been laid.

Write both, then run all three machines.

## The three machines

They all read your two claims out of `Claims.tla`, so you write each claim once.

| machine | what it is | must report |
|---|---|---|
| `Corridor` | the real corridor | exit code 0 |
| `Lap` | the next tile starts on the last cell of this one | exit code 12 |
| `Gap` | the next tile starts one cell past this one | exit code 12 |

```bash
bash completion/verify-item.sh completion/modules/01-tiles
```

Exit code 150 on all three means a `FILL_IN` marker is still there, or what you
wrote does not parse.

## Reading the three codes

`Lap` answers to claim 1 and `Gap` answers to claim 2, so the codes say which
claim is weak rather than only that one is.

| 0, 12, 12 | both claims hold and both bite |
|---|---|
| 0, 0, 0 | neither claim says anything |
| 0, 12, 0 | claim 1 is good, claim 2 is too weak |
| 0, 0, 12 | claim 2 is good, claim 1 is too weak |

`Clear == TRUE` and `Filled == TRUE` score the second row. They pass the real
corridor, which is why two of the three machines are built to fail.
