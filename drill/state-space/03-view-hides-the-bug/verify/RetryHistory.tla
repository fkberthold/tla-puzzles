--------------------------- MODULE RetryHistory ---------------------------
EXTENDS Naturals, Sequences, FiniteSets

CONSTANT Budget

ASSUME Budget \in Nat

\* The client keeps the outcome of every attempt and decides whether to
\* retry by counting the errors in that history. The history is read by
\* the next-state relation, so it is state and not bookkeeping.

VARIABLES status, log

vars == <<status, log>>

Errs == Cardinality({i \in 1..Len(log) : log[i] = "err"})

TypeOK ==
    /\ status \in {"running", "failed", "done", "abandoned"}
    /\ log \in Seq({"ok", "err"})

Init ==
    /\ status = "running"
    /\ log = <<>>

Succeed ==
    /\ status = "running"
    /\ status' = "done"
    /\ log' = Append(log, "ok")

Fail ==
    /\ status = "running"
    /\ status' = "failed"
    /\ log' = Append(log, "err")

\* The bug: <= where < was meant, so one attempt too many is allowed.
Retry ==
    /\ status = "failed"
    /\ Errs <= Budget
    /\ status' = "running"
    /\ UNCHANGED log

GiveUp ==
    /\ status = "failed"
    /\ Errs > Budget
    /\ status' = "abandoned"
    /\ UNCHANGED log

Next == Succeed \/ Fail \/ Retry \/ GiveUp

Spec == Init /\ [][Next]_vars

WithinBudget == Errs <= Budget

\* Named in a .cfg as VIEW StatusOnly. The history is dropped from the
\* fingerprint, so every "failed" state looks like every other.
StatusOnly == <<status>>

==========================================================================
