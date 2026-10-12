---------------------------- MODULE SitePhase --------------------------
(* The neighbour answer: one site-wide phase. It cannot say that r1 is  *)
(* at the load while r2 has stepped clear, so the lift guard has nothing *)
(* to look at.                                                           *)
CONSTANTS Rigging, Rigged, Lifting

VARIABLE phase
vars == <<phase>>

Init == phase = Rigging

Hooked == /\ phase = Rigging
          /\ phase' = Rigged

Lift == /\ phase = Rigged
        /\ phase' = Lifting

Park == /\ phase = Lifting
        /\ phase' = Rigging

Next == Hooked \/ Lift \/ Park

Spec == Init /\ [][Next]_vars
=========================================================================
