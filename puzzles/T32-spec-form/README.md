# T32: Spec Form and [A]_v ⭐⭐

## Lesson: The Standard Shape, Decoded

Almost every TLA+ spec ends with the same shape:

```
Spec == Init /\ [][Next]_vars /\ WF_vars(Next)
```

Three pieces, in order:

- **`Init`** — what's true at the start.
- **`[][Next]_vars`** — every step is either a `Next` step **or a stutter** (no change in `vars`).
- **`WF_vars(Next)`** — *weak fairness*: if `Next` is continuously enabled, it must eventually fire. Without this, a behavior could stutter forever even when real progress is possible.

### Why `[Next]_v` instead of just `Next`?

The brackets do exactly one thing: **allow stuttering**. The formula `[Next]_vars` means "either `Next` is true, or `vars` is unchanged." Equivalently:

```
[Next]_vars  ==  Next \/ (vars' = vars)
```

Why allow stuttering at all? Because real systems have to coexist with everything else in the world. A spec that says "every step must be a `Next` step" is too strict — it excludes the perfectly normal case of "this system did nothing while something else happened." TLA's answer is to bake stuttering in: `[Next]_v` says "I make a `Next` step, OR I do nothing." `[]` then says "this is true at every position in the behavior."

A consequence: a spec without `WF_vars(Next)` admits the behavior where `Next` *never* fires — pure stuttering forever. That is fine for safety (invariants still hold — they hold of the initial state and stuttering doesn't change anything) but disastrous for liveness (`<>` properties can't be checked because nothing ever happens).

### Why `WF_vars(Next)`?

`WF_vars(Next)` is shorthand for "if `Next` is enabled and stays enabled, eventually it fires." It rules out the pure-stutter behavior. With weak fairness, every reachable state has a `<>` future where some real step is taken (provided `Next` was enabled).

You'll meet **strong fairness** (`SF`) in T47. The difference: `WF` requires the action to be *continuously* enabled; `SF` only requires it to be enabled *infinitely often*. Most specs only need `WF`.

### Why `vars`?

The subscript on `[]_vars` and `WF_vars` is the tuple of all variables: `vars == <<x, y, z>>`. `[Next]_vars` reads "either `Next`, or no change in `vars`." `WF_vars(Next)` reads "weak fairness on `Next` with respect to changes in `vars`." The subscript exists so TLA+ knows what "no change" means.

**Worked example — a one-shot signal.**

A button is pressed exactly once and then never again. Without fairness, "press the button" can stay enabled forever and never fire.

```
---- MODULE Button ----
EXTENDS Integers

VARIABLE pressed

vars == pressed

TypeOK == pressed \in BOOLEAN

Init == pressed = FALSE

Press ==
  /\ pressed = FALSE
  /\ pressed' = TRUE

Next == Press

\* Without fairness — admits the all-stutter behavior.
SpecSafetyOnly == Init /\ [][Next]_vars

\* With fairness — Press is enabled at the initial state, and it
\* stays enabled (still Init), so weak fairness forces Press to fire.
SpecLive == Init /\ [][Next]_vars /\ WF_vars(Press)

EventuallyPressed == <>(pressed = TRUE)
====
```

What TLC does:

- **With `SPECIFICATION SpecSafetyOnly` and `PROPERTY EventuallyPressed`**: TLC reports the property is **violated**. Counterexample: the initial state, then stuttering forever. `pressed` is never `TRUE`.
- **With `SPECIFICATION SpecLive` and `PROPERTY EventuallyPressed`**: TLC reports **no error**. Weak fairness on `Press` rules out the eternal-stutter behavior.

The lesson: invariants hold under both specs (because stuttering doesn't change anything). Liveness properties (`<>`) are the ones that need fairness.

The single `WF_vars(Press)` line is what flips the verdict.

## Setup

A traffic counter at a street intersection counts cars from `0` up to `3`, then is "full." Two actions:

- **`CountCar`**: enabled when `count < 3`. Increments `count` by 1.
- **`Reset`**: enabled when `count = 3`. Sets `count` back to `0`.

The system should keep counting forever — `count = 3` should be reached infinitely often. You will write the spec two ways and observe how fairness changes the verdict.

## Task

Author `solution/Counter.tla` (pure TLA+) with:

- `EXTENDS Integers`
- `VARIABLE count`
- `vars == count`
- `TypeOK == count \in 0..3`
- `Init == count = 0`
- `CountCar` and `Reset` actions
- `Next == CountCar \/ Reset`
- **Two `Spec`s**, both ending the file:
  - `SpecNoFair == Init /\ [][Next]_vars`
  - `SpecFair == Init /\ [][Next]_vars /\ WF_vars(Next)`
- A property: `EventuallyFull == <>(count = 3)`

Author `solution/Counter.cfg` initially with:

```
SPECIFICATION SpecNoFair
INVARIANT TypeOK
PROPERTY EventuallyFull
```

Run TLC. Note the result.

Then change the cfg's first line to `SPECIFICATION SpecFair`. Run again. Note the result.

## Check

Both runs from `solution/`:

```bash
tlc Counter
```

## Expected Result

- **With `SpecNoFair`**: TLC reports `EventuallyFull` is **violated**. The counterexample is short — a "lasso" trace ending in a stutter loop where `count` never advances past 0.
- **With `SpecFair`**: TLC reports **no error**. Weak fairness rules out the all-stutter behavior, and from any reachable state `count = 3` is eventually reached.

Total reachable states either way: **4** (`count \in 0..3`).

The lesson: the bracket `[Next]_vars` lets the system stutter; weak fairness rules out *eternally* stuttering. Both pieces are necessary in real specs.
