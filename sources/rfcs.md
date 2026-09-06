# RFCs and published standards as a source of formal-modelling practice problems

**Survey date**: 2026-09-06. **Status**: complete for the named coverage list;
see the coverage note at the end for what was not read.

**Method**: every RFC cited below was downloaded in full from `rfc-editor.org`
and read locally, not summarised from memory. Normative sentences are quoted
verbatim from the downloaded text. Where a claim rests on my own judgement
rather than on the document, it carries the marker `INFERRED`.

**Errata** were checked per RFC through `https://www.rfc-editor.org/errata_search.php?rfc=NNNN`,
for 31 RFCs. Counts appear in the ground-truth field of each candidate.

**Corpus fetched 2026-09-06** via `curl https://www.rfc-editor.org/rfc/rfcNNNN.txt`:
1035, 1047, 1337, 2180, 2181, 2308, 3501, 3834, 5321, 5681, 5861, 5961, 6238,
6265, 6298, 6455, 6528, 6749, 6781, 6851, 7009, 7162, 7231, 7234, 7413, 7519,
7583, 7636, 8246, 8441, 8446, 8555, 8628, 8767, 9002, 9051, 9110, 9111, 9112,
9113, 9114, 9293, 9530, 9700, plus `draft-ietf-httpapi-idempotency-key-header-07`
and `chatmail/models/fetching/deltachat.tla`.

**One convention.** A handful of claims about operational evidence — MTA
documentation, client bug trackers, server implementation details — were
gathered by a delegated search rather than fetched by me, and each is marked
"relayed" where it appears. Everything quoted from an RFC, from an errata entry,
or from the Delta Chat TLA+ file was read directly. Where a relayed claim was
load-bearing I re-verified it, and said so.

---

## Reading the shape field

Each candidate is tagged with exactly one of `lifecycle`, `two-store`,
`delivery`, `expiry`, `rollout`, `concurrency`, `resource`, `workflow`. Where a
candidate could plausibly take two, I picked the one the *normative text* is
organised around, not the one the mechanism reminds me of. Coverage across the
eight is reported in the answers section.

---

# 1. HTTP caching — RFC 9111

<https://www.rfc-editor.org/rfc/rfc9111.html>

RFC 9111 is 84 KB and structurally the friendliest document in this survey. It
is written as a small number of numbered predicates over a store, and the
predicates are already close to TLA+ shape: "A cache MUST NOT store a response
to a request unless: [seven bullets]" (§3), "a cache MUST NOT reuse a stored
response unless: [five bullets]" (§4). Those are literally guards.

## 1.1 The storable / reusable pair

- **Standard and section**: RFC 9111 §3 (Storing Responses in Caches) and §4
  (Constructing Responses from Caches).
  <https://www.rfc-editor.org/rfc/rfc9111.html#section-3>,
  <https://www.rfc-editor.org/rfc/rfc9111.html#section-4>
- **The situation**: a shared cache sits between many clients and one origin,
  deciding for each response whether to keep it and for each request whether to
  answer from what it kept.
- **The property**: §4 — "When presented with a request, a cache MUST NOT reuse
  a stored response unless: [...] the stored response is one of the following:
  fresh (see Section 4.2), or allowed to be served stale (see Section 4.2.4), or
  successfully validated (see Section 4.3)." Paired with §4.2.4 — "A cache MUST
  NOT generate a stale response unless it is disconnected or doing so is
  explicitly permitted by the client or origin server".
- **Shape**: `two-store`.
- **The interesting mistake**: the disjunction in §4 is three-way and the third
  arm, "successfully validated", resets the age clock rather than bypassing it.
  An implementer who models validation as "answer from cache anyway" loses the
  §4.3.4 freshening step and the store never converges. A second one: §4
  requires "a cache MUST generate an Age header field [...] replacing any
  present in the response" only when the response is used *without* validation —
  and an implementation that always sets Age double-counts after a 304.
- **Ground truth**: weak. RFC 9111 has 1 reported and 1 rejected erratum
  (errata_search, 2026-09-06); neither bears on this. The strong external
  ground truth is not in the RFC — it is the fact that RFC 9111 is
  interoperability-tested by a public conformance suite,
  <https://cache-tests.fyi/>, whose landing page describes itself as presenting
  "test results interspersed with the current specification text" against
  RFC 9111. Its repository is `http-tests/cache-tests`, whose top contributor
  by commit count is `mnot` — Mark Nottingham, one of RFC 9111's own editors
  (GitHub contributors API, 2026-09-06). That suite is a published list of the
  behaviours real caches get wrong, test by test, keyed to the section each test
  covers. `INFERRED` that its test list maps cleanly onto model-checkable
  properties; the mapping is plausible because each test is anchored to spec
  text, but I did not read the test bodies.
- **Size**: 3 actors (client, cache, origin), 4-5 pieces of state (stored
  response, its stored age/date, origin's current representation and its
  validator, a clock).

## 1.2 Freshness as an arithmetic predicate

- **Standard and section**: RFC 9111 §4.2, §4.2.1, §4.2.3.
  <https://www.rfc-editor.org/rfc/rfc9111.html#section-4.2>
- **The situation**: a cache decides whether what it holds has expired, using
  its own clock, the origin's `Date`, and an `Age` value that upstream caches
  may have already incremented.
- **The property**: the RFC states the predicate as an equation rather than a
  MUST — "The calculation to determine if a response is fresh is:
  `response_is_fresh = (freshness_lifetime > current_age)`" (§4.2) — and then
  gives `current_age` a five-line derivation in §4.2.3:
  `apparent_age = max(0, response_time - date_value)`,
  `corrected_age_value = age_value + response_delay`,
  `resident_time = now - response_time`,
  `current_age = corrected_initial_age + resident_time`.
  The MUSTs around it are the ones worth stating: "A cache recipient MUST NOT
  allow local time zones to influence the calculation or comparison of an age or
  expiration time" (§4.2) and "A cache without a clock (Section 5.6.7 of [HTTP])
  MUST revalidate stored responses upon every use" (§4).
- **Shape**: `expiry`.
- **The interesting mistake**: `current_age` is deliberately *conservative* —
  it is the maximum of two independent estimates, so a chain of caches
  over-reports age rather than under-reports it. The invariant a learner should
  try and fail to prove is the tempting one: that a response is never served
  after its true expiry. It is not — clock skew between origin and cache breaks
  it, which is exactly why the RFC computes an over-estimate. The interesting
  model is a two-cache chain where the middle cache's clock is wrong; the
  property that survives is monotonicity of reported age along the chain, not
  absolute correctness.
- **Ground truth**: partial. The RFC gives the derivation but does not state the
  invariant, so the learner is proving something the document does not assert.
  `INFERRED` that the conservative-estimate reading is the intent; the RFC only
  says "Note that this calculation is intended to reduce clock skew by using the
  clock information provided by the origin server whenever possible" (§4.2.1).
- **Size**: 3-4 actors (origin, two chained caches, client), 6 numbers.

## 1.3 Invalidation on unsafe methods, and its stated non-guarantee

- **Standard and section**: RFC 9111 §4.4 (Invalidating Stored Responses).
  <https://www.rfc-editor.org/rfc/rfc9111.html#section-4.4>
- **The situation**: a client PUTs to a resource through one of several caches;
  the other caches never see the write.
- **The property**: "A cache MUST invalidate the target URI (Section 7.1 of
  [HTTP]) when it receives a non-error status code in response to an unsafe
  request method". And the safety rail: "However, a cache MUST NOT trigger an
  invalidation under these conditions if the origin (Section 4.3.1 of [HTTP]) of
  the URI to be invalidated differs from that of the target URI (Section 7.1 of
  [HTTP]).  This helps prevent denial-of-service attacks."
- **Shape**: `two-store`.
- **The interesting mistake**: this is the best candidate in the whole survey
  for a property the learner should expect to hold and which the RFC explicitly
  says does not. §4.4 closes with: "Note that this does not guarantee that all
  appropriate responses are invalidated globally; a state-changing request would
  only invalidate responses in the caches it travels through." A learner who
  writes "after a successful PUT, no cache holds a stale representation" gets a
  counterexample, and the RFC tells them in advance that they will. That is a
  built-in counterexample, which the brief correctly says RFCs usually lack.
- **Ground truth**: strong and unusual — the RFC states the negative result
  itself. Additionally the cross-origin MUST NOT names a threat class
  ("denial-of-service attacks") rather than leaving it implicit.
- **Size**: 4 actors (client, two caches, origin), 3 pieces of state.

## 1.4 Vary and the multi-representation cache key

- **Standard and section**: RFC 9111 §4.1.
  <https://www.rfc-editor.org/rfc/rfc9111.html#section-4.1>
- **The situation**: one URI has several stored responses, each keyed by the
  request headers the origin nominated in `Vary`, and the cache must pick.
- **The property**: "the cache MUST NOT use that stored response without
  revalidation unless all the presented request header fields nominated by that
  Vary field value match those fields in the original request (i.e., the request
  that caused the cached response to be stored)." Plus the two edge rules: "If
  (after any normalization that might take place) a header field is absent from
  a request, it can only match another request if it is also absent there." and
  "A stored response with a Vary header field value containing a member '*'
  always fails to match."
- **Shape**: `two-store`.
- **The interesting mistake**: absent-matches-absent. The natural implementation
  keys on the *values* of the nominated headers and treats a missing header as
  the empty string, which silently merges "no Accept-Encoding" with
  "Accept-Encoding: " — and then a gzip body is served to a client that cannot
  decode it. §4.1 also carries a rare SHOULD written for a bug in the wild:
  "Some resources mistakenly omit the Vary header field from their default
  response".
- **Ground truth**: moderate. Vary mishandling is a named and catalogued web
  cache poisoning class; <https://cache-tests.fyi/> has a dedicated Vary section.
  `INFERRED` that the CVE record for cache-key confusion is dominated by this
  and by unkeyed-header bugs; I did not enumerate CVEs.
- **Size**: 3 actors, N stored responses keyed by a small header set.

## 1.5 Freshening a stored response from a 304

- **Standard and section**: RFC 9111 §4.3.4.
  <https://www.rfc-editor.org/rfc/rfc9111.html#section-4.3.4>
- **The situation**: a cache holds several stored responses for a URI, sends
  one conditional request naming several validators, and gets back a single 304
  it must apply to the right subset.
- **The property**: "If the new response contains one or more 'strong
  validators' (see Section 8.8.1 of [HTTP]), then each of those strong
  validators identifies a selected representation for update. [...] If none of
  the initial set contains at least one of the same strong validators, then the
  cache MUST NOT use the new response to update any stored responses." and
  "For each stored response identified, the cache MUST update its header fields
  with the header fields provided in the 304 (Not Modified) response, as per
  Section 3.2."
- **Shape**: `two-store`.
- **The interesting mistake**: the three-way first-match filter degrades from
  strong validators to weak to none, and the *none* arm only fires when there is
  exactly one stored response and it too lacks a validator. An implementer who
  collapses this to "apply the 304 to whatever we asked about" corrupts a
  representation with another representation's headers. §3.2 then adds an
  exception list to the update itself — `Content-Length` is excluded, and a
  cache that stores decoded bodies "MAY omit these header fields from updating".
- **Ground truth**: weak. No erratum. The exception list is a MAY, so
  conformance is genuinely loose here. Say plainly: nothing outside the
  learner's own reasoning settles the interesting cases.
- **Size**: 3 actors, N stored responses, 1 in-flight validation.

---

# 2. HTTP conditional requests — RFC 9110 §13

<https://www.rfc-editor.org/rfc/rfc9110.html#section-13>

## 2.1 The precondition precedence ladder

- **Standard and section**: RFC 9110 §13.2.2 (Precedence of Preconditions).
  <https://www.rfc-editor.org/rfc/rfc9110.html#section-13.2.2>
- **The situation**: a request arrives carrying several conditional headers at
  once, and the server has to decide in one pass whether to apply the method,
  return 304, return 412, or ignore a Range.
- **The property**: "A recipient cache or origin server MUST evaluate the
  request preconditions defined by this specification in the following order:"
  followed by six numbered steps with explicit fall-through. The rationale is
  stated, and it is the property: "since 'lost update' preconditions have more
  strict requirements than cache validation, a validated cache is more efficient
  than a partial response, and entity tags are presumed to be more accurate than
  date validators."
- **Shape**: `workflow`.
- **The interesting mistake**: this is a six-branch decision procedure with
  guards that reference each other ("When recipient is the origin server,
  If-Match is not present, and If-Unmodified-Since is present"). The plausible
  bug is evaluating If-None-Match before If-Match, which turns a lost-update
  guard into a cache revalidation and lets the overwrite through with a 304. The
  checkable statement: under the mandated order, a request carrying a stale
  If-Match can never reach step 6. Under a permuted order it can.
- **Ground truth**: **strong, and the best kind in this family.** The document
  ships the correct ordering *and* the reason, so a learner can permute the
  order and check that the stated rationale breaks. Separately, RFC 9111 §4.3.2
  has a **rejected** erratum (ID 7695, rejected 2024-01-16 by Francesca
  Palombini) arguing that caches must forward If-Match and If-Unmodified-Since
  to the origin; the rejection is itself a datum about what the ordering does
  and does not require. RFC 9110 carries 6 verified errata overall, and **none of
  them touches §13** — I read the section list on the errata page — so the
  ordering as published is stable and uncontested.
- **Size**: 2 actors (client, origin server), 4 booleans plus a resource
  validator. **This is an evening's work and no more.**

## 2.2 Lost update prevention with If-Match

- **Standard and section**: RFC 9110 §13.1.1 (If-Match), §13.1.2 (If-None-Match).
  <https://www.rfc-editor.org/rfc/rfc9110.html#section-13.1.1>
- **The situation**: two clients read the same resource, both edit, both write
  back with `If-Match` carrying the ETag they read.
- **The property**: "An origin server that evaluates an If-Match condition MUST
  NOT perform the requested method if the condition evaluates to false." and
  the strength requirement: "An origin server MUST use the strong comparison
  function when comparing entity tags for If-Match (Section 8.8.3.2), since the
  client intends this precondition to prevent the method from being applied if
  there have been any changes to the representation data."
- **Shape**: `concurrency`.
- **The interesting mistake**: the RFC deliberately punches a hole in the
  guarantee and explains the hole. "Alternatively, if the request is a
  state-changing operation that appears to have already been applied to the
  selected representation, the origin server MAY respond with a 2xx (Successful)
  status code". And then, remarkably, it names the exact failure that hole
  causes: "For example, multiple user agents writing to a common resource as a
  semaphore (e.g., a nonatomic increment) are likely to collide and potentially
  lose important state transitions.  For those kinds of resources, an origin
  server is better off being stringent in sending 412 for every failed
  precondition on an unsafe method."
- **Ground truth**: **strong.** The RFC names the counterexample — nonatomic
  increment under the permissive 2xx option — in prose, in the section that
  defines the mechanism. A learner can model both options and show that the
  permissive one loses an increment. That is a documented counterexample with a
  documented remedy.
- **Size**: 3 actors (two clients, one origin), 2 pieces of state (value, ETag).
  **Very small. Probably the single best starter problem in this survey.**

## 2.3 Weak versus strong validators

- **Standard and section**: RFC 9110 §8.8.1.
  <https://www.rfc-editor.org/rfc/rfc9110.html#section-8.8.1>
- **The situation**: the origin assigns validators to representations; caches
  and range-resumers compare them; a validator that is not unique-per-byte-image
  makes one of those comparisons unsound.
- **The property**: definitional rather than a MUST — "A 'strong validator' is
  representation metadata that changes value whenever a change occurs to the
  representation data that would be observable in the content of a 200 (OK)
  response to GET." plus the usage rule: "Strong validators are usable for all
  conditional requests, including cache validation, partial content ranges, and
  'lost update' avoidance.  Weak validators are only usable when the client does
  not require exact equality with previously obtained representation data".
- **Shape**: `concurrency`.
- **The interesting mistake**: the RFC hands you the counterexample generator —
  "a representation's modification time, if defined with only one-second
  resolution, might be a weak validator if it is possible for the representation
  to be modified twice during a single second and retrieved between those
  modifications." Model a resource with a one-second clock, two writes in a
  tick, a reader in between, and the strong-validator definition is violated by
  construction. It is the classic ABA under a different name.
- **Ground truth**: **strong.** The sub-second double-modification is a stated,
  named hazard in the normative text. This is worth pairing with 2.2 rather than
  standing alone.
- **Size**: 2 actors, 3 pieces of state, one coarse clock. Tiny.

## 2.4 Range requests and If-Range resumption

- **Standard and section**: RFC 9110 §14 (Range Requests), §13.1.5 (If-Range),
  and the resumption interaction at §13.2.2 step 5.
  <https://www.rfc-editor.org/rfc/rfc9110.html#section-14>
- **The situation**: a client resumes an interrupted download by asking for the
  remaining bytes, and the representation may have changed underneath it.
- **The property**: §13.2.2 step 5 — "When the method is GET and both Range and
  If-Range are present, evaluate the If-Range precondition: if true and the
  Range is applicable to the selected representation, respond 206 (Partial
  Content); otherwise, ignore the Range header field and respond 200 (OK)."
  Paired with RFC 9111 §3.3: "A cache MUST NOT use an incomplete response to
  answer requests unless the response has been made complete, or the request is
  partial and specifies a range wholly within the incomplete response."
- **Shape**: `resource`.
- **The interesting mistake**: the safe outcome of a failed If-Range is a *full*
  200, not a 412 and not a 416 — the server silently upgrades the request. An
  implementer who returns 206 on a changed representation splices two versions
  of a file together, and the client's byte count still adds up. This is a
  genuinely nasty real bug and the property that catches it is short: every
  assembled body is a contiguous slice of one single version.
- **Ground truth**: moderate. The mechanism is normative and the failure is
  reachable from the text, but no erratum or BCP names it. `INFERRED` that
  version-splicing on resume is a real-world implementation bug class; I did not
  find a citation for it in the survey window.
- **Size**: 2-3 actors, a byte range plus a version counter. Small, and it needs
  a modelling decision the learner has to make (how to abstract bytes) that the
  RFC does not make for them — which is a mark against it as a *first* problem.

---

# 3. TCP connection management — RFC 9293

<https://www.rfc-editor.org/rfc/rfc9293.html>

RFC 9293 (2022) replaced RFC 793 and folded in RFC 1122 and about a dozen
others. It is 263 KB and is emphatically *not* an evening's work as a whole.
The connection state machine, isolated from sequence numbers, congestion
control, and windows, is.

## 3.1 The connection state machine against its own published diagram

- **Standard and section**: RFC 9293 §3.3.2 (State Machine Overview, containing
  Figure 5) checked against §3.10.7 (Segment Arrives).
  <https://www.rfc-editor.org/rfc/rfc9293.html#section-3.3.2>
- **The situation**: two TCP endpoints, each holding one of eleven states,
  driven by user calls and by arriving segments carrying SYN/ACK/FIN/RST.
- **The property**: the eleven states and their transitions are given as an
  ASCII diagram — "Figure 5: TCP Connection State Diagram" — under an explicit
  warning: "NOTA BENE: This diagram is only a summary and must not be taken as
  the total specification.  Many details are not included." The specific
  normative requirements around it are labelled: "A TCP implementation MUST
  support simultaneous open attempts (MUST-10)." and "Note that a TCP
  implementation MUST keep track of whether a connection has reached
  SYN-RECEIVED state as the result of a passive OPEN or an active OPEN
  (MUST-11)." and "When a connection is closed actively, it MUST linger in the
  TIME-WAIT state for a time 2xMSL (Maximum Segment Lifetime) (MUST-13)."
- **Shape**: `lifecycle`.
- **The interesting mistake**: **the diagram is wrong, and the RFC and its
  errata both say so.** The document itself lists three of its own gaps:
  "Note 2: The figure omits a transition from FIN-WAIT-1 to TIME-WAIT if a FIN
  is received and the local FIN is also acknowledged." and "Note 3: A RST can be
  sent from any state with a corresponding transition to TIME-WAIT [...] These
  transitions are not explicitly shown; otherwise, the diagram would become very
  difficult to read." And a **verified erratum** adds a fourth: errata ID 8710,
  reported by Noga H. Rotman 2026-01-21, verified by G Fairhurst 2026-02-11,
  against §3.3.2 Figure 5 — the edge label should read "rcv RST/SYN" rather than
  "rcv RST", because "Section 3.10.7.4 specifies two cases in which a connection
  in SYN-RECEIVED, reached via a passive OPEN, returns to LISTEN: when a RST is
  received and when a SYN is received.  Figure 5's edge label and Note 1
  currently mention only the RST-based case."
  <https://www.rfc-editor.org/errata_search.php?rfc=9293>
- **Ground truth**: **among the very best in this survey.** There is a
  published state diagram, an official list of the ways it is incomplete, and a
  *verified erratum recording a fifth way that a reader found and the IETF
  agreed with*. A learner who models Figure 5 and then checks it against the
  §3.10.7 event-processing rules is re-deriving errata 8710. The answer key
  exists and was written by someone else.
- **Size**: 2 actors, 11 states each, 4 message flags, 1 timer. The state count
  is high but the state *per actor* is a single enum. Feasible in an evening if
  sequence numbers are abstracted away — and abstracting them away is exactly
  what Figure 5 already does.

## 3.2 Simultaneous open and simultaneous close

- **Standard and section**: RFC 9293 §3.5 Figure 7 (Simultaneous Connection
  Synchronization) and §3.6 Figure 13 (Simultaneous Close Sequence).
  <https://www.rfc-editor.org/rfc/rfc9293.html#section-3.5>
- **The situation**: both endpoints actively open, or both actively close, with
  no listener and no leader.
- **The property**: §3.5 — "Simultaneous initiation is only slightly more
  complex, as is shown in Figure 7.  Each TCP peer's connection state cycles
  from CLOSED to SYN-SENT to SYN-RECEIVED to ESTABLISHED." §3.6 case 3 — "A
  simultaneous CLOSE by users at both ends of a connection causes FIN segments
  to be exchanged (Figure 13).  When all segments preceding the FINs have been
  processed and acknowledged, each TCP peer can ACK the FIN it has received.
  Both will, upon receiving these ACKs, delete the connection." Both figures
  are printed as message-sequence traces.
- **Shape**: `lifecycle`.
- **The interesting mistake**: the CLOSING state exists *only* for the
  simultaneous case and is unreachable in the normal close. An implementation
  that never enters CLOSING passes every ordinary test and deadlocks the first
  time both sides close at once. The model-checking payoff is direct: the
  liveness property "every ESTABLISHED connection eventually reaches CLOSED"
  fails under simultaneous close if CLOSING is missing, and the counterexample
  is Figure 13.
- **Ground truth**: **strong.** Figures 7 and 13 are printed traces — a
  published expected behaviour in exactly the form a model checker emits. Also
  the labelled requirement MUST-10 makes support mandatory rather than optional.
- **Size**: 2 actors, 11 states, 3 flags. **The single best-sized slice of
  RFC 9293** — this is Figure 5 minus everything except the close half.

## 3.3 TIME-WAIT and the 2MSL timer

- **Standard and section**: RFC 9293 §3.6.1, and RFC 1337 "TIME-WAIT
  Assassination Hazards in TCP".
  <https://www.rfc-editor.org/rfc/rfc9293.html#section-3.6.1>,
  <https://www.rfc-editor.org/rfc/rfc1337.html>
- **The situation**: an endpoint has closed but must refuse to forget the
  connection for 2MSL so that a delayed segment from the old incarnation cannot
  be accepted by a new one on the same four-tuple.
- **The property**: RFC 9293 §3.6.1 — "When a connection is closed actively, it
  MUST linger in the TIME-WAIT state for a time 2xMSL (Maximum Segment Lifetime)
  (MUST-13).  However, it MAY accept a new SYN from the remote TCP endpoint to
  reopen the connection directly from TIME-WAIT state (MAY-2), if it: (1)
  assigns its initial sequence number for the new connection to be larger than
  the largest sequence number it used on the previous connection incarnation,
  and (2) returns to TIME-WAIT state if the SYN turns out to be an old
  duplicate."
- **Shape**: `expiry`.
- **The interesting mistake**: **RFC 1337 prints the counterexample as a
  trace.** "Our new observation is that (4) is unreliable: TIME-WAIT state can
  be prematurely terminated ('assassinated') by an old duplicate data or ACK
  segment from the current or an earlier incarnation of the same connection."
  Its Figure 1 is a seven-line message-sequence chart ending in
  "5.3  CLOSED      <-- <SEQ=301><CTL=RST>             <--  ????
  (prematurely)". And it names the three consequences: "H1.  Old duplicate data
  may be accepted erroneously.  H2.  The new connection may be de-synchronized,
  with the two ends in permanent disagreement on the state.  Following the spec
  of RFC-793, this desynchronization results in an infinite ACK loop."
- **Ground truth**: **strong, and the closest thing in this survey to a
  published TLA+ error trace.** RFC 1337 Figure 1 is a state-by-state
  counterexample to a safety property, printed in 1992, in the format a model
  checker uses. The learner writes "no segment from a closed incarnation is
  accepted by a new one", checks it, and gets Braden's trace back.
- **Size**: 2 actors, a small state enum, one timer, one in-flight old
  duplicate. Small — but it needs sequence numbers, which is the modelling cost
  the two candidates above avoid.

## 3.4 The TCP requirement summary table

- **Standard and section**: RFC 9293 Appendix B (TCP Requirement Summary),
  adapted from RFC 1122.
  <https://www.rfc-editor.org/rfc/rfc9293.html#appendix-B>
- **The situation**: 144 labelled requirements (`MUST-nn`, `SHLD-nn`, `MAY-nn`,
  `MUST-NOT-nn`) each with a row in a six-column conformance table.
- **The property**: not one property — a machine-readable-ish conformance
  matrix. Its value here is as a *checklist against a model*: every `MUST-` label
  the model does not encode is a stated gap.
- **Shape**: `workflow`.
- **The interesting mistake**: the table and the prose can disagree. A
  **verified erratum** records exactly that: errata ID 8171, reported by
  Christopher Williams 2024-11-06, verified 2025-03-18, against Appendix B —
  "This requirement has an X in the 'MUST' column, but the X should be in the
  'SHOULD' column.  The relevant text for this requirement is 'a TCP
  implementation ... SHOULD make the information available to the application
  (SHLD-25).'"
- **Ground truth**: **strong for a narrow purpose.** A verified erratum
  demonstrating a table/prose mismatch is precisely the sort of thing a
  cross-check finds. But this is a consistency audit, not a system model, so it
  is a poor fit for the learner's stated want. Listed for completeness.
- **Size**: not a model. Skip.

---

# 4. OAuth 2.0 — RFC 7636, RFC 8628, RFC 7009, RFC 9700

**This family has the best ground truth in the survey**, and for a reason that
is worth stating separately from any individual candidate. RFC 9700 (BCP 240,
"OAuth 2.0 Security Best Current Practice", January 2025) does two things no
other document here does.

First, **it publishes a labelled attacker model**. §3 defines attackers (A1)
through (A5) — web attacker, network attacker, an attacker who "can read, but
not modify, the contents of the authorization response", one who can read the
request, one who "can acquire an access token issued by an authorization
server". A learner modelling OAuth does not have to invent the environment; the
RFC supplies it, already discretised.
<https://www.rfc-editor.org/rfc/rfc9700.html#section-3>

Second, **it says that model came from formal analysis and cites the paper**:
"The aforementioned attackers (A1) and (A2) conform to the attacker model that
was used in formal analysis efforts for OAuth [arXiv.1601.01229]. This is a
minimal attacker model." The reference resolves to Fett, Küsters and Schmitz,
"A Comprehensive Formal Security Analysis of OAuth 2.0", arXiv:1601.01229,
DOI 10.48550/arXiv.1601.01229. RFC 9700 also cites Bansal, Bhargavan,
Delignat-Lavaud and Maffeis, "Discovering concrete attacks on website
authorization by formal analysis", *Journal of Computer Security* 22(4):601-657,
DOI 10.3233/JCS-140503.

Third, there is an **executable conformance suite** as well: the OpenID
Foundation's, at <https://gitlab.com/openid/conformance-suite>, which the
Foundation describes as covering "OpenID Connect, FAPI & FAPI-CIBA Profiles"
with certification programmes behind it. So OAuth is the only family in this
survey with *both* a formal-analysis lineage inside the normative document and
a runnable test suite outside it.

So for the OAuth candidates, the answer to "is there anything outside the
learner's own reasoning that says what the right answer is" is: yes, a
peer-reviewed formal model, cited by the normative document, plus §4's
seventeen named attacks each written out as a numbered trace, plus a
conformance suite.

## 4.1 PKCE downgrade (BEST OAUTH CANDIDATE)

- **Standard and section**: RFC 9700 §4.8 (PKCE Downgrade Attack), against
  RFC 7636 §4.4 and §4.6.
  <https://www.rfc-editor.org/rfc/rfc9700.html#section-4.8>,
  <https://www.rfc-editor.org/rfc/rfc7636.html>
- **The situation**: an authorization server supports PKCE but does not require
  it, so whether a given code is bound to a challenge depends on a parameter the
  attacker can strip out of the request.
- **The property**: RFC 7636 §4.4 — "When the server issues the authorization
  code in the authorization response, it MUST associate the 'code_challenge' and
  'code_challenge_method' values with the authorization code so it can be
  verified later." RFC 7636 §4.6 — "If the values are equal, the token endpoint
  MUST continue processing as normal (as defined by OAuth 2.0 [RFC6749]).  If
  the values are not equal, an error response indicating 'invalid_grant' as
  described in Section 5.2 of [RFC6749] MUST be returned." And the patch that
  closes the hole, RFC 9700 §4.8.2 — "to prevent PKCE downgrade attacks, the
  authorization server MUST ensure that if there was no code_challenge in the
  authorization request, a request to the token endpoint containing a
  code_verifier is rejected."
- **Shape**: `workflow`.
- **The interesting mistake**: **the two MUSTs of RFC 7636 are individually
  satisfiable while the system is still broken.** The server binds a challenge
  when one is present and checks a verifier when one is bound — both MUSTs hold
  — and an attacker who deletes `code_challenge` from *their own* request
  produces a code with no binding, which the server then happily redeems against
  a verifier it never checks. RFC 9700 §4.8.1 prints the six steps, ending: "6.
  Since the authorization server sees that this code is not bound to any PKCE
  code challenge, it will not check the presence or contents of the
  code_verifier parameter.  It will issue an access token (which belongs to the
  attacker's resource) to the client under the user's control."
- **Ground truth**: **excellent.** A named attack, a printed six-step trace, an
  explicit statement of the missing precondition, and a MUST-strength
  countermeasure — all in a BCP, all written by someone other than the learner.
  This is a counterexample with an answer key. RFC 7636 itself carries 1
  verified and 2 reported errata (errata_search, 2026-09-06); RFC 9700 has none.
- **Size**: 4 actors (user agent, client, authorization server, attacker),
  4-5 pieces of state (issued code, its challenge binding or lack of one,
  the client's verifier, the AS's session). **This is genuinely an evening.**

## 4.2 Authorization code injection

- **Standard and section**: RFC 9700 §4.5, countermeasure at §4.5.3.1.
  <https://www.rfc-editor.org/rfc/rfc9700.html#section-4.5>
- **The situation**: an attacker who has read a victim's authorization code
  splices it into their own session with a legitimate client, so the client
  binds the attacker's session to the victim's identity.
- **The property**: the informal statement the mechanism is supposed to give
  you — a code redeemed at the token endpoint was issued to *this* client, for
  *this* transaction, on *this* device. RFC 9700 §4.5.3.1 states what closes it:
  "When the attacker attempts to inject an authorization code, the check of the
  code_verifier fails: the client uses its correct verifier, but the code is
  associated with a code_challenge that does not match this verifier."
- **Shape**: `workflow`.
- **The interesting mistake**: the RFC records that the intended defence is
  routinely skipped in the field, and says why: "it has been observed that
  providers very often ignore the redirect_uri check requirement at this stage,
  maybe because it doesn't seem to be security-critical from reading the
  specification." That is a rare thing to find in a standard — an
  acknowledgement that a MUST is widely unimplemented because the spec reads as
  if it does not matter.
- **Ground truth**: **strong.** Six-step numbered attack trace at §4.5.1, an
  explicit discussion of which checks catch it and which do not at §4.5.2, plus
  the citation chain to the formal-analysis papers.
- **Size**: 4 actors, 4 pieces of state. Slightly larger than 4.1 because the
  attacker's own session has to be modelled too.

## 4.3 Refresh token rotation and replay detection

- **Standard and section**: RFC 9700 §4.14.2 and §2.2.2.
  <https://www.rfc-editor.org/rfc/rfc9700.html#section-4.14.2>
- **The situation**: an authorization server hands out a new refresh token on
  every refresh and invalidates the previous one, so that a stolen token used in
  parallel with the real client shows up as a use of an already-invalidated
  token.
- **The property**: "*Refresh token rotation:* the authorization server issues a
  new refresh token with every access token refresh response.  The previous
  refresh token is invalidated, but information about the relationship is
  retained by the authorization server.  If a refresh token is compromised and
  subsequently used by both the attacker and the legitimate client, one of them
  will present an invalidated refresh token, which will inform the authorization
  server of the breach." Made mandatory by §2.2.2: "Refresh tokens for public
  clients MUST be sender-constrained or use refresh token rotation as described
  in Section 4.14."
- **Shape**: `two-store`.
- **The interesting mistake**: **the RFC admits the detection is imprecise and
  says so in the same paragraph**: "The authorization server cannot determine
  which party submitted the invalid refresh token, but it will revoke the active
  refresh token.  This stops the attack at the cost of forcing the legitimate
  client to obtain a fresh authorization grant." So the property to check is not
  "only attackers trip the alarm" — it is the weaker, true one: "if a token is
  ever used twice, the chain is revoked". The false positive a learner will find
  is the honest client that retries after a lost response and presents the old
  token: no attacker, alarm fires, user is logged out. That failure is *not*
  spelled out in the RFC, so a learner who finds it has found something the
  document did not hand them — which is the good kind of exercise.
- **Ground truth**: **moderate-to-strong.** The mechanism and its stated
  limitation are normative; the retry-race false positive is `INFERRED` from the
  mechanism, not stated in RFC 9700. That mix is arguably ideal: a verifiable
  core plus one genuine discovery.
- **Size**: 3 actors (client, attacker, AS), a token chain of 2-3 links plus a
  revoked set. **Small, and the closest thing here to the learner's day job.**

## 4.4 Token revocation and its propagation window

- **Standard and section**: RFC 7009 §2.1.
  <https://www.rfc-editor.org/rfc/rfc7009.html#section-2.1>
- **The situation**: a client revokes a token; the authorization server marks it
  dead; several resource servers have not heard yet.
- **The property**: "In the next step, the authorization server invalidates the
  token.  The invalidation takes place immediately, and the token cannot be used
  again after the revocation.  In practice, there could be a propagation delay,
  for example, in which some servers know about the invalidation while others do
  not.  Implementations should minimize that window, and clients must not try to
  use the token after receipt of an HTTP 200 response from the server."
- **Shape**: `two-store`.
- **The interesting mistake**: same structure as RFC 9111 §4.4 — a MUST-flavoured
  statement ("takes place immediately", "cannot be used again") immediately
  qualified by an admission that it does not hold across the system. The
  interesting part is the cascade rule: "If the particular token is a refresh
  token and the authorization server supports the revocation of access tokens,
  then the authorization server SHOULD also invalidate all access tokens based
  on the same authorization grant". A learner who models the cascade will find
  that a well-timed refresh *during* the revocation mints an access token from
  a grant that is being torn down.
- **Ground truth**: moderate. The propagation-delay admission is in the
  normative text and is the counterexample. RFC 7009 has 1 reported erratum. The
  refresh-during-revocation race is `INFERRED`; I found no document naming it.
- **Size**: 4 actors (client, AS, two resource servers), 3 pieces of state.

## 4.5 Device authorization grant — the polling contract

- **Standard and section**: RFC 8628 §3.5.
  <https://www.rfc-editor.org/rfc/rfc8628.html#section-3.5>
- **The situation**: a television polls a token endpoint while a human, on a
  different device, types a short code into a browser; the TV has no channel
  back from the human.
- **The property**: the interval discipline is stated as a client MUST — "Before
  each new request, the client MUST wait at least the number of seconds
  specified by the 'interval' parameter of the device authorization response
  (see Section 3.2), or 5 seconds if none was provided, and respect any increase
  in the polling interval required by the 'slow_down' error." And the
  ratchet — "*slow_down* [...] the interval MUST be increased by 5 seconds for
  this and all subsequent requests." And the terminating rule — "If the client
  receives an error response with any other error code, it MUST stop polling".
- **Shape**: `resource`.
- **The interesting mistake**: the interval is a monotone ratchet, never
  reset — so a client that recomputes the interval from the original
  `device_code` response after each `slow_down` silently un-does the backoff and
  is rate-limited off. Also `expired_token` and `access_denied` are both
  terminal, but `authorization_pending` and `slow_down` are not, and a client
  that treats "any error" as terminal never completes the flow. The property is
  a clean pair: (safety) the client never polls faster than the current
  interval; (liveness) if the user approves, the client eventually gets a token.
- **Ground truth**: weak-to-moderate. The MUSTs are unambiguous and the state
  machine is small, but no attack document, no verified erratum (RFC 8628 has 1
  reported erratum only), and no published state diagram. §5.1 does give a
  concrete rate-limit budget — "the rate-limiting interval and validity period
  would need to only allow 5 attempts in order to get the same 2^-32 probability
  of success by random guessing" — but that is a probabilistic argument, which
  is the wrong shape for a model checker.
- **Size**: 3 actors (device, user's browser, AS), 4 pieces of state (device
  code, its expiry, the current interval, the approval flag). **Small and clean;
  the weakest thing about it is the absent ground truth, not the size.**

---

# 5. HTTP idempotency keys — an expired IETF draft

- **Standard and section**: `draft-ietf-httpapi-idempotency-key-header-07`,
  "The Idempotency-Key HTTP Header Field", Jena and Dalal, 15 October 2025,
  §2.6 (Idempotency Enforcement).
  <https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/>
- **The situation**: a client retries a POST it is not sure completed, carrying
  a key; the server must tell a retry-after-completion apart from a duplicate
  that arrived while the first is still in flight.
- **The property**: §2.6 draws the distinction — "Retry: The request was retried
  after the original request completed.  The resource SHOULD respond with the
  result of the previously completed operation, success or an error." versus
  "Concurrent Request: The request was retried before the original request
  completed.  The resource SHOULD respond with a resource conflict error."
- **Shape**: `delivery`.
- **The interesting mistake**: the three-state key lifecycle (unseen /
  in-flight / completed-with-stored-response) is exactly where implementations
  go wrong, because the transition into "in-flight" has to be atomic with the
  uniqueness check or two concurrent duplicates both pass it. Nothing in the
  draft says that.
- **Ground truth**: **none, and this matters.** Two problems, both
  disqualifying for the learner's purpose. (1) **The draft is expired.**
  Datatracker shows `draft-ietf-httpapi-idempotency-key-header-07` as "Expired
  Internet-Draft", expiry 18 April 2026, with no successor version. (2) **The
  normative content is almost entirely SHOULD.** The only MUST governing
  behaviour is "Resources MUST publish a idempotency related specification"
  (§2.5.2) — that is a documentation requirement, not a system property. Both
  the retry and concurrent rules are SHOULDs. So there is nothing here that says
  what the right answer is; the draft delegates it to each server's own docs.
- **Size**: 3 actors, 3 pieces of state. The size is right and everything else
  is wrong. **Dropped as a source.** Worth writing as a problem only if the
  learner supplies the invariant himself, which defeats the point of using a
  standard.

---

# 6. Candidates beyond the named list

These were not on the brief's coverage list. Two of them are better than most
of what was.

## 6.1 TLS 1.3 0-RTT anti-replay — RFC 8446 §8 (TOP-TIER)

- **Standard and section**: RFC 8446 §8 (0-RTT and Anti-Replay), §8.1
  (Single-Use Tickets), §8.2 (ClientHello Recording), §8.3 (Freshness Checks),
  with the analysis at Appendix E.5.
  <https://www.rfc-editor.org/rfc/rfc8446.html#section-8>
- **The situation**: a client sends application data on the first flight, before
  the handshake completes; a server fleet spread across clusters that do not
  share state has to make sure that data is not processed more than once.
- **The property**: this is the rare case of a **quantified, bounded**
  guarantee, stated as a MUST — "The server MUST ensure that any instance of it
  (be it a machine, a thread, or any other entity within the relevant serving
  infrastructure) would accept 0-RTT for the same 0-RTT handshake at most once;
  this limits the number of replays to the number of server instances in the
  deployment." And the client-side counterpart at §8: "clients will not know
  which, if any, of these mechanisms servers actually implement and hence MUST
  only send early data which they deem safe to be replayed."
- **Shape**: `delivery`.
- **The interesting mistake**: the guarantee is not "at most once" — it is "at
  most once *per instance*", and the RFC says so in the same sentence. A learner
  who states exactly-once gets a counterexample immediately; the property that
  actually holds is `deliveries <= number_of_instances`, which is unusual and
  worth writing. Separately, §8 prints a second attack in prose that is not a
  replay at all but a *client retry* turned into a duplicate: "if a server
  system has multiple zones where tickets from zone A will not be accepted in
  zone B, then an attacker can duplicate a ClientHello and early data intended
  for A to both A and B.  At A, the data will be accepted in 0-RTT, but at B the
  server will reject 0-RTT data and instead force a full handshake.  If the
  attacker blocks the ServerHello from A, then the client will complete the
  handshake with B and probably retry the request, leading to duplication on the
  server system as a whole." That is a complete counterexample trace, and RFC
  8446 states flatly that TLS cannot fix it: "The second class of attack cannot
  be prevented at the TLS layer and MUST be dealt with by any application."
- **Ground truth**: **excellent, and of a kind nothing else here has.** RFC 8446
  Appendix E is titled "Overview of Security Properties" and opens: "In this
  appendix, we provide an informal description of the desired properties as well
  as references to more detailed work in the research literature which provides
  more formal definitions." §E.1.6 lists nine such references, including
  Bhargavan, Blanchet and Kobeissi, "Verified Models and Reference
  Implementations for the TLS 1.3 Standard Candidate", IEEE S&P 2017,
  DOI 10.1109/SP.2017.26. So there is a *published property list* plus
  peer-reviewed machine-checked models of the same protocol. One qualification,
  for honesty: RFC 8446 has 16 verified errata — the most of any RFC here — and
  **none of them touches §8**. Six touch §4.2.10 (Early Data Indication), the
  most-erratum'd section in the document, but they refine the PSK
  parameter-matching rules rather than the anti-replay guarantee. So the ground
  truth for this candidate is the property list and the literature, not an
  erratum. Appendix E.5 also
  enumerates the concrete harms: "Attackers can store and replay 0-RTT messages
  in order to reorder them with respect to other messages (e.g., moving a delete
  to after a create)."
- **Size**: 4 actors (client, two server clusters, attacker), 4 pieces of state
  (ticket set, per-cluster seen-ClientHello set, a coarse clock window, an
  application-side effect counter). Crypto abstracts away completely — the
  learner models a ticket as an opaque identity. **This is an evening**, and it
  is the candidate closest to the learner's stated interest: it is a
  duplicate-delivery problem in a horizontally-scaled service.

## 6.2 HTTP/2 stream concurrency versus work in flight — RFC 9113 §5.1, §5.1.2

- **Standard and section**: RFC 9113 §5.1 (Stream States, containing Figure 2)
  and §5.1.2 (Stream Concurrency).
  <https://www.rfc-editor.org/rfc/rfc9113.html#section-5.1.2>
- **The situation**: one TCP connection multiplexes many streams; the server
  advertises a cap on how many the client may have open at once; the client
  opens a stream, sends a request, and immediately resets it.
- **The property**: "Streams that are in the 'open' state or in either of the
  'half-closed' states count toward the maximum number of streams that an
  endpoint is permitted to open.  Streams in any of these three states count
  toward the limit advertised in the SETTINGS_MAX_CONCURRENT_STREAMS setting.
  Streams in either of the 'reserved' states do not count toward the stream
  limit." and "Endpoints MUST NOT exceed the limit set by their peer."
- **Shape**: `resource`.
- **The interesting mistake**: **the limit counts states, not work.** A stream
  that is RST_STREAM'd leaves the counted set immediately, but the server has
  already dispatched the request behind it. So `MUST NOT exceed the limit` can
  hold at every instant while unbounded work accumulates. That is exactly the
  invariant a learner would write and exactly the one that is too weak.
  RFC 9113 §5.1 even flags the underlying looseness: "Both endpoints have a
  subjective view of the state of a stream that could be different when frames
  are in transit."
- **Ground truth**: **strong — this is the only candidate in the survey with a
  CVE number.** CVE-2023-44487, "HTTP/2 Rapid Reset", exploited exactly this
  gap; CISA published an alert on 2023-10-10
  (<https://www.cisa.gov/news-events/alerts/2023/10/10/http2-rapid-reset-vulnerability-cve-2023-44487>)
  and Google's write-up describes the mechanism as a request-then-RST_STREAM
  loop that sidesteps the concurrency limit
  (<https://cloud.google.com/blog/products/identity-security/how-it-works-the-novel-http2-rapid-reset-ddos-attack>).
  A learner who models §5.1's Figure 2 plus §5.1.2's counting rule and asks for
  a bound on concurrent server work will re-derive the CVE.
- **Size**: 2 actors, a per-stream state enum of 7, a counter, and a work queue.
  Moderate. Figure 2 is a published state diagram, like RFC 9293's.

## 6.3 HTTP/1.1 pipelining, retry, and the TCP reset problem — RFC 9112 §9.3.2, §9.6

- **Standard and section**: RFC 9112 §9.3.2 (Pipelining) and §9.6 (Tear-down).
  <https://www.rfc-editor.org/rfc/rfc9112.html#section-9.6>
- **The situation**: a client has several requests outstanding on one
  connection; the server closes it; the client must work out which of them were
  processed and which are safe to resend.
- **The property**: "A client that pipelines requests SHOULD retry unanswered
  requests if the connection closes before it receives all of the corresponding
  responses.  When retrying pipelined requests after a failed connection (a
  connection not explicitly closed by the server in its last complete response),
  a client MUST NOT pipeline immediately after connection establishment, since
  the first remaining request in the prior pipeline might have caused an error
  response that can be lost again if multiple requests are sent on a prematurely
  closed connection". Backed by RFC 9110 §9.2.2: "A proxy MUST NOT automatically
  retry non-idempotent requests.  A client SHOULD NOT automatically retry a
  failed automatic retry."
- **Shape**: `delivery`.
- **The interesting mistake**: §9.6 spells out a genuine cross-layer
  counterexample. "If the server receives additional data from the client on a
  fully closed connection, such as another request sent by the client before
  receiving the server's response, the server's TCP stack will send a reset
  packet to the client; unfortunately, the reset packet might erase the client's
  unacknowledged input buffers before they can be read and interpreted by the
  client's HTTP parser." So the *response the client needed in order to decide
  whether to retry* is destroyed by the mechanism that signals the close. The
  remedy is a staged half-close, described in the same section.
- **Ground truth**: **strong for the mechanism, honest about its own limits.**
  The RFC names the failure, names the remedy, and then says: "It is unknown
  whether the reset problem is exclusive to TCP or might also be found in other
  transport connection protocols." A standard admitting it does not know is
  itself a useful thing for a learner to see.
- **Size**: 2 actors, a request queue, a connection state, plus enough of TCP to
  make the reset meaningful. **This is the modelling cost that disqualifies it
  as an evening's work** — it is honestly a two-layer problem. Good as a
  follow-on to a TCP model already built.

## 6.4 TOTP validation windows — RFC 6238 §5.2, §6

- **Standard and section**: RFC 6238 §5.2 (Validation and Time-Step Size) and §6
  (Resynchronization).
  <https://www.rfc-editor.org/rfc/rfc6238.html#section-5.2>
- **The situation**: a verifier accepts a one-time code that is valid across a
  small window of time steps, because the prover's clock drifts and the network
  delays, and must still guarantee each code is used once.
- **The property**: a clean MUST NOT with its purpose attached — "Note that a
  prover may send the same OTP inside a given time-step window multiple times to
  a verifier.  The verifier MUST NOT accept the second attempt of the OTP after
  the successful validation has been issued for the first OTP, which ensures
  one-time only use of an OTP." With a bounded drift budget: "If the time step
  is 30 seconds as recommended, and the validator is set to only accept two time
  steps backward, then the maximum elapsed time drift would be around 89
  seconds, i.e., 29 seconds in the calculated time step and 60 seconds for two
  backward time steps."
- **Shape**: `expiry`.
- **The interesting mistake**: the acceptance window and the one-time-use rule
  interact badly. Because a single code is acceptable across N steps, "one-time
  only use" needs a per-(user, time-step) consumed set, not a
  last-successful-timestamp high-water mark. An implementation that stores only
  the last successful step and rejects anything at or before it still accepts a
  *forward*-window code twice. The RFC does not point this out.
- **Ground truth**: moderate. The MUST NOT and the 89-second arithmetic are both
  normative and checkable. The high-water-mark bug is `INFERRED` — no erratum,
  no CVE citation found in the survey window. RFC 6238 is Informational, not
  Standards Track, which weakens it further.
- **Size**: 2 actors, a clock offset, a window width, a consumed set. **Tiny.**
  A good warm-up rather than a centrepiece.

## 6.5 HTTP cookie eviction — RFC 6265 §5.3

- **Standard and section**: RFC 6265 §5.3 (Storage Model).
  <https://www.rfc-editor.org/rfc/rfc6265.html#section-5.3>
- **The situation**: a bounded cookie jar with per-domain and global limits,
  evicting under pressure.
- **The property**: "The user agent MUST evict all expired cookies from the
  cookie store if, at any time, an expired cookie exists in the cookie store."
  followed by a priority-ordered eviction list, and the counterweight: "the user
  agent MAY evict any cookie at any time on orders from the user."
- **Shape**: `resource`.
- **The interesting mistake**: the "MAY evict any cookie at any time" clause
  makes almost every persistence property unprovable, which is itself the
  lesson — an implementer who assumes a set cookie stays set is wrong by
  specification. RFC 6265 §7 notes the consequence: when the store "reaches its
  storage limit, the user agent will be forced to evict" — an attacker can
  therefore evict a victim's cookie by filling the jar.
- **Ground truth**: weak-to-moderate. The eviction-attack is described in the
  RFC's own security considerations. But RFC 6265 is superseded in practice by
  6265bis, which I did not read in this survey — so anything built on 6265 alone
  risks being out of date. `INFERRED`.
- **Size**: 2 actors, a bounded set. Small but the property is thin. Listed for
  completeness; I would not build on it.

---

# 7. ACME certificate issuance — RFC 8555

<https://www.rfc-editor.org/rfc/rfc8555.html>

**The headline**: RFC 8555 §7.1.6 contains **four published ASCII state
diagrams** — for account, order, authorization and challenge objects. Like
RFC 9293's Figure 5, these are separate artefacts from the prose, which means
the learner can transcribe the diagram as a next-state relation and the prose as
an invariant and let the checker find where they disagree. RFC 8555 carries **11
verified, 5 reported and 6 held-for-document-update errata** — the highest count
of any RFC in this survey (errata_search, 2026-09-06).

## 7.1 The challenge retry loop and its verified contradiction (BEST ACME CANDIDATE)

- **Standard and section**: RFC 8555 §8.2 (Retrying Challenges) against §8
  (Identifier Validation Challenges, the `error` field) and §7.1.6.
  <https://www.rfc-editor.org/rfc/rfc8555.html#section-8.2>
- **The situation**: a CA repeatedly probes a client's web server or DNS zone to
  validate a challenge, retrying on failure, while the client may also demand a
  retry, and both sides must agree when the attempt is finally dead.
- **The property**: three sentences that cannot all hold. §8.2 — "While the
  server is still trying, the status of the challenge remains 'processing'; it
  is only marked 'invalid' once the server has given up." and "The server MUST
  add an entry to the 'error' field in the challenge after each failed
  validation query." Against §8 — "A challenge object with an error MUST have
  status equal to 'invalid'."
- **Shape**: `lifecycle`.
- **The interesting mistake**: put those three in one model and it deadlocks.
  The first failed probe writes an `error`, the `error` forces status `invalid`,
  `invalid` is terminal in the §7.1.6 diagram, and the entire retry mechanism of
  §8.2 becomes unreachable.
- **Ground truth**: **a verified erratum saying exactly that** — the cleanest single piece of ground truth in the survey. RFC 8555
  **Errata ID 5732**, status **Verified**, type Technical, reported by Rob
  Stradling 2019-05-23, verified by Paul Wouters 2024-02-22 (I fetched and read
  the entry directly at
  <https://www.rfc-editor.org/errata_search.php?rfc=8555>). It rewrites §8 to
  "A challenge object with an error MUST have status equal to 'processing' or
  'invalid'.", and its own note states the reasoning a model would reconstruct:
  "Section 8.2 says that 'The server MUST add an entry to the "error" field in
  the challenge after each failed validation query'.  However, if the challenge
  must then become "invalid", it is never possible to retry any validation query
  (because "invalid" is a final state for a challenge object). This erratum is
  necessary to permit validation query retries to ever happen."
  A second, still-open **Errata ID 7826** (status Reported, Rob Stradling,
  2024-02-28) argues the retry-state sentence should be scoped to `processing`,
  and settles it by appeal to the diagram — which tells you the community treats
  §7.1.6 as the arbiter when the prose is ambiguous.
  Third corroboration from implementation: Let's Encrypt's Boulder divergences
  document says under §8.2 that "Boulder does not implement the ability to retry
  challenges or the `Retry-After` header"
  (<https://github.com/letsencrypt/boulder/blob/main/docs/acme-divergences.md>).
- **Size**: 1 challenge, 1 authorization, a retry counter, a server give-up
  decision, a client-initiated retry. **The smallest ACME candidate and the one
  with the strongest ground truth. If the learner does one ACME problem, this.**

## 7.2 Order readiness as a predicate over a set

- **Standard and section**: RFC 8555 §7.1.6 (order state diagram) and §7.4
  (Applying for Certificate Issuance), with the immutability rule at §7.1.3.
  <https://www.rfc-editor.org/rfc/rfc8555.html#section-7.1.6>
- **The situation**: a certificate order holds a fixed set of domain
  authorizations, each running its own state machine, and the order's own state
  is a function of the whole set plus the client's finalize request.
- **The property**: §7.1.6 — "Order objects are created in the 'pending' state.
  Once all of the authorizations listed in the order object are in the 'valid'
  state, the order transitions to the 'ready' state. [...] The order also moves
  to the 'invalid' state if it expires or one of its authorizations enters a
  final state other than 'valid' ('expired', 'revoked', or 'deactivated')."
  Well-formed because of §7.1.3 — "The elements of the 'authorizations' and
  'identifiers' arrays are immutable once set.  The server MUST NOT change the
  contents of either array after they are created."
- **Shape**: `lifecycle`.
- **The interesting mistake**: readiness is a *predicate over the whole set*,
  not an edge fired by the last authorization going valid. §7.1.3 permits an
  order to be born ready — "there are several reasons that the referenced
  authorizations may already be valid" — and Boulder confirms it happens in
  production: "Boulder may recycle previously 'valid' or 'pending'
  `Authorizations` for a given `Account` when creating a new `Order`"
  (<https://github.com/letsencrypt/boulder/blob/main/docs/acme-implementation_details.md>).
  So one authorization object is shared state across several orders. The sharper
  find is a contradiction between §7.4 and the diagram: §7.4 says "A request to
  finalize an order will result in error if the order is not in the 'ready'
  state.  In such cases, the server MUST return a 403 (Forbidden) error with a
  problem document of type 'orderNotReady'." and then lists `pending` among the
  outcomes of a *successful* finalize — "'pending': The server does not believe
  that the client has fulfilled the requirements." The §7.1.6 order diagram has
  no `ready` to `pending` edge, so either the diagram is missing one or that
  bullet is unreachable.
- **Ground truth**: strong for the mechanism (published diagram), and
  **explicitly open** for the `ready`/`pending` contradiction — no erratum
  addresses it, among the 22 filed against RFC 8555. That the question is open
  is itself worth telling the learner, because erratum 7826 settles a
  structurally identical dispute by treating §7.1.6 as authoritative.
- **Size**: 1 order, 2-3 authorizations, 1 client, 1 server, an expiry clock.
  Comfortably an evening.

## 7.3 An authorization expiring under a live order

- **Standard and section**: RFC 8555 §7.1.4 and §7.4.
  <https://www.rfc-editor.org/rfc/rfc8555.html#section-7.1.4>
- **The situation**: two independent expiry clocks — one on the order, one on
  each authorization — tick against a client trying to finish before either
  fires.
- **The property**: §7.4 — "If the client fails to complete the required actions
  before the 'expires' time, then the server SHOULD change the status of the
  order to 'invalid' and MAY delete the order resource." §7.1.4 — "expires
  (optional, string): The timestamp after which the server will consider this
  authorization invalid [...] This field is REQUIRED for objects with 'valid' in
  the 'status' field."
- **Shape**: `expiry`.
- **The interesting mistake**: the order reaches `ready`, the client is slow to
  POST its CSR, and an authorization expires in the window. An implementation
  that latches readiness rather than re-evaluating it at finalize time issues a
  certificate on an expired authorization. The diagram does carry the edge that
  catches this — `ready` has an arrow to `invalid` labelled "Error or
  Authorization failure". And §7.1.6 pre-warns that a state your model needs may
  be one your logs never show: "Note that some of these states may not ever
  appear in a 'status' field, depending on server behavior. [...] A server that
  deletes expired authorizations immediately will never show an authorization in
  the 'expired' state."
- **Ground truth**: strong (published diagram plus the unobservable-states note).
- **Size**: 1 order, 2 authorizations, 2 clocks. Small. The learner must supply
  a discrete notion of time, which is standard modelling furniture rather than
  inventing the system.

## 7.4 The replay-nonce pool

- **Standard and section**: RFC 8555 §6.5, §6.5.1, §7.2.
  <https://www.rfc-editor.org/rfc/rfc8555.html#section-6.5>
- **The situation**: a server hands out single-use tokens; every request burns
  one; the client keeps a pool refilled from response headers and pipelines
  requests against it.
- **The property**: a clean one-liner — "Once a nonce value has appeared in an
  ACME request, the server MUST consider it invalid, in the same way as a value
  it had never issued." With the recovery rule — "when retrying in response to a
  'badNonce' error, the client MUST use the nonce provided in the error
  response."
- **Shape**: `concurrency`.
- **The interesting mistake**: two concurrent POSTs from one pool both grab the
  same nonce; one wins, one gets `badNonce`; a naive client returns the error's
  nonce to the shared pool instead of using it for that retry, violating the
  MUST. Under contention this livelocks — every request burns one nonce and
  produces one, so the pool never grows. The liveness property "every request
  eventually succeeds" is false without a fairness assumption the RFC does not
  state. The spec also names a third-party failure: §7.2 — "Proxy caching of
  responses from the newNonce resource can cause clients to receive the same
  nonce repeatedly, leading to 'badNonce' errors."
- **Ground truth**: **weak, and worth saying plainly.** No state diagram, no
  erratum on §6.5 or §7.2, and Boulder's divergences document is silent on
  nonces. What you get is the RFC naming the proxy-cache failure itself. Safety
  is fully pinned by the text; the liveness finding is the learner's own with
  nothing external to check it against.
- **Size**: 1 server nonce set, 2 clients with pools, 2-3 in-flight requests.
  Small if the nonce set is a bounded counter.

## 7.5 Account deactivation as an irreversible kill switch

- **Standard and section**: RFC 8555 §7.3.6 and §7.5.2.
  <https://www.rfc-editor.org/rfc/rfc8555.html#section-7.3.6>
- **The situation**: an account key is compromised, the operator deactivates the
  account, and everything downstream that the key authorised has to stop working
  without anything being able to bring it back.
- **The property**: "Once an account is deactivated, the server MUST NOT accept
  further requests authorized by that account's key.  The server SHOULD cancel
  any pending operations authorized by the account's key, such as certificate
  orders. [...] Servers SHOULD NOT revoke certificates issued by the deactivated
  account, since this could cause operational disruption for servers using these
  certificates.  ACME does not provide a way to reactivate a deactivated
  account." Plus §7.5.2 — "The server MUST NOT treat deactivated authorization
  objects as sufficient for issuing certificates."
- **Shape**: `lifecycle`.
- **The interesting mistake**: the MUST NOT and the SHOULD NOT are in
  deliberate tension. Deactivation must stop *requests*, should cancel pending
  operations, and should *not* revoke issued certificates. An implementer who
  reads "kill switch" and cascades to revocation violates a SHOULD NOT that
  exists to prevent an outage. One who only blocks the HTTP layer leaves an
  order a *different* live account can finalize, since §7.6 says "The server
  MUST consider at least the following accounts authorized for a given
  certificate: [...] an account that holds authorizations for all of the
  identifiers in the certificate."
- **Ground truth**: good. The §7.1.6 account diagram is three states and two
  edges, with no return path, corroborating the prose exactly. No relevant
  errata.
- **Size**: 1 account, 1-2 orders, 2 authorizations, 1 certificate. The account
  machine is trivial; the interest is entirely in what it drags down.
  Irreversibility is the cleanest possible temporal property for a learner
  eleven chapters in.

---

# 8. WebSocket close handshake — RFC 6455

<https://www.rfc-editor.org/rfc/rfc6455.html>

A framing note that governs every candidate here. **RFC 6455 §2 declares its own
diagrams non-normative**: "All diagrams, examples, and notes in this
specification are non-normative, as are all sections explicitly marked
non-normative.  Everything else in this specification is normative." There is no
state diagram for the closing handshake — it lives in prose across §5.5.1 and
§7.1.1 to §7.1.4. So unlike ACME and TCP, the learner transcribes prose into a
machine with no picture to check against, and the ground truth has to come from
the **Autobahn TestSuite**, whose README describes "over 500 test cases covering
[...] Closing Handshake" (<https://github.com/crossbario/autobahn-testsuite>).
Each case ships a `DESCRIPTION` and an `EXPECTATION` string that read as
executable acceptance criteria.

RFC 6455 carries 3 verified, 6 reported, 4 held-for-document-update and 5
rejected errata (errata_search, 2026-09-06).

## 8.1 The close handshake (BEST WEBSOCKET CANDIDATE)

- **Standard and section**: RFC 6455 §5.5.1 and §7.1.2 to §7.1.4.
  <https://www.rfc-editor.org/rfc/rfc6455.html#section-5.5.1>
- **The situation**: two peers, either of which may start closing, exchange one
  Close frame each and then tear down a TCP connection, without either losing
  data the other still wanted.
- **The property**: three separate rules, all quotable. "The application MUST NOT
  send any more data frames after sending a Close frame." / "If an endpoint
  receives a Close frame and did not previously send a Close frame, the endpoint
  MUST send a Close frame in response. [...] An endpoint MAY delay sending a
  Close frame until its current message is sent (for instance, if the majority
  of a fragmented message is already sent, an endpoint MAY send the remaining
  fragments before sending a Close frame).  However, there is no guarantee that
  the endpoint that has already sent a Close frame will continue to process
  data." / "After both sending and receiving a Close message, an endpoint
  considers the WebSocket connection closed and MUST close the underlying TCP
  connection."
- **Shape**: `lifecycle`.
- **The interesting mistake**: the two rules look like they compose into a clean
  two-phase handshake, except for the exception in the middle — an endpoint MAY
  send remaining *data* fragments after *receiving* a Close, before sending its
  own. So the no-data rule constrains the sender's own send, not the connection,
  and the peers can be in states where one is legally still transmitting while
  the other has stopped. Implementations routinely collapse this to "once
  anybody closes, nobody sends", which is stricter than the spec and breaks the
  fragment-completion case. Second: the simultaneous close, handled in one
  sentence — "If a client and server both send a Close message at the same time,
  both endpoints will have sent and received a Close message and should consider
  the WebSocket connection closed" — which a state machine with a single
  `closing_initiated_by` field cannot represent at all. (Compare RFC 9293's
  CLOSING state, candidate 3.2. Same bug, different protocol.)
- **Ground truth**: strong, external and executable. Autobahn case **7.1.1** —
  DESCRIPTION "Send a message followed by a close frame", EXPECTATION "Echoed
  message followed by clean close with normal code." Case **7.1.2** — "Send two
  close frames" / "Clean close with normal code. Second close frame ignored."
  Case **7.1.4** — "Send text message after sending a close frame." / "Clean
  close with normal code. Text message ignored." Those three pin the echo rule,
  idempotence of a second Close, and discard-after-close respectively.
- **Size**: 2 endpoints, each with `sent_close` / `received_close` and a TCP
  state; a message queue in each direction. 4-6 state variables. **The
  archetypal evening problem.**

## 8.2 Two endpoints that never agree on why the connection closed

- **Standard and section**: RFC 6455 §7.1.5 and §7.4.1.
  <https://www.rfc-editor.org/rfc/rfc6455.html#section-7.1.5>
- **The situation**: both ends decide independently to close, each sends a status
  code, and each reports the *other's* code to its application — so the two
  applications get different answers about the same event.
- **The property**: "_The WebSocket Connection Close Code_ is defined as the
  status code (Section 7.4) contained in the first Close control frame received
  by the application implementing this protocol.  If this Close control frame
  contains no status code, _The WebSocket Connection Close Code_ is considered to
  be 1005.  If _The WebSocket Connection is Closed_ and no Close control frame
  was received by the endpoint [...] considered to be 1006." Plus §7.4.1 — "1005
  is a reserved value and MUST NOT be set as a status code in a Close control
  frame by an endpoint." and the same for 1006.
- **Shape**: `delivery`.
- **The interesting mistake**: the invariant an implementer wants — both ends
  report the same close code — is **false, and the RFC says so**, though only in
  a NOTE that §2 has already declared non-normative: "NOTE: Two endpoints may not
  agree on the value of _The WebSocket Connection Close Code_.  As an example, if
  the remote endpoint sent a Close frame but the local application has not yet
  read the data containing the Close frame from its socket's receive buffer, and
  the local application independently decided to close the connection and send a
  Close frame, both endpoints will have sent and received a Close frame and will
  not send further Close frames.  Each endpoint will see the status code sent by
  the other end as _The WebSocket Connection Close Code_." Write the property you
  assume, watch the checker produce the exact counterexample the note describes,
  then read the note. The 1005/1006 rules add a second half: values that may be
  *observed* but MUST NOT be *sent*, so the model needs two distinct code
  domains — a distinction implementers collapse, and sending 1006 on the wire is
  a real and common bug.
- **Ground truth**: mixed, and worth stating carefully. The RFC's own NOTE
  describes the counterexample but is **non-normative by §2**, so it is a hint
  rather than a ruling. The external anchor is Autobahn case **7.9.x** — "Send
  close with invalid close code %d" / "Clean close with protocol error code or
  drop TCP" — and case **7.13.1**, "Send close with close code 5000", whose
  EXPECTATION reads "Actual events are undefined by the spec." A test suite
  marking where the spec runs out is unusually useful: it draws the boundary of
  what is checkable.
- **Size**: 2 endpoints, a sent-code and a received-code each, and a one-slot
  buffer per direction. The buffer is the whole point — without it the
  disagreement cannot occur.

## 8.3 Control frames interleaved with a fragmented message

- **Standard and section**: RFC 6455 §5.4, §5.5, §5.5.2, §5.5.3.
  <https://www.rfc-editor.org/rfc/rfc6455.html#section-5.4>
- **The situation**: a long message is sent as a chain of fragments; pings,
  pongs and a close can be injected between any two; the receiver keeps a
  reassembly buffer, a pong obligation and a close state straight at once.
- **The property**: §5.4 — "Control frames (see Section 5.5) MAY be injected in
  the middle of a fragmented message.  Control frames themselves MUST NOT be
  fragmented." and "An endpoint MUST be capable of handling control frames in
  the middle of a fragmented message." §5.5.2 — "Upon receipt of a Ping frame,
  an endpoint MUST send a Pong frame in response, unless it already received a
  Close frame." §5.5.3 — "If an endpoint receives a Ping frame and has not yet
  sent Pong frame(s) in response to previous Ping frame(s), the endpoint MAY
  elect to send a Pong frame for only the most recently processed Ping frame."
- **Shape**: `concurrency`.
- **The interesting mistake**: three, and they stack. (a) An implementer treats
  the mid-fragment injection as a receiver concession and never *sends* one, so
  their own long messages block their keepalive. (b) The pong obligation is
  *cancelled* by an incoming Close, not deferred — so an implementation that
  queues pongs and drains at shutdown emits one after receiving a Close, which
  is wrong. (c) The coalescing licence means "every ping eventually receives a
  matching pong" is **not** a valid property; the correct one is weaker. Learners
  write the strong version first, which is the good failure.
- **Ground truth**: strong and unusually precise. Autobahn case **5.19** is a
  hand-written interleaving trace — DESCRIPTION "A fragmented text message is
  sent in multiple frames. After sending the first 2 frames of the text message,
  a Ping is sent. Then we wait 1s, then we send 2 more text fragments, another
  Ping and then the final text fragment. Everything is legal." Case **7.1.3** —
  "Send a ping after close message" / "Clean close with normal code, no pong." —
  directly confirms the pong-cancellation rule. Case **2.11** documents the
  suite and the spec disagreeing in the open: EXPECTATION "Pongs for our Pings
  with all the payloads. Note: This is not required by the Spec .. but we check
  for this behaviour anyway."
- **Size**: 2 endpoints, a fragment counter and reassembly buffer, an
  outstanding-ping set, a close bit. **A full evening rather than half of one**,
  and the state space needs bounding (cap fragments at 3, pings at 2).

## 8.4 Two smaller ones

**Who closes the TCP connection** — §7.1.1: "The underlying TCP connection, in
most normal cases, SHOULD be closed first by the server, so that it holds the
TIME_WAIT state and not the client". Shape `resource`. A client that closes
eagerly accumulates TIME_WAIT sockets and exhausts its ephemeral port range under
reconnect churn. Ground truth is real but *qualified*: **Errata ID 7608, status
Reported** (not verified), Esmond Pitt 2023-08-19, disputes the RFC's stated
*rationale* in five particulars including "There is no such thing as a
'TIME_WAIT connection'". So the rule is undisputed and the reason for it is
contested by an unverified erratum. Too small to stand alone; a good second phase
on top of 8.1.

**Masking** — §5.1: "a client MUST mask all frames that it sends to the server
[...] The server MUST close the connection upon receiving a frame that is not
masked. [...] A server MUST NOT mask any frames that it sends to the client.  A
client MUST close a connection if it detects a masked frame." Four MUSTs, one
direction-dependent invariant, two lines of TLA+. Ground truth is a **named
published attack**: §10.3 states "an experiment was conducted to demonstrate a
class of attacks on proxies that led to the poisoning of caching proxies deployed
in the wild [TALKING]". A free addition to any of the above.

---

# 9. DNS caching, TTL and stale-serving — RFC 1035, 2181, 2308, 8767

**A framing correction that changes how this family must be used.** RFC 1035
(1987) **predates BCP 14**, and RFC 8767 §3 says so: "[RFC1035] predates the more
rigorous terminology of [RFC2119], which softened the interpretation of 'may' and
'should'." So RFC 1035 has no capitalised MUST to quote. Its §7.4 caching rules
are lowercase "should" and cannot be treated as normative text. The quotable
sentences live in **RFC 2181** and **RFC 8767**. Anyone building a problem here
should model 2181 plus 8767 as the specification and use RFC 1035 §7.4 as a
source of scenarios.

**A second correction, to the brief.** RFC 8767 does **not** contain a MUST NOT
bounding stale-serving. I checked: the file contains the string `MUST NOT` exactly
once, in the BCP 14 boilerplate at line 102, and four occurrences of `MUST`
total. §5 is titled "**Example Method**" and §6 opens "This document mainly
describes the issues behind serving stale data and intentionally does not provide
a formal algorithm." The maximum-stale timer is a **SHOULD-strength configurable
knob**, suggested at "between 1 and 3 days", not a mandated bound.

## 9.1 The negative cache and its countdown (BEST DNS CANDIDATE)

- **Standard and section**: RFC 2308 §3, §5, §6.
  <https://www.rfc-editor.org/rfc/rfc2308.html#section-5>
- **The situation**: a resolver must remember that a name *does not exist*, for a
  bounded time, and must pass the remaining time along when it forwards that
  answer — because if it does not, the "no" circulates between servers forever.
- **The property**: §5 gives the derivation — "When the authoritative server
  creates this record its TTL is taken from the minimum of the SOA.MINIMUM field
  and SOA's TTL.  This TTL decrements in a similar manner to a normal cached
  answer and upon reaching zero (0) indicates the cached negative answer MUST NOT
  be used again." §6 gives the forwarding obligation — "When a server, in
  answering a query, encounters a cached negative response it MUST add the cached
  SOA record to the authority section of the response with the TTL decremented by
  the amount of time it was stored in the cache.  This allows the NXDOMAIN /
  NODATA response to time out correctly."
- **Shape**: `two-store`. §5 is explicit that NXDOMAIN is cached against
  `<QNAME, QCLASS>` while NODATA is cached against `<QNAME, QTYPE, QCLASS>` —
  different keys, same store, and that asymmetry is itself a bug source.
- **The interesting mistake**: two, and the second is excellent. (a) The
  derivation is `min(SOA.MINIMUM, TTL of the SOA record itself)` — two different
  numbers from the same record. Implementers reach for SOA.MINIMUM alone, because
  that is what the field is called, and over-cache the negative answer. §4
  documents why the field is a trap: "The SOA minimum field has been overloaded
  in the past to have three different meanings". (b) The §6 decrement obligation
  is a **liveness** requirement dressed as a formatting rule, and §5 states the
  failure it prevents: "Without a TTL count down a cache negative response when
  received by the next server would have its TTL reset.  This negative indication
  could then live forever circulating between the servers involved."
- **Ground truth**: **present but thin on the specific rule, and I want to be
  exact.** RFC 2308 has 3 verified errata (461, 4489, 8188) and **all three are
  editorial and none touches §5 or §6**. So no erratum confirms the min() rule or
  the decrement rule. What you have is internal corroboration — §3 and §5 state
  the derivation independently — plus the RFC narrating the failure the decrement
  prevents. That is weaker than a verified erratum and should be presented as
  such.
- **Size**: 2 resolvers, 1 authoritative server, 1 non-existent name, a clock, a
  forwarding edge each way. **Small, and the loop needs only two resolvers.** One
  safety property and one liveness property from three quoted sentences.
- **Free extension**: §7.1 and §7.2 add two more bounded caches with hard
  numbers — "If it does so it MUST NOT cache it for longer than five (5)
  minutes, and it MUST be cached against the specific query tuple `<query name,
  type, class, server IP address>`" and the same five-minute cap for a dead-server
  indication.

## 9.2 TTL semantics, TTL zero, and the signed/unsigned contradiction

- **Standard and section**: RFC 1035 §3.2.1 and §4.1.3, amended by RFC 2181 §8
  and again by RFC 8767 §4; the RRSet rule at RFC 2181 §5.2.
  <https://www.rfc-editor.org/rfc/rfc2181.html#section-8>
- **The situation**: a resolver holds records that age out on independent clocks,
  refills them from upstream, and must never hand out something it was told not
  to keep.
- **The property**: RFC 8767 §4 formally amends the definition — "TTL a 32-bit
  unsigned integer number of seconds that specifies the duration that the
  resource record MAY be cached before the source of the information MUST again
  be consulted.  Zero values are interpreted to mean that the RR can only be used
  for the transaction in progress, and should not be cached." RFC 2181 §5.2 gives
  the RRSet rule with unusual force: "the use of differing TTLs in an RRSet is
  hereby deprecated, the TTLs of all RRs in an RRSet must be the same. [...] In
  no case may a server send an RRSet with TTLs not all equal."
- **Shape**: `expiry`.
- **The interesting mistake**: **RFC 1035 contradicts itself about the type of
  the field that controls when data dies.** §3.2.1 says "a 32 bit signed integer"
  and §4.1.3 says "a 32 bit unsigned integer". Read it signed and a hostile TTL
  with the top bit set is born expired — or never expires, depending on your
  language's arithmetic. And **the two clarifications disagree with each other**:
  RFC 2181 §8 says treat such a value as zero ("Implementations should treat TTL
  values received with the most significant bit set as if the entire value
  received was zero"), while RFC 8767 §4 says clamp it positive. RFC 8767 §6
  admits the divergence: "as opposed to [RFC2181] treating it as zero, the
  rationale here is basically one of engineering simplicity versus an
  inconsequential operational history." Separately, TTL 0 survives all three
  documents unchanged, and RFC 8767 §7 extends it — "The continuing prohibition
  against using data with a 0-second TTL beyond the current transaction
  explicitly extends to it being unusable even for stale fallback, as it is not to
  be cached at all." An implementation that stores TTL-0 records with an immediate
  expiry rather than not storing them at all will serve them under serve-stale.
- **Ground truth**: **strong and layered.** RFC 1035 **Errata ID 2130**, status
  **Verified**, type Technical, reported by Alexei A. Smekalkine 2010-04-05,
  verified by Brian Haberman 2012-04-26, changes §3.2.1 from "signed" to
  "unsigned", noting "Conflicting descriptions of the type of TTL field."
  (RFC 1035 has 12 verified and 16 held-for-document-update errata in total.) On
  top of that, two published Standards-Track clarifications resolve the top-bit
  case *differently* — a learner who models it and finds three answers has found
  something true.
- **Size**: 1 cache, 2-3 names, a clock, an upstream that answers or does not.
  Small.

## 9.3 Serving stale data

- **Standard and section**: RFC 8767 §4, §5, §7.
  <https://www.rfc-editor.org/rfc/rfc8767.html#section-5>
- **The situation**: the authoritative servers for a zone become unreachable, and
  a resolver keeps answering from records whose TTL has already run out — under
  conditions, for a bounded extra time, and only after genuinely trying to
  refresh.
- **The property**: the three real MUSTs. "When returning a response containing
  stale records, a recursive resolver MUST set the TTL of each expired record in
  the message to a value greater than 0, with a RECOMMENDED value of 30 seconds."
  and "Answers from authoritative servers that have a DNS response code of either
  0 (NoError) or 3 (NXDomain) and the Authoritative Answer (AA) bit set MUST be
  considered to have refreshed the data at the resolver." Plus the ordering
  discipline at §7 — "Stale data is used only when refreshing has failed [...] If
  stale data were to always be used immediately and then a cache refresh
  attempted after the client response has been sent, the resolver would
  frequently be sending data that it would have had no trouble refreshing."
- **Shape**: `expiry`.
- **The interesting mistake**: the §7 ordering rule is the one implementers
  invert — serving stale first and refreshing afterwards is the obvious efficient
  design and it is wrong. §5's four timers (client response, query resolution,
  failure recheck, maximum stale) interact, and §6 states the failure at each
  end: "If this variable [failure recheck] is set too large, stale answers may
  continue to be returned even after the authoritative server is reachable.  If
  this variable is too small, authoritative servers may be targeted with a
  significant amount of excess traffic."
- **Ground truth**: **no errata at all** on RFC 8767. But §7 contains something
  better and rarer — **a logged production bug, written into the RFC**: "This was
  observed with an initial implementation in BIND when a hostname changed from
  having an IPv4 Address (A) record to a CNAME.  The version of BIND being used
  did not evict other types in the cache when a CNAME was received, which in
  normal operations is not a significant issue.  However, after both records
  expired and the authorities became unavailable, the fallback to stale answers
  returned the older A instead of the newer CNAME." That is a three-condition
  conjunction a model checker finds and a test suite does not. §10 also names an
  attack with a citation: "In [CloudStrife], it was demonstrated how stale DNS
  data [...] can be used to co-opt security -- for example, to get
  domain-validated certificates fraudulently issued to an attacker."
- **Size**: 1 resolver, 1 cache entry, an authority that can be up or down, 4
  timers. **The timers make it bigger than 9.1 and 9.2** — model two of the four
  and hold the others constant, or it will not fit an evening.
- **Caveat, and it is the important one**: §5 is an *Example Method*, not a
  specification. The safety MUSTs are checkable; the timer algorithm is one
  plausible implementation the RFC sketches. Hand this over honestly — 9.1 and
  9.2 do not have that problem.

---

# 10. The one `rollout`-shaped candidate — DNSSEC key rollover

Seven of the eight shapes are well covered by this family. `rollout` — a change
propagating through a population that must stay correct at every intermediate
point — is covered by exactly one thing, and it comes with a caveat that
disqualifies it on the ground-truth axis rather than the size axis.

- **Standard and section**: RFC 7583, "DNSSEC Key Rollover Timing
  Considerations", §3.1 (Key States) and §3.2.1 (Pre-Publication Method).
  <https://www.rfc-editor.org/rfc/rfc7583.html#section-3.2.1>
- **The situation**: a zone operator replaces a signing key while resolvers
  around the world hold cached copies of the old one, and every intermediate
  moment must still validate.
- **The property**: RFC 7583 states the whole thing as timing algebra rather than
  as requirements. "This interval is the publication interval (Ipub) and, for the
  second or subsequent keys in the zone, is given by: `Ipub = Dprp + TTLkey`" —
  where "Dprp is the propagation delay -- the time taken for a change introduced
  at the master to replicate to all nameservers.  TTLkey is the TTL for the
  DNSKEY records in the zone.  The sum is therefore the maximum time taken for
  existing DNSKEY records to expire from caches, regardless of the nameserver
  from which they were retrieved." Then `Trdy(N) = Tpub(N) + Ipub`,
  `Tact(N) >= Trdy(N)`, `Tpub(N+1) <= Tact(N) + Lzsk - Ipub`, and
  `Tret(N) = Tact(N) + Lzsk`. §3.1 defines an eight-state key lifecycle:
  Generated, Published, Ready, Active, Retired, Dead, Removed, Revoked.
- **Shape**: `rollout`.
- **The interesting mistake**: the safety property is that no resolver ever ends
  up holding a cached DNSKEY set that does not contain the key which signed the
  RRSIG it is also holding. The constraint that enforces it is `Tact(N) >=
  Trdy(N)` — activate no earlier than one full `Ipub` after publication. Shorten
  `Ipub`, or forget that it must be recomputed when `TTLkey` changes, and a
  resolver with a stale DNSKEY set fails validation and the zone goes dark. This
  is the classic staged-rollout bug — the new thing is in use before every reader
  can see it — with an RFC that spells out the required lead time as an equation.
- **Ground truth**: **the mechanism is published in full and the normative force
  is zero.** RFC 7583 is Category: Informational and the string `MUST` appears in
  it **zero times** (checked by grep over the downloaded text, 2026-09-06). Its
  companion RFC 6781, "DNSSEC Operational Practices, Version 2", is also
  Informational and contains four MUSTs, none about rollover timing. So there is
  a detailed published state model and a complete set of timing equations, and
  nothing anywhere says an implementation is wrong to ignore them. That is the
  opposite failure mode from the idempotency draft (§5) — there the size was
  right and the content thin; here the content is rich and the authority absent.
- **Size**: 1 zone, 2 keys, 2-3 resolver caches, a clock. **Genuinely an
  evening**, and the eight states reduce to four or five if `Revoked` and
  `Generated` are dropped.
- **Verdict on this one**: usable, but present it as "here is a published design
  and its timing algebra; check that the algebra does what the prose says it
  does" rather than as "here is what a conforming implementation must do".

---

# 11. Email delivery semantics — RFC 5321, RFC 9051

This turned out to be the richest family in the survey after OAuth, and for a
different reason: **it is close to virgin territory for formal modelling.** See
§11.10 at the end — there is exactly one published formal model of either
protocol on the open web, it is a TLA+ spec, and its own TODO file lists two of
the candidates below as explicitly unmodelled.

## 11.1 The SMTP point of no return (SMALLEST GOOD CANDIDATE IN THE SURVEY)

- **Standard and section**: RFC 5321 §4.2.5 (Reply Codes after DATA and the
  Subsequent `<CRLF>.<CRLF>`), §4.1.1.4, §6.1, §4.5.3.2.6, with RFC 1047
  "Duplicate Messages and SMTP" as the analysis.
  <https://www.rfc-editor.org/rfc/rfc5321.html#section-4.2.5>,
  <https://www.rfc-editor.org/rfc/rfc1047.html>
- **The situation**: a sending relay has streamed a message and sent the
  terminating `<CRLF>.<CRLF>`; the receiver has committed it to disk and is
  composing its `250` when the connection dies — so both ends hold a live copy
  and each believes it is the responsible party.
- **The property**: responsibility is a token that transfers on a reply the
  sender may never see, and §4.2.5 says so for each reply class. "When an SMTP
  server returns a positive completion status (2yz code) after the DATA command
  is completed with `<CRLF>.<CRLF>`, it accepts responsibility for: delivering
  the message (if the recipient mailbox exists), or [...]" and, for the other
  side, "When an SMTP server returns a temporary error status (4yz) code after
  the DATA command is completed with `<CRLF>.<CRLF>`, it MUST NOT make a
  subsequent attempt to deliver that message.  The SMTP client retains
  responsibility for the delivery of that message". §6.1 adds the durability
  half — "It MUST NOT lose the message for frivolous reasons, such as because the
  host later crashes or because of a predictable resource shortage." — and
  §4.1.1.4 the atomicity of the decision — "The SMTP model does not allow for
  partial failures at this point: either the message is accepted by the server
  for delivery and a positive response is returned or it is not accepted and a
  failure reply is returned."
  The duplicate consequence is admitted rather than prevented, in §6.1 — "To
  avoid receiving duplicate messages as the result of timeouts, a receiver-SMTP
  MUST seek to minimize the time required to respond to the final
  `<CRLF>.<CRLF>` end of data indicator." Note what that MUST does *not* say: it
  does not forbid duplicates, require deduplication, or bound the count. It
  requires that a *window be made small*. §4.5.3.2.6 is franker still: "A
  spurious timeout at this point would be very wasteful and would typically
  result in delivery of multiple copies of the message, since it has been
  successfully sent and the server has accepted responsibility for delivery."
- **Shape**: `delivery`.
- **The interesting mistake**: modelling the `250` as atomic with the commit.
  The learner writes one action that flips ownership, proves "exactly one party
  is responsible", and has proved a property of a system nobody can build. The
  real invariant is weaker and is the whole lesson: *at least* one party is
  always responsible, and the window where both are is not a defect to design
  away. The second mistake is treating the client's timeout as a rollback — the
  client requeues, but the server did not un-accept.
- **Ground truth**: **strong on mechanism, absent on measurement.** RFC 1047
  (Craig Partridge, BBN, February 1988) is 170 lines devoted to this single race
  and names the state exactly: "During the period between the time the receiving
  mailer has determined that it will accept the message, and the time that
  sending mailer gets the 250 reply, the message is active at both the sending
  and receiving mailer. [...] If the communications link fails during this
  synchronization gap, then the message has been duplicated." It ranks it
  "the second leading cause of duplicate messages on the Internet (second to
  mail loops)", and RFC 5321 §6.1 cites it normatively. There is also a
  **protocol fix that never deployed**: RFC 1845 (Experimental) added
  `CHECKPOINT` and a transaction ID precisely so an interrupted transfer could
  resume rather than replay, and `draft-fanf-smtp-rfc1845bis` (Finch, 2007)
  restates the problem and notes PIPELINING makes it worse. Operationally,
  Postfix's `smtp_data_done_timeout` documentation states that on timeout "a
  warning is logged that the mail may be delivered multiple times"
  (<https://www.postfix.org/postconf.5.html#smtp_data_done_timeout>) — relayed,
  not personally fetched. **No published measurement of duplicate rates exists,
  and no MTA documents envelope-ID deduplication.** RFC 5321's three verified
  errata are ABNF and editorial; none touches the delivery-semantics sections.
- **Size**: 2 actors plus a lossy reply channel. State: client queue, server
  queue, delivered set, reply-in-flight flag. **Four variables — the smallest
  good candidate here.** This is the two-generals problem with a real system
  attached, which is what makes it usable for a learner who has already rejected
  the abstract version as computer science.

## 11.2 Queue retry, give-up, and the bounce that follows

- **Standard and section**: RFC 5321 §4.5.4, §4.5.4.1, §6.1.
  <https://www.rfc-editor.org/rfc/rfc5321.html#section-4.5.4>
- **The situation**: a relay holds a message it cannot deliver, retries on a
  schedule for days, and must eventually either succeed or give up and tell
  somebody.
- **The property**: a queued message reaches a terminal state and never
  evaporates. "The sender MUST delay retrying a particular destination after one
  attempt has failed.  In general, the retry interval SHOULD be at least 30
  minutes" / "Retries continue until the message is transmitted or the sender
  gives up; the give-up time generally needs to be at least 4-5 days." / "If
  there is a delivery failure after acceptance of a message, the receiver-SMTP
  MUST formulate and mail a notification message."
- **Shape**: `expiry`.
- **The interesting mistake**: treating give-up as terminal. It is not — it is a
  transition into a *second* delivery problem, because the bounce is itself a
  message with the same lifecycle. A learner who models the bounce as an atomic
  "notify sender" misses how mail systems generate unbounded work.
- **Ground truth**: **none external.** No erratum touches §4.5.4. The constants
  are SHOULD-level and the RFC says "The parameters to the retry algorithm MUST
  be configurable" — so they are explicitly model parameters and only the
  structure is normative. Say plainly: nothing outside the learner's own
  reasoning settles the interesting cases here.
- **Size**: 1 actor, a destination oracle, a queue with per-message attempt count
  and age. 5-6 variables.

## 11.3 Never bounce a bounce

- **Standard and section**: RFC 5321 §6.1, §4.5.4, §4.5.5, §3.6.3; RFC 3464 §2;
  **RFC 3834** (Standards Track, August 2004).
  <https://www.rfc-editor.org/rfc/rfc5321.html#section-6.1>,
  <https://www.rfc-editor.org/rfc/rfc3834.html>
- **The situation**: two relays each hold an undeliverable message addressed to
  the other, each obliged to notify a sender — and the null reverse-path is the
  only thing between that and an infinite exchange of error reports.
- **The property**: the cleanest termination argument in the email stack, stated
  in three documents. RFC 5321 §6.1 — "This notification MUST be sent using a
  null ('<>') reverse-path in the envelope. [...] However, if this address is
  null ('<>'), the receiver-SMTP MUST NOT send a notification." §4.5.4, as a
  queueing rule — "A queuing strategy MUST NOT send error messages in response to
  error messages under any circumstances." §3.6.3 gives the reason — "SMTP
  servers MUST NOT send notification messages about problems transporting
  notification messages.  One way to prevent loops in error reporting is to
  specify a null reverse-path in the MAIL command of a notification message."
  RFC 3834 supplies an independent prohibition from a different document — "
  Responders MUST NOT generate any response for which the destination of that
  response would be a null address (e.g., an address for which SMTP MAIL FROM or
  Return-Path is <>), since the response would not be delivered to a useful
  destination."
- **Shape**: `workflow`.
- **The interesting mistake**: modelling the null reverse-path as a *value*
  rather than as the terminating case of an induction. The property that matters
  is that the message graph is well-founded — every bounce is one level shallower
  than what it bounces, and the `MUST NOT send a notification` clause bounds the
  depth at 1. Break either half — rewrite `<>` to a real address, or generate a
  notification for a message whose return path is null — and one failed delivery
  produces an unbounded message population. §6.3 adds belt and braces: "Whatever
  mechanisms are used, servers MUST contain provisions for detecting and stopping
  trivial loops."
- **Ground truth**: **strong — the strongest of the SMTP candidates.** The
  failure class has a name inside the standards themselves: RFC 3834 calls it
  "sorcerer's apprentice mode" and defines it as "a bug in a program that causes
  it to send unwanted mail", and it carries a one-response-per-message rule
  explicitly justified as guarding against that multiplication — I read both.
  Outside the RFCs the same phenomenon is called **backscatter**, and the
  forged-sender attack that produces it a **Joe job**; deployed countermeasures
  with published specifications exist (BATV, SRS). Those last three names are
  relayed rather than sourced by me. **No CVE** — this is a systemic abuse
  pattern, not a memory-safety class.
- **Size**: 2 relays, a message set with an "is a notification" bit and a
  nullable sender. 3-4 variables. **Genuinely an evening, and the property is a
  termination one**, which is a different exercise from the safety invariants
  that dominate this survey.

## 11.4 Multi-recipient DATA — atomic accept, non-atomic delivery

- **Standard and section**: RFC 5321 §4.1.1.4, §4.5.4.1, §6.1.
  <https://www.rfc-editor.org/rfc/rfc5321.html#section-4.1.1.4>
- **The situation**: one SMTP transaction carries a message to several
  recipients, the server answers the whole transaction with a single reply, and
  the recipients then succeed or fail independently.
- **The property**: one reply covers N recipients, and per-recipient outcomes
  must be reported by a different mechanism. "The SMTP model does not allow for
  partial failures at this point: either the message is accepted [...] or it is
  not accepted and a failure reply is returned." / "Errors that are diagnosed
  subsequently MUST be reported in a mail message" / "When a mail message is to
  be delivered to multiple recipients, and the SMTP server to which a copy of the
  message is to be sent is the same for multiple recipients, then only one copy
  of the message SHOULD be transmitted." §6.1 supplies the reason partial failure
  is unavoidable: "Some delivery failures after the message is accepted by SMTP
  will be unavoidable."
- **Shape**: `delivery`.
- **The interesting mistake**: conflating the transaction with the deliveries.
  One `250` can produce four deliveries and one bounce, so **the count of
  outcomes does not match the count of replies** — the same shape as a batch
  write that partially fails behind a single acknowledgement.
- **Ground truth**: **none external.** Rests entirely on normative text, which is
  explicit for it. No erratum on §4.1.1.4.
- **Size**: 1 client, 1 server, N recipients (N=3 suffices). 5 variables;
  recipients are the obvious symmetry set.

## 11.5 IMAP two-phase deletion — `\Deleted` then EXPUNGE

- **Standard and section**: RFC 9051 §2.3.2, §6.4.1 (CLOSE), §6.4.2 (UNSELECT),
  §6.4.3 (EXPUNGE).
  <https://www.rfc-editor.org/rfc/rfc9051.html#section-6.4.1>
- **The situation**: deleting mail takes two steps — mark, then reap — and which
  of four commands performs the reap decides whether the mail survives.
- **The property**: `\Deleted` is a *pending intent*, and which command
  discharges it is a small table. "`\Deleted` Message is 'deleted' for removal by
  later EXPUNGE" / "The CLOSE command permanently removes all messages that have
  the `\Deleted` flag set [...] No untagged EXPUNGE responses are sent." / "The
  SELECT, EXAMINE, and LOGOUT commands implicitly close the currently selected
  mailbox without doing an expunge." UNSELECT "performs the same actions as
  CLOSE, except that no messages are permanently removed".
- **Shape**: `lifecycle`.
- **The interesting mistake**: believing CLOSE and UNSELECT are the same command
   — they differ on exactly one thing, and it is whether mail is destroyed.
  Symmetrically, a client that sets `\Deleted` and then issues `SELECT` elsewhere
  has silently deleted *nothing*. And CLOSE destroys data while sending **no**
  EXPUNGE responses, so a cache-updating client learns nothing.
- **Ground truth**: internal and stable — the rule is identical in RFC 3501 and
  RFC 9051 across nineteen years, with **no erratum** on these sections in
  either. The `EXPUNGEISSUED` response code (§7.1) is evidence the working group
  expected concurrent expunges to confuse clients.
- **Size**: 1 mailbox, 3-4 messages, 1-2 clients. 4 variables. A good warm-up for
  11.6.

## 11.6 EXPUNGE renumbering and client/server desynchronisation (BEST IMAP CANDIDATE)

- **Standard and section**: RFC 9051 §7.5.1, §5.5, §5.2, §2.3.1.2 (identical rule
  at RFC 3501 §7.4.1), plus **RFC 2180 "IMAP4 Multi-Accessed Mailbox Practice"**
  in full.
  <https://www.rfc-editor.org/rfc/rfc9051.html#section-7.5.1>,
  <https://www.rfc-editor.org/rfc/rfc2180.html>
- **The situation**: messages are addressed by position, positions shift down on
  removal, and the server may announce removals mid-conversation — so a command
  the client sent moments ago may now name a different message than it meant.
- **The property**: "The message sequence number for each successive message in
  the mailbox is immediately decremented by 1, and this decrement is reflected in
  message sequence numbers in subsequent responses (including other untagged
  EXPUNGE responses)." And the guard, with its purpose attached — "An EXPUNGE
  response MUST NOT be sent when no command is in progress, nor while responding
  to a FETCH, STORE, or SEARCH command.  This rule is necessary to prevent a loss
  of synchronization of message sequence numbers between client and server."
  §5.5 gives the client obligation — "it MUST wait for the completion result
  response before sending a command with message sequence numbers" — with the
  carve-out that makes it subtle: "Note: EXPUNGE responses are permitted while
  UID FETCH, UID STORE, and UID SEARCH are in progress." §5.2 makes EXPUNGE the
  sole shrink channel: "it is NOT permitted to send an EXISTS response that would
  reduce the number of messages in the mailbox."
- **Shape**: `concurrency`.
- **The interesting mistake**: two, both real. First, the ordering artefact the
  RFC spells out and prints both conforming outputs for: "if the last 5 messages
  in a 9-message mailbox are expunged, a 'lower to higher' server will send five
  untagged EXPUNGE responses for message sequence number 5, whereas a 'higher to
  lower' server will send successive untagged EXPUNGE responses for message
  sequence numbers 9, 8, 7, 6, and 5." Second, and worth building the model for:
  pipeline `STORE +FLAGS \Deleted` on sequence number 4 behind a command that
  permits an EXPUNGE, let the server expunge message 2 in between, and the client
  flags the wrong message for deletion.
- **Ground truth**: **the best of any candidate in this family, from three
  independent directions.** (a) **RFC 2180** (Informational, July 1997) is an
  entire RFC devoted to this problem. Its §4 opens: "Because an EXPUNGE response
  can not be sent while responding to a FETCH, STORE or SEARCH command, it is not
  possible to immediately notify the client of the EXPUNGE.  This can result in
  ambiguity if the client issues a FETCH, STORE or SEARCH operation on a message
  that has been EXPUNGED." It then enumerates the permitted server behaviours for
  FETCH (§4.1.1-4.1.4), STORE (§4.2.1-4.2.4), SEARCH (§4.3) and COPY (§4.4), and
  §4.1 supplies a **ready-made model configuration**: "Client #1 and Client #2
  have mailbox FOO selected. There are 7 messages in the mailbox. Messages 4:7
  are marked for deletion. Client #1 issues an EXPUNGE, to expunge messages 4:7".
  (b) **RFC 3501 Errata ID 261, status Verified, type Technical, filed by Mark
  Crispin — the author of IMAP — on 2007-06-13** amends §5.5 and §2.3.1.1; the
  text it added is what RFC 9051 now carries. The protocol's own author found the
  original wording insufficient to prevent this desynchronisation. (c) A real bug
  in which the wrong messages were permanently deleted: Mutt issue 121,
  <https://gitlab.com/muttmua/mutt/-/issues/121> — "If the messages marked for
  deletion are nonconsecutive [...] then any messages in between them will end up
  being purged without warning" (relayed, not personally fetched).
- **Size**: 1 server, 2 clients, 4-5 messages. State: server mailbox as an
  *ordered sequence*, per-client cached view, in-flight command queue,
  per-message `\Deleted`. 5-6 variables. The sequence-versus-set distinction is
  the modelling work, and it is the right kind.

## 11.7 UID, UIDVALIDITY and UIDNEXT as monotonicity invariants (CLEANEST INVARIANT SET IN THE SURVEY)

- **Standard and section**: RFC 9051 §2.3.1.1.
  <https://www.rfc-editor.org/rfc/rfc9051.html#section-2.3.1.1>
- **The situation**: a client caches a mailbox offline and resynchronises on
  reconnect, relying on the server's identifier scheme to tell it what changed
  without refetching everything.
- **The property**: six MUSTs, all pure monotonicity and uniqueness, in one
  section — close to a pre-written specification. "Unique identifiers are
  assigned in a strictly ascending fashion in the mailbox" / "the next unique
  identifier value MUST NOT change unless new messages are added to the mailbox;
  and second, the next unique identifier value MUST change whenever new messages
  are added to the mailbox, even if those new messages are subsequently expunged."
  / "If unique identifiers from an earlier session fail to persist in this
  session, the unique identifier validity value MUST be greater than the one used
  in the earlier session." / "The combination of mailbox name, UIDVALIDITY, and
  UID must refer to a single, immutable (or expunged) message on that server
  forever." / "When a message is expunged, its UID MUST NOT be reused under the
  same UIDVALIDITY value."
- **Shape**: `lifecycle`. (It is also legitimately `two-store` — the invariants
  exist to make a client cache resyncable — but the normative text is organised
  around the identifiers themselves.)
- **The interesting mistake**: **the UIDNEXT rule is a biconditional that reads
  like an implication.** Together the two clauses mean UIDNEXT is a
  strictly-increasing counter of *arrivals* that is **not** recoverable from
  current contents — a message that arrived and was expunged leaves no trace
  except in UIDNEXT. An implementer who computes `max(UID) + 1` over live
  messages violates the second clause the moment the newest message is expunged,
  and every disconnected client then concludes nothing has arrived. A one-line
  bug with a silent, delayed, data-losing symptom. The RFC's own note gives the
  client's use case that this breaks: "The next unique identifier value is
  intended to provide a means for a client to determine whether any messages have
  been delivered to the mailbox since the previous time it checked this value."
- **Ground truth**: **strong, and via an unusual route.** RFC 3501 **Errata ID
  261 (Verified, Technical, Mark Crispin)** also amends this section, tightening
  "A 32-bit value" to "An unsigned 32-bit value" — so the section has a
  documented history of under-specification found by the protocol's author.
  Better: **RFC 8474 (IMAP OBJECTID, Standards Track, 2018) exists because this
  identity scheme does not survive messages moving between mailboxes**, and its
  introduction states the consequence — "any other client connected to the same
  store cannot know with certainty that the messages are identical, so it will
  redownload everything." An entire Standards-Track extension published to patch
  a limitation is strong evidence the limitation is real. Client-side: isync /
  mbsync's NEWS file records at 1.4.1 "Fixed UIDVALIDITY change recovery
  potentially leading to data loss", with further fixes in 1.3.x and 1.5.1
  (relayed, not personally fetched).
- **Size**: 1 mailbox, 1 server, 1 reconnecting client. 4-5 variables. The
  temporal properties are exactly what a learner eleven chapters in wants to
  practise. **For a backend engineer who has ever built a resumable sync cursor,
  this is the most directly transferable problem in the survey.**

## 11.8 MOVE partial failure — at-least-once, stated as such

- **Standard and section**: RFC 9051 §6.4.8, against §6.4.7 (COPY) and §6.3.12
  (APPEND); original text at RFC 6851 §3.3.
  <https://www.rfc-editor.org/rfc/rfc9051.html#section-6.4.8>
- **The situation**: a client moves a set of messages from one mailbox to
  another, the server fails partway through, and every message must still be
  somewhere.
- **The property**: the best-stated at-least-once requirement in this survey,
  because the safety floor is a MUST and the deduplication preference a SHOULD
  NOT, in adjacent sentences. "Regardless of whether the command is successful in
  moving the entire set, each individual message MUST be either moved or
  unaffected.  The server MUST leave each message in a state where it is in at
  least one of the source or target mailboxes (no message can be lost or
  orphaned).  The server SHOULD NOT leave any message in both mailboxes (it would
  be bad for a partial failure to result in a bunch of duplicate messages).  This
  is true even if the server returns a tagged NO response to the command."
  The RFC even supplies the decomposition to model against: MOVE is equivalent to
  `COPY` + `STORE +FLAGS.SILENT \DELETED` + `UID EXPUNGE`, except "the
  intermediate states produced by those steps do not occur". Contrast COPY, which
  is all-or-nothing — "partial copy MUST NOT be done" — and APPEND — "no partial
  appending is permitted."
- **Shape**: `two-store`.
- **The interesting mistake**: modelling MOVE as atomic, which the spec forbids
  for a set — while COPY and APPEND *are* atomic, so three neighbouring commands
  have two different failure models. Subtler: the safety floor is
  `in source OR in target`, so a conforming server may leave a message in
  **both**. And the guarantee holds "even if the server returns a tagged NO", so
  a client treating NO as "nothing happened" is wrong.
- **Ground truth**: **excellent, and of a kind nothing else in this survey
  has — the requirement was strengthened between two published standards.**
  RFC 6851 §3.3 (2013) reads "each individual message SHOULD either be moved or
  unaffected"; RFC 9051 §6.4.8 (2021) reads "each individual message MUST be
  either moved or unaffected". I verified this by diffing the two source texts:
  `rfc6851.txt` line 177 against `rfc9051.txt` line 4687, with the rest of the
  paragraph byte-identical. The working group looked at eight years of deployed
  MOVE implementations and decided SHOULD was too weak for exactly this clause.
  RFC 9051 Appendix E corroborates ("Tightened requirements about COPY/MOVE
  commands"). Bug reports exist on the **duplicate** side only: Thunderbird bug
  610131, where bulk move was implemented as bulk-copy-then-bulk-delete and
  interrupting it left messages in both folders — precisely the non-atomic
  sequence RFC 6851 exists to replace (relayed). No published server-side bug
  losing a message outright, which matches the RFC's own risk ranking.
- **Size**: 1 server, 2 mailboxes, 3-4 messages, 1 client, a failure oracle. 4-5
  variables. **Nearly pre-formalised — three separately checkable clauses in one
  paragraph.**

## 11.9 CONDSTORE MODSEQ monotonicity

- **Standard and section**: **RFC 7162 §3.1**, inherited verbatim from RFC 4551
  §1 (June 2006), which said "the use" where RFC 7162 says "the direct use".
  <https://www.rfc-editor.org/rfc/rfc7162.html#section-3.1>
- **The situation**: a mailbox stamps every flag change with a modification
  sequence number, and a disconnected client asks "give me everything since N" —
  so the stamps must never go backwards, across connections or across an NTP
  correction.
- **The property**: "The server MUST guarantee that each STORE command performed
  on the same mailbox (including simultaneous stores to different metadata items
  from different connections) will get a different mod-sequence value.  Also, for
  any two successful STORE operations performed in the same session on the same
  mailbox, the mod-sequence of the second completed operation MUST be greater
  than the mod-sequence of the first completed operation." With a no-op exemption
  that is easy to get backwards: "Setting a flag that is already set, or clearing
  a flag that is not set, SHOULD NOT change the mod-sequence."
- **Shape**: `concurrency`.
- **The interesting mistake**: **the RFC names it, in normative text, in the very
  next sentence** — "Note that the latter rule disallows the direct use of the
  system clock as a mod-sequence because if system time changes (e.g., an NTP
  [NTP] client adjusting the time), the next generated value might be less than
  the previous one." A learner can model `MODSEQ := now()` as one action, watch
  monotonicity fail under a backwards clock step, and check the counterexample
  against a sentence in the RFC.
- **Ground truth**: **RFC-normative only, no attested instance — and that is
  worth saying plainly.** The RFC naming its own violating implementation is real
  and citable, and the rule has stood unamended since 2006. But no real
  implementation is documented as having made this mistake: Dovecot uses a
  transaction-log counter, Cyrus uses `mboxname_nextmodseq()` against a
  persistent counters file, and searches of the Dovecot, Cyrus and Thunderbird
  trackers found nothing (relayed). RFC 7162's errata are one Verified (5055, an
  example missing response text) and one Reported (8249, ABNF); neither touches
  the monotonicity rule. It is still a fine exercise — arguably the cleanest pure
  invariant warm-up here — but the mistake is hypothesised by the standard rather
  than observed in the wild.
- **Size**: 1 mailbox, 2 connections, 3 messages, a counter, a clock that can
  step backwards. 4-5 variables.

## 11.10 One that fails the "is the text enough" test, and the prior-art finding

**SMTP mail loops, RFC 5321 §6.3 — excluded.** The normative text is "SMTP
servers using this technique SHOULD use a large rejection threshold, normally at
least 100 Received entries" and "Whatever mechanisms are used, servers MUST
contain provisions for detecting and stopping trivial loops." The second clause
is unfalsifiable as written, since "trivial" is undefined. **The text is not
enough** without the learner inventing the topology — which is worth recording
because the *ground truth* here is the best in the family (CVE-2002-1005 and
CVE-2000-0738 are both mail-loop DoS; the Microsoft "Bedlam DL3" storm of 1997
and the NHSmail storm of 2016 are documented amplification events, relayed). It
is a clean case of good evidence attached to a specification too vague to model.

**Prior art: there is essentially none, and that is an argument for this
family.** There is exactly one published formal model of either protocol on the
open web: `chatmail/models/fetching/deltachat.tla`, a **407-line TLA+
specification** from the Delta Chat project. I fetched and read it. It models one
IMAP server and multiple devices moving messages from Inbox to a Movebox, with
`vars == <<Storage, UidNext, LastSeenUid, SentMessages, ReceivedMessages,
ImapTable>>` — a whole-state tuple, which is the corpus-conformant style this
project's own `.claude/rules/tla-practice.md` §2 documents at 96% of resolvable
box sites. It carries invariants `ImapTableCorrect`, `WeakNoReordering`,
`StrongNoReordering`, `InboxMessagesScheduledForDeletionInvariant` and liveness
properties `AllMessagesDownloadedEventually`, `EmptyInboxEventually`,
`PerfectImapTableEventually`, each stated as a `THEOREM Spec => []P`.

Its `TODO` file is the part that matters. I read it directly, and it lists as
explicitly unmodelled:

```
1. Model the case when the message may arrive multiple times.
...
3. Model UIDVALIDITY reset at arbitrary times.
```

Those are candidates 11.1 and 11.7. **The only existing formal model in this
domain leaves precisely the two problems this survey would set.** Searches for
TLA+, Alloy, Coq, Isabelle or SPIN models of SMTP or IMAP turned up nothing else;
`tlaplus/Examples` contains no mail-protocol spec (relayed for the search,
personally verified for the Delta Chat file).

---

# Answers to the five questions

## 1. Which sections are the right size?

Six, ordered by how confident I am. Every one is two or three actors and no more
than six pieces of state, and every one has something outside the learner's head
that says what the right answer is.

| # | Candidate | Why it is the right size |
|---|---|---|
| 1 | **RFC 9110 §13.1.1 — lost update with If-Match** (2.2) | 3 actors, 2 pieces of state. The RFC names the counterexample — nonatomic increment — in the section that defines the mechanism. |
| 2 | **RFC 9051 §6.4.8 — IMAP MOVE partial failure** (11.8) | 4-5 variables, three separately checkable clauses in one paragraph, and the requirement was **strengthened from SHOULD to MUST** between RFC 6851 and RFC 9051, which tells the learner which clause is load-bearing without guessing. |
| 3 | **RFC 9700 §4.8 — PKCE downgrade** (4.1) | 4 actors, 5 pieces of state. Two MUSTs individually satisfiable while the system is broken; a printed six-step attack; a MUST-strength patch. |
| 4 | **RFC 9051 §2.3.1.1 — IMAP UID / UIDNEXT / UIDVALIDITY** (11.7) | 1 server, 1 client, 3 messages. Six MUSTs already written as invariants. The highest quality-per-line in the survey. |
| 5 | **RFC 8555 §8.2 — ACME challenge retry** (7.1) | 1 challenge, 1 counter. Three sentences that deadlock, and a **verified erratum** saying so. |
| 6 | **RFC 6455 §5.5.1 — WebSocket close handshake** (8.1) | 2 endpoints, 4-6 variables. Autobahn cases 7.1.1 / 7.1.2 / 7.1.4 are the answer key. |

A close second tier, all the right size and all with real ground truth:
**RFC 5321 §4.2.5 with RFC 1047** (11.1) — four variables, the smallest here;
**RFC 9051 §7.5.1 with RFC 2180** (11.6) — the richest, with a whole RFC of
ground truth behind it; **RFC 8446 §8** (6.1) — a *bounded* guarantee, which is
an unusual and instructive property to write; and **RFC 9293 §3.6 simultaneous
close** (3.2), which is RFC 9293's Figure 5 with everything but the close half
deleted.

The one I would give him **first** is 2.2, because it is two clients and a
counter and the RFC hands him both the property and the counterexample in one
paragraph. The one I would give him **second** is 11.8, because it is the same
size and the SHOULD-to-MUST change is a rare and vivid demonstration that these
distinctions are load-bearing.

## 2. Which have real ground truth?

**Twenty-three of the forty-seven candidates recorded here have a documented
counterexample** — something outside the learner's own reasoning that says what
the wrong answer looks like. That is a much better hit rate than I expected going
in, and it comes from eight distinct mechanisms, three of which I did not know
to look for before this survey.

**Verified errata contradicting the specification** — 4 errata, 6 candidates:

| Candidate | Erratum | What it says |
|---|---|---|
| 3.1 TCP state diagram | **8710**, Verified 2026-02-11 | Figure 5 is missing the SYN-RECEIVED→LISTEN edge on SYN |
| 3.4 TCP requirement table | **8171**, Verified 2025-03-18 | The X is in the MUST column and the prose says SHOULD |
| 7.1 ACME challenge retry | **5732**, Verified 2024-02-22 | The retry mechanism as written is unreachable |
| 9.2 DNS TTL | **2130**, Verified 2012-04-26 | RFC 1035 calls the same field signed in §3.2.1 and unsigned in §4.1.3 |
| 11.6, 11.7 IMAP | **3501/261**, Verified, filed by **Mark Crispin** | The IMAP author found §5.5 and §2.3.1.1 under-specified against exactly this desynchronisation |

These are the best of the lot. A verified erratum is an answer key written by a
third party and ratified by the working group. In each case a learner who models
the section carefully finds precisely what the erratum found. **I read all five
entries directly** rather than taking them on report.

**A CVE** — 1 candidate: 6.2, HTTP/2 Rapid Reset, **CVE-2023-44487**, with a CISA
alert. The concurrency limit counts states and not work, and the whole internet
found out in October 2023.

**Whole RFCs that are the counterexample** — 3 candidates. **RFC 1337**
(TIME-WAIT assassination, 1992) for 3.3; **RFC 1047** (duplicate messages in
SMTP, 1988) for 11.1; **RFC 2180** (IMAP multi-accessed mailbox practice, 1997)
for 11.6. Each is a short document whose entire content is one race condition,
each is cited from the current standard, and RFC 1337 and RFC 1047 print the race
as a message-sequence chart. These are the closest thing in the published record
to a model-checker error trace. RFC 2180 goes further and supplies a **ready-made
model configuration** — two clients, seven messages, 4:7 marked deleted.

**Named attacks with printed steps in a security BCP** — 6 candidates, in the
OAuth, TLS and WebSocket families. RFC 9700 §4 alone contains seventeen. This is
the single richest seam and the reason OAuth is the best-supplied family.

**Executable conformance suites** — 3 families: `cache-tests.fyi` for RFC 9111,
Autobahn for RFC 6455, the OpenID Foundation suite for OAuth. Autobahn is the
most useful of the three, because each case ships a `DESCRIPTION` and an
`EXPECTATION` string that read as acceptance criteria, and because some cases
(7.13.1, 2.11) explicitly mark where the spec runs out.

**A requirement strengthened between two published standards** — 1 candidate,
and a mechanism I had not thought of. RFC 6851 §3.3 said "each individual message
SHOULD either be moved or unaffected"; RFC 9051 §6.4.8 says "MUST be either moved
or unaffected", with the rest of the paragraph byte-identical. I verified it by
diffing the sources. Eight years of deployed implementations told the working
group which clause could not be left optional — and that is ground truth of a
sort no single document can supply.

**A Standards-Track extension published because of the limitation** — 1
candidate. RFC 8474 (IMAP OBJECTID, 2018) exists because RFC 9051's identity
scheme does not survive messages moving between mailboxes, and its introduction
states the consequence.

And one mechanism I did not expect to matter and which turned out to matter a
lot: **specifications that state their own negative result.** RFC 9111 §4.4
("this does not guarantee that all appropriate responses are invalidated
globally"), RFC 7009 §2.1 ("In practice, there could be a propagation delay"),
RFC 9700 §4.14.2 ("The authorization server cannot determine which party
submitted the invalid refresh token"), RFC 8446 §8 ("this limits the number of
replays to the number of server instances"), RFC 5321 §6.1 (a MUST that asks only
that a window be made *small*), RFC 6455 §7.1.5's NOTE. Seven candidates carry
one. A learner who writes the strong property gets a counterexample and then
finds the RFC telling him, in the same section, that it was always going to.

**Roughly twelve candidates have essentially no ground truth** and I have said so
in each: 1.5, 2.4, 4.5, 5, 6.4, 6.5, 7.4, 9.1, 10, 11.2, 11.4 and 11.9. The
pattern is worth naming — **the candidates without ground truth are the ones
where the mechanism is uncontroversial.** Nobody files an erratum against a rule
that works. 11.9 is the interesting boundary case: the RFC names the violating
implementation (a system clock) in normative text, and no real implementation is
documented as having made the mistake. Flag it as *hypothesised by the standard,
not observed in the wild*.

## 3. Is the normative text actually enough?

**Yes for about nine of the eleven families, and the exceptions are identifiable
in advance by one test.**

The brief's worry is exactly right in the general case: a standard says what an
implementation MUST do without saying what the system is. "A cache MUST NOT reuse
a stored response unless..." names no actors, no channel, no clock. Turning it
into a statement means deciding how many caches there are, whether the network
loses messages, and what a clock is — and the RFC does not say.

**The test that separates the two cases is whether the document ships a second,
independent description of the same machine.** Where it does, the learner has
both a next-state relation and an invariant, and the exercise is checking them
against each other rather than inventing one of them:

- a **published state diagram** — RFC 9293 Figure 5, RFC 8555 §7.1.6 (four of
  them), RFC 9113 Figure 2;
- a **labelled attacker model** — RFC 9700 §3, attackers A1 to A5, and the RFC
  says outright it came from formal analysis;
- a **printed message-sequence trace** — RFC 9293 Figures 7, 12 and 13; RFC 1337
  Figure 1; RFC 9700 §4.5.1 and §4.8.1; Autobahn case 5.19; RFC 9051 §7.5.1's
  pair of divergent EXPUNGE outputs;
- a **worked scenario** — RFC 2180 §4.1, which is a model configuration in prose;
- **invariants already written as invariants** — RFC 9051 §2.3.1.1 and §6.4.8,
  which read like they were drafted by someone with a specification language in
  mind.

Where the document ships none of those, the learner is designing rather than
checking. Four candidates in this survey fall on that side and I have flagged
each in place: **RFC 8767 §5** is labelled "Example Method" and §6 says the
document "intentionally does not provide a formal algorithm"; **RFC 7583** is
Informational with zero MUSTs; the **idempotency-key draft** is expired and its
only behavioural MUST is a documentation requirement; and **RFC 5321 §6.3** on
mail loops is unfalsifiable as written, because it requires servers to stop
"trivial" loops without defining the word. That last one is the cleanest negative
in the survey — excellent external ground truth attached to text too vague to
model.

Two smaller caveats that apply everywhere. First, in every case the learner must
supply a discrete clock, a channel model, and a bound on actors — but that is
standard modelling furniture, not inventing the system. Second, **check the
conformance section before quoting a MUST**: RFC 1035 predates BCP 14 entirely,
so its §7.4 "cache should" rules carry no normative weight and the quotable text
must come from RFC 2181 or RFC 8767; and RFC 6455 §2 declares its own diagrams
and notes non-normative while saying "Everything else in this specification is
normative", which makes its lowercase "must" in §5.5.3 arguably binding in a way
it would not be in a modern RFC.

## 4. Which shapes does this family cover well?

Across the 46 candidates that carry a shape tag (47 are named; the WebSocket
masking rule in §8.4 is listed as a free addition rather than tagged):

| shape | count | assessment |
|---|---|---|
| `two-store` | 8 | **Saturated.** Cache/origin, token/revocation-list, source/target mailbox, client-cache/server. This is what standards are mostly about. |
| `lifecycle` | 8 | **Saturated**, and the best-documented — TCP, ACME, WebSocket and IMAP all ship or imply a state machine. |
| `expiry` | 7 | **Saturated.** TTLs, freshness, 2MSL, authorization expiry, retry give-up, time-step windows. |
| `delivery` | 6 | **Well covered**, and unusually good: RFC 1047, RFC 8446 §8 and RFC 9110 §9.2.2 are all at-least-once versus exactly-once. |
| `concurrency` | 6 | Well covered. Lost update, nonce pools, frame interleaving, EXPUNGE renumbering, MODSEQ. |
| `workflow` | 5 | Adequately covered. The precondition ladder (2.1) and the bounce-termination argument (11.3) are the best. |
| `resource` | 5 | Well covered but thinner in ground truth — the exception is 6.2, which has a CVE. (4 tagged plus the TIME_WAIT rule in §8.4.) |
| `rollout` | **1** | **Effectively uncovered.** |

**The finding worth carrying out of this survey is that `rollout` is a hole.**
IETF standards specify a protocol at a point in time; they do not specify how a
population migrates from one version of it to another. The one candidate I found
(RFC 7583 DNSSEC key rollover, §10) has a complete eight-state model and a full
set of timing equations and **zero normative force** — Informational, and the
string `MUST` does not appear in it once. Its companion RFC 6781 is also
Informational.

If `rollout` problems are wanted, this family is the wrong place to look for
them. `INFERRED`, but the reasoning is specific: rollout is an operational
concern, and the IETF publishes operational guidance as Informational or BCP
rather than as Standards Track, which is precisely why the normative text thins
out exactly where the rollout content is.

## 5. Supply

**Dozens, comfortably — and more than I recorded.** This document names 47
candidates from 11 families, and I stopped because the brief's coverage list was
exhausted and the shape table had stopped filling in, not because the seam ran
out.

The strongest signal about supply is that **the good candidates cluster.** Once a
document ships a state diagram, an attacker model, or invariants already written
as invariants, it usually yields three to five separate problems rather than one:
RFC 9051 gave five, RFC 8555 gave five, RFC 9111 gave five, RFC 6455 gave four.
So the search is not for individual sections — it is for documents with a certain
property, and each hit pays out several times.

**And the field is close to empty.** There is exactly one published formal model
of SMTP or IMAP on the open web: `chatmail/models/fetching/deltachat.tla`, 407
lines of TLA+ from the Delta Chat project, which I fetched and read. Its own
`TODO` lists "1. Model the case when the message may arrive multiple times" and
"3. Model UIDVALIDITY reset at arbitrary times" — which are candidates 11.1 and
11.7. The only existing model in this domain leaves precisely the two problems
this survey would set. For a learner who wants his work to be more than an
exercise, that is worth knowing.

Three seams I opened and did not exhaust, in descending order of promise:

1. **RFC 9700 §4 has seventeen named attacks and I wrote up three.** §4.4
   (Mix-Up), §4.7 (CSRF), §4.11 (Open Redirection), §4.12 (307 Redirect) and
   §4.17 (in-browser communication flows) are each a numbered trace against a
   small system, in a document that supplies its own attacker model.
2. **The other security BCPs.** RFC 6819 (OAuth threat model), RFC 8725 (JWT best
   practices), and the HTTP/1.1 request-smuggling material in RFC 9112 §6.3 are
   the same shape and I read none of them.
3. **The verified-errata seam.** RFC 8446 has 16 verified errata, RFC 1035 has
   12, RFC 8555 has 11, RFC 9293 has 4. I read only the ones adjacent to
   candidates I was already writing up. Filtering all verified *technical* errata
   across a set of protocol RFCs for ones that name a **behavioural**
   contradiction would be a cheap, high-yield search — a verified technical
   erratum is by construction a documented counterexample somebody else already
   found and the IETF already ratified.

A fourth, cheaper than any of those: **diff a superseding standard against the
one it obsoletes and grep for SHOULD becoming MUST.** RFC 6851 to RFC 9051 gave
candidate 11.8 that way, and every "Changes from RFC NNNN" appendix in this
survey is a list of places to look.

---

# Coverage note — what this survey did not do

- **No model was written and no checker was run.** Every size estimate is a
  judgement from reading the section, marked `INFERRED` where it is load-bearing.
- **No CVE database was searched systematically.** CVE-2023-44487 is the only CVE
  I verified, and I found it by knowing to look. A systematic pass over CVEs that
  name an RFC section would very likely find more.
- **Errata were read selectively.** I fetched the errata index for 31 RFCs and
  read the individual entries for RFC 9293, 8555, 1035, 2308, 9110, 9111, 8446
  and 3501. I did not read all 16 of RFC 8446's verified errata, nor all 22 of
  RFC 8555's.
- **Conformance suites were identified, not read.** I confirmed `cache-tests.fyi`,
  Autobahn and the OpenID Foundation suite exist and checked what they claim to
  cover. Individual Autobahn case descriptions are relayed and spot-checked, not
  read by cloning the repository.
- **Some operational evidence is relayed rather than personally fetched** and is
  marked as such in place: the Postfix and Exim timeout documentation, the Mutt
  and Thunderbird bug reports, the isync NEWS entries, the Dovecot and Cyrus
  MODSEQ implementations, and the mail-loop CVEs. The RFC text, the errata
  entries, the RFC 6851-to-9051 diff and the Delta Chat TLA+ file I read myself.
- **Not read at all**: RFC 6265bis (only RFC 6265), RFC 6819, RFC 8725,
  RFC 9112 §6.3 (request smuggling), QUIC (RFC 9000/9002), MQTT and AMQP — not
  IETF, but the closest thing to the learner's industrial-IoT day job and
  probably worth a separate survey — and every ITU/ISO/IEC standard.
- **No interviews and no mailing-list archaeology.** The one mailing-list link
  cited came from inside an erratum.

---

# Verdict

**Primary source.**

The case rests on three things this survey established rather than assumed.

**One: the ground-truth rate is far better than the brief feared.** The worry was
that an RFC "has no built-in counterexample, so the check falls to the learner
and the model checker". Twenty-three of forty-seven candidates have one anyway,
through eight mechanisms — and the four strongest are of a kind that could not be
better suited: a **verified erratum** is a documented contradiction found by a
third party and ratified by a working group; **RFC 1337, RFC 1047 and RFC 2180**
are whole documents whose content is a race condition printed as a trace;
**RFC 9700 §4** is seventeen attacks written as numbered steps against an
attacker model the RFC itself says came from formal analysis; and the **RFC 6851
to RFC 9051 SHOULD-to-MUST change** is eight years of field experience compressed
into one word.

**Two: it fits the learner.** He rejected search puzzles, classic algorithms and
consensus protocols. Every candidate here is a mechanism he uses on a working
day — an HTTP cache, a token refresh, a mailbox sync cursor, a retry queue, a
close handshake — specified by someone with no stake in this project, in
normative prose, at a size he can finish in an evening. The two-generals problem
he would have refused as computer science arrives as RFC 5321 §4.2.5 with a
Postfix log line attached.

**Three: the supply is deep and the field is empty.** Forty-seven candidates from
eleven families, with three named seams unexhausted and a fourth technique
(diffing superseding standards for SHOULD-to-MUST) that generates more. And the
only published formal model of SMTP or IMAP in existence is a 407-line TLA+ file
whose TODO lists two of these candidates as unmodelled.

**What would change my mind.**

- **If the first three problems built from this turn out to take a weekend rather
  than an evening.** Every size estimate here is a judgement from reading, not
  from modelling. If RFC 9110 §13.1.1 — the smallest, clearest candidate — needs
  more scaffolding than a single sitting allows, then the size claim is wrong
  across the board and this drops to secondary.
- **If the learner finds the normative-to-formal translation is the whole
  exercise.** The risk is that turning "a cache MUST NOT reuse a stored response
  unless" into TLA+ consumes the evening and leaves no time for the checking that
  makes it worth doing. The mitigation is in the answer to question 3 — favour
  documents that ship a second description of the machine — but it is a
  hypothesis until tested.
- **If ground truth turns out not to help.** A verified erratum tells you *that*
  something is wrong, not what a model of it looks like. If the learner
  reconstructs errata 5732 and finds it added nothing to the exercise, then the
  ground-truth argument is decorative and RFCs are just a source of well-written
  problems — still fine, but not the distinctive thing claimed here.
- **Nothing found in this survey would change my mind about `rollout`.** That
  hole is structural, not an artefact of where I looked, and it will need a
  different family.
