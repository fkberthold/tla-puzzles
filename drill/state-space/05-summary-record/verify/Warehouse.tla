---------------------------- MODULE Warehouse ----------------------------
EXTENDS Naturals, FiniteSets, TLC

CONSTANTS Items, Stock, PerItem

ASSUME Stock \in [Items -> Nat]
ASSUME PerItem \in BOOLEAN

VARIABLE reserved

vars == <<reserved>>

RECURSIVE Sum(_, _)
Sum(f, S) ==
    IF S = {} THEN 0
    ELSE LET x == CHOOSE x \in S : TRUE IN f[x] + Sum(f, S \ {x})

TotalStock == Sum(Stock, Items)
TotalHeld == Sum(reserved, Items)

TypeOK == reserved \in [Items -> 0..TotalStock]

Init == reserved = [i \in Items |-> 0]

\* PerItem = FALSE is the bug: the guard reads the total, so one item can be
\* reserved past its own stock while another has slack.
Reserve(i) ==
    /\ IF PerItem THEN reserved[i] < Stock[i] ELSE TotalHeld < TotalStock
    /\ reserved' = [reserved EXCEPT ![i] = @ + 1]

Cancel(i) ==
    /\ reserved[i] > 0
    /\ reserved' = [reserved EXCEPT ![i] = @ - 1]

Next == \E i \in Items : Reserve(i) \/ Cancel(i)

Spec == Init /\ [][Next]_vars

\* The summary. A record built from the state, which is what a dashboard
\* shows and what a trace is easier to read through. It is a value, not a
\* claim, and none of the four config keywords that can name it turns it
\* into one.
Summary == [free |-> TotalStock - TotalHeld, held |-> TotalHeld]

\* The summary with the raw state kept alongside, for ALIAS.
Shown == [free |-> TotalStock - TotalHeld, held |-> TotalHeld, reserved |-> reserved]

\* The claim. Boolean, reads the state, named under INVARIANT.
NoOverReserve == \A i \in Items : reserved[i] <= Stock[i]

\* A claim stated over the summary. Also boolean. It is weaker than the one
\* above and holds on the buggy system, which is the point: a summary that
\* adds things up cannot see a per-item fault.
SummaryIsSane == Summary.free >= 0 /\ Summary.held <= TotalStock

\* The wrong knob for this model: the items are NOT interchangeable, since
\* Stock tells them apart. Named in a .cfg as SYMMETRY ItemPerms.
ItemPerms == Permutations(Items)

==========================================================================
