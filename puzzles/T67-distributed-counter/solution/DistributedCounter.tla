---- MODULE DistributedCounter ----
(***************************************************************************)
(* The CONCRETE spec for the distributed counter.                          *)
(*                                                                         *)
(* Each node in `Nodes` independently flips its local cell from 0 to 1.    *)
(* A coordinator process aggregates the cells into a single sum once all   *)
(* nodes have contributed, and signals aggDone. A heartbeat process        *)
(* toggles a `ready` flag the coordinator must observe before aggregating  *)
(* — this models intermittent availability and is the reason the           *)
(* coordinator's aggregate action requires STRONG fairness.                *)
(*                                                                         *)
(* The aggregator uses ApaFoldSet (Apalache's set-fold) to sum the cells.  *)
(* For TLC compatibility we define ApaFoldSet locally with RECURSIVE; on   *)
(* Apalache, EXTENDING the Apalache module would provide a native version. *)
(*                                                                         *)
(* This module REFINES AbstractCounter via the INSTANCE clause near the    *)
(* end: each Node action maps to abstract Tick, the coordinator's          *)
(* Aggregate action maps to abstract Finish, and the heartbeat's           *)
(* ToggleReady steps map to abstract stuttering.                           *)
(***************************************************************************)
EXTENDS Integers, FiniteSets, Apalache

CONSTANT
  \* @type: Set(Str);
  Nodes

ASSUME /\ IsFiniteSet(Nodes)
       /\ Nodes # {}

VARIABLES
  \* @type: Str -> Int;
  local,
  \* @type: Bool;
  ready,
  \* @type: Int;
  agg,
  \* @type: Bool;
  aggDone

vars == <<local, ready, agg, aggDone>>

\* Sum of all local cells, computed via Apalache's ApaFoldSet (provided by EXTENDS Apalache).
\* The Apalache.tla shipped in this solution dir is the official module from the
\* apalache jar. TLC executes the recursive body in Apalache.tla directly;
\* Apalache uses its native symbolic encoding. Both produce the same result.
\* @type: (Int, Str) => Int;
Add(acc, n) == acc + local[n]
SumLocals == ApaFoldSet(Add, 0, Nodes)

NodeCount == Cardinality(Nodes)

TypeOK ==
  /\ local \in [Nodes -> 0..1]
  /\ ready \in BOOLEAN
  /\ agg \in 0..NodeCount
  /\ aggDone \in BOOLEAN

Init ==
  /\ local = [n \in Nodes |-> 0]
  /\ ready = FALSE
  /\ agg = 0
  /\ aggDone = FALSE

\* A single node flips its cell from 0 to 1.
Contribute(n) ==
  /\ local[n] = 0
  /\ local' = [local EXCEPT ![n] = 1]
  /\ UNCHANGED <<ready, agg, aggDone>>

\* Heartbeat process: toggles `ready` while the system is still running.
\* This is what makes Aggregate's enablement intermittent (forcing SF below).
ToggleReady ==
  /\ ~aggDone
  /\ ready' = ~ready
  /\ UNCHANGED <<local, agg, aggDone>>

\* Coordinator aggregates all cells once every node has contributed.
\* Note the AWAIT-style guard: \A n \in Nodes: local[n] = 1.
\* The `ready` guard models a window where aggregation is permitted —
\* if the heartbeat keeps `ready` false, Aggregate is disabled even when
\* all cells are populated.
Aggregate ==
  /\ ready
  /\ ~aggDone
  /\ \A n \in Nodes : local[n] = 1
  /\ agg' = SumLocals
  /\ aggDone' = TRUE
  /\ UNCHANGED <<local, ready>>

\* Terminal stutter: once aggregation is done, the system is at rest.
\* This explicit disjunct avoids TLC's deadlock check firing on the
\* terminal state and keeps the spec's safety semantics unchanged.
DoneStutter ==
  /\ aggDone
  /\ UNCHANGED vars

Next ==
  \/ \E n \in Nodes : Contribute(n)
  \/ ToggleReady
  \/ Aggregate
  \/ DoneStutter

Spec ==
  /\ Init
  /\ [][Next]_vars
  /\ \A n \in Nodes : WF_vars(Contribute(n))
  /\ WF_vars(ToggleReady)
  /\ SF_vars(Aggregate)

\*****************************************************************
\* Refinement: this concrete spec implements AbstractCounter
\* under the mapping below.
\*****************************************************************

\* The mapping: abstract `c` is the running sum of locals;
\*              abstract `done` is the coordinator's aggDone flag.
Abstract == INSTANCE AbstractCounter
  WITH N    <- NodeCount,
       c    <- SumLocals,
       done <- aggDone

\* The refinement claim TLC will check.
Refinement == Abstract!Spec

\*****************************************************************
\* Liveness — using leads-to.
\*****************************************************************

AllContributed == \A n \in Nodes : local[n] = 1

\* Once all nodes have contributed, aggregation eventually completes.
\* This is the core liveness obligation; SF on Aggregate is what makes
\* it true in the presence of the toggling heartbeat.
EventuallyAggregated == AllContributed ~> aggDone

\* The abstract liveness property holds at the concrete level too.
EventuallyDone == <>aggDone

\* For Apalache: provide a concrete value for the symbolic CONSTANT.
\* TLC ignores this — see DistributedCounter.cfg for TLC's constant binding.
ConstInit == Nodes = {"n1", "n2", "n3"}

================================
