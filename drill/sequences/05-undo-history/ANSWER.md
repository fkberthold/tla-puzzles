# Undo history: answer

## The answer

```tla
---- MODULE Undo ----
EXTENDS Naturals, Sequences

CONSTANT Edits

VARIABLE hist

vars == <<hist>>

TypeOK ==
  /\ hist \in Seq(Edits)
  /\ Len(hist) <= 3

Init == hist = <<>>

Edit(e) ==
  hist' = IF Len(hist) = 3 THEN Append(Tail(hist), e) ELSE Append(hist, e)

Undo ==
  /\ Len(hist) > 0
  /\ hist' = SubSeq(hist, 1, Len(hist) - 1)

Next == (\E e \in Edits : Edit(e)) \/ Undo

Spec == Init /\ [][Next]_vars
====
```

```
SPECIFICATION Spec
CONSTANT Edits = {"a", "b", "c", "d"}
INVARIANT TypeOK
```

Both ends of the list are in play, and the module gives you an operator
for only one of them. Edits join at the back, `Append`. When a fourth
arrives the oldest leaves from the front, `Tail`, and the new one still
joins at the back, so step 4 is `Append(Tail(hist), e)`. Undo takes from
the back, and there's no operator for that. It's a slice that stops one
short, `SubSeq(hist, 1, Len(hist) - 1)`.

The rule is the length bound, and it's the type invariant. `Seq(Edits)`
is infinite, so the bound is the part of `TypeOK` that makes the model
finite. Here it holds because of the drop at step 4, not because of a
constraint. Take the drop away and the bound is the first thing to fail.

## Acceptable variants

- `Edit` as two actions, one for room and one for full, with no
  conditional. Same states.
- Newest edit at the front. Edits join with `<<e>> \o hist`, the drop when
  full is `SubSeq(hist, 1, 2)` of the new list, and undo is `Tail`. A
  correct editor, measured at the same 85 states, and it doesn't admit the
  table, because the table says which end is which. The mirror image of a
  session isn't the session.
- The last element written as `hist[Len(hist)]` somewhere, for a rule
  about what undo removed. Not needed for the rule asked.

## Which row forecloses what

| row | kills | because |
|---|---|---|
| 4 | join at the back and never drop | the history would read a, b, c, d |
| 4 | refuse the fourth edit | there would be no step |
| 5 | undo as `Tail` | the history would read c, d |
| 2 | newest at the front | the history would read b, a |
| 6 | edits as unique ids, or a set | a came back, and order is kept |

The first three rows are measured below. Row 2 is measured against the
newest-first editor. Row 6 isn't measured against a module.

## Wrong neighbors

| neighbor | module | killed by | rc |
|---|---|---|---|
| undo as `Tail`, full model | `UndoTailPop` | nothing. The bound holds | rc 0 |
| undo as `Tail`, against the table | `UndoTailPopAdmits` | row 5 | rc 13 |
| join at the back and never drop | `UndoAppendOnly` | the bound, after four edits | rc 12 |
| refuse the fourth edit, full model | `UndoRefuseFull` | nothing. The bound holds | rc 0 |
| refuse the fourth edit, against the table | `UndoRefuseFullAdmits` | row 4 | rc 13 |
| newest first, full model | `UndoNewestFirst` | nothing. A correct editor | rc 0 |
| newest first, against the table | `UndoNewestFirstAdmits` | row 2 | rc 13 |
| newest first, with the drop as a slice of the first three whether or not there are three | `UndoMirror` | the first edit. `SubSeq` past the end is an error, not a truncation | rc 255 |
| the same, against the table | `UndoMirrorAdmits` | the first row, the same way | rc 255 |

The last pair wasn't planned. I wrote the newest-first editor with
`SubSeq(<<e>> \o hist, 1, 3)` and TLC refused it: "The third argument of
SubSeq must be in the domain of its first argument". A slice past the end
of a list doesn't give you the list. It gives you an exception, exit 255,
and I think that's worth more than the neighbor I meant to write.

## Measured

From `verify/`, through `harness/verdict.sh` the way `harness/drill-gate.sh`
runs it. TLC2 Version 2026.07.31.184830, `-workers 1`. The table lives in
`UndoRows.tla`, a helper with no cfg, and each `*Admits` module walks it.

| module | what | rc | distinct states |
|---|---|---|---|
| `UndoRef` | the answer, full model | rc 0 | 85 found |
| `UndoRefAdmits` | the answer against the table | rc 0 | 8 found |
| `UndoTailPop` | undo from the front, full model | rc 0 | 85 found |
| `UndoTailPopAdmits` | undo from the front against the table | rc 13 | 6 found |
| `UndoAppendOnly` | no drop when full | rc 12 | 86 found |
| `UndoRefuseFull` | fourth edit refused, full model | rc 0 | 85 found |
| `UndoRefuseFullAdmits` | fourth edit refused against the table | rc 13 | 5 found |
| `UndoNewestFirst` | newest first, full model | rc 0 | 85 found |
| `UndoNewestFirstAdmits` | newest first against the table | rc 13 | 3 found |
| `UndoMirror` | slice past the end | rc 255 | 1 found |
| `UndoMirrorAdmits` | slice past the end against the table | rc 255 | 2 found |

85 is the lists of up to three from four kinds, 1 + 4 + 16 + 64. The table
has nine rows and eight distinct states, since steps 5 and 7 are the same
history.

## Why not in prompt

Nine rows and two sentences. The prose doesn't say what undo does or what
happens when the history is full. Rows 4 and 5 say it, and the reader has
to read it off them. No operator is on the page.

The caveat: "undo" is a word every engineer already has semantics for, so
row 5 confirms more than it teaches. Row 4 is doing the real work, since
"the oldest is dropped" is a design choice the reader can't know until
they see it. The table also fixes which end is which, so the newest-first
editor, which is a fine spec, fails the item. The answer says so rather
than pretending the choice was forced by the drawing program.
