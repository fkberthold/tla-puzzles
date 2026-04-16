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

A hiker reaches a fork in a trail. They can go left or right. The left path leads to a lake. The right path leads to a summit. After arriving, the hiker sits down.

There's no randomness in the *destination* — left always means lake, right always means summit. The nondeterminism is in the *choice* itself. TLC explores both.

## Task

Write a PlusCal spec with:

- A variable `location` starting at `"fork"`
- A variable `seated` starting at `FALSE`
- A single process where the hiker:
  1. Uses `either/or` to choose: go left (location becomes `"lake"`) OR go right (location becomes `"summit"`)
  2. Then sits down (`seated` becomes `TRUE`)

## Check

1. **TypeOK**: `location` is in `{"fork", "lake", "summit"}`, `seated` is in `{TRUE, FALSE}`
2. **AlwaysAtLake**: `location /= "summit"` — TLC should violate this (the hiker CAN reach the summit)
3. **EventuallySits**: `<>(seated = TRUE)` — a TEMPORAL property (add as PROPERTY in cfg, not INVARIANT)

## Expected Result

- TLC should find **5 distinct states** (fork, lake-standing, summit-standing, lake-seated, summit-seated)
- AlwaysAtLake violated in a 2-state trace
- EventuallySits should PASS (with weak fairness, the hiker always eventually sits)
