# A08: Apalache — TLC vs Apalache Comparison ⭐⭐

## Lesson: When To Reach For Each

You now know enough Apalache to author a typed spec, fold it, terminate it, and parameterize its constants. But *should* you use Apalache for everything? No. TLC and Apalache have different sweet spots. This puzzle takes one spec, runs it on both, and observes the differences.

**TLC**, the original model checker, *enumerates* every reachable state. It's incredibly fast on small state spaces with concrete values. It's untyped. It uses simple data structures and a fingerprint table.

**Apalache** encodes the spec as SMT constraints over symbolic variables. It explores depth bounded by `--length=N` rather than enumerating all states. It requires types. It can quantify over constants symbolically (A07).

The trade-offs:

| Property                       | TLC                              | Apalache                                                |
|--------------------------------|----------------------------------|---------------------------------------------------------|
| Enumerates all states          | yes (up to memory)               | no — bounded by `--length`                              |
| Types required                 | no                               | yes                                                     |
| Symbolic constants             | no                               | yes (via `--cinit`)                                     |
| Big concrete state spaces      | strong                           | often slower than TLC                                   |
| Big *symbolic* parameter spaces| weak (one cfg at a time)        | strong                                                  |
| Counterexample length          | shortest BFS                     | exact-bounded (any depth ≤ N)                            |
| `RECURSIVE`                    | tolerates                        | rejects (use folds — A05)                               |
| Symmetry reduction             | yes (Tier 7)                     | no                                                      |
| Liveness / fairness            | yes (limited)                    | partial (limited support, growing)                       |
| Best for                       | exhaustive, finite, small        | unbounded constants, deep traces, type-safety pre-check |

The simple decision rule that emerges:

- **Default to TLC** for exhaustive checks of finite, concrete configurations. Faster feedback loop, no annotations needed.
- **Reach for Apalache** when you want type safety, parameterized constants, or a counterexample at a specific depth that TLC's BFS would never reach in reasonable time.

**Worked example — a counter spec, run on both.**

```tla
---- MODULE CounterCompare ----
EXTENDS Integers, Apalache

CONSTANT
  \* @type: Int;
  Max

\* @type: Int;
VARIABLE n

vars == << n >>

Init == n := 0

Inc ==
  /\ n < Max
  /\ n' := n + 1

Done ==
  /\ n = Max
  /\ UNCHANGED n

Next == Inc \/ Done

Spec == Init /\ [][Next]_vars

NeverNegative == n >= 0

ConstInit == Max \in 1..100
====
```

Run TLC at a single Max:

```bash
\* CounterCompare.cfg:
\*   CONSTANT Max = 50
\*   SPECIFICATION Spec
\*   INVARIANT NeverNegative
tlc CounterCompare
\* → 51 distinct states, no error. About 0.5s.
```

Run Apalache parameterized over all Max in 1..100:

```bash
apalache-mc check --cinit=ConstInit --length=100 --inv=NeverNegative CounterCompare.tla
\* → invariant holds for all Max in 1..100, in one run.
```

To prove this on TLC, you'd loop the cfg over 100 values. Apalache does it in one shot — that's the symbolic advantage.

Conversely, ask TLC and Apalache to find the violation in this version:

```tla
\* Mistake: subtract instead of add.
Inc ==
  /\ n < Max
  /\ n' := n - 1
```

TLC: deadlock at `n = -1` after one step (because the invariant is violated and TLC reports the first state where it fails) — fast trace, a few states.
Apalache: same violation, also one step. The two tools are equivalent for short violations on small specs. The advantage flips when state spaces get big or when constants need to be quantified.

**The key idea.** Both tools are valuable; they answer different questions. TLC: "is this concrete configuration safe?" Apalache: "is this *family* of configurations safe, with a clean type story?"

## Setup

A small token-bucket spec: a bucket holds up to `Capacity` tokens. Each step either adds 1 token (if not full) or consumes 1 token (if not empty). We want to verify two things:

- `NeverNegative == tokens >= 0`
- `NeverOverflow == tokens <= Capacity`

We will run the same spec on TLC (concrete `Capacity = 5`) and observe how Apalache (`--cinit`) would generalize it.

## Task

Write `Bucket.tla`:

- `EXTENDS Integers, Apalache`
- `CONSTANT Capacity` annotated `Int`.
- `VARIABLE tokens` annotated `Int`. Init `tokens := 0`.
- `Add`: when `tokens < Capacity`, increment.
- `Take`: when `tokens > 0`, decrement.
- `Done`: stutter when no work to do (here, simply allow stutter at any reachable state — `Done` always enabled and unchanged).

Wait — that would let the spec do nothing. Better to omit `Done` since `Add` and `Take` cover all states (when `tokens \in 1..Capacity-1`, both fire; at `tokens = 0`, `Add` fires; at `tokens = Capacity`, `Take` fires). No deadlock. Skip `Done`.

- `Next == Add \/ Take`
- `Spec == Init /\ [][Next]_vars`
- Two invariants: `NeverNegative` and `NeverOverflow`.
- `ConstInit == Capacity \in 1..10`.

Provide a `.cfg` for TLC with `Capacity = 5` (positive, so no negative-literal cfg quirk).

In the `README.md` for this puzzle's solution dir, add a short `NOTES.md` (or just a heading at the bottom of this README) recording what would happen on Apalache. **Don't fabricate Apalache output — describe expected behavior** based on the comparison table above.

## Check

```bash
cd solution
tlc Bucket
```

If you have Apalache:

```bash
apalache-mc typecheck Bucket.tla
apalache-mc check --inv=NeverNegative --inv=NeverOverflow --cinit=ConstInit --length=20 Bucket.tla
```

## Expected Result

- **TLC** with `Capacity = 5`: 6 distinct states (`tokens \in 0..5`), invariants hold, no error. Fast.
- **Apalache `typecheck`**: `Type checker [OK]`.
- **Apalache `check --cinit=ConstInit --length=20`**: invariants hold for *all* `Capacity \in 1..10` to depth 20. Slower than TLC, but proves a parameterized claim TLC can't.

## Comparison Recap

Fill out a table of your observations after running:

| Question                                | TLC               | Apalache                       |
|----------------------------------------|-------------------|--------------------------------|
| Single-config check, fast?             | yes               | yes (slower SMT setup)         |
| Verifies all `Capacity \in 1..10` at once? | no            | yes, via `--cinit`             |
| Needs `\* @type:` annotations?         | no                | yes                            |
| Easy counterexample at exact depth?    | hard (BFS only)   | yes (`--length`)               |
| Tolerates `RECURSIVE`?                  | yes               | no (use folds — A05)            |

## What you learned

- TLC and Apalache are not competitors; they target different verification questions.
- TLC: concrete and exhaustive, no annotations, fast feedback. Default for finite single-config specs.
- Apalache: symbolic, typed, parameterizable, depth-bounded. Reach for it when you need type safety, constant quantification, or a deep targeted trace.
- A well-written spec runs on both. Annotations are TLA+ comments — TLC ignores them.

## Hints

??? hint "💡 Hint 1 — Two complementary tools"
    The lesson compares TLC (enumerates all states, no types) vs Apalache (symbolic, typed, bounded by depth). Your spec will have a constant `Capacity`. TLC checks one concrete value at a time; Apalache uses `--cinit` to check all values in a range at once. What does that mean for your `ConstInit` operator?

??? hint "💡 Hint 2 — No Done action needed here"
    Unlike A06, this bucket spec doesn't need a terminal stutter. When `tokens = 0`, `Add` is enabled. When `tokens = Capacity`, `Take` is enabled. At any middle value, both are enabled. No state has zero enabled actions — no deadlock, no `Done` needed.

??? hint "💡 Hint 3 — Both invariants, both checkers"
    Write `NeverNegative == tokens >= 0` and `NeverOverflow == tokens <= Capacity`. TLC checks the first one explicitly (with the cfg). The lesson's comparison table shows that Apalache's symbolic encoding would verify both for all `Capacity \in 1..10` in one run via `--cinit=ConstInit`.
