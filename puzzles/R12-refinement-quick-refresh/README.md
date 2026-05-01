# R12: Review — Refinement Quick Refresh ⭐

## Lesson: Refinement, Restated

A **refinement mapping** says: "every behavior of the concrete spec, viewed through this mapping, is also a behavior of the abstract spec." The pieces:

1. The concrete spec has its own variables and `Spec == Init /\ [][Next]_vars` formula.
2. An `INSTANCE Abstract WITH absVar <- expr` — every variable of `Abstract` is supplied a value built from concrete variables.
3. A property like `C!Spec` — the abstract spec formula, called through the instance — is checked by TLC. If the concrete violates the abstract's `Spec`, TLC emits a counterexample.

**Worked example — postal scale refines coin-counter.**

`Coins.tla` (abstract) — a coin counter that grows by 1 per step:

```
---- MODULE Coins ----
EXTENDS Naturals
CONSTANT Cap
VARIABLE n
Init == n = 0
Next == n' = n + 1 /\ n < Cap
vars == << n >>
Spec == Init /\ [][Next]_vars
=====
```

`Scale.tla` (concrete) — a postal scale where parcels are added one at a time:

```
---- MODULE Scale ----
EXTENDS Naturals, FiniteSets
CONSTANT Parcels
VARIABLE pile
Init == pile = {}
Add == \E p \in Parcels \ pile : pile' = pile \cup {p}
       /\ pile # Parcels
Next == Add
vars == << pile >>
Spec == Init /\ [][Next]_vars

C == INSTANCE Coins WITH n <- Cardinality(pile), Cap <- Cardinality(Parcels)
CoinsSpec == C!Spec
=====
```

Then `Scale.cfg`:

```
SPECIFICATION Spec
CONSTANT Parcels = {p1, p2}
CHECK_DEADLOCK FALSE
PROPERTY CoinsSpec
```

TLC checks `CoinsSpec` (the abstract spec, with concrete state plugged in) holds for every Scale behavior. Each `Add` step grows the pile by one parcel — under the cardinality mapping, that's `n' = n + 1`, an abstract `Next` step. Refinement holds.

**Three load-bearing pieces** to recognize:

- `INSTANCE Coins WITH n <- ...` — the **refinement mapping**: how the concrete spec's state expresses the abstract spec's state.
- `C!Spec` — calling the abstract spec FORMULA through the instance. Anything you defined in `Coins.tla` is now reachable as `C!Init`, `C!Next`, `C!Spec`, etc.
- `PROPERTY CoinsSpec` in the cfg — TLC verifies the abstract Spec on every concrete behavior.

`CHECK_DEADLOCK FALSE` matters: the concrete spec terminates (no more parcels), but `[][Next]_vars` allows infinite stuttering. TLC's default deadlock check would complain about the terminal state; we tell it not to. (You'll see this same flag throughout Tier 6.)

## Setup

A bag fills with marbles, one at a time. Once every kind of marble is in the bag, no more steps happen. We claim this matches an abstract counter that ticks 0 → 1 → 2 → 3 (where 3 is the bag's capacity).

A pre-written abstract spec is shown below as the file `Counter.tla` (also visible in the 🔒 spoiler at the bottom of this page). A pre-written concrete spec is shown below as the file `Bag.tla` (also visible in the 🔒 spoiler at the bottom of this page). The configuration is in `solution/Bag.cfg`.

## Task

Open `solution/Bag.tla` (or click the 🔒 spoiler below). Three things were left for you to inspect:

1. The `INSTANCE Counter WITH n <- ..., Max <- ...` line. Confirm the mapping uses `Cardinality(inside)` for `n` and `Cardinality(Beads)` for `Max`.
2. The line `CounterSpec == C!Spec`. This is the abstract spec, applied through the instance.
3. The cfg's `PROPERTY CounterSpec`. This is the line that asks TLC to verify the refinement.

Run:

```bash
cd solution
tlc Bag
```

(No `tlc -pcal` — pure TLA+, no PlusCal source.)

## Check

- TLC reports **8 distinct states** (one per subset of `{b1, b2, b3}`).
- "No error has been found." — refinement holds.

Now break the refinement deliberately. Edit `Bag.tla` and change the mapping:

```
C == INSTANCE Counter WITH n <- Cardinality(inside) + 1, Max <- Cardinality(Beads)
```

Re-run `tlc Bag`. TLC should now report a property violation. The trace shows the initial state, where the abstract `n` would be 1 — but `Counter`'s `Init` says `n = 0`. The mapping is wrong, so the very first state isn't a valid `C!Init`.

Restore the mapping when you're done.

## Expected Result

- With correct mapping: TypeOK passes, CounterSpec passes, 8 distinct states.
- With sabotaged mapping: TLC reports a property violation (the abstract `C!Spec` fails at the initial state because the mapping starts at `n = 1`, not `n = 0`). Trace length 1.

## What to take away

- Refinement is one `INSTANCE ... WITH` line plus one `PROPERTY` line in the cfg. The instance gives the mapping, the property tells TLC what to check.
- If the mapping is wrong, TLC catches it — usually at Init, sometimes at the first transition.
- `CHECK_DEADLOCK FALSE` is the standard companion when the concrete spec terminates; without it, TLC complains about the terminal state.

## Hints

??? hint "💡 Hint 1 — Understanding the Mapping"
    Re-read the lesson's worked example (Coins/Scale). In that example, the abstract spec had a variable `n` and the concrete spec had `pile`. The mapping said `n <- Cardinality(pile)`. In R12, what is the abstract variable and what is the concrete variable? How does the mapping bridge them?

??? hint "💡 Hint 2 — Instance Syntax"
    The `INSTANCE` line is your gateway. After you write `C == INSTANCE Counter WITH ...`, every symbol from Counter becomes accessible through `C`. So `C!Spec` is the Counter's Spec formula, but with the variables you supplied in the WITH clause. The same pattern would give you `C!Init`, `C!Next`, `C!TypeOK`. The mapping tells TLC: "when checking `C!Spec`, substitute MY expressions for Counter's variables."

??? hint "💡 Hint 3 — Why the Mapping Must Match at Init"
    If your mapping is wrong, TLC will detect it first at the initial state. Counter!Init says `n = 0`. If your mapping makes `n` start at something else (e.g., `Cardinality(inside) + 1` would be 1 at init), then the very first state won't satisfy Counter!Init. TLC reports "property violated" after just one state. Restore the correct mapping so both specs agree on what the initial abstract state must be.
