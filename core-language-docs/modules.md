# Modules

A module is one `.tla` file. This family is the two ways to pull another module
into yours, plus the ways an import can be named, hidden, or handed parameters.

Most specs never need any of it. A spec under a few hundred lines sits in one
file without trouble, and learntla puts its modules chapter last for that
reason. Three things pay for a split. A library you want to reuse, invariants
you want kept away from the system they constrain, and an abstract spec you
intend to refine against.

Every module on this page is a real file under
`core-language-docs/snippets/`, and `run-all.sh` beside them checks each one
against the exit code and the state count quoted here. Measured on TLC
2026.07.31.184830 on 2026-10-21.

## The constructs

| Construct | Shape | What it means | In published specs |
|---|---|---|---|
| `EXTENDS` | `EXTENDS Integers, Sequences` | drops the named modules into this file's namespace | not counted |
| `LOCAL` | `LOCAL Op == ...` | keeps `Op` out of any module that imports this one | not counted |
| `INSTANCE` | `INSTANCE Sequences`, on a line of its own | same namespace effect as `EXTENDS`, and a module may have many | 190 of 666 modules |
| `LOCAL INSTANCE` | `LOCAL INSTANCE Naturals` | the import works here and stops here | not counted |
| named instance | `Foo == INSTANCE Sequences` | binds the import to a name instead of the file namespace | not counted |
| `!` | `Foo!Append(seq, 1)` | reads one definition out of a named instance | not counted |
| `INSTANCE ... WITH` | `Origin == INSTANCE Point WITH X <- 0, Y <- 0` | supplies the imported module's parameters | 43 of 250 `INSTANCE` occurrences |
| partial parameterization | `XAxis(X) == INSTANCE Point WITH Y <- 0`, called as `XAxis(2)!Add(x, y)` | leaves a parameter open and takes it at the call site | not counted |

Two of the eight carry a figure. Both come from a survey of 666 modules and
337 configuration files drawn from 16 public repositories, read on 2026-09-05.
"Not counted" means that survey has no number for the construct, which is not
the same as the construct being rare. The sections below carry counts of their
own where I could measure one.

## `EXTENDS Sequences` does not give you arithmetic

This is the first one most people hit, and the cause is a `LOCAL INSTANCE` in
a file you never opened.

8 of the 12 public standard modules shipped inside `tla2tools.jar` reach their
own dependencies with `LOCAL INSTANCE` rather than `EXTENDS`. `Sequences.tla`
line 15 is `LOCAL INSTANCE Naturals`. `LOCAL` is what stops an import
traveling, so `Naturals` gets as far as `Sequences` and no further.

So this module parses nothing:

```tla
---- MODULE NoArith ----
EXTENDS Sequences
VARIABLE q

Init == q = <<>>
Push == q' = Append(q, Len(q) + 1)
Next == Push
Spec == Init /\ [][Next]_<<q>>

Cap == Len(q) <= 2
========================
```

`Len` and `Append` resolve. `+` and `<=` do not:

```
*** Errors: 4

line 6, col 31 to line 6, col 31 of module NoArith
Could not find declaration or definition of symbol '+'.

line 10, col 15 to line 10, col 16 of module NoArith
Could not find declaration or definition of symbol '<='.
```

Four errors for two symbols. Each one is reported twice, once against the
symbol and once as a failure to resolve the infix operator around it.

The fix is `EXTENDS Integers, Sequences`. The reason `Integers` behaves
differently is that `Integers.tla` line 16 is a plain `EXTENDS Naturals`, with
no `LOCAL`, so everything `Naturals` defines passes straight through.

Worth knowing that none of the 12 uses a plain `INSTANCE`. Inside the standard
library the local form is the normal one, which is the opposite of how a spec
author writes imports.

## One `EXTENDS` line per module, and that is why `INSTANCE` exists

Two `EXTENDS` lines is a parse error rather than a merge:

```
***Parse Error***
Was expecting "==== or more Module body"
Encountered "EXTENDS" at line 3, column 1 and token "Integers"
```

A module gets one `EXTENDS` and as many `INSTANCE` lines as it likes. That is
the practical difference between them, ahead of anything about namespacing.

## Every parameter needs a substitution, and the error points at the import

A module's `CONSTANT` and `VARIABLE` declarations are its formal parameters.
`WITH` supplies the arguments. Miss one and you get a semantic error before
any state is computed.

`Tank` declares a constant and a variable:

```tla
---- MODULE Tank ----
EXTENDS Integers
CONSTANT Capacity
ASSUME Capacity \in Nat

VARIABLE tank

Init == tank = 0
Pour == tank < Capacity /\ tank' = tank + 1
Drain == tank > 0 /\ tank' = tank - 1
Next == Pour \/ Drain
Spec == Init /\ [][Next]_<<tank>>
=====================
```

On its own, with `Capacity = 3`, that is 4 distinct states. This imports it
twice and substitutes the constant only:

```tla
---- MODULE TwoTanks ----
EXTENDS Integers
VARIABLES level1, level2
vars == <<level1, level2>>

T1 == INSTANCE Tank WITH Capacity <- 3
T2 == INSTANCE Tank WITH Capacity <- 3

Init == T1!Init /\ T2!Init
Next == (T1!Next /\ UNCHANGED level2) \/ (T2!Next /\ UNCHANGED level1)
Spec == Init /\ [][Next]_vars
=========================
```

`tlc TwoTanks.tla` exits 150 with two errors, one per import:

```
line 6, col 1 to line 6, col 38 of module TwoTanks
Substitution missing for symbol tank declared at line 6, col 10 to line 6,
col 13 of module Tank and instantiated in module TwoTanks.
```

The error names the symbol it wants and the line it wants it on, which is
better than most of TLA+'s messages. Notice which line that is. It points at
the `INSTANCE` on line 6, not at `T1!Init` on line 9 where you were working.
Adding `tank <- level1` and `tank <- level2` to the two `WITH` clauses is the
whole fix, and takes the model to 16 distinct states.

A parameter the two modules share by name is passed through for free. So a
`WITH` clause is only needed where the names differ, or where you want to
choose the value. The refinement chapter covers substituting for variables at
length, including what a mapping has to preserve to mean anything. See
[Refinement](../../chapter/refinement.md).

## You cannot name a module's variable from outside

A formal parameter has no value until it is substituted, so there is nothing
behind `T1!tank` to read. Writing this into the module above, with both
substitutions correct:

```tla
Reach == T1!tank + T2!tank <= 6
```

gives exit 150 and one error per reference:

```
Unknown operator: `tank'.
```

The qualifier is gone from the message. It reads as though you had written a
bare `tank`, which is roughly what happened. The lookup failed on the inner
name rather than on the instance. Write `level1 + level2 <= 6` instead, since
those are the expressions you substituted and they are the state you actually
have.

This is also why a missing substitution tends to arrive as a pile of errors.
The two real failures are the imports, and every `!` reference downstream adds
another line to the report.

## Substitution is on the parse tree, not on the text

This one changes what your spec says, and nothing in the error channel will
tell you, because there is no error.

`Tally` has one variable and one action:

```tla
---- MODULE Tally ----
EXTENDS Integers
VARIABLE total

Bump == total' = total + 1
======================
```

Substituting an expression for that variable rewrites `Bump` into the
instantiating module's state:

```tla
---- MODULE Split ----
EXTENDS Integers
VARIABLES a, b
vars == <<a, b>>

T == INSTANCE Tally WITH total <- a + b

Init == a = 0 /\ b = 0
BumpA == a' = a + 1 /\ b' = b
BumpB == b' = b + 1 /\ a' = a
Next == BumpA \/ BumpB
Spec == Init /\ [][Next]_vars

Cap == a <= 2 /\ b <= 2

Tree == [][T!Bump <=> (a' + b' = a + b + 1)]_vars
Text == [][T!Bump <=> (a + b' = a + b + 1)]_vars
======================
```

`T!Bump` is `(a + b)' = (a + b) + 1`, and priming an expression primes every
variable in it. So the substituted action is `a' + b' = a + b + 1`. A text
macro would have replaced the characters `total` and left the prime where it
sat, giving `a + b' = a + b + 1`.

Both readings are written above as properties, and TLC separates them. With
`PROPERTY Tree` the run is clean, exit 0, 9 distinct states at depth 5. With
`PROPERTY Text` it exits 13:

```
Error: Action property Text is violated.
Error: The behavior up to this point is:
State 1: <Initial predicate>
/\ a = 0
/\ b = 0

State 2: <BumpA line 9, col 10 to line 9, col 29 of module Split>
/\ a = 1
/\ b = 0
```

The counterexample is the first step. `BumpA` raises `a` by one, so `T!Bump`
holds, while `a + b'` has not moved and the text reading is false. The two
formulas agree on any step that changes only one variable of the expression.
That is why this can sit in a spec a long time unnoticed.

## Two instances on one variable is one variable with two names

Pointing two imports at the same expression does not give you two of
something. It gives you one piece of state under two names, and a step through
either name moves what the other one reads.

Measured on `Tank` above, with `Capacity <- 3` both times. Two variables,
`tank <- level1` and `tank <- level2`, gives 16 distinct states at depth 7.
One variable, `tank <- level` in both clauses, gives 4 distinct states at
depth 4. Four is the state space of a single tank.

Both runs exit 0. If you are modeling two tanks and seeing a single tank's
numbers, this is the first thing to check, and the state count is the signal.
There is no error to read.

## A bare `INSTANCE` passes everything through by name

With no `WITH` at all, every parameter is matched to a same-named declaration
in the instantiating module. That works even when your module declares more
state than the imported one:

```tla
---- MODULE TankPlusClock ----
EXTENDS Integers
CONSTANT Capacity
VARIABLES tank, clock
vars == <<tank, clock>>

T == INSTANCE Tank

Init == T!Init /\ clock = 0
Next == T!Next /\ clock' = clock + 1
Spec == Init /\ [][Next]_vars

Cap == clock <= 4
==============================
```

Exit 0, 8 distinct states. `Tank` knows nothing about `clock` and constrains
nothing about it, so what you get is the imported spec with the extra
variables ignored. That is the identity-shaped case, and it is worth
recognizing because it looks like it should need a `WITH` and does not.

## Partial parameterization, and where the documentation stops

`XAxis(X) == INSTANCE Point WITH Y <- 0` leaves `X` open and turns the
instance itself into an operator, called as `XAxis(2)!Add(x, y)`. Leaving a
constant open this way is documented.

Leaving a **variable** open is not. learntla's modules chapter reserves that
technique behind a `todo` marker at `modules.rst:137` and never delivers it.
So actions imported from a module get named there and never taught. I have not
found a worked treatment of it anywhere else either, and I would treat it as
unexplored rather than unavailable.

## Where this is taught

learntla's modules chapter, which this project's chapter 13 exercise set
follows. `EXTENDS` itself is introduced in chapter 2, and the
`---- MODULE Name ----` through `====` boilerplate in chapter 1. Variable
substitution, the half this page spends most of its words on, is in
[Refinement](../../chapter/refinement.md) rather than in any modules material.
That chapter ships its own worked pair, `Till` and `TwoTills`, which uses the
same `a + b` mapping to make a refinement claim rather than to show the
substitution rule.
