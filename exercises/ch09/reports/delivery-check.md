# Chapter 09 delivery check

Run before the commit, on TLC2 Version 2026.07.31.184830.

```
bash scripts/deliver-exercises.sh 9 .ch09-scratch/practice
```

The delivered tree holds `EXERCISES.md`, `LOG.md`, `starters/` with all 12
files, and `cheatsheets/` with chapters 2 to 8. No `references/`, no
`COVERAGE.md`, no `reports/`, and no chapter 9 cheat sheet. That's what the
script is meant to withhold, and it withheld it.

Every command below was run from `.ch09-scratch/practice/ch09`, which is the
directory a learner works in. The harness path is the one printed in
`EXERCISES.md`, unedited.

## Exercise 1, `Footbridge`

The learner writes this module, so the check used the reference solution as the
answer.

| Step | Command | Verdict | rc |
|---|---|---|---|
| pass | `pcal starters/Footbridge.tla` then `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Footbridge.tla -c starters/Footbridge.cfg` | `OK` | 0 |
| fail, reopening branch added | same command | `SAFETY_VIOLATION` | 12 |
| fail, `PROPERTY` removed from the config | same command | `OK` | 0 |

The third row is the one Ex1 is built around. The broken bridge passes when only
the invariant is checked.

## Exercise 2, `Kiln`

| Step | Verdict | rc |
|---|---|---|
| `TODO 2` filled, `TODO 1` left alone | `LIVENESS_VIOLATION` | 13 |
| both holes filled | `OK` | 0 |
| `fair` kept, `soaks := 0` | `LIVENESS_VIOLATION` | 13 |

Command each time: `pcal starters/Kiln.tla` then
`bash ~/repos/tla-puzzles/harness/verdict.sh starters/Kiln.tla -c starters/Kiln.cfg`.

The unfilled starter returns `PARSE_ERROR` rc 150, which is the intended
behavior for a skeleton with a stub in a `define` block.

## Exercise 3, `LoadingBay`

| Step | Verdict | rc |
|---|---|---|
| `TODO 1` filled, weak `fair` as shipped | `LIVENESS_VIOLATION` | 13 |
| changed to `fair+` | `OK` | 0 |
| `fair+` kept, `Go` changed to `bay := self` | `LIVENESS_VIOLATION` | 13 |

Command each time: `pcal starters/LoadingBay.tla` then
`bash ~/repos/tla-puzzles/harness/verdict.sh starters/LoadingBay.tla -c starters/LoadingBay.cfg`.

## Exercise 4, `Beacon`

Three configs against one module, no `pcal` step.

| Config | As shipped | With `fair` deleted |
|---|---|---|
| `BeaconEver.cfg` | `OK` 0 | `LIVENESS_VIOLATION` 13 |
| `BeaconAgain.cfg` | `OK` 0 | `LIVENESS_VIOLATION` 13 |
| `BeaconSettles.cfg` | `LIVENESS_VIOLATION` 13 | `LIVENESS_VIOLATION` 13 |

The other fail sweep in Ex4, where the lamp never lights with fairness in place,
is mutant B2 in `reports/authoring.md`. All three configs return
`LIVENESS_VIOLATION` rc 13 there.

## Exercise 5, `Depot`

Two configs against one module, no `pcal` step.

| Config | As shipped, `MaxOpen == 0` | After the repair, `MaxOpen == 2` |
|---|---|---|
| `Depot.cfg` | `OK` 0 | `OK` 0 |
| `DepotProbe.cfg` | `OK` 0 | `SAFETY_VIOLATION` 12 |

The two fail runs Ex5 names, with the collect branch deleted and with `fair`
deleted, are mutants D2 and D3. Both return `LIVENESS_VIOLATION` rc 13.

## What this check would have caught

Nothing failed here, which is worth saying plainly rather than presenting as a
result. The value of the check is in the shape of the commands rather than the
verdicts, since the verdicts were already known from the reference runs. What it
confirms is that every printed path resolves from the delivered directory, that
no printed command reaches into `references/`, and that the two skeletons can be
filled and translated in the tree a learner actually gets.
