---- MODULE MusicApp ----
EXTENDS Integers

VARIABLE song

TypeOK == song \in [title: {"Etude"}, plays: 0..5, liked: BOOLEAN]

Init == song = [title |-> "Etude", plays |-> 0, liked |-> FALSE]

Play ==
  /\ song.plays < 5
  /\ song' = [song EXCEPT !.plays = @ + 1]

ToggleLike ==
  song' = [song EXCEPT !.liked = ~@]

Next == Play \/ ToggleLike

Spec == Init /\ [][Next]_song
====
