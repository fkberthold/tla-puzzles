# T34: Tier 3 Capstone — Pure TLA+ from Scratch ⭐⭐⭐

## Lesson: Tier 3 Recap

No new concept. This capstone asks you to compose every piece of pure-TLA+ machinery from this tier into one non-trivial spec:

- **`Init`** as a predicate (T28). Use `=` for fixed values, `\in` for nondeterministic ones.
- **Multiple actions** combined with `\/` in `Next` (T31). Each action is its own named formula.
- **Every action constrains every variable** (T29). Either with a primed equality, or with `UNCHANGED`.
- **Standard `Spec`** shape `Init /\ [][Next]_vars /\ WF_vars(...)` (T32). Stuttering is allowed; weak fairness rules out eternal stuttering.
- **Invariants** verified via `INVARIANT` directives in the cfg (T26 / T0c).

The composition recipe one more time:

1. Identify state. What does the system *know*?
2. Identify transitions. What can change, and under what conditions?
3. Write each transition as a named action. Inside it, mention every variable.
4. Disjunct the actions in `Next`.
5. Define invariants you actually care about. Run TLC. Read the counterexample if any.

Everything in this capstone you have done before. The novelty is doing them all together, from a description, on a system slightly bigger than any single Tier 3 puzzle.

## Setup

Model an **elevator** in a 3-floor building.

**State variables:**

- `floor` — integer `1..3`. Which floor the elevator is currently at.
- `door` — `"open"` or `"closed"`. Door state.
- `direction` — `"up"`, `"down"`, or `"idle"`. The elevator's currently committed direction. Starts `"idle"`.
- `requests` — a set, subset of `1..3`. The set of floors that have outstanding service requests.

**Initial state:** elevator on floor 1, door closed, idle, no requests.

**Actions:**

- **`Request(f)`** — a passenger pushes a button for floor `f`. For any `f \in 1..3` not already in `requests` and not equal to the current floor (no point requesting where you are): add `f` to `requests`. Doesn't move the elevator. Doesn't change floor, door, or direction.
- **`StartUp`** — enabled when `direction = "idle"`, the door is closed, and there is some request `> floor`. Sets `direction' = "up"`, leaves everything else.
- **`StartDown`** — enabled when `direction = "idle"`, the door is closed, and there is some request `< floor`. Sets `direction' = "down"`, leaves everything else.
- **`MoveUp`** — enabled when `direction = "up"`, door closed, `floor < 3`. Sets `floor' = floor + 1`, leaves everything else.
- **`MoveDown`** — enabled when `direction = "down"`, door closed, `floor > 1`. Sets `floor' = floor - 1`, leaves everything else.
- **`OpenDoor`** — enabled when `door = "closed"` and `floor \in requests` (we just arrived at a requested floor). Sets `door' = "open"`, removes `floor` from `requests`, sets `direction' = "idle"` (commit a fresh decision next time).
- **`CloseDoor`** — enabled when `door = "open"`. Sets `door' = "closed"`. Leaves everything else.
- **`GoIdle`** — enabled when `direction \in {"up", "down"}`, the door is closed, the current floor is not requested, and nothing in the committed direction would help (e.g. direction is `"up"` but no request `> floor`). Resets `direction' = "idle"` so the elevator can re-decide. Leaves everything else.

(In a richer model you would track per-direction queues, scheduling, etc. Don't add any of that. The point is to write a clean spec at the level of detail given. `GoIdle` exists only to prevent deadlock when the elevator commits a direction that turns out to be wrong.)

**Invariants to check:**

- **`TypeOK`** — domain bounds for each variable.
- **`DoorClosedWhileMoving`** — `(direction \in {"up", "down"}) => door = "closed"`. Movement only happens with the door closed. (This should hold by the action guards.)
- **`NeverStuckClosedAtRequest`** — a deliberately-flawed invariant for you to discover the trap in: `floor \in requests => door = "open"`. (Spoiler: the elevator can be at a requested floor with the door still closed for one step, before `OpenDoor` fires. This invariant will be **violated**.)

## Task

Author `solution/Elevator.tla` from scratch. The spec should be ~50 lines of pure TLA+. Use the standard shape:

```
Spec == Init /\ [][Next]_vars /\ WF_vars(Next)
```

Author `solution/Elevator.cfg` with:

```
SPECIFICATION Spec
INVARIANT TypeOK
INVARIANT DoorClosedWhileMoving
INVARIANT NeverStuckClosedAtRequest
```

Hint: the `requests` variable is a set. To say "there is some request greater than the current floor" use `\E r \in requests : r > floor`. To remove `floor` from requests, write `requests' = requests \ {floor}`. To add a request `f`, write `requests' = requests \cup {f}`.

## Check

```bash
cd solution
tlc Elevator
```

## Expected Result

- `TypeOK` — passes.
- `DoorClosedWhileMoving` — passes (the action guards enforce it).
- `NeverStuckClosedAtRequest` — **violated**. The trace TLC reports:
  - State 1: `floor=1, door="closed", direction="idle", requests={}`
  - State 2: `requests={2}` (`Request`)
  - State 3: `direction="up"` (`StartUp`)
  - State 4: `floor=2, direction="up"` (`MoveUp`) — now `floor \in requests` but `door = "closed"`. The invariant fails here, BEFORE `OpenDoor` fires.

Trace length: **4 states**.

The takeaway about that violation: it's not a bug in the elevator — it's a bug in the *invariant*. Reaching a requested floor with the door still closed is a normal transient state. A correct invariant would be something like `door = "open" => floor \notin requests` (door never opens at a non-request) or a temporal property `[](floor \in requests => <>(door = "open"))` (every request is eventually serviced — needs liveness, T42 territory).

State count for the full reachable space (with the bad invariant disabled, e.g., commented out): TLC should report **54 distinct states**.

If your spec deadlocks, the most common cause is a committed direction with no useful destination. The `GoIdle` action exists for exactly this reason — without it, an elevator on floor 3 with `direction = "up"` and a request only on floor 1 would have no enabled action.

If your state count is much higher than 100, you may have left a primed variable unconstrained somewhere. Re-check every action: every variable, every time.

## Hints

??? hint "💡 Hint 1 — Start with state, then transitions"
    The elevator has four variables: floor, door, direction, requests. Write `TypeOK` to constrain each. Then sketch the actions on paper: which ones change floor? Which change door? Which change direction or requests? This ensures you list every action and know which variables each affects.

??? hint "💡 Hint 2 — Every action mentions every variable"
    You have four variables. Every action (Request, StartUp, StartDown, MoveUp, MoveDown, OpenDoor, CloseDoor, GoIdle) must assign or `UNCHANGED` all four. If an action only updates `direction`, the other three must be `UNCHANGED <<floor, door, requests>>`. This is the most common source of error in multi-variable specs.

??? hint "💡 Hint 3 — The flawed invariant teaches a lesson"
    `NeverStuckClosedAtRequest` says `floor \in requests => door = "open"`. This *seems* true, but TLC will violate it. Why? Because the elevator can arrive at a requested floor (state has `floor \in requests`) but before `OpenDoor` fires, the door is still closed. That is a valid transient state. Use TLC's counterexample to trace the violation and understand why it is not a bug in the elevator—it's a bug in the invariant's expectation.
