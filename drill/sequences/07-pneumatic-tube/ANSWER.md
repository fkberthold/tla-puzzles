# Pneumatic tube: answer

## The answer

```tla
---- MODULE Tube ----
EXTENDS Naturals, Sequences

CONSTANT Capsules

VARIABLES tube, sent, received

vars == <<tube, sent, received>>

TypeOK ==
  /\ tube \in Seq(Capsules)
  /\ sent \in Seq(Capsules)
  /\ received \in Seq(Capsules)

Init ==
  /\ tube = <<>>
  /\ sent = <<>>
  /\ received = <<>>

Send(c) ==
  /\ tube' = Append(tube, c)
  /\ sent' = Append(sent, c)
  /\ UNCHANGED received

Receive ==
  /\ Len(tube) > 0
  /\ received' = Append(received, Head(tube))
  /\ tube' = Tail(tube)
  /\ UNCHANGED sent

Next == (\E c \in Capsules : Send(c)) \/ Receive

Spec == Init /\ [][Next]_vars

InOrder == received \o tube = sent

SentBound == Len(sent) <= 4
====
```

```
SPECIFICATION Spec
CONSTANT Capsules = {"red", "blue"}
INVARIANTS
  TypeOK
  InOrder
CONSTRAINT SentBound
```

The tube is a queue: in at the back with `Append`, out at the front with
`Head` and `Tail`. That part writes itself. The rule doesn't, because "in
the order they went in" is about capsules that have already left the tube,
and the tube forgets them. So two more lists record what went in and what
came out, and the rule is one equation. What came out, followed by what's
still inside, is what went in.

Three lists and nothing in the bank stops the teller, so the run is bounded
by a `CONSTRAINT` in the cfg. Bounding `sent` bounds the other two, since
each is a slice of it. A guard would have been a rule the bank doesn't
have.

## Acceptable variants

- `sent = received \o tube`. Same equation.
- Keep `sent` and a count of how many the vault has taken, and define the
  tube as the slice of `sent` past the count. The rule is then true by
  construction. Measured, same 129 states.
- A single history list with a marker index. Same thing as the previous
  one.
- `Capsules` as model values rather than strings. Same count.

## Wrong neighbors

| neighbor | module | killed by | rc |
|---|---|---|---|
| the clerk takes the capsule that went in last | `TubeLifo` | the rule, once two capsules share the tube | rc 12 |
| the teller puts capsules in at the clerk's end | `TubeSendFront` | the rule, on the second send | rc 12 |
| the rule written as a count, in plus inside equals out | `TubeCountOnly` | nothing. It holds for the stack as well as the queue | rc 0 |

The third row is why the prompt publishes a count. A count is the first
thing a reader adds, and it can't see order. That module is the stack's
`Receive` with a counting rule, and it passes, so the only thing that
tells a reader who wrote it that they're wrong is the 57 against 129.

## Measured

From `verify/`, through `harness/verdict.sh` the way `harness/drill-gate.sh`
runs it. TLC2 Version 2026.07.31.184830, `-workers 1`.

| module | what | rc | distinct states |
|---|---|---|---|
| `TubeRef` | the answer | rc 0 | 129 found |
| `TubeDerived` | history plus a count, tube as a slice | rc 0 | 129 found |
| `TubeLifo` | clerk takes the last in | rc 12 | 15 found |
| `TubeSendFront` | teller sends to the front | rc 12 | 5 found |
| `TubeCountOnly` | the stack with a counting rule | rc 0 | 57 found |

129 by hand: for n capsules sent there are 2^n histories and n + 1 places
the clerk can have got to. 1 + 4 + 12 + 32 + 80.

## Why not in prompt

Prose only, and the queue operators are absent from the page. So is the
idea of a history variable, which is the thing the item is about.

This section used to carry a caveat and the prompt has now answered it.
The prompt used to say "you'll have to add what it needs", which told the
reader outright that the state isn't enough. That was half the discovery.
I left it in because without it a reader writes the queue, finds no way
to state the rule, and has nothing to check.

The published 129 does that job without saying what's missing. A reader
who reaches for counters gets 57, and the gap tells them they're wrong
while leaving them to work out why. I still think the counting rule is
the trap most readers will walk into first. Now it costs them a wrong
count rather than a sentence in the prompt.
