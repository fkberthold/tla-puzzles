# T61: VIEW for Equivalence Classes ⭐⭐

## Lesson: VIEW — Telling TLC Which State Differences Matter

Sometimes a spec carries variables that aren't part of the safety story. **History buffers**, **trace logs**, **debugging counters**, **monotonically growing timestamps** — they balloon the state space without changing what's reachable in any meaningful sense. If you let TLC explore them naively, it visits an unbounded number of states that all look the same for safety purposes.

The **VIEW** directive tells TLC: "two states are equivalent if their VIEW is equivalent." TLC computes the view at every state and uses it as the fingerprint for deduplication.

```
VIEW MyProjection
```

`MyProjection` is an operator defined in your spec — typically a tuple of just the variables that matter, projecting away the noisy ones.

**Worked example — elevator with audit log.**

```
---- MODULE Elevator ----
EXTENDS Naturals, Sequences
CONSTANT Floors
VARIABLES floor, log
vars == << floor, log >>

Init == floor = 1 /\ log = << >>

GoUp == floor < Floors /\ floor' = floor + 1 /\ log' = Append(log, "up")
GoDown == floor > 1 /\ floor' = floor - 1 /\ log' = Append(log, "down")
Next == GoUp \/ GoDown

Spec == Init /\ [][Next]_vars

TypeOK == floor \in 1..Floors /\ log \in Seq({"up", "down"})

\* For TLC, the state is just the floor. The audit log is debugging context.
FloorView == floor
=====
```

Cfg:

```
SPECIFICATION Spec
CONSTANT Floors = 5
VIEW FloorView
CHECK_DEADLOCK FALSE
INVARIANT TypeOK
```

WITHOUT `VIEW FloorView`, TLC tries to explore every path that leads to floor 3: up-up, up-up-down-down-up-up, up-up-down-up-up-down-up… The set is INFINITE because the log keeps growing. TLC will run until you Ctrl-C it.

WITH `VIEW FloorView`, TLC computes the view (= `floor`) at each state. Two states with `floor = 3` and different logs collapse to the same view; TLC marks them visited. Result: **5 distinct views**, one per floor.

**Three load-bearing things:**

1. **`FloorView == floor`** — an operator that returns the part of the state TLC should care about.
2. **`VIEW FloorView`** in the cfg — names the operator. Replaces the default fingerprint (the whole state).
3. **The view doesn't change the spec.** `Spec` still has both variables. TLC still records both in the trace when it finds a violation. The view only changes which states TLC SKIPS as duplicates.

**Two warnings:**

- VIEW is dangerous if you project away something that DOES matter. If the safety property mentions a variable not in the view, TLC may collapse two states that differ in that variable, and miss bugs. **The view must include every variable referenced by your invariants and properties.**
- VIEW interacts oddly with liveness. For most cases involving liveness, prefer SYMMETRY (or no abstraction) over VIEW.

**VIEW vs. SYMMETRY (T60):**

- SYMMETRY uses orbit equivalence — two states are equal if a permutation maps one to the other. Cheap when applicable.
- VIEW uses an explicit projection — you write the operator, you decide what's kept.
- VIEW is more general. SYMMETRY is more automatic.

## Setup

A pre-written abstract spec lives in `solution/Hopper.tla`: a hopper fills and drains with capacity `Cap`. The spec ALSO records every action in a `history` sequence. Without VIEW, the history sequence makes the state space infinite. With VIEW, only `level` matters and TLC finishes immediately.

## Task

Open `solution/Hopper.tla` (or click the 🔒 spoiler below). Note:

- `level` and `history` are both variables. `level` is bounded; `history` grows without bound.
- `LevelView == level` projects away `history`.

Open `solution/Hopper.cfg` (or click the ⚙️ spoiler below). Note `VIEW LevelView`.

Run TLC:

```bash
cd solution
tlc Hopper
```

Note the **distinct states found** and the depth.

Now comment out the VIEW line:

```
\* VIEW LevelView
```

Re-run. TLC will start generating states quickly — a million in a few seconds — and never finish. It's exploring every distinct history. Hit Ctrl-C after a few seconds. Restore the VIEW line.

## Check

- WITH `VIEW LevelView`: TLC reports **4 distinct states** (one per value of `level` in `0..3`), depth 4, "No error has been found."
- WITHOUT VIEW: TLC explores millions of states quickly. State space is infinite — it never terminates.

## Expected Result

- 4 distinct states with VIEW.
- Without VIEW: TLC runs without bound. Hit Ctrl-C; the takeaway is "the abstraction is doing real work."

## What to take away

- **VIEW** is "TLC, dedupe states by THIS, not by the full state."
- The view operator is just an expression — usually a tuple of the variables that matter.
- Use VIEW when you have unbounded debugging variables (history, log, trace counter) that don't affect safety.
- Make sure your view INCLUDES every variable mentioned in invariants. If you project something away that an invariant tests, TLC might miss the bug.
- VIEW is more general than SYMMETRY. SYMMETRY is automatic when applicable; VIEW gives you full control.

## Hints

??? hint "💡 Hint 1 — History vs. Hypothesis"
    The Hopper spec has TWO variables: `level` (the hopper's fill) and `history` (a record of every action). The spec's safety properties only care about `level` — they're about capacity, not about tracing. If you let TLC explore the full state (level, history), it has to distinguish between two states that have the same level but different histories. As histories grow unboundedly, the state space explodes to infinity. VIEW says: "TLC, I only care about level. Two states with the same level but different histories are equivalent." Once you collapse them, the state space becomes finite.

??? hint "💡 Hint 2 — The View Must Be Safe"
    Before you write `VIEW LevelView`, ask: does any invariant or property mention the variable you're hiding? In Hopper, `history` is NOT mentioned by TypeOK or any other property. So it's safe to hide. If you tried `VIEW LevelView` on a spec where `NotEmpty == history # <<>>` is a property, TLC would miss bugs because it would deduplicate states that differ in history. The rule: your view must INCLUDE every variable tested by your invariants.

??? hint "💡 Hint 3 — VIEW Is Not SYMMETRY"
    T60 used SYMMETRY, which is automatic once you declare `Permutations`. T61 uses VIEW, which requires you to WRITE the operator that decides what matters. VIEW is more expressive (you have full control) but requires more thought (you must verify the projection is sound). You can use both in the same spec — SYMMETRY for interchangeable model values, VIEW for ephemeral variables.
