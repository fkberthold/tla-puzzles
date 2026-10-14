# Answer: the hoist and the crates

Files in `verify/`. `Hoist.tla` is the answer. `HoistNoRec.tla` drops
the declaration. `HoistUnguarded.tla` drops the weight check.
`HoistFn.tla` writes the sum as a recursive function instead.

Every number from `harness/verdict.sh` on TLC2 Version
2026.07.31.184830.

## Question 1: the hoist

```
---- MODULE Hoist ----
EXTENDS Naturals
CONSTANTS Crates, Limit
VARIABLE aboard

Load ==
    LET Pick(S) == CHOOSE c \in S : TRUE
        RECURSIVE Sum(_)
        Sum(S) == IF S = {} THEN 0 ELSE Pick(S) + Sum(S \ {Pick(S)})
    IN  Sum(aboard)

Init == aboard = {}

Board(c) ==
    /\ c \in Crates \ aboard
    /\ Load + c <= Limit
    /\ aboard' = aboard \cup {c}

Unload(c) ==
    /\ c \in aboard
    /\ aboard' = aboard \ {c}

Next == \E c \in Crates : Board(c) \/ Unload(c)
Spec == Init /\ [][Next]_aboard

Safe == Load <= Limit
====
```

`Heavy.cfg` sets `Crates = {40, 70, 90}` and `Limit = 150`. Six states:
empty, each crate alone, 40 with 70, 40 with 90. The 70 and 90 together
are 160.

The declaration is `RECURSIVE Sum(_)`. A definition's name isn't in
scope inside its own body until the definition is complete, so `Sum`
can't call `Sum` without being told ahead of time that a `Sum` of one
argument is coming. Without it:

```
line 11, col 51 to line 11, col 53 of module HoistNoRec
Unknown operator: `Sum'.
```

The declaration sits inside the `LET` with the two definitions, which
is allowed and keeps the module's top level clean. `Pick` is the helper
the prompt asked for, and it's there so `CHOOSE` is written once rather
than twice in the recursive arm.

## Question 2: the shortcut

"At most two crates aboard." On the first row it gives the same six
states and never fails. `Light.cfg` has crates of 40, 50 and 60, which
sum to 150, so all three board and the count is 8, every subset. A
cardinality bound would have refused the third crate and reported 7.
The count is the only thing that tells the sum from the shortcut.

## Question 3: no declaration

```
Load ==
    LET Sum[S \in SUBSET Crates] ==
            IF S = {} THEN 0
            ELSE LET c == CHOOSE c \in S : TRUE IN c + Sum[S \ {c}]
    IN  Sum[aboard]
```

A function may refer to itself by name inside its own definition, so no
declaration is needed. The cost is the domain. The function has to say
what set it's defined over, and here that's the powerset of `Crates`,
which has 8 elements at three crates and about a million at twenty. Same
6 states on `Heavy.cfg`. I suspect TLC evaluates the function lazily
rather than building the whole table, and I haven't checked, so take the
cost as the one you can see in the text.

## Variants worth running

Make `Limit` smaller than the lightest crate. One state, and `Safe`
holds because the load is zero. That's a vacuous pass and the gate
doesn't catch it.

Drop `Pick` and write `CHOOSE` twice. Same thing, and the second `LET`
definition was only there because the prompt asked for a helper next to
the sum.

## The whole table

| config | module run | rc | distinct | depth |
|---|---|---|---|---|
| `Heavy.cfg` | the answer | 0 | 6 | 3 |
| `Light.cfg` | the answer, three crates that all fit | 0 | 8 | 4 |
| `Heavy.cfg` | no declaration | 150 | | |
| `Heavy.cfg` | no weight check | 12 | 7 | 3 |
| `Heavy.cfg` | the sum as a function | 0 | 6 | 3 |

## Gate rows

One thin wrapper module per run the drill gate reproduces, each with a
copy of the config it stands for. The rc is what `harness/verdict.sh`
returns.

| module | rc | distinct | stands for |
|---|---|---|---|
| `G07Hoist.tla` | rc 0 | 6 | `Heavy.cfg`, the answer, 6 states |
| `G07Light.tla` | rc 0 | 8 | `Light.cfg`, the row that kills the cardinality shortcut, 8 states |
| `G07NoRec.tla` | rc 150 | - | the sum with no declaration, unknown operator |
| `G07Unguarded.tla` | rc 12 | 7 | boarding without the check |
| `G07Fn.tla` | rc 0 | 6 | the sum as a recursive function, 6 states |

## why-not-in-prompt

The prompt asks for the total computed from a set, with the summing
definition local to its use and a helper beside it. It prints the error
the missing line produces, and question 1 points at that row. So a
reader who writes the sum without the line gets a refusal rather than a
clean pass. The item corrects itself without the prompt naming the
construct.

What the prompt withholds: the keyword, that the missing line is a
declaration rather than a definition, and why a definition needs one to
name itself. It also withholds the underscore form of the arity, that
the declaration can sit inside a `LET`, the `CHOOSE` for picking an
element, and the recursive-function alternative.

The honest caveat: this is a core-family item wearing the modules label,
and a reader who knows the recursive-sum idiom will reproduce it from
memory in under three minutes. "Its helper next to it" says there are
two definitions in the block. The second row is what makes the item
worth running at all, since without it a cardinality bound passes.

One leak survives the edit that cut question 1's definitional sentence.
Question 3 asks for the sum "with no declaration at all". A reader who
takes the three questions in order before writing learns that the
missing line is a declaration. I think that's a real leak rather than a
late reveal, since nothing makes a reader work question 1 first. The
wording that would close it: "a second way to write the sum that
doesn't need that line at all". That keeps the question's job of
pointing at a technique the reader wouldn't look for, and drops the
construct class.
