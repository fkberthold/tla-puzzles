# T44b: Leads-To Failure — When ~> Doesn't Hold ⭐⭐

## Lesson: When a `~>` property fails

T44 introduced `~>` (leads-to): the temporal formula `P ~> Q` means `[](P => <>Q)` — "whenever P holds, eventually Q."

This feels safe: "if you publish, someone will receive." But **leads-to can FAIL** if you don't ensure the actions that make Q true are actually scheduled.

There are two failure modes:

### Failure Mode 1: Missing Fairness

If the action that MAKES Q true has **no fairness annotation**, TLC is allowed to ignore it forever.

```
process (actor = "Worker") {      \* BUG: no `fair`!
  loop:
    while (TRUE) {
      await enabledForQ;
      makeQTrue;
    }
}
```

The enabling condition `enabledForQ` holds, but the process is never scheduled. The state space stays in a loop where P is true but Q never happens. Result: `P ~> Q` is violated.

The fix: add `fair` to the process declaration.

### Failure Mode 2: Q's Enablement Depends on an Unanswered Precondition

Even with fairness, if the action's `await` guard depends on something that the system NEVER makes true, the action will never fire.

```
process (actor = "Worker") {
  loop:
    while (TRUE) {
      await P /\ someCondition;   \* someCondition is NEVER set true
      Q := TRUE;
    }
}
```

If no other process sets `someCondition`, the action is disabled forever. Fairness doesn't help: WF (weak fairness) requires the action to be **continuously enabled**, and it isn't. The system can satisfy fairness by never enabling the action.

### Why This Matters

`P ~> Q` is how you write "request eventually gets an answer," "job eventually completes," "node eventually recovers." If you forget fairness or leave a precondition hanging, TLC will find a behavior where the promise is broken. The lasso is short and clear — the system stutters in a state where P is true but Q never happens. That's the symptom; the cure is a fairness annotation (or restructuring the action's guards).

---

## Worked Example — A Water Cooler

A water cooler has a dispenser and a status light.

When the tank is LOW, the cooler **must eventually refill**. That's `low ~> ~low`.

But here's the broken spec:

```
(*--algorithm WaterCooler {
  variables low = TRUE, refilling = FALSE;

  define {
    TypeOK == low \in BOOLEAN /\ refilling \in BOOLEAN
    EventuallyRefilled == low ~> ~low
  }

  fair process (user = "User") {
    use:
      while (TRUE) {
        either {
          await ~low;
          skip;           \* use the water (do nothing in spec)
        } or {
          await TRUE;
          low := TRUE;    \* tank becomes low (unpredictable)
        };
      }
  }

  process (pump = "Pump") {        \* BUG: no `fair`!
    refill:
      while (TRUE) {
        await low;
        refilling := TRUE;
        low := FALSE;
        refilling := FALSE;
      }
  }
}*)
```

Run TLC with `PROPERTY EventuallyRefilled`. The violation trace is:

```
State 1: low=TRUE, refilling=FALSE   (init — tank is low)
State 2: Stuttering
```

The pump's action `refill` is enabled (the guard `await low` is true), but the pump process is NEVER SCHEDULED. Because `process (pump = ...)` has no fairness annotation, TLC is allowed to ignore it forever. The property `low ~> ~low` fails: we reach a state where `low = TRUE` but it never becomes `FALSE`.

**The fix:** change `process (pump = ...)` to `fair process (pump = ...)`. The pump is now weakly fair; TLC must eventually run it. Re-translate and re-run: the property holds.

---

## Setup

A broadcast publisher sends notifications. When the publisher has something to announce (`published = TRUE`), a subscriber should eventually pick it up (`received = TRUE` and the publisher resets to `published = FALSE`).

The property: `published ~> received`. "Whenever published, eventually received."

In a healthy system, this would hold — both the publisher and subscriber are scheduled fairly. But the starter spec has a deliberate fairness bug: the subscriber process lacks the `fair` annotation. TLC will find a SHORT counterexample where the publisher announces but the subscriber is never scheduled, so the system stutters forever in state `(published=TRUE, received=FALSE)`.

## Task

1. **Run TLC on the broken spec:**
   ```
   cd solution
   tlc -pcal Broadcast.tla
   tlc Broadcast
   ```
   Read the lasso counterexample. Identify the state where the system gets stuck.

2. **Understand the violation:** The property `published ~> received` fails because:
   - The publisher's action is enabled and fires (sets `published = TRUE`)
   - The subscriber's action is ALSO enabled (the guard `await published` is satisfied)
   - But the subscriber process has no `fair` annotation, so TLC is allowed to ignore it forever
   - Result: the system reaches a state where `published = TRUE` but `received` never becomes TRUE

3. **Fix the spec:** Edit `Broadcast.tla`. Change EXACTLY ONE keyword on the subscriber process declaration. Add the `fair` annotation.

4. **Re-translate and re-verify:**
   ```
   tlc -pcal Broadcast.tla
   tlc Broadcast
   ```
   TLC should now report "No error has been found."

In `Broadcast.cfg`:

```
SPECIFICATION Spec
INVARIANT TypeOK
PROPERTY PublishedEventuallyReceived
CHECK_DEADLOCK FALSE
```

## Check

1. **Before the fix**: TLC reports a temporal-property violation with a SHORT lasso (≤4 states). The final state shows `published=TRUE` and `received=FALSE`, with the system at "Stuttering" — no progress.
2. **After the fix**: TLC reports "No error." `PublishedEventuallyReceived` (`published ~> received`) holds.

## Expected Result

- **Broken-spec lasso**: roughly 3 states —
  - State 1: `published=FALSE, received=FALSE` (initial)
  - State 2: `published=TRUE, received=FALSE` (publisher fires)
  - State 3: Stuttering (subscriber never runs, system stuck)

- **Fixed-spec output**: TLC explores roughly 4–6 distinct states, verifies both the invariant and the property, and reports success.

- **The fix**: change `process (subscriber = "Subscriber")` to `fair process (subscriber = "Subscriber")` — one word added.

- **Strip test (QG #3)**: Remove the leads-to property. Change `PROPERTY PublishedEventuallyReceived` to `\* PROPERTY PublishedEventuallyReceived`. Re-run TLC on the broken spec. There's no property violation because TLC only checks the invariant `TypeOK`, which holds trivially. The leads-to property is the load-bearing concept. With it, TLC forces you to add fairness; without it, the bug hides.
