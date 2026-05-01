---- MODULE Apalache ----
(*****************************************************************************
 Minimal TLC-compatible shim of operators we use from Apalache.tla.

 In a real Apalache install this module is part of the standard library.
 Apalache treats `:=` as a syntactic marker and `ApaFoldSet` /
 `ApaFoldSeqLeft` as fold-reductions. TLC just needs the values.
 *****************************************************************************)

EXTENDS Integers, Sequences, FiniteSets

x := y == x = y

Skolem(P) == P
Gen(n) == CHOOSE x : TRUE

RECURSIVE ApaFoldSet(_, _, _)
ApaFoldSet(Op(_,_), base, S) ==
  IF S = {} THEN base
  ELSE LET x == CHOOSE y \in S : TRUE
       IN  ApaFoldSet(Op, Op(base, x), S \ {x})

RECURSIVE ApaFoldSeqLeft(_, _, _)
ApaFoldSeqLeft(Op(_,_), base, seq) ==
  IF Len(seq) = 0 THEN base
  ELSE ApaFoldSeqLeft(Op, Op(base, Head(seq)), Tail(seq))

====
