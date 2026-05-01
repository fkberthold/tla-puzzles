---- MODULE Apalache ----
(*****************************************************************************
 Minimal TLC-compatible shim of the operators we use from Apalache.tla.

 The real Apalache.tla (from an Apalache install) defines `:=` as a
 syntactic marker for assignment, and `ApaFoldSet` / `ApaFoldSeqLeft` as
 fold-reductions over sets and sequences. TLC just needs the values.

 The set-fold below picks any element, applies Op, and recurses. Order
 is unspecified, so Op must be associative+commutative for the answer
 to be deterministic — same constraint Apalache imposes.
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
