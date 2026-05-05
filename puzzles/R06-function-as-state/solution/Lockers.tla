---- MODULE Lockers ----
EXTENDS TLC

Members == {"Anna", "Ben", "Cleo"}

(*--algorithm Lockers {
  variables locker = [m \in Members |-> "closed"];

  define {
    TypeOK == \A m \in Members : locker[m] \in {"open", "closed"}
    DoneImpliesClosed ==
      \A m \in Members : pc[m] = "Done" => locker[m] = "closed"
  }

  fair process (member \in Members) {
    open:
      locker[self] := "open";
    use:
      skip;
    close:
      locker[self] := "closed";
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
