# T58: Refinement — Debugging a Failed Refinement ⭐⭐⭐

## Lesson: Reading a Refinement-Violation Trace

When TLC says your refinement holds, you celebrate. When it says the refinement fails, you read the trace. This puzzle is about THE READING, not the celebration.

A refinement-violation trace from TLC looks like a regular safety violation, but the property that failed is `Refines == L0!Spec`. The trace has the form:

```
Error: Property Refines is violated.
State 1: <Initial predicate>
  ... concrete variables ...
State 2: <action ActionName>
  ... concrete variables ...
...
State k: ... where the abstract spec breaks ...
```

Three kinds of bug typically cause refinement to fail. Learn to recognize each:

### Bug 1: The mapping is wrong.

The concrete is correct, but your `WITH` clause projects to abstract values that don't satisfy the abstract Init or Next. Symptom: the trace shows valid CONCRETE behavior, but when you compute the mapping you see an abstract jump that the abstract doesn't allow.

Fix: rewrite the WITH expression. Often you missed a case (e.g., `lampOn <- brightness > 0` is right; `lampOn <- brightness = 1` would be wrong since brightness 2 and 3 also represent "on").

### Bug 2: The concrete mechanism diverges from the abstract.

The mapping is fine, but the concrete really does take a step the abstract forbids. Symptom: the projected step matches no abstract action — and rewriting the mapping won't fix it.

Fix: change the concrete spec. Maybe an action increments by 2 when the abstract demands +1. Maybe a guard is missing.

### Bug 3 (liveness): Fairness fails to transfer.

This applies to PROPERTY checks of the form `<>P` (eventually) or `[]<>P` (infinitely often). The abstract has fairness assumptions that the concrete doesn't preserve. Symptom: TLC reports a temporal counterexample — a lasso (cycle) in concrete behavior that fails the abstract's liveness clause.

Fix: add fairness to the concrete spec, or accept that the liveness was too strong for what you're implementing.

In this puzzle we'll focus on bugs 1 and 2 (safety refinement). Liveness refinement debugging shows up at scale; T59 capstone touches it.

**Worked example — clock with broken minute rollover.**

Abstract `ClockA`: minutes counter that increments by 1 each tick, rolling over from 59 to 0.

```
---- MODULE ClockA ----
EXTENDS Integers
VARIABLE m
Init == m = 0
Tick == m' = (m + 1) % 60
Next == Tick
Spec == Init /\ [][Next]_<<m>>
====
```

Concrete `ClockC` with a buggy rollover (jumps to 1 instead of 0 at 60):

```
---- MODULE ClockC ----
EXTENDS Integers
VARIABLE m
Init == m = 0
TickC == m' = IF m = 59 THEN 1 ELSE m + 1   \* BUG: should be 0
Next == TickC
Spec == Init /\ [][Next]_<<m>>

L0 == INSTANCE ClockA WITH m <- m
Refines == L0!Spec
====
```

Run TLC on `ClockC`. Trace:

```
State 1: m = 0
State 2: m = 1
...
State 60: m = 59
State 61: m = 1   <-- abstract Tick says m' = 0, but we got 1. Refinement violated.
```

Diagnosis: this is BUG 2. The mapping is `m <- m`, the simplest possible. The mapping is fine. The concrete itself takes a step the abstract doesn't allow (60 → 1 instead of 60 → 0). Fix the concrete `TickC`.

If instead the concrete had been `TickC == m' = (m + 1) % 60` (correct mechanism) but the mapping had been `WITH m <- (m + 1) % 60` (wrong mapping that adds an extra increment), Init would fail: concrete `m = 0` projects to abstract `m = 1`, but abstract `Init` says `m = 0`. That's BUG 1.

## Setup

You're given a CONCRETE spec that DOES NOT refine its abstract. There's exactly one bug. Your task is to identify which kind of bug and fix it.

The system is a counter that should:
- Start at 0
- Increment by 1, capped at `Max`
- Reset to 0 only from `Max`

The provided concrete spec violates the refinement. Fix it so TLC reports no error.

## Task

The starting files are in `solution/`:

- `solution/CounterA.tla` — the abstract spec (DO NOT modify)
- `solution/CounterC.tla` — the concrete spec (HAS A BUG)
- `solution/CounterC.cfg` — TLC config

### Walkthrough

1. Run `tlc CounterC` from `solution/`. Read the violation trace TLC prints.
2. Identify the bug:
   - Look at each step. Compute the mapping by hand: what does the abstract see?
   - At the failing step, did the projection match an abstract `Next`? If not, is it because of the MAPPING (the WITH expression) or the CONCRETE Next?
3. Fix the spec.
4. Re-run TLC. It should now report no error.

## Expected Initial Result

When you run TLC on the unfixed file, you'll see a property violation on `Refines` after a small number of steps. Read the trace to identify which concrete action is misbehaving and why.

## Expected Final Result

After your fix:

- TLC reports no errors.
- About **3 distinct states** (`n \in {0, 1, 2}`).
- `TypeOK` and `Refines` both pass.

## What you should learn

- How to READ a refinement-violation trace.
- How to TELL whether the bug is in the mapping or in the concrete Next.
- That `Refines` violations can usually be diagnosed in 3–4 trace lines.

## Hints

??? hint "💡 Hint 1 — A refinement violation is a trace where concrete behavior breaks abstract rules"
    Read the trace step by step. At each concrete state, compute what the abstract sees (apply the WITH mapping). At the failing step, check: did that abstract state follow a valid abstract action, or did the abstract forbid it?

??? hint "💡 Hint 2 — Three kinds of bug: mapping wrong, concrete wrong, fairness weak"
    This puzzle focuses on bugs 1 and 2. Bug 1: the mapping doesn't yield abstract values correctly. Bug 2: the concrete action really does violate the abstract. The hint says the bug is in the concrete Next.

??? hint "💡 Hint 3 — Look for broken guards on the concrete"
    Typically the trace shows a concrete action firing when its guard should have been false. E.g., Reset firing from n=1 when it should only fire from n=Max. Fix the guard and re-run TLC.

