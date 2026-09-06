# Survey: issue trackers of widely-used backend systems as a source of formal-modeling practice problems

**Status: complete.** Read-only survey, 2026-09-06.

Dispatched to test a sibling survey's claim that issue trackers beat postmortems as a source,
because "an issue is written to convince a maintainer that a rule is wrong, which is nearly a
specification argument."

## The answer in short

**Verdict: primary source.** The mechanism the sibling proposed is real, its density claim is
not, and the family wins anyway on three other grounds.

- ~330 issue titles scanned, **24 opened at primary source, 19 modelable** (79% of opens, 6% of
  scans). The sibling's postmortem numbers were 22 of 27 opened, 22 of 240 read. **Per item
  opened the two families are the same.**
- Switching the keyword filter off drops the rate to **5 of 24 (21%)** on an unbiased sample of
  Temporal's closed bugs. The yield is in the searching, not the reading.
- **The family supplies `workflow`, which postmortems did not.** Five instances, two strong.
  That single fact justifies the redirect.
- **The cut is cheap.** 20 of 24 issues let you delete the diagnosis by removing a heading or a
  comment. Worked example: temporal #11842.
- **`rollout` is the gap** — one instance out of 24.
- Richest projects, in order: **temporalio/temporal**, **Apache Kafka JIRA**,
  **nats-io/nats-server**, **argoproj/argo-cd**. Keyword density is a *false friend* for ranking
  them; see §3.

Denominator discipline: every issue I actually opened at primary source is counted, including the
ones that turned out useless. Titles harvested from search listings but never opened are not.

## Method

`gh search issues` / `gh issue view --json body,comments` against GitHub trackers, and the
Apache JIRA REST API (`issues.apache.org/jira/rest/api/2/search`) for Kafka. Search terms were
the ones the brief named — `invariant`, `should never`, `stale`, `orphan`, `race`, `lost`,
`duplicate`, `split brain` — plus shape-specific probes (`workflow stuck`, `signal lost`,
`rollback`, `partially applied`, `compensat`).

**Denominator rule**: an issue counts as *opened* only if I read its body at primary source.
Titles harvested from search listings but never opened are not in the denominator. Every
verdict below rests on the body text, not the title.

---

## Candidates

Ordered roughly by how good they are, not by project.

### 1. temporalio/temporal #10639 — reset parent never sees the child that finished after it died

- **URL / state**: https://github.com/temporalio/temporal/issues/10639 — OPEN
- **Situation**: A parent process starts a child, dies before the child reports back, the child
  finishes anyway, and the parent is later restarted from a checkpoint taken before the report.
- **The rule**, quoted from the body: "Expected behavior: the reset parent run should observe the
  already completed child and make progress."
- **How it breaks**: quoted numbered sequence in the body —
  "1. Parent workflow starts. 2. Parent starts a child workflow. 3. Parent fails before receiving
  the child completion. 4. Child completes successfully after the parent is already closed.
  5. Later, the parent is reset to a point after `ChildWorkflowExecutionStarted`." The diagnosis
  is one sentence: "The child close transfer task appears to report completion to the parent while
  the parent is already closed, so the completion is effectively dropped."
- **Shape**: `workflow`
- **Modelable**: **yes**. Two actors and a delivery step. The whole argument is in the numbered
  timeline; nothing in it names a function.
- **Size**: 2 actors (parent, child) + a completion-delivery channel; state = parent status,
  child status, parent history (a set of recorded events), a boolean "reset point".
- **Needs the source?** No. The repro link is a Go test, but the body's timeline stands alone.

### 2. Apache Kafka KAFKA-20090 — a transaction that can neither commit nor time out

- **URL / state**: https://issues.apache.org/jira/browse/KAFKA-20090 — Resolved
- **Situation**: A coordinator fences a timed-out transaction by bumping an epoch counter to its
  maximum, then mistakes a late abort request for a retry and hands the fenced epoch back to the
  client, which uses it to start a transaction nobody can end.
- **The rule** is given as the failure, quoted: "We cannot commit this transaction with TV2 and we
  cannot timeout the transaction. It is stuck in Ongoing forever."
- **How it breaks**: the body gives a four-step sequence verbatim —
  "1. The fencing abort on transactional timeout bumps the epoch to max
   2. The EndTxn request with max epoch - 1 is considered a 'retry' and we return max epoch
   3. The producer can start a transaction since we don't check epochs on starting transactions
   4. We cannot commit this transaction ... It is stuck in Ongoing forever."
- **Shape**: `workflow`
- **Modelable**: **yes**, and it is the cleanest `workflow` instance found. A two-party protocol
  (producer, coordinator) with an abort branch, a monotone epoch, and a retry-detection predicate.
  The bug is that the retry predicate and the fencing rule disagree on one value.
- **Size**: 2 actors + a timeout actor; state = txn state (Empty/Ongoing/PrepareAbort/
  CompleteAbort), producer epoch, coordinator epoch, a pending-request flag. Small.
- **Needs the source?** No for the sequence. Comments quote Scala, so cut them (see §"holding back
  the cause" below — this issue is the worked example).

### 3. argoproj/argo-cd #29476 — adding a cluster leaves other clusters owned by nobody

- **URL / state**: https://github.com/argoproj/argo-cd/issues/29476 — OPEN
- **Situation**: A fleet of controller replicas each computes, locally and independently, which
  members of a shared set it owns; one member is added and the replicas end up disagreeing, so
  some members are owned by no replica and simply stop being processed.
- **The rule**, quoted: "registering a new cluster can leave other clusters owned by no
  application-controller replica. Applications on the orphaned clusters silently stop reconciling
  — with no error, no Application condition, and no change to their reported health/sync."
- **How it breaks**: quoted — "Round-robin assigns `shard = index-in-sorted-cluster-list %
  replicas` ... the list is sorted by `Cluster.ID`, which is the cluster Secret's Kubernetes UID
  ... A newly created cluster Secret therefore lands at an effectively random position in that
  ordering, and every cluster sorting after it shifts by one index". Then: "The re-shuffle was then
  applied *partially* by one replica: it ended up simultaneously holding clusters that had moved
  away from it and missing clusters that had moved onto it."
  Concrete numbers are in the body: 47 → 48 clusters, new secret at index 21, "26 of the 47
  existing clusters changed shard", two clusters left orphaned, undetected for 57 hours.
- **Shape**: `two-store` (each replica's local ownership map vs. the authoritative cluster set).
  Reads as `rollout` if you emphasise the fleet.
- **Modelable**: **yes**. The invariant is one line — every cluster is owned by exactly one
  replica — and the mechanism is modular arithmetic over an ordered list, which is native TLA+.
- **Size**: N replicas (3 suffices) × M clusters (4 suffices); state = per-replica owned-set,
  global cluster list. Also carries a liveness half: the divergence is permanent because,
  quoted, "`Init` — the only path that re-derives the whole distribution from an authoritative
  cluster list — is called **once per process**".
- **Needs the source?** No. The follow-up comment is a source walk, but the body's rule
  ("shard = index % replicas", sorted by an unpredictable key) is a complete specification.

### 4. Apache Kafka KAFKA-16198 — reconciliation drops half the assignment while a name resolves

- **URL / state**: https://issues.apache.org/jira/browse/KAFKA-16198 — Resolved
- **Situation**: A consumer holds a server-assigned set of partitions, but can only act on the
  ones whose topic name it has already learned; it treats "not yet resolvable" and "revoked" as
  the same thing.
- **The rule**, quoted: "Absence of a topic in `assignmentReadyToReconcile` may mean either
  revocation of the topic partition(s), or unavailability of a topic name for the topic."
- **How it breaks**: the body gives the sequence verbatim —
  "We get assigned T1-1 and T2-1 / We reconcile T1-1, T2-1 remains in `assignmentUnresolved` since
  the topic id T2 is not known yet / We get new cluster metadata, which includes T2, so T2-1 is
  moved to `assignmentReadyToReconcile` / We call `reconcile` — T2-1 is now treated as the full
  assignment, so T1-1 is being revoked / We end up with assignment T2-1, which is inconsistent
  with the broker-side target assignment."
- **Shape**: `two-store` (broker's target assignment vs. the consumer's effective one)
- **Modelable**: **yes**, and it is the smallest good one in this list. Two sets and a name
  resolution step. The invariant is "the consumer's effective assignment converges to the
  broker's target".
- **Size**: 1 consumer, 2 topics, 1 metadata channel. Three state variables.
- **Needs the source?** No. The two collection names are the argument's vocabulary, not a
  pointer into a file.

### 5. nats-io/nats-server #8505 — a deleted key comes back after a crash

- **URL / state**: https://github.com/nats-io/nats-server/issues/8505 — OPEN
- **Situation**: A delete is recorded as a tombstone that is itself given a TTL; the tombstone
  expires, the process is killed uncleanly, state is rebuilt from the log, and the delete is gone
  while the deleted value is not.
- **The rule**, quoted: "Correctness of the delete - the key must never come back - is the entire
  point of the operation."
- **How it breaks**: the body gives a six-step deterministic repro and, better, an asymmetry that
  states the mechanism without naming a function: "sequence 9 (the PURGE marker, removed by TTL
  expiry through the single-message remove path) **stayed deleted** after the rebuild, while
  sequence 7 (`keya-v4`, removed by the rollup purge) **revived**. Two deletions, same block,
  same crash". A commenter generalises it: "the actual semantics of a PURGE is not made durable
  (may not survive dirty restarts). The semantics are, essentially, 'remove all earlier messages
  from this subject'."
- **Shape**: `expiry`
- **Modelable**: **yes**. A log of (seq, subject, kind) records, a rebuild function that replays
  it, and a TTL that can remove the tombstone before the values it covers.
- **Size**: 1 store, 2 keys, ~6 log entries, a crash action and a rebuild action.
- **Needs the source?** No. Storage-block layout is mentioned but the argument is about which
  facts survive a replay.

### 6. temporalio/temporal #10239 — paused, then running, and unpausable either way

- **URL / state**: https://github.com/temporalio/temporal/issues/10239 — CLOSED
- **Situation**: An entity has a status field and a separate "why it was paused" record; a task
  already in flight when the pause lands completes afterwards and flips the status back without
  clearing the record, and the unpause guard reads only the status.
- **The rule**, quoted: "After `PauseWorkflowExecution` succeeds, mutable state should satisfy:
  `executionState.Status == WORKFLOW_EXECUTION_STATUS_PAUSED`; `executionInfo.PauseInfo` set with
  the request's identity/reason/requestId. No further `WORKFLOW_TASK_SCHEDULED` events should be
  appended until `UnpauseWorkflowExecution` is called, and that unpause call should succeed."
- **How it breaks**: a real event log is pasted with event ids and server timestamps, ending
  "#1962 WORKFLOW_EXECUTION_PAUSED ← pause event committed / #1963 WORKFLOW_TASK_SCHEDULED ←
  ❗ scheduled AFTER pause / #1965 WORKFLOW_TASK_COMPLETED ← resets Status to RUNNING".
  End state, quoted: "`Status == RUNNING`, `pauseInfo != nil`".
- **Shape**: `lifecycle`
- **Modelable**: **yes**. Two fields that must agree, a guard that reads one of them, and an
  in-flight task that outlives the transition.
- **Size**: 1 entity + 1 worker + 1 operator; state = status, pauseInfo, in-flight-task flag.
  The smallest of the six.
- **Needs the source?** No. One file path is named (`unpauseworkflow/api.go:59`) but only to say
  the guard "only checks `Status`", which is the rule itself.

---

## The rest of the pool

Opened at primary source, worth building from, but behind the six above.

| # | issue | shape | rule (quoted fragment) | modelable |
|---|---|---|---|---|
| 7 | [etcd #15247](https://github.com/etcd-io/etcd/issues/15247) CLOSED | `expiry` | "the lessor primary is not synced up with the raft leader, there is big gap between lessor primary and raft leader when etcd server is stuck in processing raft Ready" | yes — two role flags that must move together; the old leader keeps expiring leases the new leader is renewing. 2 servers + 1 client, 4 state vars. Numbered 10-step repro in the body. Needs no source. |
| 8 | [k8s #110210](https://github.com/kubernetes/kubernetes/issues/110210) OPEN | `delivery` | "The above violates the invariant that we need in order to ensure that watch requests can be resumed at any point" | yes. The body spells the counterexample out in three bullets: a batch delete gives every object the same version, a watcher that breaks mid-batch resumes from the last version it saw, and the rest of that batch is never delivered. 1 watcher, 1 store, 3 objects. Source links are decoration. |
| 9 | [temporal #11842](https://github.com/temporalio/temporal/issues/11842) OPEN | `rollout` | "After promoting a build to current ... the routing config propagation should complete shortly and `DescribeWorkerDeployment.routingConfigUpdateState` should transition to `COMPLETED`" | yes — and it is the **best worked example of holding the cause back** (below). Body is pure symptom; the cause is in a reply. |
| 10 | [k8s #125410](https://github.com/kubernetes/kubernetes/issues/125410) CLOSED | `lifecycle` | Failure mode quoted from a maintainer reply: "the pod first is counted as Succeeded, then as Failed." The controller then wedges on `status.uncountedTerminatedPods.failed[0]: Duplicate value`. | yes. A counter, a set of not-yet-counted terminations, a finalizer that must be removed exactly once, and a terminal state that can be re-observed as a different terminal state. Close to the learner's own reconciler work. |
| 11 | [nats-server #8348](https://github.com/nats-io/nats-server/issues/8348) OPEN | `two-store` | "the meta layer still holds R1 stream assignments for them ... The condition **survives a full restart of the node and a rolling upgrade** ... it does not self-reconcile" | yes, though bulkier than the six. A metadata plane and a data plane that must agree, plus a health check that reads only one of them. |
| 12 | [temporal #10841](https://github.com/temporalio/temporal/issues/10841) OPEN | `two-store` | "`SignalWithStartWorkflowExecution` for a workflow ID makes progress: it either signals the running execution or starts a new run, and returns within the client deadline." | yes, and it is a nice **liveness** exercise rather than a safety one: a pointer row survives, the row it points at does not, and the create path is conditioned on the pointer's absence, so the retry loop never terminates. 1 caller, 2 tables. |
| 13 | [temporal #11869](https://github.com/temporalio/temporal/issues/11869) OPEN | `expiry` | "The internal scheduler workflow still holds a pending timer in its mutable state, but **no corresponding row exists in the `timer_tasks` table**, so the timer never fires." | yes. The logical timer and the physical timer are two stores that must agree; only one of them makes anything happen. The body proves the logical side was intact ("`tdbg workflow refresh-tasks` recovers the schedule"). |
| 14 | [k8s #116485](https://github.com/kubernetes/kubernetes/issues/116485) CLOSED | `lifecycle` | "the lease controller is not aware of this and keeps renewing the lease ... this will keep updating the lease, that is wrong, because the node object doesn't exist" | yes, and it is the smallest thing here — two loops over one entity, one of which notices deletion and one of which does not. Body also names the consequence: "a new VM with the same name register and the other kubelet is still running, this may cause a conflict". |
| 15 | [etcd #14758](https://github.com/etcd-io/etcd/issues/14758) CLOSED | `expiry` | "I use Watch API and observe that sometimes all keys attached to one lease are deleted without any warning/error log ... When I check with `lease timetolive`, I expect keys remain" | yes, but the body is a user report padded with production key names. Weaker than #15247, which is the same family stated better. |
| 16 | [temporal #2694](https://github.com/temporalio/temporal/issues/2694) CLOSED | `concurrency` | The body states the algorithm as four steps and then breaks it with a five-row `T = 0..4` interleaving ending "see target workflow '1234-5678' is finished, while the actually current workflow is 'abcd-efgh'". | yes. Textbook read-then-lock race, written as a trace. Very small. The body also contains the fix in Go, so it must be cut. |
| 17 | [consul #5047](https://github.com/hashicorp/consul/issues/5047) CLOSED | `lifecycle` | "violates the assumption that establishLeadership has to succeed before we can handle requests as the leader"; a maintainer adds "does a bunch of work that _must succeed_ for the leader to be in a healthy state." | yes, but thin — the issue states a rule and never exhibits a sequence. Good raw material, more authoring work than the six. |
| 18 | [Kafka KAFKA-20685](https://issues.apache.org/jira/browse/KAFKA-20685) Resolved | `two-store` | "Under EOS an unclean crash during RUNNING should hit the no-checkpoint path, throw TaskCorruptedException and wipe local state, because the store may contain uncommitted writes." | yes-weak. The rule is clean, but the body then argues in line numbers on a specific tag ("verified on the 4.1.2 tag"), so the cut has to remove more than a trailing section. |
| 19 | [CockroachDB #173315](https://github.com/cockroachdb/cockroach/issues/173315) OPEN | `two-store` | "That ordering is only sound if the in-memory threshold is bumped *before* the data it describes is removed." | yes as a modelling exercise — that sentence is already a TLA+ ordering invariant — but **rejected for this learner**: it is Raft snapshot internals, the family he called irrelevant and too large. |
| 20 | [argo-workflows #16450](https://github.com/argoproj/argo-workflows/issues/16450) CLOSED | `workflow` | "A DAG workflow that has been retried one or more times can end up permanently Running with every pod finished." | yes-weak. Defect 1 is genuinely modelable — a retry walks *one* parent chain up from the failed node, and a node with several parents keeps whichever parent the map iteration saw last, so "which nodes a retry resets is a coin flip". But the argument is carried by a Go snippet. |
| 21 | [temporal #2140](https://github.com/temporalio/temporal/issues/2140) CLOSED | `workflow` | "It looks like `resetWorkflowExecution` is idempotent and duplicate requests with the same `requestId` is getting ignored, including an empty one." | yes-weak. A real idempotency-key invariant, but the whole model is "the default value collides", which is a one-step counterexample. |

### Opened and rejected

Counted in the denominator. These are the discriminator working.

- **[envoy #46561](https://github.com/envoyproxy/envoy/issues/46561)** — `delivery`, and a genuinely interesting bug. Rejected: the entire argument is a walk through named C++ methods — "`NewGrpcMuxImpl::addWatch()` registers the on-demand filter's initial subscription with an **empty** resource-name set, which the internal `WatchMap` treats as a wildcard/catch-all watch". Delete the method names and nothing is left to model. **Needs the source: yes.**
- **[argo-workflows #16638](https://github.com/argoproj/argo-workflows/issues/16638)** — rejected for the same reason, more sharply: the author's own framing is "I have tested against `:latest` **by line-verifying the source rather than running it**", and the key claim is `// v3.6.5:2262 (main:2575)`. The invariant it states ("`node.Fulfilled() == true` is therefore an invariant at the `markNodeError` call") is an invariant *of a call site*, not of the system.
- **[Kafka KAFKA-13357](https://issues.apache.org/jira/browse/KAFKA-13357)** — states a real invariant in one sentence ("the invariant that controllers snapshots are equivalent to broker snapshots") and then stops. Two sentences total. Nothing to exhibit.

---

## 1. Is the sibling's argument right?

**Partly.** Its mechanism is right and its comparison is wrong.

The mechanism — "an issue is written to convince a maintainer that a rule is wrong, which is
nearly a specification argument" — holds. In 24 issues opened at primary source, **19 state a
rule in the author's own words before showing the case that breaks it**, and 15 of those state it
under a heading the template supplied: `## Expected Behavior` / `**Describe the problem**` /
`h3. Expected behavior`. That heading is doing the work. It is a form field that asks a bug
reporter for a specification, and people fill it in.

The comparison does not hold on density, because I ran the honest control.

**Targeted arm** — issues surfaced by the brief's own search terms (`invariant`, `should never`,
`stale`, `orphan`, `race`, plus shape probes) and then opened:

| | count |
|---|---|
| titles scanned in search listings | ~330 |
| opened at primary source | 24 |
| modelable | 19 |
| modelable and worth building | 15 |

**Unbiased arm** — 25 most recent `label:bug` closed issues in Temporal, the richest project
found, taken without any keyword filter, bodies read:

| | count |
|---|---|
| issues (excluding PRs) | 24 |
| modelable | 5 |
| modelable and worth building | 2 (#2694, #2140) |

So: **19 of 24 opened (79%)** in the targeted arm, against **5 of 24 (21%)** with the filter
switched off. The sibling reported 22 of 27 opened and 22 of 240 read. Per item opened the two
families are the same, near 80%. Per item *scanned* mine is worse — 19 of ~330, about 6%,
against its 9%.

The ratio is not the point, and this is where I part company with a straight "issue trackers
win" reading. Two things do not show up in the ratio:

- **The corpus is unbounded.** 240 postmortems is a large fraction of the good public ones.
  Temporal alone has 1,649 issues, Kubernetes 49,625, CockroachDB 88,673 (`gh api search/issues
  -f q="repo:X is:issue" --jq .total_count`). The 6% scan rate is over a supply that does not run
  out, and it was achieved with four keywords and no craft.
- **The filter is native.** A postmortem corpus is not searchable by "contains a stated
  invariant"; an issue tracker is, because the word appears in the argument. The targeted arm's
  79% is the number that matters operationally — it says roughly five opens per four usable
  problems, once you search for the property rather than the incident.

## 2. Does this family supply `workflow`?

**Yes.** This is the finding that justifies the family on its own, since the postmortem survey
returned zero.

Named candidates, in order:

1. **[Kafka KAFKA-20090](https://issues.apache.org/jira/browse/KAFKA-20090)** — a two-party
   transaction protocol with a real abort branch, where the abort path and the retry-detection
   path disagree about one epoch value and leave a transaction that can neither commit nor time
   out. The best `workflow` instance found anywhere in this survey.
2. **[temporal #10639](https://github.com/temporalio/temporal/issues/10639)** — parent/child with
   the parent aborting mid-flight and the child's completion arriving at a dead addressee.
3. **[temporal #2694](https://github.com/temporalio/temporal/issues/2694)** — a multi-step
   resolve-then-act sequence against a target that hands off its identity between the two steps.
4. **[argo-workflows #16450](https://github.com/argoproj/argo-workflows/issues/16450)** — a DAG
   retry that resets one ancestor chain out of several and leaves a group nobody will ever
   finish. Weaker, because the argument is carried by a Go snippet.
5. **[temporal #2140](https://github.com/temporalio/temporal/issues/2140)** — idempotency keys on
   a retryable multi-step operation. Weakest; one-step counterexample.

The supply is not accidental. Workflow engines — Temporal, Cadence, Argo Workflows, and Kafka's
transaction coordinator, which is a two-phase commit in all but name — have issue trackers whose
subject matter *is* multi-step multi-party sequences with abort branches. That is the entire
domain. A postmortem corpus has no equivalent concentration because the shape is invisible from
the customer-facing end: a saga that half-applied reads, in a postmortem, as "some records were
inconsistent".

**Where to mine more of it**: `temporalio/temporal` first, then Kafka's `KAFKA` JIRA restricted to
the transaction coordinator and group coordinator components, then `argoproj/argo-workflows`
accepting a lower yield per open.

## 3. Which projects are richest?

Ranked by modelable-per-opened plus the register the community writes in. Counts are what I
actually opened, so the small ones are small.

| rank | project | opened / modelable | why |
|---|---|---|---|
| 1 | **temporalio/temporal** | 8 / 7 | The template (`## Expected Behavior` / `## Actual Behavior`) forces a rule statement, and the domain is the learner's top shape. Recent issues (2025-26) paste real event histories with event ids and timestamps, which is a counterexample trace already written out. Supplies `workflow`, `lifecycle`, `expiry`, `rollout`. |
| 2 | **Apache Kafka (`KAFKA` JIRA)** | 4 / 3 | Protocol-level arguments about epochs, assignments and transaction state, written in prose because the audience is other protocol designers. `text~"invariant" AND resolution=Fixed` alone returns 36. Best source of `workflow` and `two-store`. |
| 3 | **nats-io/nats-server** | 2 / 2 | Small yield but the highest per-issue quality found: deterministic numbered repros, and authors who state the semantic rule ("the actual semantics of a PURGE ... 'remove all earlier messages from this subject'") rather than the code path. Strong on `expiry`. |
| 4 | **argoproj/argo-cd** | 1 / 1 | One open, one outstanding candidate (#29476). Fleet-ownership and sync-state arguments, which is exactly `rollout` and `two-store`. Under-sampled here; I would mine it next. |
| 5 | **etcd-io/etcd** | 2 / 2 | Reliable on `expiry` and `two-store`. Argues in terms of raft/lessor roles, which is one level more internal than Temporal but still above the source. |
| 6 | **kubernetes/kubernetes** | 3 / 3 | Everything I opened was modelable, but the surrounding noise is the worst in the survey: a `state:closed` search for `invariant` and for `race` returned mostly flaky-test and CI tickets. Mine it by area (`sig/apps` Job controller, kubelet lease, endpoints) rather than by keyword. |
| 7 | **hashicorp/consul** | 1 / 1 weak | States rules ("violates the assumption that establishLeadership has to succeed") but rarely exhibits a sequence. More authoring work per problem. |
| 8 | **argoproj/argo-workflows** | 2 / 1 weak | Right shape, wrong register. The community writes source-line arguments (`// v3.6.5:2262 (main:2575)`), and one maintainer reply in my sample was a genAI-policy warning, which suggests the culture is hostile to prose-only reports. |
| 9 | **envoyproxy/envoy** | 1 / 0 | Arguments are C++ method walks. |
| — | **cockroachdb/cockroach** | 1 / 1, out of domain | Highest `invariant` word count in the survey (171) and the least usable, because the subject matter is storage-engine and Raft internals — the family the learner has already rejected. |
| — | **jira.mongodb.org `SERVER`** | 0 opened, 20 titles scanned | Dropped without opening a body, and the reason is worth recording: `text~"invariant"` returns 1,877 issues, but `invariant()` is a **C++ assertion macro** in that codebase. The word marks a crash site, not a specification. A lexical probe cannot tell those apart. |

**The lexical probe is a false friend, and this is a methodological finding.** Density of the
word `invariant` in issue bodies, measured with `gh api search/issues`:

| project | issues | `"invariant"` in body | `"should never"` in body |
|---|---|---|---|
| cockroachdb/cockroach | 88,673 | 171 | 144 |
| kubernetes/kubernetes | 49,625 | 33 | 222 |
| etcd-io/etcd | 7,258 | 16 | 29 |
| envoyproxy/envoy | 14,131 | 10 | 27 |
| argoproj/argo-workflows | 6,651 | 3 | 22 |
| nats-io/nats-server | 2,211 | 1 | 11 |
| **temporalio/temporal** | **1,649** | **1** | **9** |
| argoproj/argo-cd | 10,604 | 1 | 33 |

The project I rank first has the lowest raw count in the table. What predicts yield is not the
vocabulary — it is whether the issue template asks for expected behaviour, and whether the
subject matter is a protocol rather than a data structure. Rank by those, then search.

## 4. Can the cause be held back?

**Yes, and more easily than for postmortems — but not for the reason the brief guessed.**

The brief's hypothesis was that "an issue thread usually has the diagnosis in the replies rather
than the body". That is only half true. My hand tally over the 24 opened:

| where the cause sits | count |
|---|---|
| in the replies, or nowhere | 10 |
| in the body, under its own heading or trailing sentence | 10 |
| in the body, woven into the same sentence as the rule | 4 |

So in 10 of 24 the cut is free, exactly as hoped. But the interesting number is the middle row.
When issue authors put the cause in the body they **fence it off**, because the templates and the
conventions push them to. The observed headings, quoted verbatim from the bodies I read:
`**Root cause**` (CockroachDB #173315), `## Root cause (from source)` (Envoy #46561),
`## Why this seems problematic` (temporal #10639), `### Defect 1:` (argo-workflows #16450),
`h3. Code paths (verified on the 4.1.2 tag)` (KAFKA-20685), `Here is the reasoning of what could
happen:` (temporal #10841), `Generally, this seems to be a problem around semantics of...`
(KAFKA-16198), `Essentially the above 2 issues are because of...` (etcd #15247).

**So in 20 of 24, holding the cause back is a heading-level deletion.** That is qualitatively
different from a postmortem, where the diagnosis is the narrative spine and removing it removes
the story. Here it is an appendix.

The residual 4 are the ones where the rule and the cause are the same sentence — argo-cd #29476
("Round-robin assigns `shard = index-in-sorted-cluster-list % replicas` ... the list is sorted by
`Cluster.ID`, which is the cluster Secret's Kubernetes UID") states the mechanism *as* the rule.
Those need rewriting, not cutting.

### Worked example: temporal #11842

The cleanest case in the survey, because the body is pure symptom and a reply carries the whole
diagnosis.

**What the body gives you** (`## Expected Behavior`, `## Actual Behavior`, `## Steps to
Reproduce the Problem`), quoted:

> After promoting a build to current via `SetWorkerDeploymentCurrentVersion`, the routing config
> propagation should complete shortly and `DescribeWorkerDeployment.routingConfigUpdateState`
> should transition to `COMPLETED`.

> For one worker deployment (a task queue serving **both workflows and activities**),
> `routingConfigUpdateState` is **permanently `IN_PROGRESS` (1)** and never transitions to
> `COMPLETED` ... The deployment workflow ... has **no pending activities**, and its event history
> contains **only the initial startup events** — the `PropagationComplete` signal from the version
> workflow never arrives (or is never processed).

Plus a three-row table showing the same promotion completing on two activity-only queues and
hanging on the one queue that serves both types, and a repro of three numbered steps.

That is a complete practice problem: a promotion protocol, a fleet, a state that must reach
`COMPLETED`, and an observation that it does not for one member. The learner has a rule, a
counterexample to find, and a strong hint about which member is special — with **no cause**.

**What the reply gives you**, and what you withhold — comment by `CodeBuildder`:

> I traced the root cause: the deployment workflow waits forever on a one-shot
> PropagationCompleteSignal from the version workflow, with no timeout and no fallback if that
> signal's underlying transfer task gets lost (same failure class as #11402).

One sentence, in a comment, cleanly separable, and it is the entire answer: a one-shot signal
with no retry and no watermark. Delete the comment and the problem is intact. Keep it and there
is nothing to discover.

The same reply even supplies the follow-up exercise, since it proposes two fixes of different
strength — "retry the signal send itself a couple of times with backoff" versus "add a durable
'last propagated revision' watermark ... so the deployment workflow can self-heal" — and only one
of them holds under an adversarial model. That is a second question to ask after the first one is
answered.

## 5. The best six candidates

They are written up in full at the top of this document, under `## Candidates`. In order:

1. **temporal #10639** — `workflow`. Parent aborts, child finishes anyway, restart never sees it.
2. **Kafka KAFKA-20090** — `workflow`. A transaction that can neither commit nor time out.
3. **argo-cd #29476** — `two-store`. Adding a member orphans others; nobody notices for 57 hours.
4. **Kafka KAFKA-16198** — `two-store`. "Not resolvable yet" and "revoked" confused for each other.
5. **nats-server #8505** — `expiry`. The tombstone expires before the thing it buries.
6. **temporal #10239** — `lifecycle`. Two fields that must agree; the guard reads one of them.

That set covers four of the learner's top five shapes with two instances of his first. It does
not cover `rollout`.

### Shape coverage over everything opened

| shape | learner's rank | count | note |
|---|---|---|---|
| `workflow` | 1 | 5 | The headline result. Postmortems returned zero. |
| `two-store` | 2 | 6 | Most abundant, and the easiest to state as an invariant. |
| `lifecycle` | 3 | 4 | |
| `expiry` | 4 | 4 | |
| `rollout` | 5 | **1** | **The gap.** Only temporal #11842. argo-cd #29476 reads as `rollout` if you emphasise the fleet, but that is one issue counted twice. |
| `concurrency` | secondary | 1 | temporal #2694, also readable as `workflow`. |
| `delivery` | secondary | 1 | k8s #110210. |
| `resource` | excluded | 0 | Not hunted, per the brief. |

**If another pass happens, spend it on `rollout`**, and spend it in `argoproj/argo-cd`,
`fluxcd/flux-controllers`, `knative/serving` and Kubernetes' `sig/apps` area (Deployment surge,
DaemonSet rolling update, revision history). I sampled Flux and Knative only at the search-listing
level and opened nothing there, so I have no evidence about them either way — that is a gap in
this survey, not a judgement on those projects.

---

## Appendix: the denominator

Every issue whose body I read at primary source. 24 rows. `y` = modelable, `y-` = modelable but
weak or out of domain, `n` = not modelable.

| # | issue | shape | verdict | reason |
|---|---|---|---|---|
| 1 | temporal #10639 | workflow | y | numbered timeline, no source |
| 2 | KAFKA-20090 | workflow | y | 4-step protocol sequence in prose |
| 3 | argo-cd #29476 | two-store | y | rule is modular arithmetic over an ordered list |
| 4 | KAFKA-16198 | two-store | y | 5-step sequence, two sets |
| 5 | nats-server #8505 | expiry | y | deterministic repro + stated semantics |
| 6 | temporal #10239 | lifecycle | y | real event log pasted, two fields must agree |
| 7 | etcd #15247 | expiry | y | 10-step repro, two role flags |
| 8 | k8s #110210 | delivery | y | invariant named in the title, 3-bullet counterexample |
| 9 | temporal #11842 | rollout | y | pure-symptom body, cause isolated in a reply |
| 10 | k8s #125410 | lifecycle | y | terminal state re-observed as a different terminal state |
| 11 | nats-server #8348 | two-store | y | metadata plane vs data plane, bulkier |
| 12 | temporal #10841 | two-store | y | liveness: pointer outlives its target, retry never terminates |
| 13 | temporal #11869 | expiry | y | logical timer vs physical timer row |
| 14 | k8s #116485 | lifecycle | y | two loops, one notices deletion |
| 15 | etcd #14758 | expiry | y | same family as #15247, stated worse |
| 16 | temporal #2694 | concurrency | y | `T = 0..4` interleaving written out |
| 17 | consul #5047 | lifecycle | y- | states a rule, never exhibits a sequence |
| 18 | KAFKA-20685 | two-store | y- | clean rule, then argues in line numbers on a tag |
| 19 | crdb #173315 | two-store | y- | invariant is already TLA+ shaped; **wrong domain** for this learner |
| 20 | argo-workflows #16450 | workflow | y- | modelable defect carried by a Go snippet |
| 21 | temporal #2140 | workflow | y- | real idempotency invariant, one-step counterexample |
| 22 | envoy #46561 | delivery | n | argument is a C++ method walk |
| 23 | argo-workflows #16638 | workflow | n | invariant is of a call site, not of the system |
| 24 | KAFKA-13357 | two-store | n | two sentences; nothing to exhibit |

Plus 24 Temporal `label:bug` closed issues read without a keyword filter, as the control arm for
§1 (5 modelable, 2 worth building: #2694 and #2140, both already in the table above).

**Scanned but never opened**, and so excluded from the denominator: ~330 search-listing titles
across etcd, Kubernetes, Temporal, NATS, Consul, Vault, CockroachDB, Envoy, Argo CD, Argo
Workflows, Flux, Cadence and the Kafka and MongoDB JIRA instances. Flux, Knative, Cadence,
Debezium, Redis, RabbitMQ, TiDB and Postgres were **not sampled at all or only at listing level** —
no claim in this document covers them.

### Tooling notes for a follow-up pass

- `gh issue view N --repo R --json number,title,state,url,body,comments` is the right primitive.
  Bodies and threads come back structured, so the cause-holding-back cut can be scripted.
- Apache JIRA is open: `curl --get https://issues.apache.org/jira/rest/api/2/search
  --data-urlencode 'jql=project=KAFKA AND text~"invariant" AND resolution=Fixed'`. Same for
  `jira.mongodb.org`. No auth needed.
- The GitHub **search** API rate-limits at 30/min and will silently hand back a 403 JSON body in
  place of a count; the core API does not. Sleep between search calls.
- In this sandbox, `curl` works when typed directly but returns an empty file when run from inside
  a shell script. `gh` works either way. Fetch with a direct `curl`, parse with a script.

---

## Verdict

**Primary source.**

Issue trackers are a better source than postmortems for this curriculum, and the reason is not
that any single issue is better. Per item opened the two families are indistinguishable — 19 of
24 here against the sibling's 22 of 27. The case rests on three things the ratio hides.

**One: the family supplies `workflow`, and postmortems did not.** The sibling survey returned
zero instances of the learner's top-ranked shape. This one returned five, two of them strong
enough to build from tonight. That is the whole argument in one line. Workflow engines exist,
they have public trackers, and their trackers are about nothing but multi-step multi-party
sequences with abort branches.

**Two: the corpus does not run out, and it is searchable by the property.** A good public
postmortem corpus is a few hundred documents and you are done. Temporal alone carries 1,649
issues and Kubernetes 49,625, and — unlike an incident narrative — an issue can be filtered for
"contains a stated rule" because the rule is in the text the author wrote to win the argument.
The 6%-of-scanned rate looks unimpressive next to the sibling's 9%, but it came from four
keywords over ~330 titles with no craft applied, against a supply that is effectively infinite.

**Three: the cut is cheaper.** 20 of 24 issues let you withhold the diagnosis by deleting a
heading or a comment, because issue conventions fence the cause off from the symptom. In a
postmortem the diagnosis is the narrative. temporal #11842 is the clean case: the body is pure
symptom, one reply is the whole answer.

Two honest qualifications. The 79% is a *targeted* number and the unfiltered base rate in the
best project is 21%, so the effort is in the searching, not the reading. And the discriminator
bites hard by project rather than by issue — Envoy and Argo Workflows write source-level
arguments and are near-useless despite having exactly the right subject matter, while MongoDB's
1,877 hits for "invariant" are a C++ assertion macro. Rank projects by whether their template
asks for expected behaviour, not by keyword density.

**What would change my mind.** Three things, in order of how likely they are to happen:

- **If the `rollout` gap does not close.** One instance out of 24 is not a supply. If a
  dedicated pass through Argo CD, Flux, Knative and `sig/apps` still returns one or two, then
  issue trackers cover four of the learner's five shapes and something else has to cover the
  fifth.
- **If the withheld-cause versions turn out too hard without it.** I judged modelability from the
  prose, not by building anything. An issue is written for someone who already knows the system;
  a postmortem is written for someone who does not. If the learner needs the diagnosis to find
  the counterexample, then the cheap cut I am celebrating is cheap because it removes something
  load-bearing, and the six candidates need a written preamble that costs as much as authoring
  from scratch.
- **If the 79% does not survive a second searcher.** I chose which titles to open, and I was
  hunting for a specific answer. A blind pass over the same search listings by someone who has
  not read this document is the check.
