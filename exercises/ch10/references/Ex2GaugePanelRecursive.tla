-------------------------- MODULE Ex2GaugePanelRecursive --------------------------
\* Exercise 2, the side experiment. This is the exercise 2 reference with one
\* line added: a RECURSIVE declaration for `Mapped`, whose first parameter is
\* an operator.
\*
\* The chapter warns that recursive and higher-order operators do not
\* combine. This module is where that warning is a parse error you can see.
\* SANY rejects the DECLARATION, not the definition, and it never gets as far
\* as the body: `RECURSIVE` accepts only bare `_` placeholders, so the moment
\* it reads the `(` inside `_(_)` it stops and says it wanted a comma or a
\* closing bracket.

EXTENDS Integers, FiniteSets

Gauges == {12, 28, 41, 55}

\* ---------------- the added line, and the answer block ----------------

RECURSIVE Mapped(_(_), _)
Mapped(Op(_), set) == { Op(x) : x \in set }

Kept(Test(_), set) == { x \in set : Test(x) }

Chained(F(_), G(_), x) == F(G(x))

Trimmed == Mapped(LAMBDA g: g - 12, Gauges)

OverLine == Kept(LAMBDA g: g >= 40, Gauges)

Rescaled == Chained(LAMBDA a: a \div 2, LAMBDA b: b - 12, 28)

\* ---------------- scaffolding below this line ----------------

VARIABLE probe

Init == probe = 0
Next == UNCHANGED probe

PanelIsRight ==
    /\ probe = 0
    /\ Trimmed = {0, 16, 29, 43}
    /\ OverLine = {41, 55}
    /\ Rescaled = 8
    /\ Cardinality(Trimmed) = 4
    /\ Cardinality(OverLine) = 2

===========================================================================
