# T03: The Fork in the Road ⭐

## Lesson: Nondeterminism in CONTROL FLOW with `either/or`

In T02, `with` chose a VALUE from a set. `either/or` is different — it chooses which BRANCH of code to execute. `with` selects data; `either/or` selects behavior. TLC explores both branches automatically.

**Worked example — a cat deciding what to do.**

A cat is on a kitchen counter. It might jump to the floor, or it might stare at you without moving. The two possibilities aren't data that differ — they're different ACTIONS the cat takes.

```
(*--algorithm Cat {
  variables position = "counter", watching = FALSE;

  fair process (cat = "Whiskers") {
    decide:
      either {
        position := "floor";
      } or {
        watching := TRUE;
      };
  }
}*)
```

Sample invariants:

- `TypeOK == position \in {"counter", "floor"} /\ watching \in BOOLEAN`
- `AlwaysJumps == position = "floor"` — TLC WILL violate this; the "stare" branch leaves the cat on the counter

TLC explores both branches. After the `decide` label, the cat is in exactly one of two terminal states: on the floor (having jumped) OR on the counter with `watching = TRUE` (having stared). Never both. Never neither.

**Syntax detail:** branches are braced blocks separated by `or`. No comma or semicolon between the blocks — just `} or {`.

Note that `either` branches can assign DIFFERENT variables. In this example, the jump branch touches `position`; the stare branch touches `watching`. Either is fine — the one-assignment-per-label rule only applies WITHIN a single branch's execution.

## Setup

A hiker reaches a fork in a trail. They can go left to a lake or right to a summit. The destination is determined by the choice: left always means lake, right always means summit — the nondeterminism is in the *choice* itself, not the geography. After arriving at either spot, the hiker eats a snack from their pack: granola, an apple, or trail mix. Which snack they pull out is also unknown until they reach into the pack.

Two independent sources of nondeterminism stack here. `either/or` (the new concept) decides the branch of code; `with` (from T02) picks the snack value. TLC explores every combination.

## Task

Write a PlusCal spec with:

- A variable `location` starting at `"fork"`
- A variable `snack` starting at `"none"`
- A single process where the hiker:
  1. Uses `either/or` to choose: go left (location becomes `"lake"`) OR go right (location becomes `"summit"`)
  2. Then uses `with (s \in {"granola", "apple", "trail_mix"}) { snack := s; }` to pick a snack

The `with` selection composes with the `either/or` choice — your spec must combine both kinds of nondeterminism, not just one.

## Check

1. **TypeOK**: `location` is in `{"fork", "lake", "summit"}`, `snack` is in `{"none", "granola", "apple", "trail_mix"}`
2. **AlwaysAtLake**: `location /= "summit"` — TLC should violate this (the hiker CAN reach the summit)
3. **EventuallyHasSnack**: `<>(snack /= "none")` — a TEMPORAL property (add as PROPERTY in cfg, not INVARIANT)

## Expected Result

- TLC should report `No error has been found` (TypeOK and EventuallyHasSnack should pass)
- AlwaysAtLake should be violated in a short trace
- The canonical solution reports **9 distinct states** — initial (fork, none), two intermediate (lake/summit, none), and six terminal (lake/summit × granola/apple/trail_mix). The state-space multiplication is the point: 2 paths × 3 snacks = 6 outcomes, plus the path-only intermediates. Label choices may yield different counts, but the multiplicative structure stays.

## Hints

??? hint "💡 Hint 1 — `either/or` is about behavior; `with` is about data"
    `either/or` picks which BRANCH of code to execute. `with` picks a VALUE from a set. The puzzle uses both: `either/or` decides where the hiker goes, `with` decides what they eat. Neither alone explains the state space — the multiplication does.

??? hint "💡 Hint 2 — Two labels, two kinds of nondeterminism"
    Put the `either/or` in one label (e.g., `choose:`) and the `with` in the next label (e.g., `eat:`). Inside the `eat:` label, `with (s \in {"granola", "apple", "trail_mix"}) { snack := s; }` binds `s` for the scope of the block and assigns it to `snack`. Both nondeterministic constructs are exhaustively explored by TLC.

??? hint "💡 Hint 3 — Temporal properties use PROPERTY, not INVARIANT"
    `EventuallyHasSnack` is a PROPERTY (`<>(snack /= "none")`) because it talks about BEHAVIOR — "at some point in the future, the snack is no longer `none`." Invariants check individual states. Properties check entire execution paths. Use the right cfg directive. Without `fair process`, TLC might not guarantee the eat step ever runs, and the property could fail.
