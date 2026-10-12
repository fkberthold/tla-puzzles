# Window display

A grocer stacks cans in the shop window in one of two styles. The style is
chosen when the display is started and kept until it's taken down.

- Pyramid: the k-th row from the top holds k cans.
- Wall: every row holds the same number of cans, the window's width.

The stacker adds a row at the bottom or takes the bottom row away, one row at
a time, up to a maximum height, and keeps a running count of cans in the
window.

Write the specification from an empty file. Say what every variable can be.
State the rule: the running count always equals what the style says the rows
should hold. Write "what the style says" as one definition that serves both
styles, given a style's rule for a row and the number of rows.

Check it with a width of 3 and a maximum of 4 rows. A correct model finds 10
distinct states.
