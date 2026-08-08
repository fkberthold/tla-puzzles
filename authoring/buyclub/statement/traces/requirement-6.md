# Requirement 6: phases run forward

Phases move only open to placed to arrived, one product per step, and a phase step leaves the book and the other shares alone.

Members Ana, Ben, and Cai. Products oats and oil. `Min = 3`, `Cap = 2`.
Each step shows the whole of `Observe` at that moment.

## A run the club can produce

Your model must allow this run.

Oats walks open, placed, arrived, one move per step, and oil never moves at all.

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
```

## A run that breaks the requirement

Your model must rule this run out.

One delivery step moves both products to arrived at once. Phases move one product per step.

```
Step 1, where this run starts
  phase   oats open, oil open
  book    oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 2, Ana's oats pledge goes 0 to 1
  phase   oats open, oil open
  book    oats: Ana 1, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 3, Ana's oil pledge goes 0 to 1
  phase   oats open, oil open
  book    oats: Ana 1, Ben 0, Cai 0 | oil: Ana 1, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 4, Ben's oats pledge goes 0 to 2
  phase   oats open, oil open
  book    oats: Ana 1, Ben 2, Cai 0 | oil: Ana 1, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 5, Ben's oil pledge goes 0 to 2
  phase   oats open, oil open
  book    oats: Ana 1, Ben 2, Cai 0 | oil: Ana 1, Ben 2, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 6, oats goes open to placed, and Ana's oats share goes 0 to 1, and Ben's oats share goes 0 to 2
  phase   oats placed, oil open
  book    oats: Ana 1, Ben 2, Cai 0 | oil: Ana 1, Ben 2, Cai 0
  share   oats: Ana 1, Ben 2, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 7, oil goes open to placed, and Ana's oil share goes 0 to 1, and Ben's oil share goes 0 to 2
  phase   oats placed, oil placed
  book    oats: Ana 1, Ben 2, Cai 0 | oil: Ana 1, Ben 2, Cai 0
  share   oats: Ana 1, Ben 2, Cai 0 | oil: Ana 1, Ben 2, Cai 0

Step 8, oats goes placed to arrived, and oil goes placed to arrived
  phase   oats arrived, oil arrived
  book    oats: Ana 1, Ben 2, Cai 0 | oil: Ana 1, Ben 2, Cai 0
  share   oats: Ana 1, Ben 2, Cai 0 | oil: Ana 1, Ben 2, Cai 0
```
