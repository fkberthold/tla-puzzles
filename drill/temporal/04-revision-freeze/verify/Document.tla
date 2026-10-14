---- MODULE Document ----
\* The answer to drill item 04-revision-freeze, plus the wrong neighbors as
\* named alternatives. Steps.tla instantiates this module and checks each
\* formula against the step table from the prompt.
EXTENDS Naturals

VARIABLES rev, published

vars == <<rev, published>>

Init == /\ rev = 0
        /\ published = FALSE

Edit == /\ ~published
        /\ rev' = rev + 1
        /\ UNCHANGED published

Publish == /\ ~published
           /\ published' = TRUE
           /\ UNCHANGED rev

Next == Edit \/ Publish

Spec == Init /\ [][Next]_vars

\* The two halves of Spec, checked separately against the table: the init
\* rows are one-state behaviors and the step rows start mid-history.
NextBox == [][Next]_vars

\* Neighbors. Each is the answer with one thing wrong.
EditNoGuard     == rev' = rev + 1 /\ UNCHANGED published
EditNoUnchanged == ~published /\ rev' = rev + 1
EditGt          == ~published /\ rev' > rev /\ UNCHANGED published
PublishToggle   == published' = ~published /\ UNCHANGED rev

NoGuardBox     == [][EditNoGuard \/ Publish]_vars
NoUnchangedBox == [][EditNoUnchanged \/ Publish]_vars
GtBox          == [][EditGt \/ Publish]_vars
ToggleBox      == [][Edit \/ PublishToggle]_vars
ConjBox        == [][Edit /\ Publish]_vars
SubRevBox      == [][Next]_rev
SubPubBox      == [][Next]_published

InitNoRev == published = FALSE
InitNoPub == rev = 0
====
