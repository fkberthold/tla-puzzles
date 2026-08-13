# Authoring report: ch07 exercise set

Bead `tla-jb7f.19`. Five exercises for learntla core chapter 7,
"Nondeterminism".

Toolchain for every run below: `TLC2 Version 2026.07.31.184830 (rev: 30cc360)`,
tla2tools v1.8.0, the project's pinned build. PlusCal translator is
`pcal.trans Version 1.12 of 01 July 2024`. Chapter source is `hwayne/learntla-v2`
at `09840bfc2ee9a88cdbedb672be77a6c73942fe16`, cloned shallow outside the
worktree and confirmed by `git rev-parse HEAD`.

Every verdict here comes from `harness/verdict.sh`, which reads TLC's exit
status and never its console text. No stated outcome anywhere in this set is a
state count.

## Dialect

Every module in this set is **c-syntax PlusCal**, the braced dialect
(`--algorithm name { ... }`), on a ruling from central that landed while the
references were being written. The ch02 to ch06 sets are p-syntax. This is the
first chapter in the curriculum where the two diverge, so a reader coming from
ch06 should expect the surface to look different.

The dialect was probed before anything was committed to. A throwaway module
with a braced `with`, a braced `either`, and a braced `define` block translated
and checked clean, so nothing in this set rests on an assumption that c-syntax
carries the constructs the chapter teaches.

## The set

| # | Title | Format | Module | Budget |
|---|---|---|---|---|
| 1 | Depot | complete-the-skeleton | `Depot` | 12 min |
| 2 | Sluice | complete-the-skeleton | `Sluice` | 12 min |
| 3 | Two jugs and a tap | predict-then-check | `Jugs` | 10 min |
| 4 | Box office | write-from-prompt | `BoxOffice` | 15 min |
| 5 | Ferry | write-from-prompt | `Ferry` | 15 min |

61 minutes total.

Every module is a PlusCal spec with a `define` block and invariants, so a wrong
answer lands on `SAFETY_VIOLATION`. There is no scratch-file `ASSUME` shape in
this set the way there was in ch06, because nondeterminism is a property of a
behaviour and a module with no behaviour has nowhere to put it. `Depot` carries
one `ASSUME` for its constant, which is the set's only route to
`ASSUMPTION_FAILED` and is exercised by mutant D5.

## Pass runs

All six reference rows, re-run after the last edit to any module. Six rows for
five modules because `Jugs` is checked once per config.

```
bash exercises/ch07/reports/run-refs.sh

Depot        Depot        OK                   rc=0
Sluice       Sluice       OK                   rc=0
Jugs         Jugs         SAFETY_VIOLATION     rc=12
Jugs         JugsEven     OK                   rc=0
BoxOffice    BoxOffice    OK                   rc=0
Ferry        Ferry        OK                   rc=0
```

The `Jugs`/`Jugs.cfg` row is `SAFETY_VIOLATION` on purpose and is not a defect.
That exercise inverts its invariant so that reaching the goal breaks it, which
is the chapter's own search-by-refutation move.

## Fail runs

The fail run stated in each exercise is a single edit the learner makes to
their own answer. Each one is seeded as a mutant and run, so the verdict in
`EXERCISES.md` is measured rather than predicted.

| Ex | Stated edit | Mutant | Verdict | rc |
|---|---|---|---|---|
| 1 | `TODO_2` draws from `Crates` instead of `waiting` | D1 | `SAFETY_VIOLATION` | 12 |
| 2 | `TODO_2` becomes `TRUE`, so the open branch is unguarded | S1 | `SAFETY_VIOLATION` | 12 |
| 3 | no learner edit. The two stated runs are the two configs | n/a | see pass runs | |
| 4 | the room check becomes `TRUE`, so every order is sold | B1 | `SAFETY_VIOLATION` | 12 |
| 5 | `aboard := 0` replaces the `skip` in the failed crossing | F1 | `SAFETY_VIOLATION` | 12 |

## Mutant pass

25 hand-seeded mutants, 5 per reference. Each is one literal substring
replacement applied to a fresh copy of the reference in its own directory, so
the module name still matches the file name. The seeder refuses any pattern
that does not occur exactly once, which is what keeps a mutant from silently
hitting the wrong line.

Every ch07 reference is a PlusCal spec, so every mutant is re-translated with
`pcal` before the run. TLC checks the translation and not the algorithm
comment, so an edit inside the PlusCal block does nothing until `pcal` has run
again. Several patterns here are pinned to the PlusCal copy **by indentation**,
because the same text appears again in the translation. D2, D4, S3, S5, B3, B4
and F5 are all in that group, and the re-translation step is what makes pinning
the PlusCal copy the right choice rather than a mistake.

The seeder carries a `cfg` field, which ch06's did not need. `Jugs` ships two
configs and its two stated outcomes are one per config, so each `Jugs` mutant
names the config it is meant to flip.

Seeder and runner are committed next to this file, so the pass is repeatable
rather than a table you have to take on trust. From the repo root:

```
python3 exercises/ch07/reports/mutants.py
bash exercises/ch07/reports/run-mutants.sh
```

The mutant tree they build is scratch and untracked. The table below is the
record of the run.

| id | module | cfg | edit | verdict | rc |
|---|---|---|---|---|---|
| D1 | `Depot` | `Depot` | the `with` draws from `Crates`, not `waiting` | `SAFETY_VIOLATION` | 12 |
| D2 | `Depot` | `Depot` | `Conserved` forgets the crates still waiting | `SAFETY_VIOLATION` | 12 |
| D3 | `Depot` | `Depot` | the pick does not remove the crate from `waiting` | `SAFETY_VIOLATION` | 12 |
| D4 | `Depot` | `Depot` | `NoRepeats` is off by one | `SAFETY_VIOLATION` | 12 |
| D5 | `Depot` | `Depot` | `ASSUME` demands an empty `Crates` | `ASSUMPTION_FAILED` | 10 |
| S1 | `Sluice` | `Sluice` | the open branch loses its guard | `SAFETY_VIOLATION` | 12 |
| S2 | `Sluice` | `Sluice` | the freeze branch loses its guard | `SAFETY_VIOLATION` | 12 |
| S3 | `Sluice` | `Sluice` | `FrozenIsShut` drops the negation | `SAFETY_VIOLATION` | 12 |
| S4 | `Sluice` | `Sluice` | the shut branch opens the gate instead | `SAFETY_VIOLATION` | 12 |
| S5 | `Sluice` | `Sluice` | `TypeOK` narrows the step range by one | `SAFETY_VIOLATION` | 12 |
| J1 | `Jugs` | `JugsEven` | the tap fills the small jug one short | `SAFETY_VIOLATION` | 12 |
| J2 | `Jugs` | `JugsEven` | the tap fills the big jug one short | `SAFETY_VIOLATION` | 12 |
| J3 | `Jugs` | `Jugs` | the big-into-small pour moves nothing | `SAFETY_VIOLATION` | 12 |
| J4 | `Jugs` | `Jugs` | `Min` returns 0, so neither pour moves anything | `OK` | 0 |
| J5 | `Jugs` | `JugsEven` | the small-into-big pour gains a unit | `SAFETY_VIOLATION` | 12 |
| B1 | `BoxOffice` | `BoxOffice` | the room check becomes `TRUE` | `SAFETY_VIOLATION` | 12 |
| B2 | `BoxOffice` | `BoxOffice` | the room check allows one seat too many | `SAFETY_VIOLATION` | 12 |
| B3 | `BoxOffice` | `BoxOffice` | `NeverOversold` uses `<` instead of `<=` | `SAFETY_VIOLATION` | 12 |
| B4 | `BoxOffice` | `BoxOffice` | `TypeOK` narrows the codomain by one | `SAFETY_VIOLATION` | 12 |
| B5 | `BoxOffice` | `BoxOffice` | the sale adds one seat too many | `SAFETY_VIOLATION` | 12 |
| F1 | `Ferry` | `Ferry` | the failed crossing tips the load overboard | `SAFETY_VIOLATION` | 12 |
| F2 | `Ferry` | `Ferry` | the landing does not clear `aboard` | `SAFETY_VIOLATION` | 12 |
| F3 | `Ferry` | `Ferry` | loading takes the crate but never puts it aboard | `SAFETY_VIOLATION` | 12 |
| F4 | `Ferry` | `Ferry` | loading has no guard, so `near` goes negative | `SAFETY_VIOLATION` | 12 |
| F5 | `Ferry` | `Ferry` | `NothingLost` forgets what is aboard | `SAFETY_VIOLATION` | 12 |

24 killed, 1 inert.

**J3 is the inert one, and it earned its place.** It kills the big-into-small
pour by fixing `moved` at 0, and 4 litres is still reachable, so the stated
`SAFETY_VIOLATION` does not flip. I had predicted a kill and was wrong: the
small-into-big pour on its own still gets you there. Fill the small jug, pour it
across, fill it again, pour again, and the big jug reaches 4 without the other
pour ever being used. Keeping the mutant records that the two pours are not
independent, and J4 next to it is the version that does flip, because `Min`
returning 0 kills both pours at once. The pair together is what shows the
difference.

**Two mutants were replaced during the pass rather than kept as inert, and both
replacements are worth recording.**

The first J1 turned `Min` into a maximum. It came back `TIMEOUT` at rc=124
rather than any verdict, because a maximum lets the jugs overflow without
bound and the state space stops being finite. That is a real result and it is
cited in `COVERAGE.md` as the closest this set comes to touching theme 6, but a
timeout is not a clean flip of a stated outcome and it made a 25-state exercise
into a 60-second wait, so it was replaced with the short-fill edit that now
carries the id.

The first J4 removed the "fill the big jug" action. I expected the target to
become unreachable and it did not, for the same reason J3 does not flip: the
small-into-big pour still fills the big jug. It was replaced with the `Min`
edit, which is the only single substitution that reaches both pours.

Both replacements are the same lesson. On a spec whose whole subject is
nondeterminism, removing one route to a state usually leaves another, and a
mutant designed by reasoning about the spec needs to be run before it is
believed.

## Delivery seam

`scripts/deliver-exercises.sh` delivers `EXERCISES.md`, `LOG.md`, `starters/`
and the earlier chapters' cheat sheets. It never delivers `references/`,
`reports/`, `COVERAGE.md`, or chapter 7's own cheat sheet. So a module that
lives only in `references/` cannot be run by a learner, and a printed command
naming a `references/` path is a command nobody can execute.

Every exercise in this set therefore ships its module in `starters/`, and no
printed command anywhere in `EXERCISES.md` names `references/`.

Delivered into a scratch tree and every printed command run from it:

```
bash scripts/deliver-exercises.sh 7 .ch07-deliver
find .ch07-deliver -type f | sort
```

which places 18 files, 5 cheat sheets and `EXERCISES.md` and `LOG.md` and 11
starter files, and no `references/` or `reports/` or `COVERAGE.md`.

**As delivered, before the learner writes anything.** Run from
`.ch07-deliver/ch07`:

| Ex | Command as printed | Verdict | rc |
|---|---|---|---|
| 1 | `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Depot.tla -c starters/Depot.cfg` | `PARSE_ERROR` | 150 |
| 2 | `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Sluice.tla -c starters/Sluice.cfg` | `PARSE_ERROR` | 150 |
| 3 | `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Jugs.tla -c starters/Jugs.cfg` | `SAFETY_VIOLATION` | 12 |
| 3 | `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Jugs.tla -c starters/JugsEven.cfg` | `OK` | 0 |
| 4 | `bash ~/repos/tla-puzzles/harness/verdict.sh starters/BoxOffice.tla -c starters/BoxOffice.cfg` | `CONFIG_ERROR` | 151 |
| 5 | `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Ferry.tla -c starters/Ferry.cfg` | `CONFIG_ERROR` | 151 |

Exercise 3 is the one that reaches its stated outcomes with no work at all,
which is correct. It is a predict-then-check over a complete module.

The other four tokens are all named in `EXERCISES.md`, so none of them is a
surprise. `PARSE_ERROR` is what an unfilled `TODO` gives. `CONFIG_ERROR` is
what a config gives when it names invariants the file does not define yet, and
both write-from-prompt starters say so in their own header comment.

`pcal starters/Depot.tla` and `pcal starters/Sluice.tla` both translate
cleanly with the stubs still in place, which is the point of shipping those
starters pre-translated. `pcal` on the two write-from-prompt stubs refuses with
`Beginning of algorithm string --algorithm not found`, and `EXERCISES.md` says
so rather than leaving it to be discovered.

**Solved, in the same tree.** The four reference answers were copied over the
delivered starters and the printed commands re-run unchanged:

| Ex | Verdict | rc |
|---|---|---|
| 1 | `OK` | 0 |
| 2 | `OK` | 0 |
| 4 | `OK` | 0 |
| 5 | `OK` | 0 |

So every printed command resolves from the practice directory, and every one of
them reaches its stated pass verdict on a correct answer. The harness is named
by an absolute path and the modules by paths relative to the practice
directory, which is the combination that survives the practice tree being
somewhere other than the repo.

One thing the first delivery caught. `pcal` leaves `.old` backups beside every
file it translates, and three had accumulated in `starters/`. The delivery
script copies `starters/` recursively, so `Depot.old`, `Jugs.old` and
`Sluice.old` were handed to the learner. They are gitignored, so they would
never have reached a clean checkout, but they were in the tree the script read.
They were removed and the delivery re-run clean. Worth knowing for the next
chapter: translate, then sweep `*.old` before delivering.

## Chapter examples avoided

Read `docs/core/nondeterminism.rst` in full, 242 lines. Its own worked material,
none of which appears in this set:

- the deterministic `with tmpx = x, tmpy = y` swap (`nondeterminism.rst:30`)
- `with roll \in 1..6 do sum := sum + roll` (`:39`)
- the mixed-binding tip, `x \in BOOLEAN, y \in 1..10, z = TRUE` (`:50`)
- `with thread \in sleeping do sleeping := sleeping \ {thread}` (`:63`)
- the pull-request `either`, approve or request changes or reject (`:80`)
- the `request_resource` macro, `either reserved := reserved \union {r} or
  skip` (`:122`)
- the escalated `request_resource` with
  `reason \in {"unauthorized", "in_use", "other"}` (`:138`)
- `RequestType == [from: Client, type: {"GET", "POST"}, params: ParamType]` and
  the `if`/`elsif`/`assert FALSE` dispatch over it (`:153`)
- the calculator in all three versions: the digit adder, the add/subtract/
  multiply `either`, and `Invariant == sum # Target` with `Target <- 417` and
  `NumInputs <- 5` (`:173`, `:188`, `:198`)
- the closing aside that 851 is the smallest number unreachable in five inputs
  (`:234`)

Four places where this set runs structurally close to the chapter, declared
rather than hidden.

**Exercise 1 draws from a variable set, which is the chapter's `sleeping`
snippet.** Two lines of the chapter and unavoidable, because "the set can be a
variable" has one shape. What differs is what the pick feeds. The chapter's
snippet only removes from a set. Exercise 1 also appends to a sequence, so the
nondeterministic pick generates every loading order rather than every choice of
one element, and the two invariants are about the whole order rather than about
the set. The chapter never checks its snippet with a model at all.

**Exercise 4 draws a struct out of a struct set, which is the shape of
`RequestType`.** Also unavoidable: theme 4 is that shape. The payload differs,
seats and a tier against a client and an HTTP verb, and so does what happens
next. The chapter dispatches on a field with an `if`/`elsif` and an
`assert FALSE` on the impossible branch. Exercise 4 does not dispatch at all.
It applies a capacity guard, so the interesting orders are the ones that do not
fit rather than the ones with an unexpected type.

**Exercise 5 is `either or skip`, which is the `request_resource` macro.** The
chapter calls this a common pattern, and drilling a pattern means writing one.
The differences are that exercise 5 is not a macro, that the sad branch leaves
work in flight rather than simply not happening, and that it carries a
conservation invariant. The chapter's macro has no invariant, so the question
exercise 5 asks, which is what still has to be true once you have abstracted
the failure away, is not one the chapter asks.

**Exercise 3 uses an invariant that is false at the goal, which is the
calculator's move.** This is the closest call in the set and the one I would
argue about. It is theme 5, and theme 5 is that technique, so leaving it out
would leave the chapter's most surprising idea untested. Nothing of the
calculator's surface survives: no digits, no `0..9`, no arithmetic operator
choice, no `sum`, no `NumInputs`, no 417. The jug spec has two variables under
capacity bounds and six branches that fill, empty and pour. It also does
something the calculator never does, which is run the same module against a
second config where the goal is unreachable, so the learner sees `OK` as a
proof of impossibility and not just as the absence of an answer. That second
config is the half the chapter leaves on the page. Its own version of the idea
is the 851 aside at `:234`, which the chapter reaches with a shell script over
1000 model checks rather than with a spec.

## Scope check

Constructs used across the five references and the five starters, checked
against the `ch02` through `ch07` sheets.

| Source | Constructs used |
|---|---|
| ch02 | operator definition, `IF-THEN-ELSE`, `EXTENDS`, integers, strings, `BOOLEAN`, `=` and `#`, `=>`, `~`, sequences with `Len` and `Append`, sets, `\in`, `\union`, `\` set difference, `a..b`, `Cardinality`, set map |
| ch03 | `--algorithm`, `variables`, `:=`, `||`, labels, `while`, PlusCal `if`, `skip`, deterministic `with` |
| ch04 | `define` block, invariants, `\A` |
| ch05 | `CONSTANT`, `ASSUME`, model values, ordinary constant assignment in the `.cfg` |
| ch06 | struct literal, struct set, function literal, function set, indexed function update |
| ch07 | nondeterministic `with`, `either-or` |

Nothing from chapter 8 or later. No `process`, no `await`, no fairness
annotation, no temporal property, no hand-written `EXCEPT`, no `RECURSIVE`, no
`CHOOSE`.

Three things to flag rather than leave for a reviewer to find.

**Deadlock is deliberately kept out of exercise 1.** A nondeterministic `with`
over an empty set blocks, and the chapter's own note says so while pointing at
chapter 8. `Depot` draws from `waiting`, which does empty. Its loop guard
counts picks instead of testing the quay, so the guard is already false by the
time the set would be empty and the draw is never made on `{}`. The starter
tells the learner to leave the guard alone and says why in one line. Nothing in
the exercise, its stated fail run, or any of its five mutants reaches a blocked
`with`.

**`verdict.sh` does not check for deadlock unless asked.** The default is off,
per its own header. No command printed in `EXERCISES.md` passes
`-d`. That is consistent with keeping chapter 8 out, and it means `Jugs`, whose
`while (TRUE)` never terminates, gets a clean `OK` on the config where the
target is unreachable rather than a deadlock report.

**The translation is not chapter 7 material.** Every translated module carries
`Spec == Init /\ [][Next]_vars`, which is chapter 12. Four of the five
references also carry a `pc` variable and `UNCHANGED`, `Jugs` being the
exception because its single label on a `while (TRUE)` gives the translator
nothing to track. That has been true of every PlusCal exercise since chapter 3,
so none of it is new here.

What is new is that three starters ship pre-translated, `Depot` and `Sluice`
and `Jugs`, and the first two ask the learner to notice that the stub appears
twice. Those two exercises point at the translation block on purpose. Neither
asks the learner to read or edit what is in it, only to re-run `pcal` over it.
The other two starters, `BoxOffice` and `Ferry`, are module headers with no
algorithm and so carry no translation at all until the learner writes one.

## Type-stability check

TLC aborts evaluation on a cross-type comparison rather than returning `FALSE`,
so a drill can quietly turn into an evaluation failure instead of the verdict it
advertises. Every comparison in this set was written to stay on one type.

- `Depot` compares a set of model values to a set of model values in
  `Conserved`, and two integers in `NoRepeats`. `Crates` is a set of model
  values and nothing is ever compared to one except another one.
- `Sluice` compares booleans, and `steps` against an integer range.
- `Jugs` is integers throughout.
- `BoxOffice` compares integers. `order.tier` is used as a function argument
  rather than compared, and `TypeOK` is a `\in` on a function set rather than a
  comparison.
- `Ferry` is integers throughout.

No exercise mixes a string with a number anywhere, and none needs a phase test
or `ToString` to stay safe.

The seeded mutants back this up. All 25 came back on a verdict row, 0 or 10 or
12, and none landed on 75 or 76 or 255, which is what an aborted evaluation
would have produced. The one non-verdict result seen during authoring was the
replaced J1's `TIMEOUT` at 124, which is a state-space fact rather than a type
fact.

## Review checklist

Against `exercises/templates/REVIEW-CHECKLIST.md`:

- Each exercise fits its budget. 10 to 15 minutes, 61 total.
- Every statement is unambiguous. The `.cfg` files pin the constants and the
  invariant names, so a correct answer cannot miss its stated verdict on a
  naming difference.
- No construct is used before the chapter that introduces it. Table above.
- No exercise is a near-copy of a running example. Four structural overlaps
  declared above, with exercise 3 flagged as the closest call.
- The set covers the chapter's major themes. `COVERAGE.md` maps five of six to
  exercises and argues the sixth as an omission the harness cannot honestly
  check.
- Mutant evidence is present. This file, plus the seeder and runner beside it.
- Every expected outcome is verified through `harness/verdict.sh`. 41 runs in
  total: 6 reference rows, 25 mutants, 6 as-delivered rows from the practice
  tree, and 4 solved rows from the same tree.
- Delivered into a scratch tree and every how-to-run confirmed there. Section
  above, both as-delivered and solved.
