---- MODULE SeedDrill ----
\* Exercise 1 reference answer.
\*
\* A pure TLA+ spec, written directly. There is no PlusCal anywhere in this
\* file, so nothing here is a translation of anything and there is no `pcal`
\* step.
\*
\* The shape of the module is the chapter's blueprint: declare the variables,
\* tuple them into `vars`, say what the first state looks like, say what a
\* step looks like, and glue the two together with `[][Next]_vars`.
EXTENDS Integers

Capacity == 4
SeedsPerRow == 2
MaxRows == 3

VARIABLES hopper, rows

\* Every variable, once, in one tuple. This is what the subscript on the box
\* refers to.
vars == << hopper, rows >>

Init == /\ hopper = Capacity
        /\ rows = 0

\* An action is a boolean operator containing a primed variable. Nothing here
\* is an assignment. `hopper' = hopper - SeedsPerRow` is a claim about the
\* pair of states, true exactly when the step drops the hopper by one row's
\* worth of seed.
Plant == /\ rows < MaxRows
         /\ hopper >= SeedsPerRow
         /\ hopper' = hopper - SeedsPerRow
         /\ rows' = rows + 1

\* Refilling plants nothing, so `rows` has to be pinned explicitly. Drop the
\* UNCHANGED and the action stops describing `rows` at all, which does not
\* make the spec weaker. It makes it unevaluable.
Refill == /\ hopper < SeedsPerRow
          /\ hopper' = Capacity
          /\ UNCHANGED rows

Next == Plant \/ Refill

Spec == Init /\ [][Next]_vars

HopperInRange == hopper \in 0..Capacity
RowsInRange == rows \in 0..MaxRows
====
