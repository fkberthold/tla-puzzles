# p1-commit, the item record

Withheld from every delivery route, the same way a drill item's `ANSWER.md`
and `verify/` are. Do not read this before attempting the item.

## The system

Two-phase commit over a set of resource managers with one coordinator.

| field | value |
|---|---|
| requirement module | `TCommit.tla` |
| requirement source | `tlaplus/Examples`, `specifications/transaction_commit` |
| pinned commit | `0cab2b3fbfefc6d48a9f84a432f5bb5498738d46` |
| licence | MIT |
| published answer | `specifications/transaction_commit/TwoPhase.tla` |
| grading model | `RM = {r1, r2}` |
| abstract init | `TCInit`, not the grader's default of `Init` |
| abstract spec | `TCSpec` |

## The decision the brief forces

Requirement 1 says a resource manager can give up without asking anybody.
Requirement 4 says every resource manager commits once the coordinator has
announced a commit. Requirement 5 says no two reach opposite outcomes.

The pair does not say when the right in requirement 1 runs out. Two readings:

- **It ends when the manager votes.** `RMChooseToAbort` is guarded by
  `rmState[rm] = "working"`. This one refines.
- **It lasts until the manager commits.** The guard widens to
  `rmState[rm] \in {"working", "prepared"}`. This one does not refine.

The second reading costs the transaction its consistency. Once the coordinator
has committed, one manager can take the commit message while another walks
away, so two managers reach opposite outcomes. `TCommit` admits no such step,
because its `Decide` action only aborts under `notCommitted`.

This is 2PC's blocking property, which is the thing people complain about in
2PC and the reason Paxos Commit exists. So the decision is a real engineering
decision with a published answer, not a puzzle.

## Expected verdicts

| module | verdict | exit |
|---|---|---|
| `verify/TwoPhaseCommit.tla` | `REFINES` | 0 |
| `verify/WrongUnilateralAbort.tla` | `REFINEMENT_VIOLATED` | 22 |
| `verify/FrozenMapping.tla` | `FROZEN_MAPPING` | 20 |

`FrozenMapping.tla` is the trapdoor the bead is built around, shown shut on
this item's own material rather than on `harness/fixtures/refinement`. Its
concrete spec is honest and its mapping sends `rmState` to a constant.

## How this item differs from a drill item

Named on Barnett & Ceci 2002 dimensions, which do not combine into one scalar,
so each one stands on its own.

- **Modality**: 921 words, no state count, no construct list.
- **Functional context**: framed as a design review, not as an exercise.
- **Memory demands**: two machines, `TCommit`'s and his own, plus the mapping.
- **Ill-structured**: three bounds the prose leaves open, and the pair above.

## The mapping, and what the grader cannot see

The mapping for this item is close to an identity on `rmState`, so it tests
less of the mapping skill than p2-queue does. That is the known weakness of
this item and it is why the two items are not interchangeable.

The grader also cannot rule out a submission that adds a history variable to
make a mapping exist. Lamport's *Hiding* argument, quoted in
`harness/refinement.sh`, is that for any two specs suitable auxiliary
variables make a refinement mapping exist. So a module whose state carries
something the described system does not have is a finding for a reader, not
for TLC. Check it by eye when the verdict comes back `REFINES`.
