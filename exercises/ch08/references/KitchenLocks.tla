---- MODULE KitchenLocks ----
\* Exercise 2 reference. Identical to the starter, which already runs.
\*
\* A baker and a cook share one pan and one whisk. Each needs both before it
\* can work, takes them one at a time, and puts both back afterwards.
\* `Nobody` is a model value standing for "nobody is holding this".
EXTENDS Integers

CONSTANT Nobody

(*--algorithm kitchenlocks {
  variables pan = Nobody, whisk = Nobody;

  process (baker = "baker")
  {
    BakerTakesPan:
      await pan = Nobody;
      pan := "baker";
    BakerTakesWhisk:
      await whisk = Nobody;
      whisk := "baker";
    BakerPutsBack:
      pan := Nobody;
      whisk := Nobody;
  }

  process (cook = "cook")
  {
    CookTakesPan:
      await pan = Nobody;
      pan := "cook";
    CookTakesWhisk:
      await whisk = Nobody;
      whisk := "cook";
    CookPutsBack:
      pan := Nobody;
      whisk := Nobody;
  }
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "ae87f502" /\ chksum(tla) = "3e5a5b26")
VARIABLES pc, pan, whisk

vars == << pc, pan, whisk >>

ProcSet == {"baker"} \cup {"cook"}

Init == (* Global variables *)
        /\ pan = Nobody
        /\ whisk = Nobody
        /\ pc = [self \in ProcSet |-> CASE self = "baker" -> "BakerTakesPan"
                                        [] self = "cook" -> "CookTakesPan"]

BakerTakesPan == /\ pc["baker"] = "BakerTakesPan"
                 /\ pan = Nobody
                 /\ pan' = "baker"
                 /\ pc' = [pc EXCEPT !["baker"] = "BakerTakesWhisk"]
                 /\ whisk' = whisk

BakerTakesWhisk == /\ pc["baker"] = "BakerTakesWhisk"
                   /\ whisk = Nobody
                   /\ whisk' = "baker"
                   /\ pc' = [pc EXCEPT !["baker"] = "BakerPutsBack"]
                   /\ pan' = pan

BakerPutsBack == /\ pc["baker"] = "BakerPutsBack"
                 /\ pan' = Nobody
                 /\ whisk' = Nobody
                 /\ pc' = [pc EXCEPT !["baker"] = "Done"]

baker == BakerTakesPan \/ BakerTakesWhisk \/ BakerPutsBack

CookTakesPan == /\ pc["cook"] = "CookTakesPan"
                /\ pan = Nobody
                /\ pan' = "cook"
                /\ pc' = [pc EXCEPT !["cook"] = "CookTakesWhisk"]
                /\ whisk' = whisk

CookTakesWhisk == /\ pc["cook"] = "CookTakesWhisk"
                  /\ whisk = Nobody
                  /\ whisk' = "cook"
                  /\ pc' = [pc EXCEPT !["cook"] = "CookPutsBack"]
                  /\ pan' = pan

CookPutsBack == /\ pc["cook"] = "CookPutsBack"
                /\ pan' = Nobody
                /\ whisk' = Nobody
                /\ pc' = [pc EXCEPT !["cook"] = "Done"]

cook == CookTakesPan \/ CookTakesWhisk \/ CookPutsBack

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == baker \/ cook
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
====
