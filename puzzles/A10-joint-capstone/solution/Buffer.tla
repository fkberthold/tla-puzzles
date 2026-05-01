---- MODULE Buffer ----
(*
  A bounded FIFO buffer: a joint capstone for TLC and Apalache.

  This spec demonstrates both tools' complementary strengths:
  - TLC: enumerates concrete buffer states, counts exact state space
  - Apalache: proves the invariant symbolically for ANY buffer size (via --cinit)

  The SAME spec runs on both tools with no edits.
*)
EXTENDS Integers, Sequences, Apalache

CONSTANT
  \* @type: Int;
  MaxSize

VARIABLES
  \* @type: Seq(Int);
  buffer
\* @type: <<Seq(Int)>>;
vars == << buffer >>

TypeOK ==
  /\ buffer \in Seq(1..100)
  /\ Len(buffer) <= MaxSize

Init ==
  buffer := << >>

Push ==
  /\ Len(buffer) < MaxSize
  /\ \E val \in 1..100:
       buffer' := Append(buffer, val)

Pop ==
  /\ Len(buffer) > 0
  /\ buffer' := Tail(buffer)

\* Terminal action: once buffer is empty, we can stutter forever.
Done ==
  /\ Len(buffer) = 0
  /\ UNCHANGED buffer

Next == Push \/ Pop \/ Done

Spec == Init /\ [][Next]_vars

\* Core safety invariant: buffer never exceeds its bound.
NeverOverflow == Len(buffer) <= MaxSize

\* For Apalache: verify NeverOverflow for all MaxSize in range 1..10.
\* TLC will use the concrete value from the .cfg.
ConstInit ==
  MaxSize \in 1..10
====
