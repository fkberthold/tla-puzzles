---- MODULE Shape ----
EXTENDS Integers, Sequences
VARIABLES rec, fn, seq
vars == <<rec, fn, seq>>

\* One operator over all three shapes. It never asks which one it has.
Bump(f, k) == [f EXCEPT ![k] = @ + 1]

Init == /\ rec = [hits |-> 0, misses |-> 0]
        /\ fn  = [k \in {"hits", "misses"} |-> 0]
        /\ seq = <<0, 0>>

Next == /\ rec' = Bump(rec, "hits")
        /\ fn'  = Bump(fn, "hits")
        /\ seq' = Bump(seq, 1)

Spec == Init /\ [][Next]_vars
Cap == rec.hits <= 2

\* The record literal and the function literal are one value, not two.
SameValue == rec = fn

\* DOMAIN reads all three.
Domains == /\ DOMAIN rec = {"hits", "misses"}
           /\ DOMAIN seq = 1..Len(seq)

\* Two spellings of one lookup.
TwoSpellings == rec.hits = rec["hits"]

\* A sequence rebuilt as a function literal is the same sequence.
SeqIsFn == seq = [i \in 1..Len(seq) |-> seq[i]]

Unified == SameValue /\ Domains /\ TwoSpellings /\ SeqIsFn

\* The claim a reader starts with, and it is false.
Separate == rec # fn
======================
