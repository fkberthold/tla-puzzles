# 04 night-patrol: answer

The guard's position is control state. It says where in the round the
guard is, and nothing in the world records it but the guard. It belongs in
the state, and it belongs in the tuple under every box and every fairness
operator, because the step that only changes it is the step a narrower
tuple cannot force.

## The spec

`verify/Patrol.tla`.

```tla
EXTENDS Naturals
CONSTANT N
Checkpoints == 1..N

VARIABLES pos, logged
vars == <<pos, logged>>

Init == /\ pos = 1
        /\ logged = {}

Log == /\ pos \notin logged
       /\ logged' = logged \cup {pos}
       /\ UNCHANGED pos

Walk == /\ pos \in logged
        /\ pos' = (pos % N) + 1
        /\ UNCHANGED logged

Next == Log \/ Walk

Spec == Init /\ [][Next]_vars /\ WF_vars(Next)

WholeRound == <>(logged = Checkpoints)
```

Config: `N = 3`, `PROPERTY WholeRound`. **Measured: rc 0, 8 distinct
states** (`verify-all.sh` row `04-Patrol`).

"Never stops for good" is `WF_vars(Next)`: if some step stays possible, one
is eventually taken. The guard here is one process with two actions, so
fairness on `Next` is fairness on the guard.

The two-sentence answer: the position belongs in the state, because
`Walk` and `Log` are both guarded on it and nothing else in the model can
stand in for it. It belongs in the fairness statement because `Walk`
changes nothing but the position, and a fairness statement that does not
mention the position cannot see `Walk` happen, so cannot force it.

## The slip, and the trace it produces

`verify/PatrolSlip.tla` is the same module with one line changed:

```tla
vars == <<logged>>
```

Everything else is identical, including `[][Next]_vars /\ WF_vars(Next)`.
**Measured: rc 13, `WholeRound` violated, 8 distinct states**
(`verify-all.sh` row `04-PatrolSlip`). Same state count as the correct
spec, which is the first thing to notice: TLC generated the same graph.
The difference is entirely in what fairness forces.

| state | action | pos | logged |
|---|---|---|---|
| 1 | | 1 | {} |
| 2 | Log | 1 | {1} |
| 3 | Walk | 2 | {1} |
| 4 | Log | 2 | {1, 2} |
| 5 | stuttering | | |

The guard stops at checkpoint 2 with it logged and checkpoint 3 never
visited. `Walk` is enabled in state 4. Nothing forces it.

Why not: `WF_v(A)` promises that if `<<A>>_v` stays enabled, an `<<A>>_v`
step eventually happens, and `<<A>>_v` means "an `A` step that changes
`v`". With `v = <<logged>>`, a `Walk` step changes nothing in `v`, so it is
not an `<<A>>_v` step, so the promise says nothing about it. `Log` in state
2 was forced, because it changes `logged`. `Walk` in state 2 was taken only
because TLC explored it. In state 4 TLC is allowed to explore the
behaviour that stutters forever, and that behaviour satisfies the slipped
spec and fails the property.

The corpus figure behind this: a box-action subscript covers the tuple of
every variable at 96.2% of the resolvable sites in 666 published modules
(`.claude/rules/tla-practice.md:177`), and `pc` is in that tuple in 49 of
the 59 translated modules (`.claude/rules/tla-practice.md:419`). The
translator puts `pc` in `vars` for exactly this reason. Writing `vars` by
hand means remembering why.

## The same slip in the other place

Had the slip been `WF_vars(Log)` instead of `WF_vars(Next)`, with a correct
`vars`, the trace would be the same: `Walk` is never under a fairness
operator, so the guard may stand at a logged checkpoint forever (INFERRED
from the definition, not run). The lesson generalises: every action that
advances control state needs to be under the fairness operator, and the
tuple under that operator needs to include the control variable, or the
advance is optional.

## Acceptable variants

- **`WF_vars(Log) /\ WF_vars(Walk)`** instead of `WF_vars(Next)`. Equivalent
  here and stronger in general (per-action fairness). Same verdict
  (INFERRED).
- **Model-value checkpoints** with an explicit successor function instead
  of `1..N` and `%`. Same shape. More typing.
- **A `pc`-named variable.** Calling it `pos` is the item's point: control
  state does not have to be called `pc` to be control state.
- **A liveness property per checkpoint**, `\A c \in Checkpoints : <>(c \in
  logged)`. Equivalent.

## Elimination table

| neighbour answer | what kills it |
|---|---|
| `vars` without `pos` | the trace above: rc 13, stuttering at checkpoint 2. |
| `Walk` with no guard (the guard may walk on before logging) | `WholeRound` fails with a lasso, not a stutter: the guard can circle forever without logging, and `WF_vars(Next)` is satisfied by the circling (INFERRED from the definition, and an authoring probe of exactly this shape gave rc 13 with "Back to state 3", and was not kept). |
| no fairness at all | rc 13, stuttering at state 1 (INFERRED, not run). The property is liveness and needs a fairness assumption. |
| position left out of the state entirely, `Log` picks any unlogged checkpoint | passes, rc 0 (INFERRED), and is a different guard: one who teleports. The prompt's "fixed round" and "walks on to the next" are what it violates. |

## why-not-in-prompt

The prompt shows no TLA+. Its caveat is the last paragraph. "The guard's
position is not something the clock records" plants the idea that it might
be left out, and asking whether it belongs "in the statement that the
guard never stops for good" points at the fairness tuple specifically. A
reader who takes the hint will put `pos` in `vars` and never see the slip.
That is acceptable: the retrieval happened. The item cannot force the slip
without showing code, so it is built the other way round, as a correct
answer with the slip's trace alongside for the reader who made it. The
instruction "say at which state the guard stopped and what the guard was
able to do there" is the diagnosis step, pre-written for whoever needs it.
