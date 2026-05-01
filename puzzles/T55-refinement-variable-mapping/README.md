# T55: Refinement — Variable Mapping ⭐⭐

## Lesson: Mapping Concrete Variables to Abstract Ones

T54 had it easy: the abstract and the concrete used the SAME variable name (`punches`), and the concrete's INSTANCE worked with no `WITH` clause. Real refinement is rarely so kind.

The general case: the abstract has variables `a1, a2, ...` and the concrete has DIFFERENT variables `c1, c2, ...`. To say "the concrete refines the abstract," you must specify a REFINEMENT MAPPING — a function from concrete state to abstract state. INSTANCE WITH is how you write it down.

```
L0 == INSTANCE Abstract WITH abstractVar <- expr_in_concrete_vars
```

Reads: "in the abstract, wherever you see `abstractVar`, substitute this expression evaluated in concrete state." TLC then projects every concrete behavior onto the abstract by computing the expression at each step, and checks the projected behavior satisfies the abstract spec.

The mapping is a CHOICE — the same concrete can refine many different abstracts via different mappings. The mapping must:

- Yield a value of the right TYPE (whatever the abstract's TypeOK expects).
- Make the abstract's `Init` true on the initial concrete state (under the substitution).
- Make every concrete `Next` step look like a valid abstract step OR a stutter on the abstract variables.

**Worked example — a stopwatch.**

Abstract `StopwatchA` has a single variable `seconds`:

```
---- MODULE StopwatchA ----
EXTENDS Integers

VARIABLE seconds
vars == << seconds >>
Init == seconds = 0
Tick == seconds' = seconds + 1
Reset == seconds' = 0
Next == Tick \/ Reset
Spec == Init /\ [][Next]_vars
====
```

Concrete `StopwatchC` keeps time as `mins` and `secs` separately, plus a `running` flag:

```
---- MODULE StopwatchC ----
EXTENDS Integers

VARIABLES mins, secs, running
vars == << mins, secs, running >>

Init == mins = 0 /\ secs = 0 /\ running = TRUE

TickSec ==
  /\ running
  /\ secs < 59
  /\ secs' = secs + 1
  /\ UNCHANGED << mins, running >>

TickMin ==
  /\ running
  /\ secs = 59
  /\ secs' = 0
  /\ mins' = mins + 1
  /\ UNCHANGED running

Pause   == running /\ running' = FALSE /\ UNCHANGED << mins, secs >>
Resume  == ~running /\ running' = TRUE /\ UNCHANGED << mins, secs >>
ResetC  == mins' = 0 /\ secs' = 0 /\ UNCHANGED running

Next == TickSec \/ TickMin \/ Pause \/ Resume \/ ResetC
Spec == Init /\ [][Next]_vars

\* The mapping: the abstract sees only the total seconds.
L0 == INSTANCE StopwatchA WITH seconds <- mins * 60 + secs
Refines == L0!Spec
====
```

Three things to study:

1. The WITH clause: `seconds <- mins * 60 + secs`. The expression on the right is evaluated in CONCRETE state. From the abstract's view, that's just "seconds."
2. `Pause` and `Resume` change `running` only. The mapping yields the same `seconds` value — these are STUTTERING steps on the abstract variable. Allowed by `[Next]_<<seconds>>` in the abstract's Spec form.
3. `TickMin` rolls minutes. From `secs = 59, mins = m`, the next state has `secs = 0, mins = m+1`, so the mapping goes from `60m + 59` to `60(m+1) + 0 = 60m + 60`. Difference: `+1`. That's a valid abstract `Tick`.

If you forgot to constrain `secs < 60` in the type, TLC could find a state where `secs = 60` and the mapping yields a value the abstract has no transition to. That's how broken mappings get caught.

## Setup

You'll write a refinement where concrete variable names DIFFER from abstract variable names.

The abstract spec describes a single LIGHT — `lampOn` is a boolean, `Toggle` flips it.

The concrete spec models a DIMMER — `brightness` is `0..3`. The dimmer can step up by 1 (until 3), step down by 1 (until 0), or jump-to-zero. From the abstract's perspective, the LIGHT is on whenever `brightness > 0` — an off light is brightness 0, an on light is any brightness 1, 2, or 3.

You will write the refinement mapping `lampOn <- (brightness > 0)`.

## Task

Three files in `solution/`:

### `solution/AbstractLight.tla`

```
---- MODULE AbstractLight ----
VARIABLE lampOn
vars == << lampOn >>
Init == lampOn = FALSE
Toggle == lampOn' = ~lampOn
Next == Toggle
Spec == Init /\ [][Next]_vars
====
```

### `solution/ConcreteDimmer.tla`

- `EXTENDS Integers`
- `VARIABLE brightness`
- `vars == << brightness >>`
- `Init == brightness = 0`
- `StepUp   == brightness < 3 /\ brightness' = brightness + 1`
- `StepDown == brightness > 0 /\ brightness' = brightness - 1`
- `OffSwitch == brightness > 0 /\ brightness' = 0` — instantly turn off from any nonzero
- `OnSwitch  == brightness = 0 /\ brightness' = 1` — instantly turn on (to dim level 1) from off
- `Next == StepUp \/ StepDown \/ OffSwitch \/ OnSwitch`
- `Spec == Init /\ [][Next]_vars`
- The mapping: `L0 == INSTANCE AbstractLight WITH lampOn <- (brightness > 0)`
- The wrapper: `Refines == L0!Spec`
- `TypeOK == brightness \in 0..3`

### `solution/ConcreteDimmer.cfg`

```
SPECIFICATION Spec
INVARIANT TypeOK
PROPERTY Refines
```

## Check

```bash
cd solution
tlc ConcreteDimmer
```

## Expected Result

- TLC explores 4 distinct concrete states (`brightness \in {0,1,2,3}`).
- `TypeOK` passes.
- `Refines` PASSES — every concrete step looks like a valid abstract step or a stutter:
  - `StepUp` from 1 to 2, or 2 to 3: lampOn was TRUE, stays TRUE — stutter on the abstract.
  - `StepUp` from 0 to 1: lampOn went FALSE → TRUE — that's the abstract `Toggle`.
  - `OnSwitch`/`OffSwitch`: lampOn flips, matching abstract `Toggle`.
  - `StepDown` from 3 to 2 or 2 to 1: lampOn was TRUE, stays TRUE — stutter.
  - `StepDown` from 1 to 0: lampOn went TRUE → FALSE — abstract `Toggle`.

If you delete the `>0` guards on `StepDown`, TLC will report `TypeOK` failing (and a refinement violation when brightness goes negative).

## Hints

??? hint "💡 Hint 1 — The abstract and concrete might have DIFFERENT variable names"
    T54 was easy: both used `punches`. Here the abstract has `lampOn`, the concrete has `brightness`. The WITH clause tells TLC how to translate: lampOn <- (brightness > 0).

??? hint "💡 Hint 2 — The mapping is an expression evaluated in concrete state"
    It can be a simple variable (n <- n), a computation (seconds <- mins * 60 + secs), or a boolean expression (lampOn <- brightness > 0). Every value the mapping produces must match the abstract's TypeOK.

??? hint "💡 Hint 3 — Stuttering steps are the key insight"
    StepUp (brightness 1→2) leaves the abstract `lampOn = TRUE` unchanged — a stutter. OnSwitch (brightness 0→1) flips `lampOn` — a valid abstract `Toggle`. Both are allowed by [Next]_vars in the abstract.

