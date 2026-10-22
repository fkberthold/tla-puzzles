# Sequences

A sequence is an ordered finite list of values, written `<<a, b, c>>`. It is
also a function on the integer interval `1..Len(s)`, and that second sentence
is the one this page keeps coming back to.

Reach for one when the order is part of the problem. A queue, a log, a message
channel and a call stack are all sequences. The eight operators in the
standard `Sequences` module are shaped for exactly those jobs.

The state space is what it costs. Every distinct ordering is a distinct state,
and a sequence with no bound on its length gives TLC nothing to stop at.

Every module on this page is a real file under
`core-language-docs/snippets/`, and `run-all.sh` beside them checks each one
against the exit code and the state count quoted here. Measured on TLC
2026.07.31.184830 on 2026-10-22.

The operator list below is the whole export list of `Sequences.tla` as it
ships inside `tla2tools.jar`. I read it out of the jar rather than off a cheat
sheet, and that matters here more than on most pages. Chapter 2's cheat sheet
names six of the eight, and `Seq` and `SelectSeq` appear in none of the 12
chapter cheat sheets in this project. I read that as a gap in the chapter
material rather than a statement about the two operators.

## The constructs

| Construct | Shape | What it means | In published specs |
|---|---|---|---|
| sequence literal | `<<a, b, c>>`, indexed with `seq[n]`, 1-indexed | an ordered finite list, which is a function on `1..Len(s)` | 375 definitions have a plain tuple of names as their body |
| `Len` | `Len(s)` | how many elements `s` holds | not counted |
| `Head` | `Head(s)` | the first element, which is `s[1]` | not counted |
| `Tail` | `Tail(s)` | all but the first element, re-indexed from 1 | not counted |
| `Append` | `Append(s, x)` | `s` with `x` added at the end as one element | not counted |
| `\o` | `s \o t` | the elements of `s` followed by the elements of `t` | not counted |
| `SubSeq` | `SubSeq(s, m, n)` | the slice `<<s[m], ..., s[n]>>`, re-indexed from 1 | not counted |
| `SelectSeq` | `SelectSeq(s, Test(_))` | the elements `Test` holds for, in order, re-indexed from 1 | not counted |
| `Seq` | `Seq(S)` | the set of every finite sequence over `S`, which is infinite | not counted |

One of the nine rows carries a figure, and it's about tuples rather than about
an operator. The survey behind that column read 666 modules and 337
configuration files from 16 public repositories on 2026-09-05. None of its
passes counted a sequence operator. So "not counted" means the survey has no
number for the construct, which isn't the same as the construct being rare.
Each count in the sections below is one I measured on this build.

That one figure is worth reading twice. It counts the most common sequence
literal in published TLA+, and nobody calls it one. `vars == <<x, y, z>>` is a
sequence, and 181 of those 375 definitions are named `vars`.

## A sequence is a function on `1..Len(s)`, so it's indexed from one

`DOMAIN` over a sequence hands back an integer interval, and the interval
starts at 1:

```
tlc -repl 'DOMAIN <<10, 20, 30>>'
1..3
```

That isn't a convenience of the printer. A sequence and a function are the
same kind of value, and the equality holds:

```
tlc -repl '<<10, 20, 30>> = [i \in 1..3 |-> 10 * i]'
TRUE
```

So everything on the functions and records page applies to a sequence,
`EXCEPT` included. `Conveyor` loads a belt, clears it when it's full, and
states four readings of the same fact:

```tla
---- MODULE Conveyor ----
EXTENDS Integers, Sequences
VARIABLE belt

Init == belt = <<>>
Load == Len(belt) < 3 /\ belt' = Append(belt, Len(belt) + 1)
Clear == Len(belt) = 3 /\ belt' = <<>>
Next == Load \/ Clear
Spec == Init /\ [][Next]_<<belt>>

IsFunction == DOMAIN belt = 1..Len(belt)
Numbered == \A i \in DOMAIN belt : belt[i] = i
FirstIsHead == belt = <<>> \/ Head(belt) = belt[1]
Patched == belt = <<>> \/ [belt EXCEPT ![1] = 99][1] = 99
ZeroIndexed == belt = <<>> \/ belt[0] = belt[1]
=========================
```

The first four exit 0 over 4 distinct states. `IsFunction` is the domain
claim. `Numbered` indexes with `belt[i]` and never calls an operator.
`FirstIsHead` says `Head` is `belt[1]` and nothing beyond that. `Patched` runs
an `EXCEPT` over a sequence position and reads the result back.

Index 0 is where a zero-indexed habit lands first, and it's outside the
domain. With `INVARIANT ZeroIndexed` the run exits 76:

```
Error: Evaluating invariant ZeroIndexed failed.
Attempted to access index 0 of tuple
<<1>>
which is out of bounds.
Error: The behavior up to this point is:
State 1: <Initial predicate>
belt = <<>>

State 2: <Load line 6, col 9 to line 6, col 60 of module Conveyor>
belt = <<1>>
```

Read the message rather than the code. It says "out of bounds" where a plain
function application outside its domain says something else, so TLC knows it
is holding a tuple. The empty sequence has an empty domain and not a domain of
`{0}`:

```
tlc -repl 'DOMAIN <<>>'
{}
```

`EXCEPT` on a sequence has one trap of its own, and it sits with the functions
family rather than here. A clause on a position one past the end is dropped
and the run stays clean. So the obvious way to append with `EXCEPT` leaves the
sequence exactly where it was. See
[Functions and records](functions-records.md), which carries the measurement
and the state counts that report it.

## `Seq(S)` is infinite, so it works as a test and fails as a source

This is the one failure on the page that stops a run before anything useful
happens, and the definition says why. `Sequences.tla` line 20 inside
`tla2tools.jar` reads:

```tla
Seq(S) == UNION {[1..n -> S] : n \in Nat}
```

One function set per length, unioned over every natural number. `Nat` is
infinite, so the union is infinite whatever `S` is, and TLC won't walk it.

The part that surprises people is how much still works. Membership is a test
rather than a draw, and TLC answers it:

```
tlc -repl '<<1, 2, 3>> \in Seq(1..3)'
TRUE
```

`Spool` winds a wire in two colors, up to two turns:

```tla
---- MODULE Spool ----
EXTENDS Integers, Sequences
VARIABLE wire

Colors == {"red", "blue"}
Cap == 2

BoundedSeq(S, n) == UNION {[1..i -> S] : i \in 0..n}

Init == wire = <<>>
Wind == Len(wire) < Cap /\ \E c \in Colors : wire' = Append(wire, c)
Next == Wind \/ UNCHANGED wire
Spec == Init /\ [][Next]_<<wire>>

InitAny == wire \in Seq(Colors)
SpecAny == InitAny /\ [][Next]_<<wire>>

TypeOK == wire \in Seq(Colors)
Bounded == wire \in BoundedSeq(Colors, Cap)
Enumerated == \E s \in Seq(Colors) : s = wire
======================
```

With `INVARIANT TypeOK` that run exits 0 over 7 distinct states. So an
unbounded `Seq(S)` as a type invariant is fine, and needs no length bound to
work. `INVARIANT Bounded` exits 0 over the same 7 states, which is the
agreement worth having: the finite union checks every state the infinite set
checks.

Put a quantifier over it and the run stops. With `INVARIANT Enumerated` it
exits 75, and TLC spends a paragraph on it:

```
Error: TLC encountered the non-enumerable quantifier bound
Seq({"red", "blue"})
line 20, col 24 to line 20, col 34 of module Spool
In TLA+, Seq(S) represents the set of all finite sequences whose elements come from the set S. Even when S
is a finite set, the number of possible sequences in Seq(S) is unbounded because sequences can have any
finite length (e.g., length 0, 1, 2, and so on). As a result, TLC cannot evaluate expressions that
universally (\A) or existentially (\E) quantify over Seq({"red", "blue"}), because this would require checking an
infinite number of cases. Note that for a finite set of sequences s, TLC handles s \subseteq Seq(S).
See https://explain.tlapl.us/seq-unenumerable for additional details.
While working on the initial state:
wire = <<>>
```

Drawing the variable out of it in `Init` is the same refusal one phase
earlier. `SPECIFICATION SpecAny` exits 75 with a shorter message and no state
at all:

```
Error: In computing initial states, the right side of \IN is not enumerable.
line 15, col 12 to line 15, col 31 of module Spool
Error: The error occurred when TLC was evaluating the nested
expressions at the following positions:
0. Line 15, column 12 to line 15, column 31 in Spool
0 states generated, 0 distinct states found, 0 states left on queue.
```

So the rule is about which side of the membership the unknown sits on. A
sequence you already have, tested against `Seq(S)`, is one evaluation. A
sequence TLC has to produce from `Seq(S)` is an infinite search.

When you do need a source, write the bounded union the module's own definition
is built from:

```
tlc -repl 'LET Big(S, n) == UNION {[1..i -> S] : i \in 0..n} IN Big({1, 2}, 2)'
{<<>>, <<1>>, <<2>>, <<1, 1>>, <<1, 2>>, <<2, 1>>, <<2, 2>>}
```

That's `Seq(S)` with `Nat` swapped for `0..n`, and it's a finite set TLC
will draw from. `BoundedSeq` above is the same operator under a name.

Two more things `Seq(S)` won't do, and both read as though they should.
Cardinality is refused, and so is a comparison against an ordinary set:

```
tlc -repl 'Cardinality(Seq({}))'
Error evaluating expression: 'Cardinality(Seq({}))'
tlc2.tool.EvalException: Attempted to compute cardinality of the value
Seq({})
```

```
tlc -repl 'Seq({}) = {<<>>}'
Error evaluating expression: 'Seq({}) = {<<>>}'
Attempted to compare overridden value Seq({}) with non-overridden value: {<<>>}
```

`Seq({})` is mathematically `{<<>>}`, one member, and TLC refuses it anyway.
I read that as the override being opaque rather than as a claim about the
empty set, since nothing in the message mentions `S`. The containment the
error message recommends works, as long as the enumerable side is on the
left:

```
tlc -repl '{<<>>, <<1>>} \subseteq Seq({1})'
TRUE
```

```
tlc -repl 'Seq({1}) \subseteq Seq({1, 2})'
Error evaluating expression: 'Seq({1}) \subseteq Seq({1, 2})'
Attempted to evaluate an expression of form S \subseteq T, but S was not enumerable.
```

## `Append` adds one element and `\o` joins two sequences

`Append(s, x)` puts `x` at the end as a single element, whatever `x` is. Hand
it a sequence and you get a sequence nested inside a sequence:

```
tlc -repl 'Append(<<1, 2>>, <<3>>)'
<<1, 2, <<3>>>>
```

```
tlc -repl '<<1, 2>> \o <<3>>'
<<1, 2, 3>>
```

The module defines one in terms of the other. `Sequences.tla` line 36 is
`Append(s, e) == s \o <<e>>`, so the `<<e>>` wrapper is the entire difference
between them. `Pallet` stacks layers both ways at once:

```tla
---- MODULE Pallet ----
EXTENDS Integers, Sequences
VARIABLES stack, flat
vars == <<stack, flat>>

Layer == <<7, 8>>

Init == stack = <<>> /\ flat = <<>>
Add ==
  /\ Len(stack) < 2
  /\ stack' = Append(stack, Layer)
  /\ flat' = flat \o Layer
Next == Add \/ UNCHANGED vars
Spec == Init /\ [][Next]_vars

AppendNests == \A i \in DOMAIN stack : stack[i] = Layer
ConcatFlattens == \A i \in DOMAIN flat : flat[i] \in {7, 8}
LengthsTrack == Len(flat) = 2 * Len(stack)
SameLength == Len(stack) = Len(flat)
=======================
```

The first three exit 0 over 3 distinct states. Every element of `stack` is a
whole `Layer`, every element of `flat` is a number, and `flat` runs twice as
long. `SameLength` is the claim somebody writes when they have reached for the
wrong one of the two, and it exits 12:

```
Error: Invariant SameLength is violated.
Error: The behavior up to this point is:
State 1: <Initial predicate>
/\ flat = <<>>
/\ stack = <<>>

State 2: <Add line 10, col 3 to line 12, col 26 of module Pallet>
/\ flat = <<7, 8>>
/\ stack = <<<<7, 8>>>>
```

`stack = <<<<7, 8>>>>` is the readable part of that trace. Six angle brackets
in a row is what a nesting mistake looks like on screen. It's the first thing
to look for when a length comes out half or double what you expected.

The trap is sharper when the element is a one-element sequence.
`Append(s, <<3>>)` and `s \o <<3>>` differ by one layer, which prints as two
extra brackets in a value you were scanning past. Both are legal and neither
warns.

## `Head` and `Tail` stop the run on the empty sequence

Both operators are undefined on `<<>>` and TLC says so rather than returning
something. `Crate` unpacks a one-item crate and then has an empty one:

```tla
---- MODULE Crate ----
EXTENDS Integers, Sequences
VARIABLE crate

Init == crate = <<"bolt">>
Unpack == crate /= <<>> /\ crate' = Tail(crate)
Next == Unpack \/ UNCHANGED crate
Spec == Init /\ [][Next]_<<crate>>

GuardedHead == crate /= <<>> => Head(crate) = "bolt"
GuardedTail == crate /= <<>> => Len(Tail(crate)) = Len(crate) - 1
BareHead == Head(crate) = "bolt"
BareTail == Tail(crate) = <<>>
======================
```

The two guarded claims exit 0 over 2 distinct states. `BareHead` exits 76:

```
Error: Evaluating invariant BareHead failed.
Attempted to apply Head to the empty sequence.
Error: The behavior up to this point is:
State 1: <Initial predicate>
crate = <<"bolt">>

State 2: <Unpack line 6, col 11 to line 6, col 47 of module Crate>
crate = <<>>
```

`BareTail` exits 76 with the same shape and `Tail` in place of `Head`. So the
fix is the guard, and `crate /= <<>> => ...` is the normal way to write it.

Now read what the module promises, because it's less than what you got.
`Sequences.tla` line 41 is `Head(s) == s[1]`, which on `<<>>` is a function
application outside its domain. Line 42 is stranger:

```tla
Tail(s) == CASE s # << >> -> [i \in 1..(Len(s)-1) |-> s[i+1]]
```

A `CASE` with one arm and no `OTHER`. On the empty sequence no arm holds, and
a `CASE` where nothing holds is undefined in TLA+. Neither line promises an
error message, and the comment two lines down records why it's written that
way:

```
(* The usual head (first) and tail (rest) operators. (Definition of Tail *)
(* changed on 4 Jun 2013 because original defined Tail(<< >>) = << >> .  *)
```

So `Tail(<<>>)` used to answer `<<>>` and somebody decided the quiet answer
was worse than none. I think they were right, and the reason is the whole
argument of this page's last section: an answer you didn't want costs more to
find than a stopped run.

What you actually see comes from neither line. Lines 9 through 12 of the same
file say the definitions in it "are all overridden by TLC in the Java class
`tlc2.module.Sequences`". So the messages above are TLC's rather than the
module's. Reading the TLA+ text tells you where a value is undefined. It
doesn't tell you what you'll be shown.

## `SubSeq` clips nothing, and a backwards range is quietly empty

A slice inside the domain is the slice you asked for, re-indexed from 1:

```
tlc -repl 'DOMAIN SubSeq(<<10, 20, 30>>, 2, 3)'
1..2
```

A range that runs backwards is the empty sequence, with no complaint:

```
tlc -repl 'SubSeq(<<10, 20, 30>>, 3, 1)'
<<>>
```

An index outside the domain stops the run. `Trim` holds a three-element tape
and states both halves:

```tla
---- MODULE Trim ----
EXTENDS Integers, Sequences
VARIABLE tape

Full == <<10, 20, 30>>

Init == tape = Full
Next == UNCHANGED tape
Spec == Init /\ [][Next]_<<tape>>

Middle == SubSeq(tape, 2, 3) = <<20, 30>>
OneElement == SubSeq(tape, 2, 2) = <<20>>
Backwards == SubSeq(tape, 3, 1) = <<>>
BackwardsReindexed == DOMAIN SubSeq(tape, 2, 3) = 1..2
PastTheEnd == SubSeq(tape, 1, 5) = Full
BeforeTheStart == SubSeq(tape, 0, 2) = <<10, 20>>
=====================
```

The first four exit 0 over 1 distinct state. `PastTheEnd` exits 75:

```
Error: The third argument of SubSeq must be in the domain of its first argument:
<<10, 20, 30>>
, but instead it is
5
```

`BeforeTheStart` exits 75 too, naming the second argument and the value 0.
That is the bound a zero-indexed habit reaches for, and it fails the same way
the upper one does.

So the asymmetry is the thing to carry away. A backwards range is empty and a
bound outside the domain is fatal, and they aren't two readings of one rule.
The definition at line 48 shows why:

```tla
SubSeq(s, m, n) == [i \in 1..(1+n-m) |-> s[i+m-1]]
```

When `n` is below `m` the interval `1..(1+n-m)` is empty, so the function is
the empty function and `s` is never touched. When the interval is non-empty
it reads every position in the interval, and a position outside the domain is
where it stops. The empty sequence settles which of those is happening:

```
tlc -repl 'SubSeq(<<>>, 1, 0)'
<<>>
```

Index 1 isn't in the empty domain and the answer is still `<<>>`. So the
bounds are checked only when the slice has something in it. That makes the
drop-the-last-element idiom safe without a guard, which I think is the useful
consequence:

```
tlc -repl 'SubSeq(<<10>>, 1, 0)'
<<>>
```

`SubSeq(s, 1, Len(s) - 1)` is that expression for a one-element `s`, and on
`<<>>` it becomes `SubSeq(<<>>, 1, -1)`, which also answers `<<>>`.

## A string is half a sequence, and which half depends on the operator

TLC treats a string as a sequence of characters under four of the module's
eight operators and refuses it under three. The two function operations, `[i]`
and `DOMAIN`, refuse it as well:

| what you write | on `"abc"` |
|---|---|
| `Len(label)` | `3` |
| `Tail(label)` | `"bc"` |
| `SubSeq(label, 2, 3)` | `"bc"` |
| `label \o "d"` | `"abcd"` |
| `Head(label)` | stops the run |
| `Append(label, "d")` | stops the run |
| `SelectSeq(label, Test)` | stops the run |
| `label[1]` | stops the run |
| `DOMAIN label` | stops the run |

`Barge` carries one string and states all nine:

```tla
---- MODULE Barge ----
EXTENDS Integers, Sequences
VARIABLE label

Init == label = "abc"
Next == UNCHANGED label
Spec == Init /\ [][Next]_<<label>>

StringLen == Len(label) = 3
StringTail == Tail(label) = "bc"
StringSub == SubSeq(label, 2, 3) = "bc"
StringConcat == label \o "d" = "abcd"

StringHead == Head(label) = "a"
StringAppend == Append(label, "d") = "abcd"
StringIndex == label[1] = "a"
StringDomain == DOMAIN label = 1..3
======================
```

The first four exit 0 together over 1 distinct state. Each of the other four
exits 75 on its own, and the messages come from three different places:

```
Error: The argument of Head should be a sequence, but instead it is:
"abc"
```

```
Error: Evaluating an expression of the form Append(s, v) when s is not a sequence:
"abc"
```

```
Error: Attempted to apply the operator DOMAIN to a non-function
(a string)
```

Put the first row and the last row together and you have a value with a length
and no domain. No function can be that. The four that work hand back a string
rather than a sequence, so the value never converts:

```
tlc -repl 'Tail("abc") \in STRING'
TRUE
```

A string is a member of `STRING` and not a member of `Seq(STRING)`, and asking
the second question is itself refused:

```
tlc -repl '"abc" \in Seq(STRING)'
Error evaluating expression: '"abc" \in Seq(STRING)'
tlc2.tool.EvalException: Attempted to check if the value:
"abc"
is an element of Seq(STRING).
```

So I'd read the four that work as a convenience TLC offers over an opaque
value. They aren't a claim that a string is a sequence.

The consequence worth watching for is a type invariant that passes over the
wrong kind of value. `Len(q) <= 3` holds of `"abc"` as readily as of
`<<1, 2, 3>>`. So a length bound alone doesn't establish that `q` is a
sequence. `q \in Seq(Vals)` does, and the section above measures it exiting 0.

## `SelectSeq` takes an operator, not a condition

The second parameter is declared `Test(_)` at line 53, and that underscore is
the whole story. It wants a one-argument operator, so you pass a name or a
`LAMBDA` and never a boolean expression. `Sorter` filters a line of numbers
both legal ways:

```tla
---- MODULE Sorter ----
EXTENDS Integers, Sequences
VARIABLE line

Big(x) == x > 20

Init == line = <<10, 30, 20, 40>>
Next == UNCHANGED line
Spec == Init /\ [][Next]_<<line>>

Kept == SelectSeq(line, Big) = <<30, 40>>
KeptByLambda == SelectSeq(line, LAMBDA x : x > 20) = <<30, 40>>
Reindexed == DOMAIN SelectSeq(line, Big) = 1..2
NoneKept == SelectSeq(line, LAMBDA x : FALSE) = <<>>
OrderHeld == \A i \in 1..1 : SelectSeq(line, Big)[i] < SelectSeq(line, Big)[i + 1]
=======================
```

All five exit 0 over 1 distinct state. The named operator and the `LAMBDA`
give the same answer. The result is a sequence on `1..2`, not one with gaps
where `10` and `20` were. Keeping nothing gives `<<>>` rather than an error.

Write the condition inline and it fails before any state is computed, at
exit 150:

```
*** Errors: 2

line 9, col 25 to line 9, col 36 of module SorterExpr
An expression appears as argument number 2 (counting from 1) to operator 'SelectSeq', in a position an operator is required.

line 9, col 9 to line 9, col 37 of module SorterExpr
Argument number 2 to operator 'SelectSeq' 
should be a 1-parameter operator.
```

Two errors for one mistake, and the second one names what it wanted. This is
the only operator in the module that takes an operator. It's also the only one
defined by recursion rather than in a line, at lines 58 through 65.
`SelectSeq` is in none of this project's 12 chapter cheat sheets, which is
most of why it's worth its own section here.

## The same failure reports two exit codes, depending on when it happens

12 of this page's 22 runs are evaluation failures. 8 of them exit 75 with no
behavior printed and 4 exit 76 with the behavior printed. The split tracks
when the failure happened rather than what failed. Every 75 above failed while
TLC was working on the initial state. Every 76 failed on a state reached by a
step.

One matched pair pins it rather than leaving it as a pattern. `Trim` with
`INVARIANT PastTheEnd` and `Conveyor` with `INVARIANT SlicePastEnd` are the
same out-of-domain `SubSeq` failure on the same build. `Trim` has one state,
so it fails on the initial one and exits 75. `Conveyor` reaches it on the
second state and exits 76:

```
Error: Evaluating invariant SlicePastEnd failed.
The third argument of SubSeq must be in the domain of its first argument:
<<1>>
, but instead it is
4
Error: The behavior up to this point is:
State 1: <Initial predicate>
belt = <<>>

State 2: <Load line 6, col 9 to line 6, col 60 of module Conveyor>
belt = <<1>>
```

Same operator, same message, two codes. In practice a 75 hands you no trace,
so there's nothing to read about how you got there. The state you want is
whatever `Init` admits. A 76 hands you the path.

I haven't sourced TLC's rule for choosing between them, so treat this as 12
runs on one build rather than as documented behavior. The direction is worth
knowing either way. A reader who sees 75 and goes hunting for the trace will
spend a while on a report that never had one.

## Where this is taught

learntla's operators chapter, which this project's chapter 2 exercise set
follows. Both of this family's cheat-sheet entries arrive there, the literal
with its 1-indexing and a bundle of six module operators. Chapter 2's own
summary line puts them together as "ordered, 1-indexed value lists, with a
small module of helper operators".

Chapter 6 is where the function half lands, and its cheat sheet calls it the
reveal of the chapter. Sequences and structures both turn out to be functions,
sequences over `1..n` and structures over a set of strings. `DOMAIN` is named
there as the one operation that works on all three. Chapters 3 and 5 both
defer variable-length sequences to chapter 6 rather than covering them.

Two chapters use the module without teaching it. Chapter 8 needs
`EXTENDS Sequences` for PlusCal procedures, since the call stack a procedure
needs is a sequence. Chapter 13 uses `Sequences` as its stand-in import
throughout and says in as many words that the operators belong to chapter 2.

The standard module's own reference page is
[Sequences](../modules/Sequences.md). It lists the same eight operators and is
the shorter read when you want a signature rather than a failure mode. One
entry there asks for a `Len(s) <= N` bound in `TypeOK` to deal with `Seq(T)`
being infinite. The measurement in this page's second section says the
unbounded membership test exits 0 without one. I'd read that entry as advice
about `Init`, where the bound is needed, rather than about the invariant.

The function side of all this, `DOMAIN` and `EXCEPT` and what happens outside
a domain, is on [Functions and records](functions-records.md). I put the
one-based rule here because it's the thing a reader coming from a zero-indexed
language gets wrong first. That page's version of it is one line inside a
larger argument.
