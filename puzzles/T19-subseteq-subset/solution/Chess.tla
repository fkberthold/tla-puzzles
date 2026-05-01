---- MODULE Chess ----
EXTENDS Integers, TLC

(*--algorithm Chess {
  variables
    roster = {"a", "b", "c", "d"},
    team = {},
    captain = "none",
    phase = 0;

  define {
    TypeOK ==
      /\ team \subseteq roster
      /\ captain \in roster \cup {"none"}
      /\ phase \in 0..2
    CaptainConsistent == phase = 2 => (captain = "none" \/ captain \in team)
  }

  fair process (coach = "Coach") {
    pickTeam:
      with (t \in SUBSET roster) {
        team := t;
      };
      phase := phase + 1;
    pickCaptain:
      with (c \in team \cup {"none"}) {
        captain := c;
      };
      phase := phase + 1;
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "2147f55a" /\ chksum(tla) = "ac6b1d9f")
VARIABLES roster, team, captain, phase, pc

(* define statement *)
TypeOK ==
  /\ team \subseteq roster
  /\ captain \in roster \cup {"none"}
  /\ phase \in 0..2
CaptainConsistent == phase = 2 => (captain = "none" \/ captain \in team)


vars == << roster, team, captain, phase, pc >>

ProcSet == {"Coach"}

Init == (* Global variables *)
        /\ roster = {"a", "b", "c", "d"}
        /\ team = {}
        /\ captain = "none"
        /\ phase = 0
        /\ pc = [self \in ProcSet |-> "pickTeam"]

pickTeam == /\ pc["Coach"] = "pickTeam"
            /\ \E t \in SUBSET roster:
                 team' = t
            /\ phase' = phase + 1
            /\ pc' = [pc EXCEPT !["Coach"] = "pickCaptain"]
            /\ UNCHANGED << roster, captain >>

pickCaptain == /\ pc["Coach"] = "pickCaptain"
               /\ \E c \in team \cup {"none"}:
                    captain' = c
               /\ phase' = phase + 1
               /\ pc' = [pc EXCEPT !["Coach"] = "Done"]
               /\ UNCHANGED << roster, team >>

coach == pickTeam \/ pickCaptain

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == coach
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(coach)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
