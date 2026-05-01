# T47: Strong Fairness ⭐⭐

## Lesson: `SF_vars(A)` — the action that flickers in and out

Weak fairness (WF, the `fair process` you've used since T01) says:

> If action A is **continuously** enabled from some point on, then A eventually fires.

Strong fairness (SF) says:

> If action A is **repeatedly** enabled (enabled infinitely often), then A eventually fires (in fact infinitely often).

The difference is what counts as "enough enabledness to deserve a turn":

- WF: A must stay enabled without interruption.
- SF: A only needs to BECOME enabled infinitely often. It can flicker.

If an action is enabled and disabled and enabled and disabled forever, WF gives no guarantee — the action is never "continuously enabled." SF guarantees it fires anyway.

In PlusCal:

| Keyword | Fairness on the process's actions |
|---------|-----------------------------------|
| `process` | none (no fairness) |
| `fair process` | WF — weak fairness |
| `fair+ process` | SF — strong fairness |

The `+` is literally the syntax: `fair+ process (...) { ... }`. Translates to `SF_vars(...)` instead of `WF_vars(...)` in the generated TLA+.

In raw TLA+ (no PlusCal) you write the conjunct directly:

```
Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(steady_action)
        /\ SF_vars(flickering_action)
```

**Worked example — a bus stop with a request button.**

A bus drives by repeatedly. It only stops if a passenger has pressed the request button. Passengers arrive intermittently and leave the queue when picked up, so the "request" condition flickers: there's a button, then there isn't, then there is.

```
(*--algorithm Bus {
  variables waiting = FALSE, atStop = FALSE;

  define {
    PassengerEventuallyPickedUp == [](waiting => <>~waiting)
    TypeOK == waiting \in BOOLEAN /\ atStop \in BOOLEAN
  }

  fair process (passenger = "Passenger") {
    arrive:
      while (TRUE) {
        either {
          await ~waiting;
          waiting := TRUE;     \* press the request button
        } or {
          skip;                \* don't press this round
        };
      }
  }

  fair+ process (bus = "Bus") {
    drive:
      while (TRUE) {
        await waiting;         \* only stop when requested
        atStop := TRUE;
        waiting := FALSE;      \* picked up the passenger
        atStop := FALSE;
      }
  }
}*)
```

The bus's `drive` action is enabled only while `waiting = TRUE`. Each pickup makes it FALSE; each new press makes it TRUE again. Across the behavior, `waiting` flickers. The bus action is never CONTINUOUSLY enabled — the moment it fires, `waiting` becomes FALSE and the action disables itself.

With WEAK fairness on the bus (`fair process`), TLC could find a behavior where the passenger presses, the bus driver decides to take a stutter step (allowed because `waiting` will become false again on the next press cycle), and the property `[](waiting => <>~waiting)` fails. Actually the failure mode is more subtle: WF doesn't fire actions whose enabledness oscillates.

With STRONG fairness (`fair+ process`), the bus is required to fire whenever `waiting` is enabled infinitely often. So every pickup happens. The leads-to-style property holds.

The rule of thumb: **if your action gets DISABLED by its own firing (like a "consume from queue" or "release lock" action) and the precondition is re-armed by another process, you probably need SF**. WF works for actions that stay enabled until they fire, like incrementing a counter.

In the cfg, both kinds of fairness are part of `Spec`, so you don't add a special directive. Just write `SPECIFICATION Spec` as usual. The fairness conjuncts come from the PlusCal translation.

## Setup

A printer has a single job slot. Users submit print jobs one at a time. The printer only prints when there's a job in the slot. After printing, the slot is empty until a new job arrives. Users sometimes pause submitting; the slot's `hasJob` flag flickers.

The user expectation: every submitted job is eventually printed.

## Task

Write a PlusCal spec with:

- Variables `hasJob = FALSE`, `printed = 0`
- A `define` block with:
  - `TypeOK == hasJob \in BOOLEAN /\ printed \in 0..3`
  - `JobsServed == []<>(printed = 3)` — eventually all 3 jobs are printed (we cap so the state space is finite)
- A `fair process (user = "User")` that submits up to 3 jobs total. Each iteration:
  - `await ~hasJob`
  - if `printed < 3`, set `hasJob := TRUE`
- A `fair+ process (printer = "Printer")` that loops forever:
  - `await hasJob`
  - `printed := printed + 1`
  - `hasJob := FALSE`

Why `fair+` on the printer? Because each print FIRES the action and immediately disables it (clearing `hasJob`). The action is intermittently enabled, so weak fairness won't suffice; strong fairness will.

In `Printer.cfg`:

```
SPECIFICATION Spec
INVARIANT TypeOK
PROPERTY JobsServed
CHECK_DEADLOCK FALSE
```

The `CHECK_DEADLOCK FALSE` line tells TLC not to flag a deadlock when the user reaches `Done` (no more jobs to submit) and the printer is blocked on `await hasJob`. We're not modeling shutdown — the printer's purpose here is the SF demonstration, and `[]<>(printed = 3)` only requires that 3 prints happen, not that the printer terminates afterward.

## Check

1. **TypeOK** holds.
2. **JobsServed** (`[]<>(printed = 3)`) passes — every job is eventually printed.

## Expected Result

- TLC finds a small state space — about **8 distinct states** covering combinations of `hasJob`, `printed`, and the two pcs.
- `JobsServed` passes with `fair+ process` on the printer.
- **Strip test**: change `fair+ process` to `fair process` on the printer (downgrade SF to WF). Re-translate (`tlc -pcal Printer.tla`) and re-run. The property's checked behavior depends on TLC's interpretation: depending on TLC's WF semantics for this exact pattern you may or may not see a violation directly. The point of the lesson is mechanical: `fair+` produces `SF_vars(...)` in the translation; `fair` produces `WF_vars(...)`. Open `Printer.tla` after both translations and read the `Spec ==` block to see the difference. The cfg never changes.
- **Inspect the translation**: at the bottom of `Printer.tla`, look for the `Spec ==` definition. With `fair+` on the printer, you should see `SF_vars(printer)` (not `WF_vars(printer)`). That generated formula is the new concept this puzzle teaches.
