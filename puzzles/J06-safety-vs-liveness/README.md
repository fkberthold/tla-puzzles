# J06: Judgment — Safety vs Liveness ⭐

**Judgment puzzle.** No new syntax. The goal: when a stakeholder hands you a requirement in English, can you instantly classify it as **safety** ("nothing bad happens") or **liveness** ("something good eventually happens")? The answer determines what kind of TLA+ thing you write.

## The choice

Every TLA+ property falls into one of two camps:

- **Safety.** A claim about *every reachable state*. "Nothing bad happens." Has the shape of an INVARIANT — a predicate over a single state.
- **Liveness.** A claim about *behaviors* (infinite sequences of states). "Something good eventually happens." Has the shape `<>P`, `[]<>P`, `P ~> Q`, etc.

The two have *different ergonomics in TLA+*:

- Safety violations are caught by simple state-graph search. Counterexample = a finite path to a bad state.
- Liveness violations need more — fairness assumptions, lasso-shaped counterexamples, longer search.
- Safety failures are usually one bug. Liveness failures often surface design questions about scheduling and progress.

Misclassifying matters. If you write `INVARIANT EventuallyComplete` where `EventuallyComplete == <>(...)`, TLC will reject it (you can't put a temporal formula in an INVARIANT slot). If you write `PROPERTY NoDoubleSpend` where the property is really a state predicate, you'll do extra work and may need fairness you don't actually need.

## Worked example — both kinds in one spec

Open `solution/SafetyDemo.tla`. A toggle that flips between "on" and "off" twice.

```
StateOK     == state \in {"on", "off"}     \* SAFETY: about each state.
FlipsNonNeg == flips >= 0                   \* SAFETY: about each state.
EventuallyOn == <>(state = "on")           \* LIVENESS: about the behavior.
```

`solution/SafetyDemo.cfg`:

```
INVARIANT StateOK
INVARIANT FlipsNonNeg
PROPERTY  EventuallyOn
```

Note the cfg keywords: **safety properties go under `INVARIANT`, liveness properties go under `PROPERTY`.** That's the syntactic line. The semantic line is one level deeper.

```bash
cd solution
tlc -pcal SafetyDemo.tla && tlc SafetyDemo
```

All three pass. 4 distinct states.

## How to tell — three tests

### Test 1: Can you violate it with a *finite* trace?

If a violation is witnessed by a single bad state (the trace ends there), it's **safety**. If a violation requires showing "this goes on forever / never reaches the goal," it's **liveness**.

- "The balance is never negative." Bad state = a state with negative balance. Finite trace. → Safety.
- "Every request eventually gets a response." Bad behavior = a request that *never* gets a response, however long you wait. Infinite trace. → Liveness.

### Test 2: Does it have an "always" or an "eventually"?

- **Always X / X holds in every state** — safety. (The `[]` is implicit when you write an INVARIANT.)
- **Eventually X / will at some point** — liveness.
- **Always-eventually X** — liveness (`[]<>X`, "infinitely often").
- **Eventually-always X** — liveness (`<>[]X`, "stabilizes").
- **X leads-to Y** — liveness (`X ~> Y`).

### Test 3: Does it depend on fairness?

Safety properties are checkable on a spec **without fairness** — `Init /\ [][Next]_vars` is enough.

Liveness properties almost always need fairness on the relevant actions. If your "property" suddenly fails the moment you remove `WF_vars` from the spec, it's liveness.

## Why the distinction matters

1. **Where it goes in the cfg.** `INVARIANT` for safety, `PROPERTY` for liveness. Different keyword, different TLC machinery.
2. **What TLC has to do.** Invariants: state-by-state check during graph exploration — fast. Properties: temporal-logic check at the end — slower.
3. **What a counterexample looks like.** Invariant violation: a finite path to a bad state. Property violation: a "lasso" — a finite stem followed by a cycle that the system loops in forever, never satisfying the property.
4. **Whether fairness matters.** Safety: never. Liveness: almost always.
5. **What kind of bug it is.** Safety failures = "this state shouldn't be possible" (logic bug). Liveness failures = "the system can stall here" (scheduling bug, missing precondition, deadlock, livelock).

## Mini-classification exercise

For each English requirement, classify as Safety (S) or Liveness (L). Then, **what cfg keyword** would you use?

1. The light is never both on and off at the same time.
2. The user eventually sees a confirmation message.
3. The bank account balance never goes below zero.
4. Every transaction is either committed or aborted, never both.
5. If a process requests the lock, it eventually acquires it.
6. The system never deadlocks.
7. Once the leader is elected, no other node thinks it's the leader.
8. The queue never holds more than 100 items.
9. After a crash, the system eventually returns to the consistent state.
10. The counter, once incremented, is never decremented.

Rough answers (think first, then check):

1. S — invariant on a single state. `INVARIANT`.
2. L — eventually. `PROPERTY <>(...)`.
3. S — invariant on balance. `INVARIANT`.
4. S — invariant on the transaction's state. `INVARIANT`.
5. L — `Request ~> Acquire`. `PROPERTY` (leads-to).
6. **Subtle** — usually phrased as liveness ("the system always makes progress"), but TLC's `CHECK_DEADLOCK` is a safety check on "no successor state exists." In TLA+ "no deadlock" is most often a liveness property — `<>` something happens — but TLC's deadlock check is technically a safety check on the structure of the next-state. Worth asking: do you mean "no terminal state" (safety, structural) or "always makes progress" (liveness)? Both exist.
7. S — invariant: "at most one node thinks it's the leader." `INVARIANT`.
8. S — invariant on queue length. `INVARIANT`.
9. L — eventually returns to consistent state. `PROPERTY`.
10. S — invariant: "the counter never decreases" — actually a *trace* property over two consecutive states; in TLA+ you'd write it as a property over `[Next]_vars`, e.g. `[][counter' >= counter]_vars`. Conventionally: still safety (it's about every step), but lives in `PROPERTY` because it's not a single-state invariant. It's a useful edge case that some safety properties span pairs of states (action-level safety) — TLC handles them as PROPERTY but they aren't liveness.

## The trade-off

There isn't really a trade-off here — properties are *either* safety or liveness; the question is which lens fits the requirement. The skill is recognizing the shape fast.

A useful rule of thumb:

> **"Never X" / "Always X" / "X holds" → safety, INVARIANT. "Eventually X" / "X then Y" / "infinitely often X" → liveness, PROPERTY.**

When stakeholders speak in *English*, "the system should be reliable" / "things should work" are too vague. Push them: do you mean "reliable means no two clients see different views" (safety) or "reliable means a request always completes within N steps" (liveness)? The TLA+ shape sharpens the requirement.

## What to take away

- Two camps: **safety = invariants over states**, **liveness = temporal claims over behaviors**.
- Three quick tests: finite-trace witness? language of *always* vs *eventually*? fairness needed?
- Different cfg keyword (`INVARIANT` vs `PROPERTY`), different TLC machinery, different counterexample shape.
- Most production systems care about both. The bugs you find via safety vs liveness are different *kinds* of bugs.
- A vague "the system should be reliable" is either (a) safety in disguise, (b) liveness in disguise, or (c) both — never neither. Force the disambiguation.

Done. J07 closes the judgment set with the smallest-grained choice yet — when do two operations belong in one PlusCal label vs two?
