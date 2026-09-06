# What these models chose

You've written your own model of the lease problem by now. This note reads the
decisions the spike's models made that the statement doesn't force. If yours
differs on any of these, that's a different model and not a wrong one. Nothing
below is a grade.

Every state count here comes from one command, run from the repository root on
2026-09-06:

```
bash harness/spike-measure.sh --dir sources/spikes/fencing --module <M> --budget 120 --label verify-<M>
```

## How time is represented

This is the decision the problem turns on, and the spike built it both ways
rather than arguing about it.

The clocked pair carries `clock` as a bounded counter, a tick action guarded by
`clock < MaxTime` (`Broken.tla:80-83`), and a lock service that stores its
deadline as an absolute clock value (`Broken.tla:67`). A lease is live while
`clock < expiry` (`Broken.tla:106`).

The clockless pair deletes all of it. No clock, no deadline, no `MaxTime`, no
`Lease`. Expiry is one action that clears the holder and says nothing about when
(`BrokenAbstract.tla:58-61`).

| model | broken states | fenced states |
|---|---|---|
| bounded clock, `MaxTime = 3` | 62 | 74 |
| no clock | 21 | 29 |

Both find the bug. Both clear the fenced system. The verify runs above returned
rc 12 for `Broken` and `BrokenAbstract`, rc 0 for `Fenced` and `FencedAbstract`.
So the clock costs about 2.9x on the broken side and 2.6x on the fenced side,
and the multiplier grows with the bound.

| `MaxTime` | fenced states |
|---|---|
| 3 | 74 |
| 6 | 269 |
| 12 | 1,037 |
| 24 | 4,085 |
| 48 | 16,229 |

Those rows are `fenced-clock-2c-t6` through `t48` in `measurements.tsv`.
Doubling the bound roughly quadruples the space, because `clock` and `expiry`
are each bounded by `MaxTime` and they multiply.

Neither is the right answer. The safety question asks about the order of expiry
against the client's progress. It never asks how long either took, so the
arithmetic buys nothing here. What brings a clock back is a requirement with a
number in it, like a bound on how long a client may be locked out. If you built
the clock, you now have something you can delete and watch the answer stay the
same. I think that's worth more than never having written one.

## What got folded, and what got split

Three things sit inside one action that a different model could split:

**The ask and the grant.** `Acquire` is one step (`Broken.tla:63-71`). There's
no state where a client has asked and hasn't been answered, so no request can be
in flight or lost.

**The write and the storage service accepting it.** `Write` changes the client's
state and the log together (`Broken.tla:74-78`). No network, no delivery, no
reordering between the two components.

**The number and the grant.** A token is handed out inside the same step that
sets the holder (`Broken.tla:68-69`).

Two things are split that could have been folded:

**Getting the lease and writing.** These are separate actions, and the gap
between them is where the bug lives.

**Accepting and rejecting.** The fenced model gives rejection its own action
(`Fenced.tla:59`, `:67`) rather than one action with a conditional body.

And one thing isn't modelled at all. There's no action for the client pausing.
A client sitting in `"held"` while the clock ticks is a paused client, and the
interleaving comes for free.

## Each client asks once and writes once

`pc` runs one way, from `"idle"` to `"held"` to `"done"` (`Broken.tla:46`).
Across all five specification modules the string `"idle"` appears only in the
type invariant, the initial state, and the guard on acquiring. No action sends a
client back.

Rule 1 says any client can ask for the lease at any time, and doesn't say a
client stops after one grant. This is a bounding decision, and it's load
bearing: it's what makes the token space finite without a separate constant
(`Broken.tla:27-28`, `:45`). A model where clients loop needs its own bound on
the counter.

## Version one already carries the number

The statement introduces numbers at rule 7. `Broken.tla` has `nextTok` and `tok`
from the start (`:34`, `:36`, `:68-69`), before anything reads them.

That's there so the requirement can be stated. Staleness is "this write landed
behind one from a later grant", and without a per-grant number there's nothing in
version one to say that over. If your version-one model has no numbers in it,
you needed some other observable, and a history variable is the usual answer.
`FencedRestart.tla:20-27` reaches for exactly that once the token stops being
usable.

## The storage service is a log

Rule 6 says the storage service accepts every write, and no rule says what a
write contains. The models make it a sequence of the accepted tokens
(`Broken.tla:37`, `:76`). No values, no data, nothing overwritten.

The log is an observation rather than a component. Which write landed behind
which isn't anywhere else in the state, so without it the requirement has nothing
to look at.

## Rejection is something the client sees

Rule 10 says the storage service rejects a write. Nothing says the client is
told. `Fenced.tla` gives the client a fourth state, `"failed"`, reached by an
action of its own (`:31`, `:67-71`).

The module's comment justifies it as deadlock avoidance (`Fenced.tla:11-14`).
That reason is weaker than it looks, because both configs turn deadlock checking
off anyway (`Fenced.cfg:9`). So I read it as a choice about what the model shows,
not a repair. A model where a rejected client simply stops is admissible and
smaller.

## The client's progress is a variable, not a consequence

"This client has a grant and hasn't written yet" lives in `pc`
(`Broken.tla:35`, `:46`), and it isn't derived from the lock service.

It can't be. Once a second client acquires, `owner` and `expiry` carry nothing
at all about the first one (`Broken.tla:66-67`), and that client is exactly the
one about to do the damage. A model that reads client progress off the lock
service loses the state the failure lives in.

## What the type invariant commits to

| commitment | site | what it rests on |
|---|---|---|
| tokens range over `1..Cardinality(Clients)` | `Broken.tla:28`, `:47` | each client gets at most one grant |
| a deadline may exceed the clock bound | `Broken.tla:44` | a late grant outlives the model |
| the log is typed by quantifying over its indices | `Broken.tla:48` | the set of all sequences is infinite |

The middle row has a consequence worth seeing. At `MaxTime = 3` and `Lease = 2`
a lease granted at clock 2 gets a deadline of 4, so it never expires inside the
model at all (`Broken.cfg:5-6`).

## How many clients

Rule 1 says more than one and doesn't fix a number, and neither do the models.
Two is the primary size (`Broken.cfg:3`). The same modules run at three, four
and five through wrapper configs. Three clients cost 171 and 684 states on the
clocked pair. Four and five cost 2,777 and 41,021 on the clockless one
(`measurements.tsv`, rows `broken-clock-3c-t5` through `fenced-abstract-5c`).

The token bound is derived from the client set rather than declared
(`Broken.tla:28`), so the size is a config change and not a model change. That's
a small decision and it's the reason scaling costs nothing here.
