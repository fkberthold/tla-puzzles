# Covering a sick driver: answer

## The answer

```tla
---- MODULE DepotCover ----
EXTENDS Naturals, TLC

Routes == 1..3
Drivers == 1..4
Default == [r \in Routes |-> r]

VARIABLES sick, cover
vars == <<sick, cover>>

Roster == cover @@ Default
Drives(d) == {r \in Routes : Roster[r] = d}
Fit == Drivers \ sick

TypeOK == /\ sick \subseteq Drivers
          /\ DOMAIN cover \subseteq Routes
          /\ \A r \in DOMAIN cover : cover[r] \in Drivers

Init == /\ sick = {}
        /\ cover = [r \in {} |-> 0]

FallSick(d) == /\ d \notin sick
               /\ sick' = sick \cup {d}
               /\ \/ /\ Drives(d) = {}
                     /\ UNCHANGED cover
                  \/ /\ Drives(d) /= {}
                     /\ \E s \in Fit \ {d} :
                          cover' = [r \in Drives(d) |-> s] @@ cover

Recover(d) == /\ d \in sick
              /\ sick' = sick \ {d}
              /\ cover' = [r \in {q \in DOMAIN cover : Default[q] /= d} |-> cover[r]]

Next == \E d \in Drivers : FallSick(d) \/ Recover(d)

Spec == Init /\ [][Next]_vars

NoSickDriverRostered == \A r \in Routes : Roster[r] \notin sick
====
```

```
SPECIFICATION Spec
INVARIANTS TypeOK NoSickDriverRostered
CHECK_DEADLOCK TRUE
```

No constants to bind: routes and drivers are small intervals in the module,
so the defaults can be written down as a function literal.

`cover` is the standing list, a partial function from routes. The merge
keeps the left value on a shared key, so the two merges in the module both
put the thing that should win on the left. `Roster` puts the list over the
defaults. `FallSick` puts the new stand-ins over the list, because a route
the sick driver was covering already has an entry, and that entry has to
lose. `Recover` strikes entries by rebuilding the function over a filtered
domain.

TLC found 33. I don't have a hand count for this one. The reachable set is
shaped by which drivers can fall sick while a stand-in exists, and I didn't
enumerate it by hand.

## The merge has a side

Two neighbours, each with one merge turned round.

`DepotCoverDefaultsWin` writes `Roster == Default @@ cover`. Now the
default driver wins on every route the list names, and the list is
decoration. rc 12 at the second state: driver 1 falls sick, driver 2 goes
on the list for route 1, and the roster still reads 1.

`DepotCoverOldWins` has the roster right and writes the sick-day merge as
`cover @@ [r \in Drives(d) |-> s]`. The old entry wins. rc 12 at the third
state, 12 states explored:

- driver 1 falls sick, driver 2 covers route 1
- driver 2 falls sick, driver 3 covers route 2, and route 1 keeps its entry for driver 2

Route 1 is rostered to a sick driver. That's the prompt's second row,
with driver 2 standing where the row has driver 4. The first fall works in
both orders. The trap is the second one, when a stand-in is the one who
falls sick, and that's why the row is there.

A small thing worth noticing in the trace: TLC printed `cover` as `<<2>>`
and then `<<2, 3>>`. A function on `1..n` is a tuple, and TLC prints it as
one. The second value is the function on `{1, 2}`, and the printer doesn't
know the keys are routes.

## Acceptable variants

`DepotCoverIfForm` has no merge anywhere. `Roster` is a conditional over
the domain and the sick-day update rebuilds the function over the union of
the two domains with the same conditional. rc 0 at 33. Longer, and the
same thing, since this is what the merge abbreviates.

`DepotCoverTotal` keeps the list as a total function with a hole value,
`NoCover`. The domain never moves and no merge is needed. rc 0 at 33.

Both are right answers, and neither meets the direction trap. That's the
caveat below.

## Elimination table

| neighbour answer | what kills it |
|---|---|
| the roster merge with the defaults on the left | row 1. rc 12, measured |
| the sick-day merge with the old list on the left | row 2. rc 12, measured |
| the list as a set of route-driver pairs | row 2 needs the old pair removed. Not wrong, but uniqueness per route is then owed. Not measured |
| the last fit driver allowed to fall sick | row 5, and the rule. rc 12 I'd expect. Not measured |
| conditional or hole-value forms | nothing. rc 0 at 33, measured |

## Why not in prompt

"Laid over it" is the merge's meaning in English, and it has to be there.
Without saying which side wins the roster isn't defined, and the gate's
rule is that the problem statement gets to say what the problem is.

The honest caveat is that the prose does say which side wins, and the
item's trap is writing that down with the operands the right way round. A
reader who knows the operator knows the left wins and only has to map
"laid over" to "left". I think the second row still earns its place. The
sick-day merge is the one that goes backwards even when the roster merge
is right, and the trace that catches it is three states deep.

A second caveat. Two of the five modules that pass never use the merge at
all. The conditional form and the hole-value form are both right, and a
reader who writes either one meets no trap. The drill doesn't force the
operator, and I'd rather that than a prompt that did.

## Measured runs

Each row is a line of `bash drill/functions-records/verify-all.sh 06`, with
`-d` passed because every config here asks for deadlock checking.

| module | config | rc | distinct states |
|---|---|---|---|
| `DepotCover.tla` | `DepotCover.cfg` | rc 0 | 33 |
| `DepotCoverIfForm.tla` | `DepotCoverIfForm.cfg` | rc 0 | 33 |
| `DepotCoverTotal.tla` | `DepotCoverTotal.cfg` | rc 0 | 33 |
| `DepotCoverDefaultsWin.tla` | `DepotCoverDefaultsWin.cfg` | rc 12 | 2 |
| `DepotCoverOldWins.tla` | `DepotCoverOldWins.cfg` | rc 12 | 12 |
