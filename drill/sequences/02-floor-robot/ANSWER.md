# Floor robot: answer

## The answer

```tla
---- MODULE Robot ----
EXTENDS Naturals, Sequences

Tiles == (1..3) \X (1..3)

VARIABLE path

vars == <<path>>

Here == path[Len(path)]

Adjacent(a, b) ==
  \/ a[1] = b[1] /\ (a[2] = b[2] + 1 \/ b[2] = a[2] + 1)
  \/ a[2] = b[2] /\ (a[1] = b[1] + 1 \/ b[1] = a[1] + 1)

Visited(t) == \E i \in DOMAIN path : path[i] = t

TypeOK ==
  /\ path \in Seq(Tiles)
  /\ Len(path) \in 1..9

Init == \E t \in Tiles : path = <<t>>

Step == \E t \in Tiles :
  /\ Adjacent(Here, t)
  /\ ~Visited(t)
  /\ path' = Append(path, t)

Lift == \E t \in Tiles : path' = <<t>>

Next == Step \/ Lift

Spec == Init /\ [][Next]_vars

NeighborsOnly == \A i \in 1..(Len(path) - 1) : Adjacent(path[i], path[i + 1])

NoTileTwice == \A i, j \in DOMAIN path : i /= j => path[i] /= path[j]
====
```

```
SPECIFICATION Spec
INVARIANTS
  TypeOK
  NeighborsOnly
  NoTileTwice
```

A tile is a pair and the record is a list of pairs, so `path[i]` is a pair
and `path[i][1]` is its row. That's the point of the item. A pair is a
sequence of length two, and the same square brackets take apart both.
`<<2, 3>>` is a member of `(1..3) \X (1..3)`, and it's also a member of
`Seq(1..3)` with `Len` 2, and TLC doesn't tell the two apart.

The robot is wherever the record ends, so there's no second variable for
its position. `Here` is `path[Len(path)]`, the last index, which is the one
place a 1-based list differs from what a programmer's hand types.

`NeighborsOnly` runs `i` from 1 to one short of the end, because it looks
at `path[i + 1]`. Run it over the whole domain and the last index asks for
an element that isn't there. That's the first wrong neighbor below, and
it isn't a violated invariant. It's an invariant TLC couldn't evaluate.

The no-revisit guard is what bounds the model. Without it the record would
grow for ever. This item has no constraint because the floor supplies one:
nine tiles, so a record of at most nine.

## Acceptable variants

- Tiles as records, `[row : 1..3, col : 1..3]`, taken apart with `.row`
  and `.col`. Nothing about the list changes. Measured, same 653 states.
- A separate `pos` variable kept equal to the record's last element. More
  state to keep in step, same reachable positions.
- `Adjacent` as a squared distance equal to 1, with `Integers` in place of
  `Naturals` since the differences go negative.
- `Visited(t)` as `t \in {path[i] : i \in DOMAIN path}`. A set built from
  the list, then membership.
- `Lift` restricted to one home tile, or dropped. Fewer states, same rules.

## Wrong neighbors

| neighbor | module | killed by | rc |
|---|---|---|---|
| the adjacency rule quantified over the whole domain | `RobotDomainEdge` | the first state, where the rule asks for index 2 of a one-element record | rc 75 |
| the move checked against the first tile in the record, not the last | `RobotFromStart` | the adjacency rule, on the second move | rc 12 |

The first row is the 1-based lesson in TLC's own words: "Attempted to
access index 2 of tuple". `harness/verdict.sh` lists 76 for an invariant
that can't be evaluated. Measured, this one exits 75, and I think the
reason is that the failure lands while TLC is computing the initial
states, a path that wraps every evaluation error as 75. The table's own
note on an `Assert` in `Init` predicts the same split.

## Measured

From `verify/`, through `harness/verdict.sh` the way `harness/drill-gate.sh`
runs it. TLC2 Version 2026.07.31.184830, `-workers 1`.

| module | what | rc | distinct states |
|---|---|---|---|
| `RobotRef` | the answer | rc 0 | 653 found |
| `RobotRecord` | tiles as records | rc 0 | 653 found |
| `RobotDomainEdge` | the rule over the whole domain | rc 75 | 1 found |
| `RobotFromStart` | moves checked from the start tile | rc 12 | 34 found |

653 is the number of self-avoiding walks of one to nine tiles on a three by
three grid, counted from every starting tile. I didn't count it by hand.
Both encodings agree, which is the check that the pair and the record are
the same model.

## Why not in prompt

Prose only. The reader has to decide that a tile is a pair, that the record
is a list of pairs, and that the robot's position is the last element
rather than a variable of its own. The two rules are in English and the
reader has to find the index arithmetic.

The caveat: "in order" and "that one tile" push toward a list, and "three
rows of three" pushes toward a pair, so the shape is nudged. What isn't
nudged is the off-by-one at the end of the adjacency rule, and that's
where I think the item earns its place. A reader who has met grid walks
before will write the pair without thinking, which is domain smell the gate
can't see.
