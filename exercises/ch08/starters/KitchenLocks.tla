---- MODULE KitchenLocks ----
\* Exercise 2 starter. This one is complete. Read it, predict, then run.
\*
\* A baker and a cook share one pan and one whisk. Each needs both before it
\* can work, takes them one at a time, and puts both back afterwards.
\* `Nobody` is a model value standing for "nobody is holding this".
EXTENDS Integers

CONSTANT Nobody

(*--algorithm kitchenlocks {
  variables pan = Nobody, whisk = Nobody;

  process (baker = "baker")
  {
    BakerTakesPan:
      await pan = Nobody;
      pan := "baker";
    BakerTakesWhisk:
      await whisk = Nobody;
      whisk := "baker";
    BakerPutsBack:
      pan := Nobody;
      whisk := Nobody;
  }

  process (cook = "cook")
  {
    CookTakesPan:
      await pan = Nobody;
      pan := "cook";
    CookTakesWhisk:
      await whisk = Nobody;
      whisk := "cook";
    CookPutsBack:
      pan := Nobody;
      whisk := Nobody;
  }
}
*)
====
