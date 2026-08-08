# Requirement 8: delivery comes

Every placed product eventually arrives.

Members Ana, Ben, and Cai. Products oats and oil. `Min = 3`, `Cap = 2`.
Each step shows the whole of `Observe` at that moment.

## A run the club can produce

Your model must allow this run.

The order goes in, club life continues (Ben pledges on oil), and the goods arrive. Delivery is the one thing in this system that must happen.

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

Step 5, Ben sets his oil pledge to 2 (life goes on while oats is placed)
  phase   oats placed, oil open
  book    oats: Ana 2, Ben 0, Cai 1 | oil: Ana 0, Ben 2, Cai 0
  share   oats: Ana 2, Ben 0, Cai 1 | oil: Ana 0, Ben 0, Cai 0

Step 6, oats arrives
  phase   oats arrived, oil open
  book    oats: Ana 2, Ben 0, Cai 1 | oil: Ana 0, Ben 2, Cai 0
  share   oats: Ana 2, Ben 0, Cai 1 | oil: Ana 0, Ben 0, Cai 0
```

## A run that breaks the requirement

Your model must rule this run out.

Oats is placed at step 9 and never arrives. Oil's whole story completes around it, and then the run stops moving, forever.

```
Step 1, where this run starts
  phase   oats open, oil open
  book    oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 2, Ben's oil pledge goes 0 to 2
  phase   oats open, oil open
  book    oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 2, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 3, Ben's oats pledge goes 0 to 1
  phase   oats open, oil open
  book    oats: Ana 0, Ben 1, Cai 0 | oil: Ana 0, Ben 2, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 4, Cai's oats pledge goes 0 to 1
  phase   oats open, oil open
  book    oats: Ana 0, Ben 1, Cai 1 | oil: Ana 0, Ben 2, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 5, Cai's oil pledge goes 0 to 1
  phase   oats open, oil open
  book    oats: Ana 0, Ben 1, Cai 1 | oil: Ana 0, Ben 2, Cai 1
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 6, Ana's oil pledge goes 0 to 1
  phase   oats open, oil open
  book    oats: Ana 0, Ben 1, Cai 1 | oil: Ana 1, Ben 2, Cai 1
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 7, oil goes open to placed, and Ana's oil share goes 0 to 1, and Ben's oil share goes 0 to 2, and Cai's oil share goes 0 to 1
  phase   oats open, oil placed
  book    oats: Ana 0, Ben 1, Cai 1 | oil: Ana 1, Ben 2, Cai 1
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 1, Ben 2, Cai 1

Step 8, Ana's oats pledge goes 0 to 1
  phase   oats open, oil placed
  book    oats: Ana 1, Ben 1, Cai 1 | oil: Ana 1, Ben 2, Cai 1
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 1, Ben 2, Cai 1

Step 9, oats goes open to placed, and Ana's oats share goes 0 to 1, and Ben's oats share goes 0 to 1, and Cai's oats share goes 0 to 1
  phase   oats placed, oil placed
  book    oats: Ana 1, Ben 1, Cai 1 | oil: Ana 1, Ben 2, Cai 1
  share   oats: Ana 1, Ben 1, Cai 1 | oil: Ana 1, Ben 2, Cai 1

Step 10, oil goes placed to arrived
  phase   oats placed, oil arrived
  book    oats: Ana 1, Ben 1, Cai 1 | oil: Ana 1, Ben 2, Cai 1
  share   oats: Ana 1, Ben 1, Cai 1 | oil: Ana 1, Ben 2, Cai 1

Step 11, Cai's oil share goes 1 to 0
  phase   oats placed, oil arrived
  book    oats: Ana 1, Ben 1, Cai 1 | oil: Ana 1, Ben 2, Cai 1
  share   oats: Ana 1, Ben 1, Cai 1 | oil: Ana 1, Ben 2, Cai 0

Step 12, Ana's oil share goes 1 to 0
  phase   oats placed, oil arrived
  book    oats: Ana 1, Ben 1, Cai 1 | oil: Ana 1, Ben 2, Cai 1
  share   oats: Ana 1, Ben 1, Cai 1 | oil: Ana 0, Ben 2, Cai 0

Step 13, Ben's oil share goes 2 to 0
  phase   oats placed, oil arrived
  book    oats: Ana 1, Ben 1, Cai 1 | oil: Ana 1, Ben 2, Cai 1
  share   oats: Ana 1, Ben 1, Cai 1 | oil: Ana 0, Ben 0, Cai 0
```

A run never ends, so read step 13 as the club's last word: from here nothing more happens, ever. Oats stays placed and the goods never come.
