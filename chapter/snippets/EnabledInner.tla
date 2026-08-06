--------------------------- MODULE EnabledInner ---------------------------
(***************************************************************************)
(* Two variables and one claim about them.  In this module `F` is TRUE: no *)
(* matter what state you are in, there is some next state in which x is 0  *)
(* and y is 1.                                                             *)
(*                                                                         *)
(* The example is Lamport, Specifying Systems, section 17.8.               *)
(***************************************************************************)
VARIABLES x, y

F == ENABLED (x' = 0 /\ y' = 1)
===========================================================================
