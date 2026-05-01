# R01: Either/Or in a New Skin ⭐

## Lesson: Recap — `either/or` for Branching Behavior

You met `either/or` back in T03 (the hiker at the fork). This is a recap drill in a fresh domain — no new syntax, just the same shape applied somewhere different.

The rule, once more:

- `with` chooses a VALUE from a set.
- `either { ... } or { ... }` chooses which BRANCH of code to execute.

Branches are braced blocks separated by the keyword `or`. No semicolon between them — just `} or {`. TLC explores both.

**Recap example — a vending machine response.**

A vending machine has been asked for a snack. It either dispenses the snack and decrements stock, or — when something jams — it returns the coin and lights the fault lamp. Two branches, different variables touched.

```
(*--algorithm Vending {
  variables stock = 1, coin_returned = FALSE, fault = FALSE;

  fair process (vendor = "Machine") {
    respond:
      either {
        stock := stock - 1;
      } or {
        coin_returned := TRUE;
        fault := TRUE;
      };
  }
}*)
```

Sample invariants:

- `TypeOK == stock \in 0..1 /\ coin_returned \in BOOLEAN /\ fault \in BOOLEAN`
- `AlwaysDispenses == stock = 0` — TLC violates this; the jam branch leaves stock untouched

After the `respond` label, the vendor is in EXACTLY ONE of two states: dispensed (stock = 0) or jammed (coin returned, fault on). Never both. Never neither.

The puzzle below is the same shape — pick a branch, change the right variables, watch TLC enumerate both worlds.

## Setup

An elevator is on the ground floor. A passenger presses a button. They either go to the lobby (floor 1) or up to the office (floor 5). Once the elevator arrives, the doors open.

There's no nondeterminism in the *destination* — lobby is always 1, office is always 5. The nondeterminism is in *which button the passenger pressed*. TLC explores both.

## Task

Write a PlusCal spec with:

- A variable `floor` starting at `0` (ground)
- A variable `doors` starting at `"closed"`
- A single fair process where the elevator:
  1. Uses `either/or` to choose: lobby (`floor := 1`) OR office (`floor := 5`)
  2. Then opens the doors (`doors := "open"`)

## Check

1. **TypeOK**: `floor \in {0, 1, 5} /\ doors \in {"closed", "open"}`
2. **AlwaysOffice**: `floor /= 1` — TLC should violate this (the elevator can stop at the lobby instead)
3. **EventuallyOpen**: `<>(doors = "open")` — a temporal PROPERTY (not an INVARIANT)

## Expected Result

- TLC should report `No error has been found`. State count for the reference solution: 5 (ground/closed, lobby/closed, office/closed, lobby/open, office/open).
- AlwaysOffice violated in a 2-state trace ending at the lobby
- EventuallyOpen passes under weak fairness — the elevator always eventually opens its doors

## Hints

??? hint "💡 Hint 1 — Compare to T03"
    You've seen this exact pattern in T03: the hiker choosing a path. The difference here is your DOMAIN (an elevator, not a hiking trail). Reread the lesson's recap example. Which variable gets different values in the two branches?

??? hint "💡 Hint 2 — Two labels, two outcomes"
    Your spec needs two labels: one for the nondeterministic choice (the `either/or` that sets the floor), and a second for the deterministic action (doors open). The second label depends on the choice made in the first — no branching, just a follow-up.

??? hint "💡 Hint 3 — Brace and or syntax"
    The `either/or` shape is `either { stmt; } or { stmt; };`. Notice: no semicolon after the closing brace of the first branch, just `} or {`. And the whole statement ends with a semicolon after the final brace.
