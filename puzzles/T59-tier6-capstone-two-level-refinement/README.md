# T59: Tier 6 Capstone — Two-Level Refinement ⭐⭐⭐

## Lesson: Capstone — Composing Refinement End-to-End

No new concept. This puzzle composes the Tier 6 refinement toolkit on a single problem:

- **T50** — `CONSTANT` and `ASSUME` to parameterize.
- **T51** — multi-module specs with separate .tla files.
- **T52** — `INSTANCE WITH` to bind constants.
- **T53** — write the abstract spec, maximally nondeterministic.
- **T54** — concrete spec with `INSTANCE` and `PROPERTY Refines`.
- **T55** — refinement mapping when names differ.
- **T56** — auxiliary variables for mappings the raw concrete state can't support.
- **T57** — stuttering steps (`[Next]_vars`) make refinement work.

The recap below is the workflow you compose; the puzzle uses a different domain.

### The end-to-end workflow

1. **Identify the visible state.** What does the user / outside observer see? That's the abstract's variables.
2. **Write the abstract.** Maximally nondeterministic, no mechanism. `ASSUME` constants are well-formed.
3. **Build the concrete.** Add the implementation variables. The concrete may have MORE actions and MORE state than the abstract.
4. **Write the mapping.** `L0 == INSTANCE Abstract WITH abstractVar <- exprInConcrete`. If raw concrete state can't reconstruct an abstract value, add an `aux_` variable that tracks it.
5. **Wrap with `Refines == L0!Spec`.** TLC's cfg parser doesn't accept dotted names directly.
6. **Run TLC.** PROPERTY Refines. INVARIANT TypeOK. CHECK_DEADLOCK FALSE if the concrete has terminal states.
7. **If refinement fails:** read the trace. Bug in mapping? In concrete Next? (See T58.)

## Setup

A simple traffic-light system, modeled in two levels of detail.

**Abstract:** the world sees just whether a light is "go" or "stop". (Yellow is collapsed into stop — pedestrians don't care; only the controller cares about yellow.)

**Concrete:** the controller cycles through red → green → yellow → red. The yellow phase is invisible to the abstract — yellow looks like "stop" externally.

We additionally track an auxiliary `aux_cycles` that counts complete cycles (red → red), used in the abstract as a wrapping counter. The abstract has TWO state variables: `signal` (the visible "go"/"stop") and `cycles` (the number of completed cycles). The concrete's mapping uses `aux_cycles` for the latter.

## Task

Three files in `solution/`:

### `solution/AbstractSignal.tla`

```
---- MODULE AbstractSignal ----
EXTENDS Integers
CONSTANT MaxCycles
ASSUME MaxCycles \in Nat /\ MaxCycles >= 1

VARIABLES signal, cycles

vars == << signal, cycles >>

Init == signal = "stop" /\ cycles = 0

\* The abstract observer sees signal flip and cycles increment when a cycle completes.
ToGo   == signal = "stop" /\ signal' = "go"   /\ cycles' = cycles
ToStop == signal = "go"   /\ cycles < MaxCycles
                          /\ signal' = "stop" /\ cycles' = cycles + 1

Next == ToGo \/ ToStop
Spec == Init /\ [][Next]_vars

TypeOK == signal \in {"go", "stop"} /\ cycles \in 0..MaxCycles
====
```

### `solution/ConcreteLight.tla`

The concrete cycles `red` → `green` → `yellow` → `red`. Both `red` and `yellow` map to abstract `"stop"`. `green` maps to abstract `"go"`. The transition `yellow → red` completes a cycle.

- `EXTENDS Integers`
- `CONSTANT MaxCycles`, `ASSUME MaxCycles \in Nat /\ MaxCycles >= 1`
- `VARIABLES color, aux_cycles`  (aux_cycles is auxiliary)
- `vars == << color, aux_cycles >>`
- `Init == color = "red" /\ aux_cycles = 0`
- `RedToGreen    == color = "red"    /\ color' = "green"  /\ UNCHANGED aux_cycles`
- `GreenToYellow == color = "green"  /\ color' = "yellow" /\ UNCHANGED aux_cycles`
- `YellowToRed   == color = "yellow" /\ aux_cycles < MaxCycles /\ color' = "red" /\ aux_cycles' = aux_cycles + 1`
- `Next == RedToGreen \/ GreenToYellow \/ YellowToRed`
- `Spec == Init /\ [][Next]_vars`
- `TypeOK == color \in {"red", "green", "yellow"} /\ aux_cycles \in 0..MaxCycles`
- The mapping:
  ```
  L0 == INSTANCE AbstractSignal WITH
    signal <- IF color = "green" THEN "go" ELSE "stop",
    cycles <- aux_cycles
  ```
- `Refines == L0!Spec`

### `solution/ConcreteLight.cfg`

```
SPECIFICATION Spec
CONSTANT MaxCycles = 3
INVARIANT TypeOK
PROPERTY Refines
CHECK_DEADLOCK FALSE
```

## Check

```bash
cd solution
tlc ConcreteLight
```

## Walking through the refinement

You should be able to convince yourself, before running TLC, that:

- Concrete `Init` projects to abstract `Init`: `color = "red"` → `signal = "stop"`; `aux_cycles = 0` → `cycles = 0`. Match.
- `RedToGreen`: signal goes "stop" → "go"; cycles unchanged. Matches abstract `ToGo`.
- `GreenToYellow`: signal goes "go" → "stop"; aux_cycles unchanged. So mapped cycles also unchanged. The abstract's `ToStop` increments cycles — so this CAN'T be `ToStop`. Yet signal flipped! How is this allowed? It's NOT — this would be a refinement violation if our abstract demanded the cycles increment on every signal flip.

Wait — that's the bug catch. Let me re-examine. The abstract `ToStop` says signal flips to "stop" AND cycles increment. The concrete `GreenToYellow` flips signal to "stop" without incrementing aux_cycles. That's exactly `ToStop` with cycles unchanged — which the abstract DOESN'T allow.

So the concrete as described WOULD fail refinement if you implemented it literally. To make it pass, we must EITHER:

(a) Increment `aux_cycles` on `GreenToYellow` instead of `YellowToRed`, OR
(b) Map `signal` such that the visible signal does NOT flip on `GreenToYellow`.

Option (b) is what the lesson described — `IF color = "green" THEN "go" ELSE "stop"` means BOTH `red` and `yellow` map to `"stop"`. So `GreenToYellow` flips `signal` from `"go"` to `"stop"` — and we still face the cycles-not-incrementing problem.

This is the crux: the abstract's `ToStop` couples the signal flip with the cycle increment. To make refinement hold, the concrete must increment `aux_cycles` AT THE SAME STEP it flips signal to "stop". So `GreenToYellow` must increment `aux_cycles`, NOT `YellowToRed`.

Adjust the concrete:

- `GreenToYellow`: this is the step that flips signal — so increment aux_cycles here.
- `YellowToRed`: signal stays "stop" (yellow and red both map to "stop"); aux_cycles unchanged. PURE STUTTER on the abstract.

Updated definitions:

- `RedToGreen    == color = "red"    /\ color' = "green"  /\ UNCHANGED aux_cycles`
- `GreenToYellow == color = "green"  /\ aux_cycles < MaxCycles /\ color' = "yellow" /\ aux_cycles' = aux_cycles + 1`
- `YellowToRed   == color = "yellow" /\ color' = "red"    /\ UNCHANGED aux_cycles`

That's the version that refines.

## Expected Result

- TLC explores the concrete state space. With `MaxCycles = 3`, expect about **10 distinct states** (3 colors × 4 cycle-count values, minus unreachable combos plus terminal states reached at `MaxCycles`).
- `TypeOK` passes.
- `Refines` PASSES.
- `RedToGreen` is the abstract `ToGo`. `GreenToYellow` is the abstract `ToStop`. `YellowToRed` is a stutter on `<<signal, cycles>>` because both `signal` (still maps to "stop") and `cycles` (`aux_cycles` unchanged) stay the same.

## What you should learn

- A real refinement requires you to ALIGN observable changes between concrete and abstract — you don't get to flip the abstract signal without also doing whatever else the abstract demands AT THE SAME STEP.
- Auxiliary variables are exactly the right tool for "the abstract sees a counter that the concrete doesn't natively keep."
- Stuttering steps absorb internal events — `YellowToRed` is internal-only.
- Multi-module + INSTANCE + WITH compose cleanly: one cfg, one TLC run, refinement verified end-to-end.

## Hints

??? hint "💡 Hint 1 — Decompose the concrete into abstract-level steps"
    Four concrete actions: RedToGreen (signal flip, no cycle change), GreenToYellow (signal flip AND cycle increment), YellowToRed (internal only). Ask: which of these maps to an abstract step, and which to a stutter?

??? hint "💡 Hint 2 — The abstract couples signal flip with cycle increment"
    Abstract ToStop says: signal flips AND cycles increment, TOGETHER. If concrete GreenToYellow flips signal but doesn't increment aux_cycles, it won't match ToStop. The cycle increment must happen AT THE SAME STEP as the visible signal change.

??? hint "💡 Hint 3 — The mapping makes yellow invisible"
    signal <- IF color = "green" THEN "go" ELSE "stop". Both yellow and red map to "stop". YellowToRed doesn't change color-type ("stop") or aux_cycles, so it's a pure stutter on the abstract variables.

??? hint "💡 Hint 4 — Multi-module composition: CONSTANT, ASSUME, INSTANCE, WITH"
    Constants flow from cfg into AbstractSignal and ConcreteLight. Each INSTANCE binds them. The cfg lists PROPERTY Refines and INVARIANT TypeOK. All pieces work together.

