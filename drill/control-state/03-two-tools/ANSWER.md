# 03 two-tools: answer

Two ways to make the end of the day legitimate, and they are not the same
statement. A `Terminating` action says *this* end state is intended. The
config's `CHECK_DEADLOCK FALSE` says *every* stuck state is fine. The new
hire is the difference between them, measured.

## The spec

`verify/Agreed.tla`. Labels as model values, a function from technician
to label, a function from tool to holder.

```tla
CONSTANTS Techs, Nobody,
          Ladder, Meter,
          Idle, HasLadder, HasBoth, Done

ProcSet == Techs

VARIABLES pc, holder
vars == <<pc, holder>>

Init == /\ pc = [t \in ProcSet |-> Idle]
        /\ holder = [tool \in {Ladder, Meter} |-> Nobody]

TakeLadder(t) == /\ pc[t] = Idle
                 /\ holder[Ladder] = Nobody
                 /\ holder' = [holder EXCEPT ![Ladder] = t]
                 /\ pc' = [pc EXCEPT ![t] = HasLadder]

TakeMeter(t) == /\ pc[t] = HasLadder
                /\ holder[Meter] = Nobody
                /\ holder' = [holder EXCEPT ![Meter] = t]
                /\ pc' = [pc EXCEPT ![t] = HasBoth]

Finish(t) == /\ pc[t] = HasBoth
             /\ holder' = [tool \in {Ladder, Meter} |-> Nobody]
             /\ pc' = [pc EXCEPT ![t] = Done]

Work == \E t \in ProcSet : TakeLadder(t) \/ TakeMeter(t) \/ Finish(t)

BothInHand == \A t \in ProcSet :
                 pc[t] = HasBoth => holder[Ladder] = t /\ holder[Meter] = t
```

"Waits for it" is the guard `holder[...] = Nobody`. There is no waiting
action, because waiting changes nothing.

## What TLC says first

With `Spec == Init /\ [][Work]_vars` and nothing about the end of the day
(`verify/DayBare.cfg`): **rc 11, deadlock reached, 12 distinct
states** (`verify-all.sh` row `03-DayBare`). The trace is seven states
long and ends at `pc = (a :> Done @@ b :> Done)` with both tools on the
rack. That is the intended end, reported as a fault.

Every rc and state count in this file is a row of
`drill/control-state/verify-all.sh`, named by its config.

## The two ways to deal with it

**The `Terminating` action.** Add a disjunct that is enabled exactly in the
intended end state and changes nothing.

```tla
Terminating == /\ \A t \in ProcSet : pc[t] = Done
               /\ UNCHANGED vars

Next == Work \/ Terminating
Spec == Init /\ [][Next]_vars
```

`verify/Agreed.cfg`: **rc 0, 12 distinct states.** The quantifier
ranges over `ProcSet`, which is why that set gets a name even when it is
just `Techs`.

**The config switch.** Leave the spec alone and write `CHECK_DEADLOCK
FALSE` in the config. `verify/DayNoDL.cfg`: **rc 0, 12 distinct
states.**

Same verdict, same count, and on the agreed procedure nothing tells them
apart. 79 of 337 published configs carry the switch
(`.claude/rules/tla-practice.md:446`), so it is not a smell. It is a
statement, and the next section is what it states.

## The new hire

`verify/NewHire.tla`. One constant `Rookie`, a `FirstTool(t)` operator that
gives the rookie the meter, and `TakeFirst` / `TakeSecond` in place of the
two named actions. Nothing else moves.

| end-of-day treatment | config | rc | what TLC says |
|---|---|---|---|
| `Terminating` disjunct | `NewHire.cfg` | **11** | deadlock after 3 states: `a` holds the ladder, `b` holds the meter, each waiting for the other |
| `CHECK_DEADLOCK FALSE` | `RookieNoDL.cfg` | **0** | nothing. 13 distinct states, invariant holds |
| `CHECK_DEADLOCK FALSE` plus a liveness property | `RookieLive.cfg` | **13** | `DayEnds` violated, stuttering at the same state |

The trace under `Terminating`:

| state | action | a | b | ladder | meter |
|---|---|---|---|---|---|
| 1 | | Idle | Idle | Nobody | Nobody |
| 2 | TakeFirst(a) | HasLadder | Idle | a | Nobody |
| 3 | TakeFirst(b) | HasLadder | HasMeter | a | b |

Nothing is enabled in state 3, `Terminating` included, because nobody is
`Done`. That is the answer to the prompt's last question: **yes, the way
you dealt with the end of the day is the whole of what TLC said.** The
`Terminating` action covers one stuck state and leaves every other one
reportable. The config switch covers them all, and the lock-ordering
deadlock goes out with the bathwater.

The third row is the long way round. With deadlock checking off, a
liveness property `DayEnds == <>(\A t \in ProcSet : pc[t] = Done)` under
`WF_vars(Work)` finds the same state as a stuttering counter-example, rc
13 instead of 11. Deadlock checking is a cheap stand-in for "eventually
everyone is done", and `CHECK_DEADLOCK FALSE` without a liveness property
in its place is the combination that hides things.

## What the translator does here, and why it matters now

PlusCal emits the `Terminating` disjunct for every algorithm with a
terminating process, silently, and the generated name is literally
`Terminating`. The disjunct is suppressible with the translator flag
`-noDoneDisjunct`, which is how you know it changes the model rather than
decorating it (coordinator's research round, relayed in the brief
correction, not a run of mine). A raw-TLA+ author makes that choice on
every spec, out loud. The choice is three-way, and this item measured all
three:

| treatment | agreed order | new hire |
|---|---|---|
| nothing | rc 11 on the intended end (`verify-all.sh` row `03-DayBare`) | rc 11 on the real deadlock (row `03-RookieBare`. The lock deadlock sits at depth 2 and the intended end at depth 6, and breadth-first search reports the shallower) |
| `Terminating` | rc 0 | rc 11 on the real deadlock |
| `CHECK_DEADLOCK FALSE` | rc 0 | rc 0 |

## Acceptable variants

- **Strings for labels.** Measured clean during authoring on a scratch
  probe of the same shape (rc 0). The translator's own choice.
- **`held \in [Techs -> SUBSET Tools]`** instead of `holder`. The guard
  becomes `\A u \in Techs : tool \notin held[u]`. Same verdicts.
- **A `Trans(t, from, to)` helper** for the `pc` guard and update, as in
  item 07. Same verdicts.
- **Fix the rookie** by giving everyone the same order. That is the
  lock-ordering fix and the right engineering answer, but it is not what
  the prompt asked. The prompt asked what TLC says about the rookie.
- **`Terminating` written as `pc = [t \in ProcSet |-> Done]`** instead of
  the quantifier. Equivalent.

## Elimination table

| neighbour answer | what kills it |
|---|---|
| `CHECK_DEADLOCK FALSE` offered as the only treatment | the new hire: rc 0 on a real deadlock, measured in `RookieNoDL.cfg`. |
| `Terminating` enabled whenever *anyone* is `Done` | not killed by the agreed order. On the new hire it still reports rc 11, because nobody is `Done` in the deadlocked state (INFERRED, not run). It is wrong for the other reason: a day on which `a` is done and `b` is stuck forever would be accepted. |
| a `Waiting` label the technician moves to when the tool is out | admits a step that changes nothing but `pc`. Not wrong, and the verdicts are the same, but it is the item 02 cost for no information: "waiting for the ladder" is `pc = Idle /\ holder[Ladder] /= Nobody`, already in the state. |
| `BothInHand` as `pc[t] = HasBoth => holder[Ladder] /= Nobody` | passes (INFERRED), and says nothing: the ladder could be in the other technician's hand. The rule is about *whose* hand. |

## why-not-in-prompt

The prompt shows no TLA+. Its caveats are two. "The first thing TLC says
will be about the end of the day" tells him there is an end-of-day
problem before he has run anything, and a reader who knows the word
deadlock will reach for a treatment before meeting the symptom. "Say which
of the ways of dealing with it you chose" says there is more than one,
which is a hint that the choice matters. Both are there because without
them a reader who writes `CHECK_DEADLOCK FALSE` by reflex gets rc 0 on
both halves and learns nothing. The last sentence, "whether the way you
dealt with the end of the day had anything to do with what it said", is
the lesson asked as a question, and it is asked after the second run, so
the answer is already on the screen when he reads it.

## Measured runs

Every row is a line of `drill/control-state/verify-all.sh`. One config per
module, run with one worker, no trace spillage. `DayBare`, `DayNoDL` and the
three `Rookie*` modules are one-line `EXTENDS` wrappers so that each config
has a module of its own.

| module | config | rc | distinct states |
|---|---|---|---|
| DayBare.tla | DayBare.cfg | rc 11 | 12 |
| DayNoDL.tla | DayNoDL.cfg | rc 0 | 12 |
| RookieBare.tla | RookieBare.cfg | rc 11 | 7 |
| RookieNoDL.tla | RookieNoDL.cfg | rc 0 | 13 |
| RookieLive.tla | RookieLive.cfg | rc 13 | 13 |
| NewHire.tla | NewHire.cfg | rc 11 | 7 |
| Agreed.tla | Agreed.cfg | rc 0 | 12 |
