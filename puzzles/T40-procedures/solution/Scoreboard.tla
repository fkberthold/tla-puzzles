---- MODULE Scoreboard ----
EXTENDS Integers, Sequences, TLC

(*--algorithm Scoreboard {
  variables homeScore = 0, awayScore = 0;

  define {
    TypeOK == homeScore \in 0..10 /\ awayScore \in 0..10
    BoundedScores == homeScore <= 5 /\ awayScore <= 5
    FinalState ==
      (\A p \in {"RefA", "RefB"}: pc[p] = "Done")
        => (homeScore = 5 /\ awayScore = 5)
  }

  procedure award(team = "home", pts = 0) {
    awardStep:
      if (team = "home") {
        homeScore := homeScore + pts;
      } else {
        awayScore := awayScore + pts;
      };
      return;
  }

  fair process (refA = "RefA") {
    a1: call award("home", 3);
    a2: call award("away", 2);
  }

  fair process (refB = "RefB") {
    b1: call award("home", 2);
    b2: call award("away", 3);
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "61c06718" /\ chksum(tla) = "5f316a5d")
VARIABLES pc, homeScore, awayScore, stack

(* define statement *)
TypeOK == homeScore \in 0..10 /\ awayScore \in 0..10
BoundedScores == homeScore <= 5 /\ awayScore <= 5
FinalState ==
  (\A p \in {"RefA", "RefB"}: pc[p] = "Done")
    => (homeScore = 5 /\ awayScore = 5)

VARIABLES team, pts

vars == << pc, homeScore, awayScore, stack, team, pts >>

ProcSet == {"RefA"} \cup {"RefB"}

Init == (* Global variables *)
        /\ homeScore = 0
        /\ awayScore = 0
        (* Procedure award *)
        /\ team = [ self \in ProcSet |-> "home"]
        /\ pts = [ self \in ProcSet |-> 0]
        /\ stack = [self \in ProcSet |-> << >>]
        /\ pc = [self \in ProcSet |-> CASE self = "RefA" -> "a1"
                                        [] self = "RefB" -> "b1"]

awardStep(self) == /\ pc[self] = "awardStep"
                   /\ IF team[self] = "home"
                         THEN /\ homeScore' = homeScore + pts[self]
                              /\ UNCHANGED awayScore
                         ELSE /\ awayScore' = awayScore + pts[self]
                              /\ UNCHANGED homeScore
                   /\ pc' = [pc EXCEPT ![self] = Head(stack[self]).pc]
                   /\ team' = [team EXCEPT ![self] = Head(stack[self]).team]
                   /\ pts' = [pts EXCEPT ![self] = Head(stack[self]).pts]
                   /\ stack' = [stack EXCEPT ![self] = Tail(stack[self])]

award(self) == awardStep(self)

a1 == /\ pc["RefA"] = "a1"
      /\ /\ pts' = [pts EXCEPT !["RefA"] = 3]
         /\ stack' = [stack EXCEPT !["RefA"] = << [ procedure |->  "award",
                                                    pc        |->  "a2",
                                                    team      |->  team["RefA"],
                                                    pts       |->  pts["RefA"] ] >>
                                                \o stack["RefA"]]
         /\ team' = [team EXCEPT !["RefA"] = "home"]
      /\ pc' = [pc EXCEPT !["RefA"] = "awardStep"]
      /\ UNCHANGED << homeScore, awayScore >>

a2 == /\ pc["RefA"] = "a2"
      /\ /\ pts' = [pts EXCEPT !["RefA"] = 2]
         /\ stack' = [stack EXCEPT !["RefA"] = << [ procedure |->  "award",
                                                    pc        |->  "Done",
                                                    team      |->  team["RefA"],
                                                    pts       |->  pts["RefA"] ] >>
                                                \o stack["RefA"]]
         /\ team' = [team EXCEPT !["RefA"] = "away"]
      /\ pc' = [pc EXCEPT !["RefA"] = "awardStep"]
      /\ UNCHANGED << homeScore, awayScore >>

refA == a1 \/ a2

b1 == /\ pc["RefB"] = "b1"
      /\ /\ pts' = [pts EXCEPT !["RefB"] = 2]
         /\ stack' = [stack EXCEPT !["RefB"] = << [ procedure |->  "award",
                                                    pc        |->  "b2",
                                                    team      |->  team["RefB"],
                                                    pts       |->  pts["RefB"] ] >>
                                                \o stack["RefB"]]
         /\ team' = [team EXCEPT !["RefB"] = "home"]
      /\ pc' = [pc EXCEPT !["RefB"] = "awardStep"]
      /\ UNCHANGED << homeScore, awayScore >>

b2 == /\ pc["RefB"] = "b2"
      /\ /\ pts' = [pts EXCEPT !["RefB"] = 3]
         /\ stack' = [stack EXCEPT !["RefB"] = << [ procedure |->  "award",
                                                    pc        |->  "Done",
                                                    team      |->  team["RefB"],
                                                    pts       |->  pts["RefB"] ] >>
                                                \o stack["RefB"]]
         /\ team' = [team EXCEPT !["RefB"] = "away"]
      /\ pc' = [pc EXCEPT !["RefB"] = "awardStep"]
      /\ UNCHANGED << homeScore, awayScore >>

refB == b1 \/ b2

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == refA \/ refB
           \/ (\E self \in ProcSet: award(self))
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(refA) /\ WF_vars(award("RefA"))
        /\ WF_vars(refB) /\ WF_vars(award("RefB"))

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
