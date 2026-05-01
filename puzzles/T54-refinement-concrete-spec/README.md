# T54: Refinement — The Concrete Spec ⭐⭐

## Lesson: A Concrete Implementation that Refines the Abstract

T53 was the abstract spec — the contract. T54 is the implementation. The new mechanism: TLC can VERIFY that one spec refines another by checking `L0!Spec` (the abstract spec lifted into the concrete module via INSTANCE) AS A PROPERTY of the concrete spec.

The recipe:

1. The concrete module has its OWN variables — possibly the same as the abstract, possibly a strict superset.
2. Write the concrete `Init`, `Next`, `Spec` as you would any pure-TLA+ spec.
3. Add an INSTANCE statement: `L0 == INSTANCE Abstract`. (No WITH clause is needed yet — that comes in T55, when the variable names differ.)
4. Define a wrapper at the module level: `Refines == L0!Spec`. (TLC's .cfg parser can name an operator but not the dotted form `L0!Spec` directly, so a one-line wrapper is the convention.)
5. In the cfg, write `PROPERTY Refines`. TLC then verifies that every concrete behavior IS a behavior of the abstract.

The deep idea: in TLA+, `Spec` is itself a TEMPORAL FORMULA. Saying "the concrete spec refines the abstract spec" is just saying "every behavior of the concrete spec satisfies the abstract spec's formula." That's a property check.

**Worked example — a vending machine.**

The abstract says: the machine's `stock` decreases by exactly 1 on a sale, increases by 1 on a refill, and starts at 0.

`AbstractVending.tla`:
```
---- MODULE AbstractVending ----
EXTENDS Integers
CONSTANT Capacity
ASSUME Capacity \in Nat /\ Capacity >= 1

VARIABLE stock
Init == stock = 0
Sell    == stock > 0        /\ stock' = stock - 1
Refill  == stock < Capacity /\ stock' = stock + 1
Next    == Sell \/ Refill
Spec    == Init /\ [][Next]_<<stock>>
====
```

Now a concrete spec that adds a `mode` variable telling whether the machine is "open" or "closed". When closed, neither operation can happen. The `stock` part still matches the abstract.

`ConcreteVending.tla`:
```
---- MODULE ConcreteVending ----
EXTENDS Integers
CONSTANT Capacity
ASSUME Capacity \in Nat /\ Capacity >= 1

VARIABLES stock, mode
vars == << stock, mode >>

Init == stock = 0 /\ mode = "open"
Open    == mode = "closed" /\ mode' = "open"  /\ UNCHANGED stock
Close   == mode = "open"   /\ mode' = "closed" /\ UNCHANGED stock
SellC   == mode = "open" /\ stock > 0        /\ stock' = stock - 1 /\ UNCHANGED mode
RefillC == mode = "open" /\ stock < Capacity /\ stock' = stock + 1 /\ UNCHANGED mode
Next    == Open \/ Close \/ SellC \/ RefillC
Spec    == Init /\ [][Next]_vars

\* Refinement: every concrete behavior is a behavior of the abstract,
\* projected onto stock. Same variable name => no WITH needed.
L0 == INSTANCE AbstractVending
Refines == L0!Spec
====
```

Cfg:
```
SPECIFICATION Spec
CONSTANT Capacity = 3
PROPERTY Refines
```

What TLC does: checks every concrete reachable behavior against `L0!Spec`, which expanded is `L0!Init /\ [][L0!Next]_<<stock>>`. The Open/Close steps appear as STUTTERING on `stock` (no change), which the abstract's `[Next]_vars` allows. The SellC/RefillC steps match the abstract's `Sell`/`Refill`. So refinement holds — TLC reports no errors.

If you accidentally let `SellC` decrease stock by 2, the concrete behavior would no longer satisfy the abstract's `Next`, and TLC would print a refinement violation (a counterexample trace).

Note: writing `PROPERTY L0!Spec` is how TLC checks refinement. There's no separate `REFINES` keyword — refinement is just a property.

## Setup

T53 wrote the abstract `PunchCard` spec where `Punch` could jump punches by any positive amount. Now you'll write a CONCRETE punch card that refines it: punches go up by exactly 1, and there's an additional `lastAction` variable tracking what just happened (`"punch"`, `"redeem"`, or `"none"` initially).

The abstract spec from T53 is reproduced here in `solution/AbstractCard.tla` for self-containedness.

## Task

Three files in `solution/`:

### `solution/AbstractCard.tla` — same shape as T53's `PunchCard`

```
---- MODULE AbstractCard ----
EXTENDS Integers
CONSTANT MaxPunches
ASSUME MaxPunches \in Nat /\ MaxPunches >= 1

VARIABLE punches
vars == << punches >>

Init == punches = 0
Punch  == \E n \in (punches+1)..MaxPunches : punches' = n
Redeem == punches >= MaxPunches /\ punches' = 0
Next   == Punch \/ Redeem
Spec   == Init /\ [][Next]_vars
====
```

### `solution/ConcreteCard.tla` — punches by 1; tracks lastAction

- `EXTENDS Integers`
- `CONSTANT MaxPunches`, `ASSUME MaxPunches \in Nat /\ MaxPunches >= 1`
- `VARIABLES punches, lastAction`
- `vars == << punches, lastAction >>`
- `Init == punches = 0 /\ lastAction = "none"`
- `Punch == punches < MaxPunches /\ punches' = punches + 1 /\ lastAction' = "punch"`
- `Redeem == punches = MaxPunches /\ punches' = 0 /\ lastAction' = "redeem"`
- `Next == Punch \/ Redeem`
- `Spec == Init /\ [][Next]_vars`
- INVARIANT: `TypeOK == punches \in 0..MaxPunches /\ lastAction \in {"none", "punch", "redeem"}`
- The refinement INSTANCE and wrapper: `L0 == INSTANCE AbstractCard` and `Refines == L0!Spec`

### `solution/ConcreteCard.cfg`

```
SPECIFICATION Spec
CONSTANT MaxPunches = 3
INVARIANT TypeOK
PROPERTY Refines
```

## Check

```bash
cd solution
tlc ConcreteCard
```

## Expected Result

- TLC explores the concrete state space (~10–13 distinct states for MaxPunches=3).
- TLC verifies `L0!Spec` and reports no error.
- Why it works: the concrete `Punch` (stock += 1) is a special case of the abstract `Punch` (stock' \in (stock+1)..MaxPunches), since `n = punches + 1` is in that range. The concrete `Redeem` matches the abstract `Redeem` exactly. The extra variable `lastAction` is invisible to the abstract because the abstract's `vars` is just `<< punches >>`.

If you change concrete `Punch` to `punches' = punches + 2`, TLC will report a refinement violation: from `punches = 1`, the abstract allows the next value to be in `2..3`, but `2` was reachable from `1` only through the existential — actually `2 \in (1+1)..3 = 2..3`, so `+2` (giving 3) is `3 \in 2..3` — still in range! Try `punches' = punches - 1` instead to break the refinement and see TLC find a counterexample.

## Hints

??? hint "💡 Hint 1 — The concrete must be a valid spec on its own"
    Write your concrete spec (variables, Init, Next, Spec) as if you were specifying a fresh system. Don't worry yet about refinement. Get TypeOK passing first — TLC should explore concrete states without errors.

??? hint "💡 Hint 2 — INSTANCE brings the abstract into scope"
    L0 == INSTANCE AbstractCard (no WITH clause yet — variable names match). Then Refines == L0!Spec wraps the abstract's spec formula. The cfg lists PROPERTY Refines; TLC verifies it.

??? hint "💡 Hint 3 — Refinement is a property of the concrete"
    TLC projects every concrete behavior onto the abstract. If the mapping works, the projection must match an abstract behavior. A concrete `Punch` (+=1) is a special case of abstract `Punch` (\E n \in ... : =n), so it refines.

