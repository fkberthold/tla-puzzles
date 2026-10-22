# Core operators

This family is what you write in every spec, whatever the spec is about. It
holds operator definitions, the boolean operators and the two quantifiers. It
also holds `IF`, `CASE`, `LET` and `RECURSIVE`, which are how a definition's
body gets any structure.

None of it is optional, so there's no trade to weigh here the way there is with
modules. What there is instead is a split in how the mistakes arrive. Half of
this page is about bodies the parser refuses outright, and the other half is
about bodies that check clean and assert nothing. The second half is the
expensive one.

Every module on this page is a real file under
`core-language-docs/snippets/`, and `run-all.sh` beside them checks each one
against the exit code and the state count quoted here. Measured on TLC
2026.07.31.184830 on 2026-10-22.

## The constructs

| Construct | Shape | What it means | In published specs |
|---|---|---|---|
| operator definition | `Name(a, b) == expr`, or `Name == expr` with no arguments | binds a name to an expression, with a fixed number of arguments | 238 modules define `Next` |
| `IF`-`THEN`-`ELSE` | `IF cond THEN a ELSE b` | picks one of two values, and both branches must have a value | not counted |
| equality | `a = b`, `a # b` | claims two expressions are, or are not, the same value | not counted |
| integers | `123`, `-4`, with `EXTENDS Integers` for arithmetic | integer literals, and the operators come from a module | not counted |
| strings | `"double quoted text"` | a string value, which TLC will not compare to a number | not counted |
| booleans | `TRUE`, `FALSE`, `/\`, `\/`, `~` | the two values and the three connectives | not counted |
| bullet notation | stacked `/\` or `\/` lines, where column alignment decides the arms | the same connectives laid out so nesting is unambiguous | 105 of 238 `Next` definitions |
| implication | `A => B` | true whenever `A` is false, whatever `B` says | not counted |
| `LET`-`IN` | `LET x == expr IN body`, several definitions allowed | names a subexpression for the body only | not counted |
| `\A` | `\A x \in S : P(x)` | `P` holds for every element, and holds when `S` is empty | not counted |
| `\E` | `\E x \in S : P(x)` | `P` holds for some element, and fails when `S` is empty | 69 of 238 `Next` definitions |
| `RECURSIVE` | `RECURSIVE Op(_)` above `Op(x) == ...` | puts `Op` in scope inside its own body | not counted |
| higher-order parameter | `Name(Op(_), arg) == ... Op(arg) ...` | takes an operator as an argument rather than a value | not counted |
| `LAMBDA` | `LAMBDA x : expr`, only as an argument | an unnamed operator, written at the call site | not counted |
| custom infix operator | `a ++ b == expr` | defines one of TLA+'s spare symbols as your own operator | not counted |
| `CASE` | `CASE c1 -> v1 [] c2 -> v2 [] OTHER -> vN` | picks the value of a matching arm, and `OTHER` is optional | not counted |

Three of the sixteen carry a figure, all three from a survey of 666 modules and
337 configuration files drawn from 16 public repositories, read on 2026-09-05.
"Not counted" means that survey has no number for the construct, which isn't
the same as the construct being rare. Every one of these sixteen turns up in
nearly every spec, so I'd read this column as the least useful one on the page.

## Mixing `/\` and `\/` on one line does not parse

The two connectives share a precedence and don't associate with each other, so
there's no grouping for the parser to pick. It refuses the file rather than
guess. `Mixed.tla` line 12:

```tla
Ok == n = 0 /\ n < 5 \/ n = 1 /\ n < 5
```

`tlc -config Mixed.cfg Mixed.tla` exits 150:

```
***Parse Error***

  Precedence conflict between ops \land in block line 12, col 13 to line 12, col 14 of module Mixed and \lor.
```

I think that's a better fact to carry than a precedence table, because the
checker is doing the work for you. There's nothing to remember.

Two forms parse. Parentheses around each conjunction, and the bullet layout:

```tla
Paren == (n = 0 /\ n < 5) \/ (n = 1 /\ n < 5)

Bullet == \/ /\ n = 0
             /\ n < 5
          \/ /\ n = 1
             /\ n < 5
```

`Grouped.tla` holds both and asserts `Same == Paren = Bullet` as an invariant.
That run exits 0 over 3 distinct states, so the two forms agree in every state
the model reaches.

The bullet form decides its arms by column alignment, which is why it scales
where the one-line form doesn't. In the 666-module survey, 105 of the 238
modules that define `Next` write it as a bulleted disjunction of named actions,
and a further 69 as an existential over one parameterized action. So the layout
isn't a beginner's crutch. It's what most published specs use for their
top-level action.

## `=` is a claim about one state, and the prime is what makes it a step

`=` never assigns. It says two expressions are the same value. So an action
body that forgets the prime is a claim about a single state, and `n = n + 1` is
false of every integer. `Assign.tla` carries both bodies:

```tla
\* A claim about one state. It is false of every integer.
Unprimed == n = n + 1

\* A claim about a pair of states. This is the one that moves.
Primed == n' = n + 1
```

With `NEXT Unprimed` TLC computes the initial state and stops, exit 11:

```
Error: Deadlock reached.
Error: The behavior up to this point is:
State 1: <Initial predicate>
n = 0
```

TLC generated one state, found one distinct state and left nothing on the
queue. The same module with `NEXT Primed` exits 0 over 3 distinct states.

Deadlock is the symptom, and it's a confusing one, because nothing in the
message mentions the prime. On a spec with one action I'd read "Deadlock
reached" as a missing prime before I looked anywhere else.

Both configs use the `INIT` and `NEXT` keywords rather than `SPECIFICATION`.
53 of the 337 configuration files in the survey do the same, so it's a normal
form and not a shortcut for snippets.

## A true implication can say nothing at all

`A => B` is true whenever `A` is false, whatever `B` says. That's the
definition and it isn't a quirk. The cost is that an invariant shaped like an
implication passes in two different ways, and the exit code is 0 either way.

`Vacuous.tla` is a tank with a gate on it:

```tla
\* The requirement as a reader would state it.
Safe == (gate = "open") => (level > 0)

\* The witness. It holds exactly when Safe has nothing to say.
NeverOpen == gate # "open"
```

The `Open` action is guarded by a constant, so one module gives both readings.
With `CanOpen = FALSE` the gate never opens, and `INVARIANT Safe` exits 0 over
4 distinct states. `INVARIANT NeverOpen` exits 0 over the same 4. The second
run is what tells you the first one meant nothing. The antecedent was never
true, so TLC checked `FALSE => ...` four times and found it true four times.

Flip the constant to `TRUE` and the same `Safe` fails on the first step, exit
12:

```
Error: Invariant Safe is violated.
Error: The behavior up to this point is:
State 1: <Initial predicate>
/\ level = 0
/\ gate = "shut"

State 2: <Open line 13, col 9 to line 15, col 25 of module Vacuous>
/\ level = 0
/\ gate = "open"
```

So the invariant was right all along and the model was wrong. That's the shape
to watch for: the formula you wrote is fine, and the spec never puts it to
work.

Worth being plain about the logic, because `FALSE => anything` surprises people
and the arithmetic doesn't help. A vacuously true implication is true. It's a
true statement that tells you nothing about the world, the same way every
elephant in my pocket is pink. Truth and information content are different
things, and TLC reports only the first.

Which means vacuity is measured rather than spotted. A second invariant that
holds exactly when the antecedent fails is the cheapest instrument there is,
and it costs one TLC run. `NeverOpen` above is one.

## The same empty set makes `\A` true and `\E` false

`\A x \in S : P(x)` is true when `S` is empty, and `\E x \in S : P(x)` is
false. Both follow from the definitions, and both tend to arrive as a surprise.
`Quantify.tla` starts with an empty set and grows it once:

```tla
Init == s = {}
Grow == s = {} /\ s' = {1}

AllNeg == \A x \in s : x < 0
SomeNeg == \E x \in s : x < 0
```

`INVARIANT AllNeg` exits 12, and the trace shows where it broke:

```
Error: Invariant AllNeg is violated.
Error: The behavior up to this point is:
State 1: <Initial predicate>
s = {}

State 2: <Grow line 6, col 9 to line 6, col 26 of module Quantify>
s = {1}
```

State 1 passed. There was nothing in `s` to be negative, so the claim held.
`INVARIANT SomeNeg` on the same module also exits 12, and fails at state 1
instead:

```
Error: Invariant SomeNeg is violated by the initial state:
s = {}
```

Same emptiness, opposite verdicts. The universal is the vacuity case from the
section above wearing different syntax, since a bounded `\A` is an implication
underneath. The existential over nothing is just false.

The practical reading: a `\A` invariant that passes on a spec whose collections
start empty has told you about the empty case, and nothing more, until you've
checked that the collection fills.

## TLA+ is untyped, and TLC's equality isn't total

There's no type system, so a variable can hold an integer in one state and a
string in the next. `Untyped.tla` does exactly that:

```tla
Init == box = 0
Flip == box' = IF box = 0 THEN "zero" ELSE 0
```

TLC computes that without complaint, generating 2 states and finding 2 distinct
ones. The type change itself raises nothing at all.

What isn't total is the comparison. `0 = "0"` is not FALSE:

```
Error: Attempted to check equality of integer 0 with non-integer:
"0"
While working on the initial state:
box = 0
```

Exit 75, with no behavior to show, because the failure landed in the
initial-state pass. This project's chapter 2 cheat sheet says `=` and `#` are
the operators that work across types. I'd read that as a claim about the
language rather than about TLC, since the checker refuses this comparison
instead of returning a value for it.

A type invariant can't catch the change either. All three forms I tried fail to
evaluate rather than report a violation, and each one says so differently:

| invariant | exit | the tail of what TLC says |
|---|---|---|
| `box \in Int` | 76 | `is an element of Int` |
| `box \in 0..3` | 76 | `is in the integer interval 0..3` |
| `box \in {0, 1, 2, 3}` | 76 | `check equality of integer 0 with non-integer` |

The set literal is the interesting row, because its message names equality
rather than membership. Membership is decided by comparing elements, so `\in`
inherits whatever `=` can't do. The exit code is 76 rather than 75 on all
three, and the only difference from the bare comparison above is that TLC had a
behavior to print by the time it failed.

Where that leaves `TypeOK`. It earns its keep on a spec whose actions preserve
types, where it catches the value you didn't expect inside the kind you did.
It's not a guard against an action that returns the wrong kind of value. That
failure arrives as exit 76 from whatever reads the variable next, which can be
a long way from the action that caused it. 117 of the 713 invariant
declarations in the survey are named `TypeOK`, which is 16.4%, so the construct
is doing real work. Just not this work.

## A `CASE` with no matching arm stops the run

`CASE` is not an `IF` chain with an implicit else. With no `OTHER` arm and
nothing matching, the expression has no value and TLC gives up. `Grade.tla`:

```tla
Band == CASE score = 1 -> "low"
          [] score = 2 -> "mid"
          [] score = 3 -> "high"
```

At `score = 0`, with an invariant that reads `Band`:

```
Error: Attempted to evaluate a CASE with no conditions true.
line 10, col 9 to line 12, col 32 of module Grade
While working on the initial state:
score = 0
```

Exit 75, the same evaluation failure as the cross-type comparison above and for
the same reason. The expression doesn't denote. Adding `[] OTHER -> "none"`
takes the same module to exit 0 over 4 distinct states.

The other half is what happens when two arms both match:

```tla
Overlap == CASE score >= 1 -> "first"
             [] score >= 2 -> "second"
```

Both are true at `score = 2` and at `score = 3`. The invariant
`score < 1 \/ Overlap = "first"` exits 0 over 4 distinct states, so TLC took
the first arm in every state. I'd rely on that only as far as this build, since
I don't have a source in front of me that fixes the order in the language
itself. Write arms that can't overlap and the question doesn't come up.

## `RECURSIVE` is a declaration, not a termination check

An operator can't refer to itself unless you say so first. Without the
declaration the name isn't in scope yet, and `NoRecursive.tla` fails at
semantic analysis:

```tla
Sum(k) == IF k = 0 THEN 0 ELSE k + Sum(k - 1)
```

```
line 6, col 36 to line 6, col 38 of module NoRecursive

Unknown operator: `Sum'.
```

Exit 150. Put `RECURSIVE Sum(_)` above it and the same body checks clean.

What the declaration doesn't do is promise the recursion ends. `Depth.tla`
carries two operators whose only difference is the step:

```tla
RECURSIVE SumDown(_)
SumDown(k) == IF k = 0 THEN 0 ELSE k + SumDown(k - 1)

RECURSIVE SumEven(_)
SumEven(k) == IF k = 0 THEN 0 ELSE k + SumEven(k - 2)
```

`SumDown(4)` reaches the base case and the run exits 0. `SumEven(3)` steps over
it, going 3, 1, -1, -3 and onward:

```
Error: This was a Java StackOverflowError. It was probably the result
of an incorrect recursive function definition that caused TLC to enter
an infinite loop when trying to compute the function or its application
to an element in its putative domain.
```

Exit 75 again, and it arrives in under a second, so this isn't a hang you sit
through. Notice that the base case is a single value rather than a bound.
`k = 0` catches a walk down by one, and misses a walk down by two from an odd
start. `k <= 0` catches both.

## A `LAMBDA` is an argument and never a name

A higher-order parameter is written `Op(_)`, and it takes an operator rather
than a value. `Apply.tla`:

```tla
MapTwo(Op(_), a, b) == <<Op(a), Op(b)>>
```

Two things satisfy it. A named operator, passed with no argument list after it,
and a `LAMBDA` written at the call site:

```tla
Named == MapTwo(Twice, n, n + 1) = <<n * 2, n * 2 + 2>>
Inline == MapTwo(LAMBDA k: k * 2, n, n + 1) = <<n * 2, n * 2 + 2>>
```

Both hold in every state, and the run exits 0 over 3 distinct states.

What a `LAMBDA` can't do is get a name. `Double == LAMBDA k: k * 2` doesn't
parse:

```
***Parse Error***
Was expecting "Expression or Instance"
Encountered "LAMBDA" at line 6, column 11 and token "=="
```

Exit 150. Nothing is lost there, since `Double(k) == k * 2` is the same
operator with a name, and that's what you write. `LAMBDA` is for the case where
naming it buys nothing.

A custom infix operator has a narrower limit. `a ++ b == a + b * 2` works, and
`Apply.tla` asserts `(n ++ 3) = n + 6` alongside the two above. An invented
name in the same position does not work:

```tla
a plus b == a + b * 2
```

```
***Parse Error***
Was expecting "==== or more Module body"
Encountered "a" at line 6, column 1 and token "n"
```

Exit 150. The symbol has to be one TLA+ already reserves for the purpose.
Notice where the parser lands. It reads the line as the start of something that
isn't a definition at all, so the message points at column 1 rather than at
`plus`, and the name you chose never appears in the error.

## `RECURSIVE` and higher-order do combine, and the declaration says less than you'd think

This one came out differently from how I expected it to, so the measurement
goes first. `RecHigher.tla` defines an operator that is both recursive and
higher-order:

```tla
RECURSIVE Walk(_, _)
Walk(Op(_), k) == IF k = 0 THEN 0 ELSE Op(k) + Walk(Op, k - 1)
```

`Summed == Walk(Twice, n) = n * (n + 1)` holds in every state. Exit 0 over 4
distinct states, so the recursion ran for `n` of 0, 1, 2 and 3 and got the
right answer each time.

This project's chapter 10 cheat sheet says the two features don't combine. On
this build they do, at least in this shape, and I'd treat the cheat-sheet line
as the one to fix rather than this measurement.

What doesn't work is describing the parameter in the declaration.
`RECURSIVE Walk(_(_), _)` is a parse error:

```
***Parse Error***
Was expecting "comma or )"
Encountered "(" at line 8, column 17 and token "_"
```

Exit 150. One underscore per parameter is all the declaration carries, and the
shape of a higher-order parameter comes from the definition below it. So the
declaration says less than it looks like it says, and that turns out to be
enough.

## Where this is taught

learntla's operators chapter, which this project's chapter 2 exercise set
follows, covers nine of the sixteen: the definition form, `IF`, `=` and `#`,
integers, strings, the boolean operators, the bullet layout, implication and
`LET`. The two quantifiers arrive in chapter 4 alongside invariants, since an
invariant over a collection is where you first need one. `RECURSIVE`,
higher-order parameters, `LAMBDA`, custom infix operators and `CASE` are
chapter 10.

For arithmetic and the integer operators themselves, see
[Integers](../modules/Integers.md), since the literals are built in and the
operators are not. The bullet layout turns up on nearly every page of
[Refinement](../../chapter/refinement.md), which is a better place to read it
at length than any snippet here.
