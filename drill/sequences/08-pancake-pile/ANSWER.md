# Pancake pile: answer

## The answer

```tla
---- MODULE Pancakes ----
EXTENDS Naturals, Sequences

CONSTANT N

VARIABLE pile

vars == <<pile>>

Flip(s, k) == [i \in 1..Len(s) |-> IF i <= k THEN s[k + 1 - i] ELSE s[i]]

SamePancakes ==
  /\ Len(pile) = N
  /\ \A s \in 1..N : \E i \in DOMAIN pile : pile[i] = s

TypeOK ==
  /\ pile \in Seq(1..N)
  /\ Len(pile) = N

Init ==
  /\ pile \in [1..N -> 1..N]
  /\ SamePancakes

Turn == \E k \in 2..N : pile' = Flip(pile, k)

Next == Turn

Spec == Init /\ [][Next]_vars
====
```

```
SPECIFICATION Spec
CONSTANT N = 4
INVARIANTS
  TypeOK
  SamePancakes
```

Nothing in the module reverses a list. There's no operator for it, and the
ones there are take from an end or slice. So the flip is built rather than
called. A list is a function on `1..n`, and a function literal over
`1..Len(s)` is a list. Inside the flipped part, position `i` takes what was
at `k + 1 - i`. Outside it, position `i` keeps what it had.

`Init` uses the same fact from the other side. The arrangements of four
pancakes are the functions from `1..N` to `1..N` that hit every size once,
and `[1..N -> 1..N]` is a set TLC can enumerate. The rule then holds in
every initial state by construction and the flips have to keep it.

The mirror index is where the item bites. `k + 1 - i` runs from `k` down to
`1`. Write `k - i` and at `i = k` you ask for index 0, which no list has.
That's the first wrong neighbour, and TLC's message for it is the 1-based
origin stated plainly.

## Acceptable variants

- Reverse the top `k` by recursion over `Head` and `Tail`, then join the
  rest back on with `\o`. Measured, same 24 states.
- The flipped part as a function literal over `1..k` and the rest as a
  slice, joined with `\o`. Half and half.
- `Turn` over `1..N`. A flip of one pancake is a self-loop that changes
  nothing. Same states.
- `Init` as one fixed pile. Six states for three pancakes, 24 for four,
  since the flips reach every arrangement either way. I expect that and
  haven't measured it.

## Which row forecloses what

| row | kills | because |
|---|---|---|
| 1 | turning the whole pile over on every move | only the top two changed |
| 2 | "only the top two" | three changed and the bottom one stayed |
| 3 | any flip that leaves the bottom alone | all four moved |

Row 1 is measured against the whole-pile neighbour below. The other two
rows are read off the table and not measured against a module.

## Wrong neighbours

| neighbour | module | killed by | rc |
|---|---|---|---|
| the mirror index as `k - i` | `PileOffByOne` | the first flip, which asks for index 0 | rc 75 |
| every move turns the whole pile | `PileWhole` | nothing in the rule. The pancakes are still the same four | rc 0 |
| the whole-pile move, against the table | `PileWholeAdmits` | row 1 | rc 13 |

The off-by-one is reported by TLC as "Attempted to apply function ... to
argument 0, which is not in the domain of the function". The 24 states it
reports are the 24 initial arrangements, enumerated before the first flip
was tried.

## Measured

From `verify/`, through `harness/verdict.sh` the way `harness/drill-gate.sh`
runs it. TLC2 Version 2026.07.31.184830, `-workers 1`. The table lives in
`PileRows.tla`, a helper with no cfg, and each `*Admits` module walks it.

| module | what | rc | distinct states |
|---|---|---|---|
| `PileRef` | the answer | rc 0 | 24 found |
| `PileRefAdmits` | the answer against the table | rc 0 | 5 found |
| `PileRecursive` | the flip by recursion | rc 0 | 24 found |
| `PileOffByOne` | mirror index one short | rc 75 | 24 found |
| `PileWhole` | every move flips the whole pile | rc 0 | 24 found |
| `PileWholeAdmits` | whole-pile move against the table | rc 13 | 2 found |

24 is the arrangements of four pancakes, and every one is initial.

## Why not in prompt

Four rows and a paragraph. No operator, and no hint that the module lacks
one. The reader has to look for a reverse, fail to find it, and then
remember that a list is a function and build one.

The caveat: "say how you built the flip" tells the reader it was built,
which hints that it couldn't be called. I kept it because without it a
reader who knows the community module's `Reverse` will use it and never
meet the point. The flip is still theirs to build. The table hands over
the semantics in full, so this item drills the form, which the trial
flagged as the cost of a table. For this operator I think the form is the
whole of the difficulty.
