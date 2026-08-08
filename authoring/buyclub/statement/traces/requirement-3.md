# Requirement 3: the minimum

A product moves from open to placed only at a step where its pledges total at least `Min` (here, 3).

Members Ana, Ben, and Cai. Products oats and oil. `Min = 3`, `Cap = 2`.
Each step shows the whole of `Observe` at that moment.

## A run the club can produce

Your model must allow this run.

The total crosses the minimum, falls back under when Ben withdraws, and crosses again. The order goes in at a total of 4. Nothing forced it in earlier, and nothing froze the book while it sat over the minimum.

```
Step 1, the opening
  phase   oats open, oil open
  book    oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 2, Ana sets her oats pledge to 2
  phase   oats open, oil open
  book    oats: Ana 2, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 3, Ben sets his oats pledge to 2 (total 4, over the minimum)
  phase   oats open, oil open
  book    oats: Ana 2, Ben 2, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 4, Ben withdraws his oats pledge (total 2, under the minimum)
  phase   oats open, oil open
  book    oats: Ana 2, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 5, Cai sets her oats pledge to 1 (total 3)
  phase   oats open, oil open
  book    oats: Ana 2, Ben 0, Cai 1 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 6, Ben pledges 1 on oats again (total 4)
  phase   oats open, oil open
  book    oats: Ana 2, Ben 1, Cai 1 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 7, the coordinator places oats at a total of 4
  phase   oats placed, oil open
  book    oats: Ana 2, Ben 1, Cai 1 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 2, Ben 1, Cai 1 | oil: Ana 0, Ben 0, Cai 0
```

## A run that breaks the requirement

Your model must rule this run out.

The order for oats goes in on an empty book, total zero against a minimum of 3.

```
Step 1, where this run starts
  phase   oats open, oil open
  book    oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 2, oats goes open to placed
  phase   oats placed, oil open
  book    oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
```
