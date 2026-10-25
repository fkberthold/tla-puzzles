# A bounded queue that two kinds of thread wait on

## What you are being asked for

A team is replacing the queue that sits between their producer threads and
their consumer threads. They want the replacement checked before it lands.
They have written the requirement down as a TLA+ module, `BlockingQueue.tla`,
and that module is published work. It is not yours to change.

The deliverable is a specification of the replacement that refines it, plus
the refinement mapping that says how your state lines up with theirs. Write it
the way you would write something a colleague has to read in a pull request.

This is not a drill item. There is no construct list, there is no state count
to match, and nobody has told you how long it should take.

## The system

A bounded queue sits between a set of producer threads and a set of consumer
threads. No thread is both kinds. A producer adds one entry at a time. A
consumer takes the oldest entry. The queue holds a fixed maximum number of
entries, and that maximum is at least one.

The entry a producer adds is a token naming the producer that added it. The
requirement module's queue is a sequence of producer identities, so this one
is not a free choice. Read the module and match it.

A thread that cannot do its work goes to sleep. A sleeping thread does
nothing at all until something wakes it. It takes no steps, it holds no lock,
and it does not spin.

The replacement keeps two sleep lists rather than one, and that is the whole
reason it exists. The version being retired kept a single list of sleeping
threads. A producer finishing a hand-off could wake another producer out of
that list, which achieved nothing, and the queue could stall with work
available and everybody asleep. Splitting the list by kind of thread is the
fix. A hand-off now reaches into the list it means to reach into.

## The requirements

1. A producer that finds the queue full goes to sleep.
2. A consumer that finds the queue empty goes to sleep.
3. A producer that adds an entry hands off to a sleeping consumer.
4. A consumer that takes an entry hands off to a sleeping producer.
5. A hand-off never wakes a thread of the same kind as the thread handing off.
6. No sleeping consumer stays asleep while the queue holds an entry.
7. A woken thread is awake and runs. It re-checks nothing on the way.

At least one pair of these needs a decision from you. The prose does not
settle it, and the two readings do not specify the same queue. Find the pair,
decide it, and write the decision down before you grade. The command that
grades will ask you for it.

## What the prose does not give you

- The queue's maximum size.
- How many producers and how many consumers there are.
- Which sleeping thread a hand-off picks when several are asleep.
- Whether a thread that wakes and still cannot work goes back to sleep.

The grader runs your specification against a model of two producers, two
consumers and a maximum of one entry. So the first two have to be parameters
of your module rather than numbers inside it. The last two are yours to pick.
Say what you picked.

## What to produce

One file, `SplitWaitSets.tla`, holding `MODULE SplitWaitSets`. Put it next to
this brief. It has to carry three things the grader looks for by name.

- `Spec`, your behavior formula, in the shape `Init /\ [][Next]_vars`.
- An `INSTANCE BlockingQueue WITH ...` clause naming every substitution.
- `Refines`, defined as your instance name followed by `!Spec`.

Name every substitution in the `WITH` clause, including the ones that look
like an identity. The grader refuses an `INSTANCE` with no `WITH` at all,
because leaving it off is silent and gives you a different mapping than the
one you meant.

It also refuses a mapping that never moves. Map the abstract state to a
constant and the requirement's action formula reduces to something true at
every step, so the check would pass without ever reading the requirement. A
passing probe is a failing invariant check, and the grader runs TLC twice to
get both answers.

The mapping is the part worth slowing down on here. Your state and the
requirement's state are not the same shape, so one of your substitutions has
to be an expression rather than a variable name.

## How to grade it

```bash
./probe grade p2-queue
```

The verdicts you are likely to see:

| verdict | what it means |
|---|---|
| `REFINES` | it holds, and the mapping moves. This is the pass. |
| `REFINEMENT_VIOLATED` | your queue admits a step the requirement does not. |
| `FROZEN_MAPPING` | the mapped expression never left its initial value. |
| `IMPLICIT_MAPPING` | your `INSTANCE` has no `WITH` clause. |
| `REFINES_UNDEFINED` | the grader could not find `Refines`. |

A `REFINEMENT_VIOLATED` run leaves a counterexample trace behind. Read it. It
names the step your queue took that the requirement has no answer for.

## Where the published answer is

The system is `BlockingQueueSplit.tla` in `lemmy/BlockingQueue`, at the commit
`probe/scripts/fetch-oracles.sh` pins.

Do not open it before you grade. It is the thing this probe measures you
against, and reading it first throws the measurement away. Afterwards it is
worth reading closely, and the interesting part is where your structure and
theirs disagree rather than where they match.
