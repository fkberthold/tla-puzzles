# The autoclaves: answer

## The answer

```tla
---- MODULE Autoclaves ----
EXTENDS Naturals, FiniteSets
CONSTANTS Autoclaves, MaxP, Budget

VARIABLE unit
vars == <<unit>>

TypeOK == unit \in [Autoclaves -> [pressure: 0..MaxP, open: BOOLEAN]]

Pressurised == {a \in Autoclaves : unit[a].pressure > 0}

Init == unit = [a \in Autoclaves |-> [pressure |-> 0, open |-> TRUE]]

Close(a) == /\ unit[a].open
            /\ unit' = [unit EXCEPT ![a].open = FALSE]

Open(a) == /\ ~unit[a].open
           /\ unit[a].pressure = 0
           /\ unit' = [unit EXCEPT ![a].open = TRUE]

Heat(a) == /\ ~unit[a].open
           /\ unit[a].pressure < MaxP
           /\ Cardinality(Pressurised \cup {a}) <= Budget
           /\ unit' = [unit EXCEPT ![a].pressure = @ + 1]

Vent(a) == /\ unit[a].pressure > 0
           /\ unit' = [unit EXCEPT ![a].pressure = @ - 1]

Next == \E a \in Autoclaves : Close(a) \/ Open(a) \/ Heat(a) \/ Vent(a)

Spec == Init /\ [][Next]_vars

DoorShutUnderPressure == \A a \in Autoclaves : unit[a].pressure > 0 => ~unit[a].open

CompressorBudget == Cardinality(Pressurised) <= Budget
====
```

```
SPECIFICATION Spec
INVARIANTS TypeOK DoorShutUnderPressure CompressorBudget
CHECK_DEADLOCK TRUE
CONSTANTS
  Autoclaves = {a1, a2, a3}
  MaxP = 2
  Budget = 2
```

One function, autoclave to a record of two fields. `TypeOK` says so with
a record set inside a function set, and `Init` builds it with a record
literal inside a function literal. The arrows match the brackets: a colon
builds a set, a bar-arrow builds a value.

Hand count. One autoclave has four reachable states: open at 0, shut at 0,
shut at 1, shut at 2. Three of them is 64, less the 8 where all three are
above zero. 56, and TLC found 56.

The two closing sentences. The step that raises the pressure says nothing
about the door, because an update that names one field copies every other
field of that record. It says nothing about the other two autoclaves
either, because an update that names one key copies every other key.

## Where `@` lives

Three depths, three meanings, and the mis-spellings come from mixing them.

`![a] = ...` sits at the key. `@` is the whole record for autoclave `a`.

`![a].pressure = ...` goes one level in. `@` is the old pressure, a number.
That's the reference.

`![a] = [@ EXCEPT !.pressure = @ + 1]` nests two updates. The outer `@` is
the record, the inner `@` is its pressure. `AutoclavesNested` writes
`Heat` this way, rc 0 at 56.

## The neighbors

`AutoclavesAtDepth` writes `![a].pressure = @.pressure + 1`. The path goes
into the field, and `@` is read as if it were still the record. rc 75 at
the first heat, four states in: "Attempted to select field "pressure" from
a non-record value 0".

`AutoclavesDropField` writes `![a] = [pressure |-> @.pressure + 1]`. The
path stops at the key, so `@` is the record and `@.pressure` is right. The
replacement record has one field and no door. `TypeOK` goes red at the
fifth state, rc 12. I didn't measure the run without `TypeOK` in the
config. My guess is the next read of that autoclave's door fails at rc 75
instead, which is later and with a worse message.

`AutoclavesSetInit` builds the initial record with colons: `[pressure:
{0}, open: {TRUE}]`. A colon builds the set of records with those fields,
so every `unit[a]` is a one-element set, and rc 75 on the first state:
"Attempted to check if non-record {[pressure |-> 0, open |-> TRUE]} is in
the set of records". The same slip as a function set where a function
belongs, one level down.

`AutoclavesNoBudget` has the records right and never counts. rc 12 on
`CompressorBudget`, 50 states in.

## Acceptable variants

`AutoclavesSplit` keeps two functions, `pressure` and `open`, and no
record. rc 0 at 56. Every one-field update now has to say the other
function is held, which is the answer to the first closing sentence in
that layout: `UNCHANGED open`. Nothing wrong with it. The record form has
one variable and fewer lines, and the split form has no nested `@` to get
wrong. I'd take the record form for an entity with more than two fields
and either for this one.

The nested form in `AutoclavesNested`, as above.

`Heat`'s budget guard as `a \in Pressurised \/ Cardinality(Pressurised) <
Budget`. Same meaning, not measured.

## Elimination table

There's no behavior table in this prompt. The neighbors above are the
elimination, each with its measured number.

| neighbor answer | what kills it |
|---|---|
| `@.pressure` on the field path | rc 75, measured |
| a one-field record at the key path | `TypeOK`, rc 12, measured |
| colons in `Init` | rc 75 on the first state, measured |
| no compressor count | `CompressorBudget`, rc 12, measured |
| one pressure gauge for the lab | the door rule can't be written. Not measured |

## Why not in prompt

The prompt gives the 56 and the starting state. The two rules are stated
as the safety officer would, one per autoclave and one across the lab, so
the per-unit record and the cross-unit count both have to be there.

The honest caveat is the closing paragraph. Asking what the heating step
says about the door and about the other autoclaves is the copies-the-rest
lesson asked as a question, and a reader who knows it answers "nothing" and
writes the field path from memory. What that reader doesn't have is what
`@` is at each depth, and the two mis-spellings TLC reports with different
messages at different depths. That's the part worth running.

## Measured runs

Each row is a line of `bash drill/functions-records/verify-all.sh 04`, with
`-d` passed because every config here asks for deadlock checking.

| module | config | rc | distinct states |
|---|---|---|---|
| `Autoclaves.tla` | `Autoclaves.cfg` | rc 0 | 56 |
| `AutoclavesSplit.tla` | `AutoclavesSplit.cfg` | rc 0 | 56 |
| `AutoclavesNested.tla` | `AutoclavesNested.cfg` | rc 0 | 56 |
| `AutoclavesAtDepth.tla` | `AutoclavesAtDepth.cfg` | rc 75 | 4 |
| `AutoclavesDropField.tla` | `AutoclavesDropField.cfg` | rc 12 | 5 |
| `AutoclavesSetInit.tla` | `AutoclavesSetInit.cfg` | rc 75 | 1 |
| `AutoclavesNoBudget.tla` | `AutoclavesNoBudget.cfg` | rc 12 | 50 |
