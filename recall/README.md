# Recall reps

A need stated in English, the notation typed, graded on one exit code, in
about a third of a second. The other rungs in this corpus declare eight to
twelve minutes an item, so this is the one that runs at flow speed.

160 reps over 57 constructs, in two kinds:

| kind | reps | constructs | the answer is | the grade is |
|---|---|---|---|---|
| `REP` | 120 | 37, the value-producing families | an expression | value equality |
| `SPEC` | 40 | 20, the whole `temporal` family | a promise, a property, an action, a declaration | the vector of exit codes a set of machines returns |

A session serves both. You do not choose and you do not need to know which
kind you are answering: you read a sentence of English and type notation, and
what happens under it is the runner's problem.

## Working a session

A session serves reps one after another. It prints the prompt, reads what you
type, grades it, shows the block below, and moves on.

```bash
recall/recall.sh --session
recall/recall.sh --session --count 20
recall/recall.sh --session --seed 41
```

```
R107  every possible parking of this yard, each wagon on exactly one track
> [Wagons -> Tracks]
rep=R107 rc=0 token=OK grade=correct

correct.

R099  the parking that leaves every wagon on the first track
> [w \in Wagons |-> 1]
rep=R099 rc=0 token=OK grade=correct

correct.

2 reps, 2 right.
```

You never type a rep id. That saves keystrokes, and it closes something
worse. Until 2026-10-17 the only way to find out what a rep asked was to open
`REPS.tsv`. Field 5 sits on the same tab-delimited line as field 6, so
reading the question handed over the answer. That's the lookup this rung
exists to replace.

A session re-enters the runner once per rep, so what it grades is the
single-rep invocation below. There's no second grading path to drift from the
first.

### Which rep comes next

Not uniform random. `REPS.tsv` carries two to six differently phrased reps per
construct, so the fact gets retrieved rather than the sentence. Interleaving
is stronger when consecutive items are close enough to confuse, and most of
what `MISSES.tsv` records is a function written where a function set was
wanted. That's one construct against its neighbor.

Two reps of one construct back to back is the other failure. You typed the
answer a second ago, so the second one is recognition rather than recall.

So the walk draws the next rep from a construct within two positions of the
one just served, and never from that construct itself. The rest of that
construct's reps stay in the pool and come round again a rep or two later.

Position means file order, and that's a measurement rather than a guess.
`REPS.tsv` is sorted by family, then by construct, and one construct's reps
are contiguous. Measured on 2026-10-17: 120 reps, 37 constructs, four
unbroken family runs. So 33 of the 36 adjacent construct pairs share a
family, which is what lets the window be read off the delivered table alone.
A delivered tree carries no `drill/INVENTORY.md`, and nothing here reads a
family.

`--seed N` pins the draw, so a session can be run again.

At the tail the walk repeats a construct rather than stopping. Once every
unserved rep belongs to the construct you just did, I'd rather break the lag
than end the session short.

### How a session ends

| exit | what does it |
|---|---|
| `--count N` | N reps, then the tally |
| Ctrl-D | the end of your input, at a terminal or in a pipe |
| the table | every rep served once, and it says so |

Ctrl-D leaves one prompt unanswered on screen. The prompt goes out before the
read can find out there's nothing left to read, so the last question you see
is the one you declined.

A blank line skips the rep and shows the answer. You've declined the attempt
the answer was being kept from, so withholding it there teaches nothing. A
skip runs no TLC at all.

A session exits 0 whenever it ran. It isn't a grade, so it carries none. Each
rep's grade stays on that rep's own status line.

### Nothing is kept between sessions

`scripts/deliver-recall.sh` overwrites every file it delivers, and its header
justifies that by saying no file here is learner-owned. A progress file would
make that false, and a delivery would then overwrite your own record in a tree
that isn't a git repo. That's the shape of the 2026-10-02 incident that took
39 delivered files.

I don't think the rung wants one either. A drill item declares eight to twelve
minutes and mustn't be lost. A rep costs about a third of a second, so a
session that ends has cost you nothing. What a session does hold, for as long
as it runs, is which reps it has served, so none of them comes round twice.

## How to work one

```bash
recall/recall.sh R107 '[Wagons -> Tracks]'
recall/recall.sh R012 '-4'
```

Quote the answer. Almost every TLA+ expression carries a character your shell
wants for itself.

A leading dash is fine, and the second line above is why. Negative integers
are ordinary answers at this rung, so once the rep id is in hand the next
argument is the answer whatever it starts with. The cost is that flags go
before the rep id, which is where you would put them anyway.

`--no-prompt` drops the prompt line from the block. It's what a session hands
its own child, having printed that line and read an answer under it already.

Correct answers stop there. A wrong one prints both values, then what that
answer says, then what the construct is:

```
R107  every possible parking of this yard, each wagon on exactly one track
rep=R107 rc=10 token=ASSUMPTION_FAILED grade=incorrect

not correct. what you typed, then the answer.

you typed   [w \in Wagons |-> Tracks]
  [a |-> 1..3, b |-> 1..3, c |-> 1..3]
  Attempted to compute cardinality of the value
  [a |-> 1..3, b |-> 1..3, c |-> 1..3]
  (no count: TLC will not count that value, so it is not a set)

the answer  [Wagons -> Tracks]
  { [a |-> 1, b |-> 1, c |-> 1],
    [a |-> 1, b |-> 1, c |-> 2],
    ... 24 more lines, and --full shows them all ...
    [a |-> 3, b |-> 3, c |-> 3] }
  27

what you wrote says
  That's one parking, and what it gives back for every wagon is the whole set
  of tracks rather than a single track.

K050  ch06  function set
  [S -> T] is the set of all functions from S to T
```

The top half is one function against a set of 27 of them. Nobody wrote that
comparison; it is what the two values look like. The bottom half is the next
section.

## Spec reps, and why they exist

68 of the 105 constructs say nothing about a value. `WF_v(A)` is a promise
about a behavior, not an expression with a value, and `ASSUME Answer =
Canonical` over it is not false, it is meaningless. The whole `temporal`
family is that problem, and it was 0 of 20 on this rung until 2026-10-17.

So a spec rep puts the answer in a machine and runs the machine. The answer
fills a hole in a scaffold, TLC checks the scaffold, and **the key is the exit
code** — the same contract the value reps have, read off a model check instead
of off an assumption.

```
S001  the weaker of the two promises that can be made about the lift's own
      rise, enough that it cannot be left standing while the lamp carries on
> WF_vars(Blink)
rep=S001 rc=5 token=SPEC_NOT_MATCHED grade=incorrect

not correct. this is what the spec it is checked against made of it.

  a goods lift standing beside a lamp. the lift rises twice and then has
  nowhere left to go; the lamp flips for ever, so something can always move.
    wanted rc 0 OK, and it came back rc 13 LIVENESS_VIOLATION

the answer is:
  WF_vars(Raise)

what you wrote says
  That promises the lamp keeps flipping, which it would do anyway. The lift
  is the thing that can be left standing, and this says nothing about it.

K095  ch12  WF_v(A) (weak fairness)
  WF_v(A) == <>[](ENABLED <<A>>_v) => []<><<A>>_v. If A is eventually always
  able to happen in a way that changes v, it eventually does.
```

There is no value block, because there is no value. What stands in its place
is one line per machine: what the rep wanted that machine to say, and what it
said.

### The key is a vector, not a code

One run cannot grade a property. A property **weaker** than the one asked for
also holds, and `[]TRUE` holds on everything. So most spec reps name two or
more machines and the key is the vector:

```
S013  that the lift reaches the second floor and from then on is never
      anywhere else
> []<>(level = 2)
rep=S013 rc=5 token=SPEC_NOT_MATCHED grade=incorrect

not correct. this is what each of the 3 specs made of it.

  a lift that rises to the second floor and then has nowhere left to go, with
  a lamp that keeps flashing beside it for ever.
    as wanted: rc 0 OK

  a lift that rises to the second floor, drops straight back to the ground
  and starts again, over and over, with a lamp flashing beside it.
    wanted rc 13 LIVENESS_VIOLATION, and it came back rc 0 OK
...
```

The machine that **agreed** is shown too, and it is half the lesson: the
answer did hold where it was meant to. The next line says where it did not.

Two sides are not always enough either. `<>(level = 1)` has the same two-sided
profile as `<>(level = 2)`, which is why S011 names four machines.

### The three holes

| hole | reps | the answer is | the key is |
|---|---|---|---|
| fairness | S001-S008 | the conjunct beside `Init` and the step relation | one exit code |
| property | S009-S026 | the formula the config registers | a vector of two to four |
| action | S027-S040 | an action, a `Spec` body, a `vars` tuple, or the `VARIABLES` line | an invariant in the scaffold and a state-graph fingerprint |

### Any correct form still passes

The grade comes from what TLC said about the machine, never from the text. So
`UNCHANGED lamp` and `lamp' = lamp` both score 0 on the same rep, and so do
`WF_vars(Raise)` and `WF_vars(Raise) /\ WF_vars(Blink)`.

### What field 7 is doing on every spec row

An exit code cannot see **how** a verdict was reached, so the construct gate
carries more weight here than it does on a value rep.

Measured: `<>(level = 2)` dropped into the fairness hole scores 0. It is the
goal asserted as a hypothesis rather than a fairness condition, and no run can
tell. `\bWF_` in field 7 closes it, and the refusal says the construct was not
written, which is exactly what happened.

### What a spec rep cannot see

Two measured holes, stated here rather than left to be found:

- **A wrong subscript in a `Spec` body.** `Init /\ [][Next]_level` and `Init
  /\ [][Next]_vars` give the identical state graph — 6 states, diameter 4,
  11 generated — because TLC builds successors from `Next` and the subscript
  only decides which steps count as stuttering. No fingerprint reaches it.
  The `vars` tuple has reps of its own for that reason, and their key is a
  battery over two machines that stop moving in different places.
- **A property about the only perpetual mover.** On S026's two-machine
  battery, `[]<>(lamp = 1)` shares the canonical's vector, because the lamp is
  the thing that moves. It is not recorded as a miss for that rep, since it is
  not caught.

## What it needs

`tlc` on the path, and nothing else. No harness beside this directory, no repo
above it, no environment variable to set. An absent `tlc` is exit `3` with a
message rather than a quiet pass, so a tree that cannot grade says so on the
first rep instead of scoring one.

`drill/SHEET.md` is the one optional file, and it is read from the parent of
this directory. It carries the construct entry a wrong answer ends on. A tree
without it grades every rep exactly as before and prints two layers instead of
three, which is silence rather than a refusal.

**This was not true until 2026-10-17.** The runner used to resolve
`harness/verdict.sh` from the parent directory and refuse to start without it,
so a delivered tree answered exit `3` to every rep and every answer, right
ones included. It now runs TLC itself, under the same flags that channel runs
it under, and names five exit codes, three of which a grading run can reach.
Bead `tla-1sh7.10`, and the runner's own header carries the measurement.

## The three layers under a wrong answer

The values are the first and they are not the whole of it. Two more come out
of files this script only reads, and neither one can change a grade:

| layer | source | keyed on | says |
|---|---|---|---|
| the two values | TLC | the answer and the canonical | what each one is |
| the misconception | `MISSES.tsv` | the text that was typed | what that answer says |
| the construct | `drill/SHEET.md` | the rep's field 3 | what the construct is |

`--sheet` and `--misses` point either one somewhere else, and a file that is
not there is silence rather than a refusal. An explanation is not a verdict,
so a delivered tree without them still grades every rep in it. What stops a
path quietly breaking is the gate instead: `harness/test-recall-runner.sh`
runs one live rep through the shipped defaults, and checks that every rep's
construct has an entry and every miss row names a rep that exists.

**The miss row goes above the sheet entry**, and the reason is the 90 reps
with no row rather than the 30 that have one. This order ends on the sheet
entry at all 120. The other order ends on the sheet at 90 and on the
misconception at 30, so the bottom of the block moves under you. Reading R099
both ways is the clearest single case: its entry, `F == [x \in S |-> expr]`,
sitting directly under the canonical answer `[w \in Wagons |-> 1]` restates
the line above it, and the same entry after the misconception reads as the
general form of what was just explained.

**Nothing announces an absence.** 90 of the 120 reps carry no miss row, so no
row is the ordinary case and not the fallback. Two values and a sheet entry
is a whole answer, and you are not told that a table you cannot see had
nothing to say.

**A construct-gate refusal gets the sheet entry too**, because that is the
one grade whose entire content is that a construct was not written, and field
7 is an ERE rather than notation. It gets no miss row: the value was right,
and that table is about wrong ones.

## The miss table is matched on tokens, not on text

`MISSES.tsv` field 3 is the wrong answer verbatim, and the lookup normalises
whitespace before comparing. The rule is one sentence: **a space is kept only
where it stands between two word characters, and dropped everywhere else.**
That is the only place TLA+ needs one. So all four of these reach the same
row, and the fifth does not:

```
[w \in Wagons |-> Tracks]       the row's own spelling
[w \in Wagons|->Tracks]         no spaces round the arrow
[ w  \in  Wagons  |->  Tracks ] padded and doubled
[w \in Wagons |->	Tracks]     a tab
[w \inWagons |-> Tracks]        a different token sequence, so no row
```

Exact text was the other candidate and it loses on this script's own
argument. The grade is value equality precisely so that any correct form
passes and a rep is not a spelling test. Keying the explanation on the
byte-for-byte shape of a wrong answer puts the spelling test back one layer
down, where it costs a row somebody wrote and nobody sees. 30 rows is small
enough to match exactly; it is not small enough to be worth missing one.

Normalising gives up one thing: TLA+'s bullet-list alignment, since a run of
whitespace is what groups a stacked `/\` and `\/` list. Re-grouping a list of
one operator cannot change what it says, so the condition that makes this
safe is that no row mixes the two operators. That is a gate rather than a
note.

It is not keyed on the *value*. A second grading run against the row's own
expression would fire on any answer that evaluates the same, which is a wider
net than field 4 is written for: "that's a set, so it holds no order" is a
sentence about a shape somebody typed.

## The value block is capped

Two members, the elision, the closing member, then the count. The run above
is 24 lines, and `--full` prints the same thing at 47. The cap is doing the
work in both: without it the value block alone runs to 40.

The cap is there because the point of the block is the contrast, and a value
that scrolls the terminal pushes the two halves apart. Before the cap, 27 of
R107's 40 lines were the members of `[Wagons -> Tracks]` one per line, and the
count that makes the point sat underneath them.

Both halves are capped on the same rule. I had expected the typed value to be
the small one, and at R108 and R109 it is not: the characteristic mistake
there is to swap the domain and the range, which gives a set of exactly the
size of the right answer. Five lines is still enough to recognize as yours.

The elision counts lines rather than members, and says so. TLC prints a small
value on one line and breaks a large one at about 80 columns, one member per
line, so on a flat set a line is a member. On a nested value it is not:
`[ a |->` opens at one indent and the set under it sits at another. The member
count never goes missing either way, because it is on a line of its own below.

## What a whole block costs in lines

Measured over the shipped tables on 2026-10-16, with the two prose sections
wrapped at 76 columns:

| block | lines |
|---|---|
| a wrong answer with a miss row and an entry | 21 to 25 |
| a wrong answer with an entry and no row | 17 to 21 |
| the same block before the two layers | 17 |
| the same block before the cap, layer 1 alone | 40 |

The worst is 25, at R006 and R114, and R006 is the one to look at: its
explanation is the longest in the table at 155 characters, which wraps to
three lines. The ordinary case is 21 to 24.

**Neither prose section is capped**, and that is a decision rather than an
omission. The value block is capped because an enumeration has a middle
nobody needs; an explanation cut mid-sentence costs more than the line it
saves. So the budget is held at the data instead: the suite refuses a miss
explanation or a sheet body that wraps past three lines, which is where
today's longest of each already sits.

## Any correct form passes

The grade is value equality, so these all score 0 on R107:

```
[Wagons -> Tracks]
{f \in [Wagons -> Tracks] : TRUE}
```

That property is the reason the grade is a TLA+ assumption rather than a
string comparison, and it is what keeps a rep from being a spelling test.

## The construct gate

Value equality grades the value, so it cannot see how the value was reached.
A rep that drills `LET` wants a `LET` written, and a learner who computes the
same answer without one has done a different rep. Field 7 closes that: an ERE
matched against the raw answer before a correct value is accepted.

```
REP  R003  K001  shunting  <prompt>  LET Twice(t) == t * 2 IN ...  \bLET\b
```

A row without field 7 grades exactly as it did before the field existed, so
none of the 120 live rows changed. Empty and absent both mean no gate.

The pattern names the construct's own keyword and nothing else. All three of
these are the same answer, and `\bLET\b` takes all three:

```
LET Twice(t) == t * 2 IN [t \in Tracks |-> Twice(t)]
LET Doubled(n) == n + n IN [t \in Tracks |-> Doubled(t)]
LET F == [t \in Tracks |-> t * 2] IN F
```

A pattern reaching for the shape of the whole answer, say
`^LET [A-Za-z]+\(t\) ==`, takes the first and refuses the other two. That
trades the gate for a spelling test, which is the thing value equality exists
to avoid, so measure a correct alternate against every pattern you write.

The match runs before TLC and the refusal after it. Matching first means a
pattern grep will not read is exit `3` rather than a grade, since a gate that
falls open on a malformed pattern is worse than no gate. Refusing afterwards
means a wrong value still gets its value block, and the gate only ever speaks
about an answer the grading run already accepted.

## The five verdicts

| grade | code on a `REP` row | code on a `SPEC` row | what it means |
|---|---|---|---|
| `correct` | 0 | 0 | the values are equal, or every machine said what the rep wanted |
| `construct-missing` | 4 | 4 | the answer was accepted and the construct is not in it |
| `incorrect` | 10 | 5 | the assumption came back false, or the vector did not match |
| `parse-error` | 150 | 150 | SANY rejected it, so nothing was graded |
| `other` | whatever came back | whatever came back | a report about the run, not about the answer |

The exit code is the raw code the grading run returned, never one read back
out of anything TLC printed. Four codes belong to the runner instead and none
of them collides with a code of TLC's. `2` is a usage error and `3` is "could
not run", meaning no such rep, no environment file, no scaffold pair, no `tlc`
on the path, no scratch directory. Both happen before TLC starts.

`4` is the one that happens after a run, and it replaces a grading run that
came back `0`. The status line carries `4` and the runner's own token, and the
line under it names the rc and token the grading run returned, so nothing the
run said goes missing.

`5` is a spec rep whose machines all ran and whose codes did not match the
vector. It is the runner's own number rather than one of TLC's because a spec
rep runs between one and four TLCs, so there is no single raw code to be
faithful to — and reporting the first disagreeing run's own code would put
`rc=0` on a status line reading `grade=incorrect` whenever the answer *passed*
a machine it was supposed to fail. Every code every run returned is printed
under the status line, so nothing any run said is hidden.

Which codes a spec run may return and still be graded, all four measured:
`0`, `10` (a false `POSTCONDITION`, which is how a fingerprint mismatch
reports), `12` (a broken `INVARIANT`, and also a `PROPERTY` that is a bare
state predicate under `[]`) and `13` (a temporal `PROPERTY` that did not
hold). Everything else is a report about the run: `75` from an action that
leaves a variable unspecified, `150` from SANY, `151` from an action where a
temporal formula was wanted or from `CONSTANTS` where `VARIABLES` was, `255`
from fairness over the initial predicate.

The two level mistakes are mirror images and they land on different codes. A
temporal formula in an **action** hole is `150`, and SANY says so in the
words "Level error in applying operator" rather than in anything about syntax.
An action in a **property** hole is `151`.

`11` DEADLOCK is not reachable from any scaffold, and that is a fact about the
runner rather than about the codes: every run carries TLC's `-deadlock`, which
means do *not* check, so a terminal state is never an error.

`parse-error` is its own row on purpose. Telling somebody their answer is
wrong when it never parsed is a false statement about a check that did not
happen.

A session carries none of these. It exits 0 whenever it ran, and 2 or 3 when
it couldn't start. Each rep's code stays on that rep's status line, which is
the only place a grade belongs.

A type mismatch is *not* a parse error. `Answer == 7` against a set of
functions is simply false, so it scores 10 and gets the value block like any
other wrong answer.

## The rep table

`REPS.tsv`, tab-delimited, with the row kind in field 1 so prose in the file
can never be read as data. The convention is `drill/INVENTORY.md`'s.

A `REP` row:

| # | field | contents |
|---|---|---|
| 1 | marker | the literal `REP` |
| 2 | id | stable, never renumbered |
| 3 | construct | `K001`-`K105`, a `drill/INVENTORY.md` row |
| 4 | environment | resolves to `env/<name>.tla` |
| 5 | prompt | English, naming none of the notation it asks for |
| 6 | canonical | the answer, as TLA+ |
| 7 | requires | optional, an ERE the raw answer has to match |

A `SPEC` row. Fields 1, 2, 3, 5 and 6 are the same thing, field 7 is the same
*field*, and the rest is the machinery a vector needs:

| # | field | contents |
|---|---|---|
| 1 | marker | the literal `SPEC` |
| 2 | id | stable, never renumbered |
| 3 | construct | `K001`-`K105`, a `drill/INVENTORY.md` row |
| 4 | scaffolds | comma-separated; each resolves to **both** `env/spec/<name>.tla` and `env/spec/<name>.cfg` |
| 5 | prompt | English, naming none of the notation it asks for |
| 6 | canonical | the answer, as TLA+ |
| 7 | requires | an ERE the raw answer has to match. Optional in the format, and on all 40 rows in practice |
| 8 | expect | comma-separated exit codes, one per scaffold, in the scaffolds' own order. This is the key |
| 9 | check | optional; fills a scaffold's `__CHECK__` hole |

Field 7 is deliberately the same index in both kinds, so there is one rule to
learn: **field 7 is the construct gate, whatever the row kind.**

```bash
awk -F'\t' '$1 == "REP" && $2 == "R001"' recall/REPS.tsv
grep '^REP' recall/REPS.tsv | cut -f2,3        # id and construct
```

Read rows with `awk -F'\t'` or `cut`, never with `IFS=$'\t' read`. Tab is an
IFS whitespace character, so `read` folds a run of tabs into one delimiter and
drops a trailing empty field, which shifts every field after it without
saying so.

Field 5 is the field that decides whether a rep is a rep. "The set of all the
ways the wagons could be parked" asks for recall. "Write a function set" hands
over the construct, and the answer is then a transcription.

Field 3 is the join to `drill/SHEET.md`, which is keyed on the same `K` ids.
That is the whole of the sheet lookup: no matching, just the entry.

## The miss table

`MISSES.tsv`, beside this file, same tab-delimited convention with the literal
first field `MISS`. 90 rows: 30 over 30 of the 120 value reps, reaching 25 of
their 37 constructs, and 60 over 38 of the 40 spec reps, reaching 18 of their
20. Its own header says what each field is, where the rows came from, and
which constructs have none and why. Field 4 says what the wrong answer *is*,
never what to write instead, which is what lets it be printed under two values
that already show the right answer.

A wrong answer's code depends on the row kind — rc 10 for a value rep, rc 5
for a spec rep — and every row was submitted and watched returning its own
kind's code before it was written. The spec rows are denser than the value
rows because a spec rep has no value block above the explanation, so the miss
row is a larger share of what a learner is told.

## An environment file is a fragment, not a module

`env/<name>.tla` holds bare definitions: no module header, no `EXTENDS`, no
trailing `====`. The runner splices it verbatim into the scaffold, so it will
not load on its own, and the `.tla` suffix is for your editor rather than for
SANY.

```
\* shunting -- three wagons, three tracks.
Wagons == {"a", "b", "c"}
Tracks == 1..3
```

Keep them small and few. Several reps over one domain should share one file,
and I suspect a set of three strings plus a range of three or four integers
reaches most of the function, record and set families. That is a guess off
one environment, not a survey of the 38 constructs.

Three names are reserved, and an environment that defines one of them makes
every rep over it fail to parse, with SANY reporting a multiple declaration
rather than anything about the rep.

| name | where it lives |
|---|---|
| `Answer` | the grading scaffold |
| `Canonical` | the grading scaffold |
| `Shown` | the value probe |

## A spec scaffold is a whole module, not a fragment

`env/spec/<name>.tla` is a complete module and `env/spec/<name>.cfg` holds its
obligations. Both ship, and a rep whose scaffold is missing either half is
exit `3` rather than a grade.

```
\* a goods lift standing beside a lamp. the lift rises twice and then has
---- MODULE Scaffold ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
VARIABLES level, lamp
vars == <<level, lamp>>
Init == level = 0 /\ lamp = 0
Raise == level < 2 /\ level' = level + 1 /\ lamp' = lamp
Blink == lamp' = 1 - lamp /\ level' = level
Next == Raise \/ Blink
Fair ==
__ANSWER__
Spec == Init /\ [][Next]_vars /\ Fair
Tops == <>(level = 2)
====
```

Four rules, and a gate checks all four:

- **The module is called `Scaffold`.** The runner copies the file to
  `Scaffold.tla` beside `Scaffold.cfg` in a directory of its own and rewrites
  nothing, so a battery of three scaffolds is three directories and one
  module name.
- **The first line is a `\*` comment describing the machine.** It is what a
  wrong answer is told, so a learner reads about a lift and a lamp rather than
  about a file called `fair-lift`.
- **Exactly one line's whole content is `__ANSWER__`,** and at most one is
  `__CHECK__`. The runner replaces the line, so the scaffold author decides
  what the hole is: a fairness conjunct, a temporal property, an action, a
  `Spec` body, a `vars` tuple, or the `VARIABLES` line itself.
- **The fill never goes through a regex.** The runner reads the template a
  line at a time and compares against a fixed string. A substitution would
  read `\`, `&` and `/` as its own, so a learner's wrong answer would come
  back as a parse error about a character they did not type.

`__CHECK__` is where a per-rep expectation goes, which is what keeps one
scaffold serving many reps. The twelve action rows use it for the state-graph
fingerprint:

```
TLCGet("distinct") = 3 /\ TLCGet("diameter") = 3 /\ TLCGet("generated") = 3
```

Three numbers rather than two, and that was measured rather than chosen:
`\E n \in (level + 1)..2 : ...` and `\E n \in 0..2 : ...` both reach 3 distinct
states at diameter 2, and they generate 4 and 10.

`TLCGet("level")` returns **0** in a `POSTCONDITION` and is not the depth.
`TLCGet("diameter")` is.

## What the scaffold gives you

Every rep is checked inside this, with an empty `.cfg` beside it:

```
---- MODULE Recall ----
EXTENDS Naturals, Integers, Sequences, FiniteSets, TLC
<the environment, verbatim>
Answer == <what you typed>
Canonical == <the canonical answer>
ASSUME Answer = Canonical
====
```

The `EXTENDS` list is fixed, and an environment file cannot add to it, because
TLA+ allows one `EXTENDS` statement and it has to come first. It was measured
to reach `:>` and `@@`, which live in `TLC` rather than in a base module,
along with `Seq`, `Len`, record-field access, intervals and negative integers.
A rep needing something outside the list is a one-line change to
`EXTENDS_LIST` in `recall/recall.sh`.

## Why the count is attempted rather than guarded

`Cardinality` errors on a value that is not a set, and the error is the
clearest statement of the mistake there is: a function was written where a set
was asked for. So the runner prints the value, lets the count fail, and says
the count was skipped.

There is no guard to reach for instead, and that was measured rather than
assumed. `IsFiniteSet([w \in Wagons |-> 1])` returns `TRUE`, exit 0, on the
very value whose `Cardinality` errors, so an `IF IsFiniteSet(x) THEN
Cardinality(x)` would skip nothing.

The value and its count are a separate TLC run per value. A probe that exits
non-zero printed no count, so the skip is keyed on an exit code and nothing
reads TLC's prose to decide it. It also means the probe's own `10` -- the same
number a wrong answer scores -- can never leak out as a grade, because the
grade comes from a different run.

## Cost

About 320 ms for the grading run, measured three times on 2026-10-16 at 316,
388 and 351 ms. A correct answer is one run. A wrong one is three, because
each value gets a probe of its own, and by then you are reading rather than
drilling.

A construct-gate refusal is one run. The pattern match costs a `grep` against
one line and the block it would have printed is not printed, since the two
values are equal and showing them twice would say nothing.

The two explanation layers add no run at all. Both are one `awk` over a file
of a few hundred lines, and they happen after the grade is already decided,
so nothing a learner waits for got slower.

A session re-enters the runner once per rep, and that's what the per-rep cost
goes up by. Measured on 2026-10-17 over three runs each: a single correct rep
at 331, 306 and 294 ms, and a three-rep session at 961, 1029 and 964 ms, so
about 328 ms a rep. The extra process is under 20 ms, which is inside the
spread of the single runs.

A skip costs nothing at all. It runs no TLC, since there's no answer to
grade.

**A spec rep costs one TLC run per scaffold and nothing else.** Measured
2026-10-17, three runs each, at load 1.3:

| rep | scaffolds | ms |
|---|---|---|
| `R107`, a value rep for comparison | — | 324, 370, 338 |
| `S001`, the fairness hole | 1 | 357, 365, 341 |
| `S027`, the action hole | 1 | 336, 326, 322 |
| `S039`, a two-machine battery | 2 | 670, 686, 639 |
| `S013`, a three-machine battery | 3 | 1027, 1004, 1033 |
| `S011`, a four-machine battery | 4 | 1398, 1335, 1343 |

So a one-scaffold spec rep costs what a value rep costs, and a battery costs
that times the number of machines. 335 ms a run is the whole of it; there is
no per-rep overhead to find. A four-machine rep at 1.3 s is the most expensive
rep in the corpus and there are two of them.

A wrong spec answer costs the same as a right one, where a wrong *value*
answer costs three runs. There are no value probes to run, because there is no
value.
