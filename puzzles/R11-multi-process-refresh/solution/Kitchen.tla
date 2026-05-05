---- MODULE Kitchen ----
EXTENDS Integers, TLC

(*--algorithm Kitchen {
  variables dish = FALSE, delivered = 0;

  define {
    TypeOK == dish \in BOOLEAN /\ delivered \in 0..3
    OrderedDelivery == delivered <= 3
    EventuallyDone == <>(delivered = 3)
  }

  fair process (chef = "Chef") {
    cook:
      while (delivered < 3) {
        await ~dish;
        dish := TRUE;
      }
  }

  fair process (server = "Server") {
    take:
      while (delivered < 3) {
        await dish;
        dish := FALSE;
        delivered := delivered + 1;
      }
  }
}
*)
\* BEGIN TRANSLATION
\* END TRANSLATION
====
