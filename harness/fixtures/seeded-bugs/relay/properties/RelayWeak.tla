----------------------------- MODULE RelayWeak ------------------------------
(***************************************************************************)
(* A TEMPORAL SUBMISSION THAT IS SOUND AND STILL TOO WEAK.                  *)
(*                                                                          *)
(* "The relay keeps leaving position 0."  True of the reference, and it     *)
(* catches advance-stalls, where the relay never leaves position 0 at all.  *)
(* It MISSES recycle-early, whose 0 -> 1 -> 0 cycle leaves position 0 over  *)
(* and over while never reaching position 2.                               *)
(*                                                                          *)
(* This is the discriminating row.  RelayVacuous shows the matrix can fail  *)
(* a property that catches nothing; this one shows it can fail a property   *)
(* that catches SOME variants and not others, which is the only evidence    *)
(* that rc=13 is being read as a refutation per-variant rather than         *)
(* anywhere.                                                                *)
(***************************************************************************)
EXTENDS Relay

Live == []<>(stage # 0)

=============================================================================
