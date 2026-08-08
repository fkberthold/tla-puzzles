# Requirement 5: shares move two ways only

A share changes only at its product's placement or at its member's collection after arrival, and a collection changes nothing else.

Members Ana, Ben, and Cai. Products oats and oil. `Min = 3`, `Cap = 2`.
Each step shows the whole of `Observe` at that moment.

## A run the club can produce

Your model must allow this run.

One share moves at placement, and Ana's moves again at her collection, to zero, the whole of it. Oil stays open the entire run, and nobody waits for it.

```
Step 1, the opening
  phase   oats open, oil open
  book    oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 2, Ana sets her oats pledge to 2
  phase   oats open, oil open
  book    oats: Ana 2, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 3, Ben sets his oats pledge to 1
  phase   oats open, oil open
  book    oats: Ana 2, Ben 1, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 4, the coordinator places oats
  phase   oats placed, oil open
  book    oats: Ana 2, Ben 1, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 2, Ben 1, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 5, oats arrives
  phase   oats arrived, oil open
  book    oats: Ana 2, Ben 1, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 2, Ben 1, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 6, Ana collects her oats share
  phase   oats arrived, oil open
  book    oats: Ana 2, Ben 1, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 1, Cai 0 | oil: Ana 0, Ben 0, Cai 0
```

## A run that breaks the requirement

Your model must rule this run out.

Ana collects while oats is still placed. The goods haven't arrived, and her share moves anyway.

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

Step 4, oats goes open to placed, and Ana's oats share goes 0 to 1, and Ben's oats share goes 0 to 2
  phase   oats placed, oil open
  book    oats: Ana 1, Ben 2, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 1, Ben 2, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 5, Ana's oats share goes 1 to 0
  phase   oats placed, oil open
  book    oats: Ana 1, Ben 2, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 2, Cai 0 | oil: Ana 0, Ben 0, Cai 0
```
