----------------------- MODULE MCFenceRotatesCeiling ------------------------
(* The repaired system's counter never reaches the ceiling at all, so the   *)
(* two predicates have no value left to disagree at. The SAME assertion     *)
(* that MCWitnessCeiling.cfg makes against the broken spec, where TLC       *)
(* refutes it. Expect exit 0 here and exit 12 there -- one assertion, two   *)
(* verdicts, and that pair is the measurement.                             *)
EXTENDS TxnFenceRotates

=============================================================================
