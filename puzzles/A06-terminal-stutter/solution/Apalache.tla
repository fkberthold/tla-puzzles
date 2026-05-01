---- MODULE Apalache ----
(*****************************************************************************
 Minimal TLC-compatible shim of operators we use from Apalache.tla.
 In a real Apalache install this module is part of the standard library.
 *****************************************************************************)

x := y == x = y

Skolem(P) == P
Gen(n) == CHOOSE x : TRUE
====
