---- MODULE Ratchet ----
EXTENDS Integers, Sequences

Steps == 4

(*--algorithm ratchet {
variables
  level = 0,
  log = <<>>;

define {
  \* TODO: replace TRUE. `s` is a sequence of readings. Nothing later in
  \* it is smaller than anything earlier. Quantify over the index pairs
  \* and rule out the pairs you do not care about.
  Nondecreasing(s) == TRUE

  LogIsNondecreasing == Nondecreasing(log)

  \* Given, and wrong on purpose. Part 2 asks you why.
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
\* BEGIN TRANSLATION (chksum(pcal) = "b129071f" /\ chksum(tla) = "6b099092")
VARIABLES pc, level, log

(* define statement *)
Nondecreasing(s) == TRUE

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
