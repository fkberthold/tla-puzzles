# R05: Review — Sequences in Pure TLA+ ⭐

## Lesson: Append and Concat, Without PlusCal

Tier 2's T10 and T11 introduced sequences: literal `<<a, b, c>>`, `Append(s, x)`, `s \o t` (concatenation), `Len(s)`, `Head(s)`, `Tail(s)`. They worked the same way then as they work now. The pivot: in pure TLA+ you write `s' = Append(s, x)` instead of PlusCal's `s := Append(s, x)`. Same idea, different syntax.

A few things to keep straight:

- `Sequences` must be in `EXTENDS` to use `Append`, `Len`, `Head`, `Tail`, `\o`, `SubSeq`.
- Sequences are **1-indexed**: `<<10, 20, 30>>[1] = 10`.
- `Append(s, x)` builds a new sequence with `x` at the end. It is a pure expression — it does not mutate `s`.
- `s \o t` concatenates two sequences. `<<1,2>> \o <<3,4>> = <<1,2,3,4>>`.
- `Head(<<1,2,3>>) = 1` and `Tail(<<1,2,3>>) = <<2,3>>`.

**Worked example — a chat log.**

A chat room collects every message ever posted into a single log. Two actions: a user can post a message (chosen nondeterministically from a constant set), or the moderator can prepend a system banner. The log starts empty.

```
---- MODULE Chat ----
EXTENDS Integers, Sequences

CONSTANT Messages
VARIABLE log

TypeOK == log \in Seq(Messages \cup {"BANNER"})

Init == log = <<>>

Post ==
  /\ \E m \in Messages : log' = Append(log, m)

Banner ==
  log' = <<"BANNER">> \o log

Next == Post \/ Banner

Spec == Init /\ [][Next]_log
====
```

Things to notice:

- `<<>>` is the empty sequence — that is what `log` is initialized to.
- `Post` uses `\E m \in Messages : ...` to nondeterministically pick which message gets appended. Each choice is a separate next-state; TLC explores all of them.
- `Banner` uses `\o` to put `"BANNER"` at the front of the existing log.
- `TypeOK == log \in Seq(S)` says "log is a finite sequence with elements drawn from `S`." `Seq(S)` is provided by the `Sequences` module.
- Without bounding the state space (e.g., a `CONSTANT MaxLen` and a guard), the log grows without bound and TLC will not terminate. Real specs always bound sequence length somehow — a constraint, a guard, or a small `CONSTANT`.

## Setup

A printer maintains a queue of jobs. Two actions:

- **Submit**: append a new job number to the queue.
- **Print**: remove the front job from the queue.

To keep the state space finite, jobs are numbered from a fixed pool `1..3`, and the same job number can only appear in the queue once at a time (so `Submit` is only enabled if the job number is not already queued).

## Task

Author `solution/PrintQueue.tla` as **pure TLA+**. It must contain:

- `EXTENDS Integers, Sequences`
- `VARIABLE queue`
- `Jobs == 1..3`
- `TypeOK == queue \in Seq(Jobs) /\ Len(queue) <= 3`
- `Init == queue = <<>>`
- `Submit ==` action: nondeterministically pick `j \in Jobs` such that `j` is not already in `queue` (use `\E j \in Jobs : ...` and a guard like `\A i \in 1..Len(queue) : queue[i] # j`); set `queue' = Append(queue, j)`.
- `Print ==` action: enabled when `Len(queue) > 0`; sets `queue' = Tail(queue)`.
- `Next == Submit \/ Print`
- `Spec == Init /\ [][Next]_queue`

Author `solution/PrintQueue.cfg` with `SPECIFICATION Spec` and `INVARIANT TypeOK`.

## Check

Run from `solution/`:

```bash
tlc PrintQueue
```

## Expected Result

- TLC reports **16 distinct states** — the empty queue, plus every permutation of subsets of `{1,2,3}` of length 1, 2, or 3 (1 + 3 + 6 + 6 = 16).
- `TypeOK` should pass.
- No deadlock — at any reachable state, either `Submit` (pool not full) or `Print` (queue non-empty) is enabled.

If you forget the "not already in queue" guard on `Submit`, the queue can grow past length 3 and `TypeOK` will fail. If you forget `Len(queue) > 0` on `Print`, TLC reports an evaluation error from `Tail(<<>>)`.
