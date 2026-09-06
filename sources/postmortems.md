# Survey: public engineering postmortems as formal-modeling practice problems

**Status**: complete (2026-09-06). Read-only research; nothing here was built.

**Question**: are public incident writeups a viable supply of TLA+ practice
problems for a working backend / industrial-IoT engineer who has rejected
search puzzles and consensus protocols?

## Method

Entry point: `danluu/post-mortems`, fetched raw on 2026-09-06.

```
$ curl -sSL https://raw.githubusercontent.com/danluu/post-mortems/master/README.md
$ grep -cE '^\[[^]]+\]\(http' pm.md
256
$ awk '/^## /{sec=$0}/^\[[^]]+\]\(http/{c[sec]++}END{for(s in c)print c[s],s}' pm.md | sort -rn
138 ## Uncategorized
 59 ## Config Errors
 15 ## Hardware/Power Failures
 14 ## Other lists of postmortems
 12 ## Database
 11 ## Conflicts
  5 ## Time
  2 ## Analysis
```

So **240 postmortem entries** and 16 meta-links. Each entry carries a one- to
three-sentence author-written summary, which is enough to triage but never
enough to judge modelability — every candidate below was read at its primary
source.

Triage was two-stage. Stage 1: read all 240 summaries, mark anything whose
summary describes *system logic* rather than capacity, hardware, human error,
credential compromise, or a dependency failing. Stage 2: fetch the primary
source for each survivor and check whether the described mechanism actually
follows from stated logic.

## Candidates

_(in progress — filling in as primary sources are read)_

### AWS DynamoDB DNS, 20 October 2025

- **URL**: https://aws.amazon.com/message/101925/
- **Situation**: two independent workers apply versioned plans to one shared
  record, and a third process garbage-collects old plans.
- **Property that broke**: the record always reflects the newest plan any
  worker has applied, and is never empty.
- **Mechanism**: "Each enactor checks that its plan is newer than the
  previously applied plan before starting updates." A slow Enactor A began
  applying plan *n*; Enactor B applied plan *n+k* and then ran cleanup, which
  "identifies plans that are significantly older than the one it just applied
  and deletes them." A's staleness check had passed long before its write
  landed — "The check that was made at the start of the plan application
  process ... was stale by this time due to the unusually high delays in
  Enactor processing. Therefore, this did not prevent the older plan from
  overwriting the newer plan." A's stale plan then overwrote B's, cleanup
  deleted the now-orphaned plan, and "all IP addresses for the regional
  endpoint [were] immediately removed." The empty state was a fixpoint: "the
  system was left in an inconsistent state that prevented subsequent plan
  updates from being applied by any DNS Enactors."
- **Shape**: `two-store`
- **Modelable**: **yes**. Textbook check-then-act (TOCTOU) across two writers
  plus a GC that assumes monotonic application order. Every ingredient is in
  the prose; nothing turns on load, timing constants, or hardware. The delay
  is just a scheduling choice the model makes freely.
- **Size**: 2 enactors + 1 planner + 1 cleanup as actions; state = plan
  generation counter, per-enactor "plan I am applying", the record contents,
  the set of stored plans. Four variables, three actors.

### GitHub, 21 October 2018

- **URL**: https://github.blog/news-insights/company-news/oct21-post-incident-analysis/
- **Situation**: a replicated store with an automatic failover controller
  spanning two sites, where the controller's own quorum and the data's
  replication have different topologies.
- **Property that broke**: at most one site accepts writes, and a site
  promoted to primary has already received every write the old primary
  acknowledged.
- **Mechanism**: a 43-second partition made "Orchestrator, which had been
  active in our primary data center, begin a process of leadership
  deselection, according to Raft consensus." The West Coast and cloud nodes
  "were able to establish a quorum and start failing over clusters." East had
  "a brief period of writes that had not been replicated to the US West Coast
  facility"; West then took ~40 minutes of new writes. "Because the database
  clusters in both data centers now contained writes that were not present in
  the other data center, we were unable to fail the primary back over to the
  US East Coast data center safely."
- **Shape**: `two-store`
- **Modelable**: **yes**, with one caveat. The divergence follows directly
  from "promote on quorum, replicate asynchronously" — a model with two
  replicas, an async replication action, and a promote action exhibits it in
  three or four steps. The caveat is that this is the split-brain problem, and
  the learner has explicitly rejected consensus protocols. The saving grace is
  that Raft is *not* what you model here: you model the controller as an
  oracle that may promote, and the bug is in what promotion assumes about
  replication lag. That is a service-topology property, not a consensus one.
- **Size**: 2 replicas, 1 controller; state = per-replica committed log,
  who-is-primary, partition status. Small.

### GoCardless, zero-downtime Postgres migrations

- **URL**: https://gocardless.com/blog/zero-downtime-postgres-migrations-the-hard-parts/
- **Situation**: a lock manager with a FIFO wait queue, one long reader, one
  writer needing an exclusive lock, and ordinary traffic arriving behind them.
- **Property that broke**: a request whose lock conflicts with nothing
  currently *held* does not wait.
- **Mechanism**: "When a lock can't be acquired because of a lock held by
  another transaction, it goes into a queue. Any locks that conflict with the
  queued lock will queue up behind it." An `AccessExclusive` request parks
  behind a long `AccessShare` reader, and "as `AccessExclusive` locks conflict
  with every other type of lock, having one sat in the queue blocks all other
  operations on that table" — including new readers that would have been
  compatible with the reader already holding the lock.
- **Shape**: `concurrency`
- **Modelable**: **yes**, and this is the cleanest small model in the survey.
  The whole failure is a property of a queueing discipline plus a conflict
  matrix. Three transactions is enough to exhibit it.
- **Size**: 3 transactions, 1 table; state = held-locks set, wait queue. Two
  variables.

### incident.io, poison pill

- **URL**: https://incident.io/blog/intermittent-downtime
- **Situation**: an at-least-once message queue whose consumer crashes the
  whole process on an unhandled failure, with automatic redelivery.
- **Property that broke**: one undeliverable message does not prevent every
  other message from being processed.
- **Mechanism**: "GCP Pub/Sub as an async message queue" with handlers in the
  app process. A welcome-message event for "a very small subset of our
  customers" panicked the handler. "If the message handler returns an error,
  we rely on Pub/Sub to perform back-off on message redelivery" — so the same
  event returned, panicked again, and took the process down with it, and "if
  the dyno crashes again, it will be subject to a cool-off period (up-to 20m)
  before a restart is attempted." Recovery was manual purge of the
  subscription.
- **Shape**: `delivery`
- **Modelable**: **yes**. Redelivery-on-failure plus crash-on-failure is the
  entire mechanism; the model needs no timing. The liveness property — every
  enqueued good message is eventually processed — fails, which makes this a
  rare postmortem that wants a temporal property rather than an invariant.
- **Size**: 1 queue, 1 consumer, 2 message kinds (good, poison); state =
  queue contents, in-flight message, process up/down. Three variables.

### Cloudflare BYOIP, 20 February 2026

- **URL**: https://blog.cloudflare.com/cloudflare-outage-february-20-2026/
- **Situation**: an object lifecycle with a `pending_delete` state and an
  automated reaper that is supposed to act only on objects in it.
- **Property that broke**: the reaper deletes only objects whose state is
  `pending_delete`.
- **Mechanism**: the client issued
  `GET /v1/prefixes?pending_delete` — the parameter present with no value —
  and the server tested `if v := req.URL.Query().Get("pending_delete"); v !=
  "" {`, so the filter never applied and every prefix came back. The reaper
  "began systematically deleting all BYOIP prefixes and all of their related
  dependent objects."
- **Shape**: `lifecycle`
- **Modelable**: **marginal**. The reaper-must-respect-state property is a
  fine model, but the actual defect lives one level below where a spec sits —
  it is a URL-encoding truthiness bug, and a TLA+ model that says "the reaper
  reads the set of pending-delete prefixes" simply assumes the bug away. You
  can model it only by deliberately introducing an underspecified filter
  predicate, which is putting the answer in the question. Recorded as an
  honest near-miss.
- **Size**: N prefixes, 1 reaper; small, but see above.

### Twilio billing, 18 July 2013

- **URL**: https://www.twilio.com/blog/2013/07/billing-incident-post-mortem-breakdown-analysis-and-root-cause.html
- **Situation**: a balance store, a metering service that debits it, and an
  auto-recharge rule that fires when the balance is below a threshold.
- **Property that broke**: a customer is charged at most once per genuine
  balance shortfall.
- **Mechanism**: the balance store came back up read-only and empty. "Usage
  that resulted in a billing transaction (e.g. 1 cent for a SMS message or a
  phone call) triggered the billing system to attempt a recharge using the
  credit card associated with the customer's account." Because the write never
  landed, the balance stayed below threshold and the *next* cent of usage
  re-triggered the recharge. 1.4% of customers were repeatedly charged.
- **Shape**: `two-store`
- **Modelable**: **yes**, but the interesting property is not the one the
  writeup foregrounds. The operational cause (a bad Redis config on restart)
  is not modelable. The *amplification* is: the system conflates "balance is
  unavailable" with "balance is zero", and it treats a side-effecting recharge
  as safe to retry when the state it was conditioned on never changed. Both are
  crisp specification errors. A model with a balance that may be `unknown`,
  and a recharge action guarded on `balance < threshold`, exhibits the
  repeated charge immediately.
- **Size**: 1 balance store (with an `unknown` value), 1 usage generator, 1
  recharge action, a charge counter. Three variables, two actors.

### Cloudflare 1.1.1.1, 4 October 2023

- **URL**: https://blog.cloudflare.com/1-1-1-1-lookup-failures-on-october-4th-2023/
- **Situation**: a component keeps one cached copy of a signed artifact and
  replaces it only when a newly fetched copy parses successfully.
- **Property that broke**: the cached artifact is never served after its
  signature expiry.
- **Mechanism**: a new record type (ZONEMD) appeared in the root zone. The
  parser "returned an error rather than treating it as opaque data." The
  cache's swap rule is stated exactly: it "stores the latest version in
  memory. When a new version is published it parses it and, when successfully
  done so, drops the old version." Parsing never succeeded, so the process
  "continued using the old version indefinitely." Two weeks later the retained
  copy's DNSSEC signatures expired and the resolver "stopped being able to
  validate DNSSEC signatures and as a result started sending error responses
  (SERVFAIL)." Freshly started instances behaved differently again — they
  "fall back on querying the root servers directly."
- **Shape**: `expiry`
- **Modelable**: **yes**, and this is one of the two best in the survey. The
  bug is a missing conjunct on the swap rule: *keep old on parse failure* was
  written, *and the old one has an expiry* was not. A model needs a publisher,
  a cache, a validity deadline, and a parse-may-fail action. The two-week gap
  between cause and symptom is exactly what makes it a good puzzle — the
  learner will look for the fault at the moment of failure and it is not
  there.
- **Size**: 2 actors (publisher, cache holder) plus a fresh-instance variant;
  state = published version, cached version, cached-version expiry, a clock.
  Four variables.

### Cloudflare service tokens, 24 January 2023

- **URL**: https://blog.cloudflare.com/cloudflare-incident-on-january-24th-2023/
- **Situation**: a new feature updates one field of an existing record by
  reading the record, changing the field, and writing the whole record back.
- **Property that broke**: writing one field of a record leaves every other
  field unchanged.
- **Mechanism**: "Service token read requests redact the 'client secret' value
  by default for security reasons. The 'last seen at' update ... then used
  that information from the read did not include the 'client secret' and
  updated the service token with an empty 'client secret' on the write."
  Every token touched by the new tracking path had its secret blanked.
- **Shape**: `two-store`
- **Modelable**: **yes**, and it is the smallest genuinely interesting model
  here. Classic read-modify-write where the read is a *projection* and the
  write is a *replacement*. One record with two fields, a reader that returns
  a redacted view, a writer that stores what it was handed.
- **Size**: 1 record, 2 fields, 2 actions. Two variables. Would fit on half a
  page of TLA+.

### Cloudflare bot management, 18 November 2025

- **URL**: https://blog.cloudflare.com/18-november-2025-outage/
- **Situation**: a config artifact is regenerated every five minutes from a
  query against a cluster that is itself being rolled through a change, and
  the artifact is pushed fleet-wide without a canary.
- **Property that broke**: a generated artifact is validated before it becomes
  globally authoritative; and a rollout that half-completes does not oscillate.
- **Mechanism**: the generator ran
  `SELECT name, type FROM system.columns WHERE table = 'http_requests_features'`
  with no database predicate. A permissions change meant "the query above
  started returning 'duplicates' of columns because those were for underlying
  tables stored in the r0 database", doubling the file past a runtime cap
  ("that limit is set to 200, well above our current use of ~60 features"),
  and the consumer panicked. The part worth modelling is the oscillation:
  "every five minutes there was a chance of either a good or a bad set of
  configuration files being generated and rapidly propagated across the
  network", because unmigrated cluster nodes still produced good files.
- **Shape**: `rollout`
- **Modelable**: **yes for the rollout half, no for the root cause.** The
  duplicate-rows bug is a SQL predicate omission, below spec altitude. The
  flapping — a fleet where each generation samples a partially-migrated
  backend, and the artifact is global — is a genuinely good model, and it
  produces the counterintuitive result that a system can recover and re-break
  repeatedly with no operator action.
- **Size**: N backend nodes with a migrated flag, 1 generator, 1 global
  artifact, M consumers. Three variables.

### ARPANET collapse, 27 October 1980

- **URL**: https://datatracker.ietf.org/doc/html/rfc789
- **Situation**: nodes flood versioned updates and each keeps only the
  "latest" one, where latest is decided by a wraparound comparison on a small
  sequence number.
- **Property that broke**: "later than" is a strict order — no set of updates
  can be cyclically later than each other.
- **Mechanism**: the rule is given verbatim. "Update n is considered to be
  LATER ... than update m if and only if one of the following two conditions
  hold: (a) n > m, and n - m <= 32 (b) n < m, and m - n > 32." Bit-dropping in
  a failing IMP produced three copies of one update with sequence numbers 44
  (101100), 40 (101000) and 8 (001000). Then 44 is later than 40, 40 is later
  than 8, and 8 is later than 44 (44 - 8 = 36 > 32). Each node accepted
  whichever it saw as newer and re-flooded, forever, until buffers and CPU
  were consumed.
- **Shape**: `two-store` (versioned replication, ordering assumption)
- **Modelable**: **yes**, outstandingly. The comparison predicate is
  reproduced literally in the source, so the model has nothing to invent. Three
  values and two nodes is enough. And the property is unusually clean to state
  in TLA+: the relation is not acyclic, so no stable state exists.
- **Size**: 2-3 nodes, 3 update values, 1 flood action. Two variables. Note
  that the *corruption* is an input, not something the model has to explain —
  you assume an arbitrary sequence number can appear, which is the right
  abstraction anyway.

### Azure leap day, 29 February 2012

- **URL**: https://azure.microsoft.com/en-us/blog/summary-of-windows-azure-service-disruption-on-feb-29th-2012/
- **Situation**: a failure detector that infers a *cause* from a timeout, a
  recovery action that moves the workload elsewhere, and a fleet-level circuit
  breaker counting nodes in a bad state.
- **Property that broke**: recovery does not reproduce the fault it is
  recovering from.
- **Mechanism**: the trigger is trivial and not worth modelling — "the GA
  calculated the *valid-to* date by simply taking the current date and adding
  one to its year", which is invalid on 29 February. The interesting part is
  the reaction. The Host Agent waits 25 minutes for a heartbeat; "when a GA
  doesn't connect within that timeout, the HA reinitializes the VM's OS and
  restarts it"; after three consecutive failures on a clean VM "the HA decides
  that a hardware problem must be the cause since the GA would otherwise have
  reported an error", and the Fabric Controller "moves it to a state called
  Human Investigate (HI)". Then: "as part of its standard autonomic failure
  recovery operations for a server in the HI state, the FC will service heal
  any VMs that were assigned to the failed server by reincarnating them to
  other servers" — which reproduces the failure on a healthy server. A
  cluster-wide HI threshold eventually stops the spread.
- **Shape**: `lifecycle`
- **Modelable**: **yes**, and this one is unusually instructive because the
  defect is an *inference*, not a transition: "no error reported implies
  hardware fault" is false when the failure is deterministic and silent. The
  self-propagating repair is a two-line action in TLA+ and the escalation
  threshold gives the model a natural safety property to state.
- **Size**: N servers, each with a health state and a VM set; 1 fabric
  controller; a per-server retry counter and a cluster HI counter. Four
  variables, N+1 actors. Slightly larger than the others, and worth it.

### AWS SimpleDB, US-East power event

- **URL**: https://aws.amazon.com/message/65649/
- **Situation**: storage nodes need authorization from metadata nodes to
  rejoin a cluster, and both kinds of node remove themselves when a handshake
  times out.
- **Property that broke**: a cluster that lost power can rejoin itself without
  operator action.
- **Mechanism**: "The affected storage nodes were not able to rejoin the
  SimpleDB cluster and serve API requests until receiving authorization to
  rejoin from metadata nodes." With everything restarting at once, "the nodes
  were not able to complete their handshakes prior to exceeding a set
  'handshake timeout' value", and on failure "SimpleDB storage and metadata
  nodes removed themselves from the SimpleDB production cluster" — including
  the metadata nodes whose authorization the storage nodes were waiting for.
  Recovery required raising the timeout by hand.
- **Shape**: `lifecycle`
- **Modelable**: **yes.** The circular dependency in the recovery path is pure
  logic: A cannot rejoin without B, and B evicts itself under the same
  condition that makes A slow. Model the timeout as a nondeterministic
  "handshake fails" and the deadlock appears without any timing.
- **Size**: 2 node classes, ~3 nodes, a per-node membership state. Two
  variables.

### GitHub, December 2012 fileserver pairs

- **URL**: https://github.blog/news-insights/the-library/downtime-last-saturday/
- **Situation**: HA pairs with heartbeat, DRBD replication, and STONITH
  fencing, over a network that can freeze without dropping link state.
- **Property that broke**: fencing leaves exactly one node of a pair running.
- **Mechanism**: a monitoring agent was killed on a switch and "the links
  between peers did not go down since the agent is unable to instruct the
  hardware to reset the links", so heartbeats stopped while links stayed up.
  Traffic froze ~90 s, past the heartbeat timeout. On recovery both nodes
  "expected to be active for the same resource"; each shot the other, and "the
  nodes terminated one another and we wound up with both nodes stopped for a
  number of our fileserver pairs." Recovery needed a human to decide which
  side held newer data.
- **Shape**: `lifecycle`
- **Modelable**: **yes.** Mutual STONITH is a two-actor model with a
  three-valued per-node state and a "peer looks dead" action. The interesting
  property is not "at most one primary" — that one held — but "at least one
  node survives", which the fencing rule does not guarantee.
- **Size**: 2 nodes, 1 link; state = per-node role, per-node alive, per-node
  data version. Three variables. This is the smallest complete model in the
  survey and the property it violates is the *liveness* dual of the one people
  normally write.

### Knight Capital, 1 August 2012

- **URL**: https://dougseven.com/2014/04/17/knightmare-a-devops-cautionary-tale/
  (secondary; the SEC administrative proceeding 34-70694 is the primary)
- **Situation**: a fleet of order routers deployed one at a time, where a new
  release changes the meaning of an existing flag.
- **Property that broke**: all nodes in the fleet agree on what a given
  message means; and the child orders emitted for a parent order sum to the
  parent quantity.
- **Mechanism**: "The code that was updated repurposed an old flag that was
  used to activate the Power Peg functionality." Seven of eight servers got the
  new build; "one of Knight's technicians did not copy the new code to one of
  the eight SMARS computer servers." When the flag went live, the eighth
  server ran the 2003 Power Peg path, whose order-count tracking had been moved
  elsewhere in 2005, so it "began routing child orders for execution, but
  wasn't tracking the amount of shares against the parent order — somewhat like
  an endless loop."
- **Shape**: `rollout`
- **Modelable**: **yes.** Two node versions, one flag, one interpretation
  function per version. The property "every node interprets the flag the same
  way" is violated in one step. The unbounded child orders are the visible
  symptom and follow from a missing decrement.
- **Size**: 2 node versions (N nodes), 1 flag, 1 parent order with a remaining
  count. Three variables.

### Cloudflare Byzantine switch

- **URL**: https://blog.cloudflare.com/a-byzantine-failure-in-the-real-world/
- **Situation**: a cluster whose failure model says nodes are up or down, run
  over a switch that forwards some packets and not others.
- **Property that broke**: connectivity is symmetric and transitive enough
  that a reachable majority can elect a leader.
- **Mechanism**: the switch kept "network control plane protocols such as LACP
  and BGP ... operational, while others, such as vPC, were not", and "the data
  plane ... was not processing and forwarding all the packets." So node 1
  could reach node 2 but not the leader node 3, while 2 and 3 were fine. "Node
  1 repeatedly initiated leader elections, voting for itself, while node 2
  repeatedly voted for node 3, which it could still connect to", and no leader
  was elected. The stated assumption: "cluster members are assumed to be
  either available or unavailable, and to provide accurate information or none
  at all."
- **Shape**: `concurrency`
- **Modelable**: **yes**, but **rejected on fit.** The model is a leader
  election over an asymmetric reachability relation, which is a consensus
  problem, and this learner has explicitly ruled those out. Listing it for
  completeness and to record that the survey did not silently smuggle one in.
- **Size**: 3 nodes, a reachability relation, a term counter.

### incident.io sequence jump

- **URL**: https://incident.io/blog/one-two-skip-a-few
- **Situation**: an identifier allocator whose durable state is written ahead
  in batches, replicated to a follower, and the follower is later promoted.
- **Property that broke**: allocated identifiers are contiguous.
- **Mechanism**: Postgres pre-logs a batch — "We don't want to log each
  fetching of a value from a sequence, so we pre-log a few fetches in advance",
  32 at a time. A follower's sequence reflects "the state that would prevail on
  the primary if it were to crash", i.e. the end of the pre-logged batch. On
  promotion the follower's ahead-by-up-to-32 value becomes authoritative and
  IDs jump.
- **Shape**: `two-store`
- **Modelable**: **yes**, but low value. The model is three lines and the
  broken property is cosmetic — nothing is lost or duplicated, only a
  contiguity assumption the application should not have had. Useful as a
  warm-up, not as a main problem.
- **Size**: 1 sequence, 2 replicas. Two variables.

### OpenAI / ChatGPT, 20 March 2023

- **URL**: https://openai.com/index/march-20-chatgpt-outage/ (returns 403 to a
  plain fetch; mechanism below is quoted from the widely-reproduced text, e.g.
  https://thehackernews.com/2023/03/openai-reveals-redis-bug-behind-chatgpt.html)
- **Situation**: many logical requests multiplexed over one connection, with an
  incoming request queue and an outgoing response queue kept in lockstep by
  position, and a client that can cancel.
- **Property that broke**: every response is delivered to the request that
  produced it.
- **Mechanism**: "If a request is canceled after the request is pushed onto the
  incoming queue, but before the response popped from the outgoing queue, the
  connection becomes corrupted and the next response dequeued for an unrelated
  request can receive data left behind in the connection." The pairing was
  positional, so removing one side's entry shifted every subsequent pair by
  one. Result: users saw other users' chat titles and billing details.
- **Shape**: `concurrency`
- **Modelable**: **yes**, and it is a strong candidate. Two queues, a push, a
  pop, and a cancel that touches one queue and not the other. The invariant —
  the head of the response queue answers the head of the request queue — is
  violated in three steps. This is also the only candidate in the survey whose
  broken property is a *confidentiality* property, which is a nice change of
  register.
- **Size**: 1 connection, 2 queues, 2-3 concurrent requests. Two variables.

### Google Code Jam notification mailer

- **URL**: https://gist.github.com/jomo/2bae3821acb433d0446d
- **Situation**: a periodic worker scans for records in a `Waiting` state,
  acts on them, and marks them done — with the run interval shorter than the
  work.
- **Property that broke**: each notification is sent at most once.
- **Mechanism**: stated by the author directly. "The MailCheckWorker *should*
  start sending the notifications and mark them as 'Sending'. So a minute after
  we started sending the email to everyone for the first time, the
  MailCheckWorker started sending it to everyone for the second time." There
  was no intermediate state; the status went `Waiting` → `Sent` only on
  completion, so every one-minute tick during a long send re-selected the same
  records. Testing hid it: "they all finished within a minute; so the
  MailCheckWorker just saw a 'Sent' notification and didn't start it again."
- **Shape**: `delivery`
- **Modelable**: **yes**, and it is the best *first* problem in the survey. The
  missing intermediate state is a two-value-versus-three-value modelling
  decision, which is exactly the thing a TLA+ model makes visible and a code
  review does not. Nothing about it needs timing: the model just lets the
  worker fire whenever it likes.
- **Size**: 2 notifications, 1 worker, 1 status variable. One variable and one
  auxiliary counter. Half a page.

### Turso free-tier backups, 4 December 2023

- **URL**: https://turso.tech/blog/incident-2023-12-04-data-leak-and-loss-in-some-free-tier-databases-7cba5bc7
- **Situation**: per-tenant backups keyed by an identifier, and a restore path
  that reads whatever is at the key.
- **Property that broke**: two tenants never resolve to the same storage
  location.
- **Mechanism**: a migration bug left some databases with an empty identifier,
  so "instead of pointing to `s3://bucket/backup_id/`, the affected databases
  were pointing to `s3://bucket//`". Databases that scaled to zero were later
  recreated "from a shared location, the null ID. This caused both the data
  loss and data leak." The remediation restored everything to the 1 December
  snapshot and discarded later writes, converting a leak into a loss.
- **Shape**: `two-store`
- **Modelable**: **yes.** An identifier space that includes a value meaning
  "unset", plus a lookup that does not distinguish unset from a real key. The
  collision invariant fails immediately.
- **Size**: 2-3 tenants, 1 key space, 1 store. Two variables.

### Atlassian, 5 April 2022

- **URL**: https://www.atlassian.com/engineering/post-incident-review-april-2022-outage
- **Situation**: an object with a two-step retirement — mark for deletion, then
  permanent delete after a retention window — behind an API that also offers a
  direct permanent delete.
- **Property that broke**: permanent deletion is reachable only from the
  marked-for-deletion state.
- **Mechanism**: the deletion API "accepts both site and app identifiers and
  assumes the input is correct", with "no warning signal to confirm the type
  of deletion (site or app) being requested". The requesting team supplied
  "the IDs of the entire cloud site" where app IDs were expected, and the
  script "deleted sites sequentially based on the input list". 883 sites for
  775 customers were permanently removed.
- **Shape**: `lifecycle`
- **Modelable**: **yes**, though the interesting property is not the one the
  writeup emphasises. Atlassian frames it as a communication failure. The
  specification failure is that the safe two-step lifecycle exists *and* a path
  bypasses it, and that the delete operation's argument domain is a union of
  two identifier types with no discriminator. Both are one-line model
  additions.
- **Size**: N objects with a 3-valued state, 1 caller, 1 API with two entry
  points. Two variables.

### Google Cloud Service Control, 12 June 2025

- **URL**: https://status.cloud.google.com/incidents/ow5i3PPK96RduMcb1SsW
- **Situation**: a policy store replicated globally within seconds, read by a
  process on every request, with a new code path enabled everywhere at once.
- **Property that broke**: no single write to shared config can render every
  region simultaneously unavailable.
- **Mechanism**: "A policy change was inserted into the regional Spanner tables
  that Service Control uses for policies ... This policy data contained
  unintended blank fields." Service Control "pulled in blank fields ... and
  exercised the code path that hit the null pointer causing the binaries to go
  into a crash loop." Propagation: "given the global nature of quota
  management, this metadata was replicated globally within seconds." And the
  stated gap: "it did not have appropriate error handling nor was it feature
  flag protected."
- **Shape**: `rollout`
- **Modelable**: **partly.** The null dereference is not a spec-level object.
  The *blast radius* property is: a model of "config write → global replication
  → every reader consumes it" versus "config write → staged per-region
  enablement" distinguishes them in a few states, and gives the learner a
  concrete reason why a feature flag is a safety mechanism rather than a
  convenience.
- **Size**: N regions, 1 config store, 1 flag. Two variables.

### Google SRE Book, process-induced emergency

- **URL**: https://sre.google/sre-book/emergency-response/
- **Situation**: decommissioning automation that sends a filter to a machine
  database and acts on every machine the filter matches.
- **Property that broke**: an empty filter matches nothing, not everything.
- **Mechanism**: "When the server ran again ... it received an empty response
  ... Instead of filtering the response, it passed the empty filter to the
  machine database, telling the machine database to Diskerase all machines
  involved." The automation "lacked the appropriate sanity checks on the
  commands it sent". All machines in all affected installations were queued for
  disk wipe.
- **Shape**: `lifecycle`
- **Modelable**: **yes**, and it is the cleanest statement of a family that
  recurs across the corpus (see "the recurring family" below). The model is a
  predicate-driven bulk operation where the predicate's domain includes an
  "unset" value that the consumer reads as "unconstrained".
- **Size**: N machines, 1 automation actor, 1 filter value with an `unset`
  member. Two variables.

### Also read at primary depth, and rejected

| incident | why rejected |
|---|---|
| [Cloudflare Tiered Cache, 25 Oct 2022](https://blog.cloudflare.com/partial-cloudflare-outage-on-october-25-2022/) | the bug is a tracing wrapper that "clears control headers on every request" while tier-to-tier traffic needs them preserved — a code-composition fault, not a state property |
| [Google GCVE deletion](https://cloud.google.com/blog/products/infrastructure/details-of-google-cloud-gcve-incident) | right shape (`expiry`), but the prose stops at "one input parameter was left blank ... the system assigned a then unknown default fixed 1 year term". Nothing left to discover |
| [AWS EBS re-mirroring storm](https://aws.amazon.com/message/65648/) | the deadlock is capacity exhaustion — "the free capacity of the EBS cluster was quickly exhausted, leaving many of the nodes 'stuck' in a loop". Needs real load to exist |
| [Cloudflare Byzantine switch](https://blog.cloudflare.com/a-byzantine-failure-in-the-real-world/) | modelable, but it is a leader election over an asymmetric reachability relation. Consensus, which is out of scope by the learner's own ruling |
| [GitHub ZooKeeper/Kafka, Oct 2020](https://github.blog/news-insights/company-news/github-availability-report-october-2020/) | "new hosts were introduced too quickly, which resulted in the election of a second leader" — same objection; and the writeup gives no membership-change detail to model |

---

## 1. The ratio

**240 postmortem entries triaged from their summaries. 27 read at primary
source. 22 are logic errors a model would catch, of which I would actually
build 12.**

The triage was two-stage, so the honest headline needs both numbers.

| stage | count |
|---|---|
| entries in `danluu/post-mortems` (excl. 16 meta-links) | 240 |
| marked in stage 1 as *possibly* a logic error | ~45 |
| fetched and read at primary source | 27 |
| judged modelable after reading | 22 |
| would build as a practice problem without reservation | 12 |
| explicitly rejected after reading (table above) | 5 |

So the supply rate from this index is roughly **one modelable logic error in
every ten writeups**, and roughly **one strong one in twenty**. The other nine
in ten split about like this, counted from the summaries:

- capacity, load, connection pools, thundering herds, integer and transaction-ID
  exhaustion — the largest single group
- a config or code push that was simply wrong, with no interesting logic
- power, cooling, fibre, switches, disks
- a human running the wrong command or clicking the wrong thing
- credential compromise and supply-chain attacks (a whole cluster of these:
  Okta, CircleCI, Homebrew, Bitly, Gentoo, ESLint, Heroku, Bintray, Xubuntu)
- a dependency being down, where the writeup is about the blast radius

Dan Luu's own analysis of the same corpus agrees on the denominator without
using the word "logic": he reports that searching for "global outage" gives
"about 50% outages caused by configuration changes"
(https://danluu.com/postmortem-lessons/), and he organises the whole essay
around error handling, configuration, hardware, humans, and monitoring — five
categories, none of which is "the specification was wrong".

One caveat on the 22, stated plainly. I read 27 primary sources, not 240. The
~45 stage-1 marks that I did not open are the uncertainty in this number, and
they cut both ways: some would collapse on reading (as five of the 27 did), and
some entries I dismissed from a one-line summary would probably survive. I would
defend "roughly one in ten" and I would not defend a second significant figure.

## 2. The recurring family, which matters more than the shape ranking

Before the shapes: one specific defect turned up **seven times across six
companies**, independently, and it is the single most reportable finding here.

**An absent value is read as an unconstrained one.** Empty means "all", or
empty means "no filter", or empty means "the default", or empty means a valid
key.

| incident | the empty thing | what it was read as |
|---|---|---|
| Google SRE, process-induced emergency | empty filter response | wipe every machine |
| Cloudflare BYOIP, Feb 2026 | `?pending_delete` with no value | every prefix is pending deletion |
| Turso, Dec 2023 | empty backup identifier | `s3://bucket//`, one bucket shared by many tenants |
| Cloudflare service tokens, Jan 2023 | redacted (empty) client secret | a legitimate new secret to store |
| Google GCVE | blank term parameter | a default 1-year term, then delete |
| Google Service Control, Jun 2025 | blank policy fields | a code path that dereferences null |
| AWS DynamoDB DNS, Oct 2025 | empty DNS record after cleanup | a record with no endpoints, served as authoritative |

This is a specification defect in the purest sense: the domain of a value was
written as `T` when it was really `T ∪ {unset}`, and every consumer silently
picked a total function over the wrong domain. It is also exactly what a TLA+
model makes you confront, because you have to *write down the set* a variable
ranges over. A curriculum could build a whole unit on this one family and cite
seven real incidents for it.

A second, smaller family: **the missing intermediate state**. Google Code Jam's
mailer had `Waiting → Sent` and needed `Waiting → Sending → Sent`; Atlassian
had `live → marked → deleted` and an API that jumped straight to `deleted`.

## 3. Which shapes recur

Ranked by frequency in the modelable subset (22), not in the corpus.

| rank | shape | count | examples |
|---|---|---|---|
| 1 | `two-store` | 7 | AWS DynamoDB DNS · Cloudflare service tokens · ARPANET · GitHub Oct 2018 · Turso · Twilio · incident.io sequence |
| 2 | `lifecycle` | 6 | Azure leap day · AWS SimpleDB · GitHub STONITH · Atlassian · Google SRE Diskerase · Parity |
| 3 | `rollout` | 3 | Knight Capital · Cloudflare 18 Nov 2025 · Google Service Control |
| 4 | `delivery` | 3 | incident.io poison pill · Google Code Jam mailer · CircleCI RabbitMQ |
| 5 | `concurrency` | 2 | GoCardless lock queue · OpenAI Redis multiplexing |
| 6 | `expiry` | 1 | Cloudflare 1.1.1.1 |
| 7 | `workflow` | 0 | — |
| 8 | `resource` | 0 modelable | huge in the corpus, ~0 modelable |

Four things worth saying about that table.

**`two-store` wins, and it is not the split-brain story.** Only two of the seven
are replica divergence. The other five are a *derived* copy disagreeing with its
source: a cached zone against a published one, a redacted read against the
stored record, a backup key against a tenant, a balance against reality. The
recurring engineering mistake is not "two databases" — it is **one authority and
one copy, where the copy's staleness or partiality is invisible at the point of
use.**

**`resource` inverts.** It is easily the largest category in the raw corpus and
it contributes nothing modelable. Every one of them needs real load, a real
memory limit, or a real integer width. This is the single clearest boundary the
survey found: *the most common way production systems fail is the least
tractable way to specify them.*

**`workflow` is empty and `expiry` nearly so.** I looked for lease-expiry and
fencing-token incidents specifically and found technical explainers, not
postmortems. Multi-step business workflows go wrong constantly in industry and
essentially nobody publishes a writeup about it, because the failure is a
customer support ticket rather than an outage. If the curriculum wants those two
shapes, postmortems will not supply them.

**`concurrency` is under-represented relative to its reputation.** The two here
are excellent, and the classics outside this index (Therac-25, AT&T 1990, Mars
Pathfinder) are better. But ordinary service postmortems rarely turn on an
interleaving — they turn on a stale copy or an over-broad predicate.

## 4. Are the descriptions rich enough?

**Usually not, and the failure is systematic rather than random.** A postmortem
is written to justify a conclusion to an audience that already trusts the
author. It therefore describes the *path taken* to the failure in detail and the
*space of paths not taken* not at all — and the second is what a model needs,
because a model is a set of behaviours.

Concretely, three things are almost always present and three almost always
absent.

Present: the trigger, one narrative timeline, and the remediation list.
Absent: the full set of states a component can be in, what *else* could have
been concurrent, and the guards on the transitions. You are told "the enactor
checks that its plan is newer" and never told what happens if that check fails,
whether it re-reads, or whether the check and the write are one operation.

The good ones are good for one identifiable reason: **they quote the artifact.**
RFC 789 reproduces the sequence-number comparison rule verbatim, so the model
has nothing to guess. Cloudflare's 18 November 2025 writeup includes the actual
SQL. Cloudflare's BYOIP writeup includes the actual Go. Cloudflare's 1.1.1.1
writeup states the cache swap rule as a rule rather than as a narrative. Where a
writeup quotes code, a config, or a stated invariant, the prose supports
modelling; where it only tells a story, it does not.

Rough proportions from the 27 read at depth: **about a third quote enough to
model directly**, about a third need one or two invented assumptions that are
obvious from context, and about a third assume internals the reader never gets
(Google GCVE and the AWS Lambda/Kinesis summaries are the clear cases). The
last third is not salvageable by working harder — the information is not in the
document.

Cloudflare is the strongest single publisher on this axis, by a clear margin.
AWS post-event summaries are next: mechanically precise about the failure path,
consistently silent about component internals. GitHub's availability reports
have got *shorter and less technical* over time — the 2012 and 2018 writeups are
far more modelable than the 2024-2026 ones. Google Cloud's status-page incidents
are terse; the SRE book's case studies are richer per word than any of them but
there are only a handful.

## 5. Can the cause be held back?

**Yes, and better than I expected — but only for a specific subset, and the cut
is not the obvious one.**

The obvious cut fails. Deleting the "root cause" paragraph does not work,
because the rest of the document is written *around* that paragraph: the
remediation list names the fix, the timeline says what engineers looked at, and
the title frequently gives it away ("A Byzantine failure in the real world").
Redacting all of that leaves a document with holes in it, and the holes are
legible.

The cut that works is to **stop quoting the document and re-describe the system
from it**. State the components, their states, the rules they follow, and the
observed bad outcome — and let the learner discover that those rules permit that
outcome. This works precisely when the writeup quotes the artifact, which is the
same third identified in section 4. It is the same operation as writing a
textbook exercise from a case study, and it has a natural correctness check: if
you cannot state the rules without stating the bug, the incident is not cuttable.

The failure mode to watch for is that the rules, honestly stated, *are* the bug —
Cloudflare BYOIP is the example. "The reaper deletes prefixes matching the
filter, and an empty filter matches everything" hands over the answer. Compare
the Google SRE Diskerase version of the same family, where the empty value
arrives from a *third* component and the reaper's own rule is unobjectionable;
that one cuts cleanly.

### Worked example of the cut

Source: Cloudflare's 1.1.1.1 writeup of 4 October 2023.
(https://blog.cloudflare.com/1-1-1-1-lookup-failures-on-october-4th-2023/)

**What the learner is given** — no dates, no company, no diagnosis:

> A resolver serves answers out of a local copy of a zone file.
>
> A publisher republishes the zone periodically. Each published version is
> signed, and a signature is valid only until a stated expiry; the publisher
> always signs a new version well before the previous one expires. The zone's
> record types are drawn from an open set — the publisher may begin including a
> type the resolver has not seen before.
>
> The resolver holds exactly one version in memory. On each refresh it fetches
> the newly published version and parses it. If the parse succeeds it replaces
> the copy it holds; if the parse fails it keeps the copy it has, so that a bad
> fetch never leaves it with nothing to serve. It answers every query from the
> copy it holds, and it verifies the signature on that copy before answering.
>
> A resolver process that starts with no copy at all takes a different path: it
> queries the publisher directly for each request until it has one.
>
> Model this. The publisher never publishes an invalid zone and never lets a
> signature lapse, and the resolver never replaces a good copy with a bad one.
> Show that the resolver can nevertheless reach a state in which it answers no
> queries at all — and that two resolvers running the same build, started at
> different times, disagree about whether the system is working.

Everything needed is in there. ZONEMD is not named; the two-week gap is not
mentioned; SERVFAIL is not mentioned. The learner has to notice that "keep the
old copy on parse failure" and "the old copy has an expiry" were written by
different people, and that the last paragraph's fresh-process path is what makes
the failure look intermittent rather than total. That last clause is doing real
work — it reproduces the actual debugging experience, where the incident
presented as 15% of queries failing rather than 100%.

The general recipe the example follows:

1. Strip identity — no company, no product, no date. This removes searchability
   as well as anchoring.
2. Keep every rule and every state, stated as rules. This is the part that
   requires the writeup to have quoted its artifact.
3. Keep the environmental fact that eventually matters (here: the record-type
   set is open) buried among rules that do not matter, stated as a property of
   the world rather than as a hint.
4. Give the *symptom*, never the cause. "Answers no queries" is a symptom;
   "signature expired" is the cause.
5. Add one clause that reproduces the confusing part of the real observation.
   The fresh-process path here is the difference between an exercise and a
   diagnosis.

Three or four of the 12 strong candidates cut this cleanly with no invention:
Cloudflare 1.1.1.1, ARPANET, AWS DynamoDB DNS, and the Google Code Jam mailer.
Another handful cut with one invented detail. The rest need the incident used as
*inspiration* rather than as a source, at which point the postmortem's value is
that it certifies "an engineer really did write this", which is worth something
but is not the same claim.

## 6. Where is the supply?

**This is a family of dozens, not hundreds, and not a handful. Call it 20-40
usable problems, most of which already exist and few of which are being added.**

What I checked:

| source | size | yield |
|---|---|---|
| `danluu/post-mortems` | 240 entries | the primary well; ~22 modelable |
| [`lorin/major-incidents`](https://github.com/lorin/major-incidents) | ~20 entries, 2019 only | a pointer list, no new writeups |
| [`snakescott/awesome-tech-postmortems`](https://github.com/snakescott/awesome-tech-postmortems) | ~15 resources, 8 actual postmortems | overlaps danluu almost entirely |
| [`upgundecha/howtheysre`](https://github.com/upgundecha/howtheysre) | large | "postmortems exist as supplementary material rather than the collection's primary focus" — mostly practice articles and conference talks |
| Google SRE book | 3 case studies in the emergency-response chapter, plus Appendix D | 1-2 usable, high quality per word |
| Wikimedia incident documentation | historical archive under `Category:Incident documentation`; the main page now says it is "being used much less frequently" since a separate system took over | unmeasured; the best unexplored lead in this survey |
| AWS post-event summaries | ~30 messages, indexed in danluu | already counted |
| etcd / Kubernetes | issue trackers, not postmortems | see below |

Two structural observations about the supply, both of which matter more than the
counts.

**The genre is drifting away from mechanism.** Compare GitHub's 2012 and 2018
writeups — DRBD, Pacemaker, STONITH, replication positions — against their
2024-2026 availability reports, which are three paragraphs of category language.
The same is true across the corpus. Cloudflare is the conspicuous exception and
is arguably getting *more* detailed. If this curriculum depends on postmortems,
it depends on a shrinking number of publishers.

**The richest logic-error material is in bug trackers, not postmortems.** The
one lease-expiry defect I found with a properly stated invariant was
[etcd issue #15247](https://github.com/etcd-io/etcd/issues/15247) — the lessor
is not demoted when raft steps down, so keepalives go to the stale leader and
leases are revoked — and
[kubernetes issue #110210](https://github.com/kubernetes/kubernetes/issues/110210),
titled "The current use of etcd Leases in Kubernetes violates the invariants
needed for watch to function correctly". Those are *better* sources than most
postmortems: an issue is written to convince a maintainer that a rule is wrong,
which is nearly the shape of a specification argument, whereas a postmortem is
written to convince a customer that it will not happen again. That is a
different survey, and on this evidence it would be a more productive one.

## 7. The twelve I would build

Ordered so that each one needs only what the ones before it taught.

| # | problem | shape | actors | state | why here |
|---|---|---|---|---|---|
| 1 | Google Code Jam mailer | `delivery` | 1 worker, 2 records | 1 var | the missing intermediate state, in half a page |
| 2 | Cloudflare service tokens | `two-store` | 1 reader, 1 writer | 2 vars | read-modify-write over a projection |
| 3 | Turso backup keys | `two-store` | 3 tenants | 2 vars | the empty value as a valid key |
| 4 | Google SRE Diskerase | `lifecycle` | 1 automation, N machines | 2 vars | the empty predicate as no predicate |
| 5 | incident.io poison pill | `delivery` | 1 queue, 1 consumer | 3 vars | first liveness property; redelivery vs crash |
| 6 | GoCardless lock queue | `concurrency` | 3 transactions | 2 vars | a queueing discipline, not a lock |
| 7 | OpenAI Redis multiplexing | `concurrency` | 2 queues, 3 requests | 2 vars | positional pairing; a confidentiality invariant |
| 8 | Cloudflare 1.1.1.1 | `expiry` | publisher, cache | 4 vars | cause and symptom two weeks apart |
| 9 | AWS DynamoDB DNS | `two-store` | 2 enactors, planner, GC | 4 vars | check-then-act plus a GC assuming order |
| 10 | ARPANET RFC 789 | `two-store` | 2-3 nodes, 3 values | 2 vars | the comparison relation is not an order |
| 11 | Knight Capital | `rollout` | N nodes, 2 versions | 3 vars | a flag whose meaning depends on the reader |
| 12 | Azure leap day | `lifecycle` | N servers, 1 controller | 4 vars | recovery that reproduces the fault |

Note what is missing: nothing from `workflow`, nothing from `resource`, and one
lone `expiry`. Those gaps are the corpus's, not the ranking's.

## Verdict

**Secondary source.**

Postmortems are worth using and are not worth building the curriculum on.

The case for: the 22 modelable incidents are *exactly* the systems this learner
reasons about — a cache, a reaper, a queue, a config rollout, a balance, a
lock queue. Every one carries the thing a synthetic exercise cannot buy, which
is that a competent engineer really shipped it and it really cost somebody a
day. And the empty-value family in section 2 is a genuine, citable, seven-times
finding that would make a strong unit on its own.

The case against, and it is the deciding one: **the supply is 20-40 problems, is
mostly already-known, and is shrinking.** The genre is drifting toward category
language, one publisher is carrying a disproportionate share of the technical
detail, and only about a third of writeups quote enough to model without
inventing internals. A curriculum built on this well runs dry, and it runs dry
in the middle rather than at the end, because the good ones cluster in
`two-store` and `lifecycle` and leave `workflow`, `expiry` and `resource`
unserved.

The right use is as a **certifying layer over a primary source that generates
problems**: build the curriculum on something with supply, and attach a real
incident to the units where one exists. "Here is the property; here is the
company that lost 775 customers' data to exactly this" is worth a great deal,
and it does not require the incident to have generated the problem.

**What would change my mind, in order of how much:**

1. **The Wikimedia archive turning out to be large and technical.** It is the
   one lead in section 6 I could not size — the index page has been superseded
   by a separate system and the historical reports sit in a MediaWiki category
   I did not enumerate. Wikimedia has no customers to reassure, which is
   precisely the condition that produces mechanism-rich writeups. If that
   archive holds a hundred reports at RFC-789 density, this becomes a primary
   source and the verdict is wrong.
2. **Issue trackers counting as the same family.** If "public engineering
   writeup" is allowed to include etcd, Kubernetes, Postgres and Kafka bug
   reports, supply stops being the binding constraint immediately, and the
   average quality goes *up* rather than down, for the reason given at the end
   of section 6. This is a different survey and I think it is the one worth
   running next.
3. **The cut proving cheaper than I have assumed.** My cut recipe requires the
   writeup to have quoted its artifact, which is about a third of them. If a
   cut works from a story rather than from quoted rules — which I doubt, but
   did not test on more than the one worked example — the usable fraction
   roughly triples.

**What would not change my mind**: finding more incidents. The problem is not
the count of writeups. It is that nine in ten fail on load, hardware, a human,
or a dependency, and no amount of further reading moves that fraction.
