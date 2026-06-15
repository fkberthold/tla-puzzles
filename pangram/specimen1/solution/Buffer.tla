-------------------------------- MODULE Buffer --------------------------------
(***************************************************************************)
(* A Sequences-based bounded-buffer ADT (a FIFO queue with a fixed        *)
(* capacity).  This is a pure-TLA+ library module: it has no spec of its  *)
(* own and no .cfg.  ProducerConsumer.tla pulls it in via INSTANCE.       *)
(*                                                                         *)
(* The buffer is modelled as a finite sequence.  "Capacity" is the        *)
(* parameter of the instance; the operators here read it via the          *)
(* module-level CONSTANT below, supplied by the instantiator with WITH.   *)
(***************************************************************************)
EXTENDS Naturals, Sequences

CONSTANT Capacity              \* the buffer's maximum length, a Nat

--------------------------------------------------------------------------

(* A LOCAL helper is visible inside this module but is NOT re-exported to *)
(* an instantiating module.  We use it to keep the doubling detail local. *)
LOCAL Double(n) == 2 * n

(* RECURSIVE operator: sum the elements of a sequence of naturals.        *)
RECURSIVE SumSeq(_)
SumSeq(s) == IF s = << >>
               THEN 0
               ELSE Head(s) + SumSeq(Tail(s))

(* The empty buffer and the basic predicates. *)
Empty    == << >>
IsEmpty(buf) == Len(buf) = 0
IsFull(buf)  == Len(buf) = Capacity

(* Core FIFO operations expressed with Sequences primitives. *)
Enqueue(buf, x) == Append(buf, x)        \* add x at the tail
Dequeue(buf)    == Tail(buf)             \* drop the front element
Peek(buf)       == Head(buf)             \* read the front element

(* Concatenate two buffers with \o, then keep only the newest Capacity    *)
(* elements using SubSeq -- a "merge, keep last window" operation.        *)
Merge(a, b) ==
  LET joined == a \o b
      n      == Len(joined)
  IN  IF n <= Capacity
        THEN joined
        ELSE SubSeq(joined, (n - Capacity) + 1, n)

(* LAMBDA use: filter a buffer down to the elements satisfying P via      *)
(* SelectSeq, the higher-order Sequences operator.                        *)
CountWhere(buf, P(_)) == Len(SelectSeq(buf, LAMBDA x : P(x)))

(* The total "weight" of a buffer of naturals, exercising the LOCAL       *)
(* helper and the RECURSIVE sum together.                                 *)
Weight(buf) == Double(SumSeq(buf))

==============================================================================
