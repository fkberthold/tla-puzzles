# Survey: `rollout`-shaped modelling problems in GitOps and workload-rollout trackers

**Status: complete.** Read-only survey, 2026-09-06.

Dispatched as the follow-up pass the sibling `issues.md` asked for. That survey scanned ~330
titles, opened 24, and found `rollout` at one instance out of 24 — then named where to spend a
pass: "Argo CD, Flux, Knative, Kubernetes `sig/apps`. I sampled Flux and Knative only at listing
level and opened nothing, so I make no claim about them."

## The answer in short

**Verdict: the sibling's single instance was not representative. `rollout` is the densest shape
either survey has measured.**

- ~467 title rows scanned (~440 distinct), **32 opened at primary source, 26 modelable** — 81% of
  opens, 6% of scans. The sibling got 19 of 24 opened (79%) and 6% of scans. **Per item opened,
  identical. Per shape, this pass returned 26 `rollout` instances where the sibling returned 1.**
- The gap was a **search gap, not a supply gap**. The sibling searched the vocabulary
  (`rollout`) inside general-purpose trackers. The supply lives in trackers whose *entire subject
  matter* is rollout, where nobody writes the word because it is the ambient assumption. Searching
  `abort`, `paused`, `out of sync`, `prune`, `scaled down` inside `argoproj/argo-rollouts`
  returns rollout problems at a rate no keyword returns anywhere else.
- Richest projects, in order: **argoproj/argo-rollouts**, **argoproj/argo-cd (ApplicationSet
  ProgressiveSync)**, **fluxcd (kustomize-controller + helm-controller)**,
  **open-cluster-management-io/ocm**, **kubernetes/kubernetes `sig/apps`**, **knative/serving**.
  Argo Rollouts and Argo CD carry 18 of the 26.
- **The shape stays small.** Two versions and three fleet members exhibit every interesting
  failure in the top eight. Three is enough; two is often enough. §5 gives the exceptions.
- **The cut is more expensive here than the sibling found.** 18 of 26 need no holdback or a clean
  heading cut; 8 of 26 need sentence-level surgery, against the sibling's 20 of 24 clean. §6
  explains why, and the reason is structural rather than incidental.

Denominator discipline, same as the sibling: an issue counts as *opened* only if I read its body
at primary source. Titles harvested from listings and never opened are not in the denominator.

## Method

`gh api search/issues` for listings, `gh api repos/{r}/issues/{n}` for bodies, and
`repos/{r}/issues/{n}/comments` where the body carried no diagnosis. 21 listing queries across
`argoproj/argo-rollouts`, `argoproj/argo-cd`, `org:fluxcd` (flux2, helm-controller,
kustomize-controller, source-controller, image-automation-controller, notification-controller),
`knative/serving`, `kubernetes/kubernetes` filtered on `label:sig/apps`, and
`org:open-cluster-management-io`.

Search terms: the ones the brief named — `stuck`, `drift`, `out of sync`, `paused`, `prune`,
`orphan`, `both versions`, `partially applied`, `reports healthy` — plus the ones that actually
paid, which were **domain verbs rather than failure nouns**: `abort`, `rollback`, `scaled down`,
`race`, `sync loop`, `ProgressiveSync`, `selfHeal`.

Two search notes worth carrying forward. GitHub rejects a `(repo:a OR repo:b)` parenthesised
disjunction silently — it returns `TOTAL=0` rather than an error, so a cross-repo query that
looks like it found nothing may not have run. Use `org:` or one repo at a time. And
`sort=reactions` is the right ordering for this job: it surfaces the issues other operators hit,
which are the ones written up carefully.

---

## 1. Is `rollout` actually there?

Yes, and abundantly. The ratio:

| | this pass | sibling `issues.md` |
|---|---|---|
| title rows scanned | ~467 (~440 distinct) | ~330 |
| opened at source | 32 | 24 |
| modelable | **26 (81%)** | 19 (79%) |
| `rollout`-shaped among modelable | **26 of 26** | 1 of 19 |

The per-open hit rate is the same as the sibling's, which is the useful control: this is not a
better *reading* method, it is a better *searching* target. Every one of the 26 is `rollout` by
construction, because the trackers are rollout controllers.

The six opens that were not modelable, and why, so the denominator is honest:

- `argo-rollouts#3648` — a Helm templating question mislabelled as a bug; maintainer-labelled
  `answered`. No protocol content.
- `knative/serving#11916` — "Service lets you point traffic at revisions it does not own". Real,
  but it is a missing admission check, not a convergence property. A model of it has one step.
- `knative/serving#10710` — "Rollout stuck when `rolloutDuration > 0` and
  `enable-virtualservice-status = true`". The body gives the two settings and the symptom and no
  mechanism at all, so a model built from the prose cannot exhibit the violation.
- `kubernetes/kubernetes#55072` — "ControllerRevision rollback does not handle multiple versions
  correctly". A well-stated API-typing concern with no violating sequence.
- `open-cluster-management-io/ocm#1404` — "Work-agent continues applying ManifestWork after
  deletion from hub". Body says "Occurred for once" and gives an audit log. No mechanism.
- `argo-cd#22558` — 30 comments, and the root cause is never pinned. See §2 for why this one is
  instructive rather than merely a miss.

---

## 2. Which project is richest?

**1. `argoproj/argo-rollouts` — 10 modelable of 11 opened.**

The richest, and it is not close. Blue-green and canary are *already* a two-version state machine
with a named stable side, a named canary side, a weight, a promotion gate and an abort. The
tracker's bug reports are therefore already written in the vocabulary a spec wants. The issue
template — `**Describe the bug**` / `**To Reproduce**` / `**Expected behavior**` — is the "Expected
Behavior heading" the sibling identified as the yield predictor, and Argo Rollouts users fill it
in with sequences rather than with prose.

Standing yield: `abort in:title` alone returns 41 issues, of which the first 30 by reactions
contain at least seven modelable rollout problems. `abort` is the single best keyword found in
this pass, in any tracker.

**2. `argoproj/argo-cd`, specifically ApplicationSet ProgressiveSync — 8 modelable of 9 opened.**

This is the one that matters most for the target learner, because ProgressiveSync *is* the
learner's system: an ordered rollout of a versioned config across a fleet of clusters, with
per-step cohorts, a `maxUpdate` concurrency cap, and per-app pause semantics. The
`feature:progressive-sync` label is a ready-made corpus — 50 issues (`gh api search/issues
q='repo:argoproj/argo-cd is:issue label:feature:progressive-sync'`), and the recent ones
(`#29410`, `#29347`, `#27949`) are unusually well written.

A caution. `argo-cd` as a whole is a **false-friend tracker** in the sibling's exact sense. Its
`out of sync` search returns 77 issues and most are diff-normalisation noise — a `CronJob`
apiVersion promotion, `500m` versus `0.5` CPU, `nodePort` defaulting. Yield concentrates
entirely in `component:application-sets` + `feature:progressive-sync` and in
`component:sync`. Filter on the label, not the phrase.

**3. `fluxcd` — 3 modelable of 3 opened, but a low-density tracker.**

Small sample, perfect hit rate, and the three are excellent. But getting to them cost the most
searching of any project here: `org:fluxcd is:issue label:bug ... in:title` returns 216 issues
that are overwhelmingly authentication failures, hostname resolution, CRD-not-installed and
chart-not-found. Flux issues are operator-support traffic first and design reports second. The
good ones are in `kustomize-controller` (inventory/prune) and `helm-controller`
(drift detection, remediation), not in `flux2` or `source-controller`.

**4. `open-cluster-management-io/ocm` — 2 modelable of 3 opened.**

Tiny tracker, disproportionate hit rate. It is the only project here whose model is *natively*
hub-and-spoke across a cluster fleet, so its issues come pre-sized for a fleet spec:
`ManifestWorkReplicaSet` with `rolloutStrategy: Progressive`, `PlacementDecision` objects that
shard at 100 clusters, `maxConcurrency`, `minSuccessTime`, `progressDeadline`, `maxFailures`.
Worth a dedicated pass of its own; I sampled it with two queries.

**5. `kubernetes/kubernetes` `label:sig/apps` — 2 modelable of 3 opened, from a very large pool.**

High volume, low density. `sig/apps` covers Deployment, StatefulSet, DaemonSet, Job and CronJob
controllers, and most of the traffic is pod lifecycle rather than rollout convergence — pods
stuck Terminating, orphaned pods after GC, image pull failures. The rollout problems that are
there are excellent and famous (`#67250`, `#135483`), but you scan a lot of titles per hit.

One structural advantage k8s has over everything else here: the semantics are **specified in
public documentation that maintainers quote back at reporters**, so the invariant arrives
already in quotable form. See `#67250` in §3.

**6. `knative/serving` — 1 modelable of 3 opened.**

The thinnest. 418 issues match a broad rollout-adjacent title query and most are feature requests
and networking questions. Knative's rollout model is genuinely interesting — a `Route` splitting
a percentage across immutable `Revision`s, with `latestReadyRevisionName` as a monotone latch —
but the tracker does not carry many careful reports about it. It carries exactly one outstanding
one (`#16649`), which happens to be one of the best four in this whole survey. The sibling made
no claim about Knative; the claim I can now make is **one strong candidate, thin around it**.

### The instructive miss: `argo-cd#22558`

Worth its own note because it shows where this family fails. Thirty comments, an operator who
hit it repeatedly in production, logs pasted, and the root cause is never established. The
reporter's own last word is "Not sure if this is a race, but smells like it". A model built from
that prose does not exhibit the violation, because the prose does not say what interleaving
causes it.

`#29410` — filed sixteen months later against the same feature — states the mechanism cleanly.
**The lesson for sourcing is to prefer the late, well-diagnosed report over the popular,
long-threaded one.** Comment count is a false friend the same way keyword density is: a long
thread usually means nobody found the answer.

---

## 3. The best four candidates

Chosen for a stated rule, a concrete sequence, and a small model. Ordered by how good they are,
not by project.

### 1. `argoproj/argo-cd#29410` — a step is marked complete against status from the previous revision

- **URL / state**: https://github.com/argoproj/argo-cd/issues/29410 — OPEN.
  Labels `bug/severity:major`, `bug/priority:high`, `feature:progressive-sync`.
- **Situation**: An ordered rollout across a fleet decides that cohort N is finished by reading a
  per-member status field that is refreshed asynchronously, so a member still reporting the
  *previous* revision's success is counted as having converged on the *new* one, and the next
  cohort starts.
- **The rule**, quoted from the body: "A step should only be considered complete when its member
  apps have synced (or been confirmed unchanged) **at the revision being rolled out** — e.g.,
  compare app's synced revision with the AppSet's current target revision before marking a step
  done."
- **How it breaks**, quoted: "AppSet with 3 rollingSync steps (dev cohort → canary → prod
  cohort), `maxUpdate: 1` on the last. A commit changed a template value affecting all cohorts.
  Step 1's app was still reporting Synced/Healthy from before the commit; the controller recorded
  step 1 complete and proceeded — **prod-cohort apps rolled first**, dev app never synced."
  A repro sketch is given as three numbered steps, and the observation window is named: "the
  window is the app-status refresh interval".
- **The second failure in the same issue**, and it is the better one: "Because progressive syncs
  sets `automated` sync off for member apps, the skipped app then sat OutOfSync **indefinitely**
  (no retrigger), silent." So the rollout reports complete *and* one member is permanently on the
  old version with nothing scheduled to fix it. Two of the brief's six interesting failures —
  ordering violated, and success reported while a member never converged — in one issue, from one
  cause.
- **Modelable**: yes. The whole mechanism is "the observed status of member M is a stale copy of
  M's real status, and the completion predicate reads the copy". Nothing about Argo CD's source is
  needed. The fix is equally expressible — the completion predicate must compare revisions, not
  health.
- **Size**: 3 apps in 3 steps, a global target revision, and per app: a real revision, an observed
  revision, an observed health. Roughly 3 state variables of 3 members each plus one global. Two
  members and two steps suffice for the inversion; three lets you reproduce the reported
  canary-before-prod inversion specifically.
- **Cause held back?** Yes, cleanly. Delete `## Expected` and the closing clause of `## Summary`.
  The `## What we observed` narrative survives intact and states the symptom without the cause.

**Why this one is first**: it is the target learner's system with the names changed.
Per-cluster cohorts, an ordered rollout of one commit across them, a concurrency cap, and a
member that silently stays behind.

### 2. `argoproj/argo-rollouts#2235` — traffic routed to a ReplicaSet after it was scaled to zero

- **URL / state**: https://github.com/argoproj/argo-rollouts/issues/2235 — CLOSED. Label `bug`.
- **Situation**: A canary rollout's final step reroutes traffic and retires the old version in
  four separate writes, and one interleaving of those writes leaves every routed destination
  pointing at zero pods.
- **The rule**: not stated in words anywhere in the issue — only violated. What the body gives
  instead is the violation with wall-clock timestamps, which is arguably better raw material,
  and I am flagging the absence rather than paraphrasing an invariant nobody wrote.
- **How it breaks**, quoted from the body, with the reporter's own timestamps:
  "the `service-canary` was set to `desiredWeight 100` (timestamp 11:01:09), and the old
  replicaset was scaled down to zero (timestamp 11:01:42). But this happened after `service-canary`
  was set to `desiredWeight 0` (timestamp 11:01:41) and before the `service` selector was switched
  to the new replicaset hash (timestamp 11:04:57). This caused a service outage for around 4
  minutes."
- **Modelable**: yes, and it is the sharpest safety violation in the survey. The invariant writes
  itself: *at every state, some destination carrying non-zero weight has non-zero replicas.* The
  four writes are four actions; the bug is one interleaving of them; the model needs no notion of
  Istio, Datadog or analysis runs, all of which the issue mentions and none of which the failure
  requires.
- **Size**: two ReplicaSets (stable, canary), each with a replica count; two routing facts (a
  canary weight, a stable service selector). Four actions. This is a genuinely small spec —
  smaller than most of the sibling's candidates.
- **Cause held back?** Partially. There is no diagnosis heading to delete, because the body's
  sequence *is* the diagnosis. What you hold back is the concluding sentence — "This caused a
  service outage for around 4 minutes" — and the reader has to notice the gap themselves.
  Sentence-level surgery, not a heading cut.

**Caveat worth recording**: the issue closes without a stated root cause, and the reporter's own
question — "Is setting the canary service to `desiredWeight 0` expected here?" — is never
answered. That makes it excellent as a puzzle and useless as a citation for what the fix was.

### 3. `knative/serving#16649` — a monotone latch promotes a version that never became ready

- **URL / state**: https://github.com/knative/serving/issues/16649 — OPEN. Label `kind/bug`.
- **Situation**: A router always sends traffic to the most recent version that has ever been
  marked ready. The readiness predicate is weaker than the documented one, so a version that
  never reached its required scale gets marked ready once; because the pointer only moves
  forward, traffic never goes back even after that version is later marked *not* ready.
- **The rule**, quoted from the body, which in turn quotes the project's own documentation:
  "`initial-scale` is 'the initial target scale a Revision must reach ... before it is marked as
  Ready.' A new Revision should not become `Ready`, should not be promoted to
  `Configuration.status.latestReadyRevisionName`, and should not receive route traffic until it
  reaches its initial-scale. Traffic should stay on the previous, fully-scaled Revision until
  then."
- **How it breaks**, quoted: "A new Revision can be marked `Ready=True` and latched as
  `latestReadyRevisionName` while still far below its initial-scale, so the Route shifts 100% of
  traffic to an under-provisioned Revision. **Because `latestReadyRevisionName` is monotonic, the
  route never reverts** — even after the Revision later flips `Ready=False` (e.g.
  `ProgressDeadlineExceeded`). In production this abandoned a healthy fully-scaled Revision for a
  new one running at ~15% of target replicas, which then returned 503/504s."
- **Modelable**: yes. Two orthogonal facts, both stated in prose: a readiness condition computed
  from the wrong source (`Progressing` rather than `Available`), and an early-return reconcile
  loop that skips the phase which would have corrected it. Model the reconcile as a sequence of
  phases where any phase may fail and abort the rest, and the violation appears.
- **Size**: two Revisions, a per-Revision replica count and readiness flag, one latch, one
  three-phase reconcile with a failure point. Six or seven state variables.
- **Cause held back?** Yes, near-cleanly. `## Expected Behavior` and `## Actual Behavior` are
  separate headings, and the mechanism sits in a labelled `Root cause (same on release-1.20 and
  main):` block with three bullets. Delete the block. The first paragraph of Actual Behavior still
  states the symptom and the monotonicity, which is the right amount to leave in — the
  monotonicity is what makes the failure permanent rather than transient, and a reader who does
  not know it will build the wrong model.
- **Bonus**: this is the only candidate in the survey whose failure is *irreversible*. Everything
  else eventually converges or can be nudged; here the latch has moved and there is no path back.

### 4. `open-cluster-management-io/ocm#1346` — a member is in neither shard during a two-write update

- **URL / state**: https://github.com/open-cluster-management-io/ocm/issues/1346 — OPEN. Label `bug`.
- **Situation**: A fleet's membership list is sharded across several objects because it exceeds a
  size limit. Rebalancing moves a member from one shard to the next, and the two shards are
  written one at a time, so between the writes the member belongs to nothing. A downstream
  controller reconciles in that window and deletes the member's workload.
- **The rule**, quoted from `**Expected behavior**`: "The ManagedClusterAddOn for c100 should
  remain unchanged throughout the PlacementDecision updates. The addon should not be deleted and
  recreated."
- **How it breaks**, quoted from the numbered repro:
  "inital status: **decision-1**: c1, c2 ... , **c100**  **decision-2**: c101, c102, ...
  update: **decision-1**: c0, c1, c2 ... , c99  **decision-2**: **c100**, c101, c102, ...
  5. During the time window between these two updates, **c100** exists in neither PlacementDecision
  6. The addon-management-controller reconciles during this window and deletes the
  ManagedClusterAddOn for c100. 7. When decision-2 is updated to include c100, the
  ManagedClusterAddOn is re-created."
- **Modelable**: yes, and this is the smallest model in the survey. The mechanism is "a set is
  represented as the union of two objects, the objects are updated non-atomically, and a reader
  observes the union mid-update". No product knowledge at all.
- **Size**: two shard objects, three members, one reader. Three members is exactly the right
  number: you need one member that stays in shard 1, one that crosses, and one that stays in
  shard 2, or the boundary is degenerate.
- **Cause held back?** No heading to delete. The mechanism *is* the numbered repro, and steps 5
  and 6 state it outright. To hold it back you delete steps 5–7 and keep the two-line
  before/after diagram, which is a clean enough cut but is sentence-level.

**Why this one is fourth rather than lower**: it is the purest statement in the survey of the
brief's "partially-applied change that is neither the old nor the new version", and it costs
almost nothing to build. It is a good first puzzle in a `rollout` ladder, with `#29410` as the
last one.

### The next four, briefly

Ranked immediately below, for when the top four are used up.

5. **`fluxcd/kustomize-controller#1664`** — https://github.com/fluxcd/kustomize-controller/issues/1664, CLOSED.
   Reconciliation cannot close drift it never observed. Rule quoted: "`X` can remain on the
   cluster forever as an orphan: it is no longer in git, no longer in the `Kustomization`'s
   `status.inventory`, but still labeled ... Subsequent successful reconciles do not detect it as
   prunable, because the inventory comparison no longer sees `X` in the 'old' set — the snapshot
   has already advanced past the state where `X` was present." Modelable: yes. Size: an inventory
   set, a desired set, three commits of which the middle one fails to build. **Diagnosis is
   interleaved with the symptom** — sentence-level cut.

6. **`argoproj/argo-cd#28701`** — https://github.com/argoproj/argo-cd/issues/28701, OPEN.
   The best "reports success while some members never converged" instance in the survey. Rule
   quoted: "the application controller silently turns the new **full-app** sync into a selective
   sync using the *previous* operation's `resources` filter. The sync reports `Succeeded`, so the
   degradation is invisible". Consequence quoted: "five consecutive full-app syncs were each
   silently reduced to a single-Deployment selective sync, leaving the rest of the app drifted for
   hours while every operation reported success." Modelable: yes — the mechanism is JSON
   merge-patch semantics, "a field absent from the patch retains its previous value", which is one
   line of TLA+. **Cleanest heading cut in the survey**: the issue has a literal `## Root cause`.
   Marked down only because the cause is a serialisation detail rather than a distributed one.

7. **`kubernetes/kubernetes#67250`** — https://github.com/kubernetes/kubernetes/issues/67250, CLOSED, 69 comments.
   The only candidate here where the *rule and the bug are the same thing*. Rule quoted from
   maintainer @janetkuo, quoting the Kubernetes docs: "The StatefulSet controller terminates each
   Pod, and **waits for it to transition to Running and Ready prior to updating the next Pod.**"
   Symptom quoted from the body: "when I change back the StatefulSet with an existing image, the
   StatefulSet doesn't try to remove the broken pod to replace it by a good one. It keeps trying to
   pull the non-existing image." @janetkuo's verdict: "This works as intended and is documented
   here". Modelable: yes, 3 replicas, an ordinal cursor, a per-pod version and readiness flag.
   **This is a design-tension puzzle rather than a defect puzzle** — the ordering guarantee and
   the recoverability guarantee cannot both hold, and a spec makes that visible in a way the
   69-comment thread never quite does. Body carries no diagnosis at all, so nothing to hold back.

8. **`argoproj/argo-rollouts#4390`** — https://github.com/argoproj/argo-rollouts/issues/4390, CLOSED.
   Three concurrent versions. Rule implied, mechanism quoted: "DestinationRule is still pointing
   to old-canary / old-canary scale down is triggered / new-canary is healthy but not getting
   traffic / after scale down is done, 503/UH due to no endpoints being left". Same invariant as
   `#2235` but with a third version in flight, which makes it the natural sequel. Modelable: yes.
   Size: three ReplicaSets. Diagnosis interleaved.

---

## 4. The full candidate set

The other eighteen modelable instances, compressed. Every one was opened at source.

**`argoproj/argo-rollouts`**

| # | state | one-line situation | modelable / size | cut |
|---|---|---|---|---|
| [1292](https://github.com/argoproj/argo-rollouts/issues/1292) | closed | Aborting when nothing is in progress scales the *stable* version to zero. Rule quoted from the project docs inside the issue: "This command stops progressing the current rollout and reverts all steps. The previous ReplicaSet will be active." | yes; 2 RS, 1 abort action | body has no diagnosis — nothing to hold back |
| [3331](https://github.com/argoproj/argo-rollouts/issues/3331) | closed | A third revision started while the second is in flight leaves both stuck: "The Rollout Rev 3 gets 'stuck' ... The Rollout Rev 2 is also stuck - doesn't get spun down." Expected stated: "Rev 2 should be cancelled, and spin down. Then Rev 3 should start spinning up." | yes; 3 revisions | none needed |
| [2982](https://github.com/argoproj/argo-rollouts/issues/2982) | closed | Aborting an already fully-promoted rollout hot-loops: "continuously sets and unsets the `scale-down-deadline` on the desired ReplicaSet ... up to 1000 times in a minute." A liveness/stability problem, not safety. | yes; 1 RS, 1 annotation | none needed |
| [4898](https://github.com/argoproj/argo-rollouts/issues/4898) | closed | Two independent options deadlock on abort: "the canary/new ReplicaSet is never annotated with `scale-down-deadline`, never scales down, and traffic never shifts back to stable". Two mechanisms stacked — directly relevant to the learner. | yes; 2 flags, 2 RS | Summary states the mechanism — interleaved |
| [3304](https://github.com/argoproj/argo-rollouts/issues/3304) | open | A rollback window leaves the controller inconsistent: "letting the new replicaset revision not promoted to stable". Rollback does not restore. | yes; needs revision history depth 3 | no diagnosis in body |
| [3756](https://github.com/argoproj/argo-rollouts/issues/3756) | open | Abort while paused never completes. Expected quoted: "Argo rollouts should successfully undo all changes on abort." The reporter's own workaround is the specification: unpause first. | yes; 2 booleans + a phase | no diagnosis in body |
| [4261](https://github.com/argoproj/argo-rollouts/issues/4261) | open | A paused target does not accept a scale change: "changes to the `spec.replicas` are not respected ... This seems in direct conflict with the docs claiming that HPA is still supported on a paused rollout." The brief's "paused target" shape, in its second form — the update that *should* land and does not. | yes; 1 rollout, paused flag, replica count | no diagnosis in body |
| [771](https://github.com/argoproj/argo-rollouts/issues/771) | closed | Ordering between two stacked rollout mechanisms: a GitOps controller's post-sync hooks fire while the rollout controller is still creating pods. Expectation quoted: "these hooks should be triggered after the BlueGreen deploy finishes ... and the 'active' service is pointing to the new version". | yes; 2 controllers, 1 shared health signal | no diagnosis in body |

**`argoproj/argo-cd`**

| # | state | one-line situation | modelable / size | cut |
|---|---|---|---|---|
| [29347](https://github.com/argoproj/argo-cd/issues/29347) | open | Same ordering inversion as #29410, independently reported, with the frequency measured: "It happens for in 50% of cases right now and based on my investigation it depends on ApplicationSet Controller current performance and workqueue (the faster the controller - the issue is better visible)." That last clause is a real specification hint — the bug is a race the scheduler width controls. | yes; 2 apps, 2 steps | no diagnosis in body |
| [27949](https://github.com/argoproj/argo-cd/issues/27949) | open | A change to a member's *spec* rather than to the source revision slips through the completion check. Rule quoted: "The rollout then reports complete even though the child Applications are `OutOfSync`." Six-step observed sequence given verbatim. | yes; 1 app, desired spec vs current spec vs sync status | interleaved — the numbered sequence carries the cause |
| [25193](https://github.com/argoproj/argo-cd/issues/25193) | open | A resource needing manual pruning confirmation makes an ordered rollout spin: "Sync operations are triggered over and over again (and are always marked as 'completed')". Expected quoted: "The Application 'pauses' its sync and displays 'Waiting for pruning confirmation of xyz'." A held gate that reports done. | yes; 1 app, 1 resource, 1 confirmation flag | no diagnosis in body |
| [29323](https://github.com/argoproj/argo-cd/issues/29323) | open | A paginated fleet enumeration treats a mid-page 404 as an empty result, and the empty result is read as authoritative: "a successful empty result flows straight through to prune step so a repo with more than 100 branches that has 404s on page 2 can have all of its generated apps deleted rather than the generator failing and retrying." Labels: `bug/severity:criticial`, `bug/priority:urgent`. | yes; 2 pages, N members, 1 prune step | the go snippet is a block cut |
| [18442](https://github.com/argoproj/argo-cd/issues/18442) | closed | A failed sync poisons self-heal permanently. Rule quoted from the project docs inside the issue: "Automated sync will only attempt one synchronization per unique combination of commit SHA1 and application parameters. If the most recent successful sync in the history was already performed against the same commit-SHA and parameters, a second sync will not be attempted, unless selfHeal flag is set to true." Then: "Which is not reflected in the current code". | yes; 1 revision, 1 attempt record, 1 flag | last line is a clean cut |
| [26769](https://github.com/argoproj/argo-cd/issues/26769) | closed | The mirror image of #18442 — self-heal fires when disabled, but only when two revision pointers disagree: "Reproduced only when `Sync Status revision ≠ Last Sync` revision." The two-pointer condition is the whole spec. | yes; 2 revision pointers, 1 flag | no diagnosis in body |

**`fluxcd`**

| # | state | one-line situation | modelable / size | cut |
|---|---|---|---|---|
| [flux2#5916](https://github.com/fluxcd/flux2/issues/5916) | closed | A retry budget is exhausted and the rollback it was supposed to trigger never fires: "`status.upgradeFailures` keeps climbing past `retries` with no upper bound ... no rollback row ever appears". Rollback that does not restore, in its simplest form: it does not run. | yes; a counter, a limit, a strategy enum | body is symptom-only |
| [helm-controller#1583](https://github.com/fluxcd/helm-controller/issues/1583) | open | Drift is measured against a cached rendering rather than a fresh one, so drift the cache cannot express is invisible: "Drift detection reports 'no drift' while the live cluster no longer matches what a fresh render would produce." Same family as #29410 — a predicate reading a stale copy. Labelled `blocked/upstream`. | yes; desired-cached, desired-fresh, live | `## Expected` / `## Actual` split is a clean cut |

**`open-cluster-management-io/ocm`**

| # | state | one-line situation | modelable / size | cut |
|---|---|---|---|---|
| [1201](https://github.com/open-cluster-management-io/ocm/issues/1201) | closed | A progressive rollout strategy is honoured on first creation and ignored on update: "on the initial creation, I can see the minSuccessTime followed and the rollout waits the full 2 mins before it rolls out to the next cluster. however when I apply the same MWRS with a new image, I can see that the update rolls out to both clusters at the same time". The declared strategy quoted verbatim: `maxConcurrency: 1`, `minSuccessTime: 2m`, `progressDeadline: 10m`, `maxFailures: 5%`. | yes; 2 clusters, create-vs-update path | no diagnosis in body |

**`kubernetes/kubernetes`**

| # | state | one-line situation | modelable / size | cut |
|---|---|---|---|---|
| [135483](https://github.com/kubernetes/kubernetes/issues/135483) | closed | A rollout is interrupted by a concurrent scale, and a cached copy of the intended size is never refreshed, so the controller loops between two branches forever: "The annotations are never updated, creating an infinite loop ... the deployment appears healthy while being completely stuck." | yes; a real replica count, a cached one, a branch predicate | **not holdback-able at heading level** — the causal chain is the whole of "What happened?" |

---

## 5. Does this shape stay small?

**Yes. Three fleet members is enough for every interesting failure in the top eight, and two is
often enough.** The worry in the brief — that a rollout problem might need a whole fleet — did
not materialise.

The reason is that these bugs are all about **one member being in a state the controller does not
believe it is in**, and one such member is enough. The fleet is scenery.

Sized concretely, from the issues rather than from principle:

| failure from the brief | smallest instance found | members needed |
|---|---|---|
| two versions live when the design says one | `argo-rollouts#4390` | 3 versions, 1 target |
| success reported while a member never converged | `argo-cd#29410`, `#27949`, `#28701` | 2 members |
| rollback does not restore | `flux2#5916`, `k8s#67250` | 1 target / 3 replicas |
| ordering between dependent rollouts violated | `argo-cd#29410`, `#29347`, `ocm#1201`, `argo-rollouts#771` | 2 members, 2 steps |
| paused target updated, or unpaused one not | `argo-rollouts#4261`, `#3756`, `argo-cd#25193` | 1 target |
| drift reconciliation fails to close | `kustomize-controller#1664`, `helm-controller#1583` | 1 target, 3 commits |
| partially-applied: neither old nor new | `ocm#1346`, `argo-rollouts#2235` | 3 members / 2 versions |

**Where three is not enough**, and these are worth knowing before you size a spec:

1. **Percentage-valued concurrency caps.** `argo-cd#22558` uses `maxUpdate: 100%` on some steps
   and `maxUpdate: 1` on others; `ocm#1201` uses `maxFailures: 5%`. Over three members a
   percentage rounds to the same integer as over two, so the rounding rule — the thing that
   actually causes the surprise — is invisible below about five members. If you want a puzzle
   *about* the cap, size for five. If the cap is scenery, pin it to an integer and stay at three.
2. **Sharding boundaries.** `ocm#1346` shards at 100 clusters. You do not need 100 — you need the
   *boundary* to be crossable, so two shards and three members. But you cannot go to two members,
   because then one shard is empty and the crossing is degenerate.
3. **Pagination.** `argo-cd#29323` needs at least two pages with the failure on the second, so at
   least two members and a page size of one. Cheap, but it is a second dimension.

**The dimension that actually costs, and it is not fleet size, is version depth.** Three of the
candidates need a *history* rather than a *set*: `argo-rollouts#3304` needs a rollback window of
two revisions plus a current one; `kustomize-controller#1664` needs three commits of which the
middle one is broken; `argo-cd#26769` needs two revision pointers that can disagree.
`knative#16649`'s latch needs only two revisions but needs them ordered. Budget for depth 3 on
one axis rather than width 5 on another.

---

## 6. Can the cause be held back?

**Partly, and less cleanly than the sibling found.** The sibling reported 20 of 24 as a
heading-level or comment-level deletion. Here the honest split is three ways:

| | count | share |
|---|---|---|
| body carries no diagnosis at all — nothing to hold back | 12 | 46% |
| diagnosis under its own heading or block — clean cut | 6 | 23% |
| diagnosis interleaved with the repro or the symptom — sentence-level surgery | 8 | 31% |

So 18 of 26 are free or cheap, against the sibling's 20 of 24. The difference is real and it has
a structural cause worth stating plainly, because it will recur on any future rollout pass:

**In a rollout issue the interleaving is the diagnosis, and the interleaving lives in the repro
steps, which you cannot delete without deleting the puzzle.** `ocm#1346` step 5 —
"During the time window between these two updates, **c100** exists in neither PlacementDecision" —
is simultaneously the reproduction instruction and the entire answer. `argo-rollouts#2235` is four
timestamps: strip them and there is no issue left, keep them and the reader has the answer.
Compare the sibling's `temporal#10639`, where the numbered sequence is a *scenario* and the
diagnosis is a separate sentence about transfer tasks.

Two practical consequences.

**First, the 46% that carry no diagnosis are the best raw material, not the worst.** An
argo-rollouts bug report typically gives a precise symptom, a precise reproduction, an "Expected
behavior" heading, and no cause at all — because the reporter did not know it. That is exactly a
puzzle statement. `#3331`, `#2982`, `#1292`, `#3756`, `#4261`, `#3304` and `#771` are all in this
bucket, and they need no editing whatsoever. The Argo Rollouts issue template is doing the work
the sibling's heading-deletion was doing by hand.

**Second, prefer projects whose issue templates split expectation from mechanism.** Ranked by how
cheap the cut is: `argo-cd` (authors add their own `## Root cause`), `knative/serving`
(`## Expected Behavior` / `## Actual Behavior` are mandatory), `fluxcd` (`### Describe the bug`
plus author-added `## Summary`), `argo-rollouts` (usually nothing to cut),
`open-cluster-management-io/ocm` (mechanism lives in the repro),
`kubernetes/kubernetes` (worst — `### What happened?` invites reporters to dump symptom and
diagnosis into one field, which is precisely what `#135483` does).

---

## Counts

- **21** listing queries across 6 projects / 12 repositories.
- **~467** title rows returned, **~440** distinct after cross-query duplicates.
- **32** issues opened at primary source (body read in full).
- **2** comment threads read in full (`argo-cd#22558`, `kubernetes#67250`).
- **26** modelable (81% of opens, ~6% of scans).
- **26 of 26** are `rollout`-shaped, by construction of the target selection.
- Distribution of the 26: argo-rollouts 10, argo-cd 8, fluxcd 3, ocm 2, kubernetes 2, knative 1.

---

## Verdict

**`rollout` is a sourced shape, not an authored one, and it is the densest of the shapes either
survey has measured.** The sibling's single instance was an artefact of where it looked, not of
what exists.

Against the sibling's own scoring: `rollout` matches the issue-tracker family on per-open yield
(81% against 79%) and on scan efficiency (~6% both), and it beats every shape the sibling
reported on *supply* — 26 instances from 32 opens, where `workflow`, the shape that justified the
sibling's whole redirect, produced five instances with two strong. There is enough here for a
curriculum ladder several beads deep without leaving `argoproj`.

Where it is worse than the sibling's family: **the cut costs more**. 31% need sentence-level
editing rather than a heading deletion, because in a rollout report the interleaving that causes
the failure is the same text as the reproduction that demonstrates it. Budget editing time
accordingly, and prefer the 46% that state no cause at all — those are ready as written.

Three findings I did not expect and would carry into any further pass:

1. **Search the domain verb, not the failure noun.** `abort` inside `argo-rollouts` outperformed
   every term the brief supplied. `stuck`, `drift` and `orphan` returned mostly environment
   failures. The sibling's "search for the situation, not the vocabulary" generalises further than
   it stated: inside a specialist tracker, search the *specialist's* vocabulary.
2. **Comment count is a false friend, exactly as keyword density is.** `argo-cd#22558` has 30
   comments and no answer; `#29410` has one comment and the whole mechanism. A long thread usually
   means nobody found the cause. Sort by reactions, then prefer the *late* report over the
   *popular* one — a well-diagnosed re-report of an old bug is the best single signal in this
   family.
3. **`open-cluster-management-io/ocm` is under-surveyed and should get its own pass.** Two queries
   returned two of the twenty-six, from a 402-issue tracker (1,206 across the org), and it is the only
   project here that is natively about a fleet of clusters rather than a fleet of pods. Its
   `ManifestWorkReplicaSet` rollout strategy — `maxConcurrency`, `minSuccessTime`,
   `progressDeadline`, `maxFailures` as a percentage — is the closest published analogue to the
   learner's per-cluster version files that this pass found anywhere.
