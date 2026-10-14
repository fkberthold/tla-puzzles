# The charging bays: answer

Three ways to lay out the state, all three right, all three at 37 states.
What changes between them is which rule comes free and which one you owe.

## Encoding A: the bay's side, two functions

`verify/BaysTwoFns.tla`.

```tla
CONSTANTS Bays, Vans, Empty

VARIABLES van, plugged
vars == <<van, plugged>>

TypeOK == /\ van \in [Bays -> Vans \cup {Empty}]
          /\ plugged \in [Bays -> BOOLEAN]

Parked(v) == \E b \in Bays : van[b] = v

Init == /\ van = [b \in Bays |-> Empty]
        /\ plugged = [b \in Bays |-> FALSE]

DriveIn(v, b) == /\ van[b] = Empty
                 /\ ~Parked(v)
                 /\ van' = [van EXCEPT ![b] = v]
                 /\ UNCHANGED plugged

DriveOut(b) == /\ van[b] /= Empty
               /\ ~plugged[b]
               /\ van' = [van EXCEPT ![b] = Empty]
               /\ UNCHANGED plugged

PlugIn(b) == /\ van[b] /= Empty
             /\ ~plugged[b]
             /\ plugged' = [plugged EXCEPT ![b] = TRUE]
             /\ UNCHANGED van

Unplug(b) == /\ plugged[b]
             /\ plugged' = [plugged EXCEPT ![b] = FALSE]
             /\ UNCHANGED van

Next == \/ \E v \in Vans, b \in Bays : DriveIn(v, b)
        \/ \E b \in Bays : DriveOut(b) \/ PlugIn(b) \/ Unplug(b)

Spec == Init /\ [][Next]_vars

NeverPlugEmpty == \A b \in Bays : plugged[b] => van[b] /= Empty

OneBayPerVan == \A b1, b2 \in Bays :
                  (b1 /= b2 /\ van[b1] /= Empty) => van[b1] /= van[b2]
```

```
SPECIFICATION Spec
INVARIANTS TypeOK NeverPlugEmpty OneBayPerVan
CHECK_DEADLOCK TRUE
CONSTANTS
  Bays = {b1, b2, b3}
  Vans = {v1, v2}
  Empty = Empty
```

`van` is a function from bays, so a bay has one value and "a bay never
holds two vans" can't be written false. That rule is free. "A van is never
in two bays" is the one you owe: nothing stops `van[b1]` and `van[b2]`
both reading `v1` unless `DriveIn` checks, and `OneBayPerVan` is the line
that says so.

Hand count. Occupancy first: nobody parked, 1 way. One van parked, 3 bays
times 2 vans, 6 ways. Both parked, 3 choices of bay pair times 2 orders, 6
ways. That's 13. A parked van's charger is in or out, an empty bay's is out
by the first rule, so 1 plus 6 times 2 plus 6 times 4, which is 37. TLC
found 37.

## Encoding B: the bay's side, one function to records

`verify/BaysRecords.tla`. Same information as A in one variable. Every
update goes through a field path and nothing has to say "and the other
variable is held", since there's one variable.

```tla
VARIABLE bay

TypeOK == bay \in [Bays -> [van: Vans \cup {Empty}, plugged: BOOLEAN]]

Init == bay = [b \in Bays |-> [van |-> Empty, plugged |-> FALSE]]

DriveIn(v, b) == /\ bay[b].van = Empty
                 /\ ~Parked(v)
                 /\ bay' = [bay EXCEPT ![b].van = v]

PlugIn(b) == /\ bay[b].van /= Empty
             /\ ~bay[b].plugged
             /\ bay' = [bay EXCEPT ![b].plugged = TRUE]
```

Same free rule, same owed rule, same 37.

## Encoding C: the van's side

`verify/BaysVanSide.tla`. The prompt never says the bay is the thing that
records. From the van's side, `at` says which bay each van is in, or
`Away`, and the charger follows the van.

```tla
CONSTANTS Bays, Vans, Away

VARIABLES at, plugged

TypeOK == /\ at \in [Vans -> Bays \cup {Away}]
          /\ plugged \in [Vans -> BOOLEAN]

Occupied(b) == \E v \in Vans : at[v] = b

DriveIn(v, b) == /\ at[v] = Away
                 /\ ~Occupied(b)
                 /\ at' = [at EXCEPT ![v] = b]
                 /\ UNCHANGED plugged

NeverPlugEmpty == \A v \in Vans : plugged[v] => at[v] /= Away

OneVanPerBay == \A v1, v2 \in Vans :
                  (v1 /= v2 /\ at[v1] /= Away) => at[v1] /= at[v2]
```

Now a van is in one bay by construction and the bay rule is the obligation.
The mirror image of A, guard for guard and invariant for invariant. 37.

## Side by side

| encoding | module | variables | free rule | owed rule | rc | states |
|---|---|---|---|---|---|---|
| A, bay's side | `BaysTwoFns` | `van`, `plugged` | one van per bay | one bay per van | rc 0 | 37 |
| B, bay's side, records | `BaysRecords` | `bay` | one van per bay | one bay per van | rc 0 | 37 |
| C, van's side | `BaysVanSide` | `at`, `plugged` | one bay per van | one van per bay | rc 0 | 37 |
| both sides at once | `BaysBothSides` | `van`, `at`, `plugged` | both | both sides agree | rc 0 | 37 |

The counts agree because the three carry the same facts: which van is in
which bay, and which chargers are in. The shape of the state is a choice
about which rule you'd rather have for free, and I'd pick the side whose
owed rule is the one I'm least likely to forget to guard. Here that's a
toss-up.

The fourth row is the one to notice. `BaysBothSides` keeps both maps and
adds `TwoSidesAgree`, a consistency invariant. It reaches the same 37
states, so the second map records nothing the first didn't, and it costs an
invariant and an extra update in every action that moves a van. Redundant
state doesn't show up in the count when it's kept in step. It shows up in
the number of places a change has to be made.

## The owed rule, left unguarded

Each side forgets the thing it doesn't get for free, and the owed invariant
is what catches it.

`BaysTwoFnsNoParkedGuard` drops `~Parked(v)` from `DriveIn`. rc 12,
`OneBayPerVan`, at the third state: `DriveIn(v1, b1)` then
`DriveIn(v1, b2)`. 8 states explored.

`BaysVanSideNoFreeGuard` drops `~Occupied(b)`. rc 12, `OneVanPerBay`, 9
states. The mirror of the row above.

`BaysRecordsLeavePlugged` drops the unplug-first guard from `DriveOut`. rc
12, `NeverPlugEmpty`, 24 states in.

## Elimination table

| neighbor answer | what kills it |
|---|---|
| one plugged flag for the whole forecourt | row 1: one van plugged in and the other not |
| a per-van status with no bay name (away, parked, plugged) | rows 3 and 4 name bays, and the bay rule can't be written |
| a count of vans in bays | row 1, and neither rule can be written |
| a set of occupied bays with no van name | the van rule can't be written. The table reads fine. |
| A, B or C with its owed guard missing | the owed invariant, rc 12, measured above |

## Why not in prompt

The prompt names bays and vans by number and never says which one does the
recording. "Out on the road, a van is in no bay at all" is neutral between
an `Empty` bay and an `Away` van. The two rules are stated as a pair with
no side first.

The honest caveat is the closing question. Asking which rule "your choice
of state made impossible to break" says there is such a rule, which is the
lesson said sideways, and a reader who has thought about function domains
before will hear it. It's asked after the model is run, so the choice is
made by the time it's read. The measured part the reader doesn't have is
that the three choices land on the same 37, and that a fourth, keeping
both sides, lands there too.

## Measured runs

Each row is a line of `bash drill/functions-records/verify-all.sh 02`, with
`-d` passed because every config here asks for deadlock checking.

| module | config | rc | distinct states |
|---|---|---|---|
| `BaysTwoFns.tla` | `BaysTwoFns.cfg` | rc 0 | 37 |
| `BaysRecords.tla` | `BaysRecords.cfg` | rc 0 | 37 |
| `BaysVanSide.tla` | `BaysVanSide.cfg` | rc 0 | 37 |
| `BaysBothSides.tla` | `BaysBothSides.cfg` | rc 0 | 37 |
| `BaysTwoFnsNoParkedGuard.tla` | `BaysTwoFnsNoParkedGuard.cfg` | rc 12 | 8 |
| `BaysVanSideNoFreeGuard.tla` | `BaysVanSideNoFreeGuard.cfg` | rc 12 | 9 |
| `BaysRecordsLeavePlugged.tla` | `BaysRecordsLeavePlugged.cfg` | rc 12 | 24 |
