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
  remain *continuously* enabled. Even after every node has contributed,
  `ToggleReady` can still flip `ready` back to FALSE, so `Aggregate` is
  never guaranteed to be continuously enabled. We need
  `SF_vars(Aggregate)`: infinitely often enabled is enough.

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

- **Refinement mapping (Tier 6).** That `WITH` clause is where the
  refinement mapping is declared. Every concrete behavior, viewed through the mapping, is a
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
  Apalache see the same module. TLC executes the recursive body of
  `ApaFoldSet` defined in `Apalache.tla` as a normal RECURSIVE operator
  — it is a correct, complete implementation, not a placeholder. Apalache
  replaces it with a native symbolic encoding at verification time. Both
  produce the same result; the difference is only in how they compute it.

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

TLC reports a liveness violation. The key shape of the counterexample
is a lasso in which `ready` toggles between TRUE and FALSE while
`Aggregate` never fires (your exact state numbers will depend on TLC's
exploration order and the size of the `Nodes` set):

```
...
State k:   all locals = 1, ready = FALSE
State k+1: ToggleReady → ready = TRUE
Back to state k: ToggleReady → ready = FALSE
```

The heartbeat loops forever between ready = TRUE and ready = FALSE.
`Aggregate` is enabled in odd steps and disabled in even steps — it is
infinitely-often enabled but not continuously enabled. WF does not fire
it; SF does. **(Exact state numbers depend on TLC's exploration order;
the key shape is the loop above.) This is what `concept:strong-fairness`
means in practice.**

### 2. Drop the `\A n \in Nodes : local[n] = 1` conjunct from `Aggregate`

TLC reports a refinement violation. The coordinator can now aggregate
before all cells are 1, so `SumLocals` is less than `NodeCount` at the
moment of aggregation. More importantly, the abstract `Finish` requires
`c = N`, and the mapped abstract step would have `c < N` ∧ `done' = TRUE`,
which the abstract spec forbids. **This is what `concept:await` buys you
in pure TLA+.**

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

## Hints

??? hint "💡 Hint 1 — Start with the abstract spec as your north star"
    Before diving into DistributedCounter.tla, read AbstractCounter.tla first. It's only 62 lines and it shows you the endpoint: a counter that increments to N and then signals done. Every mechanism in the concrete spec exists to make this abstract behavior true. Ask yourself: "How does each concrete action map to an abstract action?" The `WITH` clause tells you the answer.

??? hint "💡 Hint 2 — The heartbeat is the reason strong fairness exists"
    ToggleReady flips `ready` back and forth while the system is running. This means Aggregate is enabled (ready=TRUE), then disabled (ready=FALSE), then enabled again — intermittently enabled. Weak fairness fires actions that remain continuously enabled; strong fairness fires actions that are infinitely-often enabled even if they keep being disabled. Which fairness does Aggregate need? Look at the first experiment to see what happens if you guess wrong.

??? hint "💡 Hint 3 — The `WITH` mapping encodes the design choice"
    Four state variables appear in DistributedCounter: `local`, `ready`, `agg`, `aggDone`. But AbstractCounter only cares about `c` and `done`. The `WITH` clause tells TLC: `c <- SumLocals` and `done <- aggDone`. This isn't a whim — it's a choice. The `ready` flag and the heartbeat exist at the concrete level only; they are invisible to the abstract spec. Why does the mapping use SumLocals instead of `agg`? Try experiment 3 and you'll see.

??? hint "💡 Hint 4 — Type annotations are bridges between TLC and Apalache"
    Every CONSTANT and VARIABLE carries a `\* @type:` comment. TLC ignores these; Apalache reads them. When you run `apalache check`, it uses the type information to verify the spec symbolically without enumerating all states. If you remove the type annotations, TLC still works fine — but Apalache will complain. This is why capstones for the Apalache track include these annotations even though TLC doesn't need them.

??? hint "💡 Hint 5 — ApaFoldSet is the tool for aggregation over sets"
    SumLocals uses ApaFoldSet to fold (aggregate) over all nodes. It looks like: `ApaFoldSet(Add, 0, Nodes)` — accumulate with the Add operator, starting from 0, across the set Nodes. The `Add(acc, n)` operator adds the current node's local cell to the accumulator. Both TLC and Apalache accept this syntax because the Apalache.tla module is included in the solution directory, providing the definition.
