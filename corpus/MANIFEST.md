# The corpus manifest

`PRACTICE-PLAN.md` curates problems from published, human-authored specifications.
This file is the list it curates from, and the record of how the list was cut.

It exists because the first version of these counts did not survive the session that
produced them. `PRACTICE-PLAN.md` carries the funnel as six numbers and no rows. The
rows were nowhere: not in the palace, not in the repo, and the corpus clone they were
read from was gone. So this is a rebuild, and it lives in the repo where the last one
should have.

Rebuilt 2026-09-05, bead `tla-e7q2`.

**AMENDED 2026-10-01.** The curation direction was retired on 2026-09-06. Problems
come from external prose now, and `sources/README.md` is the survey that settled
which prose. So this file is no longer the list problems are curated from.

It keeps two jobs. It's the record of how a real corpus was cut, rule by rule, and
the only place that says where those numbers sit against the funnel in
`PRACTICE-PLAN.md`, which they don't match. See "What moved against the recorded
counts" below. And the 143 rows are still a candidate pool for anything that wants
a published spec to read. `harness/test-corpus-manifest.sh` keeps gating it.

Four beads sit on it and none has closed: `tla-16je`, five repositories ship no
licence. `tla-t64z`, 24 systems at level 3 against the plan's 1. `tla-kp4l`, the
prose column detects a README rather than a description of the system. `tla-6mms`,
level 5 is the softest column and one reader scored it differently.

## The corpus

Cloned with `git clone --depth 1`. Every SHA below matches the one
`.claude/rules/tla-practice.md` recorded, so this is the same corpus that survey read
and the same one the lost funnel was cut from.

| repository | clone SHA | `.tla` | licence |
|---|---|---|---|
| tlaplus/Examples | `ceeaa90` | 424 | MIT |
| tlaplus/CommunityModules | `a8068a4` | 78 | MIT |
| Vanlightly/kafka-tlaplus | `823615e` | 29 | MIT |
| microsoft/CCF | `ee34e7b` | 22 | Apache-2.0 |
| will62794/logless-reconfig | `05178a7` | 22 | NONE FOUND |
| muratdem/PlusCal-examples | `559f4b1` | 20 | NONE FOUND |
| lemmy/BlockingQueue | `6871597` | 18 | MIT |
| hwayne/tlaplus-exercises | `93dbe92` | 14 | MIT |
| Vanlightly/bookkeeper-tlaplus | `fe199dc` | 13 | MIT |
| Vanlightly/raft-tlaplus | `69ad9d6` | 10 | MIT |
| elastic/elasticsearch-formal-models | `ca30663` | 5 | Apache-2.0 |
| Azure/azure-cosmos-tla | `a8357c9` | 3 | MIT |
| etcd-io/raft | `3cbf6a7` | 3 | Apache-2.0 |
| tlaplus/DrTLAPlus | `b74cff5` | 2 | NONE FOUND |
| visualzhou/mongo-repl-tla | `7ea53f7` | 2 | NONE FOUND |
| ongardie/raft.tla | `6ecbdbc` | 1 | NONE FOUND |

Totals: 666 modules and 337 configuration files.

## The funnel

Each stage states its rule next to its count, so a reader can disagree with the rule
instead of re-deriving the number.

| stage | rule | count |
|---|---|---|
| modules | every `.tla` outside `.git` | 666 |
| specs | declares `VARIABLES`, and has `Init` and `Next` or a PlusCal translation | 211 |
| candidate groups | one per repository directory holding a spec | 127 |
| systems | groups split and merged by reading the modules | 143 |
| describable | a statement of the system can be written without naming a variable | 131 |

The last two stages are judgment, and they were made by reading the modules rather
than by a rule a script can run. A directory is a good guess at a system and no more.
It holds three unrelated algorithms in `LoopInvariance`, and one system across eight
files in `BlockingQueue`.

## What moved against the recorded counts

| stage | recorded | rebuilt |
|---|---|---|
| modules | 662 | 666 |
| specs | 208 | 211 |
| distinct systems | 107 | 143 |
| describable | 99 | 131 |

I would not read the gaps as either count being wrong. The recorded funnel did not
state its rules, so the two passes may have drawn the spec boundary in different
places. What the rebuild adds is the rules, which is the part that lets the next
disagreement be about something.

## Levels

The scale is `PRACTICE-PLAN.md`'s, anchored on state representation.

| level | systems |
|---|---|
| 1 | 24 |
| 2 | 17 |
| 3 | 24 |
| 4 | 33 |
| 5 | 45 |

A regex heuristic proposed a level for every row first, and it was wrong often enough
in both directions that no row kept its proposed value without someone reading the
module. PlusCal's `pc` and `stack` push a spec upward, since they look like
function-valued state and belong to the translation rather than the system. A
five-party security protocol went the other way and scored level 1, because all forty
of its variables are individually declared scalars.

The plan records level 3 as holding one system in the whole corpus, and that hole is
what the plan is built around. This pass does not reproduce it. Read that as a
question to settle rather than a correction, since the plan's count was over the 67
systems that survive every filter and this one is over every candidate.

**SETTLED 2026-10-01, bead `tla-t64z`.** Apply the plan's own filters to these 24
rows. 23 are describable, 21 of those carry a licence, and of the 21 five read
`checkable=yes` while eleven read `unattempted`. So the plan's filtered count
belongs between 5 and 16 rather than at 1. This bead's own caution was right that
the two counts were not over the same set. Applying the filters makes them
comparable, and the gap survives it.

The band is not a gap one pass can close, and "Checkability" below says why.
`checkable` is `unattempted` for 92 of the 143 rows. Only 79 of 211 specs ship a
`.cfg` for their own module, so for the rest there was nothing to run. Settling
checkability for one of the eleven licensed level-3 rows means writing a model for
it. That is constants, a state constraint, and a decision about what to check,
which is most of the work of using the row at all.

So the band narrows one row at a time rather than in a sweep. `tla-mjh5` already
prescribes that: fill the column per system at the moment it gets picked, and let
the rest stay honestly blank. For the same reason the plan's "68 fast enough to
check" stage is not reproducible here either. A full sweep would want the 54 MB
clone this repo does not keep. `TLA_CORPUS` is the way in, and
`harness/test-corpus-manifest.sh` already reads it.

The five that clear every filter, for whoever picks that up.

| system | repo | tlc_seconds |
|---|---|---|
| Ledger chaining into a single log | `Vanlightly/bookkeeper-tlaplus` | 12.6 |
| Raft consensus with fsync durability | `Vanlightly/raft-tlaplus` | 11.4 |
| Non-blocking atomic commitment with failure detectors | `tlaplus/Examples` | 5.0 |
| Prisoners and a single switch | `tlaplus/Examples` | 0.6 |
| Spanning-tree computation on a graph | `tlaplus/Examples` | 1.1 |

Two of those are consensus or replication, one is atomic commitment, one is a logic
puzzle and one is a graph algorithm. None is ordinary application engineering, which
is the shape the 2026-09-06 direction change went looking for.

One inconsistency to know about before trusting a level 5. Where a system merges a
base module with a refinement variant, one reader scored the merged system 5 on the
strength of the variant's `INSTANCE`, even where the base module alone reads lower.
That reader flagged the choice; the others did not say either way. So level 5 is the
column's softest value, and a row there may be reporting the family rather than the
system. The `why` column carries the citation each call was made on.

## Reading a row

Every row's `why` carries the evidence its level was decided on, as a `file:line` into
the module. That is the column to read first when a level looks wrong, since it says
where to look rather than asking you to take the number.

## Checkability

TLC ran once per spec that ships its own `.cfg`, on the pinned 2026.07.31 build, one
worker, with a 45 second budget.

| exit code | meaning | specs |
|---|---|---|
| 0 | checked clean | 30 |
| 124 | hit the 45 second budget | 15 |
| 150 | parse or semantic failure | 13 |
| 11 | deadlock reported | 12 |
| 12 | invariant violated | 4 |
| 75 | spec would not evaluate | 3 |
| 151 | config names something absent | 1 |
| 255 | other failure | 1 |

Two things this stage measured that are worth carrying.

Only 79 of 211 specs ship a `.cfg` for their own module. The rest were never
attempted, and the manifest says `unattempted` rather than `no`, because a gap in the
sweep is not a fact about the spec. Establishing checkability for those means writing
a model first.

Parse failures fell from 27 to 13 when CommunityModules went on the module path. So a
third of these specs do not stand alone, and a curated problem has to ship the library
modules alongside the specification.

## Licence

| licence | systems |
|---|---|
| MIT | 116 |
| NONE FOUND | 19 |
| Apache-2.0 | 8 |

Five of the sixteen repositories carry no `LICENSE`, `LICENCE` or `COPYING` file, and
they account for 19 systems here. The recorded funnel dropped one system at this
stage. The plan puts the shipped specification in a subfolder of each problem, so
redistribution matters, and I think these need asking about rather than assuming. An
absent file is not a refusal.

## Left out

Rows a reader judged not to be a system at all, kept here so the exclusion is visible
rather than silent.

- `SIMCoverageccfraft (parallel simulation-run harness)`: not a system

## Re-running this

Clone the sixteen repositories above into one directory, then point the gate at it.

```bash
TLA_CORPUS=<that directory> bash harness/test-corpus-manifest.sh
```

The gate checks the shape of every row and, when `TLA_CORPUS` is set, that every row
names a directory that exists. It also reads this file and recomputes every count here
that `manifest.tsv` can answer.

- the level table and the licence table
- the funnel's `systems` and `describable` stages
- each repository's clone SHA and licence
- the level-3 survival chain and the five survivors' seconds
- the counts stated in prose rather than in a table

A count it can't derive prints as a skip, so you can see what went unchecked. The
funnel's `modules`, `specs` and `candidate groups` came off the clone rather than the
TSV, and they're the main ones.

Planted controls back both halves. Each perturbs one number in a copy of the real pair,
and the gate has to reject it and name what moved. One of them earned its place on the
first run by catching that `IFS=$'\t' read` drops an empty field, because tab is IFS
whitespace.

One gap is left. A number in a sentence carries no marker that tells a derived count
from a date or a bead id. So a new one in prose stays uncovered until somebody adds a
claim to the gate. I'd rather say that here than have the next reader take this file for
fully gated.
