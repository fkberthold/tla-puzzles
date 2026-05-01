# J05: Judgment — Choosing Fairness Type ⭐⭐

**Judgment puzzle.** No new syntax. The goal: when you write a liveness property, what fairness assumption goes on the cfg/spec — none, weak, or strong?

## The choice

Liveness properties (`<>`, `~>`, `[]<>`) say something *good must eventually happen*. But TLA+ allows infinite stuttering by default, which means the system is allowed to just... stop. Without a fairness assumption, almost every liveness property fails on a "system stutters forever" counterexample.

Fairness fixes this — but it's a *strength dial*:

- **None.** The spec is `Init /\ [][Next]_vars`. Any infinite suffix is allowed, including infinite stuttering. Liveness almost never holds.
- **Weak fairness (WF).** "If an action stays continuously enabled, it eventually fires." Written `WF_vars(A)` (or `fair process` in PlusCal).
- **Strong fairness (SF).** "If an action is enabled infinitely often, it eventually fires." Written `SF_vars(A)` (or `fair+ process` in PlusCal). Stronger than WF.

The choice has consequences. Too weak: legitimate liveness properties fail. Too strong: the spec promises more than the implementation can deliver.

## Side A — no fairness fails

Open `solution/NoFairness.tla` (or click the 🔒 spoiler below). A coffee machine that should brew. The process is **not** marked `fair`.

```bash
cd solution
tlc -pcal NoFairness.tla && tlc NoFairness
```

Output:

```
Error: Temporal properties were violated.
State 1: brewed = FALSE
State 2: Stuttering
```

A 2-state counterexample. The machine just... never brewed. Without fairness, "the machine sits there forever doing nothing" is a legal behavior, and `<>(brewed = TRUE)` fails on it.

## Side B — weak fairness rescues it

Open `solution/WeakFairness.tla` (or click the 🔒 spoiler below). **Identical** spec, except `process` becomes `fair process`. That single keyword adds `WF_vars(machine)` to `Spec`.

```bash
tlc -pcal WeakFairness.tla && tlc WeakFairness
```

"No error has been found." The same liveness property now passes. The action `brew` is continuously enabled (nothing disables it), so weak fairness forces it to fire eventually.

This is the **default fairness for almost every PlusCal process** — and `fair process` is why your earlier puzzles' liveness checks worked.

## Side C — when weak fairness isn't enough

Weak fairness has a loophole: it only helps when the action is **continuously enabled**. If an action gets disabled and re-enabled repeatedly, WF says nothing.

Open `solution/StrongFairness.tla` (or click the 🔒 spoiler below). Two servers compete for a single shared slot (`servedBy`). A clock periodically clears the slot. Suppose we want to prove `<>(servedBy = "S1")` — server S1 eventually serves at least once.

With only WF on each server, here's a legal infinite behavior:

1. S1 sees `servedBy = "none"`, but before it acts, S2 grabs the slot.
2. The clock clears the slot back to `"none"`.
3. S2 grabs it again. Repeat forever.

S1's `serve` action is enabled (whenever the slot is `"none"`), then *disabled* (whenever S2 holds it), then enabled, then disabled... never *continuously* enabled. Weak fairness lets this slide. **Strong fairness** would not — SF says: if you're enabled infinitely often, you fire infinitely often.

(The shipped `StrongFairness.tla` runs to completion and is a base for the discussion. To actually witness this loophole, you'd weaken WF or look at it as a thought experiment. The cfg checks `TypeOK` only.)

## When to choose NO fairness

- You're checking **only safety properties** (invariants, `[]`-shaped). Fairness is irrelevant for safety; adding it costs nothing useful.
- You're modeling a system where "everything might just stop" is an honest possibility — e.g., a hardware-fault model, a partial-failure scenario.
- You're early in design and haven't decided what's a fairness assumption vs what's a guarantee.

## When to choose WEAK fairness (default)

- You want a process / action to **eventually take a step if it can**. This is the normal expectation for "a thread that wants to do work."
- The action's enabling condition is **stable** — once it's enabled, it stays enabled until it fires. Most "single-process loop" actions are like this.
- You're using PlusCal — `fair process` gives you WF for free.
- You're in doubt: WF is the right default 90% of the time.

## When to choose STRONG fairness

- The action's enabling condition can be **toggled by other actions** — enabled, disabled, enabled, disabled — and you want to argue it still fires eventually.
- You're modeling **scheduling fairness** at a finer grain: a process that may temporarily lose CPU but is supposed to be picked up again.
- You're checking liveness on a **contested resource** (semaphore, lock, queue) where multiple actors compete and one's enabling depends on another's choices.
- You've debugged a liveness failure and traced it to "WF wasn't strong enough" — the spec needs to *promise more* about scheduling.
- Be honest: SF is a STRONGER assumption. Make sure your real implementation actually delivers it (a fair scheduler, a fair semaphore policy). Otherwise you're proving a liveness property your code won't satisfy.

## The trade-off

**No fairness** is honest about the worst case. It's safe to assume nothing — but then you can't prove any liveness, so most "must eventually" properties fail.

**Weak fairness** is the sweet spot for most actions. Cheap, automatically encoded by `fair process`, matches reasonable scheduler behavior. The cost is its blind spot: actions that get repeatedly disabled aren't covered.

**Strong fairness** plugs that blind spot. The cost is that the spec is now claiming more about scheduling — your implementation must actually be a fair scheduler in the relevant sense. Easy to lie to yourself with SF: the spec passes liveness, the production system livelocks because the real scheduler isn't strongly fair on that action.

A useful rule of thumb:

> **Default to WF (`fair process`). Switch to SF only when you can name the *interleaving* that makes WF too weak — and only when you genuinely believe the implementation guarantees SF for that action.**

## Common patterns

- **Worker loop**: `fair process` — WF. The worker eventually does its step.
- **Producer / consumer**: WF on both. Each side eventually proceeds when its precondition holds.
- **Two clients competing for a lock**: SF on each client's `acquire` — otherwise one client can be starved while the other repeatedly grabs and releases.
- **Critical-section progress (Peterson's, bakery)**: SF on the entry action of each process to argue starvation freedom.
- **Crash / recovery model**: NO fairness on the crash action (a crash *could* never happen and that's a legal world). WF on recover.
- **A timer that should tick forever**: SF on the `tick` action if `tick` is sometimes disabled (e.g., during another action's atomic body), or `[]<>tick` as an explicit liveness property in the spec.

## Mini-classification exercise

For each, none / WF / SF?

1. A single barista serving coffee in a loop until close.
2. Two threads each trying to acquire a single mutex, in a model that should be starvation-free.
3. A network model where messages may be dropped (`Drop` action).
4. A leader-election protocol where a follower is supposed to *eventually* time out and become a candidate.
5. A producer always able to push, a consumer that pulls when the queue is non-empty, and you want both to make progress.
6. A spec that only checks `TypeOK` — no liveness anywhere.

Rough answers: (1) WF — basic worker loop. (2) SF on each thread's acquire — starvation freedom. (3) NONE on `Drop` — drops are *allowed*, not required; never WF on a "may happen" action you don't want forced. (4) WF or SF on the timeout action depending on whether messages can repeatedly defer the timeout. (5) WF on both. (6) NONE — no liveness, no need.

## What to take away

- Fairness is the *strength dial* on your liveness assumptions. Pick the weakest dial that proves what you need.
- WF is the default. Reach for SF only with a reason — a specific interleaving WF can't rule out.
- A spec that needs SF on every action is suspicious: either the model is over-permissive (too many things can disable each other) or you're promising more than implementation can deliver.
- Removing a fairness assumption never makes a safety violation appear — fairness only matters for liveness.

Done. J06 zooms out: how do you classify properties as safety vs liveness in the first place? That decision precedes the fairness choice.

## Hints

??? hint "💡 Hint 1 — Can the action be disabled and re-enabled?"
    Imagine the action's enabling condition turning on and off repeatedly — enabled, disabled, enabled, disabled, forever. With only WF, that's fine (WF only cares about *continuous* enablement). With SF, that action must fire at least once while enabled. Does your system have this on-off toggling? If yes, WF is insufficient.

??? hint "💡 Hint 2 — Ask: what makes this action disabled?"
    Is the action disabled by *other processes* (a lock held by someone else, a shared resource taken), or just by its own internal conditions? If other processes toggle the enabling, that's the hallmark of strong-fairness scenarios — two clients competing for a lock, a scheduler deciding which thread runs. If only the action's own conditions disable it (e.g., a buffer is full so append is disabled until someone empties it), WF often suffices.

??? hint "💡 Hint 3 — Does the implementation guarantee this fairness?"
    SF is a strong promise — your implementation must actually be a *fair scheduler*. If your real system is a single-threaded worker loop, WF (or no fairness) is honest. If you're modeling multiple threads and you want to claim "no thread starves," that's SF territory — but only if your OS scheduler actually gives you that. Don't let the spec pass liveness while production livelocks.
