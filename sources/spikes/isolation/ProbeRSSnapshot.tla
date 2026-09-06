-------------------------- MODULE ProbeRSSnapshot --------------------------
(***************************************************************************)
(* Vacuity probes for ReadSkewSnapshot, which passed. Same two claims as    *)
(* ProbeRSSerial, and both are expected to be refuted.                      *)
(***************************************************************************)
EXTENDS ReadSkewSnapshot

ReaderNeverReadsBoth == DOMAIN seen[Reader] # Key

TransferNeverLands == store[AccA] = 10

==========================================================================
