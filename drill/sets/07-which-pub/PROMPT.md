# Which pub

Four friends are settling on a pub for Friday. There are three pubs in reach.
Each friend says which one he wants, once, in any order, and nobody has to go
first. A friend who has said his pub doesn't get to change it.

A pub is settled when more than half the friends have named it. Nobody keeps
count out loud, so the rule is about the votes already cast rather than about
anybody announcing a result.

Two rules the evening has to keep:

1. No friend has named two pubs.
2. No more than one pub is ever settled.

Write the specification from an empty file, with both rules as named checks, and
run it with four friends and three pubs. A correct model finds 256 distinct
states.

Then say a pub is settled at half the friends rather than more than half, run it
again, and read the trace TLC gives you. Count the votes in it before you read
anything else.
