# T52: INSTANCE for Parameterization ⭐⭐

## Lesson: Reusing a Parametric Module

T51 showed `EXTENDS` — pull every public name from a helper module into the current namespace. That's good for SHARED VOCABULARY (constants, definitions). But what if you want to reuse the SAME helper module TWICE with DIFFERENT parameters? Or what if you want to keep the helper's names in their own namespace, accessed like `H!Op`?

`INSTANCE` does that.

```
H == INSTANCE Helper WITH N <- 4
```

What this declares:

- `H` is a NAME for one specific instantiation of `Helper` where the constant `N` has been bound to `4`.
- Every public operator `Op(args)` in `Helper` is now accessible from this module as `H!Op(args)`.
- If `Helper` had multiple constants, you list them all in the WITH clause: `H == INSTANCE Helper WITH N <- 4, M <- 8`.
- You can have MULTIPLE instances of the same helper: `Small == INSTANCE Box WITH Capacity <- 5` and `Big == INSTANCE Box WITH Capacity <- 100`.

Compared with `EXTENDS`:

| `EXTENDS H` | `H == INSTANCE H WITH ...` |
|---|---|
| Names flatten into current module | Names live under `H!` prefix |
| Shares constants — caller binds them in cfg | Bind constants HERE, in WITH |
| Used for shared vocabulary | Used for parameterized re-use |

**Worked example — counters in a sports broadcast.**

A reusable `Counter` module models a counter that increments to its `Limit`:

`Counter.tla`:
```
---- MODULE Counter ----
EXTENDS Integers

CONSTANT Limit
ASSUME Limit \in Nat /\ Limit >= 1

Range == 0..Limit
AtLimit(n) == n = Limit

====
```

A broadcast spec wants TWO independent counters — one for points scored, one for fouls — with different limits. INSTANCE lets you do this:

`Broadcast.tla`:
```
---- MODULE Broadcast ----
EXTENDS Integers

\* Two parameterized re-uses of the SAME module
Points == INSTANCE Counter WITH Limit <- 100
Fouls  == INSTANCE Counter WITH Limit <- 5

VARIABLES p, f

Init == p = 0 /\ f = 0
Next ==
  \/ p \in Points!Range /\ p < 100 /\ p' = p + 1 /\ UNCHANGED f
  \/ f \in Fouls!Range  /\ f < 5   /\ f' = f + 1 /\ UNCHANGED p

Spec == Init /\ [][Next]_<<p, f>>

PointsTypeOK == p \in Points!Range
FoulsTypeOK  == f \in Fouls!Range
GameOver == Points!AtLimit(p) \/ Fouls!AtLimit(f)
====
```

Things to notice:

- `Counter.tla` is the same shared module. We didn't have to copy-paste.
- `Points!Range` is `0..100`; `Fouls!Range` is `0..5` — same operator, different binding.
- `Points!AtLimit(p)` becomes `p = 100`; `Fouls!AtLimit(f)` becomes `f = 5`.
- Each instance is its own NAMESPACE — `Range` from `Points` does NOT collide with `Range` from `Fouls`.

When to use INSTANCE rather than EXTENDS:
- The helper has CONSTANTS and you want to bind them inline rather than via the cfg.
- You want MULTIPLE parameterizations in the same spec.
- You want to ISOLATE the helper's namespace (avoid name collisions).

When to use EXTENDS:
- The helper is a fixed library (like Integers, Sequences).
- Names are unique enough that flattening is fine.
- There's only one instantiation needed.

## Setup

You're modeling a kitchen with two timers: one for the oven (max 60 minutes) and one for the microwave (max 5 minutes). Both timers behave the same way — they tick from 0 up to their max and ring when they reach it. You'll write ONE `Timer` module and INSTANCE it twice with different limits.

## Task

Create THREE files in `solution/`:

### `solution/Timer.tla` — the parameterized helper

- `---- MODULE Timer ----`
- `EXTENDS Integers`
- `CONSTANT MaxMinutes`
- `ASSUME MaxMinutes \in Nat /\ MaxMinutes >= 1`
- `Range == 0..MaxMinutes`
- `Ringing(t) == t = MaxMinutes`
- `====`

### `solution/Kitchen.tla` — the spec using two instances

- `---- MODULE Kitchen ----`
- `EXTENDS Integers`
- `Oven == INSTANCE Timer WITH MaxMinutes <- 60`
- `Microwave == INSTANCE Timer WITH MaxMinutes <- 5`
- `VARIABLES oven, micro`
- `Init == oven = 0 /\ micro = 0`
- A `Next` that lets EITHER timer tick by one (so long as it's not yet ringing)
- `Spec == Init /\ [][Next]_<<oven, micro>>`
- Invariants:
  - `OvenTypeOK == oven \in Oven!Range`
  - `MicroTypeOK == micro \in Microwave!Range`
  - `BoundsCorrect == oven <= 60 /\ micro <= 5`

### `solution/Kitchen.cfg`

- `SPECIFICATION Spec`
- `INVARIANT OvenTypeOK`
- `INVARIANT MicroTypeOK`
- `INVARIANT BoundsCorrect`
- `CHECK_DEADLOCK FALSE` (both timers reaching their max would otherwise deadlock — see T51)

## Check

```bash
cd solution
tlc Kitchen
```

## Expected Result

- TLC finds **61 × 6 = 366 distinct states** (one per `(oven, micro)` pairing within bounds).
- All invariants pass.
- TLC reports parsing `Timer.tla` because of the two INSTANCE statements.

If you want to confirm the namespacing: try writing `Range` (no prefix) somewhere in `Kitchen.tla`. You'll get a parse error — `Range` is not in scope; only `Oven!Range` and `Microwave!Range` are.

## Hints

??? hint "💡 Hint 1 — INSTANCE vs EXTENDS: one is for multiple uses"
    EXTENDS brings names into your namespace. INSTANCE lets you USE THE SAME MODULE TWICE with different constants. H == INSTANCE Helper WITH N <- 4 means "call H a name for this instantiation" — the constants are bound inline.

??? hint "💡 Hint 2 — After INSTANCE, use the H! prefix to access operations"
    You write Oven!Range, not just Range. This keeps the two Timer instances (Oven and Microwave) in separate namespaces. Oven!Range is 0..60; Microwave!Range is 0..5.

??? hint "💡 Hint 3 — WITH lists all the constants the helper needs"
    Timer.tla has CONSTANT MaxMinutes. Your INSTANCE statements bind MaxMinutes <- 60 for Oven and MaxMinutes <- 5 for Microwave. Every CONSTANT in the helper must appear in the WITH clause.

