# T0b: Reading a Counterexample ⭐

**Tier 0 prelude.** No new concept. No code to write. The goal is to recognize what TLC's failure output looks like and learn how to read a counterexample trace.

## What this puzzle is

A pre-written spec models a battery that drains from `3` down to `0`. The `.cfg` declares two invariants — and one of them is **deliberately wrong**. TLC will find the violation, print a trace, and report which invariant fired.

You are not expected to understand the spec yet. The goal is reading TLC's failure output.

## The spec

Save these two files into a working directory of your choice.

`Battery.tla`:

```
---- MODULE Battery ----
EXTENDS Integers

(*--algorithm Battery {
  variables charge = 3;

  define {
    TypeOK == charge \in 0..3
    StaysCharged == charge > 0
  }

  fair process (drain = "Drain") {
    deplete:
      while (charge > 0) {
        charge := charge - 1;
      }
  }
}
*)
====
```

`Battery.cfg`:

```
SPECIFICATION Spec
INVARIANT TypeOK
INVARIANT StaysCharged
```

## Run it

From the directory containing both files:

```bash
tlc -pcal Battery.tla
tlc Battery
```

Same two commands as T0a. This time, TLC reports an error.

## What to look for

TLC prints something like:

```
Error: Invariant StaysCharged is violated.
Error: The behavior up to this point is:
State 1: <Initial predicate>
/\ charge = 3
/\ pc = [Drain |-> "deplete"]

State 2: <deplete ...>
/\ charge = 2
/\ pc = [Drain |-> "deplete"]

State 3: <deplete ...>
/\ charge = 1
/\ pc = [Drain |-> "deplete"]

State 4: <deplete ...>
/\ charge = 0
/\ pc = [Drain |-> "deplete"]
```

Three things to notice:

1. **Which invariant fired.** The first error line names it: `StaysCharged is violated`. The other invariant in the `.cfg`, `TypeOK`, held in every state — TLC only reports the one that broke.

2. **Start from the last state.** State 1 is the initial state. The last state (State 4 here) is the *violating* state — the one where the invariant was false. To understand the failure, read upward from the bottom: "TLC ended at `charge = 0`. How did it get there?" Then walk up: state 3 had `charge = 1`, state 2 had `charge = 2`, initial had `charge = 3`. The drain process subtracted 1 each step until it hit 0, where `StaysCharged == charge > 0` finally broke.

3. **What the invariant actually claimed.** In the `define` block of `Battery.tla`:

   ```tla
   StaysCharged == charge > 0
   ```

   That's the false claim: "charge is always greater than 0." TLC found a reachable state where it isn't, and showed you the shortest path there.

## What's in the .cfg

Both `INVARIANT` lines were declared. TLC checks both in every state. `TypeOK` (`charge \in 0..3`) is true throughout — `charge` only takes values 3, 2, 1, 0, all in range. `StaysCharged` is the one that fails. If you remove or comment out the `INVARIANT StaysCharged` line, TLC will accept the spec — but the spec is unchanged; you've just stopped asking the question.

## What to take away

- A failing run prints an error naming the violated invariant, then a numbered trace.
- The violating state is the LAST state in the trace, not the first. Read bottom-up to understand "how did we get here."
- TLC reports the *shortest* path to the violation — never a longer one. So traces are usually small even when state spaces are huge.
- Removing an invariant from the `.cfg` doesn't fix the bug. It just stops asking.

Done. T0c next, where you'll edit the `.cfg` file directly to change what TLC checks.

## Hints

??? hint "💡 Hint 1 — Start at the bottom"
    The trace has multiple states. The violating state (the one where the invariant breaks) is listed LAST, not first. Start there and read upward to understand "how did we get to this violation?"

??? hint "💡 Hint 2 — Which invariant fired?"
    TLC checks two invariants in the .cfg. Only ONE of them failed. Look at the error message — it names the invariant by name. The other invariant held true in every state.

??? hint "💡 Hint 3 — Battery drain is step-by-step"
    The Battery spec drains one unit of charge per step: 3, then 2, then 1, then 0. The invariant `StaysCharged` claims charge > 0. When does 0 first appear? What state does that violate?
