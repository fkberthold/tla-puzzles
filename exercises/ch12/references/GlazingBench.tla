---- MODULE GlazingBench ----
\* Exercise 3 reference answer.
\*
\* Two glaziers, one cutting bench, written the way the translator writes it
\* and by hand rather than by `pcal`. Every piece of the sequencing is a `pc`
\* guard plus a `pc'` update, and every piece of the concurrency is the one
\* `\E self` in `Next`. There is no other machinery.
EXTENDS Integers

Glaziers == {"g1", "g2"}
Free == "free"

VARIABLES pc, bench, panes

vars == << pc, bench, panes >>

ProcSet == Glaziers

\* The helper action. It carries the guard and the update for one label
\* transition, so each action below states its own work and nothing else.
\* This is one of the things pure TLA+ buys that PlusCal cannot reach.
Trans(self, from, to) == /\ pc[self] = from
                         /\ pc' = [pc EXCEPT ![self] = to]

Init == /\ pc = [self \in ProcSet |-> "Mount"]
        /\ bench = Free
        /\ panes = 0

\* `await bench = "free"` needs no machinery at all. It is the plain conjunct
\* `bench = Free`, which simply fails to enable this action while the bench is
\* taken.
Mount(self) == /\ Trans(self, "Mount", "Cut")
               /\ bench = Free
               /\ bench' = self
               /\ UNCHANGED panes

Cut(self) == /\ Trans(self, "Cut", "Done")
             /\ bench' = Free
             /\ panes' = panes + 1

glazier(self) == Mount(self) \/ Cut(self)

\* Without this, the state where both glaziers are Done has no successor at
\* all. Disjoining it lets that state stutter forever instead.
Terminating == /\ (\A self \in ProcSet : pc[self] = "Done")
               /\ UNCHANGED vars

Next == (\E self \in Glaziers : glazier(self))
          \/ Terminating

Spec == Init /\ [][Next]_vars

CutterHoldsBench == \A g \in Glaziers : pc[g] = "Cut" => bench = g
BenchHolderIsCutting == \A g \in Glaziers : bench = g => pc[g] = "Cut"
====
