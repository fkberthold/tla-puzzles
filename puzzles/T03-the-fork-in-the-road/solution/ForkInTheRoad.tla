---- MODULE ForkInTheRoad ----
EXTENDS TLC

(*--algorithm ForkInTheRoad {
  variables location = "fork", snack = "none";

  define {
    TypeOK ==
      /\ location \in {"fork", "lake", "summit"}
      /\ snack \in {"none", "granola", "apple", "trail_mix"}
    AlwaysAtLake == location /= "summit"
    EventuallyHasSnack == <>(snack /= "none")
  }

  fair process (hiker = "Hiker") {
    choose:
      either {
        location := "lake";
      } or {
        location := "summit";
      };
    eat:
      with (s \in {"granola", "apple", "trail_mix"}) {
        snack := s;
      };
  }
}

*)
\* BEGIN TRANSLATION
\* END TRANSLATION

================================
