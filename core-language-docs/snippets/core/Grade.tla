---- MODULE Grade ----
EXTENDS Integers
VARIABLE score

Init == score = 0
Next == score < 3 /\ score' = score + 1
Spec == Init /\ [][Next]_<<score>>

\* Three arms and no OTHER. Nothing matches at score = 0.
Band == CASE score = 1 -> "low"
          [] score = 2 -> "mid"
          [] score = 3 -> "high"

\* The same arms with a fallthrough.
Banded == CASE score = 1 -> "low"
            [] score = 2 -> "mid"
            [] score = 3 -> "high"
            [] OTHER     -> "none"

\* Two arms that both match at score = 2 and at score = 3.
Overlap == CASE score >= 1 -> "first"
             [] score >= 2 -> "second"

\* Each of these forces its CASE to be evaluated in every state.
NoOther == Band \in {"low", "mid", "high"}
WithOther == Banded \in {"low", "mid", "high", "none"}
FirstArm == score < 1 \/ Overlap = "first"
========================
