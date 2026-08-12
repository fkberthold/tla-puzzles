# Authoring report: ch06 exercise set

Bead `tla-jb7f.18`. Five exercises for learntla core chapter 6, "Structured
Data".

Toolchain for every run below: `TLC2 Version 2026.07.31.184830 (rev: 30cc360)`,
tla2tools v1.8.0, the project's pinned build. Chapter source is
`hwayne/learntla-v2` at `09840bfc2ee9a88cdbedb672be77a6c73942fe16`, cloned
shallow outside the worktree and confirmed by `git rev-parse HEAD`.

Every verdict here comes from `harness/verdict.sh`, which reads TLC's exit
status and never its console text. No stated outcome anywhere in this set is a
state count.

## The set

| # | Title | Format | Module | Budget |
|---|---|---|---|---|
| 1 | Parcel desk | write-from-prompt | `ParcelDesk` | 15 min |
| 2 | Six claims about DOMAIN | predict-then-check | `DomainProbe` | 10 min |
| 3 | Knob panel | complete-the-skeleton | `KnobPanel` | 15 min |
| 4 | Patch desk | write-from-prompt | `PatchDesk` | 12 min |
| 5 | Fare table | write-from-prompt | `FareTable` | 12 min |

Two module shapes carry the set. Exercises 1, 3 and 4 are PlusCal specs with a
`define` block and invariants, so a wrong answer lands on `SAFETY_VIOLATION`.
Exercises 2 and 5 are scratch files with no behavior spec and a stack of
`ASSUME` lines, so a wrong answer lands on `ASSUMPTION_FAILED`.

The scratch-file shape is worth a note, since it isn't obvious that TLC will
run a module with nothing to explore. It does. A `.cfg` naming no
`SPECIFICATION` still gets every `ASSUME` in the module checked, and the module
exits 0 or 10 on that alone. I probed that with a throwaway pair before writing
anything, and the committed evidence for it is the `DomainProbe` and
`FareTable` rows below: both `.cfg` files are comment-only, both references
come back `OK` and rc=0, and all nine of their mutants come back
`ASSUMPTION_FAILED` and rc=10.

That shape is also what chapter 1 teaches as the scratch file
(`setup.rst:89`), so it's a setup the learner has already seen.

## Pass runs

All five references, re-run after the last edit to any of them:

```
bash exercises/ch06/reports/run-refs.sh

ParcelDesk   OK                   rc=0
DomainProbe  OK                   rc=0
KnobPanel    OK                   rc=0
PatchDesk    OK                   rc=0
FareTable    OK                   rc=0
```

## Fail runs

The fail run stated in each exercise is a single edit the learner makes to
their own answer. Each one is seeded as a mutant and run, so the verdict in
`EXERCISES.md` is measured rather than predicted.

| Ex | Stated edit | Mutant | Verdict | rc |
|---|---|---|---|---|
| 1 | misspell `express` as `expres` in the `Upgrade` struct literal | P1 | `SAFETY_VIOLATION` | 12 |
| 2 | `Claim3` becomes `[i \in 0..2 \|-> i * i] = <<0, 1, 4>>` | D1 | `ASSUMPTION_FAILED` | 10 |
| 3 | `TODO_3` turns the knob to `MaxNotch` instead of `ceiling` | K1 | `SAFETY_VIOLATION` | 12 |
| 4 | swap the operands of the `Remerge` merge | T1 | `SAFETY_VIOLATION` | 12 |
| 5 | `Fare` becomes plain `a - b` | F1 | `ASSUMPTION_FAILED` | 10 |

## Mutant pass

22 hand-seeded mutants, 3 to 5 per reference. Each is one literal substring
replacement applied to a fresh copy of the reference in its own directory, so
the module name still matches the file name. The seeder refuses any pattern
that doesn't occur exactly once, which is what keeps a mutant from silently
hitting the wrong line.

PlusCal mutants are re-translated with `pcal` before the run. TLC checks the
translation and not the algorithm comment, so an edit inside the PlusCal block
does nothing until `pcal` has run again. K2 is the proof that the
re-translation works, since it edits the `define` block and still flips.

Seeder and runner are committed next to this file, so the pass is repeatable
rather than a table you have to take on trust. From the repo root:

```
python3 exercises/ch06/reports/mutants.py
bash exercises/ch06/reports/run-mutants.sh
```

The mutant tree they build is scratch and untracked. The table below is the
record of the run.

| id | module | edit | verdict | rc |
|---|---|---|---|---|
| P1 | `ParcelDesk` | key `express` misspelled `expres` in `Upgrade` | `SAFETY_VIOLATION` | 12 |
| P2 | `ParcelDesk` | `Weigh` guard `<` becomes `<=` | `SAFETY_VIOLATION` | 12 |
| P3 | `ParcelDesk` | `ParcelType` narrows `kilos` to `1..MaxKilos-1` | `SAFETY_VIOLATION` | 12 |
| P4 | `ParcelDesk` | `Upgrade` drops the `depot` field | `SAFETY_VIOLATION` | 12 |
| D1 | `DomainProbe` | `Claim3` moves the domain to `0..2` | `ASSUMPTION_FAILED` | 10 |
| D2 | `DomainProbe` | `Claim1` expects `{0, 1, 2}` | `ASSUMPTION_FAILED` | 10 |
| D3 | `DomainProbe` | `Claim2` expects `{"hue"}` | `ASSUMPTION_FAILED` | 10 |
| D4 | `DomainProbe` | `Claim6` expects 5 pairs | `ASSUMPTION_FAILED` | 10 |
| D5 | `DomainProbe` | `Claim5` expects the right side of the merge to win | `ASSUMPTION_FAILED` | 10 |
| K1 | `KnobPanel` | knob turned to `MaxNotch`, not `ceiling` | `SAFETY_VIOLATION` | 12 |
| K2 | `KnobPanel` | `DialType` codomain becomes `1..ceiling` | `SAFETY_VIOLATION` | 12 |
| K3 | `KnobPanel` | `dial` initialized over `1..NumKnobs+1` | `SAFETY_VIOLATION` | 12 |
| K4 | `KnobPanel` | knob turned to `ceiling + 1` | `SAFETY_VIOLATION` | 12 |
| K5 | `KnobPanel` | `DialType` codomain becomes `0..MaxNotch` | `OK` | 0 |
| T1 | `PatchDesk` | `Remerge` operands swapped | `SAFETY_VIOLATION` | 12 |
| T2 | `PatchDesk` | `Override` operands swapped | `SAFETY_VIOLATION` | 12 |
| T3 | `PatchDesk` | `Remerge` merges a new key `verbose` | `SAFETY_VIOLATION` | 12 |
| T4 | `PatchDesk` | `Override` sets `retries` to 50 | `SAFETY_VIOLATION` | 12 |
| F1 | `FareTable` | `Fare` becomes `a - b` | `ASSUMPTION_FAILED` | 10 |
| F2 | `FareTable` | `Fare`'s else branch becomes `b - a + 1` | `ASSUMPTION_FAILED` | 10 |
| F3 | `FareTable` | `Zones` widens to `1..4` | `ASSUMPTION_FAILED` | 10 |
| F4 | `FareTable` | `MaxFare` narrows to 1 | `ASSUMPTION_FAILED` | 10 |

21 killed, 1 inert.

**K5 is the inert one, and it's inert on purpose.** It widens `DialType`'s
codomain from `0..ceiling` to `0..MaxNotch`, which is a learner writing the
type against the constant instead of against the swept variable. On its own
nothing violates it, because every dial value the correct algorithm produces
sits in `0..MaxNotch` too. That's the finding, not a gap in the battery: the
swept type isn't checking anything the constant type checks, it's checking a
thing the constant type would let through. K1 is the same wrong answer with the
sweep still in place, and K1 dies. So the pair together shows what exercise 3's
`ceiling` is buying, which is why I kept both.

I want to be plain that K5's `OK` is a real run and not a mutant that failed to
land. K2 edits the same line of the same `define` block and comes back 12, so
the seed reaches the translation.

## Chapter examples avoided

Read `docs/core/functions.rst` in full, 401 lines. Its own worked material,
none of which appears in this set:

- `struct == [a |-> 1, b |-> {}]` (`functions.rst:17`)
- `BankTransactionType` over accounts, amounts and deposit/withdraw (`:40`)
- `RangeSeq` and `RangeStruct` (`:66`, `:72`)
- `Prod`, the pair-indexed product (`:109`)
- `TruthTable == [p, q \in BOOLEAN |-> p => q]` (`:125`)
- `1 :> "a" @@ 2 :> "b"` and `"a" :> 1 @@ "b" :> 2` (`:148`, `:151`)
- `Zip1`, `Zip2`, and the quantifier check that they agree (`:168` to `:192`)
- `assignments` over tasks and CPUs, and `OnlyOneTaskPerCpu` (`:204` to `:223`)
- the `LeqTwoCPUs` filtered function set (`:249`)
- the four function-set examples: server status, `[Node \X Node -> BOOLEAN]`,
  the undirected-graph filter, `[Resource -> User \union {NULL}]` (`:262` to
  `:265`)
- `IsSorted`, `Sort`, `Range`, `CountMatching` (`:286` to `:331`)
- the duplicate checker in all four versions under `docs/specs/duplicates/`
  (`:353`, `:361`, `:367`, `:376`)

Three places where this set runs structurally close to the chapter, declared
rather than hidden.

**Exercise 5's `Fare` is a two-argument function literal, the same form as
`Prod` and `TruthTable`.** There's no way to drill the construct without
writing one. The payload differs (a zone-boundary count against a product and
against implication), and the four claims around it are about symmetry, the
diagonal, the domain, and the type, none of which the chapter asserts about
either of its two.

**Exercise 5's `FareIsTyped` has the shape of the chapter's
`graph \in [Node \X Node -> BOOLEAN]`.** Same reason: a function set over a
cross product is the thing being taught. The codomain is a fare range rather
than `BOOLEAN`, and the chapter never checks its graph example with a model.

**Exercise 3 uses state sweeping, which the chapter teaches through the
duplicate checker.** This is the closest call in the set. The chapter sweeps a
length, `n \in 1..Size` driving `seq \in [1..n -> S]`, and checks uniqueness.
Exercise 3 sweeps a bound instead, `ceiling \in 1..MaxNotch` driving the
codomain of `dial`, with the domain fixed by a constant. The chapter's tip at
`:374` names both flavours and demonstrates only the first, so the exercise
takes the half the chapter leaves on the page.

## Scope check

Constructs used across the five references and the two starters, checked
against the `ch02` through `ch06` sheets.

| Source | Constructs used |
|---|---|
| ch02 | operator definition, `IF-THEN-ELSE`, `EXTENDS`, integers, strings, `BOOLEAN`, `=` and `#`, `=>`, sequences and `Len`, sets, `\in`, `\union`, `a..b`, `\X`, `Cardinality` |
| ch03 | `--algorithm`, `variables`, `:=`, labels, `while`, PlusCal `if`, `variables x \in Set` |
| ch04 | `define` block, invariants, `\A` |
| ch05 | `CONSTANT`, `ASSUME`, ordinary constant assignment in the `.cfg` |
| ch06 | struct literal, struct set, `DOMAIN`, function literal, `:>`, `@@`, function set |

Nothing from chapter 7 or later. No `either`, no `with x \in Set`, no process
or fairness syntax, no temporal property, no hand-written `EXCEPT`, no
`RECURSIVE`.

Two things to flag rather than leave for a reviewer to find.

**Assignment to one part of a variable.** Exercise 1 writes
`parcel.kilos := parcel.kilos + 1` and exercise 3 writes
`dial[next] := ceiling`. The indexed form is in the chapter, at
`functions.rst:206`, and ch03's sheet carries the same shape in its `||` entry.
The dotted form is the struct spelling of the same thing, and the chapter says
at `functions.rst:20` that the two are interchangeable for reading. I read that
as in scope. It's the one call in this set I'd most expect an argument about.

**The translation is not chapter 6 material.** After `pcal` runs, the learner's
own file carries `EXCEPT`, `UNCHANGED`, and `Spec == Init /\ [][Next]_vars`,
which are chapter 12. That's been true of every PlusCal exercise since chapter
3, so it isn't new here, and no exercise asks the learner to read or edit the
translated block.

## Type-stability check

TLC aborts evaluation on a cross-type comparison rather than returning `FALSE`,
so a structured-data drill can quietly turn into an evaluation failure instead
of the verdict it advertises. Every comparison in this set was written to stay
on one type.

- `DomainProbe` claims 1, 2 and 6 compare a set of integers to a set of
  integers, a set of strings to a set of strings, and an integer to an integer.
- Claim 3 compares a function to a sequence, which is one type, and that
  equality is the chapter's own point.
- Claims 4 and 5 compare integers.
- `FareTable` compares integers throughout, and `FareIsTyped` is a `\in` on a
  function set rather than a comparison.
- The three PlusCal specs compare inside their own variable's type.

No exercise mixes a string with a number anywhere, and none needs a phase test
or `ToString` to stay safe. The seeded mutants back this up: every one of the
22 came back on a verdict row (0, 10 or 12) and none landed on 75, 76 or 255,
which is what an aborted evaluation would have produced.

## Review checklist

Against `exercises/templates/REVIEW-CHECKLIST.md`:

- Each exercise fits its budget. 10 to 15 minutes, 64 total.
- Every statement is unambiguous. The `.cfg` files pin the invariant names, so
  a correct answer can't miss the stated verdict on a naming difference.
- No construct is used before the chapter that introduces it. Table above.
- No exercise is a near-copy of a running example. Three structural
  overlaps declared above.
- The set covers the chapter's major themes. `COVERAGE.md` maps six themes to
  exercises and argues the two partial rows.
- Mutant evidence is present. This file.
- Every expected outcome is verified through `harness/verdict.sh`. 27 runs,
  5 pass and 22 mutant.
