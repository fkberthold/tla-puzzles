------------------------------ MODULE Pool ------------------------------
EXTENDS Naturals, FiniteSets, Sequences, TLC

CONSTANTS Workers, Slots

ASSUME Slots \in Nat

VARIABLES st, queue

vars == <<st, queue>>

Holders == {w \in Workers : st[w] = "holding"}

TypeOK ==
    /\ st \in [Workers -> {"idle", "waiting", "holding"}]
    /\ queue \in Seq(Workers)

Init ==
    /\ st = [w \in Workers |-> "idle"]
    /\ queue = <<>>

Want(w) ==
    /\ st[w] = "idle"
    /\ st' = [st EXCEPT ![w] = "waiting"]
    /\ queue' = Append(queue, w)

Take(w) ==
    /\ st[w] = "waiting"
    /\ queue # <<>>
    /\ Head(queue) = w
    /\ Cardinality(Holders) < Slots
    /\ st' = [st EXCEPT ![w] = "holding"]
    /\ queue' = Tail(queue)

Release(w) ==
    /\ st[w] = "holding"
    /\ st' = [st EXCEPT ![w] = "idle"]
    /\ UNCHANGED queue

Next == \E w \in Workers : Want(w) \/ Take(w) \/ Release(w)

Spec == Init /\ [][Next]_vars

NeverOversubscribed == Cardinality(Holders) <= Slots

Perms == Permutations(Workers)

==========================================================================
