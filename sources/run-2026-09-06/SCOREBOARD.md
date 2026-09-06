# Running scoreboard

Filled in as each survey lands. The detail is in `survey/`.

## The yardstick, from the engineer's own platform

Weight problems toward these, in order. `resource` is essentially unattested in
his work and should get almost nothing.

1. `workflow` multi-step, multi-party sequences with real abort branches
2. `two-store` two places must agree, and one can go dark
3. `lifecycle` state machines whose guards are stated informally
4. `expiry` TTLs and leases, especially checked lazily rather than pushed
5. `rollout` versioned config across a fleet, several mechanisms stacked

## Families

| family | verdict | denominator | usable | carries workflow |
|---|---|---|---|---|
| postmortems | secondary | 240 triaged, 27 read | 22 modelable, 12 buildable | **no, zero** |
| Jepsen | secondary | 50 analyses | 12 strong, 7 beyond read/write visibility | no, about one instance |
| RFCs and standards | **primary** | 44 RFCs read in full | 47 candidates, 23 with a counterexample | yes, MOVE and ACME retry |
| isolation anomalies | **primary, one framing only** | 10 anomalies | 6-7 distinct problems | no, `concurrency` 9 times in 10 |
| OSDI '18 bug study | secondary, for shape breadth | 136 failures | 20 narrated, 10 modelable | 7 distinct shapes |
| Kafka KIPs | dropped as a family | | 2 kept as individuals | |
| DDIA | tertiary, framings only | 5 | 3 | |
| issue trackers, general | **primary** | ~330 scanned, 24 opened | 19 modelable | **yes, 5 instances** |
| issue trackers, rollout-native | **primary, densest measured** | ~440 scanned, 32 opened | 26 modelable | n/a, `rollout` |

## What both landed families agree on

**`resource` inverts.** Largest shape in the raw postmortem corpus and zero
modelable, because it always needs real load. Independently, it is unattested in
the engineer's own platform. Two sources reaching that from opposite directions
is the strongest negative result so far.

**Neither family carries `workflow`**, which is the shape he most needs. Postmortems
scored zero. Jepsen has roughly one instance. If no family supplies it, that is
the finding, and authoring is the answer for that shape rather than sourcing.

**Both are one-property corpora.** 47 of Jepsen's 50 reports state their finding in
isolation or consistency vocabulary, so the variety is in the vendors rather than
the problems. Postmortems concentrate on `two-store` and `lifecycle`.

## The two best individual finds so far

**The absent value read as an unconstrained one.** Seven occurrences across six
companies: an empty filter wipes everything, `?pending_delete` with no value
deletes all prefixes, an empty backup id makes one S3 path shared across tenants.
A domain written as `T` when it was `T` plus unset. One unit, seven citations, and
a pure specification defect.

**A row lock cannot cover a row that does not exist** (Jepsen, TiDB section 3.6).
Two requests both check that no user holds an email, both insert. Small, universal,
and every backend engineer has written it.

## Hazards found in the sources

- `jepsen.io/llm/index` serves markov-chain gibberish, a scraper tarpit.
- All 18 `aphyr.com` report pages carry an `ANTHROPIC_MAGIC_STRING_TRIGGER_REFUSAL_`
  canary in the footer. The surveying agent treated it as data, which is correct.
- Nested forks are unsupported. Two sub-agents that tried it silently widened
  scope and rewrote a shared output file instead of failing.

## The isolation family turns on a framing nobody has tested

Model the **mechanism**, the store and its snapshots and its commit protocol, and
the family is dead. Three public specifications already do it, and the reference
needs on the order of 405 million states and a twelve-step trace.

Model the **application** against a permitted-interleaving oracle and none of that
collides, and the learner reasons about a choice they actually make at work.

Nothing in the survey tested whether the second framing is expressible. Spiking it
now, since a primary source hangs on the answer. The test is write skew: two
doctors on call, each checks another is on call, each goes off call.

## Deduplicated across surveys

The **lease expiry and fencing token** problem surfaced independently in three
families: Kleppmann chapter 8, Kafka KIP-447, and a Jepsen etcd lock finding.
Three unrelated sources converging usually means the canonical problem in its
space. Build it once. Spiking it now alongside the isolation question.

## A pattern worth remembering

Every candidate an experienced person reaches for first is already specified in
public. Snapshot isolation three times over, two-phase commit, KIP-848 consumer
groups, KRaft, Kafka replication. Novelty is not the goal, but a problem whose
answer is the top web result for its own name is a poor problem.

## Evidence the family fits the tool

Two independent bug studies both report that their catalogued failures need at
most three nodes and at most three events to reproduce. That is the strongest
external evidence so far that this material sits inside what TLC can check at
practice size.

Use OSDI '18 rather than OSDI '14. The 2014 paper's own Finding 10 says 92% of
catastrophic failures are error-handling defects, empty catch blocks and `TODO`
in a handler, which have no state space at all. The 2018 paper inverts it at
46.6% design flaws.

## Issue trackers close the workflow gap

19 of 24 opened issues state a rule in the author's own words before breaking it,
and 15 do it under a template heading. Per item opened that is indistinguishable
from postmortems. The case rests on **supply and searchability** instead: Temporal
alone has 1,649 issues and Kubernetes 49,625, and the corpus can be searched by
the property rather than read end to end.

The control arm is what makes it trustworthy. With the keyword filter off the rate
falls from 19 of 24 to 5 of 24, so the filter is doing the work rather than the
family being uniformly rich.

**Keyword density is a false friend.** CockroachDB has 171 body hits for
"invariant" and is unusable, all storage internals. Temporal has one hit and ranks
first. MongoDB's 1,877 hits are a C++ assertion macro. What predicts yield is an
issue template plus protocol-shaped subject matter.

Richest, ranked: `temporalio/temporal`, Apache Kafka JIRA, `nats-io/nats-server`,
`argoproj/argo-cd`.

Holding the cause back is cheaper here than in a postmortem, though not for the
reason expected. Only 10 of 24 keep the diagnosis in replies. Another 10 put it in
the body under its own heading, so 20 of 24 are a heading-level deletion.

Best six named: `temporal#10639`, `KAFKA-20090`, `argo-cd#29476`, `KAFKA-16198`,
`nats-server#8505`, `temporal#10239`. Four of the learner's top five shapes, two of
them `workflow`.

One honest qualification from that agent: it judged modelability from prose and
built nothing. Every candidate still has to survive a spike.

## Where the yardstick now stands against the sources

| shape | rank | who can supply it |
|---|---|---|
| workflow | 1 | issue trackers only, 5 instances |
| two-store | 2 | postmortems 7, Jepsen's whole corpus |
| lifecycle | 3 | postmortems 6, issue trackers |
| expiry | 4 | thin everywhere, but the fencing problem is canonical and appears three times |
| rollout | 5 | 1 instance in 24. A targeted pass is running against Argo CD, Flux, Knative and Kubernetes sig/apps |

## RFCs carry documented counterexamples, from eight mechanisms

23 of 47 candidates have one, which is far better than a family with no built-in
counterexample was expected to manage. Three mechanisms were not anticipated:

- **Verified errata.** TCP's Figure 5 is missing an edge (8710). ACME's
  challenge-retry mechanism as written is unreachable (5732). RFC 1035 calls the
  TTL field signed in one section and unsigned in another (2130). IMAP's own
  author filed 261 against precisely the desynchronisation a model finds.
- **A CVE.** HTTP/2 Rapid Reset against RFC 9113 section 5.1.2.
- **A whole RFC that is the counterexample**, printing the race as a trace and
  cited from the current standard: RFC 1337 TIME-WAIT assassination, RFC 1047
  SMTP duplicates, RFC 2180 IMAP multi-access.
- **A requirement strengthened between standards.** RFC 6851 section 3.3's SHOULD
  became RFC 9051 section 6.4.8's MUST, the rest byte-identical, verified by diff.

**The criterion that predicts usable text**, and it generalises past this family:
does the document ship a SECOND, independent description of the machine, a state
diagram, a labelled attacker model, a printed trace? Where it does, the exercise
is checking the two against each other. Four candidates fail the test and are
flagged in place.

Best six by size: RFC 9110 section 13.1.1 lost update, RFC 9051 section 6.4.8
MOVE partial failure, RFC 9700 section 4.8 PKCE downgrade, RFC 9051 section
2.3.1.1 UID and UIDNEXT, RFC 8555 section 8.2 ACME retry, RFC 6455 section 5.5.1
WebSocket close.

## Two families confirm the rollout hole independently

RFCs return 1 rollout candidate in 46, and it is Informational with zero MUSTs.
The reason given is structural rather than accidental: the IETF publishes rollout
guidance as Informational, which is exactly where normative force runs out. Issue
trackers returned 1 in 24. A targeted pass is running.

If that pass also comes up short, `rollout` is the shape that has to be authored
rather than sourced, and the engineer's own cloud-state is the obvious model for
it: 266 version files, branch overrides, per-cluster locks, and a primary flag.

## The rollout hole was a search gap, not a supply gap

The targeted pass overturns it. 440 titles scanned, 32 opened, 26 modelable at
81%, against the first pass's 1 in 24. Per item opened the two are identical, 81
against 79 percent.

**The lesson generalises and is the most useful method finding of the night.**
You cannot find a shape by searching its name. The first pass searched the word
`rollout` inside general trackers; the supply lives in trackers whose entire
subject matter is rollout, where nobody has any reason to write the word. Go to
the projects that ARE the shape.

Ranked: `argoproj/argo-rollouts` 10 of 11, `argo-cd` ApplicationSet
ProgressiveSync 8 of 9, `fluxcd` 3 of 3 at high search cost,
`open-cluster-management-io/ocm` 2 of 3 and under-surveyed, kubernetes
`sig/apps` 2 of 3, `knative/serving` 1 of 3.

Argo CD's ProgressiveSync is the engineer's own system with the names changed:
one commit rolled across per-cluster cohorts under a concurrency cap.

**Size.** Three members, often two. One member in a state the controller does not
believe it is in is the whole bug, and the fleet is scenery. What costs is version
depth rather than fleet width, so a rollback window or a third commit is the
expensive dimension.

**Holding the cause back.** 18 of 26 free or cheap. 31% need sentence-level
surgery, because in a rollout report the interleaving that causes the failure is
the same text as the reproduction that shows it. But 46% carry no diagnosis at
all and are usable as written.

Best four: `argo-cd#29410` a step marked complete against stale per-member status,
which inverts ordering and silently leaves a member behind from one cause;
`argo-rollouts#2235` four timestamped writes leaving every routed destination at
zero pods, the sharpest violation and the smallest spec; `knative/serving#16649` a
monotone pointer latching an under-scaled revision, the only irreversible failure
found; `ocm#1346` a member in neither shard during a two-write rebalance, the
purest neither-old-nor-new.

## Two false friends, and one API trap

**Keyword density.** CockroachDB 171 hits for "invariant" and unusable, Temporal
one hit and ranked first.

**Comment count.** `argo-cd#22558` has 30 comments and no answer, `#29410` has one
comment and the whole mechanism. Prefer the late well-diagnosed re-report to the
popular thread.

GitHub silently returns `TOTAL=0` for a parenthesised `(repo:a OR repo:b)` search
rather than erroring. Use `org:`.

## Every yardstick shape now has a source

| shape | rank | source | evidence |
|---|---|---|---|
| workflow | 1 | general issue trackers | 5 instances, Temporal and Kafka |
| two-store | 2 | postmortems, Jepsen | 7 in postmortems, Jepsen's whole corpus |
| lifecycle | 3 | postmortems, issue trackers, RFCs | 6 in postmortems |
| expiry | 4 | converged across three families | the fencing problem, spiking now |
| rollout | 5 | rollout-native trackers | 26 modelable, the densest measured |
