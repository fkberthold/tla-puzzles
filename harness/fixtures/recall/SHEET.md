# Fixture construct sheet for harness/test-recall-runner.sh (bead tla-1sh7.6)

This pins the FORMAT `drill/SHEET.md` uses: an entry is a `- Kxxx  chNN
Name` line and the one line under it, and the `K` id is the join to field 3
of a rep row. The real sheet is generated from the 12 chapter cheat sheets by
`scripts/gen-sheet.sh` and carries 105 entries.

WHY THE LINE COUNTS ARE PINNED AGAINST THIS FILE AND NOT AGAINST THE REAL
ONE. `drill/SHEET.md` is regenerated from `exercises/ch*/CHEATSHEET.md`, so a
sentence added to a cheat sheet moves a body from one wrapped line to two and
would turn a block-length row red for a reason that has nothing to do with
the runner. The real file is still reached: the last part of the suite runs
one live rep through the shipped defaults, which is what proves
`drill/SHEET.md` and `recall/MISSES.tsv` resolve at the paths the runner
actually ships with.

K087 IS LEFT OUT ON PURPOSE. Fixture rep R004 drills it, so R004 is the rep
with no entry, and that is how the suite reaches the silence path without
needing a second sheet file. Every construct a sheet does not carry has to
cost the learner nothing but the entry.

The bodies below are the real file's, byte for byte, backticks and all, so
the stripping the runner does on the way out is exercised rather than
assumed.

- K001  ch02  Operator definition
  `Name(a, b) == expr` (or `Name == expr` with no arguments)

- K047  ch06  function literal
  `F == [x \in S |-> expr]`, called with `F[x]`

- K050  ch06  function set
  `[S -> T]` is the set of all functions from `S` to `T`
