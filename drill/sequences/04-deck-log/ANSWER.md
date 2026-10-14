# Deck log: answer

## The answer

```tla
---- MODULE DeckLog ----
EXTENDS Naturals, Sequences

CONSTANT MaxEntry

VARIABLES log, archive, next

vars == <<log, archive, next>>

TypeOK ==
  /\ log \in Seq(1..MaxEntry)
  /\ archive \in Seq(1..MaxEntry)
  /\ next \in 1..(MaxEntry + 1)

Init ==
  /\ log = <<>>
  /\ archive = <<>>
  /\ next = 1

Write ==
  /\ next <= MaxEntry
  /\ log' = Append(log, next)
  /\ next' = next + 1
  /\ UNCHANGED archive

Archive == \E k \in 1..Len(log) :
  /\ archive' = archive \o SubSeq(log, 1, k)
  /\ log' = SubSeq(log, k + 1, Len(log))
  /\ UNCHANGED next

Next == Write \/ Archive

Spec == Init /\ [][Next]_vars

Numbered ==
  /\ \A i \in DOMAIN archive : archive[i] = i
  /\ \A i \in DOMAIN log : log[i] = Len(archive) + i

NothingLost == Len(archive) + Len(log) = next - 1
====
```

```
SPECIFICATION Spec
CONSTANT MaxEntry = 5
INVARIANTS
  TypeOK
  Numbered
  NothingLost
CHECK_DEADLOCK FALSE
```

An archive step moves a prefix. Step 4 moves two entries and step 7 moves
three, so the length is the mate's choice, and that's an existential over
`1..Len(log)`. The prefix is `SubSeq(log, 1, k)` and the rest is
`SubSeq(log, k + 1, Len(log))`. Both ends inclusive, both 1-based, so the
split is at `k` and `k + 1` and nothing is counted twice or dropped. The
prefix goes on the end of the harbour copy with `\o`.

The rule is about positions. The harbour copy at index `i` holds entry
`i`, and the log at index `i` holds entry `Len(archive) + i`. That's two
quantifiers over two domains, and it's what "carries on from wherever the
copy stops" means once you write it down. `NothingLost` is the count check
on top. I'd keep both, since the first can hold with entries missing from
the end of the log.

The voyage has five entries, so the model is bounded by a guard on
`Write`: nothing is written past `MaxEntry`. Once everything is archived
there's nothing left to do, so the terminal state is the voyage ending and
the cfg says so with `CHECK_DEADLOCK FALSE`.

## Acceptable variants

- The rule as one equation, `archive \o log = [i \in 1..(next - 1) |-> i]`.
  A function literal over `1..n` is a list, so the two sides compare.
- The counter dropped, with the next entry number as
  `Len(archive) + Len(log) + 1`. One less variable and `NothingLost` goes
  with it.
- `Archive` with `k` fixed at the whole log, `SubSeq(log, 1, Len(log))`,
  which is `log` itself. Admits step 7 and not step 4. Wrong for this
  table, fine for a ship that archives everything at once.

## Which row forecloses what

| row | kills | because |
|---|---|---|
| 4 | one entry per step, front first | two moved in one step |
| 4 | the newest entries archived | 3 stayed and 1 and 2 moved |
| 4 | keeping entry k in the log after archiving it | the log reads 3, not 2, 3 |
| 7 | a fixed batch of two | three moved |
| 7 | the harbour copy replaced rather than extended | it reads 1 to 5, not 3 to 5 |

The first and third of those are measured below. The one-per-step reading
is the one I'd expect most, since `Head` and `Tail` are the operators a
reader has to hand.

## Wrong neighbors

| neighbor | module | killed by | rc |
|---|---|---|---|
| the rest of the log sliced from `k`, keeping entry k | `DeckLogOffByOne` | the rule, on the first archive | rc 12 |
| the same, against the table | `DeckLogOffByOneAdmits` | row 4 | rc 13 |
| the batch replaces the harbour copy | `DeckLogOverwrite` | the rule, on the second archive | rc 12 |
| the same, against the table | `DeckLogOverwriteAdmits` | row 7 | rc 13 |
| one entry per step, front first | `DeckLogHeadOnly` | nothing. Both rules hold | rc 0 |
| the same, against the table | `DeckLogHeadOnlyAdmits` | row 4 | rc 13 |

The last pair is the point of having a table. One entry per step is a
correct log that never loses or misnumbers anything, and only the row
where two move at once tells it from the answer.

## Measured

From `verify/`, through `harness/verdict.sh` the way `harness/drill-gate.sh`
runs it. TLC2 Version 2026.07.31.184830, `-workers 1`. The table lives in
`DeckLogRows.tla`, a helper with no cfg. Each `*Admits` module walks it,
derives the counter from the two lists, and asks whether every step is a
step of the module it extends.

| module | what | rc | distinct states |
|---|---|---|---|
| `DeckLogRef` | the answer, full model | rc 0 | 21 found |
| `DeckLogRefAdmits` | the answer against the table | rc 0 | 8 found |
| `DeckLogOffByOne` | slice from k, full model | rc 12 | 4 found |
| `DeckLogOffByOneAdmits` | slice from k against the table | rc 13 | 5 found |
| `DeckLogOverwrite` | harbour copy replaced, full model | rc 12 | 12 found |
| `DeckLogOverwriteAdmits` | harbour copy replaced against the table | rc 13 | 8 found |
| `DeckLogHeadOnly` | one per step, full model | rc 0 | 21 found |
| `DeckLogHeadOnlyAdmits` | one per step against the table | rc 13 | 5 found |

21 by hand: with n entries written there are n + 1 places the split can
sit, for n from 0 to 5. 1 + 2 + 3 + 4 + 5 + 6.

## Why not in prompt

Seven rows and a paragraph. No slice operator, no join, and no hint that a
prefix is two slices rather than a loop. The reader has to find the split
point and get both ends of it right.

The caveat: the rule's English, "1, 2, 3 and so on from the start" and
"carries on from wherever the copy stops", is close to a transliteration
of the two quantifiers. I think the index arithmetic is still the reader's
to do, and the off-by-one at the split is what the item is for. "Say what
bounds the model" also hints that something has to, though not whether
it's a guard or a constraint.
