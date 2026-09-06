# Consistency check: statement against specification

I read the statement's rules 1 to 8 against `Majority.tla`, `MCMajority.tla` and
`MCMajority.cfg`. Then I ran the model checker on a copy to settle what reading
couldn't. `MajorityProof.tla` is out of scope and I only used it to see what the extra
invariant is for.

Two lists follow, then the rules that come out clean, then the runs. Every finding
carries a classification: a defect in the statement, a scope limit to disclose to the
learner, or a difference that needs no action.

## What the specification does that the statement never licensed

### The candidate exists before anything is read

Rule 6 says that when nothing is standing there's no candidate. The initial predicate
picks one from the value set anyway (`Majority.tla:40`), and the type invariant keeps
one there for the whole run (`Majority.tla:34`). On the empty sequence the walk never
reads a position and still holds a candidate. My probe returned that state as an initial
state (exit 12).

The cost is measurable. 364 inputs produce 1092 initial states, two thirds of which
differ only in a value nothing has read. They merge on the first step. That merge is the
726-state gap between the 3459 states generated and the 2733 distinct ones in the
baseline run (exit 0).

Nothing reads the candidate while the count is zero (`Majority.tla:46-48`), so the extra
value can't affect a result. **Difference that's fine.** No action.

### The value set has to be declared, non-empty, and enumerable

`Majority.tla:16` assumes the value set isn't empty, which the choice above forces. Rule
2 says only that values compare for equality, and rule 1 admits the empty sequence. Over
an empty value domain the empty sequence is the only sequence there is, and this model
can't represent that instance at all.

The correctness statement also quantifies over the declared value set rather than over
the values the input actually contains (`Majority.tla:71`). A model that drew its values
from the input alone would never need to name a value set. **Scope limit**, and a small
one. I'd mention it only if a learner asks why the value set is a parameter.

### Fairness is declared and nothing consumes it

The behavior formula carries a weak fairness conjunct (`Majority.tla:56`). The config
names invariants only (`MCMajority.cfg:10-13`), so no temporal property is checked and
the conjunct does no work in any run. Rules 3 and 7 imply the walk finishes, so the
fairness is licensed in spirit. Termination isn't checked anywhere in this directory.

**Scope limit worth disclosing.** A learner who wrote a termination property and checked
it did something the reference doesn't do.

### An extra invariant exists to serve a proof

`Majority.tla:73-77` defines a strengthening the statement never asks for, and the
config checks it alongside the requirement (`MCMajority.cfg:13`). It's there for the
proof module, which consumes it at `MajorityProof.tla:64`. This project excludes TLAPS.

Checking it with a model checker shows it holds on the reachable states. That isn't the
same as showing it's inductive, which is what the proof needs it for.
**Difference that's fine**, though a learner should know why an invariant nobody asked
for is in the config.

## What the statement claims that the specification doesn't do

### Rule 5 contradicts rule 4, and the specification takes rule 4's side

This is the one real defect I found.

Rule 4 says every read position is cancelled or standing, and that a cancellation pairs
exactly two read positions whose values differ. Rule 5 says a position cancels at the
moment it's read, or never.

Take any sequence whose second value differs from its first. Position 1 is read with
nothing standing, so rule 5 says it doesn't cancel and rule 4 makes it standing.
Position 2 is read, position 1 is standing and differs, so rule 5 says position 2
cancels. Rule 4 says that cancellation pairs two read positions, and position 1 is the
only other one. So position 1 is cancelled now. It wasn't cancelled when it was read,
and rule 5 says it never will be.

The specification realises rule 4. The cancel branch decrements the count
(`Majority.tla:52-54`), so a position that was standing stops standing at a step where
some later position is being read. On the input `<<C, B>>` the count runs 0, then 1,
then 0 across three states, and my probe returned that trace (exit 12).

The word "cancels" is carrying two senses across adjacent rules. Rule 4 uses it as a
status a position has. Rule 5 uses it as an act a position performs. Under the second
sense rule 5 is true and says something useful about the arriving position. Under the
first it's false from the very first cancellation.

**Defect in the statement.** The learner has to guess which sense is meant, and the
guess decides whether their model lets a standing position become cancelled later.
That's a structural decision about their state, not a wording preference. My suggested
repair is to scope rule 5 to the arriving position. Then say a standing position's
status changes only when it's drawn as a partner. Dropping rule 5's first sentence and
letting rule 4 carry the mechanics would also work.

### Rule 8 is established for 364 inputs, not in general

The specification states rule 8's forward direction as written (`Majority.tla:69-71`)
and the config checks it (`MCMajority.cfg:12`). The baseline run establishes a finite
instance: three values, length 0 to 5, 364 inputs, and 366 terminal states out of 2733
reachable (exit 0).

I checked that the instance isn't vacuous. Terminal states with a real majority exist,
witnessed on `<<A>>` (exit 12). The bound also reaches the awkward path, not only the
easy ones. On `<<B, A, A>>` the count falls to zero part way through while A holds a
majority of the whole (exit 12).

The unbounded result rests on `MajorityProof.tla`, which this project excludes.
**Scope limit, and the first one I'd disclose.** A learner told in rule 8 that the
guarantee holds will find the reference model establishes it over 364 inputs.

### Rule 7's report isn't modelled, and "no candidate" isn't reportable

Rule 7 has the walk report the standing value, or report that it has no candidate.
There's no report here and no output variable. The answer is whatever the candidate
variable holds in a state past the end of the input (`Majority.tla:44`,
`Majority.tla:70`). "No candidate" lives in the count being zero, which the property
never consults.

So the candidate holds a value in every state where rule 7 says there's nothing to
report. 57 of the 366 terminal states have nothing standing. In 54 of them the input is
non-empty and the candidate holds the last value that stood. `<<C, B>>` ending on C is
the case I pulled out (exit 12). The other three are the empty input, where the
candidate holds a value the walk never read.

Nothing goes wrong from it. I checked that no value holds a majority in any terminal
state where nothing stands (exit 0). So the correctness property is vacuously true in
the same states where the report would say "no candidate".
**Scope limit worth disclosing.** A learner who modelled the report as a distinguishable
outcome built something the reference doesn't have.

### Rule 6 is assumed here, not established

Rule 6 says all standing positions carry one and the same value at every moment. This
model has one variable for the candidate (`Majority.tla:26`), so uniformity isn't a fact
about the state. It's the shape of the state, and nothing checks it.

Rule 6's second clause, that the walk starts fresh once nothing stands, is true here and
also unstated. The branch taken when the count is zero ignores the candidate
(`Majority.tla:46-48`). From such a state the candidate has no effect on anything that
follows.

**Difference that's fine, and disclose it.** The statement's own author notes expect a
learner might turn rule 6 into something checked. That learner will open the reference
and find it can't be checked there, and I'd rather they hear why first.

### Rule 8's converse is asserted and never witnessed

Rule 8 says the converse fails and the walk can report a value holding no majority.
Nothing in the specification states or shows it. It's true of the model. On
`<<A, B, C>>` the walk ends holding C, which occupies one position of three (exit 12).

A negative claim like this isn't an obligation, and showing it takes a deliberate
witness rather than a property. **Difference that's fine.** No action, though it's the
other thing a learner may have built that the reference doesn't have.

## Rules that come out clean

Three of the eight need no finding, and I'd rather say so than reach.

**Rule 1**, fixed and possibly empty. Every step pins the input (`Majority.tla:45`), and
under the wrapper's bounded replacement length 0 is admitted (`MCMajority.tla:11`). The
empty input is a reachable initial state, which my probe returned (exit 12).

**Rule 2**, nothing known but equality. The module compares values with equality and
inequality only, at `Majority.tla:47`, `Majority.tla:49`, `Majority.tla:52` and
`Majority.tla:62`. All the arithmetic is over positions and counts, never over values.
The wrapper supplies model values, which support nothing but equality
(`MCMajority.cfg:4-6`).

**Rule 3**, read once in order and never return. The step advances the index by one
(`Majority.tla:45`) and the guard stops the walk at the end (`Majority.tla:44`).

## The runs

I copied the three files above to a scratch directory and added probe modules there.
The corpus directory wasn't touched. Version reported by the tool is TLC2
2026.07.31.184830.

Five of the probes negate an existence claim, so exit 12 there is the witness I was
after. One asserts something positive and passes at exit 0. One re-runs the published
obligations under a permutation set, and the other two rows are the published model
unchanged.

| command | exit | what it settles |
|---|---|---|
| `tlc -workers auto MCMajority` | 0 | baseline, 3459 generated, 2733 distinct |
| `tlc -config Probe_NoEmptySeq.cfg -workers auto Probe` | 12 | the empty input is reachable |
| `tlc -config Probe_NoMajorityEverExists.cfg -workers auto Probe` | 12 | some terminal state has a real majority |
| `tlc -config Probe_NoFalseCandidate.cfg -workers auto Probe` | 12 | the walk can end on a non-majority value |
| `tlc -config Probe_NoEmptyStanding.cfg -workers auto Probe` | 12 | the walk can end with nothing standing |
| `tlc -workers auto -dump states.dump MCMajority` | 0 | the state dump behind the counts below |
| `tlc -config Probe2a.cfg -workers auto Probe2` | 0 | nothing standing at the end means no majority |
| `tlc -config Probe2b.cfg -workers auto Probe2` | 0 | permutation symmetry holds, 466 distinct states |
| `tlc -config Probe3.cfg -workers auto Probe3` | 12 | the count reaches zero on a majority input |

The state counts come from the dump: 2733 reachable states, of which 366 are past the
end of the input and 2367 aren't. 57 of the 366 have nothing standing, and 54 of those
are on a non-empty input.
