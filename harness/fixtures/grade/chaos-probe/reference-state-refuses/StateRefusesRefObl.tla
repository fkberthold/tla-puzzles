---------------------- MODULE StateRefusesRefObl ----------------------
(***************************************************************************)
(* Obligations for `chaos-probe/reference-state-refuses`. The second way a  *)
(* package survives the chaos probe, and the one that says what the gate    *)
(* actually asks for.                                                       *)
(*                                                                          *)
(* THERE IS NO Step_* IN THIS MODULE, and the package stands anyway. The    *)
(* gate is not "state a transition obligation". It is "let your obligations *)
(* refuse chaos", and a one-state requirement can do that whenever it       *)
(* relates two fields of the observation. Chaos over the record type        *)
(* reaches [level |-> 0, full |-> TRUE], which is a box reporting itself    *)
(* full while it is empty, and Req_fullflag is false there.                 *)
(*                                                                          *)
(* Why the distinction is worth a fixture of its own: a gate that demanded  *)
(* a Step_* would be a syntactic stand-in for the property wanted, and it   *)
(* fails in both directions. A vacuous Step_* satisfies it while refusing   *)
(* nothing, and a business-rule problem with no concurrency in it would     *)
(* have to fabricate a transition obligation to get past it. This fixture   *)
(* goes red if anyone builds the stand-in.                                  *)
(***************************************************************************)
EXTENDS Naturals

ObsDomain == [level: 0..3, full: BOOLEAN]

(***************************************************************************)
(* PHI_1 -- the full flag agrees with the level. One observation, two       *)
(* fields, and chaos over the domain breaks it.                             *)
(***************************************************************************)
Req_fullflag(o) == o.full <=> (o.level = 3)

Landmark_full(o) == o.full

=============================================================================
