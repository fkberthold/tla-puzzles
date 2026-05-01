---- MODULE Train ----
EXTENDS Integers, Sequences, TLC

(*--algorithm Train {
  variables
    morning = <<"A", "B", "C">>,
    afternoon = <<"D", "E", "F">>,
    fullDay = <<>>,
    middleThree = <<>>,
    phase = 0;

  define {
    TotalLen == Len(fullDay)
    SliceLen == Len(middleThree)

    TypeOK == TotalLen \in {0, 6} /\ SliceLen \in {0, 3} /\ phase \in 0..3
    LengthsAddUp == TotalLen > 0 => Len(morning) + Len(afternoon) = TotalLen
    MiddleStations == phase >= 2 => middleThree = <<"B", "C", "D">>
  }

  fair process (dispatcher = "Dispatch") {
    combine:
      fullDay := morning \o afternoon;
      phase := phase + 1;
    slice:
      middleThree := SubSeq(fullDay, 2, 4);
      phase := phase + 1;
    finish:
      phase := phase + 1;
  }
}

*)
\* BEGIN TRANSLATION (chksum(pcal) = "dfa5e157" /\ chksum(tla) = "4beafde5")
VARIABLES morning, afternoon, fullDay, middleThree, phase, pc

(* define statement *)
TotalLen == Len(fullDay)
SliceLen == Len(middleThree)

TypeOK == TotalLen \in {0, 6} /\ SliceLen \in {0, 3} /\ phase \in 0..3
LengthsAddUp == TotalLen > 0 => Len(morning) + Len(afternoon) = TotalLen
MiddleStations == phase >= 2 => middleThree = <<"B", "C", "D">>


vars == << morning, afternoon, fullDay, middleThree, phase, pc >>

ProcSet == {"Dispatch"}

Init == (* Global variables *)
        /\ morning = <<"A", "B", "C">>
        /\ afternoon = <<"D", "E", "F">>
        /\ fullDay = <<>>
        /\ middleThree = <<>>
        /\ phase = 0
        /\ pc = [self \in ProcSet |-> "combine"]

combine == /\ pc["Dispatch"] = "combine"
           /\ fullDay' = morning \o afternoon
           /\ phase' = phase + 1
           /\ pc' = [pc EXCEPT !["Dispatch"] = "slice"]
           /\ UNCHANGED << morning, afternoon, middleThree >>

slice == /\ pc["Dispatch"] = "slice"
         /\ middleThree' = SubSeq(fullDay, 2, 4)
         /\ phase' = phase + 1
         /\ pc' = [pc EXCEPT !["Dispatch"] = "finish"]
         /\ UNCHANGED << morning, afternoon, fullDay >>

finish == /\ pc["Dispatch"] = "finish"
          /\ phase' = phase + 1
          /\ pc' = [pc EXCEPT !["Dispatch"] = "Done"]
          /\ UNCHANGED << morning, afternoon, fullDay, middleThree >>

dispatcher == combine \/ slice \/ finish

(* Allow infinite stuttering to prevent deadlock on termination. *)
Terminating == /\ \A self \in ProcSet: pc[self] = "Done"
               /\ UNCHANGED vars

Next == dispatcher
           \/ Terminating

Spec == /\ Init /\ [][Next]_vars
        /\ WF_vars(dispatcher)

Termination == <>(\A self \in ProcSet: pc[self] = "Done")

\* END TRANSLATION 
================================
