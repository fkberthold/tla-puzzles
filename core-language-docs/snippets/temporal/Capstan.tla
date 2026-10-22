---- MODULE Capstan ----
EXTENDS Integers
VARIABLES turn, hauled
vars == <<turn, hauled>>

Init == turn = 0 /\ hauled = FALSE

\* The capstan swings back and forth whether or not anybody takes the rope.
Swing == /\ turn' = 1 - turn
         /\ hauled' = hauled

\* The rope can only be taken at one end of the swing.
Haul == /\ turn = 1
        /\ ~hauled
        /\ hauled' = TRUE
        /\ turn' = turn

Next == Swing \/ Haul

\* Fairness on the whole next-state relation. It asks for some step.
Moving == Init /\ [][Next]_vars /\ WF_vars(Next)

\* Weak fairness on Haul, which asks for an action eventually always enabled.
Weak == Init /\ [][Next]_vars /\ WF_vars(Swing) /\ WF_vars(Haul)

\* Strong fairness on Haul, which asks for one always eventually enabled.
Strong == Init /\ [][Next]_vars /\ WF_vars(Swing) /\ SF_vars(Haul)

Taken == <>hauled
========================
