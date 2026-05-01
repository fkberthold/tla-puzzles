---- MODULE Tasks ----
EXTENDS FiniteSets, TLC

CONSTANT Workers, Boss

VARIABLE done

Init == done = {}

\* Anyone may finish a task EXCEPT Boss, who only supervises.
Finish == \E w \in Workers \ done : w # Boss /\ done' = done \cup {w}

Done == done = Workers \ {Boss}

Next == Finish /\ ~Done

vars == << done >>

Spec == Init /\ [][Next]_vars

TypeOK == done \subseteq Workers

\* This is what we WANT to declare as the symmetry.
\* For symmetry to be sound: every model value the operator permutes
\* must be INTERCHANGEABLE in the spec body.
WorkerSym == Permutations(Workers \ {Boss})

================================
