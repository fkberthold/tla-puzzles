# Requirement 7: shares tell the book's truth

An open product carries only zero shares, and a placed or arrived product carries each member's book entry or zero.

Members Ana, Ben, and Cai. Products oats and oil. `Min = 3`, `Cap = 2`.
Each step shows the whole of `Observe` at that moment.

## A run the club can produce

Your model must allow this run.

While oats is open every share is zero. From placement on, each member holds their book entry or zero: Ben's revision landed before the book closed, and after he collects, his share reads zero against a book entry of 1.

```
Step 1, the opening
  phase   oats open, oil open
  book    oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 2, Ana sets her oats pledge to 2
  phase   oats open, oil open
  book    oats: Ana 2, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 3, Ben sets his oats pledge to 2
  phase   oats open, oil open
  book    oats: Ana 2, Ben 2, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 4, Ben revises his oats pledge down to 1
  phase   oats open, oil open
  book    oats: Ana 2, Ben 1, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 5, the coordinator places oats
  phase   oats placed, oil open
  book    oats: Ana 2, Ben 1, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 2, Ben 1, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 6, oats arrives
  phase   oats arrived, oil open
  book    oats: Ana 2, Ben 1, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 2, Ben 1, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 7, Ben collects his oats share
  phase   oats arrived, oil open
  book    oats: Ana 2, Ben 1, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 2, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
```

## A run that breaks the requirement

Your model must rule this run out.

Ana's pledge change moves her share while oats is still open. An open product carries only zero shares.

```
Step 1, where this run starts
  phase   oats open, oil open
  book    oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 0, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0

Step 2, Ana's oats pledge goes 0 to 1, and Ana's oats share goes 0 to 1
  phase   oats open, oil open
  book    oats: Ana 1, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
  share   oats: Ana 1, Ben 0, Cai 0 | oil: Ana 0, Ben 0, Cai 0
```
