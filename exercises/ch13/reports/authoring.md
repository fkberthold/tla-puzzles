# Authoring report: ch13 exercise set

Bead `tla-jb7f.28`. Four exercises, four references, twenty seeded mutants.

Source of truth for the chapter is `hwayne/learntla-v2` at
`09840bfc2ee9a88cdbedb672be77a6c73942fe16`
[`git rev-parse HEAD` in the clone returned
`09840bfc2ee9a88cdbedb672be77a6c73942fe16`]. Coverage target is
`exercises/ch13/CHEATSHEET.md`, which passed cross-sheet review clean
[`exercises/reports/sheet-review-ch12-13.md`, "ch13 ... PASS"].

Toolchain is tla2tools v1.8.0 [`tlc` printed
`TLC2 Version 2026.07.31.184830 (rev: 30cc360)`]. Every verdict below comes
from `harness/verdict.sh`, which derives its token from the process exit status
and never from TLC's stdout [`V2-PLAN.md` §5.1].

## The exercises

| # | Title | Format | Target construct | Budget |
|---|---|---|---|---|
| 1 | Rules in their own file | complete-the-skeleton | named instance, `!`, `LOCAL` | 12 min |
| 2 | How far a name travels | predict-then-check | `LOCAL INSTANCE` against `INSTANCE` | 10 min |
| 3 | Two rooms, one range | write-from-prompt | `INSTANCE ... WITH` and `<-` | 15 min |
| 4 | The rate arrives late | complete-the-skeleton | partial parameterization | 12 min |

Surface content is a loading dock, a signal beacon, a wine and beer cellar, and
a parking garage. None of them is the chapter's `Point`, and none of them uses
`Sequences` [the chapter's running examples are `Point` at `modules.rst:104-111`
and `Sequences` throughout].

## References

All four green, run from the repo root
[`bash exercises/ch13/reports/run-refs.sh`]:

```
Dock       OK                     rc=0
Beacon     OK                     rc=0
Cellar     OK                     rc=0
Garage     OK                     rc=0
```

## Mutants

Twenty, five per reference, each one literal substring replacement with an
asserted occurrence count. Seeded with `reports/mutants.py` and run with
`reports/run-mutants.sh`, which runs each group from its own directory so TLC
resolves the group's other modules the way a learner's run resolves `starters/`.

| id | edited file | edit | verdict | rc |
|---|---|---|---|---|
| D1 | `Dock.tla` | `WithinCap` calls the `LOCAL` operator | `PARSE_ERROR` | 150 |
| D2 | `DockRules.tla` | drop `LOCAL` from `Level` | `OK` | 0 |
| D3 | `Dock.tla` | named instance becomes a bare `INSTANCE` | `PARSE_ERROR` | 150 |
| D4 | `DockRules.tla` | `<= cap` becomes `< cap` | `SAFETY_VIOLATION` | 12 |
| D5 | `Dock.tla` | `Take` guard `< Cap` becomes `<= Cap` | `SAFETY_VIOLATION` | 12 |
| B1 | `Signal.tla` | `INSTANCE` becomes `LOCAL INSTANCE` | `PARSE_ERROR` | 150 |
| B2 | `Palette.tla` | `Warm` narrows to one colour | `SAFETY_VIOLATION` | 12 |
| B3 | `Signal.tla` | `Escalated` drops its second conjunct | `SAFETY_VIOLATION` | 12 |
| B4 | `Beacon.tla` | `EXTENDS Signal` becomes `EXTENDS Palette` | `PARSE_ERROR` | 150 |
| B5 | `Palette.tla` | `LOCAL` on the unused `Cool` | `OK` | 0 |
| C1 | `Cellar.tla` | `WineBand` upper bound 14 becomes 11 | `SAFETY_VIOLATION` | 12 |
| C2 | `Cellar.tla` | `BeerBand` loses its whole `WITH` clause | `PARSE_ERROR` | 150 |
| C3 | `Band.tla` | `Holds` widens its range by one | `SAFETY_VIOLATION` | 12 |
| C4 | `Band.tla` | `ASSUME` becomes a contradiction | `OK` | 0 |
| C5 | `Band.tla` | `Headroom` subtracts the wrong way round | `SAFETY_VIOLATION` | 12 |
| G1 | `Garage.tla` | metered rate 3 becomes 5 at the call site | `SAFETY_VIOLATION` | 12 |
| G2 | `Garage.tla` | `Flat` adds `Base <- 0`, overriding the pass-through | `SAFETY_VIOLATION` | 12 |
| G3 | `Garage.tla` | `Metered` fixes `Base` at 100 | `SAFETY_VIOLATION` | 12 |
| G4 | `Tariff.tla` | `Charge` adds where it should multiply | `SAFETY_VIOLATION` | 12 |
| G5 | `Garage.tla` | `Garage` stops declaring `Base` | `PARSE_ERROR` | 150 |

Seventeen flip the reference's stated outcome. Three are inert, and each one is
inert for a reason worth writing down.

**D2, dropping `LOCAL` from a definition nobody outside calls.** The rules file
still works and the spec still passes. `LOCAL` restricts who can see a name, not
what the name means, so removing it changes nothing until somebody reaches for
it. D1 is the same edit from the other side and it does flip.

**B5, marking an unused definition `LOCAL`.** `Cool` is defined in `Palette.tla`
and used nowhere. Hiding it costs nothing. The pair with B1 is the point: the
same keyword on an import line takes the whole exercise down.

**C4, a false `ASSUME` in an instantiated module.** This is the finding, and I
went looking for it after C4 came back green. Probe: add
`UnusedBand == INSTANCE Band WITH Lo <- 99, Hi <- 1` to a working `Cellar.tla`,
where `Band` assumes `Lo <= Hi`, and run. Result `OK`, rc=0. So TLC doesn't
check an `ASSUME` in a module reached through `INSTANCE`, at least not on this
build. I don't know whether that's the language or the build, and both
`EXERCISES.md` and `COVERAGE.md` say so in those terms.

## Multi-file resolution, measured

This is the seam the whole chapter runs through, so I probed it before writing
anything. `Use.tla` binds `L == INSTANCE Lib` and `Lib.tla` sits beside it in
`starters/`. Three invocation shapes, all from a scratch tree:

| cwd | module argument | result |
|---|---|---|
| the chapter directory | `starters/Use.tla` | `SAFETY_VIOLATION` rc=12 |
| `starters/` | `Use.tla` | `SAFETY_VIOLATION` rc=12 |
| the chapter directory | absolute path to `Use.tla` | `SAFETY_VIOLATION` rc=12 |

The violation is the probe's own deliberately breakable invariant. What matters
is that none of the three is `PARSE_ERROR`, so `Lib` resolved every time. TLC
finds an auxiliary module beside the module it was pointed at, not only in the
caller's working directory. That's what lets the how-to-run commands name one
file and stay true.

`harness/verdict.sh` leaves the module argument alone on purpose, and its own
comment says why: absolutising it would move TLC's search for auxiliary modules
off the cwd [`harness/verdict.sh`, "The MODULE is deliberately left alone"]. The
measured answer is that both roots work, so neither form breaks the set.

## Delivery

`scripts/deliver-exercises.sh 13` into a scratch tree, then every how-to-run
command run from the delivered directory as printed. This is the check the
wave-1 review found four of its five defects behind, so it ran here on the real
delivered tree rather than on the repo.

The delivered tree holds `EXERCISES.md`, `LOG.md`, eleven starter files and
eleven earlier cheat sheets. It holds no `references/`, no `reports/`, no
`COVERAGE.md`, and not chapter 13's own sheet.

As delivered, before any work:

```
Dock     PARSE_ERROR      rc=150
Beacon   OK               rc=0
Cellar   PARSE_ERROR      rc=150
Garage   PARSE_ERROR      rc=150
```

Three of those are the design. `Dock.tla` and `Garage.tla` ship with holes and
don't parse until they're filled, and `Cellar.tla` doesn't exist until the
learner writes it. `Beacon` runs as shipped because exercise 2 is
predict-then-check and its first prediction is about the file as it stands.

After copying the four reference answers into the delivered `starters/`:

```
Dock     OK       rc=0
Beacon   OK       rc=0
Cellar   OK       rc=0
Garage   OK       rc=0
```

Every fail run `EXERCISES.md` names, applied in the delivered tree:

```
ex1 fail   PARSE_ERROR        rc=150
ex2 fail   PARSE_ERROR        rc=150
ex2 extra  SAFETY_VIOLATION   rc=12
ex3 fail   SAFETY_VIOLATION   rc=12
ex4 fail   SAFETY_VIOLATION   rc=12
```

All four back to `OK` after each edit was restored.

A second delivery over the same tree reported `skipped (exists)` for all
twenty-four files and wrote nothing, so a learner who re-delivers over
half-solved work keeps it.

The script needed no extension for the multi-file case. It copies `starters/`
recursively, one file at a time, so eleven files land as readily as three
[`scripts/deliver-exercises.sh`, the `find ... -print0` loop]. Nothing about
this chapter exposed a gap in it.

## Scope check

Every construct in the set appears on a sheet from `ch02` to `ch13`. The newest
are `EXCEPT` and `@`, both chapter 12's
[`exercises/ch12/CHEATSHEET.md`, `EXCEPT` and `@` construct entries]. Nothing
from beyond chapter 13 appears.

No PlusCal, no `--algorithm`, no translation step. Chapter 13 is written in
TLA+ directly and the set follows. The standing c-syntax dialect rule for this
track doesn't apply here, and no `.tla` file in the set names a translator
marker.

## What I'd change

Exercise 5 would be the `LET`-bound instance, and I didn't write it. The
reasoning is in `COVERAGE.md`. I think the better repair is a `LET` binding
added to exercise 3's task rather than a fifth exercise, because a whole
exercise on it would spend most of its budget re-teaching chapter 2's `LET`.

The `ASSUME` finding deserves a follow-up. If instantiated assumptions really
are unchecked, then a library that guards its constants with `ASSUME` is
guarding nothing once anybody instantiates it, and that's worth knowing well
beyond this exercise set.
