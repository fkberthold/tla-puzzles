# The tool crib: answer

## The answer

```tla
---- MODULE ToolCrib ----
EXTENDS Naturals, FiniteSets, TLC
CONSTANTS Tools, Workers, Limit

VARIABLE out
vars == <<out>>

TypeOK == /\ DOMAIN out \subseteq Tools
          /\ \A t \in DOMAIN out : out[t] \in Workers

Holding(w) == {t \in DOMAIN out : out[t] = w}

Init == out = [t \in {} |-> 0]

SignOut(t, w) == /\ t \notin DOMAIN out
                 /\ Cardinality(Holding(w)) < Limit
                 /\ out' = out @@ (t :> w)

Return(t) == /\ t \in DOMAIN out
             /\ out' = [u \in (DOMAIN out) \ {t} |-> out[u]]

Next == \/ \E t \in Tools, w \in Workers : SignOut(t, w)
        \/ \E t \in Tools : Return(t)

Spec == Init /\ [][Next]_vars

WithinLimit == \A w \in Workers : Cardinality(Holding(w)) <= Limit
====
```

```
SPECIFICATION Spec
INVARIANTS TypeOK WithinLimit
CHECK_DEADLOCK TRUE
CONSTANTS
  Tools = {saw, drill, plane, rasp}
  Workers = {w1, w2}
  Limit = 2
```

`out` is a partial function. Its domain is the set of tools that are out
and nothing else, so the domain moves. Signing out adds a key by merging a
one-key function in. Returning rebuilds the function over the old domain
less the key, because nothing removes a key in place: an update with a
bang can change the value at a key that's there and can't take the key
away.

`TypeOK` takes two lines. `[Tools -> Workers]` holds total functions only,
and the empty function isn't one of them. The one-line form is
`out \in UNION {[D -> Workers] : D \in SUBSET Tools}`, the set of all
partial functions, which I didn't measure.

Hand count. Each tool is on the shelf or with one of two workers, 81 ways.
A worker with three or more tools: 9 ways each, 18. 63, and TLC found 63.

The closing question. The set of tools that are out is `DOMAIN out`. When a
tool comes back that set shrinks, and the function is rebuilt without the
key.

## Three layouts, 63 each

`ToolCribTotal` keeps a total function with a hole value. Every tool always
has an entry, `InCrib` when it's on the shelf, so the domain never moves
and every update is an in-place one with a bang. The set of tools that are
out is `{t \in Tools : out[t] /= InCrib}`, and when a tool comes back
nothing happens to that set's shape. One value changes. rc 0 at 63.

`ToolCribByWorker` records the crib from the worker's side, each worker to
the set of tools they hold. The limit is a size, which is easy. "A tool is
with one worker" was free on the tool's side and is an obligation here,
`OneHolder`. rc 0 at 63.

`ToolCribEmptyTuple` is the reference with `Init == out = <<>>`. A tuple is
a function on `1..n`, so the empty tuple is the function with no domain,
which is the same value the constructor over the empty set builds. rc 0 at
63.

| layout | module | the set of tools out | on return | rc | states |
|---|---|---|---|---|---|
| partial function | `ToolCrib` | its domain | the domain shrinks | rc 0 | 63 |
| total function, hole value | `ToolCribTotal` | a filter on the range | one value changes | rc 0 | 63 |
| worker to set of tools | `ToolCribByWorker` | the union of the sets | one set shrinks | rc 0 | 63 |

## The merge has one rule, and the guard is what makes it not matter

The merge keeps the left value on a shared key. With `t \notin DOMAIN out`
in `SignOut`, there's never a shared key, and the two orders are the same
function. Drop the guard and they aren't, and neither order is caught.

`ToolCribReissueOldWins` writes `out @@ (t :> w)` with no guard. Signing
out a tool that's already out leaves `out` as it was. A no-op, rc 0, 63.

`ToolCribReissueNewWins` writes `(t :> w) @@ out` with no guard. A tool
that's out moves to `w` without ever coming back. rc 0, 63.

Both clean, both at the reference's count, because every state either
reaches was reachable by a return and a fresh sign-out. No invariant on
this state can tell them from the reference. An action property could, and
this item doesn't carry one. I think that's the honest limit of the drill:
a wrong merge direction is invisible to a state invariant when the guard is
missing, and the guard is the fix in both cases.

## The neighbours

`ToolCribNoLimit` drops the count from `SignOut`. rc 12 on `WithinLimit`,
34 states.

`ToolCribWrongType` writes `TypeOK == out \in [Tools -> Workers]`, the total
type on a partial variable. rc 12 on the initial state, since the empty
function isn't in that set. TLC prints no state count when the first state
fails.

`ToolCribNoTLC` is the reference without `EXTENDS TLC`. The merge and the
one-key constructor both come from that module, and without it neither
parses. rc 150, two errors.

## Acceptable variants

- Any of the three layouts above.
- `(t :> w) @@ out` in `SignOut`, with the guard. Same function.
- `<<>>` for the empty function, as measured.
- The one-line `TypeOK` over `SUBSET Tools`, not measured.

## Elimination table

| neighbour answer | what kills it |
|---|---|
| a set of tools that are out, no holder | the rule can't be written. Every row reads fine |
| a tool's holder fixed once it's out | row 2 |
| the total type on a partial variable | rc 12 on the first state, measured |
| no limit guard | rc 12, measured |
| the merge the wrong way round, with the guard | nothing. Same function |
| either merge, without the guard | nothing. rc 0 at 63 both ways, measured |

## Why not in prompt

"For every tool, whether it is on the shelf and if not, who has it" is
neutral between a partial function and a total one with a hole value, and
it says tool-first without saying the tool is the key.

The honest caveat is the closing question. Asking what the set of tools out
looks like, and what happens to it on a return, points at the domain being
state. A reader who writes the total layout answers "it's a filter, and
nothing happens to it", which is right, and never meets the merge or the
rebuild. So the lesson about the merge and the one-key constructor lands
for the partial choice and not the other two. I'd keep it that way. The
total layout is a legitimate answer and a drill shouldn't force a shape to
reach a construct.

## Measured runs

Each row is a line of `bash drill/functions-records/verify-all.sh 05`, with
`-d` passed because every config here asks for deadlock checking.

| module | config | rc | distinct states |
|---|---|---|---|
| `ToolCrib.tla` | `ToolCrib.cfg` | rc 0 | 63 |
| `ToolCribEmptyTuple.tla` | `ToolCribEmptyTuple.cfg` | rc 0 | 63 |
| `ToolCribTotal.tla` | `ToolCribTotal.cfg` | rc 0 | 63 |
| `ToolCribByWorker.tla` | `ToolCribByWorker.cfg` | rc 0 | 63 |
| `ToolCribReissueOldWins.tla` | `ToolCribReissueOldWins.cfg` | rc 0 | 63 |
| `ToolCribReissueNewWins.tla` | `ToolCribReissueNewWins.cfg` | rc 0 | 63 |
| `ToolCribNoLimit.tla` | `ToolCribNoLimit.cfg` | rc 12 | 34 |
| `ToolCribWrongType.tla` | `ToolCribWrongType.cfg` | rc 12 | none printed |
| `ToolCribNoTLC.tla` | `ToolCribNoTLC.cfg` | rc 150 | none |
