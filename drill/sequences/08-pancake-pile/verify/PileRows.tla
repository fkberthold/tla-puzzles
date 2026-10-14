---- MODULE PileRows ----
\* The behaviour table from PROMPT.md as data: the pile before and after
\* each flip, top pancake first. No cfg, so the drill gate reads this as a
\* helper.
EXTENDS Sequences

Row(before, after) == <<before, after>>

Rows == <<
  Row(<<3, 1, 4, 2>>, <<1, 3, 4, 2>>),
  Row(<<1, 3, 4, 2>>, <<4, 3, 1, 2>>),
  Row(<<4, 3, 1, 2>>, <<2, 1, 3, 4>>),
  Row(<<2, 1, 3, 4>>, <<1, 2, 3, 4>>)
>>
====
