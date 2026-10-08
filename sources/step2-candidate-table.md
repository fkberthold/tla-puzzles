# Step-2 candidate table

Read 2026-10-08. Sources read in full: `sources/README.md`, `sources/own-systems.md`,
`sources/rfcs.md`, `sources/semantics.md`, `sources/rollout.md`, `sources/issues.md`.
`sources/jepsen.md` and `sources/postmortems.md` were not opened, per the brief.

Twenty ranked candidates, then a reserve. No candidate carries a target difficulty,
a target position, or a target dimension value. The ramp places these after they are
measured.

Every load-bearing claim below carries a `file:line` into the surveys, the source
document's own identifier, or the literal marker `INFERRED`.

Scoring, in the order it was applied: does the source ship a *second, independent*
description of the machine (`sources/README.md:172-175`); is there a documented
counterexample; is the cause separable; is the shape one of the learner's top five
(`sources/own-systems.md:72-76`); and is the answer already the top search result for
its own name (`sources/README.md:182-185`).

---

## The twenty

### 1. `progressive-sync-stale-status`

- **source** — rollout-native trackers, `argoproj/argo-cd#29410` (`sources/rollout.md:178-215`)
- **yardstick shape** — `rollout`
- **the machine** — An ordered rollout pushes one commit across a fleet of member
  applications in named cohorts, one cohort at a time, with a concurrency cap on the
  last step. The controller decides a cohort is finished by reading a per-member status
  field that a separate loop refreshes asynchronously. Progressive sync also turns
  automated sync off for the member apps while it owns them.
- **the property at stake** — A cohort counts as finished only when its members have
  synced at the revision being rolled out, and every member ends up on that revision.
- **second independent description** — `none`. The three numbered repro steps and the
  named observation window, "the window is the app-status refresh interval", restate the
  same description rather than supplying a second one (`sources/rollout.md:195-196`).
- **documented counterexample** — A narrated run with the cohorts named: "prod-cohort
  apps rolled first, dev app never synced" (`sources/rollout.md:193-194`), plus a second
  failure from the same cause, the skipped app sitting `OutOfSync` indefinitely with no
  retrigger (`sources/rollout.md:197-200`).
- **cause separable** — Yes. Delete `## Expected` and the closing clause of `## Summary`;
  `## What we observed` survives intact (`sources/rollout.md:210-211`).
- **why this makes a good problem** — It is the learner's own platform with the names
  changed, down to per-cluster cohorts and a concurrency cap (`sources/rollout.md:213-215`,
  against `sources/own-systems.md:41` where a `*_LOCK` file leaves one cluster behind
  while the rest keep auto-updating). One cause yields two different failures, an ordering
  inversion and a silent permanent divergence, so the learner writes two properties over
  one model.
- **risk** — The completion predicate reads an observed copy that a refresh loop updates,
  and the prose never says whether a refresh can land mid-cohort or only between cohorts.
  That choice decides whether the inversion is reachable at all.

### 2. `txn-epoch-fence-vs-retry`

- **source** — general issue trackers, Apache Kafka `KAFKA-20090` (`sources/issues.md:69-89`)
- **yardstick shape** — `workflow`
- **the machine** — A coordinator owns a per-client transaction state machine with a real
  abort branch and fences a client by bumping a monotone epoch counter. On transactional
  timeout the fencing abort bumps the epoch to its maximum. A late end-transaction request
  carrying the previous epoch is then classified as a retry, and the coordinator hands the
  fenced epoch back to the client.
- **the property at stake** — A fenced transaction can never be reopened, and every
  transaction can eventually be committed or aborted.
- **second independent description** — `none`. The body is one four-step sequence
  (`sources/issues.md:77-81`), and the comments quote Scala rather than restating the
  machine (`sources/issues.md:88-89`).
- **documented counterexample** — The four-step sequence verbatim, ending "We cannot commit
  this transaction ... It is stuck in Ongoing forever" (`sources/issues.md:76-81`).
- **cause separable** — Yes. The rule and the failure are the same four steps, so the body
  needs no cut; the source walk is in the comments (`sources/issues.md:88-89`).
- **why this makes a good problem** — The cleanest multi-party sequence with an abort branch
  found in any family, and the defect is that two predicates over one counter disagree at a
  single value (`sources/issues.md:82-85`). The failure is liveness, a transaction that can
  neither commit nor time out, which is a change of gear from a safety invariant.
- **risk** — The maximum epoch is the whole mechanism and the body says only "bumps the epoch
  to max" without saying what happens on the next bump. A spike that lets the counter keep
  climbing never reaches the bug.

### 3. `acme-challenge-retry-deadlock`

- **source** — RFCs, RFC 8555 §8.2 against §8 and §7.1.6 (`sources/rfcs.md:926-967`)
- **yardstick shape** — `lifecycle`
- **the machine** — A certificate authority repeatedly probes a client's web server or DNS
  zone to validate a challenge, retrying after each failed query, while the client may also
  demand a retry. The challenge object carries a status and an error list. The authority
  decides when the attempt is finally dead.
- **the property at stake** — A challenge stays retriable while the authority is still
  trying, and becomes final only once the authority has given up.
- **second independent description** — Four published ASCII state diagrams at §7.1.6, one
  each for account, order, authorization and challenge (`sources/rfcs.md:918-923`). Erratum
  7826 shows the community treats the diagram as the arbiter when the prose is ambiguous
  (`sources/rfcs.md:957-960`).
- **documented counterexample** — Verified erratum 5732 (Rob Stradling 2019-05-23, verified
  Paul Wouters 2024-02-22), whose own note states the deadlock: "if the challenge must then
  become 'invalid', it is never possible to retry any validation query"
  (`sources/rfcs.md:945-956`). Boulder's divergences document corroborates from
  implementation (`sources/rfcs.md:961-964`).
- **cause separable** — Yes, and it already is. The three contradictory sentences are in the
  RFC and the diagnosis is in an erratum the learner is not handed
  (`sources/rfcs.md:938-944`).
- **why this makes a good problem** — Three normative sentences that cannot all hold, with a
  working-group-ratified answer key written by a third party, over one challenge and a counter
  (`sources/rfcs.md:965-967`). The RFC survey calls it the cleanest single piece of ground
  truth it found (`sources/rfcs.md:945`).
- **risk** — The deadlock is reachable only if the model gives the authority a give-up decision
  distinct from writing an error. Collapse those two into one action and the contradiction never
  shows, and that is exactly the modelling choice the RFC leaves to the reader.

### 4. `commit-permission-window`

- **source** — catalogued bug studies, CrashTuner §2.2 Figure 3, MR-3858
  (`sources/semantics.md:659-688`)
- **yardstick shape** — `workflow`
- **the machine** — A worker asks a coordinator for permission to commit a task's result, is
  granted it, starts committing, and may crash at any point. The coordinator records which
  attempt holds the permission. When a worker dies the coordinator starts a replacement attempt
  for the same task.
- **the property at stake** — A task's result is committed once, and a crashed attempt is always
  recoverable by a fresh attempt.
- **second independent description** — A numbered six-step trace in Figure 3, printed separately
  from the prose that states the window boundaries (`sources/semantics.md:668-676`).
- **documented counterexample** — Yes, and graded: the paper names three crash windows and the
  outcome of each, with only the middle one bad. Crash after `doneCommit` needs no recovery,
  crash before `commitPending` is correctly redone, and a crash between the two RPCs means "the
  recovery process always fails, and the job will never finish"
  (`sources/semantics.md:670-676`).
- **cause separable** — Yes. The diagnosis is the boundary sentence that follows the trace, so it
  lifts out whole and the six steps stand (`sources/semantics.md:668-676`). `INFERRED` for the
  separability, since the bug-study survey does not score holdback the way the tracker surveys do.
- **why this makes a good problem** — A two-phase-commit-shaped problem stated entirely at the
  application level, with a safe region named on each side of the bad window, so the learner must
  find a predicate that distinguishes three windows rather than two
  (`sources/semantics.md:680-687`). The failure is liveness.
- **risk** — The three windows exist only if the model carries *where inside the commit sequence*
  the crash landed. The paper's framing is positional, "in the small time window between the two
  RPCs", and a spike that models the commit as one atomic action collapses all three windows into
  one.

### 5. `imap-move-partial-failure`

- **source** — RFCs, RFC 9051 §6.4.8 against RFC 6851 §3.3 (`sources/rfcs.md:1792-1837`)
- **yardstick shape** — `two-store`
- **the machine** — A client moves a set of messages from a source mailbox to a target mailbox in
  one command, and the server may fail partway through the set. Two neighbouring commands over the
  same mailboxes, copy and append, are specified all-or-nothing while move is not. The guarantee
  holds even when the server answers with a flat refusal.
- **the property at stake** — However the command fails, every message ends up in at least one of
  the two mailboxes and preferably not in both.
- **second independent description** — The RFC supplies its own decomposition: move is equivalent
  to copy plus a deleted-flag store plus an expunge, "except the intermediate states produced by
  those steps do not occur" (`sources/rfcs.md:1810-1812`).
- **documented counterexample** — Of a kind nothing else has: the requirement was strengthened from
  SHOULD to MUST between RFC 6851 §3.3 and RFC 9051 §6.4.8 with the rest of the paragraph
  byte-identical, verified by the surveyor diffing the two source texts
  (`sources/rfcs.md:1821-1828`). Thunderbird bug 610131 is the duplicate-side instance, relayed
  (`sources/rfcs.md:1829-1833`).
- **cause separable** — Not applicable, and that is the point: there is no defect narrative to
  withhold. The three clauses are normative text and eight years of field experience sit in one
  changed word (`sources/rfcs.md:1821-1828`).
- **why this makes a good problem** — Three separately checkable clauses in one paragraph, with a
  safety floor that a conforming server may satisfy by leaving a message in *both* mailboxes
  (`sources/rfcs.md:1815-1820`). The SHOULD-to-MUST change tells the learner which clause is
  load-bearing without guessing (`sources/rfcs.md:1947-1950`).
- **risk** — The interesting content is the per-message granularity of the failure, and nothing in
  the RFC says what the server does with the rest of the set after one message fails. A spike that
  models failure as "stop here" gets a prefix, which is sound and uninteresting.

### 6. `parent-reset-loses-child`

- **source** — general issue trackers, `temporalio/temporal#10639` (`sources/issues.md:49-67`)
- **yardstick shape** — `workflow`
- **the machine** — A parent process starts a child and expects to be told when it finishes. The
  parent can die mid-flight and the child carries on and completes anyway. The parent can later be
  restarted from a checkpoint taken before the completion was recorded.
- **the property at stake** — A parent restarted from a checkpoint observes a child that has
  already completed and makes progress.
- **second independent description** — `none`. The body is one numbered timeline
  (`sources/issues.md:56-59`), and the repro link is a Go test the survey says the timeline stands
  without (`sources/issues.md:66-67`).
- **documented counterexample** — A five-step numbered timeline in the body
  (`sources/issues.md:56-59`).
- **cause separable** — Yes. The diagnosis is one sentence under the heading `## Why this seems
  problematic` (`sources/issues.md:59-61`, `sources/issues.md:354-355`).
- **why this makes a good problem** — Two actors, a completion-delivery step, and an addressee that
  can be dead when the delivery arrives (`sources/issues.md:62-65`), which is the learner's
  agent-command-across-a-reconnect shape (`sources/own-systems.md:44, 48`). The parent's recorded
  history is a set the learner has to decide how to represent.
- **risk** — The argument turns on what a reset restores, and the body says only "reset to a point
  after `ChildWorkflowExecutionStarted`". Nothing states whether the reset discards the completion
  record or never had it, and those are different bugs.

### 7. `shard-boundary-two-writes`

- **source** — rollout-native trackers, `open-cluster-management-io/ocm#1346`
  (`sources/rollout.md:283-313`)
- **yardstick shape** — `rollout`
- **the machine** — A fleet's membership list exceeds a size limit, so it is stored as the union of
  several shard objects. Rebalancing moves a member from one shard to the next by writing the two
  objects one at a time. A downstream controller reconciles against the union whenever it changes.
- **the property at stake** — A member that is only being rebalanced keeps its workload and never
  looks to a reader as though it left the fleet.
- **second independent description** — A two-line before-and-after listing of both shards'
  contents, printed separately from the numbered repro (`sources/rollout.md:294-299`).
- **documented counterexample** — The numbered repro steps 5 to 7, ending with the member's addon
  deleted and then recreated (`sources/rollout.md:295-299`).
- **cause separable** — No heading to delete. Steps 5 and 6 state the mechanism outright, so the cut
  is to drop steps 5 to 7 and keep the before-and-after diagram, which the survey calls clean enough
  but sentence-level (`sources/rollout.md:306-308`).
- **why this makes a good problem** — The purest statement in either tracker survey of a change that
  is neither the old state nor the new one, with no product knowledge needed at all
  (`sources/rollout.md:300-304, 310-313`). Three members is exactly the right number, because two
  leaves one shard empty and the crossing degenerate (`sources/rollout.md:302-304`).
- **risk** — The reader's reconcile has to interleave between the two shard writes. If a spike models
  the two writes as one update to a derived union, the window the bug lives in does not exist.

### 8. `mailbox-sync-cursor-identity`

- **source** — RFCs, RFC 9051 §2.3.1.1 (`sources/rfcs.md:1741-1790`)
- **yardstick shape** — `lifecycle` (the survey notes it is legitimately `two-store` as well, and
  picks `lifecycle` because the normative text is organised around the identifiers,
  `sources/rfcs.md:1760-1762`)
- **the machine** — A server assigns each message in a mailbox a strictly ascending identifier and
  publishes a next-identifier value plus a validity value. A client caches the mailbox offline and
  resynchronises on reconnect from those three numbers. Messages can be expunged between sessions,
  and identifiers must never be reused under the same validity value.
- **the property at stake** — A disconnected client can tell from the published numbers alone whether
  anything has arrived since it last looked, without refetching the mailbox.
- **second independent description** — Six MUSTs in one section written as invariants, plus the RFC's
  own note stating the client use case they exist to serve (`sources/rfcs.md:1748-1759, 1769-1773`).
  This is the "invariants already written as invariants" form the survey names
  (`sources/rfcs.md:2055-2057`).
- **documented counterexample** — Two. Verified erratum 3501/261, filed by IMAP's own author Mark
  Crispin, amends this section (`sources/rfcs.md:1774-1777`). And RFC 8474, Standards Track 2018,
  exists because the scheme does not survive messages moving between mailboxes, stating the
  consequence that a client "will redownload everything" (`sources/rfcs.md:1780-1783`).
- **cause separable** — Not applicable. No defect narrative. The trap is that the next-identifier rule
  is a biconditional that reads like an implication, and the RFC states both halves
  (`sources/rfcs.md:1763-1770`).
- **why this makes a good problem** — The one-line wrong implementation, max-of-live-identifiers plus
  one, violates the second half the moment the newest message is expunged, and every disconnected
  client then concludes nothing arrived (`sources/rfcs.md:1766-1773`). The only published formal model
  in this domain lists this exact reset as unmodelled (`sources/rfcs.md:1904-1914`).
- **risk** — The bug is about a value not recoverable from current contents, so the model needs an
  arrival history the learner never reads directly. If a spike represents the mailbox as a set of live
  messages only, the correct and the wrong implementations are indistinguishable and the problem
  evaporates.

### 9. `queued-version-stamp-stale`

- **source** — catalogued bug studies, OSDI '14 Figure 1, HDFS (`sources/semantics.md:838-858`)
- **yardstick shape** — `two-store`
- **the machine** — A work queue records an item's version at the time it is enqueued. The item is
  later modified and its version bumped at the holder, while the queue's recorded version is not
  updated. A worker asked to act on the queued item compares the two versions and refuses when they
  disagree.
- **the property at stake** — An item that is under-replicated eventually becomes replicated.
- **second independent description** — The survey calls it the best-drawn trace of any bug it found: a
  three-step sequence diagram with the erroneous step labelled "an error"
  (`sources/semantics.md:845-857`).
- **documented counterexample** — The figure's three-step caption, ending "since the generation stamps
  from needReplication queue and DN1 do not match, DN1 keeps refusing to replicate"
  (`sources/semantics.md:846-851`).
- **cause separable** — No. The erroneous step is labelled inside the figure, "the generation stamp in
  the needReplication queue is not updated - an error" (`sources/semantics.md:848-850`), so the label
  comes out and the three steps stay. Sentence-level, not heading-level. `INFERRED`.
- **why this makes a good problem** — Two stores holding the same fact where only one drives a guard is
  this platform's default condition rather than its exception (`sources/own-systems.md:21`), and the
  learner's own version is a setting whose desired value the agent may never report back
  (`sources/own-systems.md:35`). The property is liveness over five variables
  (`sources/semantics.md:852-855`).
- **risk** — OSDI '14 is 92 percent error-handling code defects by its own Finding 10 and the survey
  recommends against the paper as a family (`sources/semantics.md:1196-1201`). This figure is one of
  about three logic-level narratives in it, so there is no sibling to fall back on if the prose turns
  out thin.

### 10. `paused-then-running`

- **source** — general issue trackers, `temporalio/temporal#10239` (`sources/issues.md:163-183`)
- **yardstick shape** — `lifecycle`
- **the machine** — An entity has a status field and a separate record of why it was paused, and
  pausing sets both. A task already in flight when the pause lands completes afterwards and flips the
  status back to running without clearing the record. The unpause guard reads only the status.
- **the property at stake** — Once a pause succeeds, no further work is scheduled until an unpause is
  called, and that unpause call succeeds.
- **second independent description** — A real event log pasted into the body with event ids and server
  timestamps, which the survey notes is a counterexample trace already written out
  (`sources/issues.md:173-176`, `sources/issues.md:307`).
- **documented counterexample** — The pasted log ending `#1965 WORKFLOW_TASK_COMPLETED` resetting
  status to running, with the end state stated as `Status == RUNNING, pauseInfo != nil`
  (`sources/issues.md:174-176`).
- **cause separable** — Yes. One file path is named, and only to say the guard reads one field, which
  is the rule rather than the diagnosis (`sources/issues.md:181-183`).
- **why this makes a good problem** — Two fields that must agree, a guard that reads one of them, and
  an in-flight task that outlives the transition (`sources/issues.md:177-181`), which is exactly the
  alarm-activation shape on the learner's platform where five timestamps are independently settable
  with no stated ordering (`sources/own-systems.md:20, 37`). It is the smallest of the issue survey's
  six best (`sources/issues.md:180-181`).
- **risk** — The bug needs the in-flight task to carry what it will write when it lands. If a spike
  models completion as "set status to running" rather than as a decision taken before the pause, the
  pause and the completion race the wrong way and the end state is unreachable.

### 11. `monotone-readiness-latch`

- **source** — rollout-native trackers, `knative/serving#16649` (`sources/rollout.md:249-281`)
- **yardstick shape** — `rollout`
- **the machine** — A router always sends traffic to the most recent version that has ever been marked
  ready. Readiness is computed from the wrong source, so a version can be marked ready before it
  reaches its required scale. The pointer to the latest ready version only ever moves forward.
- **the property at stake** — Traffic stays on the previous fully-scaled version until the new one
  reaches its required scale.
- **second independent description** — The issue quotes the project's own published documentation for
  the readiness definition, so the rule arrives from outside the issue
  (`sources/rollout.md:256-261`).
- **documented counterexample** — A narrated production failure: a healthy fully-scaled version
  abandoned for one running at about 15 percent of target replicas and returning errors, with no path
  back even after the new version flips not-ready (`sources/rollout.md:262-267`).
- **cause separable** — Yes, near-cleanly. The mechanism sits in a labelled `Root cause` block with
  three bullets, and deleting it leaves the first paragraph of `## Actual Behavior` stating the symptom
  and the monotonicity (`sources/rollout.md:274-279`).
- **why this makes a good problem** — The only candidate in the rollout survey whose failure is
  irreversible, so the property is about what can no longer happen rather than what currently holds
  (`sources/rollout.md:280-281`). The reconcile is a sequence of phases where any phase may fail and
  abort the rest (`sources/rollout.md:268-272`), which generalises off the product entirely.
- **risk** — The survey says the monotonicity must stay in the statement or the reader builds the wrong
  model (`sources/rollout.md:277-279`). That is a holdback decision somebody has to take deliberately,
  and getting it wrong in either direction either gives the answer away or makes the failure read as
  transient.

### 12. `pkce-downgrade`

- **source** — RFCs, RFC 9700 §4.8 against RFC 7636 §4.4 and §4.6 (`sources/rfcs.md:519-557`)
- **yardstick shape** — `workflow`
- **the machine** — An authorization server issues a code to a client and later redeems it for a token.
  When the request carries a challenge the server binds that challenge to the code and checks a verifier
  at redemption. The server supports the mechanism but does not require it, so whether a given code is
  bound depends on a parameter the requester can simply leave out.
- **the property at stake** — A code is redeemed only by the party that asked for it, on the device that
  asked.
- **second independent description** — Two. A labelled attacker model, A1 to A5, which the RFC says came
  from formal analysis and cites the paper (`sources/rfcs.md:489-504`). And a printed six-step attack
  trace at §4.8.1 (`sources/rfcs.md:545-549`).
- **documented counterexample** — The six-step trace, ending with the server issuing a token to the wrong
  party because the code carries no binding, plus a MUST-strength countermeasure naming the missing
  precondition (`sources/rfcs.md:534-552`).
- **cause separable** — Yes, structurally. The two individually-satisfiable MUSTs are in RFC 7636 and the
  diagnosis plus the patch are in a separate BCP, so the learner can be handed the former alone
  (`sources/rfcs.md:528-538`).
- **why this makes a good problem** — Two MUSTs are each satisfied and the system is still broken, which
  is the sharpest available demonstration that a conjunction of local requirements is not a system
  property (`sources/rfcs.md:540-544`). The RFC supplies the environment rather than making the learner
  invent it (`sources/rfcs.md:491-494`).
- **risk** — The attacker is a party the spike author has to model, and A1 to A5 are capability labels
  rather than actions. Turning "can read, but not modify, the contents of the authorization response"
  into a next-state relation is a decision the RFC does not make, and it is where the evening goes.

### 13. `check-then-use-after-timeout`

- **source** — catalogued bug studies, CrashTuner §2.1 Figure 2, YARN-5918
  (`sources/semantics.md:690-711`)
- **yardstick shape** — `expiry`
- **the machine** — A registry holds the live members of a cluster. A monitor removes a member after its
  heartbeat times out, and a recovery thread deletes the entry. A separate running thread looks a member
  up in the registry and uses what it finds.
- **the property at stake** — Every lookup of a member either fails cleanly or returns a member that is
  still usable.
- **second independent description** — The figure's four numbered steps, printed separately from the prose
  that generalises the class (`sources/semantics.md:698-702`).
- **documented counterexample** — The four steps ending with the reader getting nothing back, and the
  paper states the class size: "37 bugs belong to this scenario", with the instances listed by issue id in
  Table 1 (`sources/semantics.md:700-709`).
- **cause separable** — No. The mechanism is the four steps. `INFERRED`, since the bug-study survey does
  not score holdback.
- **why this makes a good problem** — A model that captures this shape is validated against 37 real bugs
  rather than one, the highest leverage per model in any of the four families
  (`sources/semantics.md:707-710`). It is also the learner's own control-state question: what happens in
  the dead time between a missed reconfirmation and the recency window expiring
  (`sources/own-systems.md:33`).
- **risk** — The shape is general enough that a faithful model is three lines and the invariant holds
  trivially, because a lookup returning nothing *is* a clean failure. The interesting version needs the
  reader to have already decided to use the member, and the four steps do not say where that decision is
  taken.

### 14. `tombstone-outlives-its-grave`

- **source** — general issue trackers, `nats-io/nats-server#8505` (`sources/issues.md:141-161`)
- **yardstick shape** — `expiry`
- **the machine** — A delete is recorded as a tombstone in an append-only log, and the tombstone itself is
  given a time to live. The tombstone can expire and be removed before the values it covers are. State is
  rebuilt by replaying the log after an unclean restart.
- **the property at stake** — A key that was deleted never comes back.
- **second independent description** — An asymmetry the reporter isolated: two deletions in the same block
  under the same crash, where one stayed deleted and the other revived, stated by sequence number and
  removal path (`sources/issues.md:150-153`).
- **documented counterexample** — A six-step deterministic repro plus that asymmetry, and a commenter
  stating the semantics rather than the code path: "the actual semantics of a PURGE is not made durable"
  (`sources/issues.md:148-155`).
- **cause separable** — Yes. The generalising comment carries the mechanism and lifts out; the body's repro
  and asymmetry stand without it (`sources/issues.md:153-155`).
- **why this makes a good problem** — Two expiry clocks over one logical fact, where the one that expires
  first is the record of the decision rather than the data, which inverts the usual TTL exercise
  (`sources/issues.md:156-159`). This project is the issue survey's highest-quality source for stated
  semantics rather than code paths (`sources/issues.md:309`).
- **risk** — The revival depends on which removal path took the tombstone out, and the body argues that in
  terms of storage-block layout. The survey holds that the argument is really about which facts survive a
  replay (`sources/issues.md:160-161`), but a spike still has to decide how many removal paths exist, and
  the prose names two without enumerating them.

### 15. `fleet-ownership-reshuffle`

- **source** — general issue trackers, `argoproj/argo-cd#29476` (`sources/issues.md:91-117`)
- **yardstick shape** — `two-store` (the survey notes it reads as `rollout` if you emphasise the fleet,
  `sources/issues.md:108-109`)
- **the machine** — Several controller replicas each compute, locally and independently, which members of a
  shared fleet they own, using the member's index in a list sorted by an unpredictable key modulo the replica
  count. A new member is registered, lands at an effectively random position, and shifts everything after it.
  Each replica re-derives the whole distribution only once per process.
- **the property at stake** — Every member of the fleet is owned by exactly one replica, and stays owned.
- **second independent description** — The body carries the production numbers as a separate statement of the
  same event: 47 members to 48, the new one at index 21, 26 of the 47 changing owner, two left orphaned,
  undetected for 57 hours (`sources/issues.md:102-107`).
- **documented counterexample** — The quoted partial application: one replica "simultaneously holding
  clusters that had moved away from it and missing clusters that had moved onto it"
  (`sources/issues.md:103-105`).
- **cause separable** — No, and it is one of the four the survey says need rewriting rather than cutting,
  because the mechanism is stated *as* the rule (`sources/issues.md:363-366`).
- **why this makes a good problem** — The invariant is one line, the mechanism is modular arithmetic over an
  ordered list which is native TLA+, and it carries a liveness half because the only path that re-derives
  the distribution runs once per process (`sources/issues.md:110-117`). Silent for 57 hours with no error
  and no health change is the failure mode the learner's own fleet has
  (`sources/own-systems.md:41`).
- **risk** — The statement has to be rewritten rather than trimmed, so step 3 inherits an authoring job
  before it inherits a modelling one. A rewrite that keeps the sort key unpredictable but drops the
  index-modulo-replicas rule may leave the learner unable to reach the shuffle at all.

### 16. `two-clocks-one-relationship`

- **source** — RFCs, RFC 8555 §7.1.4 and §7.4 with the §7.1.6 diagrams (`sources/rfcs.md:1010-1037`)
- **yardstick shape** — `expiry`
- **the machine** — An order holds a fixed set of per-domain authorizations. The order has its own expiry
  and each authorization has a separate one. The order becomes ready once every authorization is valid, and
  the client then has to submit a signing request before either clock fires.
- **the property at stake** — A certificate is never issued against an authorization that has expired,
  however the order reached ready.
- **second independent description** — The §7.1.6 order diagram carries the edge from ready to invalid
  labelled "Error or Authorization failure", so the picture states the rule the prose only implies
  (`sources/rfcs.md:1026-1029`).
- **documented counterexample** — `none`. The failure, latching readiness instead of re-evaluating it at
  finalize time, is the surveyor's reading of the mechanism rather than a documented instance
  (`sources/rfcs.md:1024-1026`). The RFC does pre-warn that a state a model needs may never appear in a
  status field, because a server that deletes expired authorizations immediately never shows one
  (`sources/rfcs.md:1029-1033`).
- **cause separable** — Not applicable. No defect narrative to withhold.
- **why this makes a good problem** — Two independent expiry clocks over what is conceptually one
  relationship, with nothing stating which governs when they disagree, is a situation the learner's own IAM
  carries verbatim (`sources/own-systems.md:23`, item d, and `sources/own-systems.md:39`). The learner
  supplies a discrete clock, which the survey calls standard modelling furniture rather than inventing the
  system (`sources/rfcs.md:1035-1037`).
- **risk** — With no documented counterexample, the only thing saying what the right answer is is the
  diagram. If a spike finds that latching readiness is in fact unreachable under the diagram's edges, there
  is no third source to appeal to.

### 17. `ordered-update-versus-recovery`

- **source** — rollout-native trackers, `kubernetes/kubernetes#67250` (`sources/rollout.md:339-349`)
- **yardstick shape** — `rollout`
- **the machine** — A controller updates a set of ordered replicas one at a time, terminating each and
  waiting for it to reach running and ready before touching the next. A replica is given a version it cannot
  run, so it never becomes ready. The operator then puts the previous, working version back.
- **the property at stake** — An ordered update visits replicas in order and waits for each, and a bad
  version can be undone.
- **second independent description** — The rule arrives from the project's published documentation, quoted
  back at the reporter by a maintainer, so it is a description of the machine written independently of the
  issue (`sources/rollout.md:341-343`).
- **documented counterexample** — The symptom quoted from the body, with the maintainer's verdict "This
  works as intended and is documented here" (`sources/rollout.md:344-346`).
- **cause separable** — Yes, trivially. The body carries no diagnosis at all, so there is nothing to hold
  back (`sources/rollout.md:349`).
- **why this makes a good problem** — It is a design-tension problem rather than a defect: the ordering
  guarantee and the recoverability guarantee cannot both hold, and a specification makes that visible in a
  way the 69-comment thread never does (`sources/rollout.md:347-349`). That removes the "would I have
  caught this?" hindsight problem the surveys flag against incident narratives
  (`sources/semantics.md:1228-1235`).
- **risk** — Because nothing is broken, the learner has to be told what to check, and neither guarantee is
  written anywhere as a formal claim. A spike has to author both properties and show they are jointly
  unsatisfiable, which is more authoring than the other rollout candidates need.

### 18. `never-bounce-a-bounce`

- **source** — RFCs, RFC 5321 §6.1, §4.5.4 and §3.6.3 with RFC 3834 (`sources/rfcs.md:1582-1628`)
- **yardstick shape** — `workflow`
- **the machine** — Two relays each hold a message they cannot deliver and each is obliged to notify a
  sender. A notification is itself a message with the same lifecycle, sent with a null return path. A relay
  that receives something with a null return path must not notify anybody about it.
- **the property at stake** — One failed delivery produces a bounded number of messages, and the exchange of
  error reports always stops.
- **second independent description** — RFC 3834, a separate Standards-Track document, states the same
  prohibition from a different angle and names the failure class, "sorcerer's apprentice mode"
  (`sources/rfcs.md:1600-1604, 1615-1619`).
- **documented counterexample** — Partial. The failure class is named inside the standards and deployed
  countermeasures have published specifications, but the outside names (backscatter, Joe job, BATV, SRS) are
  relayed rather than fetched by the surveyor, and there is no CVE (`sources/rfcs.md:1615-1624`).
- **cause separable** — Not applicable. There is no withheld diagnosis; the three documents state the rule
  and its reason together.
- **why this makes a good problem** — The property is well-foundedness of a message graph rather than a state
  invariant, and the depth bound comes entirely from the null-return-path clause, so breaking either half
  turns one failure into an unbounded population (`sources/rfcs.md:1606-1614`). Three or four variables, and
  the strongest ground truth of the SMTP candidates (`sources/rfcs.md:1615`).
- **risk** — Termination over an unbounded message population is the whole problem and nothing bounds that
  population from inside the module. If a spike pins the message set to a fixed size to make it finite, the
  property it was set to check becomes true by construction.

### 19. `observed-transaction-vanishes`

- **source** — isolation anomalies, Hermitage `postgres.md` section "Observed Transaction Vanishes", anomaly
  OTV (`sources/semantics.md:213-234`)
- **yardstick shape** — `two-store` (the survey scores it `two-store` over `concurrency` because the property
  is agreement between two places, "which is the shape a working engineer meets as cache-and-database",
  `sources/semantics.md:225-227`)
- **the machine** — An application writes two related records in one transaction. A third party reads the
  first record, then later reads the second. Under the isolation level the platform is configured for, the
  reader can see one half of the write and miss the other.
- **the property at stake** — If a reader sees any effect of a committed change, it sees all of that change's
  effects.
- **second independent description** — An empirical matrix rather than a narrative: 30 isolation-level rows
  against 10 anomalies, probed against 9 database implementations, with a legend distinguishing prevented,
  not prevented, prevented read-only, and prevented in some cases
  (`sources/semantics.md:1120-1124, 1220-1226`).
- **documented counterexample** — The repository prints the prevented form verbatim and the matrix says at
  which levels the anomaly is permitted (`sources/semantics.md:219-230`).
- **cause separable** — Not applicable, and better than separable. The failure is by design rather than by
  accident, so the learner derives the consequences of a configuration he chose instead of hunting a defect
  with hindsight (`sources/semantics.md:1228-1235`).
- **why this makes a good problem** — It is the only anomaly in the family needing three transactions, and
  atomic visibility is exactly the property an engineer needs from a two-table write and the one whose name
  most engineers cannot define off-hand (`sources/semantics.md:227-234`). The existing isolation spike already
  settled that the application framing works and hands over 28 percent of the scaffolding by two-token
  substitution (`sources/README.md:107-123`).
- **risk** — The spike that validated this family covered write skew, lost update and read skew, three
  anomalies of ten (`sources/README.md:188-190`), and OTV is the only one of the three-transaction kind. The
  permitted-interleaving oracle may not extend to a reader taking two reads at different points, which is the
  one thing the measured runs did not exercise.

### 20. `commit-before-or-after`

- **source** — semantics documents, Apache Kafka design documentation "Message Delivery Semantics",
  `docs/design/design.md` on `apache/kafka@trunk` (`sources/semantics.md:455-491`)
- **yardstick shape** — `delivery`, which is secondary on the yardstick
  (`sources/own-systems.md:25`)
- **the machine** — A worker reads items from a durable ordered log, does something with each, and records how
  far it got in a separate register. It can crash at any point, and a successor resumes from the recorded
  position. The two steps, record the position and perform the work, can go in either order.
- **the property at stake** — Either every item in the log is processed at least once, or no item is processed
  twice. Not both.
- **second independent description** — The documentation states both orderings and names the consequence of
  each, so there are two descriptions of the same machine under two different step orders
  (`sources/semantics.md:463-477`).
- **documented counterexample** — In prose and in both directions: save-then-process loses items,
  process-then-save duplicates them, each quoted verbatim with its named semantics
  (`sources/semantics.md:463-477`).
- **cause separable** — Not applicable. There is no defect; the documentation is stating a design choice and
  its price.
- **why this makes a good problem** — The survey calls it the single clearest problem statement in its whole
  set, two orderings of two steps with the source naming each consequence, and it generalises off the product
  completely (`sources/semantics.md:478-489`). It is the learner's own Kinesis checkpoint question, where
  checkpoint-then-crash and crash-then-checkpoint are two distinct failure windows
  (`sources/own-systems.md:48`).
- **risk** — The problem is one choice between two orderings, so it may be finished before the interesting part
  starts. If a spike cannot find a second axis, probably the handover to a successor
  (`sources/semantics.md:482-484`), it lands below the ramp's floor rather than on it.

---

## Reserve

Near-misses, with the one reason each missed.

| id | source | missed because |
|---|---|---|
| `precondition-precedence-ladder` | RFC 9110 §13.2.2 (`sources/rfcs.md:216-246`) | Tagged `workflow` and has strong ground truth, but it is a single-request decision procedure rather than a multi-party sequence, so the shape reads thinner than the evidence deserves. |
| `if-match-lost-update` | RFC 9110 §13.1.1 (`sources/rfcs.md:248-277`) | Secondary `concurrency`, and lost update is the problem the isolation spike already measured (`sources/README.md:112-116`) and the one the family itself calls least instructive (`sources/semantics.md:279-283`). |
| `weight-without-replicas` | `argoproj/argo-rollouts#2235` (`sources/rollout.md:217-247`) | The sharpest safety violation in the rollout survey, but no rule is stated in words anywhere in the issue (`sources/rollout.md:223-225`), so the statement has to be authored from scratch. |
| `three-versions-in-flight` | `argoproj/argo-rollouts#4390` (`sources/rollout.md:351-356`) | Same invariant as `#2235` with a third version added; a sequel rather than a standalone candidate. |
| `refresh-token-rotation` | RFC 9700 §4.14.2 (`sources/rfcs.md:586-620`) | Closest thing in the RFC survey to the learner's day job and matches his own unresolved Auth0 TODO (`sources/own-systems.md:39`), but the interesting failure, an honest retry tripping the alarm, is marked `INFERRED` rather than documented (`sources/rfcs.md:615-618`). |
| `revocation-propagation-window` | RFC 7009 §2.1 (`sources/rfcs.md:622-647`) | Same stated-negative-result structure as RFC 9111 §4.4 with weaker ground truth, and the refresh-during-revocation race is `INFERRED` (`sources/rfcs.md:644-646`). |
| `invalidation-is-not-global` | RFC 9111 §4.4 (`sources/rfcs.md:126-150`) | Excellent as a property the RFC says in advance will fail, but the machine is a cache chain and the shape competes with four other `two-store` candidates already in the twenty. |
| `negative-cache-countdown` | RFC 2308 §5, §6 (`sources/rfcs.md:1290-1333`) | Carries a liveness requirement dressed as a formatting rule, but all three verified errata are editorial and none touches §5 or §6, so the ground truth is internal corroboration only (`sources/rfcs.md:1319-1325`). |
| `ttl-signed-or-unsigned` | RFC 1035 §3.2.1 vs §4.1.3 (`sources/rfcs.md:1335-1377`) | Verified erratum 2130 plus two Standards-Track clarifications that resolve the top-bit case differently, which is unusually strong, but the exercise is closer to a field-type audit than to a system. |
| `two-sync-paths-one-copy` | OSDI '18 §4.2, ZooKeeper [74] (`sources/semantics.md:737-756`) | Called the purest `two-store` problem found anywhere, but the narrative turns on a node becoming leader, and the learner rejected consensus (`sources/semantics.md:745-749`). |
| `last-copy-discarded` | OSDI '18 §4.4, Hazelcast [82] (`sources/semantics.md:758-772`) | Tiny and catastrophic, with a one-line invariant and a four-step counterexample, which makes it a warm-up rather than a candidate slot. |
| `health-check-wrong-direction` | OSDI '18 §4.3, HDFS [77] (`sources/semantics.md:826-835`) | Four or five lines of model by the survey's own estimate; too small to carry a problem alone. |
| `one-shot-propagation-signal` | `temporalio/temporal#11842` (`sources/issues.md:368-407`) | The canonical worked example of holding the cause back, but its mechanism, a one-shot signal with no retry and no watermark, repeats several candidates already in the twenty. |
| `selective-sync-leaks-forward` | `argoproj/argo-cd#28701` (`sources/rollout.md:328-337`) | The cleanest heading cut in the rollout survey, with a literal `## Root cause`, but the cause is JSON merge-patch semantics, a serialisation detail rather than a distributed one. |
| `retry-budget-no-rollback` | `fluxcd/flux2#5916` (`sources/rollout.md:392`) | An unbounded failure counter is attractive material, but the body is symptom-only with no mechanism, so a model built from the prose cannot exhibit the violation. |
| `lease-renewed-for-deleted-node` | `kubernetes/kubernetes#116485` (`sources/issues.md:200`) | The smallest `lifecycle` instance in the issue survey, two loops over one entity where one notices deletion, and probably a one-step counterexample. |
| `rapid-reset` | RFC 9113 §5.1.2, CVE-2023-44487 (`sources/rfcs.md:785-818`) | The only candidate in any family with a CVE, and tagged `resource`, which the brief rules out. |
| `predicate-tier-anomalies` | Hermitage PMP and G2 (`sources/semantics.md:238-263, 329-346`) | The growable record domain is the most natural state-space material in any family, but the survey calls G2 "probably beyond one sitting" (`sources/semantics.md:346`). |
| `read-then-lock-identity-swap` | `temporalio/temporal#2694` (`sources/issues.md:202`) | A textbook race written out as a `T = 0..4` interleaving and very small, but the body contains the fix in Go, so the cut is larger than a heading. |
| `strategy-honoured-on-create-only` | `open-cluster-management-io/ocm#1201` (`sources/rollout.md:399`) | A natural create-path-versus-update-path pair, but the whole mechanism is "the update path does not read the strategy", which is one step. |

Explicitly excluded rather than reserved, because they already exist:
the lease-and-fencing-token problem, which appears three times over as D2, K2 and the
Jepsen etcd lock and is spiked at `spikes/fencing/` (`sources/semantics.md:1005-1011`,
`sources/README.md:130-151`); and write skew, lost update and read skew, spiked at
`spikes/isolation/` (`sources/README.md:107-116`).

---

## 1. Shape coverage of the twenty

| yardstick shape | rank | count | candidates |
|---|---|---|---|
| `workflow` | 1 | 5 | 2, 4, 6, 12, 18 |
| `two-store` | 2 | 4 | 5, 9, 15, 19 |
| `lifecycle` | 3 | 3 | 3, 8, 10 |
| `expiry` | 4 | 3 | 13, 14, 16 |
| `rollout` | 5 | 4 | 1, 7, 11, 17 |
| `delivery` (secondary) | — | 1 | 20 |
| `concurrency` (secondary) | — | 0 | — |
| `resource` | excluded | 0 | — |

`workflow` is **not** thin in the twenty, and the brief's reason for expecting it to be
does not hold. The brief says issue trackers are the only source of `workflow` and that
the family yields only 5 instances. The 5 is right for that one family
(`sources/issues.md:19-20, 427`), but the exclusivity is wrong, and two sibling surveys
say so. `sources/rfcs.md:2092` tags 5 candidates `workflow` and calls the shape
"adequately covered", and `sources/semantics.md:682` and `sources/semantics.md:803` tag
B1 and B7 `workflow`. So the shape has roughly 12 instances across the four primary
families, drawn from three of them, and the five in the twenty come from three different
families. See the discrepancy note below.

Two honest qualifications on the 5. Of the issue family's five, two are `y-` weak and one
(`temporal#2694`) is tagged `concurrency` in the survey's own appendix and counted as
`workflow` only in the summary table (`sources/issues.md:432, 466`). And the five in this
twenty are the strongest of the ~12, not a sample, so a second pass would have to go
further down each family's list.

`concurrency` is at zero by selection rather than by supply. Both candidates that reached
the shortlist, `if-match-lost-update` and `read-then-lock-identity-swap`, are in the
reserve, and the `concurrency` instances the surveys rate highest are the three the
isolation spike already measured.

---

## 2. Where the four holes are reachable

An observation about the material, not a plan. Nothing above was selected to reach a hole,
and no candidate carries a dimension target.

First, the holes themselves verified against the seven rungs rather than taken from the
brief. Rungs 1 to 7 of batch 2 are bonded-store, laytime, river-call, assay-office,
floor-malting, herbarium-sheet and estate-notice
(`authoring/bonded-store/VECTOR.md:3`, `authoring/laytime/VECTOR.md:3`,
`authoring/river-call/VECTOR.md:3`, `authoring/assay-office/VECTOR.md:3`,
`authoring/floor-malting/VECTOR.md:3`, `authoring/herbarium-sheet/VECTOR.md:3`,
`authoring/estate-notice/VECTOR.md:3`).

- **State space is 0 on all seven**, read off the vector records. A keyword sweep over the
  seven reference `.cfg` files returns only `CHECK_DEADLOCK`, `CONSTANTS`, `INVARIANTS`,
  `PROPERTIES` and `SPECIFICATION`: no `CONSTRAINT`, no `VIEW`, no `SYMMETRY`
  (`grep -hoE "^[[:space:]]*[A-Z_]+" authoring/{bonded-store,laytime,river-call,assay-office,floor-malting,herbarium-sheet,estate-notice}/reference/*.cfg | sort -u`, run 2026-10-08).
- **Representation caps at 2**, and `grep -nE "INSTANCE" authoring/*/reference/*.tla` over the
  same seven returns nothing, so **refinement is at zero** as the brief says.
- **Property kind is at 3 on five of the seven** and cannot set a new high.

One correction to the brief here, and it changes what a candidate aimed at the hole would
need. The brief says representation caps at 2 "so PlusCal never appears". PlusCal does
appear: `authoring/bonded-store/reference/BondedStore.tla:57`,
`authoring/laytime/reference/Laytime.tla:74` and
`authoring/assay-office/reference/AssayOffice.tla:61` each carry a `BEGIN TRANSLATION`
marker. What is absent is the program counter, because all three are a single unlabelled
`while (TRUE)` over an `either`, so the translator emits no `pc`
(`authoring/bonded-store/reference/BondedStore.tla:40-58`, and `grep -nE "\bpc\b"` over
the three returns nothing). The brief's own gloss, "representation 2 means no program
counter", is the accurate half. The hole is a multi-label algorithm, not PlusCal.

**Could carry a model that does not fit.** The common feature is a width or depth that the
source itself does not bound.

- `fleet-ownership-reshuffle` (15). The real event is 47 members to 48 and the mechanism is
  index-modulo-replicas over a list sorted by an unpredictable key
  (`sources/issues.md:100-107`). Three replicas by four members suffices for the invariant
  (`sources/issues.md:112-113`), but nothing in the mechanism bounds the member count, and
  the rollout survey separately measured that a percentage-valued cap rounds identically
  below about five members (`sources/rollout.md:432-436`). A model of this has a natural
  width knob that is not three.
- `observed-transaction-vanishes` (19) sits one tier below the family's predicate tier, where
  the record domain is growable by construction because the anomaly is an insert
  (`sources/semantics.md:251-254`, `sources/semantics.md:1151-1152`). Tier 4 is where a fixed
  two-row store stops working, and OTV is the last rung before it.
- `never-bounce-a-bounce` (18). The population of messages is unbounded by construction and the
  only thing bounding it is the clause under test (`sources/rfcs.md:1606-1614`). This is the
  plainest fit for bounding an infinite domain from outside the module.
- Reserve `retry-budget-no-rollback`: "`status.upgradeFailures` keeps climbing past `retries`
  with no upper bound" (`sources/rollout.md:392`) is an unbounded counter stated as the defect.
- The rollout survey's own sizing note says the dimension that costs is version *depth* rather
  than fleet width, and names three candidates needing a history rather than a set
  (`sources/rollout.md:443-448`).

**Could carry a program counter.** Each of these is a fixed statement sequence where the
failure is indexed by *which step* the interruption landed on, which is what a `pc` is for.

- `commit-permission-window` (4). The paper states the boundary positionally, three crash
  windows across two RPCs, and the middle one is the only bad one
  (`sources/semantics.md:670-676`).
- `txn-epoch-fence-vs-retry` (2). A four-step protocol where step 2's predicate misreads step
  1's output (`sources/issues.md:77-81`).
- `parent-reset-loses-child` (6) and `paused-then-running` (10) both turn on a task that was in
  flight across a transition (`sources/issues.md:56-59`, `sources/issues.md:174-176`).
- Reserve `weight-without-replicas`: "four separate writes, and one interleaving of those writes"
  (`sources/rollout.md:220-221`) is a statement sequence whose interleaving is the whole bug.

**Could carry a refinement.** Three of the twenty have an abstract and a concrete description of
the same machine already written by somebody else, which is the shape `INSTANCE` exists for.

- `imap-move-partial-failure` (5) is the strongest. The RFC states the decomposition itself: move
  is copy plus a deleted-flag store plus an expunge, "except the intermediate states produced by
  those steps do not occur" (`sources/rfcs.md:1810-1812`). An atomic move and the three-step
  sequence are an abstract and a concrete spec, and the working group wrote both. The same
  candidate is also the before-and-after pair, because RFC 6851's SHOULD and RFC 9051's MUST are
  the same paragraph one word apart (`sources/rfcs.md:1821-1828`).
- `commit-before-or-after` (20) is two concrete orderings under one abstract statement that every
  item is processed (`sources/semantics.md:463-477`).
- `observed-transaction-vanishes` (19) is one application against a graded family of environments,
  and the isolation spike already generated the levels by substituting two tokens, with
  `diff` returning two lines (`sources/README.md:118-123`).

**Property kind** is topped out and nothing above is aimed at it. Two candidates do change the
*kind of argument* rather than the level: `never-bounce-a-bounce` (18) is well-foundedness of a
growing message graph, and `ordered-update-versus-recovery` (17) asks the learner to show two
properties are jointly unsatisfiable rather than to find a violation.

**The other two farmed techniques.** A clock as a step source fits `two-clocks-one-relationship`
(16), where the RFC's own §7.1.6 note warns that a state the model needs may never appear in a
status field (`sources/rfcs.md:1029-1033`), and `check-then-use-after-timeout` (13) and
`tombstone-outlives-its-grave` (14), where a timeout and a TTL respectively are the only thing
that fires. The `notes/CHOICES.md` format, reading a published spec as a set of decisions
somebody made, fits `acme-challenge-retry-deadlock` (3), where a verified erratum literally *is*
a decision record; `mailbox-sync-cursor-identity` (8), where an entire Standards-Track extension
was published because of a decision taken in the earlier one (`sources/rfcs.md:1780-1783`); and
`ordered-update-versus-recovery` (17), where the maintainer's "This works as intended and is
documented here" is the decision and the answer at once (`sources/rollout.md:344-346`).

---

## 3. What I could not settle from the surveys

- **No survey says, for any candidate, whether it needs `CONSTRAINT`, `VIEW` or `SYMMETRY`.**
  `sources/rfcs.md:2159-2160` states plainly that "No model was written and no checker was run"
  and every size estimate is a judgement from reading. The rollout survey's sizes come from the
  issues rather than from a model (`sources/rollout.md:418`). So every state-space observation in
  §2 is material-shaped, not measured. Only the fencing and isolation spikes carry real numbers
  (`sources/README.md:98-151`).
- **Whether `issues.md` counts 19 or 21 modelable, and which two it dropped.** See the discrepancy
  note. I could not recover which of the five `y-` rows the headline excludes.
- **Whether `KAFKA-20090` collides with existing published work.** `sources/semantics.md:437-440`
  records that Vanlightly's transaction diary stops at entry 02 and that the author excludes
  fencing explicitly, which is the right direction, but nobody checked whether an entry 03 landed
  after 2026-09-06.
- **Whether the CrashTuner narratives (candidates 4 and 13) stand without the JIRA threads.**
  `sources/semantics.md:1319-1322` names this as the thing that would collapse the bug-study
  family's usable count toward zero, and no spike has tested it.
- **Whether OTV's three-transaction fixture stays inside the isolation spike's measured regime.**
  The spike ran write skew, lost update and read skew, all two-transaction
  (`sources/README.md:107-116, 188-190`). OTV is the family's only three-transaction anomaly
  (`sources/semantics.md:223-228`) and the permitted-interleaving oracle was never exercised
  against a reader that takes two reads at different points.
- **Whether `argo-cd#29410`'s cut is as clean as claimed once both failures are kept.**
  `sources/rollout.md:210-211` calls it a clean heading cut, but the statement of the second
  failure includes "no retrigger" (`sources/rollout.md:197-200`), which is mechanism. Keeping the
  second failure and holding its cause back may not both be possible.
- **The twenty are not de-duplicated against each other by mechanism.** Candidates 1, 9 and 11,
  plus reserve `helm-controller#1583` (`sources/rollout.md:393`), are all "a predicate reads a
  stale copy of a fact". The surveys do cross-survey overlap for the fencing problem
  (`sources/semantics.md:1005-1011`) but nobody did it inside the rollout family, and a step-3
  wave could discover it is building one problem four times.
- **Nothing in the surveys covers the brief's remaining hole directly.** No candidate in any
  family was recorded as requiring a multi-label algorithm, and the four techniques were farmed
  elsewhere, so the fits named in §2 are mine. `INFERRED` for all of §2's hole assignments.

---

## Discrepancies found

Reported rather than adapted to. Each carries both citations.

**D1. `issues.md`'s headline count of 19 modelable is not supported by its own appendix,
which shows 21.** The headline and the §1 table both say "19 modelable" of 24 opened
(`sources/issues.md:14-16, 239`). The appendix denominator table has 24 rows with 16
verdicts of `y` and 5 of `y-`, which is 21 modelable, and 3 of `n`
(`sources/issues.md:449-474`). The surveyor's own definitions make `y-` "modelable but weak
or out of domain" (`sources/issues.md:446-447`), so it is inside the count. The brief's figure
of 19 came from `sources/README.md:43`, which took the headline. **I could not determine
which two rows the 19 excludes.** The most likely reading is that `crdb#173315`, marked
"**rejected for this learner**" and "wrong domain" (`sources/issues.md:205, 469`), was
dropped along with one more, but the file does not say.

**D2. "Issue trackers are the only source of `workflow`" is false, and the brief repeats it.**
`sources/README.md:53` says "workflow | general issue trackers, 5 instances. Nothing else has
it". Two sibling primary surveys contradict it. `sources/rfcs.md:2092` tags 5 candidates
`workflow` and rates the shape "Adequately covered", naming the precondition ladder and the
bounce-termination argument as the best. `sources/semantics.md:682` tags B1 `workflow` and
`sources/semantics.md:803` tags B7 `workflow`. The defensible version of the claim is the
narrower one at `sources/README.md:70-71`, which scopes it to postmortems and Jepsen:
"Postmortems returned zero and Jepsen about one." The practical consequence is that the brief's
instruction to say plainly whether `workflow` is thin rests on a premise that does not hold.

**D3. `issues.md`'s project table sums to 25 opened against a stated denominator of 24.**
The §3 table (`sources/issues.md:305-317`) gives opened counts of 8, 4, 2, 1, 2, 3, 1, 2, 1 and
1, which is 25. The appendix has 24 rows (`sources/issues.md:449-474`), of which 7 are Temporal
issues, against the table's "temporal | 8 / 7". The one-row overcount is in that cell.

**D4. The same survey's shape table sums to 22 over 21 modelable, because one issue is counted
twice.** `sources/issues.md:425-434` gives 5 + 6 + 4 + 4 + 1 + 1 + 1 + 0 = 22. `temporal#2694`
is tagged `concurrency` in the appendix (`sources/issues.md:466`), is counted in the
`concurrency` row, and is also named as the third of the five `workflow` instances
(`sources/issues.md:281-282`), with the table's own `concurrency` row conceding "also readable as
`workflow`" (`sources/issues.md:432`). So the headline "five `workflow` instances" includes one
issue double-counted.

**D5. The brief's "representation caps at 2, so PlusCal never appears" overstates the hole.**
PlusCal appears in three of the seven references
(`authoring/bonded-store/reference/BondedStore.tla:57`,
`authoring/laytime/reference/Laytime.tla:74`,
`authoring/assay-office/reference/AssayOffice.tla:61`). What is missing is the program counter,
which the brief's next sentence gets right. Detail in §2.

**Counts that do hold, verified against the file each summarises:**

- **47 RFC candidates.** `sources/rfcs.md:2112` states it, and counting the numbered
  subsections across the eleven families gives 5+4+4+5+1+5+5+5+3+1+9 = 47. The shape table sums
  to 46 because §8.4's masking rule is listed untagged, which `sources/rfcs.md:2082-2083` says
  itself.
- **23 of 47 with a documented counterexample.** `sources/rfcs.md:1954`. One caveat: it is the
  author's hand tally. The per-candidate "Ground truth" fields are prose grades, not a boolean,
  so the 23 is not re-derivable row by row. It is internally consistent with the eight named
  mechanisms (`sources/rfcs.md:1960-2020`, 28 slots with acknowledged overlap) and with the 12
  candidates listed as having essentially none (`sources/rfcs.md:2022-2023`).
- **44 RFCs read in full.** The corpus list at `sources/rfcs.md:14-19` holds exactly 44 RFC
  numbers plus one draft and one `.tla` file, matching `sources/README.md:41`.
- **26 rollout modelable.** `sources/rollout.md:499`, and the enumeration adds up: 4 in §3's best
  four, 4 in the next four, and 18 in §4's tables, with the per-project distribution at
  `sources/rollout.md:501` reconciling to argo-rollouts 10, argo-cd 8, fluxcd 3, ocm 2,
  kubernetes 2, knative 1.
- **5 `workflow` instances in the issue family.** `sources/issues.md:19-20` and `:427`, subject
  to D4 above.
