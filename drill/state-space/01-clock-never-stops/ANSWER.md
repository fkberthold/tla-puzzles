# Answer: the clock that never stops

Files in `verify/`. `Heartbeat.tla` is the system, with a `Fence` constant
so the buggy and fixed runs share one module. `MCHeartbeat.tla` carries the
three knobs side by side. `HeartbeatRelative.tla` is question 3.

Every number below came from `tlc -workers 1` on TLC2 Version
2026.07.31.184830, each config in its own run, wall time from `date`
around the call.

## Question 1: why the fix made it slow

TLC searches breadth first. With the bug in, the violation sits at depth 5
(pause, three ticks, promote, resume), and TLC reports it the moment it
generates that state. It never needs the rest of the graph.

A clean verdict is a claim about every reachable state. The clock makes
that set infinite, because `Tick` is enabled in every state and `clock`
never comes back down. So the buggy run stopped at 15 states and the fixed
one was at 2,954,402 when I killed it at 30 seconds (rc 124). Same model.
One asks "is there a bad state", the other asks "is there no bad state",
and only the second has to finish.

## Question 2: two places for the cap

**Inside the behaviour formula.** `MCHeartbeat.tla` defines

```
BoundedNext == Next /\ clock' <= MaxTime
BoundedSpec == Init /\ [][BoundedNext]_vars
```

and the config names `SPECIFICATION BoundedSpec`. This is a different
system. Its clock stops.

**Outside it, in the config.** The module defines `ClockBound == clock <=
MaxTime` and the config says `CONSTRAINT ClockBound` with `SPECIFICATION
Spec` unchanged. TLC generates every successor as before, checks it, and
only expands the ones inside the bound.

What the two measured, at every cap:

| cap | spec-side generated | spec-side distinct | constraint generated | constraint distinct |
|---|---|---|---|---|
| 3 | 45 | 21 | 54 | 21 |
| 6 | 153 | 66 | 171 | 66 |
| 12 | 585 | 237 | 621 | 237 |
| 24 | 2,313 | 903 | 2,385 | 903 |
| 48 | 9,225 | 3,531 | 9,369 | 3,531 |

Distinct counts match to the state. Generated counts don't, and the gap is
the states just past the bound. Under the spec-side bound they're never
produced. Under the constraint TLC produces them, decides they're outside,
and drops them without counting them as found.

It checks them first, though. `ConstraintProbe12.cfg` declares an invariant
`InsideBound == clock <= MaxTime` next to the same constraint, and it exits
12 at 183 distinct states, depth 13. So a state outside the constraint
still gets the invariants run over it. A constraint stops expansion, not
checking. The same probe under `ACTION_CONSTRAINT` also exits 12 at 183.

The deadlock check is where the two routes split. With `CHECK_DEADLOCK`
left at its default of on:

| route at cap 12 | rc | distinct | depth |
|---|---|---|---|
| spec-side bound | 11 | 217 | 15 |
| `CONSTRAINT` | 0 | 237 | 15 |
| `ACTION_CONSTRAINT` | 0 | 237 | 15 |

Under the spec-side bound, take the state at the cap with the primary
fenced and the standby working. It has no successor at all, so TLC
reports it. Under the constraint `Tick` is still enabled there (its
successor just gets dropped), so nothing looks stuck. One route tells you the cap created a dead end,
the other hides it. I think that's the most useful difference, since the
dead end is an artifact of the cap and not of the supervisor.

`ACTION_CONSTRAINT TickWithin` with `TickWithin == clock' <= MaxTime` gave
the same numbers as `CONSTRAINT` in every cell here. On this spec the
step constraint is a function of the successor state alone, so it has to.
It would differ for something like `clock' - clock <= 1`, which no state
constraint can say.

## Question 3: nothing to cap

The supervisor reads `clock - lastBeat` and compares it to `Timeout`. It
never reads the clock on its own. `HeartbeatRelative.tla` keeps `since`,
the gap, and stops counting once it passes `Timeout`:

```
Tick == since' = IF since > Timeout THEN since ELSE since + 1
```

| run | rc | distinct | depth | wall |
|---|---|---|---|---|
| relative, fixed | 0 | 9 | 5 | 0.3 s |
| relative, buggy | 12 | 9 | 5 | 0.3 s |

Nine states, no constant to pick, and the same bug at the same depth. The
fencing spike in this repo found the same shape: the clockless model
caught its bug in 21 states against 62 (`sources/README.md:152`). The
requirement there never asked how long anything took, only in what order,
and I think the same is true here.

## Variants worth running

`RelativeBuggy.cfg` runs `HeartbeatRelative` with `Fence = FALSE`. The
bug survives the rewrite, which is the check that the abstraction
didn't lose it.

Set `Timeout = 0` in `Relative.cfg`. The gap tops out at 1, the space
shrinks to a handful, and `Promote` fires on the first tick. The model is
right about that: a zero timeout promotes on any pause.

## Gate rows

One thin wrapper module per run the drill gate reproduces, each with a
copy of the config it stands for. The rc is what `harness/verdict.sh`
returns, with its default `-deadlock`.

| module | rc | distinct | stands for |
|---|---|---|---|
| `G01Bug.tla` | rc 12 | 15 | `UnboundedBuggy.cfg`, the bug found at depth 5 in the infinite graph |
| `G01Cut12.tla` | rc 0 | 237 | `Constraint12.cfg`, the constraint at cap 12 |
| `G01Cap12.tla` | rc 0 | 237 | `SpecBound12.cfg`, the spec-side bound at cap 12 |
| `G01Probe12.tla` | rc 12 | 183 | `ConstraintProbe12.cfg`, a state outside the constraint still checked |
| `G01Gap.tla` | rc 0 | 9 | `Relative.cfg`, the model with no clock to bound |

## why-not-in-prompt

The prompt says "I capped the clock". That names the variable that's
growing, which is half of question 1. I couldn't give the growth table
without saying what I varied, and a table with no axis label is a worse
puzzle, not a harder one.

What the prompt withholds: the word for either route, that the two routes
give the same distinct count, that one of them still checks states it
won't expand, and that the deadlock check tells them apart. Question 2
does say there are two routes, so a reader who's met `CONSTRAINT` will
reach for it as the second one. The one I most wanted to hide was the
deadlock split, and I think the prompt hides it.

The honest caveat on question 3: the prompt says "say what the supervisor
reads", and that's a nudge toward the gap. I left it in because without
it the question reads as "find a trick", and there's no trick, only a
variable that was never needed.
