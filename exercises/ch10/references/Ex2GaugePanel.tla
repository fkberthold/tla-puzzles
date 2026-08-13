---------------------------- MODULE Ex2GaugePanel ----------------------------
\* Reference answer for exercise 2, "The gauge panel".
\* Everything below the answer block is scaffolding. Leave it alone.

EXTENDS Integers, FiniteSets

Gauges == {12, 28, 41, 55}

\* ---------------- answer block, this is what you write ----------------

\* Three operators that take another operator as an argument. The `Op(_)`
\* in the parameter list is what marks the argument as an operator rather
\* than a value, and the `(_)` says it takes one argument of its own.

Mapped(Op(_), set) == { Op(x) : x \in set }

Kept(Test(_), set) == { x \in set : Test(x) }

Chained(F(_), G(_), x) == F(G(x))

\* Three call sites. Each one builds its operator argument on the spot with
\* LAMBDA instead of naming it first.

Trimmed == Mapped(LAMBDA g: g - 12, Gauges)

OverLine == Kept(LAMBDA g: g >= 40, Gauges)

Rescaled == Chained(LAMBDA a: a \div 2, LAMBDA b: b - 12, 28)

\* ---------------- scaffolding below this line ----------------

\* The spec needs one variable so TLC has a state to check the invariant in.
\* It never changes.
VARIABLE probe

Init == probe = 0
Next == UNCHANGED probe

\* The `probe = 0` line is load bearing. Without it every conjunct is a
\* constant, TLC folds the whole invariant away before the run starts, and a
\* wrong answer comes back as a config error instead of a violation.
PanelIsRight ==
    /\ probe = 0
    /\ Trimmed = {0, 16, 29, 43}
    /\ OverLine = {41, 55}
    /\ Rescaled = 8
    /\ Cardinality(Trimmed) = 4
    /\ Cardinality(OverLine) = 2

===========================================================================
