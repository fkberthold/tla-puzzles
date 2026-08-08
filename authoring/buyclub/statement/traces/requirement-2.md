# Requirement 2: one hand on the book

A step that changes the book changes one member's pledge on one open product, and nothing else.

Members Ana, Ben, and Cai. Products oats and oil. `Min = 3`, `Cap = 2`.
Each step shows the whole of `Observe` at that moment.

## A run the club can produce

Your model must allow this run.

Three pledge changes, one book entry at a time. Ana's revision down at the end is just another change.

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

Step 4, Ana revises her oats pledge down to 1
  phase   oats open, oil open
  book    oats: Ana 1, Ben 1, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
```

## A run that breaks the requirement

Your model must rule this run out.

One step writes Ana's whole row: her oats pledge and her oil pledge move together.

```
Step 1, where this run starts
  phase   oats open, oil open
  book    oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 2, Ana's oats pledge goes 0 to 1, and Ana's oil pledge goes 0 to 1
  phase   oats open, oil open
  book    oats: Ana 1, Ben 0, Cai 0 | oil: Ana 1, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
```
