---- MODULE DeckLogRows ----
\* The behavior table from PROMPT.md as data. One pair per step: the
\* (log, archive) state before and after. The entry counter is implied by
\* the two lists and the *Admits modules derive it. No cfg, so the drill
\* gate reads this as a helper.
EXTENDS Sequences

S(l, a) == <<l, a>>
Row(before, after) == <<before, after>>

Rows == <<
  Row(S(<<>>,        <<>>),              S(<<1>>,       <<>>)),
  Row(S(<<1>>,       <<>>),              S(<<1, 2>>,    <<>>)),
  Row(S(<<1, 2>>,    <<>>),              S(<<1, 2, 3>>, <<>>)),
  Row(S(<<1, 2, 3>>, <<>>),              S(<<3>>,       <<1, 2>>)),
  Row(S(<<3>>,       <<1, 2>>),          S(<<3, 4>>,    <<1, 2>>)),
  Row(S(<<3, 4>>,    <<1, 2>>),          S(<<3, 4, 5>>, <<1, 2>>)),
  Row(S(<<3, 4, 5>>, <<1, 2>>),          S(<<>>,        <<1, 2, 3, 4, 5>>))
>>
====
