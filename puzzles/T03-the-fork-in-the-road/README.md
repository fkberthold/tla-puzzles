# T03: The Fork in the Road ⭐

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

## Concept

**Nondeterministic CONTROL FLOW with `either/or`.** In T02, `with` chose a VALUE from a set. Here, `either/or` chooses which BRANCH to execute. Both are nondeterminism, but they work differently: `with` selects data, `either/or` selects behavior. TLC explores both branches automatically.
