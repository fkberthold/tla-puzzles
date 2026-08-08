# Requirement 1: the opening

Every product starts open, every pledge and every share starts at zero, nothing has arrived.

Members Ana, Ben, and Cai. Products oats and oil. `Min = 3`, `Cap = 2`.
Each step shows the whole of `Observe` at that moment.

## A run the club can produce

Your model must allow this run.

The club at the start. Nothing has happened yet, and this is the only place a run may begin.

```
Step 1, the opening
  phase   oats open, oil open
  book    oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
```

## A run that breaks the requirement

Your model must rule this run out.

This run begins with a unit already in every pledge. It is wrong before anyone moves.

```
Step 1, where this run starts
  phase   oats open, oil open
  book    oats: Ana 1, Ben 1, Cai 1 | oil: Ana 1, Ben 1, Cai 1
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
```
