-------------------------- MODULE MCUnboundedFree ---------------------------
(* The same module with the CONSTRAINT removed, so nothing bounds the       *)
(* counter at all. The state space is infinite and the run is expected to   *)
(* hit the wall-clock budget at exit 124.                                   *)
(*                                                                         *)
(* It is here to make the asymmetry a measurement rather than an assertion: *)
(* an unbounded counter costs nothing when the answer is a counterexample   *)
(* and everything when the answer is a proof. The fencing spike found the   *)
(* same asymmetry at sources/spikes/fencing/REPORT.md.                      *)
EXTENDS TxnUnbounded

=============================================================================
