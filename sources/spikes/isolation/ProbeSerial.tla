---------------------------- MODULE ProbeSerial ----------------------------
(***************************************************************************)
(* Vacuity probes for OnCallSerial, which passed.                          *)
(*                                                                         *)
(* A passing run proves nothing if the interesting states are unreachable.  *)
(* Each definition here is a claim I expect TLC to REFUTE, so a violation   *)
(* is the good outcome and rc 0 would be the finding.                       *)
(*                                                                         *)
(* Kept in its own module so the three OnCall*.tla files stay byte for byte *)
(* identical.                                                               *)
(***************************************************************************)
EXTENDS OnCallSerial

\* Refuted means: under serialisable a doctor really does go off call, so
\* the invariant did not survive by nobody ever writing.
EveryoneStaysOnCall == \A d \in Doctor : store[d] = "on"

\* Refuted means: both transactions really do run to completion.
NotBothDone == \E t \in Txn : pc[t] # "done"

==========================================================================
