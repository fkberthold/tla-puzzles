# Returns desk: answer

There are three right answers, and the item is about telling them apart.
The one in this family comes first.

## The answer, with the desk as a list

```tla
---- MODULE Desk ----
EXTENDS Naturals, Sequences

CONSTANT Books

VARIABLES out, desk

vars == <<out, desk>>

OnDesk(b) == \E i \in DOMAIN desk : desk[i] = b

TypeOK ==
  /\ out \subseteq Books
  /\ desk \in Seq(Books)

Init ==
  /\ out = {}
  /\ desk = <<>>

Borrow(b) ==
  /\ b \notin out
  /\ ~OnDesk(b)
  /\ out' = out \cup {b}
  /\ UNCHANGED desk

Return(b) ==
  /\ b \in out
  /\ out' = out \ {b}
  /\ desk' = Append(desk, b)

Shelve == \E i \in DOMAIN desk :
  /\ desk' = SubSeq(desk, 1, i - 1) \o SubSeq(desk, i + 1, Len(desk))
  /\ UNCHANGED out

Next == (\E b \in Books : Borrow(b) \/ Return(b)) \/ Shelve

Spec == Init /\ [][Next]_vars

NeverBoth == \A i \in DOMAIN desk : desk[i] \notin out

NoBookTwice == \A i, j \in DOMAIN desk : i /= j => desk[i] /= desk[j]
====
```

```
SPECIFICATION Spec
CONSTANT Books = {b1, b2, b3}
INVARIANTS
  TypeOK
  NeverBoth
  NoBookTwice
```

38 distinct states. The desk remembers the order books came back in, which
the prompt never asked for, and the extra states are that order. For each
set of books on the desk there's one state per arrangement. A list can also
hold the same book twice, which a set can't, so the list encoding carries a
second rule the others don't need.

Membership in a list is a search, `\E i \in DOMAIN desk : desk[i] = b`.
There's no operator for it in the module. The rule is the same search with
the quantifier turned round.

## The desk as a set

```tla
---- MODULE DeskAsSet ----
EXTENDS Naturals

CONSTANT Books

VARIABLES out, desk

vars == <<out, desk>>

TypeOK ==
  /\ out \subseteq Books
  /\ desk \subseteq Books

Init ==
  /\ out = {}
  /\ desk = {}

Borrow(b) ==
  /\ b \notin out
  /\ b \notin desk
  /\ out' = out \cup {b}
  /\ UNCHANGED desk

Return(b) ==
  /\ b \in out
  /\ out' = out \ {b}
  /\ desk' = desk \cup {b}

Shelve(b) ==
  /\ b \in desk
  /\ desk' = desk \ {b}
  /\ UNCHANGED out

Next == \E b \in Books : Borrow(b) \/ Return(b) \/ Shelve(b)

Spec == Init /\ [][Next]_vars

NeverBoth == out \cap desk = {}
====
```

27 distinct states, three places for each of three books. The rule is one
intersection. This is the encoding the prompt's silence about order points
at, and it's the one I'd write.

## One function from book to place

```tla
---- MODULE DeskAsFunction ----
EXTENDS Naturals

CONSTANT Books

VARIABLE place

vars == <<place>>

Places == {"shelf", "out", "desk"}

TypeOK == place \in [Books -> Places]

Init == place = [b \in Books |-> "shelf"]

Borrow(b) ==
  /\ place[b] = "shelf"
  /\ place' = [place EXCEPT ![b] = "out"]

Return(b) ==
  /\ place[b] = "out"
  /\ place' = [place EXCEPT ![b] = "desk"]

Shelve(b) ==
  /\ place[b] = "desk"
  /\ place' = [place EXCEPT ![b] = "shelf"]

Next == \E b \in Books : Borrow(b) \/ Return(b) \/ Shelve(b)

Spec == Init /\ [][Next]_vars
====
```

27 distinct states, the same as the set. There's no rule to state. A
function gives each book one place, so a book can't be in two of them, and
`TypeOK` is the whole requirement. That's the answer to the last question
in the prompt. The encoding that makes the rule unstatable is the one that
makes it unbreakable.

## Which is right

All three. The prompt gives no reason to remember the order of returns, so
the set is the simplest model of what it says. The list is right if a later
rule will care about order, and the item sits in this family because the
list is the encoding whose operators the reader has to produce. The
function is right if the three places are what the model is about and the
desk is incidental.

What isn't a matter of taste is the count. 27 against 38 is the order of
the desk, and a reader who gets 38 should be able to say so.

## Acceptable variants

- The list with `Shelve` taking the front, `Tail`, or the back,
  `SubSeq(desk, 1, Len(desk) - 1)`. Either fixes an order the prompt didn't
  give, and I expect either to reach the same 38 states, since arrival
  order is free. Not measured.
- Three sets, one per place, with a rule that they partition the books.
- A list of records with a book field and a place field. More than the
  prompt needs.

## Wrong neighbors

| neighbor | module | killed by | rc |
|---|---|---|---|
| `Return` adds to the desk and forgets to take the book off the loan set | `DeskSeqStaysOut` | the rule, on the first return | rc 12 |

The same slip in the set encoding should fail the same way. Not measured.
In the function encoding it can't be written: there's one assignment and
it moves the book.

## Measured

From `verify/`, through `harness/verdict.sh` the way `harness/drill-gate.sh`
runs it. TLC2 Version 2026.07.31.184830, `-workers 1`. The three book names
are model values.

| module | what | rc | distinct states |
|---|---|---|---|
| `DeskSeq` | the desk as a list | rc 0 | 38 found |
| `DeskSet` | the desk as a set | rc 0 | 27 found |
| `DeskFun` | one function, book to place | rc 0 | 27 found |
| `DeskSeqStaysOut` | the list, loan set never updated | rc 12 | 5 found |

38 by hand: for k books on the desk there are k! arrangements, and each of
the other 3 - k books is out or shelved. 8 + 12 + 12 + 6.

## Why not in prompt

Prose only, and the prose is silent on the thing that decides the encoding.
The reader has to notice that it's silent, and then pick. The list
encoding's operators, membership as a search and removal as two slices, are
nowhere on the page.

The caveat: "a colleague found a different number" says outright that there
is a choice, and a reader who has thought about sets against lists before
will guess what it is. The item still has to be written three times to be
checked, and the question of which choice made the rule harder to break
isn't answerable from the hint.
