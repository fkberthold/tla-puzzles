# Answer: a clean run, and a colleague's deadlock

Files in `verify/`. `Locks.tla` is the system, with the lock order as a
constant. `MCLocks.tla` names the workers and locks and defines the two
orderings.

Every number from `tlc -workers 1` on TLC2 Version 2026.07.31.184830.

## Question 1: what differed

The command line. Your wrapper passed `-deadlock`, which switches the
check off, and the keyword you wrote in the config didn't switch it back
on. TLC's deadlock check is an AND across the two: the `.cfg`'s
`CHECK_DEADLOCK` keyword and the command line's `-deadlock` flag. Either
side turns it off, and neither side prints anything when it does.

The six runs, all on the buggy ordering:

| keyword in `.cfg` | `-deadlock` on the command line | rc | distinct | depth |
|---|---|---|---|---|
| absent | absent | 11 | 7 | 4 |
| absent | present | 0 | 13 | 7 |
| `TRUE` | absent | 11 | 7 | 4 |
| `TRUE` | present | **0** | 13 | 7 |
| `FALSE` | absent | 0 | 13 | 7 |
| `FALSE` | present | 0 | 13 | 7 |

Row four is yours. You wrote the keyword that asks for the check, on a
model that has the bug, and got a clean run. The flag you never saw won.
Your colleague ran bare `tlc` and got row three.

This repo's own verdict channel passes `-deadlock` on every run, and
until bead `tla-eafx` it did this to every learner config that said
`TRUE`. It now refuses the run with rc 99 when the two sides disagree
(`harness/verdict.sh:189-235`). The six cells above match the table in
that file to the number.

The default, with no keyword and no flag, is checking on. 79 of the 337
published configs in the corpus write `CHECK_DEADLOCK FALSE`, and 334
configs in this repo do, because their terminal states are the point
(`.claude/rules/tla-practice.md`, section 7). So "absent" is the row to
be careful with: it's the strict one.

## Question 2: the depth-7 deadlock on the fixed ordering

Not real. `SameNoKeyword.cfg` exits 11 at 12 distinct states, depth 7,
and the state it reports is both workers at `pc = 3`, both locks free.
That's everybody finished. TLC's definition of a deadlock is a state
with no successor, and a system that's done has no successor.

The one at depth 4 on the buggy ordering is real: `a` holds `l1`, `b`
holds `l2`, each waiting on the other's.

## Question 3: two ways to a clean run

**Throw the check away.** `CHECK_DEADLOCK FALSE`. `SameFalse.cfg` exits
0 at 12 states. It would also exit 0 on the buggy ordering (that's row
five above), so it can't tell the two apart.

**Keep it, and say in the spec that finishing goes nowhere.**

```
Terminating == AllDone /\ UNCHANGED vars
SpecWithEnd == Init /\ [][Next \/ Terminating]_vars
```

With the check on:

| ordering | spec | rc | distinct | depth |
|---|---|---|---|---|
| same | `SpecWithEnd` | 0 | 12 | 7 |
| opposite | `SpecWithEnd` | **11** | 7 | 4 |

The finished state now has a successor (itself), so TLC doesn't report
it, and the real deadlock at depth 4 still has none, so TLC does. This
is what the PlusCal translator does for you with its `Terminating`
disjunct, and in raw TLA+ you write the one line yourself.

I'd take the second route whenever the model has a real "done". The
first is fine for a model that runs forever, where there's no terminal
state to excuse and any stuck state is a bug.

## Variants worth running

Add a third worker with the same ordering. `SpecWithEnd` still exits 0,
and `AllDone` is the only thing you had to leave alone.

Take `Terminating` out of `SpecWithEnd` and put `CHECK_DEADLOCK FALSE`
back. Then add a bug where a worker releases only one lock. Nothing
reports it. The requirement is about working, not finishing, and the
check that would have caught a stuck worker is off.

## Gate rows

One thin wrapper module per run the drill gate reproduces, each with a
copy of the config it stands for. The gate runs them through
`harness/verdict.sh`, which passes `-deadlock` on every run and refuses
with rc 99 when the config asks for the check that flag turns off. So
the rc column here is the six-cell table seen through that channel,
and the middle row is the harness doing on purpose what bare `tlc`
does silently.

| module | rc | distinct | stands for |
|---|---|---|---|
| `G04Opposite.tla` | rc 0 | 13 | `OppositeNoKeyword.cfg`, the buggy ordering, keyword absent, flag present: the real stuck state not reported |
| `G04AsksOpposite.tla` | rc 99 | - | `OppositeTrue.cfg`, the buggy ordering asking for the check: the channel refuses rather than drop it |
| `G04SameEnd.tla` | rc 0 | 12 | `SameWithEnd.cfg`, the fixed ordering with finishing allowed to go nowhere |

## why-not-in-prompt

The prompt says you "wrote the config asking TLC to check for a stuck
state", which tells the reader a keyword exists. It also says the
colleague ran "your two files unchanged", which puts the difference
outside the files, and there's only one place outside the files. A
reader who knows there's a `-deadlock` flag has question 1 from that
sentence.

What the prompt withholds: that the two sides are an AND, that neither
side reports the override, which direction the default runs, that
"done" counts as deadlocked, and the `Terminating` shape. Question 3
says there are two routes and that one keeps the check, which narrows
the search without naming the line.

The honest caveat: "six ways" in question 1 is the shape of the answer
table, and I gave it because without that nudge the reader runs two
cells and stops. The thing worth learning is the full table, and I
think the nudge is cheaper than the gap.
