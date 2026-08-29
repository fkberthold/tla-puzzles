# Cold-solve review: ch.13 exercise set, Modules

Bead `tla-jb7f.28`. I solved all four exercises blind from a delivered scratch
tree, then read the answer key. Verdict is **PASS** on all four. Five findings
follow, none of them in the four SEND BACK classes.

## How this run was done

Phase 1 solved blind from a delivered tree
[cmd: `bash scripts/deliver-exercises.sh 13 <scratch>`, exit 0, `find` over the
result returned 25 files: `EXERCISES.md`, `LOG.md`, 12 starters, and
`cheatsheets/ch02.md` through `ch12.md`]. Nothing from `references/`,
`reports/`, `COVERAGE.md`, or ch.13's own sheet landed there, and I read none of
those four until phase 1 closed.

Every how-to-run command ran from the delivered chapter directory, as printed,
against the main checkout's harness. That harness is byte-identical to the one
in my worktree [cmd: `diff -q harness/verdict.sh /home/frank/repos/tla-puzzles/harness/verdict.sh`,
exit 0].

Toolchain is the pinned build [cmd: `tlc`, printed
`TLC2 Version 2026.07.31.184830 (rev: 30cc360)`].

### The spoiler trap, and how I stayed out of it

Three of five wave-2 reviewers spoiled their own exercise 2 prediction by
reading `EXERCISES.md` in one pass. I never opened the delivered file whole.
I listed its headings first, found the single `### After the run` block at lines
125 to 158, and cut that range plus the closing section into a stripped working
copy [cmd: a `grep -n` for markdown headings, then `sed '125,158d'`]. The
stripped copy holds no After-the-run text [cmd: `grep -c 'After the run'`,
printed `0`, exit 1].

I wrote both exercise 2 predictions to a file, with reasoning, before the first
TLC run of that exercise. The prediction file is timestamped 17:47:51 and the
first run followed it.

## Exercise 2: the prediction, and what happened

Written before the run, verbatim:

> P1. As it stands (bare `INSTANCE Palette` in Signal.tla): OK
>
> P2. With `LOCAL INSTANCE Palette`: PARSE_ERROR

The reasoning I recorded for P1 was that an unnamed `INSTANCE` with no `WITH`
incorporates Palette's definitions as definitions of Signal, and a non-local
incorporated definition is itself exported. For P2, that `LOCAL` stops the
re-export, so `Escalated` still compiles inside Signal while `IsWarm` no longer
reaches Beacon.

Both landed. P1 gave `OK` and P2 gave `PARSE_ERROR`
[cmd: `bash ~/repos/tla-puzzles/harness/verdict.sh starters/Beacon.tla -c starters/Beacon.cfg`,
printed `OK` rc=0, then `PARSE_ERROR` rc=150 after the one-word edit]. SANY
names the operator I expected [cmd: `tlc -config Beacon.cfg Beacon.tla`, line 29
of the capture reads ``Unknown operator: `IsWarm'.``].

I also ran the optional third run from the After-the-run section. Narrowing
`Warm` to one colour gives `SAFETY_VIOLATION` [cmd: same harness line, rc=12].

I think the exercise is well built. The reveal only works if you have committed
to an answer, and the task text says so plainly enough that I committed without
being told twice.

## Per-exercise verdict

| # | Title | Verdict | Pass run | Fail run | Clock |
|---|---|---|---|---|---|
| 1 | Rules in their own file | PASS | `OK` rc=0 | `PARSE_ERROR` rc=150 | 43 s |
| 2 | How far a name travels | PASS | `OK` rc=0 | `PARSE_ERROR` rc=150 | 49 s |
| 3 | Two rooms, one range | PASS | `OK` rc=0 | `SAFETY_VIOLATION` rc=12 | 80 s |
| 4 | The rate arrives late | PASS | `OK` rc=0 | `SAFETY_VIOLATION` rc=12 | 13 s |

Every stated outcome reproduced on the first try, from the delivered tree, with
the printed command. No exercise needed a command the file didn't print.

The clock column is agent tool-loop wall time, not a human stopwatch, so it
doesn't compare to a 10 to 15 minute budget on its own. What it shows is that no
exercise cost me a backtrack, a re-read, or a failed run on the way. The budget
judgement below rests on that, not on the seconds.

### Budgets

No breach. Exercise 3 is the tightest of the four, and I think 15 minutes is
right rather than generous. A learner writing a module from scratch has to get
`INSTANCE ... WITH` syntax correct before anything else runs, and a first miss
there costs a parse cycle. The other three are three short lines or two
predictions each, well inside 12 and 10 minutes.

### Ambiguity

None that made me guess. The strongest evidence is exercise 3, the only
write-from-prompt in the set. My cold answer and the shipped reference differ in
two identifier names and one line break, and in nothing else
[cmd: `diff -u exercises/ch13/references/Cellar.tla <my cold answer>`, the hunk
renames `WineDrifts` to `WineStep`, swaps an explicit stutter for `UNCHANGED`,
and splits one conjunction across two lines]. Two independent solvers reaching
the same spec from six numbered requirements is what an unambiguous prompt looks
like.

Exercise 4's `TODO_2` is the one place I expected trouble, because the task
tells you not to name `Base` in the `WITH` clause and that reads like a typo
until you know the pass-through rule. The task text points at it directly, and
the `.cfg` comment says the same thing again [`exercises/ch13/starters/Garage.cfg:1`].
That's the lesson, stated twice, not a gap.

### Prerequisite leak

None. Every construct in the set is citable against a delivered sheet.
`DOMAIN` is ch.06 [`cheatsheets/ch06.md:19`], `ASSUME` is ch.05
[`cheatsheets/ch05.md:15`], and `EXCEPT` and `UNCHANGED` are ch.12
[cmd: `grep -rln 'EXCEPT' cheatsheets/`, returned `ch12.md` only]. The seven
chapter-13 constructs come from the chapter the learner just read.

### Near-copy

None. The chapter runs on `Point` and `Sequences`. The set runs on a loading
dock, a signal beacon, a wine and beer cellar, and a parking garage. Exercise 4
shares the shape of the chapter's `XAxis(X) == INSTANCE Point WITH Y <- 0`,
which partial parameterization can't avoid, but it pins the other constant and
adds a second instance exercising pass-through. Different surface, different
point.

Exercise 2 is the case worth naming, because it teaches the same rule
`Sequences.tla` teaches with `Naturals`. It builds an independent three-file
chain first and points at `Sequences` only afterward, in the After-the-run
prose. That's the right order.

### Delivery seam

Clean, and this is the class that produced all five wave-1 defects. Every
`starters/` path `EXERCISES.md` names lands in the delivered tree
[cmd: a `grep -o` for `starters/` paths in `EXERCISES.md`, piped through
`sort -u`, 16 hits]. The two that don't land are meant not to:
`starters/Cellar.tla` is what exercise 3 asks you to write, and
`starters/YourSpec.tla` is the placeholder in the how-to-run section. Modules
are multi-file and the set is 12 starters, so I expected to find something here.
I didn't.

## The ASSUME question

The set teaches around it honestly, and no exercise depends on an `ASSUME`
firing. The only `ASSUME` in the whole set is `Band.tla`'s
[cmd: `grep -rn 'ASSUME' exercises/ch13/starters/`, one hit], and every
instantiation in every stated outcome satisfies it, including the fail run that
moves the upper bound from 14 to 11.

I reproduced the non-firing myself before reading the key. Adding
`BadBand == INSTANCE Band WITH Lo <- 99, Hi <- 1` to a working `Cellar.tla` runs
green [cmd: `tlc -config Cellar.cfg Cellar.tla`, rc=0, and a case-insensitive
`grep` for `Assumption` over the capture returned nothing, exit 1].

I also ran the half the material doesn't have. A module carrying an `ASSUME`
that its lower bound sits at or below its upper bound, run directly with
`Lo = 99` and `Hi = 1` in its `.cfg`, does fail
[cmd: `tlc -config Direct.cfg Direct.tla`, rc=10, printed
`Error: Assumption line 4, col 8 to line 4, col 15 of module Direct is false.`].
So the scoping is sharper than the closing section claims. On this build an
`ASSUME` in the root module is checked, and only the ones reached through
`INSTANCE` are skipped. That's worth handing to bead `tla-byo5`.

## Findings

**F1, LOW, `reports/authoring.md`.** The delivered-file counts are off by one.
The report says "eleven starter files" and "twenty-four files", and delivery
places 12 and 25 [cmd: `find <fresh-delivery> -type f | wc -l`, printed `25`,
and the same over `starters/` printed `12`]. Nothing downstream depends on it,
but it sits in the file whose job is to be the evidence.

**F2, MEDIUM, `EXERCISES.md`.** The `ASSUME` correction is placed behind the
learner who needs it. It sits in the closing section at line 234, after exercise
4, and exercise 3's own text never mentions `ASSUME` at all
[cmd: `grep -n 'ASSUME' exercises/ch13/EXERCISES.md`, hits at 234 and 240 only].
Meanwhile the delivered ch.05 sheet tells the learner that `ASSUME` "documents
and enforces valid constant values before a run starts"
[`cheatsheets/ch05.md:47`]. A learner sitting in exercise 3, reading `Band.tla`
with that sheet open, has every reason to think the `ASSUME` guards their `WITH`
clause. I'd add one forward pointer from exercise 3 to the closing section. This
is the only finding I'd act on before shipping.

**F3, LOW, `EXERCISES.md`.** Exercise 3 says the numbers 10, 14, 2 and 6 "should
each appear exactly once in your file, on the instance lines". Requirement 3 of
the same task has you write `wine = 12`, so a learner checking the rule
mechanically finds a second `2`. The intent reads clearly and I followed it
without trouble. The wording just isn't true under the check it invites.

**F4, LOW, cross-cutting.** The delivered `LOG.md` carries an `Ex5:` line and
ch.13 has four exercises. It comes from the shared template
[`exercises/templates/LOG.md:12`], so it hits ch.04 the same way
[cmd: `grep -c '^## Exercise ' exercises/ch*/EXERCISES.md`, ch04 and ch13 both
returned 4]. Not ch.13's to fix alone.

**F5, process.** My brief named the deliverable
`exercises/ch13/reports/cold-solve-review.md`, and all ten sibling chapters use
`cold-solve.md` [cmd: `find exercises -name 'cold-solve*.md'`, `ch02` through
`ch11` all returned `cold-solve.md`, and this file is the only other hit]. I
followed the brief because the commit command names that path. Rename it if
consistency matters more.

## Two things I checked that came back clean

`NeitherRoomOverfull` is implied by `BothInBand`, so it can never fail on its
own in the shipped set. I went looking for it as dead weight and it isn't.
Mutant C5 reverses `Headroom`'s subtraction and does fire it
[`exercises/ch13/reports/authoring.md:66`], so the invariant carries real load
under the sweep.

I spot-checked two mutants I hadn't seen the mechanism for. G2 adds `Base <- 0`
to the `Flat` instance and gives `SAFETY_VIOLATION` rc=12. B4 swaps
`EXTENDS Signal` for `EXTENDS Palette` and gives `PARSE_ERROR` rc=150. Both
match the table [`exercises/ch13/reports/authoring.md:68` and `:60`].
