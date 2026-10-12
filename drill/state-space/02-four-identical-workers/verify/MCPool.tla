----------------------------- MODULE MCPool -----------------------------
EXTENDS Pool

\* Two named workers, so a .cfg can state something that is NOT symmetric.
CONSTANTS w1, w4

\* A requirement that singles out one worker. It is false on the system,
\* since every worker can hold a slot, and it is not invariant under
\* permuting Workers. That combination is the hazard the item measures.
\* Two copies, because which worker TLC happens to enumerate first decides
\* whether the violating state is ever generated.
FirstWorkerNeverHolds == st[w1] # "holding"
LastWorkerNeverHolds == st[w4] # "holding"

\* The same requirement stated without naming anybody, so it IS symmetric.
\* Also false, and false for the same reason.
NobodyEverHolds == Holders = {}

\* A liveness claim, for the symmetry-and-liveness cell.
EveryWaiterIsServed == \A w \in Workers : (st[w] = "waiting") ~> (st[w] = "holding")

FairSpec == Spec /\ \A w \in Workers : WF_vars(Take(w) \/ Release(w))

\* The plausible wrong knob. Named in a .cfg as CONSTRAINT ShortQueue.
ShortQueue == Len(queue) <= 2

==========================================================================
