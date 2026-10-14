# Answer: two chutes, one gate

Files in `verify/`. `Chute.tla` is the one chute. `SortingLine.tla` is
the line with both rules in place. `SortingLineNamed.tla` defines each
rule first. `SortingLineExpr.tla` is row two and
`SortingLineCrossed.tla` is row three.

Every number from `harness/verdict.sh` on TLC2 Version
2026.07.31.184830.

## Question 1: the chute and the line

```
---- MODULE Chute ----
CONSTANTS Parcels, Admit(_)

VARIABLE passed

Init == passed = {}

Pass(p) ==
    /\ p \in Parcels \ passed
    /\ Admit(p)
    /\ passed' = passed \cup {p}

Next == \E p \in Parcels : Pass(p)
Spec == Init /\ [][Next]_passed

OnlyAdmitted == \A p \in passed : Admit(p)
====
```

```
---- MODULE SortingLine ----
EXTENDS Naturals
CONSTANTS Parcels, Small
VARIABLES light, paired

L == INSTANCE Chute WITH Admit <- LAMBDA p : p <= Small, passed <- light
P == INSTANCE Chute WITH Admit <- LAMBDA p : p % 2 = 0, passed <- paired

Init == L!Init /\ P!Init
Next ==
    \/ L!Next /\ UNCHANGED paired
    \/ P!Next /\ UNCHANGED light
Spec == Init /\ [][Next]_<<light, paired>>

OnlyAdmitted == L!OnlyAdmitted /\ P!OnlyAdmitted

Routed ==
    /\ \A p \in light : p <= Small
    /\ \A p \in paired : p % 2 = 0
====
```

`Line.cfg` sets `Parcels = {1, 2, 3, 4}`, `Small = 2`, and names both
invariants.

The rule parameter is an operator. `CONSTANTS Parcels, Admit(_)`
declares `Admit` as a constant that takes one argument, and the
underscore in parentheses is the whole declaration of that. `Parcels` is
shared by name and passes through to both instances without being
mentioned in the `WITH`.

## Question 2: expression against test

`p <= Small` is a boolean about a `p` that has to already mean
something. `LAMBDA p : p <= Small` is a thing you can hand a parcel to.
The instance wants the second, because the chute is going to apply it.
Row two, with the expression:

```
line 9, col 35 to line 9, col 46 of module SortingLineExpr
Arity 1 operator (not an expression) is expected
to substitute for CONSTANT 'Admit'.
An operator must be substituted for symbol 'Admit', and it must have arity 1.
```

The lambda is the shortest way to write an operator in place. The
longer way is to define `IsLight(p) == p <= Small` and write
`Admit <- IsLight`, with no argument list, because what's being passed
is the operator and not a call of it. `SortingLineNamed.tla` does that
and gets the same 16.

## Question 3: crossed wiring

In `SortingLineCrossed.tla` the light rule is wired to `paired` and the
even rule to `light`. Each instance's `OnlyAdmitted` is stated over its
own record with its own rule, and each instance is internally
consistent: the light rule only ever puts light parcels into `paired`.
So both pass. `Routed` is written from the line and names the variables
with the rules the line meant them to have, and it fails on the first
step that puts a 4 into `light`. Two states.

That's the reason to state the requirement twice. A property reached
through an instance inherits the instance's wiring, mistakes included.

## Question 4: the 16

`light` ends up a subset of `{1, 2}` and `paired` a subset of `{2, 4}`.
Four subsets each, every combination reachable, 16 states. Parcel 3
passes nowhere, which the line allows.

## Variants worth running

Give the chute alone a config. An operator constant can be set from the
config too, with the arrow form naming an operator defined in an `MC`
module. I haven't run that here, so take it as the documented route
rather than a measured one.

Add a third chute with the rule `TRUE`. A lambda that ignores its
argument is still arity 1 and still fine.

## The whole table

Every run uses the same constants. `G06Expr.tla`'s config omits
`Routed`, since it never gets past the parser.

| module run | rc | distinct | depth |
|---|---|---|---|
| the line, rules in place | 0 | 16 | 5 |
| the line, rules defined and named | 0 | 16 | 5 |
| the rules as expressions | 150 | | |
| the rules crossed | 12 | 2 | 2 |

## Gate rows

One thin wrapper module per run the drill gate reproduces, each with a
copy of the config it stands for. The rc is what `harness/verdict.sh`
returns.

| module | rc | distinct | stands for |
|---|---|---|---|
| `G06Line.tla` | rc 0 | 16 | the answer, 16 states |
| `G06Named.tla` | rc 0 | 16 | the rules as named operators, 16 states |
| `G06Expr.tla` | rc 150 | - | an expression where an operator was wanted |
| `G06Crossed.tla` | rc 12 | 2 | the rules wired to the wrong records |

## why-not-in-prompt

The prompt says "a test the chute applies to a parcel", "written in
place", and gives the parser's own words, "arity 1", in the table.

What the prompt withholds: the keyword for an operator written in place,
the underscore declaration of an operator parameter, that an instance
substitution takes an operator by name without an argument list, and
that a shared constant passes through unmentioned.

The honest caveat: "arity 1" is the parser's phrase and a reader who
knows SANY's messages will go straight to the operator-parameter form.
And the domain is a sorting line with one-to-four weights, which is
about as thin as a domain gets. The crossed-wiring row is the part I'd
keep if the item were cut to one question.
