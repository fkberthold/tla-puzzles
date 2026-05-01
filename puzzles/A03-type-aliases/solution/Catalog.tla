---- MODULE Catalog ----
EXTENDS Integers, Sequences

\* @typeAlias: book = { title: Str, pages: Int };
\* @typeAlias: borrowing = { book: $book, patron: Str };
CatalogTypes == TRUE

VARIABLES
  \* @type: Set($book);
  shelf,
  \* @type: Seq($borrowing);
  recent,
  \* @type: $book;
  featured
vars == << shelf, recent, featured >>

Hamlet == [ title |-> "Hamlet", pages |-> 200 ]
Dune   == [ title |-> "Dune",   pages |-> 600 ]

Init ==
  /\ shelf    = { Hamlet, Dune }
  /\ recent   = << >>
  /\ featured = Hamlet

Borrow ==
  \E b \in shelf, p \in { "alice", "bob" }:
    /\ shelf'  = shelf \ { b }
    /\ recent' = Append(recent, [ book |-> b, patron |-> p ])
    /\ featured' = featured

Done ==
  /\ shelf = {}
  /\ UNCHANGED vars

Next == Borrow \/ Done

Spec == Init /\ [][Next]_vars

TypeOK ==
  /\ shelf \subseteq { Hamlet, Dune }
  /\ Len(recent) <= 2
  /\ featured.title \in { "Hamlet", "Dune" }
====
