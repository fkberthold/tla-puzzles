------------------------------- MODULE Concrete -------------------------------
(***************************************************************************)
(* THE TRAPDOOR. Byte-identical to correct/Concrete.tla except for the WITH *)
(* clause, which is FROZEN: the abstract's `level` is mapped to the         *)
(* constant 0 and never moves.                                              *)
(*                                                                          *)
(* TLC passes this at rc=0 on `PROPERTY Refines`, and the configuration     *)
(* guard Gate!RefinementConfigured passes it too, because the .cfg really   *)
(* did declare the PROPERTY. Nothing about the refinement channel can tell  *)
(* this file from correct/Concrete.tla.                                     *)
(*                                                                          *)
(* Mechanism: A!Spec expands to A!Init /\ [][A!Next]_(A!vars). With the     *)
(* mapping frozen, A!vars is << 0 >> in every state, so UNCHANGED (A!vars)  *)
(* holds at every step and the right disjunct of                            *)
(*                                                                          *)
(*     A!Next \/ UNCHANGED (A!vars)                                         *)
(*                                                                          *)
(* is true everywhere. A!Next is never evaluated once. The check passes and *)
(* has proved nothing at all.                                               *)
(*                                                                          *)
(* This is not a hypothetical. tlaplus/TLAiBench -- the only public         *)
(* benchmark that grades TLA+ refinement -- has this trapdoor open: a       *)
(* fully frozen mapping (WITH big <- 0, small <- 0) passes both its plain   *)
(* refinement check and its Gold!Refinement postcondition at rc=0. Recorded *)
(* in the tla-kl5.3 survey; this fixture is our regression case for it.     *)
(***************************************************************************)
EXTENDS Naturals

VARIABLE ticks

vars == << ticks >>

Init == ticks = 0
Tick == ticks < 6 /\ ticks' = ticks + 1
Next == Tick

Spec == Init /\ [][Next]_vars

TypeOK == ticks \in 0..6

(***************************************************************************)
(* THE FROZEN MAPPING -- the one line that differs from correct/.           *)
(***************************************************************************)
A == INSTANCE Abstract WITH level <- 0

Refines == A!Spec

(***************************************************************************)
(* The module-authored probe, honest here: it says exactly what is true,    *)
(* which is that the mapped expression never leaves << 0 >>. Used only by   *)
(* the raw-TLC guard matrix in fixtures/refinement/cfg/.                    *)
(***************************************************************************)
Probe == A!vars = << 0 >>

===============================================================================
