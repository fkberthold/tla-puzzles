# Traces

Every requirement in `../PROBLEM.md` ships with two behaviors. The satisfying
side of all seven is one behavior, `full-circulation.md`, a circulation that
runs right through from the opening to the last sign-off. Each violating run
gets its own file, and each file says where its behavior breaks the
requirement.

Read them before you model. If TLC later hands you a counterexample shaped
like one of these, you're standing in that trap.

## How to read the tables

Every row is one state of the observation, and nothing else. Consecutive rows
are one step apart. The columns are the five `Observe` fields, plus a
narration of the step that led in.

- **amendment**: the amendment being circulated. `0` is the standing edition.
- **working b1 b2 b3**: `working` as three numbers, one per box.
- **inHand**: the district in hand, numbered as the interface says.
- **underIssue**: the boxes she has out and hasn't closed off.
- **signedOff**: the districts she has signed off, by position.

The board isn't in the tables, because the board isn't a field. Where a
narration says the clerk wrote a line, none of the five fields moves, so the
row repeats the one above it. That's the board doing its work out of sight,
and it's the only place a table has two rows the same.

The narration column is prose about the parties. It isn't a sixth field, and
your model doesn't have to name any of it.

## The files

| File | Requirement |
|---|---|
| `full-circulation.md` | satisfies all seven |
| `requirement-1.md` | a sign-off says what it means |
| `requirement-2.md` | no box moves ahead of its turn |
| `requirement-3.md` | one district at a time |
| `requirement-4.md` | the cap holds on the last district |
| `requirement-5.md` | a box moves only under issue |
| `requirement-6.md` | the circulation never goes back |
| `requirement-7.md` | the amendment reaches every box |

## The satisfying run is the gate on over-constraint

A green check is weak evidence on its own. Seven green requirements over a
region your model can't reach tell you nothing about the region the rules
describe, and nothing goes red to say so.

`full-circulation.md` is the test for that direction, and two models I'd
expect people to write fail it rather than failing a requirement.

The first drops a box from `underIssue` on the box's own pasting step. It
can't reach row 5, where b1 works to the amendment and is still under issue.
The second has no board and no clerk at all. It can't reach row 6, because
row 6 is a step where none of the five fields moves and only a clerk's line
accounts for it.

So if your seven checks come out green and you still can't walk this run,
the problem has gone out of your model and the checks won't tell you.
