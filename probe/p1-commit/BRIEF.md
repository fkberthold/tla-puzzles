# A transaction that spans several stores

## What you are being asked for

A team is about to ship a distributed commit path. They want the design
checked before it lands. They have written the requirement down as a TLA+
module, `TCommit.tla`, and that module is published work. It is not yours to
change.

The deliverable is a specification of the protocol that refines it, plus the
refinement mapping that says how your state lines up with theirs. Write it the
way you would write something a colleague has to read in a pull request.

This is not a drill item. There is no construct list, there is no state count
to match, and nobody has told you how long it should take.

## The system

One business transaction touches several independent stores. Each store runs
its own resource manager. A resource manager owns the data it is about to
change and knows nothing about the other stores. One coordinator drives the
transaction to an outcome.

The point of the whole protocol is that no two resource managers end up with
opposite outcomes. One cannot keep the change while another throws it away.

A resource manager is in one of four states. It starts out **working**, which
means it is still doing local work and has promised nothing. It moves to
**prepared** once it has written enough that it could commit if it were asked
to, and has reported that to the coordinator. From there it ends up either
**committed** or **aborted**. Those two are final. Nothing moves a resource
manager out of them.

The coordinator holds its own state. It also keeps its own record of which
resource managers have reported in, and that record is not the same thing as
the managers' own states. The coordinator shares no memory with them.
Everything between the two sides travels as a message.

A sent message stays readable. Reading it does not consume it, so a message
read by one resource manager is still there for the next one.

The protocol runs in two phases. In the first phase each resource manager
decides on its own whether it can commit, and the ones that can report it. In
the second phase the coordinator picks the outcome and announces it. A resource
manager that hears the commit announcement commits. One that hears the abort
announcement aborts.

## The requirements

1. A resource manager can refuse. It needs nobody's permission to give up, and
   one that gives up ends up aborted.
2. The coordinator announces a commit only when every resource manager has
   reported that it is prepared.
3. The coordinator can stop waiting and announce an abort instead.
4. Once the coordinator has announced a commit, every resource manager in the
   transaction commits.
5. No two resource managers reach opposite outcomes.

At least one pair of these needs a decision from you. The prose does not
settle it, and the two readings do not specify the same protocol. Find the
pair, decide it, and write the decision down before you grade. The command
that grades will ask you for it.

## What the prose does not give you

- How many resource managers there are.
- What makes the coordinator stop waiting.
- Whether a message can be read more than once, or go missing.

The grader runs your specification against a model of two resource managers,
so the set has to be a parameter of your module rather than a number inside
it. The other two are yours to pick. Say what you picked.

## What to produce

One file, `TwoPhaseCommit.tla`, holding `MODULE TwoPhaseCommit`. Put it next to
this brief. It has to carry three things the grader looks for by name.

- `Spec`, your behavior formula, in the shape `Init /\ [][Next]_vars`.
- An `INSTANCE TCommit WITH ...` clause naming every substitution.
- `Refines`, defined as your instance name followed by `!TCSpec`.

Name every substitution in the `WITH` clause, including the ones that look
like an identity. The grader refuses an `INSTANCE` with no `WITH` at all,
because leaving it off is silent and gives you a different mapping than the
one you meant.

It also refuses a mapping that never moves. Map the abstract state to a
constant and the requirement's action formula reduces to something true at
every step, so the check would pass without ever reading the requirement. A
passing probe is a failing invariant check, and the grader runs TLC twice to
get both answers.

## How to grade it

```bash
./probe grade p1-commit
```

The verdicts you are likely to see:

| verdict | what it means |
|---|---|
| `REFINES` | it holds, and the mapping moves. This is the pass. |
| `REFINEMENT_VIOLATED` | your protocol admits a step the requirement does not. |
| `FROZEN_MAPPING` | the mapped expression never left its initial value. |
| `IMPLICIT_MAPPING` | your `INSTANCE` has no `WITH` clause. |
| `REFINES_UNDEFINED` | the grader could not find `Refines`. |

A `REFINEMENT_VIOLATED` run leaves a counterexample trace behind. Read it. It
names the step your protocol took that the requirement has no answer for.

## Where the published answer is

The system is `specifications/transaction_commit/TwoPhase.tla` in
`tlaplus/Examples`, at the commit `probe/scripts/fetch-oracles.sh` pins.

Do not open it before you grade. It is the thing this probe measures you
against, and reading it first throws the measurement away. Afterwards it is
worth reading closely, and the interesting part is where your structure and
theirs disagree rather than where they match.
