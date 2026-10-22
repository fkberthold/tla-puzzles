---- MODULE Crate ----
EXTENDS Integers, Sequences
VARIABLE crate

Init == crate = <<"bolt">>
Unpack == crate /= <<>> /\ crate' = Tail(crate)
Next == Unpack \/ UNCHANGED crate
Spec == Init /\ [][Next]_<<crate>>

GuardedHead == crate /= <<>> => Head(crate) = "bolt"
GuardedTail == crate /= <<>> => Len(Tail(crate)) = Len(crate) - 1
BareHead == Head(crate) = "bolt"
BareTail == Tail(crate) = <<>>
======================
