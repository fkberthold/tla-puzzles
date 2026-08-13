---- MODULE Ex4Tanks ----
EXTENDS Integers, TLC

\* Untranslated. Run `pcal starters/Ex4Tanks.tla` from the chapter directory
\* before you run TLC.

(*--algorithm tanks {
  variables
    tanks = <<7, 0>>;

  {
    Pump:
      \* YOUR WORK GOES HERE. Move 3 litres from tank 1 to tank 2.
      \* Both tanks change, and they change in this one step.
      \* Bind the 3 to a name instead of writing the literal twice.
      skip;
    Audit:
      assert tanks[1] + tanks[2] = 7;
    Settle:
      assert tanks[2] = 3;
  }
}
*)
====
