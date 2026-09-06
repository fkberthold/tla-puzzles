# Survey: semantics documents as formal-modeling practice problems

**Status**: COMPLETE (2026-09-06). Written incrementally so partial work would
have survived a dead session.

**Question**: do transaction-isolation documentation, Kafka KIPs, catalogued
real-world bug studies, and *Designing Data-Intensive Applications* supply
problems at the altitude a working backend / industrial-IoT engineer reasons
at — services, stores, queues, lifecycles — for a learner ~11 chapters into
learntla who has rejected search puzzles, classic algorithms, and distributed
consensus protocols?

Every load-bearing claim carries a URL, a paper section, a quoted phrase, or
the literal marker `INFERRED`.

## Method

Sources are read directly rather than through summaries wherever the raw text is
fetchable. Hermitage's per-database files were downloaded with `curl` and read in
full, so the interleavings quoted below are the repository's own text. The Kafka
KIPs were read from `cwiki.apache.org`. The existing-spec check ran against the
GitHub trees API rather than against memory.

Denominators are stated for every count. Where I could not read a source (a
paywalled paper, a book I do not have) the entry says so and the claim is marked
`INFERRED` or dropped.

### A framing decision that governs the whole survey

There are two ways to turn an isolation anomaly into a TLA+ problem, and they are
not the same problem.

**(a) Model the mechanism.** State the database's concurrency control — MVCC
snapshots, row locks, first-committer-wins, SSI's dangerous-structure detection —
and check that the level prevents the anomaly. This is database internals. It is
the same objection the learner already raised against classic algorithms, one
domain over.

**(b) Model the application against a given isolation level.** Take the isolation
level as an *environment assumption* — a nondeterministic scheduler that is
allowed to produce exactly the interleavings that level permits — and check
whether the *application's* invariant survives. The thing being specified is the
service, and the isolation level is the platform it runs on.

Every isolation candidate below is scored under **(b)**. Under (a) I would drop
the family. This distinction is mine, not the sources'; the sources describe the
mechanism because they are documenting databases. `INFERRED`


## 1. Transaction isolation anomalies

**Supply: 10 named anomalies, each with at least one concrete runnable
interleaving, over a fixed 2-row schema.** This is the strongest sub-family in
the survey and the lead in the brief holds up. Evidence below.

### The source

Martin Kleppmann, *Hermitage*, <https://github.com/ept/hermitage>. Stated
purpose: "an attempt to nail down precisely what different database systems
actually mean with their isolation levels" (`README.md`). Started "as background
research for his book, Designing Data-Intensive Applications" (`README.md`), so
sub-families 1 and 4 share a root.

The anomaly names and their glosses are the README's own legend, verbatim:

| code | README gloss |
|---|---|
| G0 | Write Cycles (dirty writes) |
| G1a | Aborted Reads (dirty reads, cascaded aborts) |
| G1b | Intermediate Reads (dirty reads) |
| G1c | Circular Information Flow (dirty reads) |
| OTV | Observed Transaction Vanishes |
| PMP | Predicate-Many-Preceders |
| P4 | Lost Update |
| G-single | Single Anti-dependency Cycles (read skew) |
| G2-item | Item Anti-dependency Cycles (write skew on disjoint read) |
| G2 | Anti-Dependency Cycles (write skew on predicate read) |

Definitions are not Kleppmann's own: the README says the project "is based on the
formal definition of weak isolation introduced by Adya, as extended by Bailis et
al." Adya, "Generalized Isolation Level Definitions", ICDE 2000,
<https://pmg.csail.mit.edu/papers/icde00.pdf>. Berenson et al., "A Critique of
ANSI SQL Isolation Levels", SIGMOD 1995,
<https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/tr-95-51.pdf>.

### Does every anomaly have a concrete interleaving? Yes — counted

Downloaded 2026-09-06 from `raw.githubusercontent.com/ept/hermitage/master/`.
` ```sql ` fenced blocks per file:

| file | fenced sql blocks |
|---|---|
| `sqlserver.md` | 43 |
| `mysql.md` | 28 |
| `cockroachdb.md` | 23 |
| `postgres.md` | 22 |
| `yugabytedb.md` | 22 |
| `oracle.md` | 21 |
| `tidb.md` | 17 |
| `foundationdb.md` | 0 (not SQL-fenced) |
| `memgraph.md` | 0 (Cypher; file is a stub, 33 lines) |
| **total** | **176** |

`postgres.md` has 22 blocks, of which 2 are setup (`create table` and
`select current_setting`), leaving **20 interleavings covering all 10 anomalies**
— several anomalies appear twice, once at a level that permits them and once at a
level that prevents them. Counted by hand from the file's section headings: G0 1,
G1a 1, G1b 1, G1c 1, OTV 1, PMP 4, P4 2, G-single 4, G2-item 2, G2 3 = 20.

So the honest denominator is **10 distinct anomalies**, not 176. The 176 blocks
are the same 10 problems re-run across 9 databases and 3-6 isolation levels each.
That redundancy is not waste — it is the ground-truth oracle, see below.

### The fixture is tiny and identical for every anomaly

`postgres.md`, verbatim:

```sql
create table test (id int primary key, value int);
insert into test (id, value) values (1, 10), (2, 20);
```

Two rows, one integer column. Every one of the 10 anomalies is exhibited against
that fixture. A TLA+ model needs a function `id -> value` over a 2-element
domain, plus per-transaction bookkeeping. This is the smallest per-problem state
of anything in this survey.

### The candidates

Sizes below count **actors** (concurrent transactions) and **state pieces** a
model would need. All ten share: committed store (`[Id -> Value]`, |Id| = 2),
per-transaction status (`active` / `committed` / `aborted`), per-transaction
read/write set. The differences are what each anomaly adds.

---

**G0 — Write Cycles (dirty write)**
Source: Hermitage `postgres.md` §"Read Committed basic requirements", plus
Berenson §3 P0.
Situation: two writers each update two shared records, and the store must not end
up with one record from each writer.
Property: the final committed store equals the store some single writer left it
in — no interleaved-write result exists.
Anomaly: `update test set value = 11 where id = 1; -- T1` then
`update test set value = 22 where id = 2; -- T2` committing in an order that
leaves `1 => 11, 2 => 22`. Concrete interleaving: yes, `postgres.md` shows the
prevented form (T2 BLOCKS) rather than the anomalous one, so the anomalous trace
must be constructed. Hermitage shows it as prevented at every level of every
database in the table — G0 has a `✓` in every row.
Shape: `concurrency`
Size: 2 transactions, 2 records, 1 lock-holder field. Smallest in the family.
Ground truth: the README table's G0 column is all `✓`, so a model that permits G0
under read-committed contradicts nine databases at once.
**Weakness**: because it is universally prevented, there is no interesting
"which level allows this" question. Good as a warm-up, poor as a puzzle.

---

**G1a — Aborted Read (dirty read)**
Source: Hermitage `postgres.md` §"Read Committed basic requirements".
Situation: a reader observes a value a writer wrote and then rolled back.
Property: no committed transaction's read set contains a value written by a
transaction that aborted.
Anomaly: verbatim —
`update test set value = 101 where id = 1; -- T1` / `select * from test; -- T2.`
under read uncommitted returns `1 => 101` / `abort; -- T1`.
Concrete interleaving: yes, both prevented (Postgres) and permitted (MySQL "read
uncommitted", `mysql.md`) forms are in the repo.
Shape: `concurrency`
Size: 2 transactions, 1 record, abort flag. Tiny.
Ground truth: the README table — `—` at MySQL/SQL Server/Memgraph "read
uncommitted", `✓` everywhere else.

---

**G1b — Intermediate Read**
Source: Hermitage `postgres.md` §"Read Committed basic requirements".
Situation: a reader observes a value that a still-running writer later overwrites
before committing, so the reader saw a state that was never a commit point.
Property: every value a transaction reads was the value at some commit boundary,
never a mid-transaction intermediate.
Anomaly: T1 writes 101, T2 reads, T1 writes 11, T1 commits. A reader that sees
101 has read an intermediate. Concrete interleaving: yes.
Shape: `concurrency`
Size: 2 transactions, 1 record, plus a per-transaction *write sequence* rather
than a single write — this is the first anomaly that needs a transaction to write
the same key twice.
Ground truth: README table column G1b.
**Note**: G1a and G1b are close enough that they are probably one problem with
two invariants, not two problems.

---

**G1c — Circular Information Flow**
Source: Hermitage `postgres.md` §"Read Committed basic requirements".
Situation: two in-flight transactions each read what the other wrote, so neither
can be said to have run first.
Property: the reads-from relation over committed transactions is acyclic.
Anomaly: T1 writes id=1, T2 writes id=2, T1 reads id=2 seeing T2's value, T2
reads id=1 seeing T1's value. Concrete interleaving: yes (shown prevented — both
selects return the pre-values).
Shape: `concurrency`
Size: 2 transactions, 2 records, plus a **dependency edge set** — the first
anomaly whose property is not a state predicate but a property of the history.
Ground truth: README table column G1c.
**This is the family's difficulty step-change.** G0-G1b are checkable as state
invariants over the store. G1c onward need history in the state. A learner ~11
chapters into learntla has met history variables; this is where they earn their
keep. `INFERRED`

---

**OTV — Observed Transaction Vanishes**
Source: Hermitage `postgres.md` §"Observed Transaction Vanishes".
Situation: a reader sees one half of a two-record write and then, later in the
same reader, fails to see the other half — an atomic write appears to come apart.
Property: if a reader observes any effect of a committed transaction, it observes
all of that transaction's effects (atomic visibility).
Anomaly: three transactions. Verbatim from `postgres.md`, the *prevented* form:
`select * from test where id = 1; -- T3. Shows 1 => 11` /
`select * from test where id = 2; -- T3. Shows 2 => 19` — T3 sees T1's writes to
both rows. The anomaly is T3 seeing T1's row 1 and T1's *predecessor's* row 2.
Concrete interleaving: yes, and it is the only anomaly in the set needing **three**
transactions.
Shape: `two-store` (two records that must be seen consistently) or `concurrency`.
I score it `two-store` because the property is agreement between two places, which
is the shape a working engineer meets as cache-and-database.
Size: 3 transactions, 2 records, per-reader snapshot. Largest of the ten.
Ground truth: README table column OTV — `✓` everywhere except MySQL/SQL Server
"read uncommitted".
**This is the best single candidate in the family.** Atomic visibility is exactly
the property an application engineer needs from a two-table write, the property
has an obvious application statement, and it is the anomaly whose name most
engineers cannot define off-hand.

---

**PMP — Predicate-Many-Preceders (phantom)**
Source: Hermitage `postgres.md` §"Predicate-Many-Preceders"; also the PostgreSQL
manual's own `website` example.
Situation: a query over a predicate is evaluated twice in one transaction and
returns a different row set, because another transaction inserted a matching row.
Property: within one transaction, a predicate query's result set does not grow.
Anomaly: verbatim —
`select * from test where value = 30; -- T1. Returns nothing` /
`insert into test (id, value) values(3, 30); -- T2` / `commit; -- T2` /
`select * from test where value % 3 = 0; -- T1. Returns the newly inserted row`.
Concrete interleaving: yes, four of them in `postgres.md` alone (read/write
predicate × permitted/prevented).
Shape: `concurrency`
Size: 2 transactions, **unbounded record domain** — this is the one anomaly whose
model cannot use a fixed 2-row store, because the anomaly is an insert. Needs
`Id` large enough to hold a third row, and a predicate as a first-class model
object.
Ground truth: README table column PMP, plus the R/O caveat on MySQL "repeatable
read": "isolation level prevents this anomaly in a read-only context, but when
you perform writes, the anomaly can occur".
**The PostgreSQL manual carries an independent second example**: with `website`
a two-row table with `hits` of 9 and 10, `UPDATE website SET hits = hits + 1`
concurrent with `DELETE FROM website WHERE hits = 10` — "The DELETE will have no
effect even though there is a website.hits = 10 row before and after the UPDATE"
(<https://www.postgresql.org/docs/current/transaction-iso.html>, §13.2.1). Two
independent statements of the same anomaly is unusually good grounding.

---

**P4 — Lost Update**
Source: Hermitage `postgres.md` §"Lost Update (P4)"; Berenson §4.
Situation: two clients read a counter, each computes a new value, each writes it,
and one increment disappears.
Property: the final value reflects every committed write's *read-modify-write*,
so a counter incremented by n committed transactions has increased by n.
Anomaly: verbatim — both transactions `select * from test where id = 1`, then
both `update test set value = 11 where id = 1`, "commit; -- T1. This unblocks T2,
so T1's update is overwritten". Concrete interleaving: yes, both forms.
Shape: `concurrency`
Size: 2 transactions, 1 record, per-transaction read value. Second smallest.
Ground truth: README table column P4.
**The most familiar problem in the family** and therefore possibly the least
instructive — a working engineer already knows this one. Its value is as the
calibration problem: if the model of read-committed does not exhibit lost update,
the model is wrong.

---

**G-single — Read Skew**
Source: Hermitage `postgres.md` §"Read Skew (G-single)".
Situation: a reader reads two related records and a writer commits a change to
both in between, so the reader sees a pair that never coexisted.
Property: a transaction's reads all come from one committed store state.
Anomaly: verbatim — `select * from test where id = 1; -- T1. Shows 1 => 10` /
T2 sets id=1 to 12 and id=2 to 18 and commits /
`select * from test where id = 2; -- T1. Shows 2 => 18`. T1 has now seen the
old row 1 and the new row 2. Concrete interleaving: yes, four in `postgres.md`.
Shape: `two-store`
Size: 2 transactions, 2 records, reader snapshot. Small.
Ground truth: README table column G-single; note the `some` at SQL Server
"repeatable read", legend "isolation level prevents this anomaly in some cases,
but not in others", which is a genuinely interesting model question.
**This is the one whose real-world statement is cleanest**: the two records are
two accounts and the invariant is that their sum is constant. That framing is not
in Hermitage — it is DDIA's. See §4.

---

**G2-item — Write Skew on disjoint reads**
Source: Hermitage `postgres.md` §"Write Skew (G2-item)".
Situation: two transactions each read the same pair of records, each concludes it
is safe to change *its own* record, and together they break a constraint that
spans both.
Property: an invariant over both records (e.g. "at least one is below 20") holds
in every committed state.
Anomaly: verbatim — both `select * from test where id in (1,2)`, then
`update test set value = 11 where id = 1; -- T1` and
`update test set value = 21 where id = 2; -- T2`, both commit. Under snapshot
isolation both succeed. Concrete interleaving: yes, permitted and prevented.
Shape: `concurrency`
Size: 2 transactions, 2 records, per-transaction snapshot. Small.
Ground truth: README table column G2-item — `—` at every snapshot-isolation row
and `✓` only at serializable. That column is the family's sharpest signal: it is
exactly the column that separates "snapshot isolation" from "serializable".
**The single most valuable anomaly for a working engineer.** Write skew is the
one an application engineer will actually hit, because it is the one that
survives the isolation level most people configure. It is also the one with the
best independent statement (the on-call doctors, §4).

---

**G2 — Anti-Dependency Cycles on predicate reads**
Source: Hermitage `postgres.md` §"Anti-Dependency Cycles (G2)"; PostgreSQL manual
§13.2.3.
Situation: two transactions each query a predicate and each insert a row that
would have changed the other's answer.
Property: the committed outcome is consistent with some serial order.
Anomaly: verbatim — both `select * from test where value % 3 = 0`, then
`insert (3, 30)` in T1 and `insert (4, 42)` in T2, both commit.
Concrete interleaving: yes, three in `postgres.md`, including "Fekete et al's
example with two anti-dependency edges" which is a **three**-transaction trace.
The PostgreSQL manual carries the independent `mytab` class/value version:
"if A had executed before B, B would have computed the sum 330, not 300".
Shape: `concurrency`
Size: 2-3 transactions, growable record domain, predicates as objects, and a
serializability check that needs the dependency graph. **Largest and hardest.**
Ground truth: README table column G2 — `✓` only at serializable, plus the
`some` at Oracle, legend "prevents this anomaly in some cases, but not in others".
**The right final problem in the ladder** and probably beyond one sitting.

---

### The ordering claim, tested

The brief asks whether there is "a clean ordering from easy to hard". There is,
and it is not the alphabetical G0..G2 order. Ordering by what the model has to
carry:

1. **State-predicate tier** — the property is an invariant over the committed
   store alone. G0, P4. 2 transactions, 1-2 records.
2. **Snapshot tier** — the model needs a per-transaction read snapshot, and the
   property compares the snapshot to the store. G1a, G1b, G-single, OTV.
3. **History tier** — the property is over the *relation between* transactions,
   not over any state. G1c (reads-from acyclicity), G2-item (an invariant no
   single transaction violates).
4. **Predicate tier** — the record domain grows, and predicates become model
   objects. PMP, G2.

That is a real four-step ladder, each step adding one modelling technique.
**Confirmed**, on the evidence of the interleavings themselves. `INFERRED` for
the tier assignment, which is my reading of what each model needs rather than
anything the sources say.

### The honest weaknesses

- **Redundancy.** Ten anomalies, but G1a/G1b are one problem, and G-single/OTV
  are close. The distinct-technique count is nearer **six or seven** than ten.
- **Isolation level as environment.** Framing (b) works only if the model can
  express "the scheduler may do anything read-committed permits" without
  modelling read-committed's mechanism. That is a real modelling question I have
  not tested. It is the thing to spike first. `INFERRED`
- **The mechanism trap.** Half the Hermitage material is about which database
  does what, which is the wrong altitude for this learner. The problem statements
  have to be written from the *anomaly*, not from the table.
- **Existing specs: the mechanism side is thoroughly specified, and this is the
  strongest single argument for framing (b).** Found on 2026-09-06:
  - `will62794/snapshot-isolation-spec` — "A formal specification of snapshot
    isolation" (repo description), `SnapshotIsolation.tla` + `.cfg` + models +
    traces, last pushed 2025-07-17. Its README states it carries "Two
    concurrency anomalies that snapshot isolation allows, Write Skew and a
    'read only' transaction anomaly ... with examples", and the main invariant
    is `IsSerializable(txnHistory)`. **So G2-item is already a published,
    checkable TLA+ property.**
  - `pron/amazon-snapshot-spec` — Chris Newcombe's Amazon specs,
    `textbookSnapshotIsolation.tla` and `serializableSnapshotIsolation.tla`,
    plus his "Debugging Designs" HPTS 2011 paper. Mirrored at
    `sanjosh/tlaplus/amazon/`.
  - `tlaplus/Examples/specifications/SnapshotIsolation/README.md` is a pointer
    to that same `serializableSnapshotIsolation.tla` — so the canonical examples
    repository links to it. (The directory holds only the README; the survey's
    424-module count for `tlaplus/Examples` is unaffected.)

  **Under framing (a) the isolation family is dead**: the reference specs
  already exist, are well documented, and will be the first search result the
  learner hits. **Under framing (b) none of them collide**, because none of them
  models an application on top of an isolation level.

  There is also a state-space warning in that README that framing (a) cannot
  escape. Finding the read-only anomaly took "1 hour and 4 minutes running TLC
  on a 12-core ... workstation. It generated a bit over 405 million distinct
  states and it took a 12 step trace to violate the invariant." That is with
  3 transactions, 2 keys and 2 values under symmetry. A learner who models the
  mechanism inherits that cost; a learner who models the application against a
  permitted-interleaving oracle does not.


## 2. Kafka KIPs and delivery semantics

**Supply: 4 usable candidates after removing everything already specified.**
Smaller than the isolation family and much more work per candidate, but two of
the four are excellent.

### The existing-spec check ran first, and it removes the obvious picks

`Vanlightly/kafka-tlaplus` is a public repository of "TLA+ specifications for
Kafka related algorithms" (its whole README). Listed via the GitHub trees API on
2026-09-06, `GET /repos/Vanlightly/kafka-tlaplus/git/trees/main?recursive=1`,
filtered to `*.tla` — 29 modules:

| area | modules | status for this survey |
|---|---|---|
| `groupprotocol/consumer_group_protocol_kip_848.tla` (+ `_v2`) | 2 | **KIP-848 is spec'd. Dropped.** |
| `kafka_data_replication/kraft/v3.5/*` and `kip-966/*` | 10 | replication + ELR spec'd. Dropped. |
| `kraft/kip_853/*`, `kraft/kip_996/*` | 10 | KRaft consensus spec'd, and consensus is out of scope anyway. |
| `transactions/diary/01_InitPidRequest/*` | 2 | producer-id acquisition spec'd. |
| `transactions/diary/02_AddPartitionsToTxn/*` | 2 | partition enrolment spec'd. |

The transactions work is a public diary series and it **stops at entry 02**.
`GET /repos/Vanlightly/kafka-tlaplus/contents/transactions/diary` returns exactly
two directories, `01_InitPidRequest` and `02_AddPartitionsToTxn`. The author
states the scope limit himself: "Fencing is not included in this initial model
though"
(<https://jack-vanlightly.com/analyses/2024/12/3/verifying-kafka-transactions-diary-entry-2-writing-an-initial-tla-spec>),
and explains why the whole thing was not attempted — extending the replication
spec would be "too big, complex and the state space would be impractical".

So the parts of the Kafka transaction story that are **not** spec'd are exactly
the parts a working engineer cares about: fencing a zombie producer, the
commit/abort marker, and the consumer offset commit. Those are the candidates.

Also dropped on the same grounds: KIP-101 leader epochs and log truncation
(covered by `kafka_data_replication/kraft/v3.5`), and anything KRaft.

### The candidates

---

**K1 — Consumer offset commit: at-most-once versus at-least-once**
Source: Apache Kafka design documentation, "Message Delivery Semantics",
`docs/design/design.md` on `apache/kafka@trunk`, read raw on 2026-09-06.
Situation: a worker reads items from a durable ordered log, does something with
each, and records how far it got. It may crash at any point.
Property: **at-least-once** — every item the log holds is processed at least
once by some worker. Or, at the learner's choice, **at-most-once** — no item is
processed twice. Not both.
Anomaly and the trace, verbatim from the documentation:
> "It can read the messages, then save its position in the log, and finally
> process the messages. In this case there is a possibility that the consumer
> process crashes after saving its position but before saving the output of its
> message processing. In this case the process that took over processing would
> start at the saved position even though a few messages prior to that position
> had not been processed. This corresponds to 'at-most-once' semantics"

> "It can read the messages, process the messages, and finally save its
> position. In this case there is a possibility that the consumer process crashes
> after processing messages but before saving its position. In this case when the
> new process takes over the first few messages it receives will already have
> been processed. This corresponds to the 'at-least-once' semantics"

Concrete interleaving: **yes, in prose, and both directions of it.** This is the
single clearest problem statement in the whole survey — two orderings of two
steps, each with its named consequence spelled out by the source.
Shape: `delivery`
Size: 1 log (a sequence), 1 consumer with a crash action, 1 committed offset, 1
set of side effects performed. **Two actors if you model handover to a
successor.** The smallest problem in sub-family 2 and comparable to the smallest
isolation ones.
Ground truth: the documentation names the outcome of each ordering. A model that
gets `at-most-once` from process-then-commit has the arrows backwards.
**The best entry point in this sub-family**, and it generalises off Kafka
completely — this is the same problem as an SQS consumer, a cron job with a
watermark, or an industrial poller with a "last successfully read" register.

---

**K2 — Zombie fencing after a rebalance (KIP-447)**
Source: <https://cwiki.apache.org/confluence/display/KAFKA/KIP-447:+Producer+scalability+for+exactly+once+semantics>
Situation: a worker owns a work partition, pauses long enough to be declared
dead, the partition is reassigned to a second worker, and the first worker wakes
up and finishes the write it started.
Property: for each partition, at most one worker's writes are accepted, and the
accepted writes are the current owner's. Stated in the KIP as "only one producer
instance per transactional ID may actively progress at any time".
Anomaly and trace: the KIP gives an ordered scenario — client A pauses mid-commit
of offsets for P1, A's session times out, the group rebalances, B takes P1,
B sees no pending offsets so it reprocesses data A had already handled, and then
A wakes and retries its commit. Concrete interleaving: **yes, as an ordered
list of 5 steps.**
Shape: `lifecycle` (ownership handover) with an `expiry` component (the session
timeout is what makes A a zombie).
Size: 2 workers, 1 partition, a group generation counter, a per-worker "my
generation", a committed-offset store. 2 actors, 4 state pieces.
Ground truth: the KIP names the fix — generation ID, member ID, group instance
ID compared at the coordinator — so a model whose invariant survives *without*
the generation check contradicts the KIP.
**Second best in this sub-family** and the most transferable. This is the
distributed-lock / lease / "only one worker touches this device" problem the
learner's own domain is full of. Note the sibling: the Jepsen survey's etcd lock
candidate is the same problem from the lock side. If both surveys keep it, one
of them should be dropped.

---

**K3 — Hanging transactions from a delayed write (KIP-890)**
Source: <https://cwiki.apache.org/confluence/display/KAFKA/KIP-890%3A+Transactions+Server-Side+Defense>
Situation: a client writes into a batch, the batch is aborted, and a write from
that batch arrives afterwards and lands in the *next* batch.
Property: every accepted write belongs to the batch that was open when the
client issued it; no write crosses a batch boundary.
Anomaly: quoting the KIP's own consequence — "the last stable offset (LSO) does
not update, we can't clean the log (if the topic is compacted), and read_committed
consumers get stuck". Cause one is "a message gets delayed due to networking
issues or partition. The transaction aborts, then the delayed message arrives
afterward." Cause two is a client that "writes to a partition before explicitly
adding it to the transaction".
Concrete interleaving: **partial.** The KIP states the cause in one or two
sentences per case, not as a numbered trace. The trace has to be constructed,
which is more work than K1 or K2 but is not open-ended.
Shape: `delivery`
Size: 1 producer, 1 broker partition, 1 coordinator, a delayed-message channel,
an epoch counter. 3 actors. Larger.
Ground truth: the KIP's fix is stated as an invariant — "Uniquely identify
transactions by bumping the producer epoch after every commit/abort marker. That
way, each transaction can be identified by (producer id, epoch)." A model in
which the epoch bump does *not* close the hole has a bug in the model.
**Flag**: the AddPartitionsToTxn half of this is adjacent to Vanlightly's
`02_AddPartitionsToTxn` spec. Not the same model, but overlapping, so check
before spiking.

---

**K4 — Cooperative rebalancing without double ownership (KIP-429)**
Source: <https://cwiki.apache.org/confluence/display/KAFKA/KIP-429%3A+Kafka+Consumer+Incremental+Rebalance+Protocol>
Situation: a set of work items is shared out among a changing set of workers, and
the assignment must change without ever giving one item to two workers and
without stopping every worker to do it.
Property: quoting the KIP's own constraint — "any topic partition could not be
re-assigned before it is revoked", i.e. each partition has exactly one owner at
every instant.
Anomaly: the eager protocol satisfies the property by stopping the world;
the cooperative protocol keeps working during the rebalance and so has to prove
the property holds across a *multi-round* assignment.
Concrete interleaving: **no.** The KIP describes the desired protocol, not a
failure trace. That makes it a design problem rather than a bug-reproduction
problem — a different and harder kind of exercise.
Shape: `rollout` (an assignment moving across a fleet) or `resource`.
Size: 2-3 workers, 2-4 partitions, per-worker owned set, a coordinator's
assignment, a generation counter. Largest in this sub-family.
Ground truth: **weak.** No trace to reproduce, and the closest thing to an oracle
is KIP-848's spec, which is a *different* protocol.
**Recommend dropping.** The property is good and the shape is right, but with no
documented failure and an adjacent already-spec'd protocol, this is a design
exercise dressed as a puzzle.

---

**Not carried forward**: the idempotent producer's sequence numbers (KIP-98).
The design documentation states the mechanism — "the broker assigns each producer
an ID and deduplicates messages using a sequence number that is sent by the
producer along with every message" (`docs/design/design.md`) — but the
interesting failures around it (`OutOfOrderSequenceException`, producer-id
expiry) are not narrated in the KIP, and the mechanism as stated is a two-line
model with no anomaly. `INFERRED`

### Honest assessment of sub-family 2

- **Supply is 4, of which I would keep 3.** Against 10 for isolation.
- **Cost per candidate is higher.** Every one of these needs the learner to be
  told what a partition, a coordinator, a generation and a producer epoch are
  before the problem is stateable. The isolation problems need "two rows and two
  transactions".
- **The best two (K1, K2) are not really about Kafka.** K1 is the commit-order
  problem and K2 is the lease problem. That is a strength for transfer and a
  weakness for grounding — once you strip Kafka out, Kafka's documentation stops
  being the oracle.
- **The already-spec'd list is long and includes the obvious first picks.**
  Anyone reaching for "model Kafka" reaches for the consumer group protocol or
  KRaft, and both are done.


## 3. Catalogued bug studies

**Supply: thousands catalogued, roughly 35 narrated in prose across the four
papers read, of which about 15 are both modelable from the paper alone and
outside the consensus family the learner rejected.**

This is the sub-family where the gap between the headline number and the usable
number is largest, and where the brief's question 3 has a specific answer.

### The papers read, with denominators

| paper | venue | catalogued | systems | read how |
|---|---|---|---|---|
| Alquraan et al., "An Analysis of Network-Partitioning Failures in Cloud Systems" | OSDI '18 | 136 failures | 25 | full PDF, <https://www.usenix.org/system/files/osdi18-alquraan.pdf> |
| Yuan et al., "Simple Testing Can Prevent Most Critical Failures" | OSDI '14 | 198 failures | 5 | full PDF, <https://www.usenix.org/system/files/conference/osdi14/osdi14-paper-yuan.pdf> |
| Lu et al., "CrashTuner" | SOSP '19 | 52 studied + 21 new | 5 | full PDF, <https://www.cs.otago.ac.nz/cosc440/readings/crashTuner.pdf> |
| Leesatapornwongsa et al., "TaxDC" | ASPLOS '16 | 104 bugs, "2,083 classification labels" | 4 | **not read** — the UChicago host fails TLS chain validation from this environment. Counts from the ACM abstract, <https://dl.acm.org/doi/10.1145/2872362.2872374>. |
| Gunawi et al., "What Bugs Live in the Cloud?" (CbsDB) | SoCC '14 | 3,655 vital issues of 21,399 reviewed | 6 | ;login: version read, <https://www.usenix.org/system/files/login/articles/login_aug15_08_gunawi.pdf> |

**Total catalogued across the five: ~4,145 issues.** That is the headline. Now
the honest number.

### Question 3, answered: how many can you model from the paper alone?

**Counted by hand from the OSDI '18 paper's own prose**, which is the best of the
five for this purpose. Sections 4.1-5.3 narrate **20 distinct failures**, each
attached to a numbered issue-tracker citation. Of those 20:

- **6 are one-sentence vignettes** with no mechanism — the Riak partial-write
  warning [67], the MongoDB socket exception [68], the Redis sync corruption
  [83], and three similar. Not modelable from the paper.
- **4 are leader-election failures** — the MongoDB arbiter thrash [80], the
  Elasticsearch dual leader [81], the RethinkDB Raft-log deletion [72], and the
  "electing a bad leader" family. Modelable, but they are consensus, which the
  learner has rejected.
- **10 carry a complete mechanism in prose and are outside consensus.** Those
  are the usable ones, listed below.

So the ratio for the best paper in the set is **10 usable out of 136 catalogued,
about 7%.** Extrapolating the same ratio across ~4,145 catalogued issues would
give ~290 candidates, but that extrapolation is wrong and I will not make it:
the 10 are usable *because the authors chose to narrate them*, and every paper
narrates only a dozen or two regardless of catalogue size. **The narrated set,
not the catalogued set, is the supply.** Across all five papers the narrated set
is roughly 35, and the usable subset roughly 15.

The catalogues' real value is as an **index into issue trackers** — every entry
carries a JIRA or GitHub issue ID, and the issue thread does contain enough to
model. That is a different source with a much higher per-item cost, since it
means reading a bug thread rather than a paper section. CrashTuner ships
reproduction instructions: "The website https://github.com/lujiefsi/CrashTuner
shows how to repro..." (paper footnote 1). CbsDB "is publicly available"
(;login: article, reference [1] → `ucare.cs.uchicago.edu/projects/cbs/`) — I
could not open it from here, TLS chain failure, so I cannot say what its entries
contain beyond "a set of rich classifications". `INFERRED` that it is labels
plus issue IDs rather than prose.

### The usable candidates

---

**B1 — Commit-permission window (CrashTuner Figure 3, MR-3858)**
Source: CrashTuner §2.2, Figure 3, <https://www.cs.otago.ac.nz/cosc440/readings/crashTuner.pdf>
Situation: a worker asks a coordinator for permission to commit, gets it, starts
committing, and crashes before reporting done. A replacement worker is started
for the same task.
Property: a task's result is committed exactly once, and a crashed attempt is
always recoverable by a fresh attempt.
Anomaly, and the paper gives it as a **numbered 6-step trace**: node1 sends
`commitPending` and gets attempt_1 recorded; node1 sends `startCommit`; node1
crashes so `doneCommit` never arrives; AM starts node2 with attempt_2; node2
sends `commitPending`; "node2 fails the commit checking and is then killed by
AM@node0." The paper states the boundary precisely: "If node1 crashes after
doneCommit, attempt_1 is committed to the global state and no recovery is
needed. If the crash happens before commitPending, the recovery process will
fork another attempt instance, which will correctly redo the task. However, if
node3 crashes in the small time window between the two RPCs, the commit status
commit is contaminated. The recovery process always fails, and the job will never
finish."
Shape: `workflow`
Size: 1 coordinator, 2 workers, a per-task commit-status record, a crash action.
2-3 actors, 3 state pieces.
Ground truth: the paper names the three crash windows and the outcome of each.
A model must reproduce all three, and the middle one must be the only bad one.
**The best single candidate in sub-family 3.** It is a two-phase-commit-shaped
problem stated entirely at the application level, with a stated safe region on
each side of the bad window — which is exactly the kind of thing an invariant
plus a well-chosen state space finds. And the failure is a *liveness* failure
("the job will never finish"), which is a genuine change of gear from the
isolation family's safety invariants.

---

**B2 — Check-then-use across a membership change (CrashTuner Figure 2, YARN-5918)**
Source: CrashTuner §2.1, Figure 2.
Situation: a registry of live nodes, a monitor that removes a node after a
heartbeat timeout, and a worker that looks a node up in the registry and uses
what it finds.
Property: every lookup of a node in the registry either fails cleanly or returns
a node that is still usable.
Anomaly, from the figure caption's 4 numbered steps: NM@node1 stops heartbeating;
the liveMonitor "detects the crash of node1 after a timeout period"; the recovery
thread "removes node1 from nodes"; "Another running thread job tries to get
resources of NM@node1" and gets null. The paper generalises the whole class:
"37 bugs belong to this scenario: Node M tries to read meta-info of node N
without knowing its availability, leading to aborts and job failures."
Shape: `expiry` (the timeout is what makes the entry disappear) with a
`lifecycle` reading.
Size: 1 registry, 2-3 nodes, a heartbeat/timeout action, a reader. Small.
Ground truth: **37 catalogued instances of the same shape**, listed by issue ID
in the paper's Table 1. That is unusual — most candidates in this survey have
one instance. A model that captures the shape is validated against 37 real bugs.
**Second best**, and the highest-leverage one in the survey by instances-per-model.

---

**B3 — Ack lost, retry executes twice (OSDI '18 §4.2, Elasticsearch [75])**
Source: <https://www.usenix.org/system/files/osdi18-alquraan.pdf> §4.2.
Situation: a request goes through a forwarding node to a primary; the primary
does the work; the acknowledgement back to the forwarder is lost; the forwarder
reports failure; the client retries.
Property: a write reported as failed did not happen, and a retried write happens
once.
Anomaly, verbatim: "If a primary completes the write operation but fails to send
an acknowledgment back to the coordinator, then the coordinator will assume the
operation has failed and will return an error code to the client. The next client
read will return the value written by a write operation that was reported to have
failed. Moreover, if the client repeats the operation, then it will be executed
twice."
Shape: `delivery`
Size: client, coordinator, primary, one lossy link. 3 actors, small state.
Ground truth: the quoted sentence names both consequences.
**Overlap warning**: this is the same problem as the Jepsen survey's jetcd
retry candidate and close to K1. Three surveys converging on the retry problem
is a signal that it is the canonical one, and also a signal that only one of the
three should ship.

---

**B4 — Two synchronisation paths that update different copies (OSDI '18 §4.2, ZooKeeper [74])**
Source: OSDI '18 §4.2.
Situation: a service keeps the same data in two places, a durable store and an
in-memory log, and has two catch-up mechanisms, one of which updates only one of
them.
Property: the two copies agree after any catch-up path completes.
Anomaly, verbatim: "storage synchronization that is used for syncing a large
amount of data, and in-memory log synchronization that is used for a small amount
of data. If node A misses many updates during a network partition, then ZooKeeper
will use storage synchronization to bring node A up to date. Unfortunately,
storage synchronization does not update the in-memory log. If A becomes a leader,
and other nodes use in-memory log synchronization, then A will replicate its
incomplete in-memory log."
Shape: `two-store`
Size: 2-3 nodes, per-node (store, memlog) pair, two sync actions. Small.
Ground truth: the quoted mechanism.
**The purest `two-store` problem found anywhere in this survey.** Two copies, two
update paths, one path forgets a copy. Strip ZooKeeper out and it is the
cache-and-database problem verbatim.

---

**B5 — Step down, delete, then the other side dies (OSDI '18 §4.4, Hazelcast [82])**
Source: OSDI '18 §4.4.
Situation: a replica promotes itself, is told to stand down, discards its local
data on the assumption that it can re-fetch from the real owner, and the owner
then dies.
Property: the system does not discard the last copy of the data.
Anomaly, verbatim: "That replica will step down, delete its data, and try to
download the data from the primary. If the primary permanently fails before the
partition heals, the data will be lost."
Shape: `lifecycle`
Size: 2 replicas, 1 master, per-replica data-present flag, a crash action. Tiny.
Ground truth: the quoted sentence.
**The smallest catastrophic-failure model in the survey** and a good early one.
The invariant — "at least one node holds the data" — is a one-line TLA+
expression and the counterexample is four steps.

---

**B6 — Fenced-off work continues on the far side (OSDI '18 §4.3, HBase [76])**
Situation: a worker is declared dead by its supervisor but is not dead, and keeps
appending to a new log the supervisor never learns about.
Property: every write the worker accepted is reachable by whoever takes over.
Anomaly, verbatim: "If a partial partition separates a region server from the
HMaster but not from HDFS, then the HMaster will assume that the region server
has crashed and will assign the region logs to other servers. At this time, if
the old region server creates a new log, HMaster will not be aware of the new log
and will not assign it to any region server. All client operations stored in the
new log will be lost."
Shape: `lifecycle`
Size: supervisor, 2 workers, a shared store, a log-set. 3 actors.
Ground truth: the quoted mechanism.
Note this is the zombie problem again, from the storage side rather than K2's
producer side.

---

**B7 — Double execution after a supervisor times out (OSDI '18 §4.4, MapReduce [78])**
Verbatim: "if a partial network partition isolates an AppMaster from the resource
manager while both can still communicate with the cluster nodes, the AppMaster
will finish executing the current task and return the result to the client. The
resource manager will assume that the AppMaster has failed and will rerun the
task using a new AppMaster. The new AppMaster will execute the task again and
send a second result to the client."
Property: a task produces one result.
Shape: `workflow`
Size: resource manager, 2 app masters, 1 client, a reachability relation.
The paper flags what makes this one distinctive: "Note that in this failure,
there is no client access after the network partition."

---

**B8 — A liveness bug from a retry policy that keeps choosing the same bad option
(OSDI '18 §4.4, HDFS [79])**
Verbatim: "If the NameNode allocates replicas on rack 0, then a client write
operation will fail, and the client will ask for a different replica. The
NameNode, following its rack-aware data placement, will likely suggest another
node from the same rack. The process repeats five times before the client gives
up."
Property: a client that can reach some valid placement eventually gets one.
Shape: `resource`
Size: 1 allocator, 1 client, a rack→node map, a reachability relation, a retry
counter. Small.
**The only pure allocation-policy problem in the survey**, and one of very few
whose property is naturally temporal.

---

**B9 — Half-open connection reads as healthy (OSDI '18 §4.3, HDFS [77])**
Verbatim: "in HDFS, a data node that can send a periodic heartbeat message but is
unable to receive requests is still considered a healthy node."
Property: a node the supervisor considers healthy can actually serve requests.
Shape: `expiry`
Size: 1 supervisor, 1 node, a directional reachability relation, a heartbeat
clock. Tiny.
**Good as a first problem in the family** — the whole bug is "liveness detection
tests the wrong direction", and the model is four or five lines.

---

**B10 — Stale generation stamp blocks replication forever
(OSDI '14 Figure 1, HDFS)**
Source: <https://www.usenix.org/system/files/conference/osdi14/osdi14-paper-yuan.pdf> Figure 1.
Situation: a queue of work items records an item's version at enqueue time; the
item is later modified and its version bumped; the queue's copy is not updated;
the worker refuses the job because the versions disagree.
Property: an under-replicated block eventually becomes replicated.
Anomaly, from the figure's own 3-step caption: "(1) the user uploads a data
block, causing HDFS to assign a generation stamp... adds it to needReplication
queue. (2) the user appends to this block, causing DN1 to increment the
generation stamp from 100 to 101. However, the generation stamp in the
needReplication queue is not updated – an error. (3) DN2 is started, so NN asks
DN1 to replicate the block to DN2. But since the generation stamps from
needReplication queue and DN1 do not match, DN1 keeps refusing to replicate."
Shape: `two-store`
Size: 1 name node, 2 data nodes, a queue holding (block, stamp), a per-node
stamp. Small.
Ground truth: the figure's trace.
**The best-drawn trace of any bug in the survey** — it is a sequence diagram with
the erroneous step labelled "an error".

---

### The finding that makes this family tractable

All four papers independently report that these bugs are small.

- OSDI '18: "A majority (83%) of the failures triggered by a network partition
  require an additional three or fewer input events to manifest" (Finding 7);
  "All failures can be reproduced on a cluster of five nodes, with the majority
  (83%) of the failures being reproducible with three nodes only" (Finding 12);
  "Only 7% of the failures are nondeterministic".
- OSDI '14: "A majority (77%) of the failures require more than one input event
  to manifest, but most of the failures (90%) require no more than 3"
  (Finding 1); 74% deterministic (Table 6); "almost all failures require only 3
  or fewer nodes to reproduce" (abstract).

Three nodes and three events is squarely inside TLC. That is a real, independent,
quantified argument that this family fits the tool, and it is the strongest
single piece of evidence in this document.

### The finding that removes most of the supply

OSDI '14's headline result disqualifies most of its own catalogue for this
purpose. Finding 10: "Almost all catastrophic failures (92%) are the result of
incorrect handling of non-fatal errors explicitly signaled in software", and
Figure 5 breaks that down as 35% "trivial mistakes" — "Errors ignored (25%)",
"Abort in over-caught exceptions (8%)", "'TODO' in handler (2%)".

**An empty catch block is not a TLA+ problem.** It is a code defect with no
interesting state space. The paper's own thesis — that a static checker finds
them — is the correct tool, and it is not this one. So of 198 failures, the
logic-level ones are a minority, and the paper narrates about three of them
(Figures 1, 2, 11).

The network-partitioning paper inverts this: "The resolution of 47% of the
failures required redesigning a system mechanism" (Finding 11), and Table 12 puts
design flaws at 46.6% against implementation flaws at 32.2%. **Design flaws are
exactly what a specification catches.** If only one bug-study paper is used, it
should be the OSDI '18 one.


## 4. Designing Data-Intensive Applications

**Supply: high, but every candidate needs a substitute source before it can
ship.** The brief asked what a problem drawn from DDIA would need in the way of
an independent description. The answer turns out to be simple, and it is the
reason this sub-family is worth having.

### The constraint

I do not have the book. Everything below is verified against **public sources
other than the book** — the chapter reference lists Kleppmann publishes at
<https://github.com/ept/ddia-references>, his own public blog posts, and
third-party reading notes. Where a claim rests only on a third-party note it is
marked. This is not a limitation to work around; it *is* the finding.

A problem drawn from DDIA needs an independent description because:

1. **The book is copyrighted and the learner may not have it.** A puzzle whose
   statement is "see DDIA p. 246" is not a puzzle.
2. **A restated scenario needs an oracle.** If the problem statement is
   paraphrased from the book, the answer has to be checkable against something
   else, or the only ground truth is the paraphrase.
3. **The good news**: for the three strongest DDIA scenarios, a public
   independent source already exists, and in two of the three Kleppmann wrote it
   himself. That converts them from book-derived problems into problems with
   ordinary citations.

### What each chapter carries

Verified from the published reference lists, which are the book's own citations
and therefore fix each chapter's subject matter.

- **Ch. 5, Replication** — `chapter-05-refs.md` cites version vectors, dotted
  version vectors, "Version Vectors Are Not Vector Clocks", conflict-free
  replicated JSON, and quorum papers. Subject: replication lag, read-your-writes,
  monotonic reads, consistent prefix reads, multi-leader conflict resolution,
  quorums, and concurrent-write detection.
- **Ch. 7, Transactions** — `chapter-07-refs.md` cites Gray et al. on degrees of
  consistency, Berenson et al. by way of the Hermitage bibliography, and Fekete
  et al. "Making Snapshot Isolation Serializable". Subject: exactly the anomalies
  of §1 of this survey. **Ch. 7 and Hermitage are the same material**; the README
  says Hermitage was "background research for his book".
- **Ch. 8, The Trouble with Distributed Systems** — `chapter-08-refs.md` cites
  "The Network Is Reliable", Gray and Cheriton's "Leases", Lamport's "Time,
  Clocks, and the Ordering of Events", hybrid logical clocks, and **eight**
  separate references about JVM garbage-collection pauses. Subject: unreliable
  networks, unreliable clocks, process pauses, leases, fencing.
- **Ch. 9, Consistency and Consensus** — `chapter-09-refs.md` cites Herlihy and
  Wing on linearizability, Attiya and Welch on sequential consistency versus
  linearizability, Helland's "Life Beyond Distributed Transactions", and two
  pieces on two-phase commit including Fowler's "Your Coffee Shop Doesn't Use
  Two-Phase Commit". Subject: linearizability, ordering guarantees, 2PC,
  distributed transactions.

### The candidates

---

**D1 — Two on-call doctors both go off call (Ch. 7, write skew)**
Situation: a scheduling service where each of two people independently checks
"is anyone else covering?", sees yes, and stands down.
Property: at least one person is on call at all times.
Anomaly: both read a snapshot showing two on call, both conclude it is safe, both
write, and the count reaches zero. Third-party account, which I could not verify
against the book: "both Alice and Bob begin transactions, check the count of
currently on-call doctors (which returns 2 for both), and then each attempts to
set themselves as off-call if the count is at least 2. Since the database is
using snapshot isolation, both transactions commit, and now no doctor is on call"
(<https://dev.to/yugabyte/the-doctors-on-call-shift-example-in-a-normalized-relational-schema-to-avoid-write-skew-4hhf>).
Shape: `concurrency`
Size: 2 transactions, 2 records, per-transaction snapshot. Identical to G2-item.
**Independent description available: yes, and it is Hermitage's G2-item.**
The Hermitage `postgres.md` interleaving *is* this problem with `value` in place
of `on_call`. So D1 ships as "the G2-item anomaly, stated as a rostering
service", with Hermitage as the mechanism oracle and no dependence on the book.
**This is the model for how the whole sub-family should be used**: DDIA supplies
the *situation* — a rostering service, not a table called `test` — and Hermitage
supplies the *trace*. The book gives the altitude, and the free source gives the
ground truth. That combination is better than either alone, and it is the single
most useful thing this survey found.

---

**D2 — The lease holder that pauses (Ch. 8, fencing tokens)**
Situation: a worker takes a lease on a resource, pauses long enough for the lease
to expire, a second worker takes the lease, and the first worker wakes up and
writes.
Property: a write to the resource comes from the current lease holder.
Anomaly: verbatim, and from **Kleppmann's own public post**, not the book:
"Client 1 acquires the lease and gets a token of 33, but then it goes into a long
pause and the lease expires." Both clients then write and the data is corrupted
(<https://martin.kleppmann.com/2016/02/08/how-to-do-distributed-locking.html>).
The fix is stated as an invariant in the same post: "a fencing token is simply a
number that increases (e.g. incremented by the lock service) every time a client
acquires the lock", and the storage server rejects any write with a lower token
than one it has already processed.
Shape: `expiry`
Size: 2 clients, 1 lock service, 1 storage server, a clock or a
nondeterministic-expiry action, a token counter, a per-storage highest-seen
token. 3 actors, 4 state pieces.
**Independent description available: yes — the blog post is the whole problem,
free, and by the same author.** The book is not needed at all.
Ground truth: the post states both the failure and the fix, so the model must
show the invariant failing without the token and holding with it. That is a
two-stage exercise, which is a good shape.
**Overlap warning**: this is the Jepsen survey's etcd lock candidate and it is
K2 from §2. Three surveys, one problem. That is a strong signal it is *the*
canonical problem in this whole space, and an equally strong signal that the
curriculum should carry it once. Also note the post's own framing distinction —
efficiency uses of a lock, where failure means "a minor increase in cost", versus
correctness uses, where it means "corrupted file, data loss, permanent
inconsistency". That distinction is itself worth a problem statement.

---

**D3 — Two channels between the same two services (Ch. 9, cross-channel timing
dependencies, Figure 9-5)**
Situation: a web server writes a file to a storage service and separately puts a
job on a queue; a worker takes the job and reads the file. The two paths have
different latencies.
Property: a job's referent exists, in its current version, by the time the job is
processed.
Anomaly, from third-party notes rather than the book: "The message queue might be
faster than the internal replication inside the storage service, and when the
resizer fetches the image, it might see an old version of the image or nothing at
all, causing the full-size and resized images in the file storage to become
permanently inconsistent"
(<https://xgwang.me/posts/ddia-9-consistency-and-consensus/> and
<https://candost.blog/books/consistency-and-consensus-in-distributed-systems/>,
both paraphrasing Figure 9-5). The book's own framing, per those notes, is that
"there are two different communication channels between the web server and the
resizer".
Shape: `two-store`
Size: 1 producer, 1 consumer, a store with a replication-lag action, a queue.
2 actors, 3 state pieces. Small.
**Independent description available: NOT directly.** No Kleppmann post carries
this one, and the third-party notes are paraphrase. But the *shape* is
independently attested elsewhere in this survey — it is B10, the HDFS
`needReplication` stale-stamp bug, and it is the ordinary "wrote to S3, published
to SNS, consumer read too early" problem.
**Recommendation**: ship the shape with an independently-sourced instance, not
with the book's image resizer. B10 or a plainly-stated version.
**The permanence is the interesting part** and it is what the notes emphasise:
"permanently inconsistent". The failure is not a retry-able race; the system
settles into a wrong state and stays there. That is the same permanence the
network-partitioning paper measured — "21% of the failures leave the system in an
erroneous state that persists even after the network partition heals"
(OSDI '18 Finding 3). Two independent sources on the same property.

---

**D4 — Replication-lag anomalies (Ch. 5)**
Read-your-writes, monotonic reads, consistent prefix reads. Three properties, each
with a named violation.
Property (monotonic reads): a client's successive reads never go backwards in
time.
Property (consistent prefix): if writes happened in a causal order, any reader
sees them in that order.
Shape: `two-store` (a leader and a follower that disagree).
Size: 1 leader, 2 followers, per-follower lag, 1 client with a follower choice.
Small.
**Independent description available: partially.** Chapter 5's reference list
confirms the subject, and Bailis et al.'s "Highly Available Transactions"
(<http://arxiv.org/pdf/1302.0309.pdf>, cited by the Hermitage README) defines
these session guarantees formally and freely. So the *definitions* are free even
though the book's narrative examples are not.
**Weakness for this learner**: these are three properties over one small model
rather than three problems. And unlike write skew, the violation is not
surprising — a follower lags, so a read from it is stale. It is a good place to
practise *stating* a temporal property and a weak place to practise finding a
bug. `INFERRED`

---

**D5 — Two-phase commit with an in-doubt participant (Ch. 9)**
Situation: a coordinator and two participants; the coordinator crashes after some
participants have voted yes and before all have learned the outcome.
Property: no two participants decide differently, and a participant that has
voted yes eventually learns the outcome.
Shape: `workflow`
Size: 1 coordinator, 2 participants, per-participant vote and decision, a crash
action. Small.
**Flag: heavily specified already.** `tlaplus/Examples` carries `TwoPhase.tla`,
and the project's own `.claude/rules/tla-practice.md` §5 names it explicitly:
"`TwoPhase`, `PConProof` and `BPConProof` are proved and never checked". A
canonical TLA+ specification of 2PC is one search away and the learner will find
it. **Drop.**

---

### Honest assessment of sub-family 4

- **The book is not a source of problems. It is a source of *framings*.** Every
  candidate above either duplicates a problem already available free (D1 = G2-item,
  D5 = `TwoPhase.tla`) or has a free author-written substitute (D2). What DDIA
  uniquely supplies is the *statement altitude* — "two doctors going off call"
  instead of "two transactions updating rows 1 and 2".
- **That is worth a lot for this particular learner**, who rejected earlier
  directions for being too abstract. The framing is the thing he complained was
  missing.
- **Cost**: for each problem, someone has to find the free source. For D1 and D2
  it took one fetch each. For D3 it could not be done and the recommendation is
  to substitute.
- **Chapters 5, 7, 8 and 9 are not equally useful.** Ch. 7 is entirely covered by
  Hermitage, Ch. 8's best material has a free blog substitute, Ch. 9's best
  material overlaps already-published specs, and Ch. 5 gives properties rather
  than puzzles.


## Answers to the five questions

### Q1. Are the isolation anomalies the strongest lead? — Confirmed, with one amendment

**Confirmed on the evidence**, and the amendment matters.

What holds:
- **10 named anomalies**, each with **at least one concrete runnable
  interleaving** in `ept/hermitage`, most with several.
- **One shared fixture of two rows and one integer column** across all ten.
- **A real four-step difficulty ladder** (state-predicate → snapshot → history →
  predicate), derived in §1 from what each model has to carry.
- **A ground-truth oracle that no other sub-family has**: the README's 10-column
  table across 9 databases and 30 isolation-level rows. A model's verdict for
  "does read committed prevent G1a" is checkable against nine independent
  implementations, and the legend distinguishes `✓`, `—`, `R/O` and `some`.

The amendment, in two parts:

1. **The distinct-problem count is 6-7, not 10.** G1a and G1b are one problem
   with two invariants. G-single and OTV are close. G0 is prevented at every
   level of every database, so it has no "which level allows this" question and
   works only as a warm-up.
2. **The framing is load-bearing and untested.** Everything above holds under
   framing (b) — model the application, take the isolation level as an
   environment assumption. Under framing (a) the family is already specified
   three times over in public TLA+ and blows up to 405 million states. **Nothing
   in this survey tested whether (b) is expressible.** That is the one thing a
   spike must settle before any of this ships.

**Full list with sizes**, ordered by the §1 ladder rather than by name:

| tier | anomaly | actors | records | extra state a model needs | shape |
|---|---|---|---|---|---|
| 1 state-predicate | G0 write cycle | 2 | 2 | which writer holds the row | `concurrency` |
| 1 state-predicate | P4 lost update | 2 | 1 | per-txn read value | `concurrency` |
| 2 snapshot | G1a aborted read | 2 | 1 | abort flag | `concurrency` |
| 2 snapshot | G1b intermediate read | 2 | 1 | per-txn write sequence | `concurrency` |
| 2 snapshot | G-single read skew | 2 | 2 | per-txn snapshot | `two-store` |
| 2 snapshot | OTV | **3** | 2 | per-reader snapshot | `two-store` |
| 3 history | G1c circular info flow | 2 | 2 | reads-from edge set | `concurrency` |
| 3 history | G2-item write skew | 2 | 2 | per-txn snapshot + a cross-record invariant | `concurrency` |
| 4 predicate | PMP phantom | 2 | **growable** | predicates as objects | `concurrency` |
| 4 predicate | G2 anti-dependency | 2-3 | **growable** | predicates + dependency graph | `concurrency` |

Two to three actors and one to two records throughout. Nothing here exceeds
"three transactions over two rows", which is smaller than every candidate in the
other three sub-families.

### Q2. Which sub-family gives the best supply? — Counts

| sub-family | candidates found | candidates I would keep | of which already TLA+-spec'd | median size (actors) |
|---|---|---|---|---|
| 1 isolation anomalies | **10** | 6-7 | mechanism side: **all** (see §1); application side: 0 | 2 |
| 2 Kafka KIPs | 4 | 3 | 1 of the 4 obvious picks (KIP-848) removed before counting; KRaft, replication, InitPid and AddPartitions also removed | 2-3 |
| 3 bug studies | **20 narrated** in the best paper, ~35 across all four read | **10** from the best paper, ~15 overall | 0 found | 3 |
| 4 DDIA | 5 | 3 | D5 (2PC) is `TwoPhase.tla` | 2-3 |

**Isolation wins on supply, cost-per-candidate, and oracle quality.** Bug studies
win on breadth of shape — they are the only sub-family that produced `expiry`,
`resource`, `workflow` and `lifecycle` candidates, where isolation produced
`concurrency` nine times out of ten and `two-store` twice.

That is the real division of labour, and it is not "pick one":

- **Isolation supplies depth in one shape.** Ten graded problems, all
  `concurrency`, all tiny, all with the same fixture. Excellent for a ladder.
- **Bug studies supply breadth across shapes.** Ten problems, seven distinct
  shapes, each standing alone. Excellent for coverage, useless as a ladder.
- **Kafka supplies two problems that are not really about Kafka.**
- **DDIA supplies framings, not problems.**

### Q3. How many catalogued bugs are modelable from the paper alone?

Answered in §3 with a hand count. **In the best paper of the four — Alquraan et
al., OSDI '18 — 20 of 136 catalogued failures are narrated in prose, and 10 of
those 20 are both modelable from the paper alone and outside the consensus family
the learner rejected. That is 7%.**

Across all four papers read: roughly 35 narrated, roughly 15 usable, against
~4,145 catalogued issues. **Do not use the catalogue size as the supply
number.** The catalogue is an index into issue trackers; the narrated set is the
supply, and it is bounded by how many examples the authors chose to write out,
which is a dozen or two per paper regardless of catalogue size.

Two things sharpen this:

- **The wrong paper doubles the work.** OSDI '14's own Finding 10 says "Almost
  all catastrophic failures (92%) are the result of incorrect handling of
  non-fatal errors explicitly signaled in software", with 35% of those being
  empty catch blocks, over-catch, and `TODO` in a handler. Those are code
  defects with no state space. OSDI '18's Table 12 inverts it: 46.6% design
  flaws against 32.2% implementation flaws. **Use OSDI '18.**
- **All four papers independently confirm the size fits TLC.** OSDI '18: 83% of
  failures need ≤3 events, 83% reproduce on 3 nodes, only 7% nondeterministic.
  OSDI '14: 90% need ≤3 events, 74% deterministic, "almost all failures require
  only 3 or fewer nodes to reproduce". This is the strongest external evidence
  in the whole document that the family is the right size for the tool.

### Q4. What does this family cover that RFCs and postmortems do not?

Three things, and they are structural rather than incidental. Read against the
sibling surveys in this directory as they stood on 2026-09-06.

**1. A graded ladder over one fixture.** A postmortem is a singleton: one
incident, one system, one severity. An RFC describes one protocol. The isolation
family is the only source found anywhere in this run that supplies **ten
problems over the same two-row fixture at four increasing levels of modelling
technique**. Difficulty ordering in every other family has to be imposed by the
curriculum author; here it falls out of the material.

**2. An oracle that is not a narrative.** A postmortem's ground truth is the
author's account of what happened once. Hermitage's ground truth is a **table of
30 isolation-level rows × 10 anomalies, empirically probed against 9 database
implementations**, with a legend that distinguishes "prevented", "not
prevented", "prevented read-only", and "prevented in some cases". A model's
verdict is checkable against a matrix, not against a story. Nothing in the
postmortem or RFC families has that.

**3. The failure is by design, not by accident.** A postmortem describes a
system that was supposed to work and did not. An isolation level describes a
system that **is documented to permit the anomaly** — that is what "read
committed" means. The learner is not hunting a defect; he is deriving the
consequences of a specification he chose. That is closer to what a working
engineer does when he picks an isolation level or a delivery guarantee than
anything in the incident literature, and it removes the "would I have caught
this?" hindsight problem that every postmortem carries.

A fourth, weaker: **the bug studies quantify the size of the family.** No
postmortem collection says "83% of these reproduce on three nodes". The academic
catalogues do, and that number is what makes the family a defensible bet rather
than a hopeful one.

What this family does **not** cover that postmortems do: the compounding failure,
where three things go wrong at once and the recovery mechanism is the third.
Nothing in isolation levels or KIPs has that shape.

### Q5. Candidates that already have a public TLA+ specification — flagged

| candidate | existing spec | verdict |
|---|---|---|
| **All 10 isolation anomalies, mechanism side** | `will62794/snapshot-isolation-spec/SnapshotIsolation.tla` (write skew + read-only anomaly, `IsSerializable` invariant); `pron/amazon-snapshot-spec/{textbook,serializable}SnapshotIsolation.tla` (Chris Newcombe, Amazon); mirrored at `sanjosh/tlaplus/amazon/`; linked from `tlaplus/Examples/specifications/SnapshotIsolation/README.md` | **Framing (a) is dead. Framing (b) is clear.** |
| Kafka consumer group protocol, KIP-848 | `Vanlightly/kafka-tlaplus/groupprotocol/consumer_group_protocol_kip_848.tla` + `_v2.tla` | **Dropped before counting.** |
| Kafka data replication, KRaft, KIP-966 ELR | `kafka_data_replication/kraft/{v3.5,kip-966}/*.tla`, 10 modules | Dropped. |
| KRaft consensus, KIP-853, KIP-996 | `kraft/kip_853/*.tla`, `kraft/kip_996/*.tla`, 10 modules | Dropped, and consensus is out of scope anyway. |
| Kafka producer-id acquisition | `transactions/diary/01_InitPidRequest/tlaplus/kafka_transactions.tla` | Dropped. |
| Kafka AddPartitionsToTxn | `transactions/diary/02_AddPartitionsToTxn/tlaplus/kafka_transactions.tla` | Dropped; **K3 (KIP-890) overlaps it — check before spiking.** |
| D5, two-phase commit | `tlaplus/Examples/specifications/transaction_commit/TwoPhase.tla` (+ `TwoPhase_proof.tla`, `TCommit.tla`, `PaxosCommit.tla`, `2PCwithBTM.tla`) | **Dropped.** |
| D2 / K2 / etcd lock, lease + fencing token | No canonical spec found in the checks run, but a public FizzBee model exists (<https://surfingcomplexity.blog/2025/03/03/locks-leases-fencing-tokens-fizzbee/>) and a public TLA+ blog model (<https://medium.com/@polyglot_factotum/modelling-distributed-locking-in-tla-8a75dc441c5a>). Not searched exhaustively. `INFERRED` | **Keep, but expect the learner to find prior art.** |
| K1, K4, B1-B10, D1, D3, D4 | none found | Clear. |

The pattern is worth stating plainly: **every candidate an experienced person
would reach for first is already specified.** Snapshot isolation, 2PC, the
consumer group protocol, KRaft. What survives is the second rank — the
application on top of the mechanism, the KIP nobody modelled, the bug narrated in
a paper's §4.4.

## Verdict

**Primary source: the transaction isolation anomalies, under framing (b) only.**

They are the best supply in this survey by every measure that matters —
10 candidates, a shared two-row fixture, a documented interleaving for each, a
four-step difficulty ladder that falls out of the material, and a 30-row × 10-column
empirical oracle. Nothing else found in this run has a ladder or a matrix.

The framing condition is not a footnote. Model the isolation *mechanism* and the
family is dead on arrival: three public TLA+ specs already exist, one of them
linked from `tlaplus/Examples`, and the reference model needs 405 million states
and 12 steps to reach the interesting anomaly. Model the *application* against a
permitted-interleaving oracle and none of that applies.

**Secondary source: the network-partitioning bug study**, Alquraan et al.
OSDI '18. 10 usable candidates covering `lifecycle`, `two-store`, `delivery`,
`expiry`, `resource` and `workflow` — every shape the isolation family cannot
reach. Each stands alone with a quoted mechanism, and the paper's own Findings 7
and 12 quantify that these bugs fit in three nodes and three events. Use it for
breadth, not for a ladder.

**Tertiary, and only as framings: DDIA.** The book supplies the altitude a
problem statement should be written at — "two doctors going off call" rather than
"two transactions updating rows 1 and 2" — and for its two best scenarios a free
author-written substitute already exists. It supplies no problem that is not
better sourced elsewhere.

**Dropped: Kafka KIPs as a sub-family.** Keep K1 and K2 as individual candidates;
drop the family. Everything an engineer would reach for is spec'd, the survivors
need a page of Kafka vocabulary before the problem is even stateable, and the two
good ones (offset-commit ordering, zombie fencing) are not Kafka problems at all
once you strip the vocabulary out — which means Kafka's documentation stops being
their oracle.

**Also dropped: OSDI '14 "Simple Testing" and CbsDB as problem sources.** OSDI '14
is 92% error-handling code defects by its own Finding 10, and CbsDB is
classification labels over issue IDs. Both are excellent papers and neither is a
supply of specifications.

### What would change my mind

- **A spike showing framing (b) is not expressible.** If "the scheduler may
  produce any interleaving read-committed permits" cannot be written without
  reconstructing MVCC, the isolation family collapses into framing (a), the
  published specs win, and the primary source becomes the OSDI '18 bug study.
  **This is the single highest-value thing to spike, and it should be spiked
  before anything else in this family is built.**
- **A demonstration that the ladder does not survive contact.** The four tiers in
  §1 are my reading of what each model needs, marked `INFERRED`. If tier 3
  (G1c, G2-item) turns out to be no harder than tier 2 in practice, the family
  is six flat problems rather than a graded ten, and its main advantage over the
  bug studies evaporates.
- **Finding that the OSDI '18 narratives are thinner than they read.** I judged
  10 of 20 modelable from the prose alone. If a spike on B1 or B4 needs the JIRA
  thread, the usable count for sub-family 3 drops toward zero and the breadth
  argument goes with it.
- **The three-way overlap resolving badly.** The lease/fencing problem appears as
  D2, as K2, and as the Jepsen survey's etcd lock candidate. If cross-survey
  reconciliation shows more such collisions, the combined supply across all
  surveys is smaller than the individual counts suggest, and the right response
  is to widen the source families rather than to build from these.
- **The learner rejecting framing (b) as still-too-abstract.** He has rejected
  two directions in two days. "Two transactions over a two-row table" is
  recognisably a database exercise even when it is dressed as a rostering
  service. If that reads as academic to him, the bug studies — which are
  unambiguously about services, supervisors, queues and timeouts — become
  primary and this family becomes secondary.

