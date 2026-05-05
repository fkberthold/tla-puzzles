---- MODULE Inventory ----
EXTENDS Integers, TLC

(*--algorithm Inventory {
  variables
    apples = 5,
    bananas = 5,
    cherries = 5,
    dates = 5,
    elderberries = 5,
    figs = 5,
    grapes = 5,
    honeydew = 5,
    sold = 0;

  define {
    TypeOK ==
      /\ apples \in 0..5
      /\ bananas \in 0..5
      /\ cherries \in 0..5
      /\ dates \in 0..5
      /\ elderberries \in 0..5
      /\ figs \in 0..5
      /\ grapes \in 0..5
      /\ honeydew \in 0..5
      /\ sold \in 0..40
    \* Deliberate violation: claims sold can never reach 6 — but it can.
    NotPastFive == sold <= 5
  }

  fair process (seller = "Seller") {
    work:
      while (sold < 8) {
        either { apples := apples - 1; }
        or     { bananas := bananas - 1; }
        or     { cherries := cherries - 1; }
        or     { dates := dates - 1; };
        sold := sold + 1;
      };
  }
}
*)
\* BEGIN TRANSLATION
\* END TRANSLATION
================================
