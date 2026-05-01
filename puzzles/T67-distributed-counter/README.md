# T67: Final Capstone — Distributed Counter ⭐⭐⭐

## Lesson: The Whole Curriculum, in One Spec

This is the final puzzle. No new concept. Instead, every major piece of the
curriculum lands in a single small system: a distributed counter whose
abstract description is "count to N and signal done" and whose concrete
implementation is N nodes, a heartbeat, and a coordinator.

Here is the recap, traced through the eight techniques this capstone
exercises:

- **Distinct processes (Tier 4).** Three kinds of actor live in the same
  spec — per-node `Contribute(n)`, the heartbeat's `ToggleReady`, and the
  coordinator's `Aggregate`. They are not symmetric copies of one PlusCal
  process; they are different actions written directly in TLA+.

- **`await`-style guards (Tier 4).** The coordinator's `Aggregate` action
  has an explicit precondition `\A n \in Nodes : local[n] = 1`. In pure
  TLA+, an "await" is just a conjunct in the action's enabling predicate.
  Until every cell has been populated, `Aggregate` is disabled.

- **Strong fairness (Tier 5).** The heartbeat toggles `ready` while the
  system is running. `Aggregate` requires `ready = TRUE`, so its
  enablement is intermittent: enabled, disabled, enabled, disabled. Weak
  fairness on `Aggregate` would not suffice — WF only fires actions that
  remain *continuously* enabled. We need `SF_vars(Aggregate)`: infinitely
  often enabled is enough.

- **Leads-to (Tier 5).** Liveness is stated as
  `AllContributed ~> aggDone` — once every node has contributed, the
  coordinator eventually finishes. This is the classic "good progress"
  pattern: a precondition leads to a desired outcome.

- **`INSTANCE ... WITH` (Tier 6).** The concrete spec instantiates the
  abstract one, mapping concrete state to abstract state:

  ```
  Abstract == INSTANCE AbstractCounter
    WITH N    <- NodeCount,
         c    <- SumLocals,
         done <- aggDone
  ```

- **Refinement mapping (Tier 6).** That `WITH` clause IS the refinement
  mapping. Every concrete behavior, viewed through the mapping, is a
  behavior of the abstract spec. TLC checks `Refinement == Abstract!Spec`
  as a temporal property — and it passes only because each concrete
  action lines up with an abstract action (or stutters it):

  | Concrete action       | Abstract image                 |
  |-----------------------|--------------------------------|
  | `Contribute(n)`       | `Tick` (sum increases by 1)    |
  | `ToggleReady`         | stuttering (sum, done unchanged) |
  | `Aggregate`           | `Finish` (done := TRUE)        |
  | `DoneStutter`         | stuttering                     |

- **Apalache type annotations (Apalache track).** Every CONSTANT and
  VARIABLE carries a `\* @type:` comment. `apalache check` reads them and
  verifies the same spec symbolically against an SMT solver. TLC reads
  the same file and ignores the comments.

- **`ApaFoldSet` (Apalache track).** Aggregation is a fold over the set
  of nodes:

  ```
  Add(acc, n) == acc + local[n]
  SumLocals == ApaFoldSet(Add, 0, Nodes)
  ```

  The spec `EXTENDS Apalache`. The official `Apalache.tla` ships in this
  solution dir (extracted from the apalache jar), so both TLC and
  Apalache see the same module — Apalache uses native ApaFoldSet,
  TLC uses the erasure-style operator definition.

## Setup

You have N worker nodes. Each holds a single bit (a "vote" of 1) it can
contribute exactly once. A coordinator wants to know the total once
every node has contributed — but it can only run when a heartbeat says
the system is "ready," and the heartbeat toggles asynchronously.

The system is correct when:

1. The coordinator never produces a wrong total.
2. Once every node has contributed, the coordinator eventually publishes
   the total.
3. Viewed externally — total only — this is just "count to N and signal
   done." That is the abstract spec. The concrete spec must refine it.

## Task

Two modules already live in `solution/`:

- `AbstractCounter.tla` — the abstract spec (`c`, `done`, with `Tick`
  and `Finish` actions). This is the model the outside world sees.
- `DistributedCounter.tla` — the concrete spec (`local`, `ready`, `agg`,
  `aggDone`, with per-node, heartbeat, and coordinator actions). This
  refines the abstract spec via `INSTANCE AbstractCounter WITH ...`.

Read both, then run TLC and confirm the four checks below.

After you have read and run them, try the experiments at the bottom of
this README. Each one breaks one of the eight techniques and shows you,
through TLC's counterexample, why that technique was load-bearing.

## Check

`solution/DistributedCounter.cfg` asks TLC to verify:

1. **`TypeOK`** — every variable stays in its declared domain.
2. **`Refinement`** — `Abstract!Spec` holds: every concrete behavior is a
   behavior of the abstract counter under the mapping.
3. **`EventuallyAggregated`** — `AllContributed ~> aggDone`.
4. **`EventuallyDone`** — `<>aggDone`.

## Expected Result

```
cd solution
tlc DistributedCounter
```

TLC reports **17 distinct states**, depth **6**, and "No error has been
found." All four properties pass.

For the abstract spec on its own:

```
tlc AbstractCounter
```

5 distinct states, depth 5.

## Experiments — break one technique at a time

Each experiment edits `DistributedCounter.tla`, re-runs TLC, and shows
the counterexample. Restore the file after each.

### 1. Replace `SF_vars(Aggregate)` with `WF_vars(Aggregate)`

TLC reports a liveness violation. The trace:

```
State 4: all locals = 1, ready = FALSE
State 5: ToggleReady → ready = TRUE
Back to state 4: ToggleReady → ready = FALSE
```

The heartbeat loops forever between ready = TRUE and ready = FALSE.
`Aggregate` is enabled in odd states and disabled in even states — it is
infinitely-often enabled but not continuously enabled. WF does not fire
it; SF does. **This is what `concept:strong-fairness` means in practice.**

### 2. Drop the `\A n \in Nodes : local[n] = 1` conjunct from `Aggregate`

TLC reports a refinement violation. The coordinator now aggregates with
some cells still 0, so `agg` ≠ `SumLocals`-when-all-done — but more
importantly the abstract `Finish` requires `c = N`, and the mapped
abstract step would have `c < N` ∧ `done' = TRUE`, which the abstract
spec forbids. **This is what `concept:await` buys you in pure TLA+.**

### 3. Change the `WITH` mapping so `c <- agg`

Run again. Refinement fails: between `Contribute(n)` and `Aggregate`,
`agg` does not change, but `c` should advance one tick at a time. The
mapping `c <- SumLocals` is the only choice that lets each concrete
`Contribute` step look like an abstract `Tick`. **This is what
`concept:refinement-mapping` is doing under the hood.**

### 4. Remove all type annotations

TLC behavior is unchanged — the annotations were inert for TLC. Run
`apalache check --inv=TypeOK --cinit=ConstInit DistributedCounter.tla`
and you will see snowcat report missing types. **This is `apa:type-base`
in action.**

## Verifying with Apalache

```bash
apalache check --inv=TypeOK --cinit=ConstInit --length=10 DistributedCounter.tla
```

The `--cinit=ConstInit` flag tells Apalache where to find the constant
initializer (Apalache reads `.cfg` files for the spec/properties but not
for `CONSTANT` bindings — that's Apalache's symbolic model talking).
Expected outcome: `NoError`.

## What this puzzle celebrates

You started in Tier 1 with a single PlusCal process that flipped a light
switch. You now have, in front of you, a distributed system whose
correctness is stated at two levels of abstraction, whose progress
guarantees use the right fairness, and whose aggregation is written as a
fold annotated for symbolic verification.

That is the toolkit. Congratulations.
