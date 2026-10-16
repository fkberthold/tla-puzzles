# Recall reps

A need stated in English, the notation typed, graded on one exit code, in
about a third of a second. The other rungs in this corpus declare eight to
twelve minutes an item, so this is the one that runs at flow speed.

## How to work one

```bash
recall/recall.sh R001 '[Wagons -> Tracks]'
```

Quote the answer. Almost every TLA+ expression carries a character your shell
wants for itself.

Correct answers stop there. A wrong one prints both values, and TLC's own
printout of them is usually the whole explanation:

```
R001  the set of all the ways the wagons could be parked, one track each
rep=R001 rc=10 token=ASSUMPTION_FAILED grade=incorrect

not correct. what you typed, then the answer.

you typed   [w \in Wagons |-> Tracks]
  [a |-> 1..3, b |-> 1..3, c |-> 1..3]
  Attempted to compute cardinality of the value
  [a |-> 1..3, b |-> 1..3, c |-> 1..3]
  (no count: TLC will not count that value, so it is not a set)

the answer  [Wagons -> Tracks]
  { [a |-> 1, b |-> 1, c |-> 1],
    ... 25 more ...
    [a |-> 3, b |-> 3, c |-> 3] }
  27
```

One function against a set of 27 of them. Nobody wrote that comparison. It is
what the two values look like.

## Any correct form passes

The grade is value equality, so these all score 0 on R001:

```
[Wagons -> Tracks]
{f \in [Wagons -> Tracks] : TRUE}
```

That property is the reason the grade is a TLA+ assumption rather than a
string comparison, and it is what keeps a rep from being a spelling test.

## The four verdicts

| grade | code | what it means |
|---|---|---|
| `correct` | 0 | the two values are equal |
| `incorrect` | 10 | the assumption came back false |
| `parse-error` | 150 | SANY rejected it, so nothing was graded |
| `other` | whatever came back | a report about the run, not about the answer |

The exit code is the raw code `harness/verdict.sh` returned, never one read
back out of anything TLC printed. Two codes belong to the runner instead, and
both happen before TLC starts, so neither collides: `2` is a usage error and
`3` is "could not run" -- no such rep, no environment file, no scratch
directory.

`parse-error` is its own row on purpose. Telling somebody their answer is
wrong when it never parsed is a false statement about a check that did not
happen.

A type mismatch is *not* a parse error. `Answer == 7` against a set of
functions is simply false, so it scores 10 and gets the value block like any
other wrong answer.

## The rep table

`REPS.tsv`, tab-delimited, with the literal first field `REP` so prose in the
file can never be read as data. The convention is `drill/INVENTORY.md`'s.

| # | field | contents |
|---|---|---|
| 1 | marker | the literal `REP` |
| 2 | id | stable, never renumbered |
| 3 | construct | `K001`-`K105`, a `drill/INVENTORY.md` row |
| 4 | environment | resolves to `env/<name>.tla` |
| 5 | prompt | English, naming none of the notation it asks for |
| 6 | canonical | the answer, as TLA+ |

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
