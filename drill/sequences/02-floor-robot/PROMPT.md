# Floor robot

A cleaning robot works a floor of nine tiles, three rows of three. It
keeps a record of every tile it has stood on since it was last set down,
in order, and it won't stand on a tile that is already in the record. Each
move is to a tile that shares an edge with the one it's on. At any time
the operator may lift it, set it down on any tile, and wipe the record, so
the record starts again with that one tile.

Write the specification from an empty file. Say what the record can be.
State two rules: every move in the record is between tiles that share an
edge, and no tile appears in the record twice.

Check it. A correct model finds 653 distinct states.
