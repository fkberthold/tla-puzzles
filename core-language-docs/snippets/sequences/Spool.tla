---- MODULE Spool ----
EXTENDS Integers, Sequences
VARIABLE wire

Colors == {"red", "blue"}
Cap == 2

BoundedSeq(S, n) == UNION {[1..i -> S] : i \in 0..n}

Init == wire = <<>>
Wind == Len(wire) < Cap /\ \E c \in Colors : wire' = Append(wire, c)
Next == Wind \/ UNCHANGED wire
Spec == Init /\ [][Next]_<<wire>>

InitAny == wire \in Seq(Colors)
SpecAny == InitAny /\ [][Next]_<<wire>>

TypeOK == wire \in Seq(Colors)
Bounded == wire \in BoundedSeq(Colors, Cap)
Enumerated == \E s \in Seq(Colors) : s = wire
======================
