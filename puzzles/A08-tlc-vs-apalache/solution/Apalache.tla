---- MODULE Apalache ----
(*****************************************************************************
 Minimal TLC-compatible shim of operators we use from Apalache.tla.
 *****************************************************************************)

x := y == x = y

Skolem(P) == P
Gen(n) == CHOOSE x : TRUE
====
