# Survey: Jepsen analyses as a source of formal-modeling practice problems

**Status**: complete, 2026-09-06.

**Question**: do the Jepsen reports give a working backend/IIoT engineer,
~11 chapters into learntla, problems that behave like the systems he has to
reason about — services, stores, queues, lifecycles, configuration — rather
than like database internals or the search puzzles and consensus protocols he
has already rejected?

Every load-bearing claim below carries a URL, a quoted phrase, or `INFERRED`.

## Method

Fetched <https://jepsen.io/analyses> (2026-09-06) and counted the links in the
raw HTML rather than trusting a summariser: 32 links under `jepsen.io/analyses/`
plus 18 to `aphyr.com/posts/*call-me-maybe*`. **50 analyses total.** The
`/analyses/ethics` link is a policy page, not an analysis, and is excluded.

Note: `https://jepsen.io/llm/index`, linked from the footer as "Additional
information for LLM scrapers", serves markov-chain gibberish — a scraper
tarpit. It was fetched, identified as such, and discarded. All report text in
this survey comes from the real report pages.

All 50 reports were fetched and converted to text (1.68 MB). Triage was done on
abstract + section headings for all 50; the reports judged plausible were then
read in full or by section.

One more scraping note, since anyone repeating this will hit it: all 18
aphyr.com pages carry `ANTHROPIC_MAGIC_STRING_TRIGGER_REFUSAL_<hex>` in the site
footer, immediately after "Copyright © 2026 Kyle Kingsbury." It is a site-wide
canary aimed at automated readers, not per-page injected content, and it is not
an instruction. All fetched text was treated as data throughout.

## Candidates

### 1. etcd 3.4.3 — "Locks Aren't Real"

- **system**: etcd's lock API. <https://jepsen.io/analyses/etcd-3.4.3> §3.2
- **situation**: a lease-based lock service, where a client acquires a named
  lock backed by a lease with a TTL, does some work against an unrelated
  resource, and releases.
- **property**: mutual exclusion. The report quotes an etcd maintainer's stated
  use case: "acquire an etcd lock / do something (again, not necessarily
  related to etcd database) / unlock the same etcd lock".
- **violation**: "multiple clients may hold the same etcd lock simultaneously
  … it can also occur in healthy clusters, without any external faults."
  Concrete history linked ("process 3 successfully acquires a lock, and
  process 1 concurrently acquires that same lock before process 3 can release
  it"). Quantified: "With two-second lease TTLs, five concurrent processes, and
  process pauses every five seconds, we could reliably induce the loss of ~18%
  of acknowledged updates."
- **shape**: `resource`
- **modelable**: **yes**. Everything needed is in the prose — a lock key, a
  lease with a TTL, a client that can pause. The report even states the general
  argument independent of etcd: "if a process crashes while holding a lock, the
  lock service needs some way to force the release of the lock in order to make
  progress. However, if the process is not in fact dead, but merely slow or
  unreachable, releasing the lock could lead to it being held in multiple
  places at once."
- **transferable**: **yes**, maximally. This is the everyday
  leader-election / distributed-cron / "only one worker touches this device"
  problem. The report also hands over the *fix* to model as a second round —
  fencing tokens: "use a fencing token of some kind, which is included with
  every operation a lockholder performs and used to ensure that no previous
  lockholder's operations interleave with the current lockholder's."
- **second violation in the same section, separately modelable**: the report
  notes that even a *perfect* lock does not order operations on a remote
  resource — "If process A sends a message to database D while holding a lock,
  A crashes, and process B acquires the lock and sends a message to D, then the
  message sent by A might arrive (thanks to asynchrony) after process B's
  message". That is a 2-process, 1-channel model.

### 2. jetcd 0.8.2 — unsafe retry of non-idempotent requests

- **system**: the official Java client library for etcd.
  <https://jepsen.io/analyses/jetcd-0.8.2>
- **situation**: a client library that automatically retries a request when it
  does not get an acknowledgement, in front of a store that offers strict
  serializable micro-transactions.
- **property**: the store's own guarantee. "Etcd is a coordination service
  designed to offer Strict Serializable reads, writes, and micro-transactions".
- **violation**: three, each with a concrete history linked from the report —
  lost update (§3.1), circular information flow / Adya's G1c (§3.2), aborted
  read (§3.3), plus a transaction that "observed a write it hadn't performed
  yet". Root cause stated in one sentence: "jetcd incorrectly retries
  non-idempotent requests which may have actually succeeded".
- **shape**: `delivery`
- **modelable**: **yes**, and this is the single cleanest one found. The whole
  mechanism is one sentence of prose; no etcd internals are needed. A model is
  a client that may emit an operation twice and a server that applies
  operations in order.
- **transferable**: **yes**, maximally. The report's own discussion generalises
  it away from etcd: "Retrying is safe when a client can prove that the
  operation cannot have taken place … It is also safe when the operation is
  idempotent … Engineers should also be careful when classifying operations as
  idempotent. It is easy to assume that `set(x, 5)` is idempotent because
  applying it twice in a row still produces the state `x = 5`. However, this
  operation is no longer idempotent if its executions are interleaved with
  other writes — then, it leads to lost update."
- **family**: the report names two siblings with the same root cause — "TiDB
  2.1.7 exhibited read skew and lost update thanks to an automatic retry
  mechanism. MongoDB 4.2.6's retry system allowed retrocausal transactions
  which read their own future effects."

### 3. Bufstream 0.1.0 §5.4 / §6.3 — the Kafka transaction protocol has no transaction number

- **system**: the Kafka transaction protocol, as implemented by Bufstream and by
  Kafka itself. <https://jepsen.io/analyses/bufstream-0.1.0> §5.4, §6.3
- **situation**: a client opens a transaction, sends writes over several
  connections to several servers, then sends one end-transaction message saying
  commit or abort.
- **property**: atomicity of a transaction — all of its writes take effect, or
  none do.
- **violation**: "torn transaction" — the report coins the name because none
  existed. "The first half (sending 424 to key 5) was committed and visible to
  pollers. The second half (sending 926 and 927 to key 17) implicitly began a
  second transaction, which was then aborted by the client." Concrete history
  and packet-capture reconstruction given, plus aborted read and lost writes.
- **shape**: `delivery`
- **modelable**: **yes**, and the report states the whole cause in three
  sentences with no reference to any implementation: "There is no sequence
  number to order requests from the same client. There is no concept of a
  transaction number. When a server receives a commit (or abort) message, it
  has no way to know what transaction the client intended to commit. It simply
  commits (or aborts) whatever transaction happens to be in progress."
- **transferable**: **yes**. The generalisation is written into the report:
  "Kafka's transaction system implicitly assumes ordered, reliable delivery
  where none exists … This demonstrates the importance of the end-to-end
  principle in protocol design: the client and transaction state machine must
  explicitly encode and enforce ordering 'at the edges,' rather than relying on
  the unreliable network between them." Any session-scoped state machine driven
  by unsequenced commands has this bug.
- **bonus**: the proposed fix is also in the prose and is a second modelling
  round — "KIP-890 revises the transaction protocol to bump the producer's
  epoch on every transaction. Since servers reject messages from older epochs,
  this should prevent commit messages from prior transactions leaking into
  later ones."

### 4. Aerospike 3.99 §3.1 — a proxy that retries, then reports the wrong error

- **system**: a request proxy in front of a store.
  <https://jepsen.io/analyses/aerospike-3-99-0-3> §3.1
- **situation**: a client sends a write to node A, which forwards it to node B;
  A retries on timeout and relays B's answer back to the client.
- **property**: a write reported as failed did not happen.
- **violation**: a write reported `:unavailable` was in fact applied and later
  read back. Concrete history given (process 98's failed write of 4, then
  process 99 reading 4). Cause stated in prose: "when Aerospike proxies writes
  from one server to another, it may transparently retry indeterminate failures
  like timeouts. It then returns the most recent failure, not the most
  conservative failure."
- **shape**: `delivery`
- **modelable**: **yes**. The report hands over a complete 3-actor narrative:
  "say a client issues a write to node A, which proxies it to B, where it is
  applied. However, B's response is lost due to a network failure. A
  transparently retries, and the second time around, B responds with a definite
  error: the partition is unavailable. A dutifully relays this message to the
  client, saying that the write was rejected, even though it successfully
  completed."
- **transferable**: **yes**. This is the API-gateway retry problem, and the
  modelling payload is a *lattice of error certainty* — definite failure vs
  indeterminate failure — which is a genuinely useful thing to have modelled
  once. Same family as candidate 2 (jetcd).

### 5. CockroachDB beta-20160829 §2.5 — "Comments"

- **system**: a service whose users post an item and then post a correction.
  <https://jepsen.io/analyses/cockroachdb-beta-20160829> §2.5
- **situation**: two write transactions issued one after the other by the same
  user, and a third transaction reading the collection.
- **property**: the report is explicit that this is *not* a bug — it is the gap
  between serializability and strict serializability. "CockroachDB does not
  provide strict serializability — linearizability over the entire keyspace.
  This means that transactions over different keys may not be observed in their
  real-time order."
- **violation**: "A user could observe the followup comment C2, but not the
  original comment C1." Concrete history exhibited (process 24 reads 430 but
  not 425, both written before its read returned).
- **shape**: `concurrency`
- **modelable**: **yes**, trivially — three transactions, two keys, an ordering
  relation. Kyle even writes the offending interleaving out by hand.
- **transferable**: **yes**, and this is the report where the corpus does the
  translation work itself: the whole section is framed as an application
  scenario ("imagine an application which has a sequential stream of comments")
  rather than as a database property.
- **note**: this is the one candidate that is a *permitted* behaviour rather
  than a defect. As an exercise that is arguably better, not worse: the task is
  "here is the guarantee the vendor gives you — show me the surprise it
  allows", which is exactly what a spec-vs-intuition modelling exercise is for.

### 6. Radix DLT §3.6 — a status cache overwritten by a rejected duplicate

- **system**: a ledger with an append-only log plus a separate per-item status
  field. <https://jepsen.io/analyses/radix-dlt-1.0-beta.35.1> §3.6
- **situation**: an item is committed to the log; a duplicate copy of the same
  item arrives later by a second path and is rejected as already-present.
- **property**: a transaction reported FAILED did not commit.
- **violation**: "Under normal operation without faults, transactions with
  status FAILED could actually be committed." Concrete histories given, and
  also reproduced on the live public network with named transaction hashes
  ("its transaction state on October 1 … was FAILED. Two days later, on October
  3rd, its state flipped to CONFIRMED").
- **shape**: `two-store`
- **modelable**: **yes**. The cause is stated as a plain mechanism: "a
  transaction committed normally but had been gossipped to other nodes'
  mempools; if those nodes then gossiped the transaction back to the original
  node, that node would recognize that the transaction had already committed
  and reject the gossip message. Concluding the transaction was rejected, Radix
  would then overwrite the transaction's status to flag it as FAILED. When the
  transaction later fell out of cache, subsequent reads would query the log
  directly, and observe its state as CONFIRMED."
- **transferable**: **yes**. The pattern — a *rejection* of a duplicate written
  back over the *status* of the original — is a bug an ordinary service with a
  status column and an idempotency check can have. The two-store disagreement
  (cache says FAILED, log says CONFIRMED, cache expiry flips the answer) is the
  transferable part.

### 7. Dgraph 1.1.1 §4.1 — an ownership handoff where both owners answer

- **system**: a keyspace partitioned into units that can be moved from one
  owner to another while requests are in flight.
  <https://jepsen.io/analyses/dgraph-1.1.1> §4.1
- **situation**: a unit of data is migrated from shard A to shard B; requests
  carry a start timestamp; A deletes its copy once the move completes.
- **property**: a read returns the committed value, not a null.
- **violation**: "reads would return a null value for a record which should
  have existed". Concrete histories and a plot given; "These errors were
  common in version 1.1.1, occurring with essentially every tablet move."
- **shape**: `two-store`
- **modelable**: **yes**, and the cause is a two-clause window condition stated
  outright: "the new shard could serve transactions whose start timestamp was
  prior to the tablet move time, and the old shard could serve transactions
  with a start timestamp after the move time — i.e. after that shard had
  deleted the tablet entirely. Without any data, those shards would return null
  values."
- **transferable**: **yes**. This is device/tenant ownership handoff between
  gateways, or a shard rebalance, and the failure — both ends believing the
  other has it — is the everyday form.
- **caveat**: the *other* Dgraph findings are not modelable. §4.3's loss of
  "up to tens of thousands of acknowledged inserts" is attributed to "posting
  list splits" and "a bug in Dgraph allowed the parts of a split posting list
  to be accessed individually" — a storage internal, and out of scope by the
  brief's own test.

### 8. Scylla 4.2-rc3 §3.4 — per-field last-write-wins jumbles two writers' updates

- **system**: a record whose fields are merged independently by last-write-wins
  on a timestamp. <https://jepsen.io/analyses/scylla-4.2-rc3> §3.4
- **situation**: two writers each write a whole record; the store resolves each
  field separately by comparing timestamps.
- **property**: row-level isolation, which both vendors claim in their docs.
  "Scylla's DML documentation made repeated claims that INSERT, UPDATE, DELETE,
  and BATCH are all isolated (at least, when limited to a single partition)."
  The report notes Cassandra's documentation "still insists that writes are
  'performed with full row-level isolation.'"
- **violation**: "values from three completely separate writes have been jumbled
  together". Concrete trace given: `[[:r 4 -5] [:r 3 -2] [:r 5 -3]]` where every
  key should have shown the same absolute value. "This problem occurs in healthy
  clusters, even with consistency level ALL for reads and writes."
- **shape**: `concurrency`
- **modelable**: **yes**. The mechanism is per-field LWW on a timestamp plus
  timestamp collision; no storage internals are needed. The report even names
  the amplifier: "By quantizing timestamps, we could induce anomalies in just a
  handful of writes."
- **transferable**: **yes**, and this is the candidate closest to the learner's
  own domain. Per-field last-write-wins merge is how device shadows / digital
  twins / desired-state documents work in industrial IoT, and how most
  "merge the config" code works. Two operators each submitting a complete
  desired state, and the device ending up with half of each, is the same bug.

### 9. Chronos 2.4.0 — a resource lease held by an identity that no longer exists

- **system**: a distributed task scheduler running on a cluster resource
  manager. <https://aphyr.com/posts/326-call-me-maybe-chronos>
- **situation**: a scheduler claims resources from a pool under an identity,
  fails over to a standby, and the standby registers as a *new* identity while
  the pool still credits the resources to the old one.
- **property**: stated cleanly and without giving anything away — "The scheduler
  does its job iff, for every target time, the task is run." The report is also
  explicit that duplicate runs are permitted: "It's a lot easier to recover from
  multiple runs than no runs!"
- **violation**: "Chronos never recovers when the network heals. It continues
  accepting new jobs, but won't run any jobs at all for the remainder of the
  test… This behavior persists even when we give Chronos 1500+ seconds to
  recover." Concrete trace: a timestamped 8-step timeline plus the log line
  `No resources available to allocate!`
- **shape**: `resource`
- **modelable**: **yes**. The cause is two sentences, verified verbatim at
  `chronos-2.4.0` line 134: "This is bug #520: after Chronos fails over, it
  registers with Mesos as an entirely new framework instead of re-registering.
  Mesos assumes the original Chronos framework still owns every resource in the
  cluster, and refuses to offer resources to the new Chronos leader."
- **transferable**: **yes**, and this is the single best fit in the whole corpus
  for the learner's stated interests. It is not a database, not a consensus
  protocol, and not an isolation level. It is "a worker takes a lease under an
  instance id, restarts under a new id, the lease never expires, and the
  replacement starves" — connection pools, licence slots, partition
  assignments, device claims.
- **bonus**: the fix is also a mechanism, so the model has a green variant —
  "Set Mesos' `--offer_timeout` to some reasonable (?) value".

### 10. Chronos 2.4.0 — poll period versus deadline window

- **system**: a scheduler whose dispatch loop polls on a fixed period and must
  start each job inside a window. Same report.
- **property**: a run must begin between the target time `t` and `t + epsilon`.
- **violation**: "If you schedule jobs with intervals that are too frequent —
  even if they don't overlap — Chronos can fail to run jobs on time, because the
  scheduler loop can't handle granularities finer than `--schedule_horizon`,
  which is, by default, 60 seconds." No trace; stated as a rule, with the
  confirming experiment: "Lowering the scheduler horizon to 1 second allows
  Chronos to satisfy all executions for intervals around 30 seconds."
- **shape**: `expiry`
- **modelable**: **yes**, and it needs no distribution at all — a tick every
  `P`, a window `[t, t+epsilon]`, and the question of whether the window
  contains a tick.
- **transferable**: **yes**. Every poll-loop scheduler, cron-plus-worker, and
  IoT sampling loop has this.
- **note**: this is the smallest thing in the corpus and would make a good
  warm-up, but it is close to trivial — there is barely a discovery in it.

### 11. Hazelcast 3.8.3 §3.4 — block-allocated IDs double-allocated

- **system**: a service that hands out unique identifiers by reserving blocks of
  numbers from a shared counter. <https://jepsen.io/analyses/hazelcast-3-8-3>
- **property**: "cluster-wide unique identifiers".
- **violation**: "~91,000 duplicated IDs out of ~834,000". Aggregate checker
  output plus a duplicate map; no per-operation trace.
- **shape**: `resource`
- **modelable**: **yes**, and the amplification is stated as protocol: "If a
  pair of IdGenerators request a new block of numbers from their underlying
  AtomicLong during a partition, they will likely double-allocate that entire
  block of IDs."
- **transferable**: **yes**. Block-allocated sequence numbers — order ids,
  invoice numbers, device ids, tag ranges — are ordinary backend work, and the
  payload is the non-obvious amplification: one lost compare-and-set becomes a
  whole block of collisions.

### 12. Hazelcast 3.8.3 §3.5 / §3.6 — the merge rule decides whether updates survive

- **system**: a store whose diverged copies are reconciled by a configured merge
  rule. Same report.
- **property**: "Every successful replace should result in that particular
  element being present in all subsequent versions of the set."
- **violation**: "Hazelcast lost four modifications to a single key, all
  clustered around the start of a network partition." Aggregate output only.
- **shape**: `two-store`
- **modelable**: **yes**, and this candidate is unusual in that **the report
  ships its own green case**: §3.6 replaces the merge policy with set union and
  reports the run valid — "every one of those acknowledged elements was present
  in the final reads". The available policies are named in §2: "larger or
  smaller cluster wins, last-write-wins, or higher-hits-wins."
- **transferable**: **yes**. "Reconciling two diverged copies with
  last-write-wins loses updates; a commutative merge does not" applies directly
  to cache/DB resync and to offline-device sync.
- **why this one is worth more than its siblings**: it is a red→green pair in a
  single model — swap one operator and the invariant holds. That is a better
  exercise than a bug hunt.

### 13. Redis WAIT — highest-offset-wins discards the branch that had quorum

- **system**: two branches of the same data that diverge during a split and are
  reconciled by whichever branch has the larger progress counter.
  <https://aphyr.com/posts/307-call-me-maybe-redis-redux>
- **property**: "positive acknowledgement of a write to a majority of nodes
  guarantees that write will be visible in all future states of the system."
- **violation**: a hand-built 7-step counterexample ending "The coordinator sees
  that O1 is higher than O3, and chooses P1 as the new primary. P3 is demoted,
  and all its acknowledged writes are destroyed", *plus* an experimental
  confirmation: "In a partition which lasted for roughly 45% of the test, 45% of
  acknowledged writes were thrown away. To add insult to injury, Redis preserved
  all the failed writes in place of the successful ones."
- **shape**: `two-store`
- **modelable**: **yes**, entirely from prose, and the essential condition is
  stated without reference to any bug: "All that's required is for more
  operations to happen on P1 than P3 after the two diverge."
- **transferable**: **yes**, and for an industrial-IoT engineer this is close to
  home: a device that was offline and accumulated a higher local sequence number
  overwriting the server branch that actually had quorum.
- **special property of this report**: it analyses a **proposed design that was
  never built**, so it contains no product internals at all, and — uniquely in
  the corpus — the puzzle and the answer already sit in separate unmodified
  sections. "The failover proposal" states the 5-step algorithm neutrally; "The
  coordinator" and "The servers" are the answer key.

### 14. Amazon RDS for PostgreSQL 17.4 — the writer and the reader disagree about order

- **system**: a replicated store with one write endpoint and one read endpoint.
  <https://jepsen.io/analyses/amazon-rds-for-postgresql-17.4> §1, §4
- **property**: "the strongest consistency model supported across all
  endpoints"; restated plainly by the report itself in §5 — "A read transaction
  may disagree with other transactions as to the order in which transactions
  were executed."
- **violation**: four transactions narrated fully in text; T2 sees T1's append
  but not T3's, T4 sees T3's but not T1's. Occurred with **no faults at all**:
  "We performed no fault injection, and triggered no failovers."
- **shape**: `two-store`
- **modelable**: **yes — the cleanest mechanism statement in the corpus.** Two
  sentences, verified at line 13: "the order in which a PostgreSQL primary makes
  transactions visible is determined by an in-memory lock. Secondaries, however,
  make transactions visible based on their order in the Write-Ahead Log (WAL).
  The lock order and WAL order can be different." The model is: each commit
  carries two ranks, and each endpoint serves by a different one.
- **transferable**: **yes**. "Primary and read-replica expose the same commits in
  different orders" is a fact about every read-replica deployment.
- **best split in the corpus**: the cause lives entirely in a section headed
  "1 Update, 2025-05-03", added after publication. Withhold that one section and
  the original report has *no* diagnosis — §5 says "we have not investigated
  Amazon RDS for PostgreSQL behavior in detail." The split is structurally free.

### 15. FaunaDB 2.5.4 §4.9 — the record keeps history, the index keeps only last-touched

- **system**: a store that retains every version of a record, plus an index whose
  entries carry a single mutable timestamp.
  <https://jepsen.io/analyses/faunadb-2.5.4> §4.9
- **property**: "In a snapshot isolated system, every read would return exactly
  100."
- **violation**: "the observed total of all account values could fluctuate
  between $27 and $126"; "roughly 60% of reads could observe inconsistent
  states." Aggregate evidence, not a named history.
- **shape**: `two-store`
- **modelable**: **yes**, and the report states *both* the correct rule and the
  broken one, which is unusually generous. Correct: "a transaction would ensure
  that the server had applied every transaction up to t in the log, then find
  the version of r with the highest timestamp tr such that tr < t." Broken,
  verified at line 277: "if an index entry with the same value already existed,
  that entry's timestamp t1 would be overwritten with a new timestamp t2."
- **transferable**: **yes**, with no isolation vocabulary at all. Plain form: the
  table keeps history, the search index or materialised view only keeps
  last-touched-at, so as-of queries answered from the index lie.

### 16. FaunaDB 2.5.4 §4.7 / §4.10 — paginating a collection that is being written

- **system**: an API that returns a large result set a page at a time, with a
  cursor that records *where* to resume but not *when*. Same report.
- **property**: there is no claimed one, and the report says so — "The
  documentation says that pagination can be used to 'walk the result set in
  blocks', but doesn't actually claim that result sets are transactional."
- **violation**: §4.7 is hypothetical ("a transaction could insert the numbers 80
  and 81 together, but if the two elements happen to fall on different pages, a
  paginated query could observe 81 but not 80"). §4.10 is a real bug with a
  concrete history and a one-sentence mechanism: "the query engine filtered out
  unapplied transactions from the index, but still counted those unapplied
  transactions towards the total number of results for a given page —
  effectively skipping n records at the end of each page."
- **shape**: `workflow`
- **modelable / transferable**: **yes / yes**, needing no database concept. §4.10
  is "we applied LIMIT before the visibility filter", a bug most backend
  engineers can date to a specific sprint.
- **why §4.7 is worth more than it looks**: because there is no claimed property,
  the exercise is *"what should this guarantee?"* — which is the hardest and most
  useful modelling skill, and the corpus almost never asks for it.

### 17. TiDB 2.1.7 §3.6 — a row lock cannot cover a row that does not exist yet

- **system**: a service that locks each record it reads so two concurrent
  requests cannot both act on it. <https://jepsen.io/analyses/tidb-2.1.7> §3.6
- **property**: a guarantee that was only ever spoken — "PingCAP's engineers have
  said repeatedly that using `select ... for update` prevents write skew", while
  "PingCAP's official documentation did not describe what `select ... for update`
  should have done."
- **violation**: concrete two-line history given, with the contradiction argued
  in the next sentence. Mechanism verified at line 222: "TiDB's locking
  mechanism can't lock keys which haven't been created yet, which allows write
  skew to manifest!"
- **shape**: `concurrency`
- **modelable**: **yes**, and it is the smallest interesting model found —
  2 processes, 2 keys, an existence predicate, a lock set in which acquiring a
  lock on an absent key is a silent no-op.
- **transferable**: **yes**, with the label discarded entirely. Plain form: "two
  requests both check that no user with this email exists, and both insert."
  Every backend engineer has hit this and most reach for a unique index without
  ever asking why the row lock did not help.

### 18. TiDB 2.1.7 §3.4 — a retry that replays the writes and returns the old reads

- **system**: a service that silently retries a conflicted request's writes
  against fresh state while handing the caller the response computed from the
  *first* attempt. Same report, §3.4
- **violation**: concrete, and the report reconstructs the mechanism across four
  successive renderings of one history. Stated cause: "it returns the reads from
  the aborted transaction T2, then retries T2's writes, without bothering to
  return the new values that would have been observed in T2r." Bank totals
  "doubling in under thirty seconds".
- **shape**: `delivery`
- **modelable / transferable**: **yes / yes**, with no isolation vocabulary.
  Plain form: "an HTTP client retries a failed POST; the retry lands, but the
  caller gets the first attempt's response body."
- **family**: third member of the retry family with candidates 2 and 4.

### 19. RavenDB 6.0.2 §3.2 / §3.3 — "a transaction in RavenDB is a request"

- **system**: a client API whose "session" object looks like a transaction but
  sends each read and each write as its own round trip.
  <https://jepsen.io/analyses/ravendb-6.0.2> §3.2, §3.3
- **property**: quoted from the vendor — "even if you access multiple documents,
  you'll get all of their state as it was in the beginning of the request."
- **violation**: a request sees one of another request's two writes. The trace is
  a diagram; the prose narration is complete but the figure does not survive as
  text.
- **shape**: `concurrency`
- **modelable**: **yes**, and the reveal is a single quoted sentence from
  RavenDB's CEO in §4.1: "A transaction in RavenDB is a request - so TX1 and TX2
  above aren't actually single transactions, instead, each of them represent 3
  independent transactions."
- **transferable**: **yes**. The plain form is "a handler reads the customer
  record and then the address record; between the two reads something updated
  both; the handler sees the new address with the old customer." The modelling
  payload is making the *atomicity boundary* explicit, which is exactly the
  thing an ORM session hides.
- **best framing in the corpus for "what does the vendor actually promise"**:
  §§1.1–1.2 are a pile of mutually contradictory vendor claims and make an
  excellent problem statement on their own.

### Also usable, recorded without full treatment

- **Crate 0.54.9** (<https://aphyr.com/posts/332-jepsen-crate-0-54-9-version-divergence>)
  — two different values carrying the same `_version`, so a compare-and-swap
  against a stale version succeeds. Property stated jargon-free: "we just want to
  ensure that each `_version` of a given row identifies a single value."
  Concrete text trace. Tiny (2 replicas, 1 key, a counter, a partition flag).
  Transferable as ETag / version-column optimistic concurrency. Marked down only
  because the report never establishes a mechanism beyond the symptom, so the
  compare-against answer is thin.
- **FaunaDB §4.11** — as-of reads bounded on one side only: "queries would be
  prohibited from returning the state of that instance after t, but could observe
  any state — not just the most recent state — before t." Plain form: a
  read-at-timestamp routed to a replica that has not caught up. Good, and it
  pairs with §4.9, which states the *correct* rule in the same report.
- **MySQL 8.0.34 §3.5** — a "snapshot" that a write promotes one row out of, with
  the cleanest formatted trace in the corpus (a literal SQL transcript). Plain
  form: a read-through cache where writing a key invalidates that key's entry but
  not the others. Marked down because §3.5 states no mechanism and the report
  never confirms one — the puzzle-setter has to join it to a doc quote buried in
  §1.3 and write the answer themselves.
- **Hazelcast §3.1 locks, §3.2 queues, §3.3 atomics; RabbitMQ mutex and queue;
  Redis WAIT §"The coordinator"** — all real, all modelable, all transferable,
  all **duplicates** of candidates 1, 12 and 13. Kept as alternative costumes,
  not counted as separate problems. RabbitMQ's mutex section is worth keeping
  specifically because it prints the only full step-by-step counterexample in the
  corpus, including the checker's reason `([{:locked true} "already held"])` — a
  model can be checked against a real history rather than a description of one.

### Marginal — recorded so the reasoning is visible, not counted as candidates

- **VoltDB 6.3 §4.1** — the shrinking-membership mechanism is stated cleanly
  ("VoltDB can give up on nodes which are unresponsive. These nodes are ejected
  from the cluster … Since the cluster no longer includes the unreachable nodes,
  the SPI is free to return writes which weren't replicated to them"), and it is
  modelable. But "acknowledge when all *current* members have it, and let
  membership shrink" is a replication-protocol problem, which is adjacent to the
  consensus family the learner rejected. Same mechanism as Kafka 0.8.
- **MongoDB 4.2.6 §4.1** — a real configuration-composition hazard: "any read
  concern set at the collection and database level is ignored inside the
  transaction", so wrapping existing code in a transaction silently *downgrades*
  its safety. Transferable as a shape (an inner scope discarding an outer
  scope's setting). Rejected as a modelling problem because the interesting part
  is a documented API rule rather than a behaviour a checker would discover.
- **RethinkDB 2.2.3 §7** — a genuinely appealing `lifecycle` setup: an entity is
  removed, wiped, re-added under a fresh identity, and the guard is a monotonic
  timestamp on ACTIVE/INACTIVE messages, because "If a node ever applied an old
  ACTIVE message a second time, it'd re-use the former node ID, which would
  appear as data loss to other nodes who still believe that node is in the
  cluster." That is device-replacement-under-a-recycled-tag, and it is worth
  stealing as a *scenario*. Rejected as a *problem* because the actual bug is a
  three-way interaction between Raft joint consensus, a 2^63 timestamp bug, and
  an escape hatch added to work around it — the report says the cause "remained
  elusive" for months. Unreachable ground truth.
- **Elasticsearch 1.1.0 / 1.5.0, Redis 2.6.13, MongoDB 2.4.3, Riak, Cassandra,
  NuoDB, Aerospike 3.5.4, Zookeeper, MariaDB Galera 10.0, Percona, Crate,
  Redis-Raft, Tendermint, Scylla split-brain, Dgraph 1.0.2, RethinkDB 2.1.5,
  etcd 0.4.1, Redis WAIT** — the failure is "a failover or a partition lost
  writes". The consequence is the premise; the mechanism that would make it a
  puzzle is a replication or election protocol, which is exactly the rejected
  territory. `INFERRED` from the triage pass over abstracts and headings for
  these reports.
- **Capela, NATS 2.12.1, TigerBeetle §3.6–§3.8, Dgraph §4.3** — crashes, panics,
  fsync behaviour, storage-engine internals. Excluded by the brief's own
  modelability test.

### Rejected after reading, with reasons

- **MongoDB 3.6.4 §3 (causal consistency)** — the documented guarantees are
  quoted cleanly and the anomaly traces are concrete text tables. Rejected
  because to *exhibit* it you must model why an acknowledged write vanished, and
  the report never states that mechanism — it says only "the value of the second
  write appears to have been rolled back" and links SERVER-35316. The rule you
  would have to supply is a leader-with-an-uncommitted-tail, i.e. a small
  consensus model wearing a session-token hat.
- **TiDB §3.5** — a documented off-switch that disables only one of two retry
  paths. A real lesson about configuration surfaces, but the prose gives nothing
  for a checker to discover; a model of it just restates the sentence.
- **RavenDB §3.1** — plain read-modify-write lost update at default settings.
  Correct, well-evidenced, and almost certainly already covered by learntla
  chapter 11. `INFERRED` from the brief's "about eleven chapters into learntla".

## Corpus-level findings

These are counts over all 50 reports, not impressions. The commands are in the
Method section's spirit — each was run over the fetched text.

### The corpus is about one property, tested against fifty products

**47 of 50 reports** use isolation- or consistency-model vocabulary
(`linearizab|serializab|snapshot isolation|read committed|repeatable read|causal
consistency|G2-item|G1c|write skew|read skew|long fork`). That is the subject
matter. The variety in this corpus is in the *products*, not in the *problems*.

Against that, the counts for everything else are small:

| theme | reports mentioning it | substantive |
|---|---|---|
| locks / mutual exclusion / fencing | 9 | ~4 (etcd 3.4.3, Hazelcast, RabbitMQ, Redis) |
| queue / message delivery semantics | 7 | ~4 (Kafka, Bufstream, Redpanda, RabbitMQ) |
| scheduling, cron, jobs | 5 | **1** (Chronos) |
| rolling upgrade / version rollout | 2 | **1** (TigerBeetle) |
| lease / TTL / expiry as the subject | — | **1** (etcd 3.4.3 leases) |
| configuration composition | — | ~1 (MongoDB 4.2.6 §4.1) |

Of the brief's eight shapes, the corpus populates `concurrency` overwhelmingly,
`delivery` decently, `two-store` and `resource` thinly, and `lifecycle`,
`expiry`, `rollout` and `workflow` at roughly one report each. There is nothing
about business workflows, approval chains, state machines with human steps, or
device lifecycles — the things an industrial-IoT engineer actually ships.

### A quarter of the findings are crashes, not properties

Across the 22 reports with a numbered `Results` section there are **190 numbered
findings**. **50 of them (26%)** are titled as a crash, panic, assertion
failure, deadlock, memory leak, hang, timeout, unavailability, or performance
degradation. Examples: `capela §3.12 Double-Free or Corruption Crash (#12)`,
`capela §3.17 Crashes on Startup With .sst File Bitflips (#10)`,
`tigerbeetle §3.8 Panic Due to Superblock Bitflips (#2681b)`. None of these is
a modelling problem. Capela alone contributes 14 such findings out of its 24 —
that whole report is unusable for this purpose.

### Ten reports admit they never found the cause

`bufstream`, `mongodb-4.2.6`, `dgraph-1.1.1`, `redis-raft`, `mysql-8.0.34`,
`rethinkdb-2.2.3`, `redpanda`, `voltdb-6.3`, `postgresql-12.3`, `radix-dlt` each
contain at least one finding where Jepsen says outright that it does not know
the cause. Radix DLT §3.8 is the clearest: "We don't know what caused this
issue". A finding with no diagnosis has **no ground truth** and cannot be used
in the compare-against-the-report format at all.

### Jepsen's own modelling cost is a warning

TigerBeetle §2.2 records what it costs to model a real product faithfully: "The
state machine is surprisingly complex, involving over 1,600 lines of Clojure and
an extensive test suite." That is the price of modelling the *product*. Every
candidate below is small precisely because it models only the **mechanism** the
report isolates, and throws the product away.

### The distinction that separates a puzzle from a non-puzzle

Some reports state a mechanism whose *consequences* are surprising. Others state
a failure whose consequence *is* the premise. Compare:

- **A puzzle**: "jetcd incorrectly retries non-idempotent requests which may have
  actually succeeded" → the learner must discover that this yields lost update,
  circular information flow, aborted read, and read-your-own-future-writes.
  Four non-obvious consequences from one line of mechanism.
- **Not a puzzle**: Elasticsearch 1.5.0 "Isolated primaries" — "For several
  seconds, Elasticsearch is happy to believe two nodes in the same cluster are
  both primaries, will accept writes on both of those nodes, and later discard
  the writes to one side." There is nothing to find. Two primaries lose writes;
  that is the premise restated. The interesting part is the election protocol,
  which the report does not give and which is the consensus territory the
  learner has already rejected.

This test does more filtering work than `modelable` does, and it is the one I
applied hardest.

## Can the ground truth be split from the description?

The plan is: hand the learner the system description with the cause held back,
let him model it and find the break, then compare against what the report found.

**Structurally, Jepsen reports support this better than most prose.** The 32
modern reports have a fixed skeleton — `Background` (what the system is),
`Test Design` (workload and faults), `Results` (finding by finding), `Discussion`
— and the diagnosis lives in `Results`. So a mechanical split exists: give
`Background` + `Test Design`, hold `Results`.

**But the mechanical split does not actually work**, for three reasons found by
checking it against specific reports:

1. **The abstract gives the answer away.** Every report opens with a paragraph
   naming the violations. etcd 3.4.3's says "etcd locks are fundamentally
   unsafe". That paragraph has to be removed by hand.

2. **`Background` is usually product background, not mechanism.** It describes
   architecture and links to vendor docs. Where the causal mechanism appears at
   all, it appears in `Results`, next to the diagnosis. jetcd is the clean
   example: §1 Background never mentions retries; the retry mechanism is the
   first sentence of §3 Results — the same sentence that is the answer.

3. **Some findings have no answer.** Ten reports contain at least one finding
   whose cause Jepsen never established (Radix DLT §3.8: "We don't know what
   caused this issue"). Those cannot be used in this format at all.

**Two split modes, and only the second is reliable here.**

- **Mode A — hold the mechanism.** Give the system description; ask "what
  breaks". Works where `Background` genuinely contains the mechanism. It does
  for etcd 3.4.3: §1 Background states "Leases (transient objects with a limited
  lifetime, kept alive via client heartbeats), locks (exclusively held named
  objects, bound to leases)" and §2.4 Test Design states the workload — together
  that is enough to model, and nothing there says a lock can be doubly held. It
  also works for Dgraph §4.1's handoff. It works for very few others.

- **Mode B — hold the consequences.** Give the mechanism in one or two
  sentences; ask "what does this permit". This is the mode most of the good
  candidates want, and it is the more TLA+-native of the two anyway: you model a
  stated protocol and let the checker tell you what it allows. jetcd is the
  ideal case — one sentence of mechanism ("the client may retry a request that
  may already have succeeded") yields four non-obvious consequences (lost
  update, circular information flow, aborted read, a transaction reading its own
  future write), each of which the report names and exhibits with a history.
  Kafka transactions, the Aerospike proxy and CockroachDB's Comments section all
  work this way too.

**Verdict on the ground truth**: usable, but *per-problem editorial work is
required*. There is no mechanical splitter. Budget roughly an hour per problem
to write the setup, and expect to write it in the learner's own domain rather
than quoting the report, because the report's setup is a database. The
compare-against step, by contrast, is excellent where it exists: Jepsen names
the anomaly, links a machine-readable history, and usually links the upstream
issue and the fix — so the learner can check not only "did I find a break" but
"did I find *the* break, and is my fix the one they shipped".

## Are any of them small?

Yes, and the small ones are small because they model the *mechanism* and discard
the product. Sizes below are the state a model needs, not line counts.

The three smallest:

1. **Aerospike proxy retry** (candidate 4) — a client, a proxy, a backend, one
   in-flight response that may be lost, and an error value with two grades
   (definite / indeterminate). Roughly four variables. The invariant is one
   line: a write reported failed is not present.
2. **CockroachDB "Comments"** (candidate 5) — three transactions over two keys
   and a real-time order relation. Kyle writes the offending interleaving out by
   hand in the report, so the model is essentially a transcription exercise; the
   work is in stating the *property* precisely enough that the checker
   distinguishes serializable from strict serializable.
3. **etcd locks** (candidate 1) — two clients, one lock, one lease with a TTL,
   and a pause action. The mutual-exclusion invariant is a one-liner. The second
   round (add a fencing token, show it fixes it) reuses the same model.

Then, in ascending size: Radix's status cache (a log, a status map, a duplicate
delivery path); jetcd retry (a store map plus a message bag that can duplicate);
Dgraph's ownership handoff (a key, an owner, a move timestamp, timestamped
requests); Kafka torn transactions (a client, two servers, a reorderable message
bag, a per-producer current-transaction pointer).

None of these needs a quorum, a log, an election, or a clock model. That is what
makes them different from the rest of the corpus.

## The five questions, answered

### 1. How many analyses are there, and how many survive the filter?

- **50 analyses.** 32 on jepsen.io, 18 on aphyr.com. (The etcd 0.4.1 post covers
  etcd *and* Consul, so 51 systems in 50 reports.)
- **18 reports** contain at least one violation that is both modelable and
  transferable.
- **19 candidates recorded above**, which collapse to **16 distinct problems**
  once duplicate families are merged: the retry family is one problem in three
  costumes (candidates 2, 4, 18), and the reconciliation-rule family is one in
  two (candidates 12, 13). A fourth family — a handoff with no fencing token —
  appears in four separate reports (etcd locks, RabbitMQ-as-mutex, Hazelcast
  locks, Redis WAIT's cutover) and is counted once, as candidate 1.
- **12 of those 16 are strong** — small, clean mechanism, real ground truth,
  and not a costume of another one. The remaining four are the ones marked down
  in "Also usable": Crate's thin diagnosis, MySQL §3.5's absent one, FaunaDB
  §4.11 (which mostly repeats §4.9), and candidate 10's near-triviality.

Of the 16, only **7 are about something that is not a store's read/write
visibility**: the Chronos resource lease, the Chronos poll window, the etcd
lease/lock, the Kafka transaction protocol, the retry family, cursor pagination,
and block-allocated IDs. The other 9 are store-shaped but restate cleanly into
ordinary service terms. That ratio is the honest characterisation of the family.

### 2. Which violations are about a claimed guarantee rather than an implementation slip?

Most of the good ones, which is why they work. Claimed-guarantee cases:

- **Hazelcast, all five datatypes** — the report refuses to file bugs at all:
  "These problems are not bugs; they are fundamental design decisions." Each
  carries its own broken promise (locks "guaranteed mutual exclusion", the ID
  generator "cluster-wide unique identifiers").
- **Kafka's transaction protocol** — "The Kafka transaction protocol is
  fundamentally broken and must be revised", affecting "Kafka, Bufstream, and
  (presumably) other Kafka-compatible systems".
- **etcd locks** — the API is doing exactly what it was built to do; the
  conclusion is that "distributed locks are a fundamentally unsafe concept in
  asynchronous systems."
- **RavenDB** — the whole report. Its recommendation is to change the words, not
  the code: "Jepsen recommends RavenDB remove claims of 'ACID', 'Serializable',
  and 'Snapshot Isolation' from their marketing materials."
- **Amazon RDS for PostgreSQL** — a false claim *and* an identified cause.
- **Scylla / Cassandra per-field LWW** — Cassandra's documentation "still insists
  that writes are 'performed with full row-level isolation'" while the issue has
  been open since 2013.
- **TiDB §3.6** — a guarantee that was only ever *spoken*, never written down.
- **Redis WAIT** — the purest case: nothing was implemented, so the only target
  is the claim.
- **CockroachDB §2.5** — not a violation at all, but the gap between a *correct*
  guarantee and what a user assumes it means.

Implementation slips that still model well: the Chronos framework-registration
bug (#520), the FaunaDB index-timestamp and pagination bugs, the Aerospike proxy
retry, the jetcd retry, the Dgraph tablet-move window.

There is also a **third category** worth naming, and it is the most valuable
one pedagogically: FaunaDB §4.7, where *no* property is claimed — "doesn't
actually claim that result sets are transactional… Whether this behavior
violates Fauna's claimed invariants depends on how users interpret the
documentation." The exercise there is "what should this even guarantee?", which
is the hardest modelling skill and the one the rest of the corpus never asks
for.

### 3. Are any of them small?

Yes. Answered in full in the section above; the shortlist is the Aerospike proxy
(client + proxy + backend + one droppable response), CockroachDB Comments (three
transactions, two keys), TiDB §3.6 (two processes, two keys, a lock set that
silently no-ops on absent keys), the Chronos poll window (one tick counter and
two constants), and etcd locks (two clients, one lock, one lease).

None of the strong candidates needs a quorum, a log, an election, or a clock
model. That is precisely what separates them from the other 32 reports.

### 4. What is this family systematically bad at?

Plainly: **it is a corpus about one property, tested against fifty products.**
47 of 50 reports state their finding in isolation- or consistency-model
vocabulary. The variety is in the vendors, not in the problems.

Consequences, in order of how much they matter here:

1. **Four of the eight shapes are near-empty.** `lifecycle`, `expiry`, `rollout`
   and `workflow` have roughly one usable instance each across 50 reports. There
   is nothing at all about business workflows, approval chains, state machines
   with human steps, device lifecycles, feature-flag rollout, or configuration
   drift — a fair slice of what an industrial-IoT engineer actually ships. If
   the curriculum needs those shapes, this family will not supply them.
2. **A quarter of the findings are not properties.** 50 of the 190 numbered
   findings in the modern reports are crashes, panics, assertion failures,
   deadlocks, leaks, hangs or performance degradation. Capela contributes 14 of
   its 24 that way and is entirely unusable.
3. **Ten reports contain a finding with no established cause**, so those have no
   ground truth and cannot be used in the compare-against format at all.
4. **The jargon risk is real but is a property of the reports, not the
   violations.** The traces and ordering arguments are almost always jargon-free
   — RDS derives its contradiction from bare timestamps, "c1 < s2 … We have a
   contradiction!", and only afterwards labels it. But the *conclusions* are
   frequently pure taxonomy: "we did not observe Short Fork… This suggests that
   Amazon RDS for PostgreSQL might provide Parallel Snapshot Isolation" is
   meaningless without the hierarchy. Handing over an unedited report swaps
   consensus jargon for isolation jargon, and the isolation taxonomy is about as
   large. Restating the situation and handing over the trace does not — but that
   restatement is work the puzzle-setter must do, and cannot be delegated to the
   learner, since doing it requires already knowing what the labels mean.
5. **Granularity.** Most of these live at row / key / append granularity, which
   is *database* granularity. "Stores" are on the learner's accept-list, but
   modelling MVCC row versions is not self-evidently closer to his day job than
   Raft is. The candidates that survive *that* test are the ones whose mechanism
   is a service-level mechanism he has personally written — cursor pagination,
   store-versus-index drift, retry-returns-stale-response, check-then-create,
   read-at-timestamp against a lagging replica, lease handoff.

### 5. Is the ground truth actually usable?

Answered in full above. In short: **yes, but there is no mechanical splitter.**

The reports have a fixed skeleton that *looks* splittable (`Background` /
`Test Design` / `Results`), and three things defeat the naive cut: the abstract
names every violation, `Background` is usually product background rather than
mechanism, and ten reports contain findings with no answer. Two split modes
exist; the reliable one for this corpus is **mode B — give the mechanism in one
or two sentences, hold the consequences** — which is also the more TLA+-native
framing, since you model a stated protocol and let the checker tell you what it
permits.

Budget roughly an hour of editorial work per problem, and expect to write the
setup in the learner's own domain rather than quoting the report, because the
report's setup is a database.

The **compare-against half is excellent** where it exists, and better than
anything a hand-written exercise can offer: Jepsen names the anomaly, links a
machine-readable history, links the upstream issue, and usually names the fix.
So the learner can check not only "did I find a break" but "did I find *the*
break, and is my fix the one they shipped". Two reports go further and ship
their own green case — Hazelcast §3.6 re-runs the same test with a commutative
merge and reports it valid, and Chronos names `--offer_timeout` as the fix — so
the model becomes a red→green pair rather than a bug hunt.

One practical warning: evidence does not always survive as text. RavenDB
§3.2/§3.3 and FaunaDB §4.9/§4.11 present their anomalies as diagrams and plots,
so the trace has to be reconstructed by hand. Crate, RavenDB §3.1, TiDB, MongoDB
§3.2, MySQL §3.5, RDS §4, jetcd and Bufstream are all fully textual.

## Verdict

**Secondary source.** Not the spine of a curriculum, and not to be dropped.

The honest arithmetic is that 50 reports yield about 12 strong problems, of
which about 7 are genuinely not about a store's read/write visibility. That is a
real supply — enough for a solid module, not enough for a course — and it comes
at a per-problem editorial cost of roughly an hour, because the description and
the diagnosis have to be separated by hand and the situation has to be restated
out of database terms. What the family offers that nothing else does is a
*published, cited, checkable ground truth*: a named anomaly, a linked
machine-readable history, an upstream issue number, and often the shipped fix.
For the "model it, find the break, then compare" format, that is the expensive
half and Jepsen has already paid it. But the family is monotonic in subject
matter — 47 of 50 reports are about one property class — so it cannot carry
`lifecycle`, `expiry`, `rollout` or `workflow`, and it will not, on its own,
give the learner problems that look like the services he ships. Use the seven
service-shaped ones as a spine for a "distributed hazards" module, keep the
store-shaped eleven in reserve, and source the missing shapes elsewhere.

**What would change my mind toward primary**: if the learner turns out to *like*
the isolation vocabulary rather than resent it. It is a genuinely useful
formalism for anyone who writes against a store, and if it lands, the yield goes
from ~12 to ~40 because the whole corpus opens up. That is cheap to test: give
him CockroachDB §2.5 and RDS §4 — both have jargon-free traces and plain-language
framings that Kyle wrote himself — and see whether "which order did these become
visible in, and to whom" reads as interesting or as academic. His answer settles
it.

**What would change my mind toward dropping**: if the editorial cost turns out
to run well past an hour a problem, or if the first two he tries land as
"database trivia" despite the restatement. In that case the family's one real
asset — the free ground truth — is not paying for the work it takes to expose
it, and problems written from his own domain will beat it.
