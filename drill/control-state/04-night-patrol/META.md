# 04 night-patrol

- family: control-state
- shape: prose situation with a fairness statement in prose, one liveness property, a diagnosis instruction for the counter-example case, and a closing question about whether the position belongs in the state and in the fairness statement
- time: 10 minutes
- shows TLA+ in the prompt: no
- two encodings measured: yes, `vars` with the position (rc 0, 8 states) and without it (rc 13, 8 states, stuttering)

## Constructs exercised

Named as `drill/INVENTORY.md` field 4 writes them.

| id | construct | where |
|---|---|---|
| K082 | vars (the all-variables tuple) | the whole item: it must cover the control variable |
| K080 | `[P]_x` (box action formula) | the spec skeleton |
| K095 | `WF_v(A)` (weak fairness) | "never stops for good" |
| K094 | `<<A>>_v` (angle action formula) | why the slipped tuple cannot see `Walk`, in the answer |
| K036 | `pc` (PlusCal's label-tracking variable) | hand-rolled as `pos`, a scalar |
| K090 | label-as-action encoding | `Walk` is the pure control-advance action |
| K067 | `<>` (eventually) | `WholeRound` |
| K085 | UNCHANGED | both actions |
| K015 | BOOLEAN and integer interval as sets | `1..N` |
| K013 | Set relational and algebraic operators | `\cup`, `\notin` |

## The lesson in one line

An action that changes only the control variable is invisible to any fairness statement whose tuple leaves that variable out, so the advance becomes optional and the lasso stutters there.
