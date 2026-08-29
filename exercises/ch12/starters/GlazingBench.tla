---- MODULE GlazingBench ----
\* Exercise 3. Two holes, TODO_1 and TODO_2. The module does not compile until
\* both are filled.
\*
\* Two glaziers share one cutting bench. Each of them mounts a pane on the
\* bench, then cuts it, then is done. Only one glazier may be at the bench at
\* a time.
\*
\* Everything below the holes is already written for you: the helper action
\* that moves a glazier from one label to the next, the initial state, the
\* stuttering action for when both are finished, and the two invariants. What
\* is missing is the two labels themselves.
EXTENDS Integers

Glaziers == {"g1", "g2"}
Free == "free"

VARIABLES pc, bench, panes

vars == << pc, bench, panes >>

ProcSet == Glaziers

\* The helper action. `Trans(self, from, to)` is true of a step in which
\* glazier `self` was at label `from` and is at label `to` next. It says
\* nothing at all about `bench` or `panes`.
Trans(self, from, to) == /\ pc[self] = from
                         /\ pc' = [pc EXCEPT ![self] = to]

Init == /\ pc = [self \in ProcSet |-> "Mount"]
        /\ bench = Free
        /\ panes = 0

\* TODO_1. Glazier `self` moves from label "Mount" to label "Cut". This may
\* only happen while the bench is free, and it leaves the glazier holding the
\* bench. It cuts nothing.
Mount(self) == TODO_1

\* TODO_2. Glazier `self` moves from label "Cut" to label "Done". It gives the
\* bench back and it adds one to the count of cut panes.
Cut(self) == TODO_2

glazier(self) == Mount(self) \/ Cut(self)

\* Once both glaziers are Done, this is the only thing left that can happen.
Terminating == /\ (\A self \in ProcSet : pc[self] = "Done")
               /\ UNCHANGED vars

Next == (\E self \in Glaziers : glazier(self))
          \/ Terminating

Spec == Init /\ [][Next]_vars

CutterHoldsBench == \A g \in Glaziers : pc[g] = "Cut" => bench = g
BenchHolderIsCutting == \A g \in Glaziers : bench = g => pc[g] = "Cut"
====
