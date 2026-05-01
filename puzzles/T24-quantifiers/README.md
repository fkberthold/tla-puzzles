# T24: Quantifiers in Invariants ⭐

## Lesson: `\A` and `\E` — Universal and Existential

You've SEEN quantifiers throughout Tier 2 — `\A x \in S : P(x)` in TypeOK clauses, `\E x \in S : P(x)` implicitly in `with`. T24 makes them the focus.

**`\A x \in S : P(x)`** — read "for all `x` in `S`, `P(x)` holds." TRUE if every element of `S` satisfies `P`.

```
\A n \in 1..5 : n > 0                  \* TRUE
\A n \in 1..5 : n > 3                  \* FALSE — n = 1 fails
\A n \in {} : whatever                 \* TRUE — vacuously, the empty set has no counterexample
```

**`\E x \in S : P(x)`** — read "there exists `x` in `S` such that `P(x)`." TRUE if at least one element of `S` satisfies `P`.

```
\E n \in 1..5 : n > 3                  \* TRUE — 4 and 5 work
\E n \in 1..5 : n > 100                \* FALSE — none of them
\E n \in {} : TRUE                     \* FALSE — vacuously, no element to satisfy
```

**Both forms are BOUNDED.** You always quantify over a SET — `x \in S`. Unbounded quantifiers exist in TLA+ but TLC can't check them; you'll always see the bounded form in invariants.

**Combining them:**

```
\A x \in Roster : \E y \in Roster : x /= y           \* every roster member has SOMEONE else in the roster
\E x \in Roster : \A y \in Roster : balance[x] >= balance[y]   \* there's a maximum-balance member
```

Order matters. `\A x : \E y` says "for every x, there's SOME y (possibly different for each x)." `\E y : \A x` says "there's a SINGLE y that works for ALL x." The second is stronger.

**Worked example — a school checking attendance.**

A teacher tracks each student's attendance status. Three useful invariants use quantifiers:

- TypeOK: every student's status is one of the allowed values.
- AnyMissing: there exists a student who's absent.
- AllPresent: every student is present.

```
(*--algorithm Class {
  variables
    status = [s \in {"alex", "bo", "cy"} |-> "present"];

  define {
    Students == DOMAIN status

    \* TypeOK uses \A: every student's status is in the allowed set
    TypeOK == \A s \in Students : status[s] \in {"present", "absent", "tardy"}

    \* Existential: at least one student is absent
    AnyAbsent == \E s \in Students : status[s] = "absent"

    \* Universal: every student is present
    AllPresent == \A s \in Students : status[s] = "present"
  }

  fair process (teacher = "Teacher") {
    take:
      with (a \in [Students -> {"present", "absent", "tardy"}]) {
        status := a;
      };
  }
}*)
```

Sample invariants you'd CHECK:

- `TypeOK` — passes (the function-set guarantees each value is in the allowed set)
- `AllPresent` — TLC violates this; one of the assignments has someone absent

Notice how `AnyAbsent` and `AllPresent` are not negations of each other! `~AllPresent` says "at least one student is NOT present" (could be absent OR tardy). `AnyAbsent` is more specific. Quantifier mechanics are subtle — keep the predicate's exact form in mind.

**De Morgan, briefly.** Two equivalences worth remembering:

- `~(\A x \in S : P(x))  <=>  \E x \in S : ~P(x)`   ("not all P" = "some not-P")
- `~(\E x \in S : P(x))  <=>  \A x \in S : ~P(x)`   ("no P" = "all not-P")

You'll see them when TLC reports a violated `\A` invariant — the witness is the `\E` counterexample.

## Setup

A small fleet of 4 delivery drones each report a battery level (1..10) and a status (`"flying"`, `"docked"`, or `"low"`). The dispatcher wants to verify several properties using quantifiers:

- All drones have a battery level in the safe range.
- At least one drone is docked.
- Every drone with a low battery is in the `"low"` status (consistency).

You'll use both `\A` and `\E` in the invariants and let TLC sweep through possible drone states.

## Task

Write a PlusCal spec with:

- A variable `battery` initialized to `[d \in 1..4 |-> 10]` (all full)
- A variable `state` initialized to `[d \in 1..4 |-> "docked"]` (all docked)
- A variable `phase` starting at `0`

In the `define` block:

- `Drones == 1..4`
- `BatteryLevels == 1..10`
- `States == {"flying", "docked", "low"}`
- `TypeOK == \A d \in Drones : battery[d] \in BatteryLevels /\ state[d] \in States`
- `AnyDocked == \E d \in Drones : state[d] = "docked"`
- `LowConsistent == \A d \in Drones : (battery[d] <= 2 => state[d] = "low")`
- `AllSafe == \A d \in Drones : battery[d] >= 3`  \* this CAN be violated by some assignments

A single fair process runs one label:

1. **report**: nondeterministically assign new battery and state functions:
   ```
   with (b \in [Drones -> BatteryLevels]) {
     with (s \in [Drones -> States]) {
       battery := b;
       state := s;
     };
   };
   phase := phase + 1;
   ```

(That's a heavy nondeterministic step — `[Drones -> BatteryLevels]` is `10^4 = 10000` functions, times `3^4 = 81` for state. Don't worry: TLC handles it. The state space will be ~810,000 states.)

Wait, that's too big. Use a smaller domain. Reduce battery levels to `1..3` for the nondeterministic step:

A single fair process runs one label:

1. **report**: nondeterministically assign:
   ```
   with (b \in [Drones -> 1..3]) {
     with (s \in [Drones -> States]) {
       battery := b;
       state := s;
     };
   };
   phase := phase + 1;
   ```

(That's `3^4 * 3^4 = 6561` reachable post-report states. Still substantial but tractable.)

## Check

1. **TypeOK** — see above. The `with`-bounded values guarantee this passes.
2. **LowConsistent** — TLC will VIOLATE this. Some assignment has a drone with battery=1 (low) but state="flying" or "docked", not "low".
3. **AnyDocked** — TLC will violate this too: some assignment has no drone docked.

For the puzzle's primary verification, list `LowConsistent` as a checked invariant and confirm TLC finds a violation. Use a SHORT trace.

## Expected Result

- Without the `LowConsistent` invariant, TLC sweeps through ~6500+ states and TypeOK passes.
- WITH `LowConsistent` enabled, TLC reports a violation in 2 states (initial + report).
- The trace shows a single drone with battery=1 and state="flying" (or similar mismatch).

**Bonus.** Replace `LowConsistent` with its de Morgan dual: `~\E d \in Drones : (battery[d] <= 2 /\ state[d] /= "low")`. Predict whether the violation set is the same. (Answer: yes — they're logically equivalent. The traces should agree.)

## Hints

??? hint "💡 Hint 1 — Universal says 'for every'"
    `\A d \in Drones : P(d)` is TRUE if EVERY drone `d` satisfies `P(d)`. If even ONE drone violates `P`, the universal is FALSE. Use `\A` when you need a property to hold EVERYWHERE.

??? hint "💡 Hint 2 — Existential says 'there exists at least one'"
    `\E d \in Drones : P(d)` is TRUE if AT LEAST ONE drone `d` satisfies `P(d)`. If NO drone satisfies `P`, it's FALSE. Use `\E` when you need to assert that SOMETHING exists.

??? hint "💡 Hint 3 — LowConsistent checks consistency"
    The invariant `LowConsistent == \A d \in Drones : (battery[d] <= 2 => state[d] = "low")` says "for every drone, if its battery is low, its state MUST be 'low'." TLC will find drones where battery <= 2 but state is "flying" or "docked" — that violates the implication. The trace will show one such drone as the counterexample.
