--------------------------- MODULE ProducerConsumer ---------------------------
(***************************************************************************)
(* A bounded-buffer producer/consumer system, written in c-syntax         *)
(* PlusCal.  A set of producer processes each push a fixed quota of items  *)
(* into a shared FIFO buffer; a set of consumer processes drain it; and a  *)
(* single distinguished monitor process snapshots the high-water mark.     *)
(*                                                                         *)
(* The buffer itself is the Buffer ADT, pulled in via INSTANCE so the      *)
(* FIFO mechanics (Enqueue / Dequeue / Peek / IsFull / IsEmpty) live in    *)
(* one place and the algorithm reads as ordinary queue manipulation.      *)
(***************************************************************************)
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC

CONSTANTS Producers,    \* the set of producer process ids
          Consumers,    \* the set of consumer process ids
          BufCapacity,  \* the bounded buffer's capacity (a positive Nat)
          Items         \* the set of item values a producer may emit

(* Bring the Buffer ADT in at this capacity.  The WITH clause wires the   *)
(* instance's Capacity parameter to our BufCapacity constant.             *)
Buf == INSTANCE Buffer WITH Capacity <- BufCapacity

(* Quota: how many items each producer must emit before it retires.       *)
Quota == 2

ASSUME /\ Producers \cap Consumers = {}          \* ids are disjoint
       /\ IsFiniteSet(Producers) /\ IsFiniteSet(Consumers)
       /\ BufCapacity \in Nat /\ BufCapacity > 0
       /\ Items \subseteq Nat /\ Items # {}

(*--algorithm ProducerConsumer {
  variables
    buffer    = Buf!Empty,                 \* the shared FIFO buffer
    produced  = 0,                         \* total items ever enqueued
    consumed  = 0,                         \* total items ever dequeued
    highWater = 0,                         \* max buffer length seen by monitor
    \* a per-producer remaining-quota function: [ Producers -> Nat ]
    remaining = [ p \in Producers |-> Quota ];

  define {
    \* ---- The set of all process ids, and the total work to do. ----
    AllProcs == Producers \cup Consumers
    TotalQuota == Quota * Cardinality(Producers)

    \* ---- Type invariant. ----
    TypeOK ==
      /\ buffer \in Seq(Items)
      /\ produced \in 0..TotalQuota
      /\ consumed \in 0..TotalQuota
      /\ highWater \in 0..BufCapacity
      /\ remaining \in [ Producers -> 0..Quota ]
      /\ DOMAIN remaining = Producers

    \* ---- Safety: the buffer never overflows its capacity. ----
    NeverOverflow == Len(buffer) <= BufCapacity

    \* ---- Safety: nothing is consumed that was not first produced, and
    \*      the books always balance (conservation of items).
    Conservation == consumed + Len(buffer) = produced
    NoUnderflow   == consumed <= produced

    \* ---- The monitor's snapshot is a true upper bound on past lengths.
    HighWaterSound == highWater <= BufCapacity /\ Len(buffer) <= TotalQuota

    \* ---- Liveness: every produced item is eventually consumed, the
    \*      system drains, and all producers retire.
    AllProduced   == produced = TotalQuota
    Drained       == (produced = TotalQuota) => <>(consumed = TotalQuota)
    EventuallyIdle == <>[](Buf!IsEmpty(buffer) /\ produced = TotalQuota)
  }

  \* A macro: record a fresh high-water mark.  Macros are inlined, so this
  \* may only contain straight-line assignments (no labels / awaits).
  macro observe(len) {
    highWater := IF len > highWater THEN len ELSE highWater;
  }

  \* A procedure that enqueues one item and bumps the produced counter.
  \* Demonstrates call / return and a procedure-local variable.
  procedure deposit(item = 0)
    variable slot = 0;
  {
    depEnter:
      \* Guard and enqueue in ONE atomic label so two producers can't both
      \* pass the room-check and then overflow the buffer.
      await ~ Buf!IsFull(buffer);
      slot := Len(buffer) + 1;            \* the index this item will land at
      buffer := Buf!Enqueue(buffer, item);
      produced := produced + 1;
      assert Len(buffer) <= BufCapacity;  \* the atomic await guarantees this
    depDone:
      return;
  }

  \* ---- Producers: a process SET, indexed over the Producers ids. ----
  fair process (Prod \in Producers)
    variable nextVal = 0;
  {
    prodLoop:
      while (remaining[self] > 0) {
        \* pick an arbitrary item value from Items with with(\in)
        pick:
          with (v \in Items) {
            nextVal := v;
          };
        \* block until there is room; then deposit via the procedure
        push:
          await ~ Buf!IsFull(buffer);
          call deposit(nextVal);
        bookkeep:
          remaining[self] := remaining[self] - 1;
          print <<"produced", self, nextVal>>;
      };
  }

  \* ---- Consumers: a process SET, indexed over the Consumers ids. ----
  fair process (Cons \in Consumers)
    variable got = 0;
  {
    consLoop:
      while (consumed < TotalQuota) {
        take:
          \* block until non-empty, then either take one or briefly idle
          either {
            await ~ Buf!IsEmpty(buffer);
            got := Buf!Peek(buffer);
            buffer := Buf!Dequeue(buffer);
            consumed := consumed + 1;
          } or {
            await consumed >= TotalQuota;  \* nothing left to do; fall through
            skip;
          };
      };
  }

  \* ---- Monitor: a SINGLE distinguished process in =-form (not a set).
  \*      It watches the buffer and keeps the high-water mark current.
  fair process (Monitor = "monitor")
    variable len = 0;
  {
    watch:
      while (consumed < TotalQuota \/ ~ Buf!IsEmpty(buffer)) {
        sample:
          len := Len(buffer);
          observe(len);
      };
  }
}
*)
\* BEGIN TRANSLATION
\* END TRANSLATION

------------------------------------------------------------------------------
(***************************************************************************)
(* Hand-written supplements that exercise tokens the algorithm body does   *)
(* not naturally reach.  These are ordinary TLA+ definitions over the      *)
(* translated state (buffer, produced, consumed, ..., pc, vars).           *)
(***************************************************************************)

(* A record describing the system's instantaneous load, built with the    *)
(* [field |-> value] form, read with .field, and updated with EXCEPT / @.  *)
Status ==
  LET base == [ depth |-> Len(buffer), pending |-> produced - consumed,
                full |-> Buf!IsFull(buffer) ]
  IN  [ base EXCEPT !.pending = @ + 0 ]   \* @ refers to the old field value

(* A function literal [x \in S |-> e], its DOMAIN, application f[x], and a *)
(* function-valued EXCEPT ![k] = update.                                   *)
QuotaFn   == [ p \in Producers |-> Quota ]
QuotaOf(p) == QuotaFn[p]
BumpFirst(f) ==
  IF DOMAIN f = {} THEN f
  ELSE [ f EXCEPT ![CHOOSE q \in DOMAIN f : TRUE] = @ + 1 ]

(* Build a function with :> (single mapping) and @@ (merge), the TLC way.  *)
Labels == ("idle" :> 0) @@ ("busy" :> 1) @@ ("full" :> 2)

(* CASE over the qualitative buffer state. *)
Phase ==
  CASE Buf!IsEmpty(buffer) -> "idle"
    [] Buf!IsFull(buffer)  -> "full"
    [] OTHER               -> "busy"

(* Set comprehension: a filter and a map, plus the full kit of set ops.   *)
ItemsSeen   == { buffer[i] : i \in DOMAIN buffer }        \* map form
EvenItems   == { x \in Items : x % 2 = 0 }               \* filter form
SmallItems  == { x \in Items : x < 10 }
ItemFacts ==
  /\ EvenItems \subseteq Items
  \* proper subset, spelled out: contained in but not equal to a superset
  /\ EvenItems \subseteq (Items \cup {99}) /\ EvenItems # (Items \cup {99})
  /\ ItemsSeen \in SUBSET Items
  /\ (\A x \in EvenItems : x \in Items)
  /\ (\E x \in Items : x \notin EvenItems \/ x \div 2 \in Nat)
  /\ Cardinality(SmallItems) <= Cardinality(Items)

(* A small assertion exercised once via TLC's Assert/Print/PrintT.        *)
SanityCheck ==
  /\ PrintT("checking labels") => TRUE
  /\ Assert(Labels["idle"] = 0, "idle must map to 0")
  /\ Print("labels ok", TRUE)

(* Arithmetic / order / range tokens gathered into one predicate.          *)
ArithFacts ==
  /\ produced - consumed >= 0
  /\ produced + consumed <= 2 * TotalQuota
  /\ TotalQuota \div Quota >= 0
  /\ TotalQuota % Quota = 0
  /\ Len(buffer) \in 0..BufCapacity
  /\ (Len(buffer) > 0) <=> (~ Buf!IsEmpty(buffer))
  /\ (consumed = produced) => (Status.pending = 0)

(* The composite invariant fed to TLC. *)
Inv ==
  /\ TypeOK
  /\ NeverOverflow
  /\ Conservation
  /\ NoUnderflow
  /\ HighWaterSound
  /\ ItemFacts
  /\ ArithFacts

------------------------------------------------------------------------------
(***************************************************************************)
(* Hand-written temporal / fairness properties.  These reference the       *)
(* translated Next / vars and exercise the full temporal-operator kit.     *)
(***************************************************************************)

(* [] safety and <> eventually as standalone properties. *)
AlwaysBounded == [] NeverOverflow
EventuallyDone == <> (consumed = TotalQuota)

(* Leads-to: every item produced is eventually consumed (the books        *)
(* eventually balance with an empty buffer).                              *)
ItemsDrain == (produced = TotalQuota) ~> (consumed = TotalQuota)

(* []<> progress: the buffer is empty infinitely often (it keeps draining)*)
(* and <>[] stabilization: it ends up permanently empty + fully produced. *)
Progress      == []<> Buf!IsEmpty(buffer)
Stabilizes    == <>[] (consumed = TotalQuota /\ Buf!IsEmpty(buffer))

(* ENABLED inside a property: at every reachable state either a real       *)
(* (non-stuttering) system step is enabled, or the system has already      *)
(* finished all its work.  Exercises ENABLED over the translated Next.     *)
NotStuck == [] (ENABLED <<Next>>_vars \/ (consumed = TotalQuota))

(* A hand-written Spec re-stating the safety/fairness shape with explicit  *)
(* [A]_v stutter-steps, <<A>>_v non-stutter steps, UNCHANGED, and          *)
(* WF_ / SF_ fairness conditions over the translated state.               *)
ProgressNext == <<Next>>_vars \/ (UNCHANGED vars /\ consumed = TotalQuota)

SpecHand ==
  /\ Init
  /\ [][Next]_vars
  /\ WF_vars(Next)
  /\ \A self \in Consumers : SF_vars(Cons(self))

==============================================================================
