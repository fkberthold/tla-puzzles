# How TLA+ is written in published specifications

**Date**: 2026-09-05. **Edition**: first, and I expect it to be amended. Where
a count here is wrong, fix the count and say which run produced the new one.

This describes how practitioners write TLA+. It surveys 666 modules and 337
configuration files from 16 public repositories. It cites Leslie Lamport's
*Specifying Systems* where the corpus needs a rule stated rather than counted.
It's a record of what people who publish TLA+ do, not advice about any
particular project.

Every number came from a script run over the clones below. Where the corpus
can't settle a question, the section says so and gives the sample size. A
section reading "16 examples, too few" is doing its job, so don't upgrade it
to a rule.

## The corpus

Cloned 2026-09-05 with `git clone --depth 1`. Counts exclude `.git`.

| repository | clone SHA | last commit | `.tla` | `.cfg` |
|---|---|---|---|---|
| tlaplus/Examples | `ceeaa90` | 2026-08-31 | 424 | 235 |
| tlaplus/CommunityModules | `a8068a4` | 2026-07-31 | 78 | 22 |
| Vanlightly/kafka-tlaplus | `823615e` | 2025-01-24 | 29 | 9 |
| microsoft/CCF | `ee34e7b` | 2026-09-04 | 22 | 17 |
| will62794/logless-reconfig | `05178a7` | 2024-10-07 | 22 | 24 |
| muratdem/PlusCal-examples | `559f4b1` | 2023-10-21 | 20 | 1 |
| lemmy/BlockingQueue | `6871597` | 2026-04-22 | 18 | 9 |
| hwayne/tlaplus-exercises | `93dbe92` | 2025-05-07 | 14 | 4 |
| Vanlightly/bookkeeper-tlaplus | `fe199dc` | 2024-03-16 | 13 | 4 |
| Vanlightly/raft-tlaplus | `69ad9d6` | 2022-07-18 | 10 | 9 |
| elastic/elasticsearch-formal-models | `ca30663` | 2019-05-06 | 5 | 0 |
| Azure/azure-cosmos-tla | `a8357c9` | 2022-11-28 | 3 | 0 |
| etcd-io/raft | `3cbf6a7` | 2026-09-02 | 3 | 3 |
| tlaplus/DrTLAPlus | `b74cff5` | 2022-04-18 | 2 | 0 |
| visualzhou/mongo-repl-tla | `7ea53f7` | 2019-11-23 | 2 | 0 |
| ongardie/raft.tla | `6ecbdbc` | 2025-02-18 | 1 | 0 |
| **total** | | | **666** | **337** |

`tlaplus/tlapm` was cloned and dropped. Its 321 modules are prover test
fixtures rather than specifications of a system, and keeping them would have
moved every naming and decomposition number. Microsoft CCF was cloned directly
rather than through the submodule pointer in `tlaplus/Examples`, which a
shallow clone misses.

## Re-running the numbers

Clone the 16 repositories into one directory, then:

```bash
find . -name '*.tla' -not -path '*/[.]git/*' | wc -l          # 666
find . -name '*.cfg' -not -path '*/[.]git/*' | wc -l          # 337
grep -rhoE '\]_[A-Za-z_][A-Za-z0-9_]*' --include='*.tla' . \
  | sort | uniq -c | sort -rn | head                          # ]_vars 518
grep -rn --include='*.tla' ']_\[' . | wc -l                   # 0
grep -rEn --include='*.tla' '\]_[A-Za-z_][A-Za-z0-9_]*(\[|\.)' . | wc -l  # 0
grep -rl 'BEGIN TRANSLATION' --include='*.tla' . | wc -l      # 59
grep -rlE '^[[:space:]]*VIEW\b'  --include='*.cfg' . | wc -l  # 25
grep -rlE '^[[:space:]]*ALIAS\b' --include='*.cfg' . | wc -l  # 23
```

Four figures come from parser passes rather than greps.

**Obligation counts** (939 over 337 configs). Parse each `.cfg`, strip `\*` and
`(* *)` comments, collect identifier tokens under `INVARIANT`/`INVARIANTS` and
`PROPERTY`/`PROPERTIES` until the next keyword.

**Subscript classification.** Split each file on `---- MODULE N ----` headers,
since some files hold two modules. Read each module's `VARIABLE(S)` as a
comma-separated identifier list, then close that set over `EXTENDS` inside the
repository. Scan for `]_`, read the expression after it, expand a named tuple
through its definition, and compare against the closed set. Both steps matter.
Without them `<<memInt, mem, ctl, buf>>` in `InternalMemory.tla` reads as
partial when it's the whole state.

**Conjunct analysis.** A definition counts as an outer conjunction only when
everything between `==` and the first `/\` is whitespace. Without that guard
the splitter cuts inside `\A v \in Value : ... /\ ...`. A looser pass got 30%
disjoint arms where the strict pass gets 4 non-type-invariant cases.

**Redundancy.** Resolve each declared obligation name against definitions in
the same directory, split the body into outer conjuncts, and check whether any
bare-identifier conjunct is separately named in the same config.

`grep -c ']_'` returns 755 against the parser's 725, since grep counts
occurrences inside comments and in files with no module header.

**The section 8 run, 2026-10-26.** Helper-operator facts come from a fifth
parser pass, and it needs two things the earlier four didn't. Index every
definition with its body span, taking the span from `==` to the next
column-1 structural line. Then close each module's `VARIABLES` over `EXTENDS`
and `INSTANCE` inside the repository, the way the subscript pass does, and
close state-dependence over it too: a definition is state-dependent when its
body reads a closed variable or calls something that does. Skip that second
closure and a proof module looks stateless, because its variables live in the
module it extends. That mistake put 954 of 1,211 theorems in the
operator-property bucket against the closed pass's 727.

A use count is occurrences of the name in the same module, outside the
definition's own span. Drop tokens preceded by `!` or `.`, and tokens followed
by `|->`. Those three are instance references, record fields and record
constructors, and none is a call.

Four of the 16 repositories had moved off their recorded tip by 2026-10-26.
`git fetch --shallow-since` then `git checkout --detach <sha>` pins them, and
the run was made at the recorded SHAs. `find` needs `-type f` here, since the
`ongardie/raft.tla` clone directory matches `-name '*.tla'` and reads 667.

Figures that moved against this file on re-measurement, all small and none
amended above. Plain-tuple-body definitions read 388 against 375, of which 40
span more than one line, and `vars` reads 187 against 181. `INSTANCE` reads
252 occurrences in 194 modules against 250 in 190. Definitions whose body is
`M!Spec` read 27 against 28. `THEOREM ... => M!Spec` on one line inside
`tlaplus/Examples` reads 19 against the 15 in section 5, and none of the 19 is
commented out. I'd want a second reader on the tuple figure before changing
it, since my test may be stricter or looser than the original's.

## What this survey did not cover

- No TLC or TLAPS run. Nothing here was executed, only read.
- No closed corpus. No AWS, no Azure beyond `azure-cosmos-tla`, no internal work.
- No Apalache idioms, though 63 modules carry `@type:` annotations.
- No proof style. 94 modules contain `QED` and none of it was analyzed.
- No history. Every number is one snapshot.
- No interviews. Author reasons below are quoted from comments in the files.

Silence in this document is a gap, not permission.

## 1. Decomposition

**The practice**: a config declares a median of 2 named obligations, mean
2.79. Requirements get separate names, and type invariants are the exception
that gets bundled.

| named obligations | configs | | named invariants | configs |
|---|---|---|---|---|
| 0 | 43 | | 0 | 62 |
| 1 | 79 | | 1 | 101 |
| 2 | 81 | | 2 | 97 |
| 3 | 57 | | 3 | 36 |
| 4 to 5 | 44 | | 4 to 9 | 33 |
| 6 or more | 33 | | 12 or more | 8 |

939 in total: 713 invariants and 226 properties. 220 of 337 configs declare no
`PROPERTY` at all. The maximum is 34, in `CCF/tla/consensus/SIMccfraft.cfg`.
Density splits by repository: CCF averages 8.94 per config and Vanlightly's
Kafka work 7.00, against 2.52 for `tlaplus/Examples` and 1.67 for
`logless-reconfig`. I read that as system size rather than house style, but
the corpus can't separate the two.

**Why separate names.** Lamport states the mechanism in *Specifying Systems*
§14.5.3, p. 259: "If you give separate names to the conjuncts of your
invariant and list them separately in the configuration file's `INVARIANT`
statement, TLC will tell you which conjunct is false." A named obligation is a
label in TLC's failure report, and merging two throws the label away.

`braf/BufferedRandomAccessFile.cfg` is the practice at its clearest. It
declares 5 invariants and 9 properties, each named, including seven of the
shape `[][Action => Abstract!Action]_vars`. The author could have written one
conjunction and wrote fourteen names.

**The working test.** Of 899 obligations I could resolve to a definition, 180
have a conjunction as the outermost operator. Of the 179 whose arms resolve to
variables:

| arms | count |
|---|---|
| every arm shares a variable with every other | 49 |
| arms overlap partly | 61 |
| arms pairwise disjoint in the variables they touch | 69 |

65 of those 69 disjoint ones are type invariants by name. So the corpus answer
is: **bundle when the arms are the per-variable clauses of a type invariant.
Otherwise name each arm.**

Four non-type-invariant declarations in the whole corpus bundle arms over
disjoint state, and they come from three specs, since `Elevator` appears at
two model sizes:

- `Elevator.tla` `TemporalInvariant`, two unrelated leads-to properties
- `BufferedRandomAccessFile.tla` `Inv1`, two proof lemmas
- `BookKeeperProtocol_v4_13.tla` `OnlyValidFragments`, two symmetric writers

Arms that constrain the same state are a legitimate bundle and shouldn't be
flagged. `acp/ACP_SB_TLC.tla` defines `AC4_alt` as two conjuncts, both
quantified over `participants`, both about the stability of
`participant[i].decision`. That's one requirement with two halves.

**Thin spot**: 4 cases is not a distribution. The strong claim is the negative
one, that published specs almost never join arms over disjoint state under one
name. Why they don't isn't measured.

## 2. Subscripts

**The practice**: `[][A]_v` is subscripted over the tuple of every variable,
and the tuple is called `vars`.

Of 1,182 subscript sites across 334 modules, 906 have the bare token `vars` as
the subscript, which is 77%. Splitting by site kind and resolving each
subscript against the module's declared variables:

| site | resolvable | every variable | proper subset |
|---|---|---|---|
| `[]_` and `[A]_` | 421 of 725 | 405 (96.2%) | 16 (3.8%) |
| `WF_` and `SF_` | 306 of 456 | 300 (98.0%) | 6 (2.0%) |

The unresolved remainder is mostly `M!vars` and names defined in a module the
pass didn't reach. That's 249 of 725 box sites, a third, and it's a real limit
on the precision of both percentages.

**The soundness condition.** `[A]_v` is defined as `A \/ (v' = v)` (§2.2,
p. 17). `v` may be any state function, not only a tuple of variables: "A
formula `[][N]_v`, where `N` is an action and `v` is a state function, is true
of a behavior iff every successive pair of steps in the behavior is a `[N]_v`
step" (§8.1, p. 89). The subscript exists because `[]A` isn't invariant under
stuttering and TLA admits only formulas that are (§8.1, p. 90).

The condition on `v` is stated for angle brackets, §9.2, p. 123: "We are
interested in the meaning of `Timer(t)` only when `v` is a tuple whose
components include all the variables that may appear in `A`. In this case, a
step that leaves `v` unchanged cannot enable or disable `<A>_v`." The whole
tuple is the default for a stated reason, §8.4, p. 96: "To avoid having to
think about which variables `A` actually changes, we generally take the
subscript `v` to be the tuple of all variables."

So a narrower subscript isn't a blanket error. It's sound when `v` covers
every variable `A` mentions. It does change what the formula says. Every step
that leaves `v` unchanged now satisfies it, whatever else moved. Lamport does
that on purpose in §9.1, p. 119, writing `MinTime == [][HCnxt => (t >= 3600 -
Rho)]_hr` and saying "We don't care about steps that leave `hr` unchanged."

**All 16 proper-subset box sites**, grouped by what the author was doing:

| what | sites | modules |
|---|---|---|
| stability property over the variable it constrains | 6 | `Consistency`, `SingleNode`, `Paxos`, `ACP_SB_TLC`, `ACP_NB_TLC`, `EWD687a` |
| real-time spec conjoined with a clock | 5 | `MCRealTimeHourClock`, `RTWriteThroughCache` |
| component spec over its own variables | 3 | `InnerFIFOInstanced`, `CompositeFIFO` |
| abstract spec under a refinement mapping | 2 | `WriteThroughCacheInstanced` |

The first group reads narrowest and is still routine. CCF's `Consistency.tla`
declares three variables and writes `LedgersMonoProp == [][\A view \in DOMAIN
ledgerBranches: IsPrefix(...)]_ledgerBranches`. `SimplifiedFastPaxos/Paxos.tla`
declares five and writes `PaxosConsistency == [][decision = none]_<<decision>>`.
Markus Kuppe's `EWD687a.tla` declares six and writes `StableUpEdge == [][ ...
]_upEdge`, commented as not a property of the algorithm and there to produce
counterexamples. In all six the action mentions only the subscripted variable.
That matches p. 123 and is narrower than the whole tuple.

**Projections and derived state functions.** A derived state function appears
as a subscript only through a refinement mapping. `Paxos/Voting.tla:192` reads
`Inv /\ [Next]_<<votes, maxBal>> => [C!Next]_chosen`, where `C == INSTANCE
Consensus` and `chosen == {v \in Value : \E b \in Ballot : ChosenAt(b, v)}`.
The subscript is the abstract module's whole state after substitution, not a
projection of the concrete one. `DrTLAPlus/Paxos/Paxos.tla:553` does the same
with `chosenBar`. Lamport's account is §5.8, p. 63: the abstract subscript is
what lets a concrete step map to abstract stuttering. Record-field projection
inside a subscript tuple appears at 3 sites, all in `Composing/CompositeFIFO`,
where each component is subscripted over the channel fields it owns.

**Not attested, across 666 modules**:

- A record literal as a subscript. `]_[` matches zero times.
- An indexed element as a subscript. `]_x[i]` matches zero times.
- `WF_` or `SF_` over a record or an indexed element. Zero.
- A derived state function as a subscript outside a refinement mapping. Zero.

**Machine closure**, since it bounds what a partial subscript can do under
fairness. §8.9.2, p. 112: a spec is machine closed if `Liveness` constrains
neither the initial state nor what steps may occur, and it "is guaranteed to
be machine closed if `Liveness` is the conjunction of weak and/or strong
fairness properties for subactions of `Next`." `FiniteMonotonic/CRDT.tla`
steps outside that and says so in a comment, noting the second conjunct isn't
a standard fairness condition and the spec is machine closed anyway.

**ADDED 2026-10-18, and this is TLC behavior rather than corpus practice.**
"Subactions of `Next`" is the whole condition, and breaking it costs more than
machine closure. A fairness conjunct over an action that `[][Next]_vars`
forbids leaves no behavior at all, and TLC then exits 0 on every temporal
property, including one no behavior can satisfy. Measured on TLC
2026.07.31.184830: `Init /\ [][Next]_vars /\ WF_vars(A)` where `A` is `s' = 99`
and `Next` never allows it reads rc 0 against `[]<>(s # s)`, where the same
property on the same system without the conjunct reads 13.

`harness/vacuity.sh` already catches it, as VECTOR 4, and that probe reads the
same two codes the measurement above does. So this paragraph records a second
route into a failure the harness was already built for. The first route was an
`Init` admitting nothing, and fairness outside `Next` gets to the same place
with a healthy state space and a configured model.

The one check that still fires is the invariant channel, which is the reason
this is worth writing down. The same empty spec exits 12 on a `[]P` over a
state predicate, because TLC lifts that to an invariant and the invariant pass
walks the state graph whatever the temporal conjunct says. So a spec checked
only through lifted invariants looks healthy while every liveness obligation
on it is vacuous. `harness/verdict.sh` carries the grid and
`harness/test-verdict.sh` pins it.

**Thin spot**: 16 box sites in 12 modules, and 6 fairness sites in 5. The four
groups above classify what exists. They aren't evidence that a fifth reason
would be wrong.

## 3. Naming

**The state tuple.** 375 definitions have a plain tuple of names as their
body. 181 are called `vars`, and 342 of 375 end in `vars` or `Vars`. The Raft
lineage groups them: `serverVars` (16), `logVars` (16), `candidateVars` (14),
`leaderVars` (14), then `vars == <<messageVars, serverVars, ...>>`. So `vars`
is often a tuple of tuples and still covers every variable.

**The behavior formula.** 178 of 253 `SPECIFICATION` lines name `Spec`, and
170 of 205 module-side definitions shaped `X == Init /\ [][Next]_v` are called
`Spec`. Variants are qualified rather than invented: `FairSpec`,
`LivenessSpec`, `TraceSpec`, `ISpec`, `AbsSpec`. A further 53 configs declare
`INIT Init` and `NEXT Next` instead, with no overlap.

**Invariants.** 229 distinct names over 713 declarations.

| name | count | share |
|---|---|---|
| `TypeOK` | 117 | 16.4% |
| `TypeInvariant` | 34 | 4.8% |
| `Inv` | 27 | 3.8% |
| ends in `Inv` or `Invariant` | 256 | 35.9% |
| starts with `Type` | 164 | 23.0% |

**Properties.** 137 distinct names over 226 declarations, with a much flatter
head: `Liveness` 14, `Termination` 7, `Safety` 6. Domain names dominate:
`OnePrimaryPerTerm`, `LeaderCompleteness`, `NoLogDivergence`.

**Actions.** Of 238 modules defining `Next`, 105 write it as a bulleted
disjunction of named actions and 69 as an existential over a parameterised
action, usually `\E self \in Procs : Step(self)`. Action names are verbs in
the system's own vocabulary: `BecomeLeader`, `FlushBuffer`, `BufRcv`,
`Gossip`.

**AMENDED 2026-10-26, and the three counts above are wrong.** The section 8
run reads **214** modules defining `Next`, not 238. Two methods agree.
`grep -rlE '^Next[ \t]*==' --include='*.tla'` under GNU grep returns 214
files, and the parser pass returns 214 modules. Allowing an indent moves it to
215, and I couldn't reconstruct 238 by any reading I tried. Closing `Next`
over `EXTENDS` and `INSTANCE` inside each repository gives 390, so that isn't
the gap either.

The shapes re-read as follows over those 214, after stripping the outer
parentheses a PlusCal translation wraps `Next` in. **91** open as a bulleted
`\/` list. **50** are a bare existential over an action taking a parameter. **57**
are an inline disjunction, and 16 are neither. 66 of the 214 have an
existential as their first arm, which is the figure closest to the 69 above.
The two readings agree on structure and disagree on the denominator, and the
original's ratio of 174 in 238 sits within a point of this run's 157 in 214.

**What a name is expected to tell a reader.** Three things, and the corpus is
consistent about all three.

1. Whether it's checked. A `*Inv` or `*OK` suffix marks something a `.cfg` can
   name. `Spec`, `Init`, `Next` and `vars` are structure.
2. What it constrains. `LeaderHasAllAckedValues` says the requirement. `Inv3`
   says nothing, and it turns up where a proof numbers its lemmas.
3. Whether it's the type layer. `TypeOK` and `TypeInvariant` are reserved for
   typing, and 164 of 713 invariant declarations use that prefix.

## 4. The obligation set as a whole

**The practice**: published specs don't declare an obligation that another
declared obligation already covers. Redundancy is avoided, and it isn't
policed.

Of 899 resolved obligations across 274 configs, 3 configs declare a
conjunction alongside one of its own named conjuncts. All three are the shape
`Inv == TypeOK /\ ...` listed next to `TypeOK`: `Bakery-Boulangerie/MCBakery`,
`Bakery-Boulangerie/MCBoulanger`, `c1cs/c1cs`.

A weaker test, where a declared obligation's body mentions another declared
one anywhere, adds 7 more. Again all `Inv` referencing `TypeOK`, plus
`LockHS.cfg` where `PSpec` mentions `Spec`. So 10 cases out of 899.

That one shape is deliberate rather than sloppy. An inductive invariant has to
contain the type invariant, and listing `TypeOK` separately is what makes TLC
name it when types are what broke. Same p. 259 mechanism as section 1.

The other half matters as much. 59.4% of resolved obligations have exactly one
top-level conjunct. Redundancy is rare because obligations start small, not
because authors prune it.

**Unchecked definitions are normal.** 286 definitions are named like an
obligation, ending in `Inv`, `Invariant`, `Safety`, `Correct`, `Consistent` or
`Prop`. 133 of them, 47%, aren't named by any `.cfg` in the same directory. A
definition that exists and isn't checked is the corpus norm.

**Thin spot**: 3 hard cases. The negative result is strong, since the pass
looked at every config it could resolve. What's unmeasured is whether authors
removed redundancy or never wrote it, and the corpus can't tell those apart.

## 5. Attested idioms versus invented ones

These get conflated, so here's what each mechanism is and what it can't do.

| mechanism | lives in | what it does | states a property |
|---|---|---|---|
| `INVARIANT` / `PROPERTY` | `.cfg` | names a formula to check | yes, the only way |
| `SPECIFICATION` | `.cfg` | names the behavior formula | it is the system model |
| `VIEW` | `.cfg` | changes which states TLC fingerprints | no |
| `ALIAS` | `.cfg` | rewrites the state shown in a trace | no |
| `SYMMETRY` | `.cfg` | declares a permutation set | no |
| `CONSTRAINT` | `.cfg` | bounds the state space | no |
| `POSTCONDITION` | `.cfg` | runs an operator after the model | reports, doesn't check |
| `INSTANCE M WITH` | `.tla` | builds a refinement mapping | supplies `M!Spec` to check |

**VIEW**: 25 configs. §14.3.3, p. 243: "The nodes of `G` are values of a state
function called the view. TLC's default view is the tuple of all declared
variables." And p. 244: "When using a view other than the default one, TLC may
stop before it has found all reachable states... it may incorrectly check the
`ImpliedTemporal` property." All 15 `VIEW` targets I could resolve are tuples
of variables. Usually it's the full state minus a bookkeeping variable, as in
`TraceView == <<vars, l, ts>>` in `Traceccfraft.tla`. None is a record. VIEW is
a state-space knob and nothing else. There's also a `-view` command-line flag
that applies the config's VIEW when printing traces ("Current Versions of the
TLA+ Tools", §2.3, p. 11), which is a different thing from the keyword.

**ALIAS**: 23 configs, added in TLC 1.8.0 (tlaplus issue #485). It runs "when
printing an error-trace" and prints a record in place of the state. All 10
resolvable `ALIAS` targets are records built from variables.

**Records built from the variables.** 176 definitions have a record body with
two or more `|->` fields. 10 are wired to `ALIAS`. 0 to `VIEW`. 0 are declared
as an `INVARIANT` or a `PROPERTY`. The remaining 166 are ordinary data
records: graph values in `CommunityModules`, SVG constructors, animation frame
positions.

So **building a record from the variables and stating a property over it is
not attested**. The idiom exists and its job is display. That's a different
job from asserting anything. The two are easy to confuse, since both produce a
record whose fields are named after the state.

**Refinement mappings.** 250 `INSTANCE` occurrences across 190 modules, 43
with a `WITH` clause. 28 definitions have a body of the form `M!Spec`, named
`Refinement`, `Refines`, `AbstractSpec`, `BQSpec`, `RefinesMLDR`. 29
`THEOREM ... => M!Op` statements. Abadi and Lamport's definition (TCS
82(2):253-284, 1991, §2.4) puts the stuttering escape hatch in condition R3.
A concrete transition maps to an abstract one "or `f(s) = f(t)`". That's why
the abstract subscript does work under a mapping, and it's what section 2
found `[C!Next]_chosen` doing.

In practice it's two lines. `M == INSTANCE Abstract WITH x <- expr` defines
`M!Spec`. Then either `THEOREM Spec => M!Spec` for a proof, or a definition
`Refinement == M!Spec` named in the config's `PROPERTY` for TLC to check.

**AMENDED 2026-09-05.** Counted over `tlaplus/Examples` at `ceeaa904`: 23
configs name a refinement property across 21 distinct pairs. 19 use the plain
form above. Three use a Toolbox-generated name for the same shape, where the
module defines `prop_156180051387248000 == C!Spec` and the config names that.

The one shape the plain form misses is an abstract spec that HIDES VARIABLES.
`MCWriteThroughCache.cfg` reads `PROPERTY LM_Inner_ISpec`, and that operator is
an inlined hand-copy rather than `LM!Spec`. The module says why at
`MCWriteThroughCache.tla:45`, "Had we used the actual INSTANCE". When the
abstract side quantifies its state away with `\EE` there is no `M!Spec` to
name, so you inline it.

Proof and model-checking overlap and neither contains the other: 15 uncommented
`THEOREM ... => M!Spec` statements against 21 checked pairs. `TwoPhase`,
`PConProof` and `BPConProof` are proved and never checked, and their configs
carry no `PROPERTY` line at all.

Other keyword counts, for calibration: `SYMMETRY` 49 configs, `CONSTRAINT` 49,
`CHECK_DEADLOCK` 82, `ACTION_CONSTRAINT` 5, `POSTCONDITION` 5.

## 6. PlusCal versus raw TLA+

**The practice**: 59 of 666 modules carry a PlusCal translation, so 9%. The
split is by domain rather than by author preference.

| repository | PlusCal | modules |
|---|---|---|
| muratdem/PlusCal-examples | 20 | 20 |
| Azure/azure-cosmos-tla | 3 | 3 |
| tlaplus/Examples | 35 | 424 |
| elasticsearch-formal-models | 1 | 5 |
| everything else, 12 repositories | 0 | 214 |

Zero of CCF's 22 modules, zero of Vanlightly's 52 across three repositories,
zero of `logless-reconfig`'s 22, zero of the four Raft specs. Every
distributed-consensus repository in the corpus is raw TLA+.

**What the choice changes about properties.** PlusCal adds `pc`, the program
counter, to the state. 49 of the 59 translated modules have `pc` in their
`vars` tuple. So every subscript covers it, and a partial subscript has to
decide about it explicitly. Termination becomes expressible over `pc`, and 29
of the 59 define `Termination` against 41 in the whole corpus. So 71% of the
`Termination` definitions in 666 modules sit in the 9% that are PlusCal.

Only 5 of 59 use `--fair algorithm`. All 59 carry `BEGIN TRANSLATION`, so the
translated TLA+ is committed rather than generated at check time.

**Thin spot**: two repositories supply 23 of the 59 PlusCal modules, and one
exists to demonstrate PlusCal. The domain split is a real observation about
this corpus. Whether it generalizes past consensus protocols isn't something
666 modules can settle.

## 7. Shapes that look wrong and are routine

A reviewer that fires on every deviation is worse than no reviewer. These all
look like defects and are normal practice.

| shape | how common | why it's normal |
|---|---|---|
| an obligation defined and never checked | 133 of 286 | retired invariants, proof-only invariants, configs that live elsewhere |
| a commented-out obligation in the config | `braf` | `\*INVARIANT Inv2 \* see note at definition of Inv2` is a pointer |
| `Inv == TypeOK /\ ...` listed next to `TypeOK` | 3 configs | so TLC names the type failure when types are what broke |
| no fairness anywhere | 196 of 337 configs | pure safety is the majority case, not an omission |
| `CHECK_DEADLOCK FALSE` | 79 of 337 configs | the spec's terminal states are intended |
| a separate `MC` module wrapping the real one | 81 of 666 modules | finite constants and overrides live away from the spec |
| a property that is deliberately false | `EWD687a` | its counterexamples explain the algorithm, and a comment says so |
| a liveness property named like an invariant | `Elevator` | the section 3 convention is a tendency, not a rule |
| `vars` that is a tuple of tuples | Raft lineage | it still covers every variable |
| `vars` including auxiliary or history variables | trace and history specs | `<<l, vars>>` is a superset, which is what an auxiliary needs |
| a subscript naming one variable of several | 12 of 16 box sites | sound when the action mentions only that variable |
| `[][A]_v` where `A` is an implication | 7 in `braf`'s config | the standard shape for step simulation |

Two of those repay a second look. `FlushBufferCorrect == [][FlushBuffer =>
UNCHANGED RAF!vars]_vars` asserts nothing about steps that leave `vars` alone,
which is the point. And 83 of 337 configs name a specification carrying a
fairness conjunct, so the liveness practice in this corpus rests on a quarter
of it.

**One thing I won't rule on.** 10 configs declare both `SYMMETRY` and a
`PROPERTY`. I didn't source whether that combination is sound for the liveness
checks TLC runs. So this document neither calls it a defect nor calls it fine.
Somebody should settle it and amend this line.

**AMENDED 2026-10-22, and the mechanism is settled while the corpus split is
not.** TLC rules on it itself. Measured on TLC 2026.07.31.184830 against
`core-language-docs/snippets/state-space/Livery.tla`, whose `Perms` is
`Permutations(Cars)` over three model values, with `SPECIFICATION FairSpec`,
`SYMMETRY Perms` and `PROPERTY Fills` where `Fills == <>(loaded = Cars)`:

```
Warning: Declaring symmetry during liveness checking is dangerous. It might
cause TLC to miss violations of the stated liveness properties. Please check
liveness without symmetry defined.
```

rc 0, 4 distinct states. So it is a defect, and the warning goes to stdout
while the exit code stays 0. There is no failure channel, which I suspect is
why the combination survives in a published corpus at all.

**It is about liveness and not about `PROPERTY`.** The other two shapes a
`PROPERTY` line can carry draw no warning under the same symmetry, both at rc
0 over 4 distinct states: `Grows == [][loaded \subseteq loaded']_<<loaded>>`,
an action formula, and `Held == [](loaded \subseteq Cars)`, a state predicate
under a box that TLC lifts to the invariant channel. The action check is live
rather than skipped, since the false twin `[][loaded' \subseteq
loaded]_<<loaded>>` exits 13 under the same symmetry with a counterexample.
Every case is pinned in that directory's `CASES`.

Two things this does NOT settle. How the 10 configs divide by property shape,
which needs a corpus clone this measurement did not have. And whether the
book's wording covers the action-property case, since `harness/refinement.sh`
refuses `SYMMETRY` and `VIEW` on any temporal check citing p. 244 and p. 246
for "miss errors, report an error that doesn't exist, or report a real error
with an incorrect counterexample", and TLC warns on only one of the three
shapes. The harness is right to refuse either way, because refinement is
liveness-shaped.

Worth recording where this was already written down. `exercises/ch09/CHEATSHEET.md:50`
says liveness checking "can't use symmetry sets" as a plain cost of the
channel, so the project held the answer in a curated file while this section
asked for somebody to go and find it. I would check the cheat sheets before
the corpus next time.

## 8. Helper operators

**The practice**: published specs are helper-rich, and about half of the
helpers they use get used once. The instinct that keeps a spec in one place, so
reading the action tells you what happens, isn't what this corpus does.

A helper here is an operator definition that is none of these: an obligation a
`.cfg` names, any other name a `.cfg` names, `Init`, `Next`, `Spec` or a
variant, `vars` or a plain tuple of names, or a definition `Next` names
directly. 4,969 of 8,306 definitions qualify, so 59.8%. 3,871 of those carry no
prime and no `UNCHANGED`, and that layer is what this section measures. The
other 1,098 are sub-actions reached from a named action.

Counted over the 214 modules that have a closed `VARIABLES` set and define
`Next`:

| non-action helpers | spec modules |
|---|---|
| 0 | 11 |
| 1 to 2 | 47 |
| 3 to 5 | 41 |
| 6 to 10 | 50 |
| 11 to 20 | 40 |
| 21 to 40 | 18 |
| 41 or more | 7 |

Median 6, mean 9.6, maximum 88. Drop the 25 proof and library modules and the
median holds at 6 while the mean rises to 10.1. A spec with a dozen named
helpers sits inside the ordinary range, and one with none is 11 modules out of
214.

**Single use is the common case.** Of the 3,871 non-action helpers, 2,846 are
referenced at least once in the module that defines them.

| uses in its own module | helpers | share of the used |
|---|---|---|
| 0 | 1,025 | |
| 1 | 1,424 | 50.0% |
| 2 | 574 | 20.2% |
| 3 | 274 | 9.6% |
| 4 to 5 | 216 | 7.6% |
| 6 or more | 358 | 12.6% |

Narrowing to spec modules gives 765 of 1,667, so 45.9%. Narrowing again to the
non-proof, non-library ones gives 757 of 1,533, so 49.4%. Three poolings land
between 45.9% and 50.0%, which is why I'd treat the figure as settled. A name
given to one expression and used in one place is how published TLA+ reads.

The zero bucket runs 20% to 27% depending on the pooling, and it isn't
evidence of dead code. Use counts here are module-internal, so a
`CommunityModules` operator written for other modules to call reads as unused.
Section 4 found the same shape from the other side, where 133 of 286
obligation-named definitions aren't named by a `.cfg` in their own directory.

**What TLC names, and where it stops.** Section 1 quotes the mechanism that
settles obligations: name the conjuncts separately and TLC tells you which one
is false. That argument doesn't reach a helper, and the boundary is sharp.

Measured on TLC 2026.07.31.184830 against a four-helper fixture, two pools and
two staff, 9 distinct states. The invariant failure names the obligation and
not the helper the comparison sits in. With
`EveryPoolSmall == \A p \in Pool : PoolSize(p) <= 1` the run exits 12 and
prints `Error: Invariant EveryPoolSmall is violated by the initial state`,
while the arithmetic that decides it is inside `PoolSize`.

Relax the bound to `<= 2` and the model runs out at exit code 0, which gets
the coverage report. Under `-coverage 1` the angle-bracketed rows are the
top-level definitions alone: `<pools>`, `<Init>`, `<Move>`, `<Drop>` and
`<EveryPoolSmall>`. A helper's body shows up underneath its caller as a line
and column with a count, under no name of its own. `StaffCanLeave` is defined
at line 10 and called from two actions. It read `line 10, col 24 to line 10,
col 37 of module Helper: 48` twice, once under `<Move>` and once under
`<Drop>`.

Two things follow. A helper is anonymous to TLC and not invisible to it, and I
think the per-caller counts are more use for diagnosis than one name would be.
And a helper nothing calls draws no coverage row, so coverage won't tell you a
definition is dead. `NeverUsed` appeared zero times in the output.

**Value-returning next-state helpers are attested and rare.** The shape is an
operator that takes a function and returns an updated one. An action then
applies it to produce a primed value. 2,440 sites write the update inline
instead, as `v' = [v EXCEPT ...]`, spread over 1,190 action-shaped
definitions.

Against that, 272 primed assignments have the form `v' = Op(...)` with `v` in
the module's closed variable set. 158 name a standard-module operator, mostly
`Append` at 86 and `Tail` at 53. 109 resolve to a non-action definition in the
same repository, and those are the factored-out next-state functions. So about
one site in 22 factors.

The sub-shape split is lopsided. 102 of the 109 take the function as a
parameter and read no module variable, so they compose. 7 read a variable and
take an index. 51 distinct definitions sit behind those sites, carrying 26
distinct names, in 25 modules across 6 of the 16 repositories.

Three of them use the same two names for the same job.
`WithMessage(m, msgs)` and `WithoutMessage(m, msgs)` appear in
`raft.tla:106`, in etcd-io's `etcdraft.tla:164`, and in CCF's
`Network.tla:172`. Each has a `[msgs EXCEPT ...]` body and the same comment
above it. That's lineage and not three inventions, and the original is
Ongardie's Raft spec.

CCF composes the pair. `ccfraft.tla:400` reads
`messages' = Network!WithoutMessage(request, Network!WithMessage(response, messages))`,
which updates one variable by threading it through two helpers. 30 primed
assignments in the corpus apply one non-standard operator to another's result.
13 of those are in `kafka-tlaplus`, where `SendFunc` and `DiscardFunc` nest
the same way.

**A guard predicate takes the state or reads it, about half and half.** 268
non-action helpers appear in a guard conjunct of an action. The test is that
the occurrence opens the conjunct instead of sitting on the right of a primed
assignment. 218 of them take a parameter.

| guard helper reads | count | share |
|---|---|---|
| no variable, state comes in as an argument | 104 | 47.7% |
| a module variable, an index comes in | 114 | 52.3% |

50 take no parameter at all, and 32 of those read a variable. 95 modules hold
at least one guard helper, and the shapes mix inside a module. 19 modules use
the argument form alone, 20 the variable-reading form alone, and 32 use both.

An even split is weak evidence for either form, which is the useful result
here. A guard that reads the module's variable and takes an index is ordinary,
and `ccfraft.tla:450` and `Elevator.tla:44` both do it. Passing the state in is
equally ordinary. I read the choice as open among practitioners instead of
settled, so neither form should draw a review comment on its own.

**What practitioners state theorems about.** 1,211 statements, 880 `THEOREM`,
325 `LEMMA` and 6 `COROLLARY`, in 176 of 673 modules.

| subject | statements | share |
|---|---|---|
| an operator, with no spec state in the claim | 727 | 60.0% |
| the spec, temporal or inductive | 245 | 20.2% |
| the spec, a state predicate | 198 | 16.4% |
| refinement, `=> M!Spec` | 23 | 1.9% |
| another instance-qualified claim | 18 | 1.5% |

So the most common subject of a theorem here is a helper operator, and by a
wide margin. 539 of the 727 sit in modules that declare no state, which is
`CommunityModules` and the proof modules beside it. The other 188 sit inside a
stateful module as side claims, and they read to me as typing lemmas for the
helpers a proof needs. `BlockingQueuePoisonApple_proofs.tla:90` is the pattern:
`ASSUME NEW buf \in Seq(Producers \cup {Poison}) PROVE IsFiniteSet(PoisonSet(buf))`.

None of that reaches TLC. The same fixture carries three false theorems,
`THEOREM 1 = 2` among them, and TLC reports `Model checking completed. No
error has been found.` at exit code 0. A theorem is a claim addressed to
TLAPS, so it tests a helper for a reader who runs the prover and for nobody
else.

**Thin spots**, and there are several.

The composable next-state helper rests on 25 modules and 26 names. Three of the
`With`/`Without` sites are one spec copied forward, so the number of
independent authors is smaller than 51 definitions suggests. The coupled
sub-shape is 7 cases, which is not a distribution.

The guard test is structural. It counts an occurrence that opens a conjunct, so
a predicate used inside a `LET` or under a quantifier doesn't land in the 268.
50 of those that do land take no parameter, and the 52.3% is a share of the 218
that remain.

Nothing here measures why an author factored. The use counts say a single-use
helper is normal and say nothing about what the name bought. Section 4 hit the
same wall on redundancy, and the corpus can't separate the cases there either.

## Sources

- Leslie Lamport, *Specifying Systems*, Addison-Wesley 2002.
  <https://lamport.azurewebsites.net/tla/book.html>. Page numbers above are the
  book's printed pages, and unqualified section numbers refer to it.
- Leslie Lamport, "Current Versions of the TLA+ Tools", 8 October 2024.
  <https://lamport.azurewebsites.net/tla/current-tools.pdf>
- Martin Abadi and Leslie Lamport, "The Existence of Refinement Mappings",
  *Theoretical Computer Science* 82(2):253-284, 1991.
- TLC `ALIAS` keyword: <https://github.com/tlaplus/tlaplus/issues/485>, and the
  TLC 1.8.0 changelog.
