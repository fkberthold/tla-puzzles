---------------------------- MODULE RetryAudit ----------------------------
EXTENDS Naturals, Sequences

CONSTANTS Budget, Strict

ASSUME Budget \in Nat
ASSUME Strict \in BOOLEAN

\* Same client, different bookkeeping. The retry decision reads a counter
\* that is reset on every submission. The outcome log is appended on every
\* attempt and never read by anything: not by the next-state relation, not
\* by the requirement. It is an audit trail, and it grows without bound
\* because jobs can be resubmitted forever.

VARIABLES status, tries, log

vars == <<status, tries, log>>

TypeOK ==
    /\ status \in {"running", "failed", "done", "abandoned"}
    /\ tries \in Nat
    /\ log \in Seq({"ok", "err"})

Init ==
    /\ status = "running"
    /\ tries = 0
    /\ log = <<>>

Succeed ==
    /\ status = "running"
    /\ status' = "done"
    /\ log' = Append(log, "ok")
    /\ UNCHANGED tries

Fail ==
    /\ status = "running"
    /\ status' = "failed"
    /\ tries' = tries + 1
    /\ log' = Append(log, "err")

\* Strict is the fix. With Strict = FALSE this is the same off-by-one as
\* RetryHistory.
Retry ==
    /\ status = "failed"
    /\ IF Strict THEN tries < Budget ELSE tries <= Budget
    /\ status' = "running"
    /\ UNCHANGED <<tries, log>>

GiveUp ==
    /\ status = "failed"
    /\ IF Strict THEN tries >= Budget ELSE tries > Budget
    /\ status' = "abandoned"
    /\ UNCHANGED <<tries, log>>

Resubmit ==
    /\ status \in {"done", "abandoned"}
    /\ status' = "running"
    /\ tries' = 0
    /\ UNCHANGED log

Next == Succeed \/ Fail \/ Retry \/ GiveUp \/ Resubmit

Spec == Init /\ [][Next]_vars

WithinBudget == tries <= Budget

\* Named in a .cfg as VIEW NoLog. Everything the next-state relation and
\* the requirement read is still in the fingerprint.
NoLog == <<status, tries>>

\* The other knob, for comparison. Named in a .cfg as CONSTRAINT LogShort.
LogShort == Len(log) <= 6

==========================================================================
