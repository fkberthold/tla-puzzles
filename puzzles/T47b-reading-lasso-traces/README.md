# T47b: Reading Lasso Traces ⭐

**Tier 5 prelude.** No new concept. No code to write. The goal is to recognize what TLC's liveness-violation output looks like and learn how to read a counterexample that forms a lasso — the infinite loop that breaks a liveness property.

## What this puzzle is

A pre-written spec lives in `solution/Clock.tla`. It models a clock that should eventually reach noon (a liveness property: `ReachesNoon == <>( hour = 12 )`). The spec has two processes: a resetter that keeps flipping a flag, and a ticker that waits for the flag to be stable before advancing the hour. Without fairness on the resetter, TLC finds a behavior where the resetter flips the flag forever, preventing the ticker from ever firing.

You are not expected to understand the spec yet. The goal is reading TLC's lasso output.

## Run it

From this directory:

```bash
cd solution
tlc -pcal Clock.tla
tlc Clock
```

Same two commands as T0b. This time, TLC reports a **temporal property violation** — something new.

## What to look for

TLC prints something like:

```
Error: Temporal properties were violated.

Error: The following behavior constitutes a counter-example:

State 1: <Initial predicate>
/\ hour = 11
/\ reset = FALSE
/\ pc = [Resetter |-> "loop", Ticker |-> "advance"]

State 2: <loop line 45, col 9 to line 48, col 23 of module Clock>
/\ hour = 11
/\ reset = TRUE
/\ pc = [Resetter |-> "loop", Ticker |-> "advance"]

Back to state 1: <loop line 45, col 9 to line 48, col 23 of module Clock>
```

Three things to notice:

1. **The violation is a behavior, not a single state.** Unlike T0b (which reported a state where an invariant was false), this error says "temporal properties were violated." That's TLC's way of saying "I found an infinite sequence that breaks a liveness property." Since infinite sequences can't be printed, TLC shows you a lasso: a finite prefix (the "stem") followed by a part that repeats forever (the "cycle").

2. **The lasso structure: stem + cycle.** State 1 is the initial state — this is part of the stem (the prefix). State 2 is reachable from State 1. Then "Back to state 1" marks the back-edge: the spot where the repeating cycle CLOSES. Everything from State 1 through State 2 and back to State 1 will repeat forever. That cycle, looping infinitely, is the violation: the property `ReachesNoon == <>( hour = 12 )` demands that we eventually reach `hour = 12`, but the cycle never does — it just flips `reset` back and forth while `hour` stays stuck at 11.

3. **What TLC is allowed to schedule.** Open `solution/Clock.tla` (or click the 🔒 spoiler below) and find this definition:

   ```tla
   process (resetter = "Resetter") {
     loop:
       while (TRUE) {
         reset := ~reset;
       }
   }
   ```

   Notice: no `fair` keyword. Without fairness, TLC is allowed to schedule the resetter action infinitely often (or not at all — fairness is not required). In the lasso, TLC schedules it forever. If you added `fair process` or `fair+ process` to the resetter, the property would likely hold, because fairness would eventually force the ticker to run.

## Lasso Anatomy

A **stem** is the prefix of states leading into the cycle. It starts at State 1.

A **cycle** is the part that repeats infinitely. It's marked by "Back to state N" — the point where execution returns to an earlier state and will loop there forever.

In this puzzle:
- **Stem length**: 1 state (just the initial state before any action)
- **Back-edge**: The transition from State 2 back to State 1
- **Cycle length**: 1 state repeating (State 2 looping back to State 1, then back to State 2, etc.)
- **Total trace shown**: 2 states

The cycle never reaches `hour = 12`, so `ReachesNoon` fails. That's the violation.

## Lesson: A worked example in a different domain

**The problem:** A vending machine has a coin slot and a dispense button. Users insert coins, then press the button. The machine should eventually dispense the item. But the coin-slot mechanism has a bug: it keeps toggling the "coin inserted" flag on and off forever, never settling.

```
(*--algorithm VendingMachine {
  variables coinInserted = FALSE, dispensed = FALSE;

  define {
    EventuallyDispensed == <>( dispensed = TRUE )
  }

  process (coinSlot = "CoinSlot") {
    pulse:
      while (TRUE) {
        coinInserted := ~coinInserted;
      }
  }

  fair process (dispenser = "Dispenser") {
    check:
      while (~dispensed) {
        await coinInserted;
        dispensed := TRUE;
      }
  }
}*)
```

Run TLC with the property `EventuallyDispensed`:

```
State 1: coinInserted = FALSE, dispensed = FALSE
State 2: coinInserted = TRUE, dispensed = FALSE

Back to state 1:
```

**Reading the lasso:**
- State 1 is the initial state (stem).
- State 2 is where the coin slot fires, setting `coinInserted = TRUE`.
- The back-edge points from State 2 back to State 1.
- The cycle repeats: State 1 → State 2 → State 1 → State 2 → ...
- Inside this cycle, the dispenser is stuck in its `check` label, waiting for `coinInserted` to become TRUE (State 2), but before it can act, the coin slot fires again, toggling it back to FALSE (returning to State 1). The dispenser never gets a guaranteed turn.
- Since the cycle never sets `dispensed = TRUE`, the property fails.

**The fix:** Add `fair` to the coin slot. Then weak fairness guarantees that if the dispenser's `await` condition `coinInserted` is continuously enabled, the dispenser will eventually fire. But in this case, `coinInserted` flickers (enabled in State 2, disabled in State 1), so weak fairness doesn't apply. The real fix would be to change the coin-slot hardware (stop toggling the flag), or add `fair+` (strong fairness) to the dispenser — see T47 for details on strong fairness.

The point here: a lasso shows you an infinite loop that violates a liveness property. The cycle repeats forever while the property's eventual state is never reached.

## What to take away

- A liveness-property violation produces a **lasso**: a finite prefix (stem) + a repeating part (cycle).
- **"Back to state N"** marks the back-edge, where the cycle closes.
- Everything inside the cycle repeats infinitely. If the property's goal is not satisfied in the cycle, the property fails.
- The cycle shows you which process(es) are firing and which are stuck. Look for an action that SHOULD fire but is being starved (no fairness) or whose precondition is being sabotaged by another process.
- Most liveness violations come from two causes:
  - **A process with no fairness** — change `process` to `fair process`.
  - **A process with weak fairness when it needs strong fairness** — change `fair process` to `fair+ process` (see T47).

Done. T48 next, where you'll fix a broken spec by diagnosing a lasso trace.

## Hints

??? hint "💡 Hint 1 — Understanding the back-edge"
    In the lasso output, look for "Back to state N." That line tells you where the cycle CLOSES. Everything from that state onward repeats infinitely. If the property fails in the cycle, it ALWAYS fails.

??? hint "💡 Hint 2 — Identifying the stuck action"
    In the Clock example, `hour` stays at 11 in the cycle. The property requires `hour = 12`. But the resetter keeps toggling `reset` back and forth. Why can't the ticker advance `hour` if the resetter is enabled infinitely often?

??? hint "💡 Hint 3 — The fairness pattern"
    When you see a lasso where one action fires infinitely (resetter) and another never fires (ticker), look at the fairness annotations. The resetter is `process` (no fairness) — TLC can schedule it forever. The ticker is `fair process` (WF), but weak fairness only helps if the action is CONTINUOUSLY enabled. Here the enablement flickers, so WF isn't enough.
