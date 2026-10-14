---- MODULE TriageRows ----
\* The behaviour table from PROMPT.md as data. One pair per step: the
\* (board, treated) state before and the state after. No cfg, so the drill
\* gate reads this as a helper and the *Admits modules extend it.
EXTENDS Sequences

S(b, t) == <<b, t>>
Row(before, after) == <<before, after>>

Rows == <<
  Row(S(<<>>,        <<>>),          S(<<3>>,       <<>>)),
  Row(S(<<3>>,       <<>>),          S(<<3, 1>>,    <<>>)),
  Row(S(<<3, 1>>,    <<>>),          S(<<3, 1, 4>>, <<>>)),
  Row(S(<<3, 1, 4>>, <<>>),          S(<<3, 4>>,    <<1>>)),
  Row(S(<<3, 4>>,    <<1>>),         S(<<3, 4, 2>>, <<1>>)),
  Row(S(<<3, 4, 2>>, <<1>>),         S(<<3, 4>>,    <<1, 2>>)),
  Row(S(<<3, 4>>,    <<1, 2>>),      S(<<4>>,       <<1, 2, 3>>)),
  Row(S(<<4>>,       <<1, 2, 3>>),   S(<<4, 4>>,    <<1, 2, 3>>)),
  Row(S(<<4, 4>>,    <<1, 2, 3>>),   S(<<4>>,       <<1, 2, 3, 4>>))
>>
====
