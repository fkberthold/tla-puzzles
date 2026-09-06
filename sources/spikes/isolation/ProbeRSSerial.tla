--------------------------- MODULE ProbeRSSerial ---------------------------
(***************************************************************************)
(* Vacuity probes for ReadSkewSerial, which passed.                        *)
(*                                                                         *)
(* ReportIsConsistent is guarded by `DOMAIN seen[t] = Key', so it holds for *)
(* free in every state where the report never finished reading. Both        *)
(* definitions below are claims I expect TLC to REFUTE.                     *)
(***************************************************************************)
EXTENDS ReadSkewSerial

\* Refuted means: the report really does read both accounts, so the guard
\* on ReportIsConsistent is discharged somewhere in the space.
ReaderNeverReadsBoth == DOMAIN seen[Reader] # Key

\* Refuted means: the transfer really does commit.
TransferNeverLands == store[AccA] = 10

==========================================================================
