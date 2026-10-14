# Dispatch board: answer

## The answer

```tla
---- MODULE Dispatch ----
EXTENDS Naturals, Sequences

CONSTANT Districts

VARIABLES calls, closed

vars == <<calls, closed>>

TypeOK ==
  /\ calls \in Seq(Districts)
  /\ Len(calls) <= 3
  /\ closed \subseteq Districts

Init ==
  /\ calls = <<>>
  /\ closed = {}

Call(d) ==
  /\ d \notin closed
  /\ Len(calls) < 3
  /\ calls' = Append(calls, d)
  /\ UNCHANGED closed

Close(d) ==
  /\ d \notin closed
  /\ closed' = closed \cup {d}
  /\ calls' = SelectSeq(calls, LAMBDA c : c /= d)

Reopen(d) ==
  /\ d \in closed
  /\ closed' = closed \ {d}
  /\ UNCHANGED calls

Next == \E d \in Districts : Call(d) \/ Close(d) \/ Reopen(d)

Spec == Init /\ [][Next]_vars

NoClosedCalls == \A i \in DOMAIN calls : calls[i] \notin closed
====
```

```
SPECIFICATION Spec
CONSTANT Districts = {"north", "south", "east"}
INVARIANTS
  TypeOK
  NoClosedCalls
```

"Every call from that district, at once, the rest keep their order" is a
filter, and `SelectSeq` is the one operator in the module that reaches
into the middle of a list without an index. It takes the list and a test,
and keeps every element the test passes. So the test is "not from `d`",
written as a `LAMBDA` in place. Reverse the test and you keep the calls
you meant to strike, which is the second wrong neighbor below.

The rule is a membership check at every index. There's no "contains" for
lists, so the quantifier over `DOMAIN calls` is how you say it.

The board has three lines, so a guard bounds the list. The closed set is
a subset of three districts and bounds itself.

## Acceptable variants

- The filter written by hand as a recursive operator over `Head` and
  `Tail`. Measured, same 98 states, more lines. It's what you write when
  you've forgotten the module has a filter.
- The test as `c \notin {d}`. Same.
- `Close` without the `d \notin closed` guard. Closing twice is then a
  self-loop that changes nothing. I expect the same 98 states. Not
  measured.
- `Reopen` dropped. The model then runs down to all districts closed and
  stops, which wants `CHECK_DEADLOCK FALSE` or a guard. Fewer states.

## Wrong neighbors

| neighbor | module | killed by | rc |
|---|---|---|---|
| strike the first call from the district and leave the rest | `DispatchFirstOnly` | the rule, with two calls from one district on the board when it closes | rc 12 |
| the test the wrong way round, keeping the district's calls | `DispatchKeeps` | the rule, on the first closure with any other call on the board | rc 12 |

The first row is the natural slip for a reader who has item 1 of this
family in their hands: find the index, cut around it. One index is one
call, and a closure is every call.

## Measured

From `verify/`, through `harness/verdict.sh` the way `harness/drill-gate.sh`
runs it. TLC2 Version 2026.07.31.184830, `-workers 1`.

| module | what | rc | distinct states |
|---|---|---|---|
| `DispatchRef` | the answer | rc 0 | 98 found |
| `DispatchRecursive` | the filter by recursion | rc 0 | 98 found |
| `DispatchFirstOnly` | one call struck per closure | rc 12 | 27 found |
| `DispatchKeeps` | the test reversed | rc 12 | 9 found |

98 by hand. No district closed: boards of up to three from three, 40. One
closed: boards from the other two, 15, times three choices, 45. Two closed:
boards from one district, 4, times three, 12. All closed: the empty board,
1.

## Why not in prompt

Prose only. The filter operator and the fact that it takes an operator as
an argument are both absent from the page. The reader has to know, or find,
that the module has one, and then that the test goes in as a `LAMBDA`.

The caveat: "every call from that district at once" is close to a
definition of a filter, and a reader who has written one in any language
will reach for it by reflex. What the prompt doesn't hand over is the
direction of the test, and I think that's the slip most worth drilling
here. The item also leans on the reader not having a filter operator in
their head at all, which is the inventory's own finding about this family.
