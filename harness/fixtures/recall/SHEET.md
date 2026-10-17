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

K095 IS HERE FOR THE SPEC ROWS, which are graded on a vector of exit codes
rather than on a value and have no value block to carry the explanation. The
sheet entry and the miss row are therefore a larger share of what a wrong
spec answer is told, which is why one spec rep reaches an entry and part 15
asserts that it does. K068 and K079, the other two spec reps' constructs, are
left out so the silence path is covered for that row kind as well.

The bodies below are the real file's, byte for byte, backticks and all, so
the stripping the runner does on the way out is exercised rather than
assumed.

- K001  ch02  Operator definition
  `Name(a, b) == expr` (or `Name == expr` with no arguments)

- K047  ch06  function literal
  `F == [x \in S |-> expr]`, called with `F[x]`

- K050  ch06  function set
  `[S -> T]` is the set of all functions from `S` to `T`

- K095  ch12  WF_v(A) (weak fairness)
  `WF_v(A) == <>[](ENABLED <<A>>_v) => []<><<A>>_v`. If `A` is eventually always able to happen in a way that changes `v`, it eventually does.
