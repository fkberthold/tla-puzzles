------------------------ MODULE Ex4FerryRouteBroken ------------------------
\* Seeded-wrong variant of `Ex4FerryRoute`. Run this to see the check go red.
\* One edit against the reference: `Between` starts its slice at index 1
\* instead of index 2, which is what 0-indexed habits produce.

EXTENDS Integers, Sequences

FirstStop(route) == Head(route)

LastStop(route) == route[Len(route)]

Between(route) == SubSeq(route, 1, Len(route) - 1)

Extend(route, stop) == Append(route, stop)

Onward(route, spur) == route \o Tail(spur)

Coast == <<"quay", "isle", "point", "harbour">>
Spur  == <<"harbour", "reef">>
Short == <<"quay", "isle">>

VARIABLE probe

Init == probe = 0
Next == UNCHANGED probe

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
