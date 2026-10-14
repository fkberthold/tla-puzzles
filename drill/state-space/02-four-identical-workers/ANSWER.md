# Answer: four identical workers

Files in `verify/`. `Pool.tla` is the system. `MCPool.tla` adds two named
workers so a config can state something that tells workers apart, which
is what the hazard needs.

Every number from `tlc -workers 1` on TLC2 Version 2026.07.31.184830.

## Question 1: what's multiplying

Each worker is idle, waiting or holding, so the per-worker part is 3 to
the N. The queue is where it gets worse: it's an ordering of the waiters,
and orderings grow as a factorial. The ratios in the table, 3.7, 4.3,
5.1, 6.0, climb instead of settling, which is the factorial showing
through. Two slots is a constant and doesn't move any of this.

## Question 2: the knob and its two conditions

Symmetry. The module names the permutation set and the config points at
it:

```
Perms == Permutations(Workers)
```

```
SYMMETRY Perms
```

TLC then treats two states as the same when one is the other with the
workers renamed, and only expands one of each class.

| workers | without | with symmetry |
|---|---|---|
| 2 | 10 | 6 |
| 3 | 37 | 9 |
| 4 | 159 | 12 |
| 5 | 811 | 15 |
| 6 | 4,888 | 18 |

The with column is 3N. The whole run reduces to how many workers are in
each of the three states, and in what order the waiters queued. Same
verdict, rc 0, every row.

**Condition one: the set must be model values.** `SymIntegers.cfg`
assigns `Workers = {1, 2, 3}` and exits 255, with "Symmetry function must
have model values as domain and range" in the log. The reason is that TLC
has to be able to swap the elements without changing anything else in the
state, and integers mean things.

**Condition two: the requirement must not tell workers apart.** `MCPool`
declares two more constants, `w1` and `w4`, and two requirements that are
false on the system and name one worker each:

```
FirstWorkerNeverHolds == st[w1] # "holding"
LastWorkerNeverHolds == st[w4] # "holding"
```

| requirement | without symmetry | with symmetry |
|---|---|---|
| first worker never holds | rc 12, 6 states, depth 3 | rc 12, 3 states, depth 3 |
| last worker never holds | rc 12, 21 states, depth 3 | **rc 0**, 12 states, depth 7 |

The second row is the hazard. Under symmetry TLC checked 12 states,
found no violation, and said so. The violating state (w4 holding) is a
renaming of one it had already expanded (w1 holding), so it never
generated it. The first row got caught only because w1 is the worker TLC
enumerates first, which makes the state it checks the one that happens to
violate. I suspect that's an accident of enumeration order and nothing to
rely on.

A symmetric statement of the same wrong claim, `NobodyEverHolds ==
Holders = {}`, is caught both ways (rc 12, 6 and 3 states).

## Question 3: the colleague's cap

`CONSTRAINT ShortQueue` with `ShortQueue == Len(queue) <= 2` at five
workers: rc 0, 211 distinct states against 811. Symmetry at the same size
is 15.

What it bought is the 211. What it can't see is any state with three or
more waiters, which on this system is where a scheduling bug would live.
The cap changed which system got checked. Symmetry didn't.

## Question 4: liveness

`EveryWaiterIsServed == \A w \in Workers : (st[w] = "waiting") ~> (st[w] = "holding")`
under `FairSpec`, three workers:

| | rc | distinct |
|---|---|---|
| without symmetry | 0 | 37 |
| with symmetry | **13** | 9 |

TLC prints a warning first: "Declaring symmetry during liveness checking
is dangerous. It might cause TLC to miss violations of the stated
liveness properties." Here it did the opposite and reported a violation
of a property that holds. Either direction, the answer under symmetry
isn't the answer. Check liveness without it, at a size you can afford.

## Variants worth running

Set `Slots = 1` and the queue becomes a mutex waiting line. Symmetry
still holds and the with column stays linear.

Add a third named worker and state `st[w1] = "holding" => st[w4] #
"holding"`. That's false too and asymmetric too. I'd guess it's missed,
but I haven't run it.

## Gate rows

One thin wrapper module per run the drill gate reproduces, each with a
copy of the config it stands for. The rc is what `harness/verdict.sh`
returns.

| module | rc | distinct | stands for |
|---|---|---|---|
| `G02Plain5.tla` | rc 0 | 811 | `NoSym5.cfg`, five workers, no symmetry, 811 states |
| `G02Sym5.tla` | rc 0 | 15 | `Sym5.cfg`, five workers under symmetry, 15 states |
| `G02PlainCaught.tla` | rc 12 | 21 | `NoSymLastWorker.cfg`, the asymmetric claim caught |
| `G02SymMissed.tla` | rc 0 | 12 | `SymLastWorker.cfg`, the same claim missed under symmetry |
| `G02SymInts.tla` | rc 255 | - | `SymIntegers.cfg`, symmetry over integers refused |
| `G02SymLive.tla` | rc 13 | 9 | `SymLiveness.cfg`, a true liveness claim reported violated |

telegraph-waiver: TLC -- the inventory cell for the PROPERTY row names the tool, and a prompt about what the model checker reports has to name it

## why-not-in-prompt

The prompt says "interchangeable" and "nothing about any worker differs
from any other". That's the definition of the symmetry condition in
prose, and a reader who knows the keyword will get there from the first
paragraph. I couldn't describe the system honestly without saying it,
because whether the workers are distinguishable is the fact the whole
item turns on.

What the prompt withholds: the keyword, that the set has to be model
values, that the requirement has to be symmetric too, which direction
the liveness result goes, and that the cap on the queue is a different
system. Question 2 says "two things", which tells the reader how many to
find without saying what they are. I think that's a fair trade for a
ten-minute item.
