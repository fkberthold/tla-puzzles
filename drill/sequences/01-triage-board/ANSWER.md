# Triage board: answer

## The answer

```tla
---- MODULE Triage ----
EXTENDS Naturals, Sequences

CONSTANT Severities

VARIABLES board, treated

vars == <<board, treated>>

TypeOK ==
  /\ board \in Seq(Severities)
  /\ treated \in Seq(Severities)
  /\ Len(board) <= 3

Init ==
  /\ board = <<>>
  /\ treated = <<>>

Arrive(s) ==
  /\ Len(board) < 3
  /\ board' = Append(board, s)
  /\ UNCHANGED treated

Take ==
  /\ Len(board) > 0
  /\ LET i == CHOOSE i \in DOMAIN board :
                \A j \in DOMAIN board : board[i] <= board[j]
     IN /\ board' = SubSeq(board, 1, i - 1) \o SubSeq(board, i + 1, Len(board))
        /\ treated' = Append(treated, board[i])

Next == (\E s \in Severities : Arrive(s)) \/ Take

Spec == Init /\ [][Next]_vars

MostUrgentFirst ==
  [][Len(treated') = Len(treated) + 1 =>
       \A i \in DOMAIN board : treated'[Len(treated')] <= board[i]]_vars

TreatedBound == Len(treated) <= 3
====
```

```
SPECIFICATION Spec
CONSTANT Severities = {1, 2, 3, 4}
INVARIANT TypeOK
PROPERTY MostUrgentFirst
CONSTRAINT TreatedBound
CHECK_DEADLOCK FALSE
```

The table makes you do two things, and neither one is a queue operation.

The 1 in step 4 came out of the middle. So `Take` has to find an index and
cut the board around it: everything before `i`, joined to everything after
`i`. `SubSeq` is inclusive at both ends and 1-based, so the two slices are
`1..i-1` and `i+1..Len`. An empty slice at either end is `<<>>`, which `\o`
takes without complaint.

The rule is about a step, not a state. "Nobody is taken while someone more
urgent waits" compares what came off the board with what was on it, and
after the step the board no longer shows what was on it. So it's a boxed
action formula. Whenever the treated list grows by one, its new last element
is no larger than anything that was on the board before the step.

The treated list grows for ever and nothing in the clinic stops it, so the
run is bounded by a `CONSTRAINT` in the cfg rather than by a guard. The
board is bounded by a guard, because room for three is a rule of the
clinic.

## Acceptable variants

- `Take` with `\E i \in DOMAIN board : (\A j \in DOMAIN board : board[i] <= board[j]) /\ ...`
  in place of `CHOOSE`. Nondeterministic over tied indices. Same 7225 states.
- The cut as a function literal, `[k \in 1..(Len(board) - 1) |-> IF k < i THEN board[k] ELSE board[k + 1]]`.
  A list is a function on `1..n`, so this builds one directly.
- A `Min(s)` helper, `CHOOSE m \in {s[i] : i \in DOMAIN s} : \A j \in DOMAIN s : m <= s[j]`,
  then any index holding that value. Two steps where the answer takes one.
- The rule with the quantifier outside, `\A i \in DOMAIN board : Len(treated') > Len(treated) => ...`.
  Same formula.

## Which row forecloses what

| row | kills | because |
|---|---|---|
| 4 | the queue, front first | 3 was at the front and 1 came off |
| 4 | the stack, back first | 4 was at the back and 1 came off |
| 7 | positional guesses such as "always the second" | two on the board and the first came off |
| 9 | a filter that strikes every patient at the minimum | two at 4, one came off, one stayed |

Row 9 is the one that matters most. Without it, a filter that drops every
element equal to the minimum fits every other row, and it fits the rule
too. A filter removes every match, and a board can carry two patients at
the same severity.

## Wrong neighbours

| neighbour | module | killed by | rc |
|---|---|---|---|
| the queue, front first | `TriageFifo` | the rule, on the first board holding two patients | rc 13 |
| the queue, against the table | `TriageFifoAdmits` | row 4 | rc 13 |
| the filter, every patient at the minimum | `TriageSelect` | nothing. The rule holds, since the one taken was the most urgent | rc 0 |
| the filter, against the table | `TriageSelectAdmits` | row 9 | rc 13 |

## Measured

From `verify/`, through `harness/verdict.sh` the way `harness/drill-gate.sh`
runs it. TLC2 Version 2026.07.31.184830, `-workers 1`. The table lives in
`TriageRows.tla`, a helper with no cfg. Each `*Admits` module walks it and
asks whether every step is a step of the module it extends.

| module | what | rc | distinct states |
|---|---|---|---|
| `TriageRef` | the answer, full model | rc 0 | 7225 found |
| `TriageRefAdmits` | the answer against the table | rc 0 | 10 found |
| `TriageFifo` | queue, full model | rc 13 | 50 found |
| `TriageFifoAdmits` | queue against the table | rc 13 | 5 found |
| `TriageSelect` | filter, full model | rc 0 | 7225 found |
| `TriageSelectAdmits` | filter against the table | rc 13 | 10 found |

7225 is 85 times 85. A board of up to three from four severities is
1 + 4 + 16 + 64 = 85 values, the treated list under the constraint is the
same, and every pair is reachable. A boxed action property that fails exits
13 whatever the trace looks like, because TLC checks it through the
implied-action channel (`harness/verdict.sh:81-91`).

## Why not in prompt

Nine rows and a paragraph, no operator. The reader has to retrieve that a
board is a list, that the middle of a list is reached by an index, and that
cutting around an index is two slices joined. None of that is on the page.

The caveats. "1 is the most urgent" plus the table together say "minimum",
so the rule itself isn't much of a puzzle. What the table adds is that it
has to be a minimum over the whole board, not the front. The ask for "the
rule as something TLC can check" gives away that there is one, though not
that it's an action property rather than an invariant. A reader who reaches
for an invariant will find there is nothing in a single state to compare,
and I think that discovery is most of the item. This is also the one in the
family most likely to run past ten minutes, because the property is a
second blank page.
