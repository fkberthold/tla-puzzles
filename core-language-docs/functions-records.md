# Functions and records

A function maps a set of inputs to values. This family is the ways to write
one, read one, type one, and change one field of one without rewriting the
rest.

It's the family you can't avoid. A spec with no sets and no modules is
ordinary. A spec with no functions holds one scalar per variable, and the
first time you want a counter per process you are here. The reason the family
is worth reading about rather than picking up is that three things that look
separate turn out to be one thing, and until you see that you're memorizing
three sets of rules.

Every module on this page is a real file under
`core-language-docs/snippets/`, and `run-all.sh` beside them checks each one
against the exit code and the state count quoted here. Measured on TLC
2026.07.31.184830 on 2026-10-21.

## The constructs

| Construct | Shape | What it means | In published specs |
|---|---|---|---|
| struct literal | `[a \|-> 1, b \|-> 2]`, read with `r.a` or `r["a"]` | one record value, with those fields holding those values | 176 definitions have a body of 2 or more fields |
| struct set | `[acct : Accounts, amnt : 1..10]` | the set of every record with those fields drawn from those sets | not counted |
| `DOMAIN` | `DOMAIN f` | the set of keys, indices, or inputs of `f` | not counted |
| function literal | `[x \in S \|-> expr]`, called with `f[x]` | one function from `S` to the values of `expr` | not counted |
| `:>` | `a :> b`, needs `EXTENDS TLC` | the one-pair function `[x \in {a} \|-> b]` | not counted |
| `@@` | `f @@ g`, needs `EXTENDS TLC` | the two functions joined, keeping `f`'s value on a shared key | not counted |
| function set | `[S -> T]` | the set of every function from `S` to `T` | not counted |
| bracket definition | `Name[x \in S] == expr` | sugar for `Name == [x \in S \|-> expr]` | not counted |
| recursive definition | `Name[x \in S] == expr`, where `expr` calls `Name` | the same sugar, and it may call itself | not counted |
| `EXCEPT` | `[f EXCEPT ![k] = v]` | a copy of `f` with `k` mapped to `v` | not counted |
| `@` | `[f EXCEPT ![k] = @ + 1]` | inside a clause, the value `f` already held there | not counted |

One of the eleven carries a figure. It comes from a survey of 666 modules and
337 configuration files drawn from 16 public repositories, read on 2026-09-05.
That survey counted how specs decompose their obligations, subscript their
actions, name their definitions, and use the configuration keywords. It never
counted an expression-level operator, so there is no number to report for
`EXCEPT` or `DOMAIN`, and that's a fact about the survey rather than about the
operators. I'd read "not counted" on this page as "used everywhere and
measured nowhere".

## A record is a function, and so is a sequence

This is the paragraph the rest of the page rests on. A record is a function
from its field names to its values. A sequence is a function from an integer
interval starting at 1. They are not three kinds of value with some operators
in common. They are one kind of value with three ways to write it down.

So one operator handles all three, and never asks which one it has:

```tla
---- MODULE Shape ----
EXTENDS Integers, Sequences
VARIABLES rec, fn, seq
vars == <<rec, fn, seq>>

\* One operator over all three shapes. It never asks which one it has.
Bump(f, k) == [f EXCEPT ![k] = @ + 1]

Init == /\ rec = [hits |-> 0, misses |-> 0]
        /\ fn  = [k \in {"hits", "misses"} |-> 0]
        /\ seq = <<0, 0>>

Next == /\ rec' = Bump(rec, "hits")
        /\ fn'  = Bump(fn, "hits")
        /\ seq' = Bump(seq, 1)

Spec == Init /\ [][Next]_vars
Cap == rec.hits <= 2

\* The record literal and the function literal are one value, not two.
SameValue == rec = fn

\* DOMAIN reads all three.
Domains == /\ DOMAIN rec = {"hits", "misses"}
           /\ DOMAIN seq = 1..Len(seq)

\* Two spellings of one lookup.
TwoSpellings == rec.hits = rec["hits"]

\* A sequence rebuilt as a function literal is the same sequence.
SeqIsFn == seq = [i \in 1..Len(seq) |-> seq[i]]

Unified == SameValue /\ Domains /\ TwoSpellings /\ SeqIsFn

\* The claim a reader starts with, and it is false.
Separate == rec # fn
======================
```

`INVARIANT Unified` exits 0 at 3 distinct states. The strong part is
`SameValue`. `[hits |-> 0, misses |-> 0]` and
`[k \in {"hits", "misses"} |-> 0]` are the same value, not two values that
behave alike, and TLC will tell you so if you claim otherwise. Running the
same module with `INVARIANT Separate` exits 12:

```
Error: Invariant Separate is violated by the initial state:
/\ fn = [hits |-> 0, misses |-> 0]
/\ rec = [hits |-> 0, misses |-> 0]
/\ seq = <<0, 0>>
```

Read what TLC printed for `fn`. It was written as a function literal over a
set of strings, and TLC printed it as a record, because that's the notation
for the value it is. The unification isn't a way of thinking about the
language. It's what the tool already does.

Once you have it, four things stop being separate rules to carry. `DOMAIN`
works on a record, a sequence, and a function because there's one operator
and one kind of argument. `EXCEPT` works on all three for the same reason.
`r.a` is sugar for `r["a"]`, so a record lookup and a function application
are the same operation. And a function set and a struct set build the same
set, which the colon-and-arrow section below measures.

## `:>` and `@@` are how TLA+ writes a function with no pattern

A function literal needs a binding pattern, so it needs a domain you can
describe. `[i \in 2..4 |-> i]` is fine. A function over `{2, 5, 11}` with
unrelated values has no pattern to write, and that is what `:>` and `@@` are
for. `:>` builds a one-pair function and `@@` joins two of them.

```tla
---- MODULE Merge ----
EXTENDS Integers, TLC
VARIABLE f

\* A function with a gappy domain, built one pair at a time.
Init == f = 2 :> 20 @@ 5 :> 50
Next == f' = f @@ (11 :> 110)
Spec == Init /\ [][Next]_<<f>>

\* On a key both sides hold, the LEFT operand wins.
LeftWins == (f @@ (2 :> 999))[2] = 20
RightWins == (f @@ (2 :> 999))[2] = 999

\* :> builds a one-pair function, and @@ joins them into a literal's equal.
Singleton == (7 :> "v") = [i \in {7} |-> "v"]
Dense == (2 :> 2 @@ 3 :> 3 @@ 4 :> 4) = [i \in 2..4 |-> i]

\* The domain is whatever was named, with no pattern to fit.
Gaps == DOMAIN f \subseteq {2, 5, 11}

\* The three notations TLC prints a function in, asserted as equalities. A
\* domain of 1..n prints as a sequence and a domain of strings as a record,
\* so what the printer picks is the shortest notation the domain allows.
Printed == /\ [i \in 1..3 |-> i * i] = <<1, 4, 9>>
           /\ [i \in {"p", "q"} |-> 1] = [p |-> 1, q |-> 1]

Holds == LeftWins /\ Singleton /\ Dense /\ Gaps /\ Printed
=====================
```

`INVARIANT Holds` exits 0 at 2 distinct states. Two things in there are worth
pulling out.

The first is that `@@` keeps the left operand's value on a shared key. That
reads backwards if you come from a language where updating a map writes right
over left, which Python's `dict.update` and JavaScript's object spread both
do. `f @@ g` is a default-filling merge rather than an update, so `g @@ f` is
the one that behaves like an assignment. Running the module with
`INVARIANT RightWins` exits 12, and the trace carries the argument:

```
Error: Invariant RightWins is violated by the initial state:
f = (2 :> 20 @@ 5 :> 50)
```

The second is how TLC printed `f` in that trace. `:>` and `@@` aren't a
corner of the `TLC` module you can skip. They're the notation TLC falls back
to when a function is neither a sequence nor a record, so you'll meet them in
an error trace whether or not you ever type one. Printing the same function
three times on this build, with only its domain changed:

| the function | what TLC printed |
|---|---|
| `[i \in 1..3 \|-> i * i]` | `<<1, 4, 9>>` |
| `[i \in {"p", "q"} \|-> 1]` | `[p \|-> 1, q \|-> 1]` |
| `[i \in 2..4 \|-> i]` | `(2 :> 2 @@ 3 :> 3 @@ 4 :> 4)` |

Same construct every time. The printer picks the shortest notation the domain
allows, which is the unification again, now in the output channel. The
`Printed` conjunct above asserts the first two of those as equalities, so the
suite holds the values. What the printer chooses to show is TLC's own, and the
trace quoted above is where you can see it.

## `EXCEPT` and `@`, and the clauses run left to right

`[f EXCEPT ![k] = v]` is a copy of `f` with one position changed. The `!` is
the selector and `@` inside the clause is the value `f` already held at the
position the selector names. So `@` is what lets you write an increment
without naming the function twice:

```tla
---- MODULE Meter ----
EXTENDS Integers
VARIABLE m

Keys == {"a", "b"}

\* A record whose count field is itself a function.
Init == m = [count |-> [k \in Keys |-> 0], last |-> "none"]

\* @ is the value at the position the selector names, so the increment
\* never spells the function out a second time. Two clauses, one step.
Tick(k) == m' = [m EXCEPT !.count[k] = @ + 1, !.last = k]

Next == \E k \in Keys : Tick(k)
Spec == Init /\ [][Next]_<<m>>
Cap == m.count["a"] + m.count["b"] <= 2

\* Two clauses on the SAME key. The second @ reads the first clause's
\* result, not the value the step started from: 10 then 100 lands on 110.
Chain == [m.count EXCEPT !["a"] = @ + 10, !["a"] = @ + 100]
Chained == Chain["a"] = m.count["a"] + 110
Naive == Chain["a"] = m.count["a"] + 100

\* The nested selector is the two-level form written short.
Nested == [m EXCEPT !.count["a"] = @ + 1]
            = [m EXCEPT !.count = [@ EXCEPT !["a"] = @ + 1]]

Holds == Chained /\ Nested
=====================
```

`INVARIANT Holds` exits 0 at 7 distinct states. Three things that module
pins down.

The selector nests, and `@` follows it down. `!.count[k]` reaches through a
record into the function it holds, and the `@` there is the leaf number
rather than the whole `count` function. The `Nested` conjunct asserts that the
short form and the explicit two-level form are the same value, and it holds.
Writing one `EXCEPT` per level is always available, and I only reach for it
when the short form stops being readable.

One `EXCEPT` can carry several clauses, and they apply in order. This is the
part that surprised me. `@` in a later clause sees the result of the earlier
ones, not the value the step started from. So
`[f EXCEPT !["a"] = @ + 10, !["a"] = @ + 100]` adds 110 rather than 100. The
module asserts the 110 reading and it passes. Swapping to `INVARIANT Naive`,
which asserts the 100 reading, exits 12. Clauses on different keys can't tell
the difference, so I think this only bites when two clauses touch the same
position, which is rare and worth knowing about when it happens.

A record of functions is the normal shape for per-key state. `count` is a
function and `m` is a record holding it, so one variable carries both the
counters and the bookkeeping. That's cheaper than two variables, since every
subscript and every `UNCHANGED` then names one thing.

## `EXCEPT` outside the domain changes nothing, and reading outside it stops the run

Here is the trap worth the most on this page, because the failure is silent
and the state count is the only thing that reports it.

`EXCEPT` on a position that isn't in the domain drops the clause. The result
is the function you started with, unchanged. No error, and the run exits 0.
The obvious way to meet this is reaching for `EXCEPT` to append to a sequence:

```tla
---- MODULE Grow ----
EXTENDS Integers, Sequences
VARIABLE q

Init == q = <<>>

\* The operator that appends.
Push == q' = Append(q, 1)

\* The EXCEPT that reads as though it appends. Len(q) + 1 is one past the
\* end of the domain, so the clause is dropped and q never moves.
Reach == q' = [q EXCEPT ![Len(q) + 1] = 1]

SpecPush  == Init /\ [][Push]_<<q>>
SpecReach == Init /\ [][Reach]_<<q>>

Cap == Len(q) <= 3
=====================
```

`SPECIFICATION SpecPush` exits 0 at 4 distinct states, which is the empty
sequence and three longer ones. `SPECIFICATION SpecReach` exits 0 at 1
distinct state. Both runs pass. The spec that never does anything is the one
that looks right.

What you get instead of an error is a warning, and it names the line:

```
Warning: The EXCEPT was applied to non-existing fields of the value at
line 12, col 16 to line 12, col 16 of module Grow
(Use the -nowarning option to disable this warning.)
```

A misspelled record field is the same failure in a different costume:

```tla
---- MODULE Typo ----
EXTENDS Integers
VARIABLE r

Init == r = [hits |-> 0, misses |-> 0]

\* "hit" is not a field of r. The clause is dropped, @ is never evaluated,
\* and the record stays where it started.
Next == r' = [r EXCEPT !.hit = @ + 1]

Spec == Init /\ [][Next]_<<r>>
=====================
```

Exit 0, 1 distinct state, same warning text. Note that `@ + 1` never runs.
The whole clause goes, so the `@` is not evaluated and does not complain
about having nothing to be. A spec whose counter never moves and whose only
sign is a warning in the scrollback is a bad afternoon.

Now the other direction, which behaves nothing like it. Reading outside the
domain is a hard error:

```tla
---- MODULE Outside ----
EXTENDS Integers, Sequences
VARIABLE q

Init == q = <<10, 20>>
Next == UNCHANGED q
Spec == Init /\ [][Next]_<<q>>

\* Reading one past the end. The same out-of-domain index that EXCEPT
\* dropped in silence stops the run here.
Past == q[Len(q) + 1] = 0
=======================
```

That exits 75, which is a different kind of exit code from the rest of this
page:

```
Error: Attempted to access index 3 of tuple
<<10, 20>>
which is out of bounds.
While working on the initial state:
q = <<10, 20>>

Error: TLC was unable to fingerprint.
```

75 means TLC couldn't evaluate an expression, so the run stopped rather than
reaching a verdict. There's no pass and no fail in it. That matters if you
read exit codes in a script, because 75 is neither 0 nor 12, and treating
anything non-zero as a violation reports a crash as a counterexample.

So the same mistake, the same index, one position past the end, is loud when
you read and silent when you write. I don't know why the language chose that
split. The practical rule I use is that `EXCEPT` never grows a function, so
anything that should change a domain needs `Append`, `@@`, or a fresh literal.

## The bracket form recurses and the operator form does not

`Name[x \in S] == expr` is sugar for `Name == [x \in S |-> expr]`, and it has
one property the plain operator form lacks. It can call itself, with no
`RECURSIVE` declaration:

```tla
---- MODULE Recurse ----
EXTENDS Integers
VARIABLE n

\* The bracket form. It calls itself, and there is no RECURSIVE line.
Fact[i \in 0..5] == IF i = 0 THEN 1 ELSE i * Fact[i - 1]

\* Sugar for the same thing, written as a literal.
FactLit == [i \in 0..5 |-> IF i = 0 THEN 1 ELSE i * Fact[i - 1]]

Init == n = 0
Next == n' = (n + 1) % 6
Spec == Init /\ [][Next]_<<n>>

\* The same form over an infinite domain. TLC evaluates lazily, so applying
\* it costs nothing. Forcing the whole value would not terminate.
Up[i \in Nat] == IF i = 0 THEN 0 ELSE Up[i - 1] + 1

Known == Fact[0] = 1 /\ Fact[5] = 120
Grows == Fact[n] >= n
Sugar == Fact = FactLit
Domain == DOMAIN Fact = 0..5
Infinite == Up[4] = 4

Holds == Known /\ Grows /\ Sugar /\ Domain /\ Infinite
=======================
```

Exit 0 at 6 distinct states, and `Sugar` confirms the bracket form and the
literal are the same value. Write the same definition as an operator and it
doesn't parse:

```tla
Fact(i) == IF i = 0 THEN 1 ELSE i * Fact(i - 1)
```

Exit 150, one error:

```
line 7, col 37 to line 7, col 40 of module RecurseOp

Unknown operator: `Fact'.
```

The message is worth reading closely, because it doesn't say what's wrong. It
says `Fact` is unknown, at a point inside the definition of `Fact`. The cause
is that a definition isn't in scope inside its own body, and the operator form
needs a `RECURSIVE Fact(_)` line ahead of it to put it there. The bracket form
needs nothing, which is the one real asymmetry between the two.

The `Up` definition in that module is the same form over `Nat`, and the
`Infinite` conjunct asserting `Up[4] = 4` passes. TLC evaluates lazily rather
than building the function, so an infinite domain costs nothing until
something asks for the whole value. I'd treat that as a convenience and not
lean on it, since anything that forces the function, such as putting it in a
variable, won't terminate.

## `[a : S]` is a set and `[a |-> v]` is one value

The colon and the arrow sit one keystroke apart and build different kinds of
thing. `[a |-> 1]` is one record. `[a : S]` is the set of every record whose
`a` field is drawn from `S`. A type invariant wants the second, and reaching
for the first is the mistake this section is about.

```tla
---- MODULE Typed ----
EXTENDS Integers
VARIABLE f

Keys == {"a", "b"}
Vals == 0..2

\* [Keys -> Vals] is the SET of every function from Keys to Vals. Its size
\* is 3 to the power of 2, and each member is one initial state.
Init == f \in [Keys -> Vals]
Next == UNCHANGED f
Spec == Init /\ [][Next]_<<f>>

\* The colon form. This is a set, so it is what \in wants.
ByColon == f \in [a : Vals, b : Vals]

\* The arrow form. This is one record whose fields hold sets, not a set of
\* records, so \in has nothing to search.
ByArrow == f \in [a |-> Vals, b |-> Vals]

\* The two set-building forms agree when the keys are the same.
SameSet == [Keys -> Vals] = [a : Vals, b : Vals]

Holds == ByColon /\ SameSet
=====================
```

`INVARIANT Holds` exits 0 at 9 distinct states. Two findings there.

`SameSet` holds, so the function-set and struct-set forms build the same set.
`[{"a", "b"} -> 0..2]` and `[a : 0..2, b : 0..2]` are one set written two
ways, which is the unification carried up to the typing layer. Use whichever
reads better. The arrow form takes its keys as a set, so it's the one that
works when the keys come from a constant.

The 9 is the arithmetic, and it's why a function set is a state-space
decision rather than a notation choice. A function set holds one member per
assignment of values to keys, so its size is the number of values raised to
the number of keys. Here that's 3 to the power of 2. Put one in `Init` and
every member is an initial state, so a 4-key function over 5 values is 625
initial states before the first step.

Writing the arrow where the colon belonged exits 75, and TLC names the
problem:

```
Error: Attempted to check if element:
[a |-> 0, b |-> 0]
is in the record:
[a |-> 0..2, b |-> 0..2]
```

"Is in the record" is the diagnosis. `\in` wanted a set on the right and got a
record whose fields happen to hold sets. The value is well formed and means
something, so nothing catches it until TLC tries to search it.

## A record built from the variables is for display, not for asserting

One more thing about records, and it comes from the corpus rather than from
TLC. Building a record whose fields are the spec's variables is a real idiom
with a real job, and the job is not stating a property.

The survey of 666 modules found 176 definitions with a record body of two or
more fields. 10 of them are wired to `ALIAS`, which rewrites the state TLC
shows you in an error trace. 0 are wired to `VIEW`. And 0 are declared as an
`INVARIANT` or a `PROPERTY` in any configuration file the survey could
resolve. So in the specs that survey read, a record built from the variables
is always a display mechanism and never an obligation.

The confusion is easy to fall into, because both mechanisms produce a record
named after the state and they look interchangeable. They aren't.
`[q |-> queue, c |-> count]` under `ALIAS` changes what a counterexample
prints. The same expression can't assert anything, since a record is a value
and an obligation needs a formula. So if you find yourself gathering the
variables into a record to say something about them, what you want is a
conjunction of the claims instead. Reach for the record when a trace is hard
to read. `ALIAS` is a configuration-file keyword, so it sits with the
state-space and configuration material rather than here.

## Where this is taught

Chapter 6, Structured Data, introduces the struct literal, the struct set,
`DOMAIN`, the function literal, `:>`, `@@`, and the function set. It builds to
the same reveal this page opens with, which is the one thing to take from it
if you take one. Chapter 10, More Operators, adds the bracket definition and
recursion through it, next to the `RECURSIVE` keyword that the operator form
needs and the bracket form doesn't.

`EXCEPT` and `@` arrive late, in chapter 12, TLA+, because they turn up there
as the way an action changes one field of a record without restating the
others. That's a gap of six chapters from the rest of the family, and it's
worth knowing about if you go looking for `EXCEPT` and expect it beside the
function material. Chapter 6 names three topics it defers, and `EXCEPT` isn't
one of them, so there's nothing to tell you it's still coming.
