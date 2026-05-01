# T51: Multi-Module Specs ⭐

## Lesson: Splitting a Spec Across Files

So far every spec has been one .tla file. Real specs grow large and want to share helper operators with each other. TLA+ has a primitive module system: `EXTENDS`.

`EXTENDS Module` makes every public definition of `Module` available in the current module — operators, constants, definitions. It's the same mechanism by which you've been writing `EXTENDS Integers` (a built-in module providing `+`, `-`, `Nat`, etc.) and `EXTENDS TLC` (the TLC runtime helpers).

To use your OWN helper module:

1. Create a `.tla` file in the SAME directory as the spec that needs it. The filename and the module name must match.
2. The helper file is a normal module: `---- MODULE Helper ----`, definitions, `====`.
3. From the spec that needs it: `EXTENDS Integers, Helper`.
4. The .cfg file points only at the TOP module. TLC walks the EXTENDS graph automatically.

**Worked example — a chess engine.**

The chess code reuses geometry (board coordinates) in many places. Pull it into a helper:

`Geometry.tla`:
```
---- MODULE Geometry ----
EXTENDS Integers

Files == 1..8
Ranks == 1..8
Square == Files \X Ranks

OnBoard(s) == s \in Square
SameFile(a, b) == a[1] = b[1]
SameRank(a, b) == a[2] = b[2]

====
```

`Chess.tla` (in the same directory):
```
---- MODULE Chess ----
EXTENDS Integers, Geometry

VARIABLE whiteKing

Init == whiteKing = <<5, 1>>           \* uses Square implicitly via the type
TypeOK == OnBoard(whiteKing)            \* reaches into Geometry
\* ... rest of the spec ...
====
```

`Chess.cfg`:
```
SPECIFICATION Spec
INVARIANT TypeOK
```

Notice:

- TLC reads `Chess.tla`. It sees `EXTENDS Geometry`, looks for `Geometry.tla` in the same directory, parses it, and inlines all its public names.
- The cfg only mentions `Chess` — not `Geometry`. The cfg is for the SPEC being checked, and `Chess` is that spec.
- `EXTENDS Integers, Geometry` lists multiple modules. Order doesn't matter; namespaces flatten.
- If `Geometry` had a `CONSTANT`, the cfg would have to bind it (because constants stay constants when EXTENDed).

Use a helper module when:
- Two specs in the same project need the same operators.
- A single spec is getting large and you want to separate "domain library" from "the system being modeled."
- You want to write tests / properties about the helper itself in a separate file.

DO NOT split a single spec for the sake of splitting. Modules are for SHARED definitions.

## Setup

You're modeling a small order-tracking system. Orders move through the states `"new"`, `"paid"`, `"shipped"`, `"delivered"`. The valid transitions are: new→paid, paid→shipped, shipped→delivered, and any state→`"cancelled"`.

You'll put the state machine VOCABULARY (the set of states, the transition relation) in a helper module, and the actual spec (with its variables and Spec form) in a top module that EXTENDS it.

## Task

Create TWO files in your working directory:

### `solution/OrderStates.tla` — the helper

- `---- MODULE OrderStates ----`
- `EXTENDS Integers`  (allowed but not strictly needed)
- Define `States == {"new", "paid", "shipped", "delivered", "cancelled"}`
- Define `ValidTransition(s, t) == ...` — returns TRUE iff `s -> t` is one of the legal transitions listed above
- Define `Terminal(s) == s \in {"delivered", "cancelled"}`
- `====`

### `solution/Order.tla` — the spec

- `---- MODULE Order ----`
- `EXTENDS Integers, OrderStates`
- `VARIABLE order` (a single state value)
- `Init == order = "new"`
- `Next == \E t \in States : ValidTransition(order, t) /\ order' = t`
- `Spec == Init /\ [][Next]_<<order>>`
- Invariant `TypeOK == order \in States`

### `solution/Order.cfg`

- `SPECIFICATION Spec`
- `INVARIANT TypeOK`
- `CHECK_DEADLOCK FALSE` — terminal states (`"delivered"`, `"cancelled"`) have no outgoing transitions, which TLC would flag as a deadlock; we'll see in a later puzzle why pure-TLA+ specs handle this with stuttering.

## Check

```bash
cd solution
tlc Order
```

TLC must locate `OrderStates.tla` automatically — same directory.

## Expected Result

- TLC finds **5 distinct states** (one per element of `States`).
- All reachable from `"new"` via valid transitions: new, paid, shipped, delivered, cancelled.
- `TypeOK` passes.

If TLC complains it can't find module `OrderStates`, the helper file is misnamed or in the wrong directory.

## Hints

??? hint "💡 Hint 1 — EXTENDS pulls vocabulary into your namespace"
    EXTENDS Module makes all public definitions from Module available directly. Create OrderStates.tla with the state vocabulary; then EXTENDS OrderStates in your main spec. TLC walks the EXTENDS graph.

??? hint "💡 Hint 2 — The helper module is just a normal module with definitions"
    OrderStates.tla exports constants and operators (like ValidTransition). It doesn't need to be a Spec (no VARIABLE, no Init, no Next). Just definitions — like a library.

??? hint "💡 Hint 3 — Only the top-level module goes in the .cfg"
    Your cfg names Order (the spec), not OrderStates (the helper). TLC discovers OrderStates via EXTENDS and automatically parses it.

