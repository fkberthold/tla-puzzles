---- MODULE OffByOne ----
EXTENDS Integers, TLC

(*--algorithm OffByOne {
  variables count = 3, done = FALSE;

  define {
    TypeOK == count \in 0..3 /\ done \in {TRUE, FALSE}
    DoneImpliesZero == done = TRUE => count = 0
  }

  fair process (counter = "Counter") {
    loop:
      \* BUG: loop exits when count > 0 is false, i.e., count = 0
      \* But we decrement FIRST, so we go 3->2->1->0 then exit
      \* and set done. Actually that's correct...
      \* The real bug: use count > 1 as condition — exits at count=1
      while (count > 1) {
        count := count - 1;
      };
    finish:
      done := TRUE;
      \* BUG: count is 1 here, not 0!
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION

================================
