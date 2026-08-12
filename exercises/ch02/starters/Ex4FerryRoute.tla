--------------------------- MODULE Ex4FerryRoute ---------------------------
\* Starter for exercise 4, "The ferry route".
\* Write your answers in the answer block. Leave the scaffolding alone.
\*
\* Run it before you write anything. It will not parse, and the error names
\* an operator you have not defined yet. That is your first checkpoint.

EXTENDS Integers, Sequences

\* ---------------- answer block, this is what you write ----------------

\* Define `FirstStop`, `LastStop`, `Between`, `Extend` and `Onward` here.
\* The prompt is in EXERCISES.md.



\* ---------------- scaffolding below this line ----------------

Coast == <<"quay", "isle", "point", "harbour">>
Spur  == <<"harbour", "reef">>
Short == <<"quay", "isle">>

VARIABLE probe

Init == probe = 0
Next == UNCHANGED probe

\* The invariant pins the answers. A wrong body makes TLC report
\* `RouteIsRight` as violated.
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
