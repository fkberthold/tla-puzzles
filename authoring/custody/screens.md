# Screens run at domain selection — §6 step 0

Both screens, run before any authoring dispatch, on the domain as `DESCRIPTION.md` fixes it
(post-215c4c3). Step 4 re-runs both on the statement as worded. Passing here does not immunize
the domain.

## §5.7, the corpus screen — CLEAR, online

`harness/screen.sh "shared-custody calendars with holiday overrides"`, run online 2026-08-08.
Name collision: `SharedCustody language:tla`, 0 hits. Mechanism collision: no mechanism derived
from the phrasing. The tool says a no-derivation CLEAR is not a clean bill until the mechanism
is named by hand, so, from the krw5 review (drawer `0f6739db`): **two-party mutual consent over
a shared calendar, with a global cap on agreements and forward-only commitment.** Checked there
against the obvious priors and matching none: not two-phase commit (no coordinator, no
all-or-nothing across N, no abort), not a lock (nothing is held), not an allocator (nothing is
requested from a pool). tla-03d2's offline run agrees: CLEAR, none derived.

## §5.7b, the puzzle screen — ACCEPT, 8 of 8 system

Worked in order from `harness/PUZZLE-SCREEN.md`, column-A form (the learner writes the spec).

| # | Question | Answer |
|---|---|---|
| 1 | anything left to model? | **The actions themselves.** See below. |
| 2 | actions given or decided? | **Decided.** Granularity is the learner's. |
| 3 | what is asked? | **Is this design correct.** Nine properties to establish. |
| 4 | who works? | **Learner models, TLC checks.** Nothing is searched for. |
| 5 | difficulty? | **Abstraction choice.** The bound is about 358,000 states. |
| 6 | agents / failure? | **Three: two fallible parents and an undriven calendar.** |
| 7 | delete TLC, decision left? | **Yes.** The forks stand on their own. |
| 8 | names an optimum? | **No.** |

**Q1 in full.** The prose gives domain events: propose, accept, drop, a day beginning. It does
not give actions. Whether acceptance and the calendar flip are one step, whether voiding is its
own step or rides the day-beginning (the description proves the second and a learner must
rediscover why), what state a pending proposal is — those are the learner's decisions, and the
declared forks (state-or-derived custody, baseline, swap record) are open on top of them.

**Q6 in full.** Two parents act concurrently and fallibly: proposals cross, a proposal can race
the day it names, a drop can race an acceptance. The calendar is a third actor no party drives.
That is the several-fallible-agents answer, and it is the domain's own texture rather than a
rescue bolted on.

**KIND VERDICT: ACCEPT — system.** In my words: hand a learner the legal moves of this domain
and the modeling is still ahead of them, because the moves are events and not actions, and the
description's forks are exactly the decisions a spec cannot avoid making.

## R, the route — ACCEPT at domain level, three probes deferred to step 4

The intended route: decide the custody-state representation (the central fork), decide action
granularity for propose, accept, drop, and day-begin, render the nine properties over an
`Observe` the learner shapes within the statement's interface typing, then let TLC surface the
acceptance-versus-day-begin race and the void-at-begin coupling. That route runs through the
declared forks and the race, which is the judgment a column-A problem is for. I see no shorter
route at domain level: the properties are not diffable against anything the learner receives,
and no answer form exists yet to narrow them.

Honest bound: tiling, the answer form, and pre-clearing are statement-and-artifact probes and
cannot run before steps 1 and 4. They run at step 4 on the statement as worded. Recall is empty
here (§5.7 CLEAR, no mechanism prior to hand anything over).

**ROUTE VERDICT: ACCEPT, provisional to step 4's re-run.**

Recorded by central, 2026-08-08. Step 0 gate: both verdicts recorded, domain proceeds.
