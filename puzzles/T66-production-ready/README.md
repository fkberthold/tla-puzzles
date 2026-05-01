# T66: Tier 7 Capstone — Production-Ready Spec ⭐⭐⭐

## Lesson: The Whole Production-Craft Toolkit, in One Spec

No new concept. This capstone composes everything Tier 7 introduced:

- **R12** — refinement instances (review)
- **R13** — boundary values: choose the smallest constants that exercise every distinguishable case
- **T60** — SYMMETRY for orbit reduction over interchangeable model values
- **T61** — VIEW for projecting away state that doesn't affect safety
- **T62** — model values vs. concrete values: which to use when
- **T63** — `-coverage` to verify every action actually fires
- **T64** — `-simulate` for state spaces too large for BFS
- **T65** — `-difftrace` for readable counterexamples

A "production-ready" spec uses all of these together. Industrial specs check in seconds, not days, because their authors picked tight bounds, declared interchangeable processes as model values, applied SYMMETRY, projected away ephemeral state with VIEW, ran `-coverage` to confirm full code coverage, and used `-simulate` for sanity checks at production scale.

This capstone gives you a small but realistic spec — a job scheduler — with all of these techniques applied. Your task is to read, run, and INSPECT each technique in turn so the composition crystalizes.

## Setup

A pre-written abstract spec lives in `solution/Scheduler.tla`. It models a job scheduler with:

- A set of `Jobs` (model values, declared as `CONSTANT`).
- A `queue` of jobs waiting to run.
- A set of `running` jobs (bounded by `WorkerSlots`, a tight constant).
- A set of `completed` jobs.
- A `log` recording every schedule and complete event (this is the variable VIEW projects away).

The spec checks three invariants:

- `TypeOK` — basic shape constraint
- `Conservation` — every job is in exactly one of queue/running/completed
- `SlotBound` — at most `WorkerSlots` jobs are running at once

The cfg applies:

- **Boundary values** — `WorkerSlots = 1` (defined inside the spec; one is enough to exercise contention; larger values would only inflate the state space).
- **Model values** — `Jobs = {j1, j2, j3}` declared in cfg.
- **SYMMETRY** — `JobSym == Permutations(Jobs)` so all jobs are interchangeable.
- **VIEW** — `Project == << queue, running, completed >>` collapses the `log` away.

## Task

### Step 1 — Run it as production

```bash
cd solution
tlc -coverage 1 Scheduler
```

Expected output:

- "No error has been found." All invariants pass.
- "7 distinct states found, depth 7."
- A coverage report at the end. Every action (`Schedule`, `Complete`, `Done`) has nonzero firing counts. No dead code.

### Step 2 — Measure each reduction's contribution

Edit `Scheduler.cfg` to remove `SYMMETRY JobSym` (keep VIEW). Re-run. State count.

Edit again to remove `VIEW Project` (no SYMMETRY, no VIEW). Re-run. State count.

Edit again to keep only SYMMETRY (no VIEW). Re-run. State count.

Restore both. Compare.

Now bump `Jobs` to `{j1, j2, j3, j4}`. Re-run with both reductions, then with neither. Note how the gap widens — at scale, SYMMETRY+VIEW make a huge difference.

### Step 3 — Try `-simulate`

```bash
tlc -simulate num=10 -depth 50 Scheduler
```

Confirms the spec passes invariants on randomized walks.

### Step 4 — Force a violation, inspect the trace

In `Scheduler.tla`, change the body of `Schedule` so it ALWAYS sets `running' = running` (forgetting to add the new job). Save and re-run:

```bash
tlc Scheduler
tlc -difftrace Scheduler   # cleaner trace
```

The Conservation violation should have a 2-state trace (initial → schedule → bad). Restore the original `Schedule`.

## Check

| Run | Distinct states (Jobs=3) | Distinct states (Jobs=4) |
|-----|--------------------------|--------------------------|
| No reduction | 31 | 129 |
| SYMMETRY only | 7 | 9 |
| SYMMETRY + VIEW | 7 | 9 |
| VIEW only | 31 | 129 |

For Jobs=4, the difference is 14× — and grows superlinearly with bigger Jobs.

The full production run reports:

- Jobs=3, SYMMETRY+VIEW: **7 distinct states**, depth 7, 0 errors.
- All actions have nonzero coverage in the `-coverage` report.
- Conservation, TypeOK, SlotBound all pass.

## Expected Result

After working through every step, you should be able to:

- Recognize `CONSTANT Jobs = {j1, j2, j3}` (model values) at a glance and explain why those tokens are the right choice (interchangeable, only equality used).
- Recognize `SYMMETRY JobSym` and explain why `Permutations(Jobs)` is sound here (no job is privileged).
- Recognize `VIEW Project` and explain why it's safe (log isn't tested by any invariant).
- Read a `-coverage` report and identify any zero-coverage actions.
- Choose `-simulate` over BFS at production scale, and `-difftrace` over default tracing for wide states.

## What to take away

- Production specs combine boundary values, model values, SYMMETRY, and VIEW from the start. Adding them after the fact is mechanical but tedious.
- `-coverage` is the spec equivalent of test coverage: a low number warns you that something isn't being exercised.
- `-simulate` extends reach when BFS hits its scaling wall.
- `-difftrace` is free — always use it on wide-variable specs.
- These techniques are independent. Use whichever fit. Skip whichever don't.
- Tier 7 is the last tier of CORE TLA+. Apalache (parallel track) and judgment intersticials extend the toolkit horizontally.
