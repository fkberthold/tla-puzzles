---- MODULE Apalache ----
(*****************************************************************************
 Minimal TLC-compatible shim of the operators we use from Apalache.tla.

 In a real Apalache install, this module is part of Apalache's standard
 library. Apalache treats `:=` as a syntactic marker that "this line is
 THE assignment of this primed variable." TLC just sees plain `=`.

 This shim lets TLC parse specs that EXTENDS Apalache when the real
 Apalache distribution is not on the include path.
 *****************************************************************************)

x := y == x = y

Skolem(P) == P
Gen(n) == CHOOSE x : TRUE
====
