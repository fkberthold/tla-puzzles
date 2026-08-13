# Cold-solve review: ch.8 exercise set

Bead `tla-jb7f.20`. Second-agent cold-solve review, per `exercises/templates/REVIEW-CHECKLIST.md`.

Toolchain: `TLC2 Version 2026.07.31.184830` [`tlc` → "TLC2 Version 2026.07.31.184830 (rev: 30cc360)"]. Repo `tla-puzzles`, worktree `.claude/worktrees/agent-ad52d62e3d3867dae`, branch `worktree-agent-ad52d62e3d3867dae` [`git remote -v`, `git rev-parse --show-toplevel`, `git branch --show-current`].

## Methodology note: a self-inflicted blinding breach, and the recovery

Phase 1 called for solving exercises 2 and 5 (predict-then-check) without reading past their "Run before you read on" line. I read the whole delivered `EXERCISES.md` in a single tool call, which put both reveal sections in view before I wrote any prediction. This is my own tool-use mistake, not a property of the exercise set. A human reading the file in an editor or pager would simply stop scrolling at the marker.

Recovery: I dispatched two fresh, isolated sub-agents, each given only the non-spoiler task text and the relevant starter module, explicitly told not to read `EXERCISES.md`, search the web, or look anything up. Both returned predictions before I ran anything. [command: `Agent` tool, two `general-purpose` dispatches, "Blind prediction for KitchenLocks exercise" and "Blind prediction for BellTower exercise"] Both predictions matched the exercise's intended answers exactly, with correct reasoning:

- KitchenLocks: Q1 `OK` (same acquire order, loser just waits), Q2 `DEADLOCK` (crossed acquire order, circular wait).
- BellTower: Q1 `OK` (RightTotal only reads names in scope at the `define` block), Q2 `PARSE_ERROR` (`left` not yet declared at that point in the source).

I recorded these in the delivered `LOG.md` before running TLC, consistent with the exercise's own instruction, and then ran the actual pass/fail cases myself. This does not compromise the verdict evidence below, only the "was the prediction genuinely blind" quality of Ex2/Ex5's log entries, which I flag here rather than silently paper over.

## Phase 1: solve log

Delivered via `bash scripts/deliver-exercises.sh 8 <mktemp-dir>` [`scripts/deliver-exercises.sh 8 /tmp/tla-ch08-delivered.4Pe232` → exit 0, tree holds `EXERCISES.md`, `LOG.md`, `starters/` with 8 files, `cheatsheets/ch02.md`..`ch07.md`, no `references/`, no `COVERAGE.md`, no `reports/`, no ch08 `CHEATSHEET.md`]. Worked only inside that tree for Phase 1. All times below are agent-speed wall-clock (`date +%s` before/after each run), not a proxy for human novice pacing. They are cited to show no exercise took repeated failed attempts, not to assert the stated budgets hold for a person.

### Exercise 1, Seat desk (complete-the-skeleton)

Start 1786582617, end 1786582727 (1.8 min) [`date +%s` × 2]. Filled the three TODOs (`NeverOversold == seats >= 0`, `BooksBalance == seats + sold = Capacity`, the three-statement `Look` body). No ambiguity, no snag.

- Pass run: `OK` [`bash harness/verdict.sh starters/SeatDesk.tla -c starters/SeatDesk.cfg` → `OK`]. Matches stated outcome.
- Fail run (split `Look` into `Look:`/`Book:`): `SAFETY_VIOLATION` rc=12 [same command after edit → exit 12, `SAFETY_VIOLATION`]. Matches stated outcome.

### Exercise 2, Two cooks one whisk (predict-then-check)

Start 1786583014, end 1786583053 (0.65 min of my own run time; prediction produced by the recovery sub-agent, 16.5 s dispatch-to-completion, run in parallel with my Ex1/3/4 work). Prediction written to `LOG.md` before either run.

- Pass run (as shipped): `OK` [`bash harness/verdict.sh -d starters/KitchenLocks.tla -c starters/KitchenLocks.cfg` → `OK`]. Matches prediction and stated outcome.
- Fail run (cook takes whisk first): `DEADLOCK` rc=11 [same command after swapping the cook's two labels → exit 11, `DEADLOCK`]. Matches prediction and stated outcome.

### Exercise 3, Cloakroom (write-from-prompt)

Start 1786582733, end 1786582903 (2.8 min). Wrote from scratch: `Hooks == 1..2`, `Guests == 1..3`, `free`/`coat`, the two invariants, one process set with the `if`-guarded `Hang` label.

One design choice worth recording: the task says the guest "picks a hook out of `free` with `CHOOSE`" without saying whether to bind the result. I used `CHOOSE` twice in the same label (`coat[CHOOSE h \in free : TRUE] := self;` then `free := free\{CHOOSE h \in free : TRUE};`), reading the same unchanged `free` both times, rather than a `with (h = ...)` binding, since the task names `CHOOSE` specifically. This differs from the shipped reference (see NOTE-1 below) but both are correct.

- Pass run: `OK` [`bash harness/verdict.sh starters/Cloakroom.tla -c starters/Cloakroom.cfg` → `OK`]. Matches stated outcome.
- Fail run (drop the `if` guard): `SPEC_EVAL_FAILURE` rc=75 [same command after edit → exit 75, `SPEC_EVAL_FAILURE`]. Matches stated outcome.

### Exercise 4, Stamp desk (write-from-prompt)

Start 1786582906, end 1786583009 (1.7 min, includes one stuck point). Wrote `procedure Stamp(copies)` with local `made`, and a `process (clerk \in Clerks)` calling it.

Stuck point: named the post-`call` label `Done`, following the chapter's own heavy use of that literal string as the terminal `pc` value (e.g. `pc = "Done"` appears repeatedly in ch02-ch07 material). `pcal` refuses it outright: `Unrecoverable error: -- Cannot use 'Done' as a label. line 35, column 5.` [`pcal starters/StampDesk.tla` with `Done:` in place → exit with that error]. Renamed to `AfterStamp` and moved on. See DEFECT-2 below.

- Pass run: `OK` [`bash harness/verdict.sh starters/StampDesk.tla -c starters/StampDesk.cfg` → `OK`]. Matches stated outcome.
- Fail run (`call Stamp(3)`): `SAFETY_VIOLATION` rc=12 [same command after edit → exit 12, `SAFETY_VIOLATION`]. Matches stated outcome.

### Exercise 5, Bell tower (predict-then-check)

Start 1786583058, end 1786583111 (0.88 min of my own run time; prediction produced by the recovery sub-agent, 322.9 s dispatch-to-completion, run in parallel with my Ex1/3/4 work). Prediction written to `LOG.md` before either run.

- Pass run (as shipped): `OK` [`bash harness/verdict.sh starters/BellTower.tla -c starters/BellTower.cfg` → `OK`]. Matches prediction and stated outcome.
- Fail run (add `EarlyTally` under `RightTotal`): `PARSE_ERROR` rc=150 [same command after edit → exit 150, `PARSE_ERROR`]. Matches prediction and stated outcome.

All ten stated outcomes (5 exercises × pass + fail) reproduced exactly, including the DEADLOCK fail run. All five "how to run" command blocks in `EXERCISES.md` work verbatim from the delivered tree, including exercise 2's `-d` flag as printed.

## Phase 2: open-book findings

Opened `exercises/ch08/references/`, `exercises/ch08/reports/authoring.md`, `exercises/ch08/COVERAGE.md`, `exercises/ch08/CHEATSHEET.md`, and a shallow clone of `hwayne/learntla-v2` pinned to `09840bfc2ee9a88cdbedb672be77a6c73942fe16` [`git rev-parse HEAD` in the clone → `09840bfc2ee9a88cdbedb672be77a6c73942fe16`, exact match].

### DEFECT-1: chapter-citation errors in the scope check

`exercises/ch08/reports/authoring.md:266-270` ("Scope check") and `exercises/ch08/COVERAGE.md:74-76` (the "Macros" documented omission) attribute several constructs to the wrong chapter, checked against this project's own `exercises/ch0N/CHEATSHEET.md` files, which this project's own `docs/core/index.rst` toctree confirms are numbered in the upstream book's actual order (`setup, operators, pluscal, invariants, constants, functions, nondeterminism, concurrency, ...` = ch01..ch08) [`/tmp/learntla-v2-clone.../docs/core/index.rst:54-71`, toctree].

| Construct | authoring.md/COVERAGE.md claims | Actual, per this project's cheat sheets |
|---|---|---|
| `CHOOSE` | ch04 (`authoring.md:268`) | ch02 [`exercises/ch02/CHEATSHEET.md:87-89`; `exercises/ch04/CHEATSHEET.md:44` itself says "CHOOSE and LET...IN... is covered in chapter 02 instead"] |
| `Cardinality` | ch04 (`authoring.md:268-269`) | ch02 [`exercises/ch02/CHEATSHEET.md:63-65`] |
| deterministic `with (h = ...)` | ch05 (`authoring.md:269`, `COVERAGE.md:71`) | ch03 [`exercises/ch03/CHEATSHEET.md:47-49`] |
| `if` / `while` | ch05 (`authoring.md:269-270`) | ch03 [`exercises/ch03/CHEATSHEET.md:39-41,51-53`] |
| `skip` | ch05 (`authoring.md:270`) | ch03 [`exercises/ch03/CHEATSHEET.md:27-29`] |
| `macro` | ch05 (`COVERAGE.md:75`) | ch03 [`exercises/ch03/CHEATSHEET.md:43-45`] |
| `\A` | ch07 (`authoring.md:270`) | ch04 [`exercises/ch04/CHEATSHEET.md:23-25`] |
| `define` blocks and invariants | ch07 (`authoring.md:270`) | ch04 [`exercises/ch04/CHEATSHEET.md:15-17`, chapter title itself is "Writing an Invariant"] |
| `CONSTANT` and model values | ch03 (`authoring.md:266-267`) | ch05 [`exercises/ch05/CHEATSHEET.md:11-13,19-21`] |

Two citations in the same paragraph checked out correctly: function literals/update at ch06 (`exercises/ch06/CHEATSHEET.md:24,45`), and nondeterministic `with x \in set` at ch07 (`exercises/ch07/CHEATSHEET.md:11-13`).

None of this creates an actual prerequisite leak: every corrected chapter is still ≤ ch08, so no construct used in this set was really introduced after chapter 8. But the scope-check paragraph is the section whose entire job is to let a reviewer verify that claim against the cheat sheets, per the checklist's own wording ("Check this against the cheat sheets"), and most of its named citations are wrong when actually checked. That is a defect in the authoring evidence, independent of whether the underlying scope claim happens to still be true.

### DEFECT-2: undocumented reserved label trap in Exercise 4

`exercises/ch08/EXERCISES.md`'s Exercise 4 task tells the learner to add a second label after the `call` (`"The second label is not decoration..."`) but never names it. The chapter's own material repeatedly uses the literal string `"Done"` as the natural terminal-state name (e.g. `pc = "Done"` in `exercises/ch04/CHEATSHEET.md:36`, and throughout the pinned clone's `docs/core/*.rst`, none of which ever warns that a learner cannot reuse that name as their own label). `pcal` rejects a user label literally named `Done` outright, with no explanation of why: `Cannot use 'Done' as a label.` I hit this myself in Phase 1 [reproduced: `pcal starters/StampDesk.tla` with `Done:` as the label → error at line 35, column 5]. Searched the full pinned clone for any warning about this restriction: none found [`grep -rn "Done" docs/core/*.rst docs/core/advanced/*.rst`, no hit describes it as reserved]. Cost was low (one failed `pcal` run, one rename), but it is exactly the class of thing Phase 1 exists to catch: an instruction that leaves a natural-seeming choice unnamed, and the natural choice fails for a reason nothing in the delivered material or the source chapter explains.

### NOTE-1: Exercise 3's CHOOSE-vs-with freedom (not a defect)

The task text names `CHOOSE` but not a binding form. The shipped reference and mutant seeder use `with (h = CHOOSE x \in free : TRUE)` [`exercises/ch08/references/Cloakroom.tla:25`, `exercises/ch08/reports/mutants.py:84`]. My own solve used two direct `CHOOSE` calls instead, which is also correct PlusCal and reproduced the exercise's stated pass/fail verdicts. Recording this only because it is a case where the instructions leave real freedom in the implementation, not a case where they leave a wrong answer possible.

### NOTE-2: BUDGET, no breach observed but worth watching on Ex4

My own times are agent-speed and not a valid stand-in for a human novice's pacing, so I cannot assert the 10-15 min budgets hold or breach for a person. Two things compound specifically on Exercise 4: the chapter ships `procedure`/`call`/`return` with a bare `.. todo:: * An example` and no worked example anywhere [`docs/core/advanced/procedures.rst:50-52`, confirmed in the pinned clone], and DEFECT-2 above. A human hitting the `Done` trap with no worked example to fall back on has less to recover with than on any other exercise here. No hard evidence of an actual breach, flagged as a NOTE rather than a DEFECT.

### COVERAGE: holds

Checked `exercises/ch08/COVERAGE.md`'s theme table and construct table against my own solve and the reference files. All six major themes and all ten listed constructs map to the exercise claimed, confirmed by direct inspection of the reference `.tla` files [`exercises/ch08/references/*.tla`] and by my own Phase 1 solves. The documented omissions (liveness, nondeterministic `with x \in set`, macros, `self` inside a macro, model values as process values) all check out against the pinned clone at the cited line numbers, modulo the macro chapter mis-citation already covered in DEFECT-1. No exercise states a state count anywhere in `EXERCISES.md`, consistent with the "representation-robust" rule COVERAGE.md and EXERCISES.md both state.

### NEAR-COPY: holds

Compared all five modules against `docs/specs/reader_writer/*/reader_writer.tla` (all revisions, especially `rw_await_2`) and `docs/specs/threads/*/threads.tla` (all revisions) in the pinned clone. No surface-level copy in variable names, structure, or failure mechanism:

- SeatDesk's overselling race (check-then-act on a bounded count) differs from threads' lost-update race (read-modify-write on a shared counter via a local temp).
- KitchenLocks' two-resource lock-ordering deadlock has no analog in either worked example; `rw_await_2`'s deadlock is a reader permanently blocked on a queue that stops refilling, a different mechanism entirely, and threads never uses two locks.
- Cloakroom's `if`-guarded empty-set case is the "skip" option from `concurrency.rst`'s own list of choices; the worked example (`rw_await_1`) instead exercises the "block via `await`" option. Different mechanism, different data structure (sets/functions vs. sequences).
- StampDesk has no worked example to copy from at all (procedures.rst ships a bare `.. todo::`).
- BellTower's `RightTotal` invariant shares the `AllDone => correct` shape with threads' `Correct`, which `authoring.md:249-253` names as the one deliberate structural echo and justifies (no other way to state a final-result property without chapter-9 liveness). BellTower adds a loop and a process-local countdown that threads/1 (the atomic baseline) does not have, and has no lock, no shared temp, and no race, unlike threads/2-4. Justified, not a copy.

### EVIDENCE: holds, reproduced independently

Re-ran the seeder and the mutant runner:

- `python3 exercises/ch08/reports/mutants.py` → all 22 mutants seeded, zero `SEED-ERROR` lines.
- `bash exercises/ch08/reports/run-mutants.sh` → 21 of 22 rows flip away from `OK`, matching `authoring.md`'s table row for row (`S1-S4` all `SAFETY_VIOLATION`, `K1-K4` all `DEADLOCK`, `C1` `SPEC_EVAL_FAILURE`, `C2-C4` `SAFETY_VIOLATION`, `T1` `SAFETY_VIOLATION`, `T2` `OK` (the documented inert one), `T3-T5` `SAFETY_VIOLATION`, `B1` `PARSE_ERROR`, `B2-B5` `SAFETY_VIOLATION`).
- `bash exercises/ch08/reports/run-refs.sh` → all five references `OK`, matching `authoring.md`.
- T2 verified myself with a `-d` run: `bash harness/verdict.sh -d .ch08-mut/T2/StampDesk.tla -c .ch08-mut/T2/StampDesk.cfg` → `DEADLOCK` rc=11, matching the "silent `pc'=Error` wedge, `OK` without `-d`, `DEADLOCK` with it" claim exactly [both runs cited above: plain run in `run-mutants.sh`'s table → `OK` rc=0, my own `-d` run → `DEADLOCK` rc=11].
- Spot-checked the unfilled `SeatDesk` skeleton claim in a fresh delivery: `pcal starters/SeatDesk.tla` on the untouched skeleton → `Unrecoverable error: -- Expected ":=" but found ";". line 33, column 13.`, matching `authoring.md`'s citation exactly.

Every stated outcome in `EXERCISES.md` was run at least twice, independently, by two different paths (my own Phase 1 solve and the committed reference/mutant), and both paths agree in all ten cases plus all 22 mutants.

## Verdict

**SEND BACK.** Two DEFECTs: DEFECT-1 (chapter-citation errors across most of the authoring report's scope-check paragraph and one COVERAGE.md line) and DEFECT-2 (the undocumented `Done`-as-reserved-label trap in Exercise 4, which I hit myself). Neither invalidates the underlying spec work: every stated pass/fail outcome reproduced exactly, mutant evidence is solid, coverage holds, and no near-copy was found. Both defects are narrow and fixable in a single repair round: correct the chapter numbers in `authoring.md:266-270` and `COVERAGE.md:74-76`, and either name Exercise 4's second label in `EXERCISES.md` or add one line warning that a fresh label name is needed there.
