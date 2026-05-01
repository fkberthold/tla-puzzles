# T37: `ENABLED` — When Can An Action Fire? ⭐⭐

## Lesson: From Action to State Predicate

Up to now, an action like `A == /\ P /\ x' = ...` has been a relation: it relates a current state to a possible next state. `A` is a property of a PAIR of states.

`ENABLED A` is something different. It is a STATE PREDICATE — a property of a SINGLE state — that asks: "from this state, is there ANY next state in which `A` is true?"

In other words: **`ENABLED A` is true in state `s` iff there exists a state `s'` such that `A` holds for the transition `s -> s'`.**

Why does that matter? Because actions usually have ENABLING CONDITIONS (predicates on unprimed variables that must hold for the action to fire). `ENABLED A` lets you talk about the enabling condition AS A FORMULA you can put in invariants and properties — without manually copying it from the action's body. It's also the core ingredient in fairness specifications (`WF_v(A)`, `SF_v(A)` you'll see in Tier 5) and in deadlock debugging.

**Worked example — a vending machine.**

A vending machine has a coin slot and a stock count. The `Buy` action requires that you've inserted enough coin and that there is stock.

```
---- MODULE Vending ----
EXTENDS Integers

VARIABLES coin, stock

Init == coin = 0 /\ stock = 3

Insert ==
  /\ coin < 5
  /\ coin' = coin + 1
  /\ stock' = stock

Buy ==
  /\ coin >= 5
  /\ stock > 0
  /\ coin' = coin - 5
  /\ stock' = stock - 1

Next == Insert \/ Buy

Spec == Init /\ [][Next]_<<coin, stock>>

\* ENABLED Buy is a STATE predicate — true in any state where Buy could fire.
BuyReady == ENABLED Buy

\* This invariant claims the boolean equivalence: ENABLED Buy iff coin >= 5 and stock > 0.
EnabledMatchesGuard == (ENABLED Buy) <=> (coin >= 5 /\ stock > 0)
================================
```

In any state where `coin = 5, stock = 3`, `ENABLED Buy` is TRUE. In `coin = 4, stock = 3`, `ENABLED Buy` is FALSE — there's no successor satisfying the action's body. The invariant `EnabledMatchesGuard` should hold trivially: `ENABLED A` "extracts" the unprimed-only part of A's enabling condition.

Two important facts:

1. `ENABLED` only inspects the UNPRIMED conditions of the action. If your action says `x' \in 0..10`, the unprimed projection is just "true" (any state has SOME next value), so `ENABLED` returns true regardless of `x`.
2. `ENABLED` is a TLA+ operator. In TLC's `.cfg` you can use it inside an `INVARIANT`, just like any state formula.

You'll use `ENABLED` heavily in Tier 5 when fairness depends on whether an action is continuously available.

## Setup

A pedestrian crossing has a light that flips between `"red"` (cars stop, peds go) and `"green"` (cars go, peds stop). A pedestrian can `Cross` only when the light is `"red"`. We want to verify, using `ENABLED`, that the pedestrian's `Cross` action is enabled EXACTLY when the light is red.

## Task

Write a PURE TLA+ spec (no PlusCal block) with:

- `EXTENDS Integers`
- Two variables: `light` (in `{"red", "green"}`) and `crossings` (integer count of times the pedestrian has crossed)
- `Init`: `light = "green" /\ crossings = 0`
- An action `Flip` that toggles `light` (red <-> green) and leaves `crossings` unchanged
- An action `Cross` whose unprimed enabling condition is `light = "red"` and which increments `crossings`. To keep state space small, also require `crossings < 3`.
- `Next == Flip \/ Cross`
- `Spec == Init /\ [][Next]_<<light, crossings>>`

Add invariants:

- `TypeOK == light \in {"red", "green"} /\ crossings \in 0..3`
- `EnabledMatchesGuard == (ENABLED Cross) <=> (light = "red" /\ crossings < 3)`

## Check

Both invariants must PASS.

## Expected Result

- TLC explores roughly 8 distinct states (2 light values × 4 crossing counts).
- `EnabledMatchesGuard` confirms: `ENABLED Cross` is exactly the conjunction of unprimed guards in `Cross`.
- All checks pass.

## Hint

Because `ENABLED A` strips out the primed conjuncts, your `Cross` action will look like:

```
Cross ==
  /\ light = "red"
  /\ crossings < 3
  /\ crossings' = crossings + 1
  /\ light' = light
```

The first two conjuncts are unprimed — those become `ENABLED Cross`. The next two are primed — they don't appear in `ENABLED`. To check this against your guard, plug it into the invariant: `(ENABLED Cross) <=> (light = "red" /\ crossings < 3)`.

You do not need `CHECK_DEADLOCK FALSE` here — `Flip` is always enabled, so TLC will never flag a deadlock. If your spec ever terminates without all actions being enabled, revisit your guards.

## Hints

??? hint "💡 Hint 1 — ENABLED is asking 'could this action fire here?'"
    An action like `Cross` is a relation between states. `ENABLED Cross` flips that perspective: it's a STATE PREDICATE that asks "from THIS state, is there ANY next state in which Cross is true?" In other words: "from here, would Cross be allowed to fire?" That's decided solely by the unprimed (guards) part of the action, not the primed (updates) part.

??? hint "💡 Hint 2 — ENABLED extracts only the unprimed guards"
    Look at your `Cross` action. It has both unprimed conjuncts (`light = "red"`, `crossings < 3`) and primed conjuncts (`crossings' = ...`, `light' = ...`). The `ENABLED Cross` operator throws away the primed part and keeps only the guards — so `ENABLED Cross` is equivalent to `light = "red" /\ crossings < 3`. The invariant `EnabledMatchesGuard` verifies this equivalence.

??? hint "💡 Hint 3 — Why does this matter?"
    In Tier 5 you'll use `ENABLED` in fairness statements like `WF_v(A)` (weak fairness: if A's enabling condition holds continuously, A must eventually fire). Here you're just verifying the principle: `ENABLED A` correctly captures the action's unprimed preconditions. That's the foundation for reasoning about fairness.

