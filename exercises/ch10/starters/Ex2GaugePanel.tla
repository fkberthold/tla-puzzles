---------------------------- MODULE Ex2GaugePanel ----------------------------
\* Starter for exercise 2, "The gauge panel".
\* Replace the six stubs. Leave the scaffolding alone.
\*
\* Every stub parses and every stub is wrong, so this module goes red before
\* you touch it. Run it first and watch it fail.

EXTENDS Integers, FiniteSets

Gauges == {12, 28, 41, 55}

\* ---------------- answer block, this is what you write ----------------

\* Three operators that take another operator as an argument. The parameter
\* lists are already written for you, and they are the part worth reading:
\* `Op(_)` marks an argument as an operator rather than a value, and the
\* `(_)` says that operator takes one argument of its own.

Mapped(Op(_), set) == {}

Kept(Test(_), set) == {}

Chained(F(_), G(_), x) == 0

\* Three call sites. Build the operator argument on the spot with LAMBDA
\* rather than naming it first.

Trimmed == {}

OverLine == {}

Rescaled == 0

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
