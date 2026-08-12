--------------------------- MODULE Ex4FerryRoute ---------------------------
\* Reference answer for exercise 4, "The ferry route".
\* Everything below the answer block is scaffolding. Leave it alone.

EXTENDS Integers, Sequences

\* ---------------- answer block, this is what you write ----------------

FirstStop(route) == Head(route)

LastStop(route) == route[Len(route)]

Between(route) == SubSeq(route, 2, Len(route) - 1)

Extend(route, stop) == Append(route, stop)

Onward(route, spur) == route \o Tail(spur)

\* ---------------- scaffolding below this line ----------------

Coast == <<"quay", "isle", "point", "harbour">>
Spur  == <<"harbour", "reef">>
Short == <<"quay", "isle">>

VARIABLE probe

Init == probe = 0
Next == UNCHANGED probe

\* The invariant pins the answers. A wrong body makes TLC report
\* `RouteIsRight` as violated.
\*
\* The `probe = 0` line is load bearing. Without it every conjunct is a
\* constant, TLC folds the whole invariant before the run starts, and a wrong
\* answer comes back as a config error instead of a violation.
RouteIsRight ==
    /\ probe = 0
    /\ FirstStop(Coast) = "quay"
    /\ LastStop(Coast) = "harbour"
    /\ LastStop(Short) = "isle"
    /\ Between(Coast) = <<"isle", "point">>
    /\ Between(Short) = <<>>
    /\ Extend(Coast, "reef") = <<"quay", "isle", "point", "harbour", "reef">>
    /\ Onward(Coast, Spur) = <<"quay", "isle", "point", "harbour", "reef">>
    /\ Len(Onward(Coast, Spur)) = 5

===========================================================================
