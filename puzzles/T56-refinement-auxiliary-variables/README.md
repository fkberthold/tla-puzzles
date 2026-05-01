# T56: Refinement — Auxiliary Variables ⭐⭐⭐

## Lesson: Auxiliary Variables in the Concrete Spec

Sometimes the concrete spec's "real" state isn't enough to construct a refinement mapping. The abstract distinguishes situations the concrete can't tell apart from its raw variables — usually because the abstract carries HISTORY that the concrete only sees as a current value.

The fix: add an AUXILIARY VARIABLE to the concrete spec. Auxiliary variables:

- exist ONLY to support the refinement mapping
- never get read by the system's "real" actions — they ride along passively
- are the variable equivalent of a ghost field
- by convention, prefix with `aux_` or comment them as auxiliary

The mapping then references the auxiliary. The concrete spec is unchanged operationally: every real action also updates the auxiliary in the obvious way, but no real action's behavior depends on it.

**Worked example — a vending machine.**

Abstract: tracks the count of items SOLD over time. Each sell event bumps the count.

Concrete: tracks `stock` (items remaining), no count of items sold. The mapping needs the count, but `stock` alone can't give it (we don't know the initial stock from a state). Add an auxiliary `aux_sold` that is incremented on every concrete sell and unchanged on every restock:

```
---- MODULE AbstractCounter ----
EXTENDS Integers
VARIABLE soldCount
Init == soldCount = 0
Sell == soldCount' = soldCount + 1
Next == Sell
Spec == Init /\ [][Next]_<<soldCount>>
====

---- MODULE ConcreteVending ----
EXTENDS Integers
CONSTANT Capacity
VARIABLES stock, aux_sold     \* aux_sold is auxiliary
vars == << stock, aux_sold >>
Init == stock = Capacity /\ aux_sold = 0
Sell    == stock > 0       /\ stock' = stock - 1 /\ aux_sold' = aux_sold + 1
Restock == stock < Capacity /\ stock' = stock + 1 /\ UNCHANGED aux_sold
Next == Sell \/ Restock
Spec == Init /\ [][Next]_vars

L0 == INSTANCE AbstractCounter WITH soldCount <- aux_sold
Refines == L0!Spec
====
```

`Restock` is a stutter on `soldCount` (the abstract sees no change). `Sell` increments both `stock` (down) and `aux_sold` (up). The mapping projects to `aux_sold`, and the abstract sees only the increment.

The concrete actions WRITE the auxiliary but never READ it — that's how you know it's truly auxiliary.

Note: sometimes you don't need a separate auxiliary at all — if the mapping can be computed directly from real variables, no auxiliary is needed. For example, a concrete spec that tracks `totalIn` and `totalOut` separately can map to an abstract `balance` via `balance <- totalIn - totalOut` without adding any new variable. The auxiliary pattern is only necessary when raw concrete state can't reconstruct an abstract value.

## Setup

You'll write a concrete spec that needs an auxiliary variable to refine its abstract.

The abstract spec is `RingCount`: a counter that increments each ring of a doorbell, with no upper bound (so we'll cap it via a constant for TLC).

The concrete spec is a `Doorbell` system that has a bell `state` (`"idle"` or `"ringing"`) and that goes idle → ringing → idle on each press cycle. The system's real actions don't track ring count — they just transition between states.

To refine `RingCount`, add an auxiliary `aux_rings` that increments each time the bell goes from `"ringing"` back to `"idle"` (i.e., each completed ring).

## Task

Three files in `solution/`:

### `solution/RingCount.tla` — abstract

```
---- MODULE RingCount ----
EXTENDS Integers
CONSTANT Max
ASSUME Max \in Nat /\ Max >= 1

VARIABLE rings
Init == rings = 0
Ring == rings < Max /\ rings' = rings + 1
Next == Ring
Spec == Init /\ [][Next]_<<rings>>

TypeOK == rings \in 0..Max
====
```

### `solution/Doorbell.tla` — concrete with auxiliary

- `EXTENDS Integers`
- `CONSTANT Max`, `ASSUME Max \in Nat /\ Max >= 1`
- `VARIABLES state, aux_rings`  (`aux_` prefix marks auxiliary)
- `vars == << state, aux_rings >>`
- `Init == state = "idle" /\ aux_rings = 0`
- `Press == state = "idle" /\ state' = "ringing" /\ UNCHANGED aux_rings`
- `Settle == state = "ringing" /\ aux_rings < Max /\ state' = "idle" /\ aux_rings' = aux_rings + 1`
- `Next == Press \/ Settle`
- `Spec == Init /\ [][Next]_vars`
- `TypeOK == state \in {"idle", "ringing"} /\ aux_rings \in 0..Max`
- The mapping: `L0 == INSTANCE RingCount WITH rings <- aux_rings`
- `Refines == L0!Spec`

### `solution/Doorbell.cfg`

```
SPECIFICATION Spec
CONSTANT Max = 3
INVARIANT TypeOK
PROPERTY Refines
CHECK_DEADLOCK FALSE
```

(After 3 rings the bell is stuck at `state = "idle"`, `aux_rings = 3`, and `Press` would lead to `Settle` failing the `< Max` guard, eventually deadlocking. Disable the check; T57 covers stuttering properly.)

## Check

```bash
cd solution
tlc Doorbell
```

## Expected Result

- TLC explores about **7 distinct states** for `Max = 3`.
- `TypeOK` passes.
- `Refines` PASSES — `Press` is a stutter on the abstract (no `rings` change); `Settle` is the abstract `Ring`.
- From `state` alone (only `"idle"` or `"ringing"`), no expression can recover the ring count — both `"idle at ring 0"` and `"idle at ring 2"` look identical. That's why `aux_rings` is necessary.

## Hints

??? hint "💡 Hint 1 — An auxiliary variable tracks state the abstract sees but the concrete's raw state doesn't reveal"
    Concrete has `state` (idle/ringing); abstract has `rings` (a count). From state alone, you can't recover the count. So add `aux_rings` to the concrete and map `rings <- aux_rings`.

??? hint "💡 Hint 2 — Auxiliary variables are NEVER read by real actions"
    Settle and Press update `aux_rings`, but their logic never DEPENDS on it. The auxiliary is purely for refinement. If an action guards on or depends on the auxiliary, it's not truly auxiliary.

??? hint "💡 Hint 3 — Each real action must keep the auxiliary consistent"
    Press doesn't change rings, so UNCHANGED aux_rings. Settle increments aux_rings each time a ring completes. The mapping references the auxiliary, so TLC sees the count grow correctly.

