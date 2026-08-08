# Requirement 4: the snapshot

At the placing step each share of that product becomes that member's standing pledge, and every other share holds still.

Members Ana, Ben, and Cai. Products oats and oil. `Min = 3`, `Cap = 2`.
Each step shows the whole of `Observe` at that moment.

## A run the club can produce

Your model must allow this run.

At the placing step every oats share becomes that member's pledge at that moment, Ben's zero included, and the oil shares hold still.

```
Step 1, the opening
  phase   oats open, oil open
  book    oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 2, Ana sets her oats pledge to 2
  phase   oats open, oil open
  book    oats: Ana 2, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 3, Cai sets her oats pledge to 1
  phase   oats open, oil open
  book    oats: Ana 2, Ben 0, Cai 1 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 4, the coordinator places oats
  phase   oats placed, oil open
  book    oats: Ana 2, Ben 0, Cai 1 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 2, Ben 0, Cai 1 | oil: Ana 0, Ben 0, Cai 0
```

## A run that breaks the requirement

Your model must rule this run out.

Placement closes oats, but nobody's pledge becomes a share. The order exists and the club's ledger says nobody is owed anything.

```
Step 1, where this run starts
  phase   oats open, oil open
  book    oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 2, Ana's oats pledge goes 0 to 1
  phase   oats open, oil open
  book    oats: Ana 1, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 3, Ben's oats pledge goes 0 to 2
  phase   oats open, oil open
  book    oats: Ana 1, Ben 2, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 4, oats goes open to placed
  phase   oats placed, oil open
  book    oats: Ana 1, Ben 2, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
```
