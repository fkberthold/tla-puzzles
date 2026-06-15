---- MODULE BoundedRing ----
\* Specimen 2 (pangram set): the CONCRETE half of an abstract <= concrete
\* refinement pair over the producer/consumer domain.
\*
\* A fixed-size ring buffer implementing the unbounded AbstractQueue.  The real
\* state is a slot array `buf : [0..N-1 -> Items \cup {NULL}]` plus a `head`
\* index and an occupancy `count`.  Producers write the tail slot
\* (head + count mod N); consumers read the head slot and advance head.
\*
\* This module exercises the refinement-specific module-system tokens that the
\* (parameterization) Specimen 1 cannot show:
\*   * INSTANCE AbstractQueue WITH queue <- <mapping>   (refinement mapping, not
\*     parameter instantiation)
\*   * a two-module abstract+concrete structure
\*   * an AUXILIARY variable (`absq`) carrying the abstract history
\*   * STUTTERING:  Spec uses [Next]_vars, and the refinement is verified as the
\*     abstract Spec (with its own [][Next]_queue) holding under the mapping
\*   * <<A>>_v : a non-stuttering angle-action property
EXTENDS Integers, Sequences

CONSTANTS Items, N, NULL
ASSUME N \in Nat /\ N >= 1
ASSUME NULL \notin Items

Slots == 0 .. (N - 1)

\* `buf`, `head`, `count` are the REAL ring state.
\* `absq` is an AUXILIARY variable: it mirrors the abstract FIFO contents so the
\* refinement mapping can name them directly.  Real ring actions write absq but
\* never read it, so erasing absq leaves ring behaviour unchanged.
VARIABLES buf, head, count, absq

vars == << buf, head, count, absq >>

Init ==
  /\ buf   = [ s \in Slots |-> NULL ]
  /\ head  = 0
  /\ count = 0
  /\ absq  = << >>

\* Producer: write item `it` into the tail slot, grow occupancy.
\* (head + count) % N is the first free slot ahead of the live window.
Produce(it) ==
  /\ count < N
  /\ buf'   = [ buf EXCEPT ![ (head + count) % N ] = it ]
  /\ count' = count + 1
  /\ UNCHANGED head
  /\ absq'  = Append(absq, it)          \* aux bookkeeping (write-only)

\* Consumer: clear the head slot, advance head, shrink occupancy.
Consume ==
  /\ count > 0
  /\ buf'   = [ buf EXCEPT ![head] = NULL ]
  /\ head'  = (head + 1) % N
  /\ count' = count - 1
  /\ absq'  = Tail(absq)                 \* aux bookkeeping (write-only)

Next ==
  \/ \E it \in Items : Produce(it)
  \/ Consume

Spec == Init /\ [][Next]_vars

TypeOK ==
  /\ buf   \in [ Slots -> Items \cup {NULL} ]
  /\ head  \in Slots
  /\ count \in 0 .. N
  /\ absq  \in Seq(Items)
  /\ Len(absq) = count                  \* aux stays consistent with occupancy

----------------------------------------------------------------------------
\* REFINEMENT MAPPING.
\*
\* The abstract queue is exactly the auxiliary history `absq`.  (The same
\* sequence could be reconstructed purely from the real ring state with
\* [ i \in 1..count |-> buf[(head + i - 1) % N] ], but routing it through the
\* auxiliary variable is what lets the mapping cite recorded history directly --
\* the point of the AUXILIARY token in this pangram.)
ABS == INSTANCE AbstractQueue WITH queue <- absq, Items <- Items

\* The concrete spec refines the abstract spec: checked as the abstract Spec
\* (Init /\ [][Next]_queue) holding under the mapping.  Concrete-only stutter on
\* `queue` is permitted by the abstract's [][Next]_queue box-action.
Refinement == ABS!Spec

----------------------------------------------------------------------------
\* <<A>>_v : a non-stuttering ANGLE-ACTION property.
\*
\* Every genuine Produce step is a NON-stutter of the abstract-visible state
\* `absq`: it really appends to the queue, so absq changes.  The angle-action
\* <<Next>>_absq asserts exactly "this step is a Next step that changed absq",
\* the negation of "stutters on absq".  (Verified non-vacuous: replacing the
\* Produce aux-write with UNCHANGED absq makes TLC report this property
\* violated.)
ProduceChangesQueue ==
  [][ (\E it \in Items : Produce(it)) => <<Next>>_absq ]_vars

====
