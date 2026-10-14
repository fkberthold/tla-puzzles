# Lift: answer

## The answer

```tla
---- MODULE Lift ----
EXTENDS Integers

CONSTANTS Basements, Top

VARIABLES floor, door, moving

vars == <<floor, door, moving>>

Bottom == -Basements

TypeOK ==
  /\ floor \in Bottom..Top
  /\ door \in {"open", "shut"}
  /\ moving \in BOOLEAN

Init ==
  /\ floor = 0
  /\ door = "open"
  /\ moving = FALSE

Open ==
  /\ ~moving
  /\ door = "shut"
  /\ door' = "open"
  /\ UNCHANGED <<floor, moving>>

Close ==
  /\ door = "open"
  /\ door' = "shut"
  /\ UNCHANGED <<floor, moving>>

Start ==
  /\ door = "shut"
  /\ ~moving
  /\ moving' = TRUE
  /\ UNCHANGED <<floor, door>>

Up ==
  /\ moving
  /\ floor < Top
  /\ floor' = floor + 1
  /\ UNCHANGED <<door, moving>>

Down ==
  /\ moving
  /\ floor > Bottom
  /\ floor' = floor - 1
  /\ UNCHANGED <<door, moving>>

Stop ==
  /\ moving
  /\ moving' = FALSE
  /\ UNCHANGED <<floor, door>>

Next == Open \/ Close \/ Start \/ Up \/ Down \/ Stop

Spec == Init /\ [][Next]_vars

DoorShutWhileMoving == moving => door = "shut"
====
```

```
SPECIFICATION Spec
CONSTANTS
  Basements = 2
  Top = 3
INVARIANTS
  TypeOK
  DoorShutWhileMoving
```

`TypeOK` is the name at 117 of 713 published invariant declarations, and 164
of 713 start with `Type` (`.claude/rules/tla-practice.md`, section 3). It's one
conjunct per variable, and it's the one obligation the corpus does bundle.

## The trap

`floor \in Nat`. The trace in the prompt goes to -2, and `Nat` has no -1. The
second module below is that spec: `TypeOK` goes red five states in, at the
first step below ground.

`Int` is the other way to say it. `Bottom..Top` is better, since it's the type
and the building at once.

## The config can't say -2

`Bottom = -2` in the `.cfg` is refused: "TLC found an error in the
configuration file at line 4. It was expecting = or <-, but did not find it."
The config grammar has no negative literal. So the constant is `Basements`, a
count, and `Bottom == -Basements` is a definition in the module. That one took
me a run to find and I'd expect it to take the reader one too.

## Measurements

From `verify/`, `tlc -workers 1 -noGenerateSpecTE -metadir states/<name>
<Module>.tla -config <Module>.cfg`.

| module | what | rc | generated | distinct | TLC says |
|---|---|---|---|---|---|
| `Lift` | reference | rc 0 | 35 | 18 | no error |
| `FloorInNat` | `floor \in Nat` | rc 12 | 6 | 5 | `Invariant TypeOK is violated.` |
| `NegativeInConfig` | `Bottom` a constant, `Bottom = -2` in the config | rc 255 | 0 | 0 | `It was expecting = or <-, but did not find it.` |

18 is 6 floors times 3 of the 4 door-and-moving pairs, since moving with the
door open is unreachable, which is what the safety rule says.

## Acceptable variants

- `floor \in Int` in `TypeOK`. Passes. It says less than the building does.
- `moving \in {TRUE, FALSE}`. Same set as `BOOLEAN`.
- `door` as a Boolean `open`. The rule becomes `moving => ~open`.
- `Bottom` and `Top` both as definitions, no constants. Passes, and the config has nothing to set.

## Wrong neighbors

| neighbor | what kills it |
|---|---|
| `floor \in Nat` | `TypeOK` red at floor -1 |
| a negative literal in the config | the config parser, before the module is read |
| `EXTENDS Naturals` | I'd expect the unary minus in `Bottom` to fail to parse (not measured) |
| `Down` guarded on `floor > 0` | passes TLC and never reaches a basement. I'd expect 12 states (not measured). |
| no `moving` variable | the safety rule can't be an invariant. It becomes `[][floor' /= floor => door = "shut"]_vars`, which is the temporal family's item. |

## Why not in prompt

The table is the prompt, and the row at -2 is the foreclosing row. A reader who
writes `Nat` gets a red `TypeOK` on his own first run. The honest caveat: the
prompt says "basements" twice and shows -2 twice, so a reader who already knows
`Int` exists has nothing to retrieve. What he does still have to retrieve is
the config limit, and I don't think the prompt gives that away.
