# 04 night-patrol

- family: control-state
- shape: prose situation with a fairness statement in prose, one liveness property, a diagnosis instruction for the counter-example case, and a closing question about whether the position belongs in the state and in the fairness statement
- time: 10 minutes
- shows TLA+ in the prompt: no
- two encodings measured: yes, the tuple with the position (rc 0, 8 states) and without it (rc 13, 8 states, stuttering)

## Constructs exercised

One per bullet, spelled as `drill/INVENTORY.md` field 4 spells it.

- vars (the all-variables tuple)
- [P]_x (box action formula)
- WF_v(A) (weak fairness)
- <<A>>_v (angle action formula)
- pc (PlusCal's label-tracking variable)
- label-as-action encoding
- <> (eventually)
- UNCHANGED
- BOOLEAN and integer interval as sets
- Set relational and algebraic operators

## Where each lands

| what | where |
|---|---|
| the all-variables tuple | the whole item: it must cover the control variable |
| the box action | the spec skeleton |
| weak fairness | "never stops for good" |
| the angle action | why the slipped tuple cannot see `Walk`, in the answer |
| the label-tracking variable | hand-rolled as `pos`, a scalar |
| label-as-action | `Walk` is the pure control-advance action |
| eventually | `WholeRound` |
| UNCHANGED | both actions |
| the integer interval | `1..N` |
| the set operators | union and non-membership in `Log` and `Walk` |

## The lesson in one line

An action that changes only the control variable is invisible to any fairness statement whose tuple leaves that variable out, so the advance becomes optional and the lasso stutters there.
