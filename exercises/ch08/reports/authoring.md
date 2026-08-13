# Authoring report: ch08 exercise set

Bead `tla-jb7f.20`. Five exercises for learntla core chapter 8, "Concurrency".

Toolchain for every run below: `TLC2 Version 2026.07.31.184830 (rev: 30cc360)`,
tla2tools v1.8.0, the project's pinned build, with `pcal.trans Version 1.12 of
01 July 2024`. Chapter source is `hwayne/learntla-v2` at
`09840bfc2ee9a88cdbedb672be77a6c73942fe16`, cloned shallow outside the worktree
and confirmed by `git rev-parse HEAD`.

Chapter 8's text is `docs/core/concurrency.rst` plus
`docs/core/advanced/procedures.rst`, which the `.. include::` at
`concurrency.rst:221` splices in. Both were read in full. The procedures half
carries a standing `.. todo:: An example` at `procedures.rst:50`, so the chapter
ships `procedure`, `call` and `return` with syntax skeletons and no worked
example at all. Exercise 4 is the first place a learner sees one run.

Every verdict here comes from `harness/verdict.sh`, which reads TLC's exit
status and never its console text. No stated outcome anywhere in this set is a
state count.

## Dialect

Every module in this set is **c-syntax PlusCal**, the brace dialect, matching
the chapter's own specs. `EXERCISES.md` names the dialect in its second
paragraph so a learner arriving from a p-syntax chapter is not left to infer it
from the braces.

## The set

| # | Title | Format | Module | Budget |
|---|---|---|---|---|
| 1 | Seat desk | complete-the-skeleton | `SeatDesk` | 15 min |
| 2 | Two cooks, one whisk | predict-then-check | `KitchenLocks` | 12 min |
| 3 | Cloakroom | write-from-prompt | `Cloakroom` | 15 min |
| 4 | Stamp desk | write-from-prompt | `StampDesk` | 15 min |
| 5 | Bell tower | predict-then-check | `BellTower` | 12 min |

Both predict-then-check modules ship complete in `starters/`, so the learner
runs the module the prediction is about. `SeatDesk` ships as a skeleton with
three `TODO` holes and does not parse until they are filled. `Cloakroom` and
`StampDesk` ship as a `.cfg` only.

The five fail runs deliberately land on four different verdicts. A learner who
has only ever seen `SAFETY_VIOLATION` reads every red run as "an invariant
broke", and two of this chapter's characteristic failures are not that:

| Ex | Fail verdict | What it means here |
|---|---|---|
| 1 | `SAFETY_VIOLATION` | an invariant was checked and came out false |
| 2 | `DEADLOCK` | no process could act; nothing was asserted at all |
| 3 | `SPEC_EVAL_FAILURE` | the spec did not evaluate, so nothing was checked |
| 4 | `SAFETY_VIOLATION` | an invariant was checked and came out false |
| 5 | `PARSE_ERROR` | the module never parsed |

Exercises 3 and 5 both spend their After-the-run prose on the same distinction,
which `harness/verdict.sh`'s own header makes at length: 75, 76 and 77 mean the
check never happened, and are not violation rows.

## Pass runs

All five references, re-run after the last edit to any of them:

```
bash exercises/ch08/reports/run-refs.sh

SeatDesk       OK                   rc=0
KitchenLocks   OK                   rc=0
Cloakroom      OK                   rc=0
StampDesk      OK                   rc=0
BellTower      OK                   rc=0
```

`KitchenLocks` is run with `-d`. `verdict.sh` has deadlock checking **off** by
default, and a spec whose entire subject is deadlock has to ask for it. Its
pass run being `OK` is only meaningful because the flag was on; without it the
row would be `OK` for a reason that has nothing to do with the exercise.

## Fail runs

The fail run stated in each exercise is a single edit the learner makes to
their own answer. Each one is seeded as a mutant and run, so the verdict in
`EXERCISES.md` is measured rather than predicted.

| Ex | Stated edit | Mutant | Verdict | rc |
|---|---|---|---|---|
| 1 | give the `if` its own `Book:` label | S1 | `SAFETY_VIOLATION` | 12 |
| 2 | the cook takes the whisk first | K1 | `DEADLOCK` | 11 |
| 3 | drop the `if (free # {})` guard | C1 | `SPEC_EVAL_FAILURE` | 75 |
| 4 | `call Stamp(2)` becomes `call Stamp(3)` | T1 | `SAFETY_VIOLATION` | 12 |
| 5 | add `EarlyTally` to the `define` block | B1 | `PARSE_ERROR` | 150 |

Exercise 5's stated edit is an **addition**, not a move, and that was chosen so
the stated edit and the seeded mutant are the same single edit. Moving
`TallyMatches` up into the `define` block would teach the identical lesson, but
it is a deletion plus an insertion, and a mutant that is one literal
substring replacement cannot express it. Adding a second operator with the same
body under a different name reaches the same `PARSE_ERROR` by the same route,
and avoids the duplicate-name error confusing the reading.

## Mutant pass

22 hand-seeded mutants, 4 or 5 per reference. Each is one literal substring
replacement applied to a fresh copy of the reference in its own directory, so
the module name still matches the file name. The seeder refuses any pattern
that does not occur exactly once, which is what keeps a mutant from silently
hitting the wrong line.

Every mutant is re-translated with `pcal` before the run. TLC checks the
translation and not the algorithm comment, so an edit inside the PlusCal block
does nothing until `pcal` has run again. B1 is the proof that the
re-translation works, since it edits the `define` block and still flips.

Seeder and runner are committed next to this file, so the pass is repeatable
rather than a table you have to take on trust. From the repo root:

```
python3 exercises/ch08/reports/mutants.py
bash exercises/ch08/reports/run-mutants.sh
```

21 of 22 flip the reference's stated pass outcome. The 22nd is inert under the
exercise's own invocation and is documented below.

| id | Module | Edit | Verdict | rc |
|---|---|---|---|---|
| S1 | SeatDesk | give the `if` its own `Book:` label | `SAFETY_VIOLATION` | 12 |
| S2 | SeatDesk | `seats := seats - 2` | `SAFETY_VIOLATION` | 12 |
| S3 | SeatDesk | `BooksBalance` off by one | `SAFETY_VIOLATION` | 12 |
| S4 | SeatDesk | `sawFree := (seats >= 0)` | `SAFETY_VIOLATION` | 12 |
| K1 | KitchenLocks | cook takes the whisk first | `DEADLOCK` | 11 |
| K2 | KitchenLocks | baker never puts the pan back | `DEADLOCK` | 11 |
| K3 | KitchenLocks | cook puts nothing back | `DEADLOCK` | 11 |
| K4 | KitchenLocks | baker takes the whisk first | `DEADLOCK` | 11 |
| C1 | Cloakroom | drop the `if (free # {})` guard | `SPEC_EVAL_FAILURE` | 75 |
| C2 | Cloakroom | `free := free \ {}` | `SAFETY_VIOLATION` | 12 |
| C3 | Cloakroom | `CoatsAreGuests` drops the `{0} \cup` | `SAFETY_VIOLATION` | 12 |
| C4 | Cloakroom | `UsedHooksAreTaken` implication inverted | `SAFETY_VIOLATION` | 12 |
| T1 | StampDesk | `call Stamp(3)` | `SAFETY_VIOLATION` | 12 |
| T2 | StampDesk | `return;` becomes `skip;` | `OK` | 0 |
| T3 | StampDesk | `LedgerBalances` off by one | `SAFETY_VIOLATION` | 12 |
| T4 | StampDesk | `while (made <= copies)` | `SAFETY_VIOLATION` | 12 |
| T5 | StampDesk | `MaxInk == 3` | `SAFETY_VIOLATION` | 12 |
| B1 | BellTower | `EarlyTally` added to the `define` block | `PARSE_ERROR` | 150 |
| B2 | BellTower | `while (left >= 0)` | `SAFETY_VIOLATION` | 12 |
| B3 | BellTower | `TallyMatches` off by one | `SAFETY_VIOLATION` | 12 |
| B4 | BellTower | `RightTotal` drops the `AllRung` guard | `SAFETY_VIOLATION` | 12 |
| B5 | BellTower | `left = Quota + 1` | `SAFETY_VIOLATION` | 12 |

Every KitchenLocks row is run with `-d`, matching how the exercise is run. Run
without it, all four come back `OK` and would read as four inert mutants when
in fact each one wedges the kitchen. The runner hardcodes the flag for that
module rather than leaving it to whoever runs the script.

### T2, the documented inert mutant, and what it turned up

T2 deletes the procedure's `return;`. The sheet says TLC errors if a procedure
ends without reaching one, so this was seeded expecting a flip. It comes back
`OK`, rc=0.

The reason is worth recording, because it is a fact about the translator rather
than about this spec. `pcal` does not refuse the file. It emits the label's
successor as a label that no action defines:

```
Finish(self) == /\ pc[self] = "Finish"
                /\ TRUE
                /\ pc' = [pc EXCEPT ![self] = "Error"]
                /\ UNCHANGED << ink, stamped, stack, copies, made >>
```

`"Error"` has no action, so a clerk that reaches it can never move again. Once
both clerks are there nothing at all is enabled, and `Terminating` does not
apply because it requires every `pc` to read `"Done"`. That is a deadlock, and
deadlock checking is off by default:

```
bash harness/verdict.sh -d .ch08-mut/T2/StampDesk.tla -c .ch08-mut/T2/StampDesk.cfg
DEADLOCK
rc=11
```

So the sheet's "TLC will raise an error" is true only if you asked TLC to look.
A missing `return` in a spec run without deadlock checking is **silent**. It is
recorded here rather than turned into the exercise's fail run because Exercise
2 already owns `DEADLOCK`, and a second exercise landing on the same token
teaches less than the four-verdict spread does.

## Verdict runs

Verdict runs through `harness/verdict.sh` while authoring this set:

| Phase | Runs |
|---|---|
| Design probes, before any deliverable existed | 12 |
| Reference pass runs, final | 5 |
| Mutant pass | 22 |
| T2 re-run with `-d` | 1 |
| Scratch-delivery pass, every printed how-to-run | 5 |
| Scratch-delivery pass, two stated fail edits | 2 |
| Scratch-delivery pass, the unfilled skeleton | 1 |
| **Total** | **48** |

The 12 design probes are the reason every verdict in `EXERCISES.md` is measured
rather than guessed. Three of them changed the set:

1. **The unguarded-`CHOOSE` verdict is `SPEC_EVAL_FAILURE`, not a violation.**
   Probed before Exercise 3 was written, which is why its After-the-run prose
   is about the difference between "your invariant is false" and "nothing was
   checked" rather than about the missing guard.
2. **A missing `return` is invisible without `-d`.** The T2 finding above,
   first seen as a probe. It cost Exercise 4 its original fail run.
3. **`pcal` reads an assigned local back within the same label.** `SeatDesk`'s
   `Look` label assigns `sawFree` and then tests it. The chapter warns at
   `concurrency.rst:204` that `await` sees the updated value when embedded
   directly but not through a defined operator, which left it open whether an
   `if` in the same position sees the old value. It sees the new one; the
   translation reads `IF sawFree'[self]`. Had it gone the other way the pass
   run would have been wrong and Exercise 1 would have needed rebuilding.

## Worked examples avoided

The chapter runs two examples end to end. Neither's surface content appears
anywhere in this set.

**`reader_writer`**, in ten revisions under `docs/specs/reader_writer/`. A
`queue` sequence with `Append`, `Head` and `Tail`; a `total` accumulator; a
`Writers` process set writing `self`; a `reader = 0` process looping on
`goto ReadFromQueue`; `await queue = <<>>` and `await queue # <<>>`; local `i`
in a `while` loop. Avoided wholesale. **No module in this set contains a
sequence-valued variable at all**, which removes the queue surface at the root
rather than by renaming it. `StampDesk` extends `Sequences` and never uses a
sequence, which is exactly its point.

**`threads`**, in four revisions under `docs/specs/threads/`. A shared
`counter` incremented by a `Threads` process set; a process-local `tmp`
holding a read-then-write temporary; a `lock` variable over
`Threads \union {NULL}` with `await lock = NULL`; `AllDone` over `pc[t]`;
`Correct == AllDone => counter = NumThreads`; an `assert lock = self` on
release. Avoided as follows:

- The **read-then-write race** is `SeatDesk`, and it is a check-then-act race
  over a seat count rather than a read-modify-write over a counter. The failure
  is overselling, not a lost update, and the racing quantity is bounded below
  by an invariant rather than compared against an expected total.
- The **mutex** is `KitchenLocks`, and it is deliberately not a mutex exercise.
  Two locks in the wrong order, no critical section, no `self`, and the lesson
  is lock ordering rather than lock acquisition.
- The **`AllDone => correct` invariant shape** is the one structural echo. It
  survives as `BellTower`'s `RightTotal`, because it is the only way to state a
  final-result property without the liveness that chapter 9 owns, and the sheet
  itself flags that at `concurrency.rst:313-317`. The surrounding spec shares
  nothing else: no lock, no shared temporary, no race.
- **`assert`** is not used anywhere in this set. It is chapter 5's construct and
  the chapter reaches for it only in a production-spec aside.

Surface nouns across the five modules are seats and agents, a pan and a whisk,
cloakroom hooks and guests, ink and clerks, ropes and ringers. No queue, no
counter, no thread, no reader, no writer.

## Scope check

Every construct used is from chapters 2 to 8, checked against
`exercises/ch02` through `exercises/ch08`'s `CHEATSHEET.md` construct lists.

The ones worth naming, with the chapter that introduces them: `CONSTANT` and
model values (ch03, `Nobody` in `KitchenLocks`); function literals and function
update (ch06, `coat` in `Cloakroom`); `CHOOSE` (ch04); `Cardinality` (ch04,
`BellTower`); the deterministic `with (h = ...)` (ch05); `if` and `while`
(ch05); `skip` (ch05); `\A` (ch07); `define` blocks and invariants (ch07).

Nothing from chapter 9 or later appears. No temporal operator, no fairness
annotation, no `Termination` in any `.cfg`.

## Scratch-delivery pass

`scripts/deliver-exercises.sh` delivers `EXERCISES.md`, `LOG.md`, `starters/`
and the earlier chapters' cheat sheets. It never delivers `references/`,
`COVERAGE.md` or `reports/`. So every command printed in `EXERCISES.md` has to
be true from the delivered tree, with no `references/` path anywhere in it.
That is checked by running them, not by reading them.

```
bash scripts/deliver-exercises.sh 8 .ch08-deliver
find .ch08-deliver -type f | sort
```

The delivered tree holds `EXERCISES.md`, `LOG.md`, `starters/` with ten files,
and `cheatsheets/ch02.md` through `cheatsheets/ch07.md`. No `references/`, no
`COVERAGE.md`, no `reports/`, and not chapter 8's own cheat sheet.

Then, standing in `.ch08-deliver/ch08` and having written the answers into
`starters/` as `EXERCISES.md` instructs, every printed how-to-run, verbatim:

```
pcal starters/SeatDesk.tla
bash ~/repos/tla-puzzles/harness/verdict.sh starters/SeatDesk.tla -c starters/SeatDesk.cfg
OK   rc=0

pcal starters/KitchenLocks.tla
bash ~/repos/tla-puzzles/harness/verdict.sh -d starters/KitchenLocks.tla -c starters/KitchenLocks.cfg
OK   rc=0

pcal starters/Cloakroom.tla
bash ~/repos/tla-puzzles/harness/verdict.sh starters/Cloakroom.tla -c starters/Cloakroom.cfg
OK   rc=0

pcal starters/StampDesk.tla
bash ~/repos/tla-puzzles/harness/verdict.sh starters/StampDesk.tla -c starters/StampDesk.cfg
OK   rc=0

pcal starters/BellTower.tla
bash ~/repos/tla-puzzles/harness/verdict.sh starters/BellTower.tla -c starters/BellTower.cfg
OK   rc=0
```

The `~/repos/tla-puzzles/harness/verdict.sh` in those lines is the main
checkout's copy, byte-identical to this worktree's by `cmp`. The learner has
only the main checkout, so that is the path the exercises print.

Two stated fail runs were then made as edits in the delivered tree and re-run,
to show a learner can reach them from what they were given:

```
# exercise 1, after adding the Book: label
SAFETY_VIOLATION   rc=12

# exercise 5, after adding EarlyTally to the define block
PARSE_ERROR        rc=150
```

One more delivery check, into a second scratch tree so the starters were
untouched. Running the unfilled `SeatDesk` skeleton straight through TLC gives
`CONFIG_ERROR` rc=151, because the shipped `.cfg` names invariants an
untranslated module does not define. Running `pcal` on it first, which is what
`EXERCISES.md` tells the learner to do, gives the useful message instead:

```
Unrecoverable error:
 -- Expected ":=" but found ";"
    line 33, column 13.
```

Line 33 is `TODO_3;`. Exercise 1's task says so, so a learner meeting that
message knows it is the exercise working rather than a broken file.

## Files

```
exercises/ch08/EXERCISES.md
exercises/ch08/COVERAGE.md
exercises/ch08/starters/     SeatDesk.tla+cfg, KitchenLocks.tla+cfg,
                             Cloakroom.cfg, StampDesk.cfg, BellTower.tla+cfg
exercises/ch08/references/   all five .tla+.cfg, translated
exercises/ch08/reports/      authoring.md, mutants.py, run-mutants.sh,
                             run-refs.sh
```

`starters/Cloakroom.cfg` and `starters/StampDesk.cfg` ship without a `.tla`,
which is what makes those two write-from-prompt. Both predict-then-check
modules, `KitchenLocks` and `BellTower`, ship complete in `starters/` and not
only in `references/`, so the module a learner is asked to predict about is one
they were actually given.
