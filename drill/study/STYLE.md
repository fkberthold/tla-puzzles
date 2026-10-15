# Reading an attempt for style

You've already said whether the module does what the prompt asked. This file is
for the other question: it's working TLA+, is it idiomatic TLA+? Those are two
questions and this file answers only the second one.

`CLAUDE.md` in this directory governs every word below. It says to report the
behavior and never the construct, and a style pass doesn't get to overrule
that. The two registers meet in one narrow place. Read the rule for it under
"What a style remark is" before you write a remark, because it's short and it's
the whole reconciliation.

## The research this rests on, and the limit it puts on you

The ground is a survey of 666 modules and 337 configuration files from 16
public repositories, every number from a script run over the clones
[C1 `tla-practice.md:6`, dated 2026-09-05 at 27cd653]. You can't open it from
here. It lives in the repo you're not allowed to read, which is why its
findings are distilled into this file instead.

Two sentences from it bind you, and they're quoted rather than paraphrased
because paraphrase loses them.

> It's a record of what people who publish TLA+ do, not advice about any
> particular project.

> Silence in this document is a gap, not permission.

[C1 `tla-practice.md:9` and `:98`]

So the survey grounds _idiomatic_ with counts and can't ground _good_ at all.
Where it has no number, you have no remark.

Reasoning from first principles about what good TLA+ looks like is the one
failure this file exists to stop. A model doing that sounds as authoritative as
a model quoting a count, and Frank can't tell the two apart from the output.

## The three tiers

Every remark carries exactly one tier and names it. A remark with no tier
doesn't get made.

**C1**: measured in the published corpus. A count from the survey, cited as
`[C1 tla-practice.md:NNN]`. This is the strongest ground for calling something
idiomatic. It's also reproducible, since the survey carries all 16 repositories
with clone SHAs and the exact greps.

**C2**: Lamport's stated reason, with a page number, cited as
`[C2 Specifying Systems §N p. N]`. Page numbers are the printed pages of the
2002 Addison-Wesley edition. This is the only tier that licenses saying a
choice _costs_ something rather than merely being unusual.

**C3**: counted now, over a named body on disk, cited as
`[C3 498 reference modules, 2026-10-15]`. Two bodies answer different
questions. The repo holds 498 reference modules and 540 configs you can't read
either, and they say what the answers to these items look like. That's why
their counts are frozen into this file. Frank's own `.tla` files say whether
something is a habit of his rather than a one-off.

C1 and C3 can disagree, and when they do, C3 wins for a drill attempt. The
published corpus specifies real systems and these items are ten-minute
exercises. A corpus median is the wrong yardstick for a file with two variables
in it. The obligation-count axis below is where that bites hardest.

Quote the count to him, not the citation path. He can reach the repo and you
can't, so the path is provenance for later rather than something he needs in
the report.

## What a style remark is

**On the page**: a remark is about the TLA+ he wrote. "134 of 140 constant
names in the reference specs are CamelCase and yours are not" is a style
remark. "You need a type invariant here" is the answer to some other item and
isn't one.

**Absence is silence**: the style pass never reports something that isn't
there. That single rule is what keeps this file inside `CLAUDE.md`'s third
prohibition, and it's not a special case bolted on. The survey counted
declarations rather than modules, so I don't think it can support a sentence
like "most specs have one of these" in the first place.

**No new lines**: naming a construct that's on the page is how a style remark
works at all. Showing him a better line is still forbidden, in a fence or
inline or under any framing.

**After the check**: a module that admits a step it shouldn't has a correctness
report waiting, and a remark about identifier case on top of that is noise. Say
the style part last and keep it short.

**One exclusion**: `core/04-lift-types` gets no type-invariant remark of any
kind, including a positive one, because that item's own lesson is what the axis
measures. Every other item is in scope on every axis. The eight `sequences/*`
items that touch a type invariant are **not** excluded, because there the
invariant is only where the lesson sits.

## The axes

The script hands you measurements. This section says what each one licenses.

### Identifier case

The survey never measured identifier case, so this axis is C3 only and C1 is
silent on it.

| body | distinct | CamelCase or ALLCAPS | camelBack | snake_case | lowercase |
|---|---|---|---|---|---|
| constant names in the 498 reference modules | 140 | 134 | 0 | 0 | 6 |
| variable names in the 498 reference modules | 137 | 0 | 10 | 0 | 127 |

[C3 498 reference modules, 2026-10-15]

The six all-lowercase constants are `a`, `b`, `l1`, `l2`, `w1` and `w4`, every
one a single letter or a letter with a digit. So the rule isn't "always
CamelCase". It's CamelCase for a named concept and short lowercase for a
mathematical placeholder.

Variables run the other way round, and no variable name in that body starts
with a capital. A lowercase or camelBack variable is the normal shape.

A snake_case identifier is the clearest finding this axis produces, because 0
of 140 is as flat as a count gets. Say the count and stop. There's no C2 behind
it, so it's unusual rather than wrong.

### The state tuple

| claim | tier |
|---|---|
| 375 plain-tuple definitions, 181 named `vars` | [C1 `tla-practice.md:253`, `:254`] |
| 342 of 375 end in `vars` or `Vars` | [C1 `tla-practice.md:254`] |
| 208 reference modules define a tuple, 203 name it `vars` | [C3 2026-10-15] |

A tuple of tuples still counts as covering every variable, and so does a tuple
carrying auxiliary or history variables [C1 `tla-practice.md:448`, `:449`].
Neither is a finding. Check what the tuple covers rather than how it's built.

### The box subscript

| claim | tier |
|---|---|
| 405 of 421 resolvable box sites cover every variable, 96.2% | [C1 `tla-practice.md:175`] |
| 906 of 1,182 subscript sites are the bare token `vars`, 77% | [C1 `tla-practice.md:169`] |
| 253 of 298 box sites in the reference modules are `vars` | [C3 2026-10-15] |

The whole tuple is the default for a reason Lamport states: "To avoid having to
think about which variables `A` actually changes, we generally take the
subscript `v` to be the tuple of all variables"
[C2 Specifying Systems §8.4 p. 96].

A narrower subscript isn't an error. It's sound when the subscript covers every
variable the action mentions, because a step leaving it unchanged then can't
enable or disable the action [C2 Specifying Systems §9.2 p. 123]. The corpus
has 16 narrow box sites, 12 of them naming one variable of several, and the
survey classifies all 16 as routine
[C1 `tla-practice.md:450`, `:205` to `:210`].

So a narrow subscript gets an observation and never a defect, and the
observation carries the 12-of-16 in the same breath. I'd lean toward saying
nothing at all unless the action it guards touches a variable the subscript
leaves out.

### The behavior formula

| claim | tier |
|---|---|
| 170 of 205 definitions shaped `Init /\ [][Next]_v` are named `Spec` | [C1 `tla-practice.md:260`] |
| 178 of 253 `SPECIFICATION` lines name `Spec` | [C1 `tla-practice.md:259`] |
| 230 of 236 reference modules with that shape name it `Spec` | [C3 2026-10-15] |
| 469 of 540 reference configs name `Spec` on `SPECIFICATION` | [C3 2026-10-15] |

Variants are qualified rather than invented. `FairSpec`, `LivenessSpec`,
`TraceSpec`, `ISpec` and `AbsSpec` all turn up, so a qualified name is on
convention and an unrelated one isn't [C1 `tla-practice.md:261`, `:262`].

### Next's shape

| claim | tier |
|---|---|
| of 238 modules defining `Next`, 105 write a disjunction of named actions | [C1 `tla-practice.md:279`] |
| 69 write an existential over a named parameterized action | [C1 `tla-practice.md:280`] |
| 222 reference modules define a top-level `Next`, and 207 of those bodies name actions and prime nothing | [C3 2026-10-15] |
| 15 prime a variable inside `Next` itself | [C3 2026-10-15] |

Action names in the corpus are verbs in the system's own vocabulary, like
`BecomeLeader`, `FlushBuffer` and `Gossip`
[C1 `tla-practice.md:281`, `:282`].

This axis has no C2. Lamport gives no stated cost for a transition written
inline under a quantifier, so the remark stops at unusual. Don't reach for
readability or maintainability. Those words are the first-principles reasoning
the silence rule forbids. 207 of 222 is the whole argument and it's enough.

### Type invariants

| claim | tier |
|---|---|
| `TypeOK` is 117 of 713 invariant declarations, 16.4% | [C1 `tla-practice.md:269`] |
| a `Type` prefix is 164 of 713, 23% | [C1 `tla-practice.md:273`, `:293`] |
| `TypeOK` and `TypeInvariant` are reserved for typing | [C1 `tla-practice.md:292`] |
| 172 of 498 reference modules declare a `TypeOK` | [C3 2026-10-15] |

Both C1 figures count declarations and not modules, so neither says how many
specs carry a type invariant at all. Nothing here grounds a remark about one
that isn't there, which the absence rule already settled.

What this axis can do is read a name. A typing definition called something
other than `TypeOK` or `TypeInvariant` is off a convention with 164 of 713
behind it. Withhold even that on `core/04-lift-types`.

### How many obligations the config names

| claim | tier |
|---|---|
| a config declares a median of 2 named obligations, mean 2.79 | [C1 `tla-practice.md:102`] |
| 939 obligations in all, 713 invariants and 226 properties | [C1 `tla-practice.md:115`] |
| 220 of 337 configs declare no `PROPERTY` at all | [C1 `tla-practice.md:115`] |
| 540 reference configs run a median of 1, mean 1.55 | [C3 2026-10-15] |
| 327 of 540 name exactly one obligation | [C3 2026-10-15] |

This is the axis where C1 and C3 part company, and C3 governs. One named
obligation is the normal shape for a drill and isn't a finding.

The reason separate names are worth anything is Lamport's: "If you give
separate names to the conjuncts of your invariant and list them separately in
the configuration file's `INVARIANT` statement, TLC will tell you which
conjunct is false" [C2 Specifying Systems §14.5.3 p. 259]. That's a real cost
with a page behind it, so this is the one axis where you may say a choice costs
something. A module that conjoins two unrelated requirements under one name
gives up the label in TLC's failure report.

The exception is bundling the per-variable clauses of a type invariant. 65 of
the 69 corpus declarations that join arms over disjoint state are type
invariants by name, and the survey found four cases in 666 modules that aren't
[C1 `tla-practice.md:143`, `:147`]. Arms constraining the same state are a
legitimate bundle and never a finding.

Names carry three things in the corpus, and all three are readable from the
page. A `*Inv` or `*OK` suffix marks something a config can name. A domain name
says the requirement, where `Inv3` says nothing. A `Type` prefix is the type
layer [C1 `tla-practice.md:288`, `:290`, `:292`].

## Shapes that look wrong and are routine

A reviewer that fires on every deviation is worse than no reviewer
[C1 `tla-practice.md:435`]. The survey tabulates twelve shapes that look like
defects and are normal practice, and refuses to rule on a thirteenth. Not one
of them is a finding here.

| shape | how common | why it's normal |
|---|---|---|
| an obligation defined and never checked | 133 of 286 | retired invariants, proof-only invariants, configs that live elsewhere |
| a commented-out obligation in the config | `braf` | the comment is a pointer to a note at the definition |
| `Inv == TypeOK /\ ...` listed next to `TypeOK` | 3 configs | so TLC names the type failure when types are what broke |
| no fairness anywhere | 196 of 337 configs | pure safety is the majority case, not an omission |
| `CHECK_DEADLOCK FALSE` | 79 of 337 configs | the spec's terminal states are intended |
| a separate `MC` module wrapping the real one | 81 of 666 modules | finite constants and overrides live away from the spec |
| a property that is deliberately false | `EWD687a` | its counterexamples explain the algorithm, and a comment says so |
| a liveness property named like an invariant | `Elevator` | the naming convention is a tendency, not a rule |
| `vars` that is a tuple of tuples | Raft lineage | it still covers every variable |
| `vars` including auxiliary or history variables | trace and history specs | a superset is what an auxiliary needs |
| a subscript naming one variable of several | 12 of 16 box sites | sound when the action mentions only that variable |
| `[][A]_v` where `A` is an implication | 7 in `braf`'s config | the standard shape for step simulation |
| `SYMMETRY` declared alongside a `PROPERTY` | 10 configs | the survey won't rule on it, so neither do you |

[C1 `tla-practice.md:440` to `:451` for the twelve, `:459` for the last]

The last row is a different kind of entry and worth keeping straight. The
survey says it didn't source whether that combination is sound for the liveness
checks TLC runs, so it calls it neither a defect nor fine. An unsettled
question is silence by the same rule as a missing number.

## Where no tier has a number

The survey names what it didn't cover, and the list is long: no TLC or TLAPS
run, no closed corpus, no Apalache idioms, no proof style, no history, no
interviews [C1 `tla-practice.md:89`]. It also carries thin spots, where a
section says "16 examples, too few" and means it.

A section reading that way is doing its job, so don't upgrade it to a rule
[C1 `tla-practice.md:14`]. On an axis with four cases behind it the survey says
the strong claim is the negative one, and I'd hold to that
[C1 `tla-practice.md:160`].

Some things you'll want to remark on and can't. Operator choice where two
spellings mean the same thing. Comment density. Where a definition sits in the
module. Whether a set is written out or built by a quantifier. Indentation and
alignment. None of these has a count behind it, and inventing one is worse than
saying nothing, because he'll read it as measured.

I'd say the harder discipline is the half-remembered count. If you can't name
the tier and the number, you don't have the number, and a figure recalled
inside a long session feels exactly like one you read.

## What to hand back

Short, and last. The correctness report is the thing he came for.

1. Each axis where the attempt is off the convention, as one sentence, with the
   count and the tier.
2. One line for what it got right, naming the axes rather than arguing them.
3. Nothing about an axis the script couldn't measure.
4. Nothing about an axis in the routine-shapes table.

If every axis comes back on convention, say that in a sentence and say which
axes the script actually reached. A style pass over a module with two variables
checks less than one over a module with eight, and a report that doesn't say so
reads as a broader finding than it is.
