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

A printer has a single job slot. The user submits jobs one at a time — but can also cancel a pending job (the job is still in the queue but the user decides not to wait). This means the slot's `hasJob` flag genuinely **flickers**: the user sets it TRUE on submit and FALSE on cancel.

The printer only prints when there is a job (`hasJob = TRUE`). After printing, the slot is cleared. The printer tracks a rolling count of prints, cycling back to 0 after every 3. The user expectation: the printer completes every batch of 3 jobs infinitely often.

## Task

Write a PlusCal spec with:

- Variables `hasJob = FALSE`, `printed = 0`
- A `define` block with:
  - `TypeOK == hasJob \in BOOLEAN /\ printed \in 0..3`
  - `JobsServed == []<>(printed = 3)` — the printer reaches 3 prints infinitely often
- A `fair process (user = "User")` that loops forever with an `either/or`:
  - Either: `await ~hasJob; hasJob := TRUE` (submit a job)
  - Or: `await hasJob; hasJob := FALSE` (cancel the pending job)
- A `fair+ process (printer = "Printer")` that loops forever:
  - `await hasJob`
  - increment `printed` mod 3 (if `printed < 3` then `printed + 1`, else reset to `0`)
  - `hasJob := FALSE`

Why `fair+` on the printer? The user can cancel any pending job, so `hasJob` **flickers** — it becomes TRUE on submit and FALSE on cancel. The printer action is enabled only while `hasJob = TRUE`. Since a cancel can disable it at any moment, the action is never *continuously* enabled; it is only *repeatedly* enabled. Weak fairness gives no guarantee here. Strong fairness does.

In `Printer.cfg`:

```
SPECIFICATION Spec
INVARIANT TypeOK
PROPERTY JobsServed
CHECK_DEADLOCK FALSE
```

## Check

1. **TypeOK** holds.
2. **JobsServed** (`[]<>(printed = 3)`) passes — the printer completes every batch of 3 infinitely often.

## Expected Result

- TLC should report `No error has been found`. The canonical solution explores **8 distinct states** covering all combinations of `hasJob ∈ {FALSE, TRUE}` and `printed ∈ {0, 1, 2, 3}`; your spec may produce more if you split any action into multiple labels — that's fine.
- `JobsServed` passes with `fair+ process` on the printer.
- **Strip test**: change `fair+ process` to `fair process` on the printer (downgrade SF to WF). Re-translate (`tlc -pcal Printer.tla`) and re-run. TLC will **definitely** report a temporal property violation — `Temporal properties were violated`. The counterexample is a lasso where the user alternates between submitting and immediately canceling: `hasJob` flickers TRUE/FALSE forever and the printer never fires past `printed = 2`. This is the WF failure mode the lesson is about.
- **Inspect the translation**: at the bottom of `Printer.tla`, look for the `Spec ==` definition. With `fair+` on the printer, you should see `SF_vars(printer)` (not `WF_vars(printer)`). With `fair`, you see `WF_vars(printer)`. That one-word difference is the lesson.

## Hints

??? hint "💡 Hint 1 — The enabled/disabled flickering"
    The printer's action fires when `hasJob = TRUE`. But the user can cancel at any time: `await hasJob; hasJob := FALSE`. That cancel sets `hasJob = FALSE` and disables the printer — without the printer having printed anything. Then the user might re-submit (TRUE) and cancel again (FALSE), indefinitely. The printer is repeatedly enabled, but never continuously. What fairness does that pattern require?

??? hint "💡 Hint 2 — Why weak fairness fails here"
    WF says "if continuously enabled, eventually fires." But the user's cancel action can disable the printer at any moment. The printer is never *continuously* enabled — it flickers. SF says "if repeatedly enabled, eventually fires." The user will keep submitting (enabling the printer) infinitely often, so SF forces the printer to fire.

??? hint "💡 Hint 3 — The `fair+ process` syntax"
    Use `fair+ process (printer = "Printer")` (note the `+`). After pcal translates, look at the `Spec ==` block: you should see `SF_vars(printer)` instead of `WF_vars(printer)`.
