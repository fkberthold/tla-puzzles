---- MODULE Shelves ----
EXTENDS Naturals, FiniteSets

CONSTANTS N, Member, Cap
ASSUME N \in Nat /\ Cap \in Nat

Title == 1..N
Slot == 1..N

Shelved == [slot: Slot]
Lent == [to: Member, home: Slot]

VARIABLE book
vars == <<book>>

TypeOK == book \in [Title -> Shelved \cup Lent]

Init == book = [t \in Title |-> [slot |-> t]]

OnShelf(t) == "slot" \in DOMAIN book[t]

\* The slot a title owns, under whichever field name holds it now.
Home(t) == IF OnShelf(t) THEN book[t].slot ELSE book[t].home

Held(m) == {t \in Title : ~OnShelf(t) /\ book[t].to = m}

Lend(t, m) ==
  /\ OnShelf(t)
  /\ Cardinality(Held(m)) < Cap
  /\ book' = [book EXCEPT ![t] = [to |-> m, home |-> book[t].slot]]

Return(t) ==
  /\ ~OnShelf(t)
  /\ book' = [book EXCEPT ![t] = [slot |-> book[t].home]]

Swap(a, b) ==
  /\ a # b
  /\ OnShelf(a)
  /\ OnShelf(b)
  /\ book' = [book EXCEPT ![a].slot = book[b].slot,
                          ![b].slot = book[a].slot]

Next ==
  \/ \E t \in Title, m \in Member : Lend(t, m)
  \/ \E t \in Title : Return(t)
  \/ \E a, b \in Title : Swap(a, b)

Spec == Init /\ [][Next]_vars

SlotsDistinct == \A a, b \in Title : a # b => Home(a) # Home(b)

Quota == \A m \in Member : Cardinality(Held(m)) <= Cap
====
