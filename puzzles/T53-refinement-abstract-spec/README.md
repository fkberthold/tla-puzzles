# T53: Refinement — The Abstract Spec ⭐⭐

## Lesson: Writing a Maximally Nondeterministic Contract

Refinement is the practice of writing TWO specs of the same system at DIFFERENT LEVELS OF DETAIL, and then proving the detailed one ("concrete") is a valid implementation of the simple one ("abstract"). T53–T58 walk through this. This first puzzle is just the abstract spec — the contract.

The abstract spec describes WHAT the system does, not HOW. Two principles:

1. **Maximally nondeterministic.** Every step the implementation could conceivably take must be allowed by the abstract Next. If the abstract says "the counter goes up by 1" and the implementation increments by 2 in some scenario, the implementation does NOT refine the abstract.
2. **No mechanism.** No counters, no buffers, no internal state — just the OBSERVABLE state and the legal transitions on it. If you find yourself adding a "scratch" variable, you're slipping into mechanism.

The abstract spec is a SET of allowed behaviors. The concrete spec, when proven to refine it, is a SUBSET of that set.

**Worked example — a mailbox.**

The abstract mailbox holds a finite set of letters. You can drop a letter in or pick one up. That's it. No queue, no order, no priority — those would be mechanism.

```
---- MODULE AbstractMailbox ----
EXTENDS Integers, FiniteSets

CONSTANT Letters             \* a finite set of possible letter IDs
ASSUME IsFiniteSet(Letters)

VARIABLE box                  \* set of letters currently in the mailbox

vars == << box >>

Init == box = {}              \* starts empty

Drop ==
  /\ \E ltr \in Letters \ box :   \* any letter not already in
       box' = box \cup {ltr}

Pick ==
  /\ \E ltr \in box :              \* any letter in the box
       box' = box \ {ltr}

Next == Drop \/ Pick

Spec == Init /\ [][Next]_vars

\* The contract: only proper subsets of Letters can be in the box
TypeOK == box \subseteq Letters
====
```

What's INTENTIONALLY missing:

- **No order.** Letters don't have positions; you can't ask "which was dropped first." If the implementation has a queue, that's its concern — the abstract simply doesn't see it.
- **No counter.** You COULD add `count` and increment it on Drop, but you don't, because Drop already conserves the right invariants.
- **No labels, no `pc`, no processes.** It's a STATE PREDICATE + a NEXT RELATION. That's the minimum.

What the abstract DOES capture:

- Initial state: empty.
- Two kinds of step: `Drop` adds, `Pick` removes.
- The state is always a subset of `Letters`.
- The state can be ANY subset, achievable by any sequence of drops and picks.

If you ran TLC with `Letters = {1,2,3}`, you'd see `2^3 = 8` reachable subsets — exactly the powerset.

## Setup

You're writing the ABSTRACT spec for a coffee shop's punch card system. A customer's card has zero or more punches up to a maximum of 10. Two operations:

- **Punch**: increase punches by some positive amount (could be 1, could be more — you don't care).
- **Redeem**: when the card has ≥ 10 punches, exchange it for a free coffee — punches reset to 0.

You're describing the CONTRACT. Don't decide whether punches go up by exactly 1 or by 1–3 at a time — let the abstract permit either. Don't track total free coffees earned — that's mechanism.

## Task

Create `solution/PunchCard.tla` (the abstract spec) and `solution/PunchCard.cfg`.

In the .tla:

- `EXTENDS Integers`
- `CONSTANT MaxPunches`
- `ASSUME MaxPunches \in Nat /\ MaxPunches >= 1`
- `VARIABLE punches`
- `vars == << punches >>`
- `Init == punches = 0`
- An action `Punch` that nondeterministically picks any new value `n` such that `punches < n /\ n <= MaxPunches` and sets `punches' = n`. (This captures "increased by some positive amount, capped at max" without committing to "by exactly 1".)
- An action `Redeem` enabled when `punches >= MaxPunches`, sets `punches' = 0`. NOTE: with the cap above, "punches >= MaxPunches" reduces to "= MaxPunches".
- `Next == Punch \/ Redeem`
- `Spec == Init /\ [][Next]_vars`
- `TypeOK == punches \in 0..MaxPunches`

Cfg:

- `SPECIFICATION Spec`
- `CONSTANT MaxPunches = 3`  (small for state-space sanity)
- `INVARIANT TypeOK`

## Check

```bash
cd solution
tlc PunchCard
```

## Expected Result

- With `MaxPunches = 3`, TLC finds **4 distinct states** (`punches \in {0, 1, 2, 3}`).
- All four are reachable from `punches = 0` because `Punch` can jump to any of `{1,2,3}` directly, and `Redeem` returns from 3 to 0.
- `TypeOK` passes.

The abstract is intentionally tiny. Tier 6's later puzzles (T54+) will write the CONCRETE side — a more detailed spec — and prove it refines this abstract.
