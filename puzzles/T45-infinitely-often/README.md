# T45: `[]<>` Infinitely Often ⭐⭐

## Lesson: `[]<>P` — P happens infinitely often

`[]<>P` reads "always eventually P." Unpack it: in EVERY state, EVENTUALLY P is true. Equivalently: "no matter how far into the behavior you go, P will become true again later." Equivalently: "P is true infinitely many times."

This is fundamentally different from `<>P`:

- `<>P` says P happens AT LEAST ONCE.
- `[]<>P` says P happens INFINITELY OFTEN — once is not enough; nor is a million; nor is any finite number.

`[]<>` is the right shape for periodic behaviors: heartbeats, retries, leader rotations, garbage collection, anything you want to keep happening. It's also what fairness conditions (T47) ultimately produce when written out.

`[]<>P` is a temporal property — it only makes sense in PROPERTY, not INVARIANT.

**Worked example — a windshield wiper during a storm.**

The wiper has two positions, `up` and `down`. The system requirement: during operation the wiper must reach `up` infinitely often (not just once — endlessly).

```
(*--algorithm Wiper {
  variables wiper = "down";

  define {
    KeepsWiping == []<>(wiper = "up")
    TypeOK == wiper \in {"up", "down"}
  }

  fair process (motor = "Motor") {
    cycle:
      while (TRUE) {
        either {
          wiper := "up";
        } or {
          wiper := "down";
        };
      }
  }
}*)
```

With weak fairness, the property `[]<>(wiper = "up")` holds: the loop is enabled forever, so the `up` branch is taken infinitely often.

Compare two near-identical claims:

- `<>(wiper = "up")` — at least once during the storm the wiper swings up. A single swipe satisfies it forever.
- `[]<>(wiper = "up")` — the wiper swings up endlessly. One swipe is not enough; the property requires infinite recurrence.

Now imagine a buggy motor that gets stuck. Replace the loop with:

```
cycle:
  wiper := "up";   \* one swipe and stop
```

`<>(wiper = "up")` would still pass — the wiper does reach up. But `[]<>(wiper = "up")` would FAIL: after the one swipe the motor halts, so `up` does not recur. TLC reports a liveness violation showing the lasso (a finite prefix followed by an infinite cycle that never visits `up` again).

The single-shot vs. recurring distinction is exactly what `[]<>` formalizes.

## Setup

A pacemaker sends a heartbeat signal. The signal toggles between `pulse = TRUE` (sending a beat) and `pulse = FALSE` (rest). The medical device claim: "the pulse fires infinitely often" — not just once, but for as long as the device runs.

## Task

Write a PlusCal spec with:

- A variable `pulse = FALSE`
- A `define` block with:
  - `TypeOK == pulse \in BOOLEAN`
  - `BeatsForever == []<>(pulse = TRUE)`
- A `fair process (heart = "Heart")` that loops forever, alternating: set `pulse := TRUE` and then on the next step set `pulse := FALSE`. Use two labels.

In `Heartbeat.cfg`: `INVARIANT TypeOK` and `PROPERTY BeatsForever`.

## Check

1. **TypeOK** holds.
2. **BeatsForever** (`[]<>(pulse = TRUE)`) passes — the heart beats infinitely often.

## Expected Result

- TLC finds **2 distinct states** alternating: `pulse = FALSE` and `pulse = TRUE`.
- `BeatsForever` passes with `fair process` — weak fairness on the heart action keeps the cycle going.
- **Strip test**: replace the body of the loop (everything inside `while (TRUE)`) with a single beat then a permanent rest:
  ```
  beat:
    pulse := TRUE;
  rest:
    pulse := FALSE;
  \* no while — just terminate after one beat
  ```
  Now run TLC. `<>(pulse = TRUE)` would still pass (the heart did beat once). But `[]<>(pulse = TRUE)` is violated: after the single beat, the system stutters forever with `pulse = FALSE`, so `pulse = TRUE` does not recur. TLC produces a short lasso trace ending at the `Done` self-loop. Only `[]<>` catches this "stops beating" bug.
- **Recap**: `<>` is one-shot. `[]<>` is recurring. They are answers to different questions about the system's longevity.
