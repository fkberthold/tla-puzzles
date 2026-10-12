# Answer: the summary record

Files in `verify/`. `Warehouse.tla` is the system, with a `PerItem`
constant for the fix. `MCWarehouse.tla` names the two items and defines
the stock function, since a `.cfg` can't assign a function.

Every number from `tlc -workers 1` on TLC2 Version 2026.07.31.184830.

## Question 1: which keyword does what

The summary is

```
Summary == [free |-> TotalStock - TotalHeld, held |-> TotalHeld]
```

and the four keywords that can take its name:

| keyword | what it does with the name | states a claim |
|---|---|---|
| `INVARIANT` | evaluates it in every state, wants a boolean | yes |
| `ALIAS` | evaluates it when printing a trace, prints the fields | no |
| `VIEW` | fingerprints states by it instead of by the variables | no |
| `SYMMETRY` | reads it as a set of permutations | no |

Only the first states anything, and it wants a boolean. `Summary` is a
record, so `INVARIANT Summary` and `PROPERTY Summary` both exit 75 on
the initial state with "TLC expected a boolean value, but did not find
one". The claim has to be an operator that reads the summary and returns
a boolean, and then it's an ordinary invariant:

```
NoOverReserve == \A i \in Items : reserved[i] <= Stock[i]
```

`ALIAS Shown`, with `Shown` the summary plus the raw `reserved`, found
the same violation (rc 12, 4 states, depth 3) and printed each trace
state as `free`, `held` and `reserved`. That's the display job, and it's
the only thing a record built from the state is wired to in the corpus.

## Question 2: the colleague's view

`VIEW Summary`, buggy model: rc 12, 3 distinct states against 4. It
found the bug because the path to it, reserve the first item twice, runs
through states whose totals differ at each step, so none of them looked
like a state TLC had already seen.

It wouldn't always. The view says two states with the same totals are
the same state, and the bug is about where the units sit, not how many
there are. A violating state that's only reachable through a state with
the same totals as one TLC already expanded is never generated. Item 03
in this family measures that shape on a different model, where the view
turns a violation at depth 8 into a clean run at depth 2.

The 3 cost one state here and could have cost the verdict. On the fixed
model the view gives 4 distinct against 6, same rc 0. Lamport's warning
at *Specifying Systems* p. 244 is the general case: under a non-default
view "TLC may stop before it has found all reachable states".

## Question 3: a boolean claim over the summary

```
SummaryIsSane == Summary.free >= 0 /\ Summary.held <= TotalStock
```

Legal, boolean, and it exits 0 on the buggy model at 10 distinct states.
The summary adds the two items up, and a per-item fault vanishes in the
sum. A claim is only as sharp as what it reads, and this one reads two
totals. The requirement is about each item, so the claim has to read
each item.

## Question 4: the corpus

176 definitions in 666 modules have a record body with two or more
fields. 10 are wired to `ALIAS`, 0 to `VIEW`, 0 declared as an
`INVARIANT` or a `PROPERTY`. The other 166 are data: graph values, SVG
constructors, animation frames (`.claude/rules/tla-practice.md`, section
5). Building a record from the variables and stating a claim over it is
not something published specs do. The idiom exists, and its job is
display.

## A wrong knob, measured

`SYMMETRY ItemPerms` with `ItemPerms == Permutations(Items)`: rc 12, 3
states. It caught the bug, and I think only because the item with less
stock is the one TLC enumerates first. The two items aren't
interchangeable (one has stock 1, the other 2), so the permutation set
is unsound here, and item 02 shows what unsound symmetry does to a
verdict when the enumeration order runs the other way.

## Variants worth running

Add a third item with stock 1. `NoOverReserve` still finds the bug.
`SummaryIsSane` still doesn't.

Change `Shown` to drop `reserved`. The trace prints only totals, and the
step that goes over is invisible in it. ALIAS controls what you see, so
what you leave out, you don't see.

## Gate rows

One thin wrapper module per run the drill gate reproduces, each with a
copy of the config it stands for. The rc is what `harness/verdict.sh`
returns.

| module | rc | stands for |
|---|---|---|
| `G05Bug.tla` | rc 12 | `Buggy.cfg`, the claim stated as a boolean, the bug found |
| `G05Fixed.tla` | rc 0 | `Fixed.cfg`, the per-item guard |
| `G05Record.tla` | rc 75 | `InvariantRecord.cfg`, the record named where a claim goes |
| `G05Alias.tla` | rc 12 | `AliasShown.cfg`, the record named where a display goes, bug still found |
| `G05Sane.tla` | rc 0 | `SummarySane.cfg`, a boolean claim over the summary that can't see the fault |

## why-not-in-prompt

The prompt says "four config keywords can take the summary's name",
which tells the reader the count and that they're config keywords. It
also quotes the error message, which names the type that was wanted. A
reader who knows what `INVARIANT` wants has question 1's first row from
the message.

What the prompt withholds: all four names, which one prints, which one
fingerprints, that the display one is the only attested use, and the
corpus counts. Question 4 asks for a guess before the lookup so the
reader commits to a number.

The honest caveat: the measurements table in the prompt labels each row
by what was done ("named as the thing to print"), which is the
keyword's job in prose. I couldn't give four verdicts without saying
which was which, and four unlabelled rows would be a guessing game
rather than a drill.
