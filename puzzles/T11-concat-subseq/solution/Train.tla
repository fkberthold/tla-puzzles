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
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
