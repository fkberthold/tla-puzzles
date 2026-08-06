--------------------------- MODULE Observatory ---------------------------
(***************************************************************************)
(* The concrete observatory.  Several dishes, each slewing to a proposal,  *)
(* integrating for a while, and archiving the result -- unless weather     *)
(* wipes the integration and the proposal goes back in the queue.          *)
(*                                                                         *)
(* Companion to the refinement chapter, worked example.                    *)
(***************************************************************************)
EXTENDS Naturals

CONSTANTS Proposals, Dishes, Needed, Idle

VARIABLES status, onsky, acc
cvars == << status, onsky, acc >>

TypeOK ==
  /\ status \in [Proposals -> {"queued", "observing", "archived"}]
  /\ onsky  \in [Dishes -> Proposals \cup {Idle}]
  /\ acc    \in [Proposals -> 0..Needed]

Init ==
  /\ status = [p \in Proposals |-> "queued"]
  /\ onsky  = [d \in Dishes    |-> Idle]
  /\ acc    = [p \in Proposals |-> 0]

Slew(d, p) ==
  /\ onsky[d] = Idle
  /\ status[p] = "queued"
  /\ onsky'  = [onsky  EXCEPT ![d] = p]
  /\ status' = [status EXCEPT ![p] = "observing"]
  /\ UNCHANGED acc

Integrate(d) ==
  /\ onsky[d] # Idle
  /\ acc[onsky[d]] < Needed
  /\ acc' = [acc EXCEPT ![onsky[d]] = @ + 1]
  /\ UNCHANGED << status, onsky >>

Cloud(d) ==
  /\ onsky[d] # Idle
  /\ acc[onsky[d]] < Needed
  /\ status' = [status EXCEPT ![onsky[d]] = "queued"]
  /\ acc'    = [acc    EXCEPT ![onsky[d]] = 0]
  /\ onsky'  = [onsky  EXCEPT ![d] = Idle]

Archive(d) ==
  /\ onsky[d] # Idle
  /\ acc[onsky[d]] = Needed
  /\ status' = [status EXCEPT ![onsky[d]] = "archived"]
  /\ onsky'  = [onsky  EXCEPT ![d] = Idle]
  /\ UNCHANGED acc

Next ==
  \E d \in Dishes :
    \/ \E p \in Proposals : Slew(d, p)
    \/ Integrate(d)
    \/ Cloud(d)
    \/ Archive(d)

Spec == Init /\ [][Next]_cvars

(***************************************************************************)
(* THE MAPPING.  Everything below this line is about the abstract spec,    *)
(* not about the observatory.                                              *)
(***************************************************************************)

\* The one we mean.
Archived == { p \in Proposals : status[p] = "archived" }

\* The one with the typo.  `acc` is bounded above by `Needed`, so this set is
\* empty in every reachable state -- a mapping frozen by a single character.
ArchivedTypo == { p \in Proposals : acc[p] > Needed }

\* Plausible and wrong in the other direction: it counts a proposal as
\* archived while it is still on sky, so a Cloud step takes it back out.
ArchivedEager == { p \in Proposals : status[p] # "queued" }

A      == INSTANCE Almanac WITH logged <- Archived
ATypo  == INSTANCE Almanac WITH logged <- ArchivedTypo
AEager == INSTANCE Almanac WITH logged <- ArchivedEager

Refines      == A!Spec
RefinesTypo  == ATypo!Spec
RefinesEager == AEager!Spec

(***************************************************************************)
(* The two facts proved of the two-line abstract spec, now stated about    *)
(* the observatory.  Nothing new is proved here: A!AppendOnly is           *)
(* Almanac's AppendOnly with `logged` replaced by `Archived`.  It is on    *)
(* the shelf the moment Refines passes.  It is named here only because     *)
(* the .cfg cannot say A!AppendOnly.                                       *)
(***************************************************************************)
InheritedAppendOnly   == A!AppendOnly
InheritedNoDuplicates == A!NoDuplicates

(***************************************************************************)
(* THE PROBE.  Run as an INVARIANT.  A violation (rc=12) means the mapped  *)
(* state left its initial value at least once, so the refinement check     *)
(* had something to chew on.  No violation (rc=0) means the mapping never  *)
(* moved and the refinement check proved nothing.  This is the one check   *)
(* whose good outcome is a failure.                                        *)
(***************************************************************************)
Frozen      == Archived     = {}
FrozenTypo  == ArchivedTypo = {}

(***************************************************************************)
(* The rung below full refinement: the abstract next-state action alone,   *)
(* with no Init and no liveness.  Same shape as MCIProp in                 *)
(* tlaplus/Examples specifications/Paxos/MCPaxos.tla line 72.              *)
(***************************************************************************)
IProp == [][A!Next]_<< Archived >>

(***************************************************************************)
(* For reading a refinement failure: print the mapped abstract state next  *)
(* to the concrete state in every row of the error trace.                  *)
(***************************************************************************)
Alias ==
  [ status |-> status,
    onsky  |-> onsky,
    acc    |-> acc,
    logged |-> ArchivedEager ]
==========================================================================
