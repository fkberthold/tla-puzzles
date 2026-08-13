---- MODULE Ratchet ----
EXTENDS Integers, Sequences

Steps == 4

(*--algorithm ratchet {
variables
  level = 0,
  log = <<>>;

define {
  Nondecreasing(s) ==
    \A a, b \in 1..Len(s):
      a < b => s[a] <= s[b]

  LogIsNondecreasing == Nondecreasing(log)

  NoDropWrong ==
    ~ \E a, b \in 1..Len(log):
        a < b => log[a] > log[b]
}

{
Tick:
  while (Len(log) < Steps) {
    with (next \in level..(level + 2)) {
      level := next;
      log := Append(log, next);
    };
  };
}
}
*)
\* BEGIN TRANSLATION (chksum(pcal) = "ceb5e30b" /\ chksum(tla) = "f2b05712")
VARIABLES pc, level, log

(* define statement *)
Nondecreasing(s) ==
  \A a, b \in 1..Len(s):
    a < b => s[a] <= s[b]

LogIsNondecreasing == Nondecreasing(log)

NoDropWrong ==
  ~ \E a, b \in 1..Len(log):
      a < b => log[a] > log[b]


vars == << pc, level, log >>

Init == (* Global variables *)
        /\ level = 0
        /\ log = <<>>
        /\ pc = "Tick"

Tick == /\ pc = "Tick"
        /\ IF Len(log) < Steps
              THEN /\ \E next \in level..(level + 2):
                        /\ level' = next
                        /\ log' = Append(log, next)
                   /\ pc' = "Tick"
              ELSE /\ pc' = "Done"
                   /\ UNCHANGED << level, log >>

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == pc = "Done" /\ UNCHANGED vars

Next == Tick
           \/ Terminating

Spec == Init /\ [][Next]_vars

Termination == <>(pc = "Done")

\* END TRANSLATION 

====
