---- MODULE UndoRows ----
\* The behavior table from PROMPT.md as data: the history before and
\* after each step. No cfg, so the drill gate reads this as a helper.
EXTENDS Sequences

Row(before, after) == <<before, after>>

Rows == <<
  Row(<<>>,              <<"a">>),
  Row(<<"a">>,           <<"a", "b">>),
  Row(<<"a", "b">>,      <<"a", "b", "c">>),
  Row(<<"a", "b", "c">>, <<"b", "c", "d">>),
  Row(<<"b", "c", "d">>, <<"b", "c">>),
  Row(<<"b", "c">>,      <<"b", "c", "a">>),
  Row(<<"b", "c", "a">>, <<"b", "c">>),
  Row(<<"b", "c">>,      <<"b">>)
>>
====
