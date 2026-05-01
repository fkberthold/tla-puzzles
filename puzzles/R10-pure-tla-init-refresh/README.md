# R10: Pure TLA+ Init Refresh ⭐

## Lesson: Re-Drilling `Init` in Pure TLA+

No new concept. Tier 3 introduced pure TLA+ where state is the conjunction `Init /\ [][Next]_vars`. The state level — what the system can BE — is captured by `Init`. Where PlusCal hides the initial state behind variable declarations, pure TLA+ requires you to write `Init` as a state predicate.

A non-trivial `Init` describes a SET of legal initial states. You build that set by:

- conjoining clauses for each variable
- using `\in` for nondeterministic choice within a finite domain
- using `\/` (disjunction) when the legal initial states fall into distinct CASES

**Worked example — a board game's opening setup.**

A two-player checkers-like game starts with each player's pieces in one of three opening formations: "classical" (pieces on the back two rows), "advanced" (back row only), or "drafted" (a custom 4-piece subset of the back row). The clock starts at 0. Whose turn it is is determined by coin flip.

```
---- MODULE GameOpening ----
EXTENDS Integers, FiniteSets

Pieces == 1..12   \* piece IDs
BackRow == {1, 2, 3, 4}

VARIABLES whitePieces, blackPieces, clock, toMove

Init ==
  /\ clock = 0
  /\ toMove \in {"white", "black"}
  /\ \/ /\ whitePieces = Pieces        \* classical
        /\ blackPieces = Pieces
     \/ /\ whitePieces = BackRow       \* advanced
        /\ blackPieces = BackRow
     \/ /\ whitePieces \in {S \in SUBSET BackRow : Cardinality(S) = 4}  \* drafted
        /\ blackPieces \in {S \in SUBSET BackRow : Cardinality(S) = 4}

vars == << whitePieces, blackPieces, clock, toMove >>
Next == UNCHANGED vars

Spec == Init /\ [][Next]_vars
====
```

Things to notice:

- The OUTER conjunction (`/\`) lists what's true in EVERY initial state: `clock = 0`, `toMove` is white or black.
- The INNER disjunction (`\/`) gives THREE alternative formations. Each disjunct is itself a conjunction of facts about `whitePieces` and `blackPieces`.
- `\in` inside Init is how pure TLA+ expresses "pick any value from this set." Tier 3 (T28) introduced this; here it appears nested inside disjuncts.
- `Next == UNCHANGED vars` is a stub so we can run TLC just on the Init exploration.

TLC enumerates initial states by trying every combination satisfying `Init`. With `BackRow` of size 4, there's exactly one 4-subset, so "drafted" gives 1 × 1 = 1 state. Plus 1 classical and 1 advanced. Times two values of `toMove` = 6 distinct initial states.

The key reflex: when initial states have DIFFERENT SHAPES (classical vs advanced uses different piece sets), you reach for `\/`. When they have the same shape but different VALUES, you reach for `\in`.

## Setup

A weather station boots up. Each boot, the station chooses a configuration:

- It is in one of two modes: `"summer"` (high temp, no precip) or `"winter"` (low temp, possibly snowing).
- In summer mode: temperature is in `60..90`, humidity is in `0..40`, snowing is `FALSE`.
- In winter mode: temperature is in `0..30`, humidity is in `30..70`, snowing is `TRUE` or `FALSE`.

Once booted, nothing changes — this puzzle is purely about Init.

## Task

Create `solution/Weather.tla` with:

- `EXTENDS Integers`
- VARIABLES: `mode`, `temp`, `humidity`, `snowing`
- An `Init` predicate using `\/` to handle the two modes, with `\in` for the in-range values
- A stub `Next == UNCHANGED << mode, temp, humidity, snowing >>`
- `Spec == Init /\ [][Next]_vars`

Add invariants:

1. `TypeOK`: each variable in its declared domain
2. `WinterImpliesCold`: `mode = "winter" => temp <= 30`
3. `SummerImpliesNoSnow`: `mode = "summer" => snowing = FALSE`

## Check

```bash
cd solution
tlc Weather
```

## Expected Result

- Summer states: 31 (temp values in 60..90) × 41 (humidity values in 0..40) × 1 (snowing) = 1271
- Winter states: 31 (temp values in 0..30) × 41 (humidity values in 30..70) × 2 (snowing) = 2542
- Total distinct states: **3813**
- All three invariants PASS.

If `WinterImpliesCold` fails, your disjunction probably let temp range overlap. The fix: each disjunct's clauses must constrain ALL variables they touch.

## Hints

??? hint "💡 Hint 1 — Two shapes, two disjuncts"
    T28 introduced pure TLA+ Init. This puzzle has TWO distinct initial configurations (summer vs winter). Use \/ at the top level of Init to express "either this set of states OR that set." Each disjunct is a separate conjunction of constraints.

??? hint "💡 Hint 2 — \in picks a value from a set"
    Inside each disjunct, use \in to let TLC enumerate all values in a range. For summer, temperature \in 60..90. TLC will try all 31 values. This is how you express nondeterminism in pure TLA+.

??? hint "💡 Hint 3 — Each disjunct must constrain ALL variables"
    If your WinterImpliesCold invariant fails, check that the winter disjunct EXPLICITLY constrains temp to 0..30. The invariant will fail if the summer branch accidentally allows winter-like temps.

