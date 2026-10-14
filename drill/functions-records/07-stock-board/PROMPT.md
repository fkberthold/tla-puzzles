# The stock board

A plant nursery keeps a stock board for three lines: rose, fern and ivy.
The board is a table with one row per line and two columns, on hand and
promised to customers. On a Tuesday afternoon it might read like this.

| line | on hand | promised |
|---|---|---|
| rose | 2 | 1 |
| fern | 0 | 0 |
| ivy | 1 | 1 |

The bench holds at most 2 plants of a line. Restocking adds one plant of a
line to the bench. Promising reserves one plant of a line for a customer,
and only a plant that is on the bench and not yet promised can be
promised. Delivering hands over one promised plant: the line's on-hand
count and its promised count both drop by one. Every line starts at zero in
both columns.

The rule: a line is never promised more plants than it has on hand.

Write the specification and the rule from an empty file. Check it with
deadlock checking on. A correct model finds 216 distinct states and reports
no error.

Then say, in one sentence, how your model reads the cell for ivy's promised
count, and in another how it writes it.
