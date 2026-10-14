# Window display: answer

## The answer

```tla
---- MODULE CanPyramid ----
EXTENDS Naturals

CONSTANTS Width, MaxRows

VARIABLES style, rows, cans

vars == <<style, rows, cans>>

RECURSIVE Total(_, _)
Total(RowCount(_), n) ==
  IF n = 0 THEN 0 ELSE RowCount(n) + Total(RowCount, n - 1)

RowCount(k) == IF style = "pyramid" THEN k ELSE Width

TypeOK ==
  /\ style \in {"pyramid", "wall"}
  /\ rows \in 0..MaxRows
  /\ cans \in Nat

Init ==
  /\ style \in {"pyramid", "wall"}
  /\ rows = 0
  /\ cans = 0

AddRow ==
  /\ rows < MaxRows
  /\ rows' = rows + 1
  /\ cans' = cans + RowCount(rows + 1)
  /\ UNCHANGED style

RemoveRow ==
  /\ rows > 0
  /\ rows' = rows - 1
  /\ cans' = cans - RowCount(rows)
  /\ UNCHANGED style

Next == AddRow \/ RemoveRow

Spec == Init /\ [][Next]_vars

CansMatchRule ==
  cans = IF style = "pyramid" THEN Total(LAMBDA k : k, rows)
                              ELSE Total(LAMBDA k : Width, rows)
====
```

```
SPECIFICATION Spec
CONSTANTS
  Width = 3
  MaxRows = 4
INVARIANTS
  TypeOK
  CansMatchRule
```

`Total` is recursive, so it's declared with `RECURSIVE` before its definition.
The declaration gives the arity only, `Total(_, _)`. The operator-valued
parameter, `RowCount(_)`, goes on the definition line. TLC accepts the pair: a
probe module with `ASSUME Total(LAMBDA k : k, 4) = 10` and `ASSUME Total(LAMBDA
k : 3, 4) = 12` ran clean. The invariant hands `Total` a `LAMBDA` for each
style.

`RowCount(k)` in the actions reads `style`, which is state, and that's fine. An
operator can mention a variable.

## Measurements

From `verify/`, `tlc -workers 1 -noGenerateSpecTE -metadir states/<name>
<Module>.tla -config <Module>.cfg`.

| module | what | rc | generated | distinct | TLC says |
|---|---|---|---|---|---|
| `CanPyramid` | reference | rc 0 | 18 | 10 | no error |
| `RemoveOffByOne` | `RemoveRow` subtracts the row below | rc 12 | 6 | 6 | `Invariant CansMatchRule is violated.` |
| `ClosedForms` | the closed forms in place of the recursion | rc 0 | 18 | 10 | no error |

Two styles times five heights is 10, and the count is a function of the two,
so that's all of them.

The third row is the acceptable variant that defeats the item.
`(rows * (rows + 1)) \div 2` and `Width * rows` are the closed forms, and they
pass identically. A reader who reaches for them has done the maths and none of
the three constructs.

## Acceptable variants

- The closed forms. Passes. Exercises nothing this item is for.
- A first-order `RECURSIVE Pyramid(_)` and `RECURSIVE Wall(_)`, one per style.
- `Total` as a recursive function `f[n \in 0..MaxRows]`. One per style, since a function can't take an operator.
- The `LAMBDA`s as named operators `PyramidRow(k) == k` and `WallRow(k) == Width`, passed by name.

The second misses the brief rather than the check, since the prompt asked for
one definition. The fourth is the same thing as the answer with two more
definitions, and if the names help the reader I'd take it.

## Wrong neighbors

| neighbor | what kills it |
|---|---|
| `RemoveRow` subtracting the row below | `CansMatchRule` red, six states in |
| `Total` defined without the `RECURSIVE` line | `Total` isn't in scope inside its own body. Parse error, rc 150 (not measured) |
| the `n = 0` base case missing | the recursion never bottoms out. I'd expect a stack overflow at rc 255 (not measured) |
| `LAMBDA k : k` passed to a first-order parameter | arity mismatch, parse error, rc 150 (not measured) |

## Why not in prompt

"One definition that serves both styles, given a style's rule for a row" is
the nudge toward a higher-order parameter, and it's a design requirement rather
than code. The honest caveat is twofold. The closed forms pass, so the
recursion is forced by the sentence and not by the check. And a reader who has
never seen `RECURSIVE` can't retrieve it from a blank page, because nothing in
the domain says "declare before define". That's a construct this item can only
teach by its answer, and I'd rank it low on retrieval for that reason.
