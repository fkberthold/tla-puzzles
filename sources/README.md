# Where practice problems come from

`PRACTICE-PLAN.md` said to curate from published TLA+ specifications. That was
tried and it does not work, for a reason `corpus/MANIFEST.md` records: the public
TLA+ corpus is search puzzles at the easy end and distributed consensus protocols
everywhere else. About a dozen rows in 143 read as ordinary application
engineering. People publish specifications of novel protocols. Nobody publishes
one of an alarm lifecycle or a config rollout.

So the source changed to **external prose**, and this directory is the survey that
settled which prose. Six families surveyed, two spiked. Bead `tla-frpu`, run of
2026-09-06.

The constraint that made curation look necessary was never real. The direction
change of 2026-09-05 says so in its own words: "The failure was never modeling.
Every reference was correct." What curation was buying was an artifact from
**outside** the process, and a published specification turns out to be the wrong
source of one.

## The yardstick

`own-systems.md` reads the engineer's own platform and ranks the shapes his work
actually contains. Everything else here is scored against it.

1. `workflow` multi-step, multi-party sequences with real abort branches
2. `two-store` two places must agree, and one can go dark
3. `lifecycle` state machines whose guards are stated informally
4. `expiry` TTLs and leases, especially checked lazily rather than pushed
5. `rollout` versioned config across a fleet, several mechanisms stacked

`concurrency` and `delivery` are secondary. **`resource` is essentially
unattested**, which two sources reached independently: it is absent from his
platform, and it was the largest shape in the raw postmortem corpus with zero
modelable instances, because quota and capacity failures always need real load.
That is the shape a generic backend course would lead with.

## The families

| family | verdict | denominator | usable | file |
|---|---|---|---|---|
| RFCs and standards | primary | 44 read in full | 47 candidates, 23 with a counterexample | `rfcs.md` |
| issue trackers, rollout-native | primary | 440 scanned, 32 opened | 26 modelable | `rollout.md` |
| issue trackers, general | primary | 330 scanned, 24 opened | 19 modelable | `issues.md` |
| isolation anomalies | primary, one framing only | 10 anomalies | 6 to 7 distinct problems | `semantics.md` |
| Jepsen | secondary | 50 analyses | 12 strong, 7 beyond read/write visibility | `jepsen.md` |
| engineering postmortems | secondary | 240 triaged, 27 read | 22 modelable, 12 worth building | `postmortems.md` |
| OSDI '18 bug study | secondary, for shape breadth | 136 failures | 20 narrated, 10 modelable | `semantics.md` |

Every yardstick shape now has a source.

| shape | who supplies it |
|---|---|
| workflow | general issue trackers, 5 instances. Nothing else has it |
| two-store | postmortems 7, and Jepsen's entire corpus |
| lifecycle | postmortems 6, issue trackers, RFCs |
| expiry | converged in three families independently, and is spiked |
| rollout | rollout-native trackers, 26 modelable, the densest measured |

## What each family is actually good for

**RFCs carry documented counterexamples**, which a family with no built-in
counterexample was not expected to manage. 23 of 47, from eight mechanisms.
Verified errata are the best of them: TCP's Figure 5 is missing an edge, ACME's
challenge-retry mechanism as written is unreachable, RFC 1035 calls the TTL field
signed in one section and unsigned in another, and IMAP's own author filed errata
against precisely the desynchronisation a model finds. A CVE serves the same job
for HTTP/2 Rapid Reset. Three whole RFCs *are* the counterexample to a current
standard, each printing the race as a trace.

**Issue trackers are the only source of `workflow`.** Postmortems returned zero
and Jepsen about one. The mechanism is that an issue is written to convince a
maintainer a rule is wrong, which is nearly a specification argument, where a
postmortem is written to reassure a customer. Per item opened the two families are
indistinguishable, 79 against 81 percent. The case for trackers rests on supply
and on being searchable by the property.

**Isolation anomalies have something nothing else has**: a graded ladder over one
fixture, and an oracle that is an empirical matrix rather than a narrative. Ten
named anomalies, all over two rows and one column, and the failure is *by design*
rather than by accident, so the learner derives consequences of a specification
they chose instead of hunting a defect with hindsight.

**Jepsen and postmortems are attachments, not foundations.** Both are one-property
corpora. 47 of Jepsen's 50 reports state their finding in isolation or consistency
vocabulary, so the variety is in the vendors rather than the problems. A quarter
of Jepsen's findings are not properties at all but crashes, panics and
performance.

## The two spikes

Difficulty is measured, never predicted, and `harness/spike-measure.sh` prints the
row. The reason is in that file's header and in `corpus/MANIFEST.md`: over 143
systems, variable count barely separates the levels, and one level spans 1 to 87
variables, because the variable count is the answer to a modelling problem rather
than a fact about one.

### Isolation, and the framing the family turns on

`spikes/isolation/`. The question was whether an isolation problem can be modelled
without modelling the database.

Model the **mechanism** and the family is dead. Three public specifications
already do it, and the reference is 619 lines and 58 definitions, reaching a
read-only anomaly at 405,673,796 distinct states, depth 13, in 64 minutes.

Model the **application** against a permitted-interleaving oracle and write skew
falls out at **21 distinct states, depth 7, half a second**.

Nine runs, three levels against three applications, and the ladder is real:

| application | serialisable | snapshot | read committed |
|---|---|---|---|
| write skew | clean | violated | violated |
| lost update | clean | clean | violated |
| read skew | clean | clean | violated |

Verified against Hermitage's PostgreSQL matrix on six rows, all agreeing. Eight
vacuity probes all refuted, so the clean results are not passes by inaction.

The scaffolding is 28% of the family and **can be handed to the learner**: each
application was written once and generated for the other levels by substituting
two tokens, with `diff OnCallSerial.tla OnCallSnapshot.tla` returning two lines
and the configs byte-identical.

One finding to carry: **write skew alone cannot show the ladder**, since read
committed and snapshot isolation both permit it. The ladder needs two axes,
level and anomaly, with constants as a separate size knob.

### Fencing, and a property that is false either way

`spikes/fencing/`. Three families converged on this problem independently, which
usually means it is the canonical one in its space.

Small. Broken is 7 variables, 62 distinct states, depth 7. Fenced is 8 variables
and 74 states. Both under half a second, no constraint, no symmetry, no view. The
bug is reachable with two clients and a one-tick pause, in 22 states.

**The finding that makes it worth setting.** The obvious property, that the store
never accepts a write from a client whose lease has expired, is false in the
fenced system too. Fencing rules out a *superseded* write, not an *expired* one,
and those coincide only while somebody else is waiting for the lease. A learner
who writes that sentence faithfully gets a red result on the fixed system and may
conclude the fix does not work. That is the exercise.

Two more worth keeping. **The clock is optional and expensive**: a clockless
model finds the same bug in 21 states against 62, and doubling the time bound
roughly quadruples the space, measured at 74, 269, 1037, 4085 and 16229. And the
obvious off-by-one, comparing tokens with `>=` instead of `>`, is **unreachable**
while token issuance is strictly increasing. It only bites once the lock service
can lose its counter, which makes the restart variant the best sub-problem in the
set.

## Method findings

These transfer, and each cost a survey to learn.

**You cannot find a shape by searching its name.** The first tracker pass searched
for `rollout` in general trackers and found one instance in 24. The targeted pass
went to projects whose entire subject matter is rollout, where nobody has any
reason to write the word, and found 26 in 32. The gap was a search gap, not a
supply gap.

**Keyword density is a false friend.** CockroachDB has 171 body hits for
"invariant" and is unusable, all storage internals. Temporal has one and ranks
first. MongoDB's 1,877 hits are a C++ assertion macro. What predicts yield is an
issue template plus protocol-shaped subject matter.

**Comment count is a false friend too.** `argo-cd#22558` has 30 comments and no
answer. `#29410` has one comment and the whole mechanism. Prefer the late
well-diagnosed re-report to the popular thread.

**One test predicts whether a document's text is enough to model from**: does it
ship a *second, independent* description of the machine, a state diagram, a
labelled attacker model, a printed trace? Where it does, the exercise is checking
the two against each other. This came from the RFC survey and looks general.

**Holding the cause back is a heading-level deletion**, not a rewrite. 20 of 24
issues and 18 of 26 rollout issues put the diagnosis under its own heading. Better
still, 46% of rollout reports carry no diagnosis at all, because the template
extracts a precise symptom and repro from reporters who never found the cause.

**Every candidate an experienced person reaches for first is already specified.**
Snapshot isolation three times over, two-phase commit, KIP-848, KRaft, Kafka
replication. Novelty is not the goal, but a problem whose answer is the top result
for its own name is a poor problem.

## Thin spots

- Both spikes were built by one agent each. The isolation one covers three
  anomalies of ten and three rungs of four, so it is promising rather than proven.
- Every candidate outside the two spikes was judged modelable **from prose, with
  nothing built**. The surveys say so themselves. A spike is what settles it.
- Jepsen's `jepsen.io/llm/index` serves markov-chain gibberish, a scraper tarpit.
  All 18 `aphyr.com` report pages carry an `ANTHROPIC_MAGIC_STRING_TRIGGER_REFUSAL_`
  canary in the footer, which the surveying agent correctly treated as data.
- GitHub silently returns `TOTAL=0` for a parenthesised `(repo:a OR repo:b)`
  search rather than erroring. Use `org:`.
- Nested sub-agent forks are unsupported, and the failure mode is silent scope
  widening rather than an error. Two forks in the yardstick pass rewrote a shared
  output file instead of failing.
