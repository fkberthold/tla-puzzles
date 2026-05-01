# C02: Cross-Tier Capstone (Tiers 4–6) ⭐⭐⭐

## Lesson: Cross-Tier Capstone — Distinct Processes + Liveness + Refinement

No new concept. This is a CROSS-TIER capstone: it composes work from Tiers 4, 5, and 6 in a single problem.

- **Tier 4** — `distinct processes` with different code, synchronizing via `await`. (T35, T36, T39.)
- **Tier 5** — `~>` (leads-to), `[]<>` (infinitely often), and `SF_vars(...)` (strong fairness). (T44, T45, T47.)
- **Tier 6** — refinement: an abstract spec, a concrete spec with more mechanism, a mapping, and TLC verifying `PROPERTY Refines`. Stuttering steps. (T53–T58.)

Recap of what each piece buys you in this capstone:

- **Two distinct processes** model the SYSTEM REALITY: a client that submits requests and a server that processes them. Each has its own code; they share a queue.
- **`await`** lets the server block until there's something to do, and lets the client block when the queue is full.
- **Strong fairness** on the server (`SF_vars(server)`) ensures that if a request is sitting in the queue, the server eventually processes it — even if other actions could keep firing.
- **`~>` (leads-to)** captures the high-level liveness contract: "every submitted request is eventually completed."
- **Refinement** lets us state the contract abstractly ("a request happens; later it's done") and prove the queue-based concrete system implements it. The mapping uses `aux_completed`, an auxiliary variable that counts processed requests — the abstract sees only "submitted" and "completed" totals.

Treat the recap above as your worked example: each technique has been demonstrated in earlier puzzles (the cross-references). The puzzle below composes them in a fresh domain.

## Setup

A small ticketing system has:

- **Client** process: submits ticket purchase requests when there's room in the buffer. Submits up to `MaxRequests` total, then stops.
- **Server** process: pulls a request from the buffer and "processes" it (we model this as just incrementing a counter). The buffer holds at most `BufferSize` requests at a time.

ABSTRACT VIEW: there are two counters: `submitted` (how many requests the client has placed) and `completed` (how many the server has finished). The abstract sees them tick up. Eventually `completed = MaxRequests`.

CONCRETE VIEW: client and server processes share a queue (a Sequence). Client appends to the tail; server takes from the head. The aux variables let the mapping reconstruct the abstract counters.

## Task

Three files in `solution/`:

### `solution/AbstractTicketing.tla`

```
---- MODULE AbstractTicketing ----
EXTENDS Integers
CONSTANT MaxRequests
ASSUME MaxRequests \in Nat /\ MaxRequests >= 1

VARIABLES submitted, completed

vars == << submitted, completed >>

Init == submitted = 0 /\ completed = 0

Submit ==
  /\ submitted < MaxRequests
  /\ submitted' = submitted + 1
  /\ completed' = completed

Complete ==
  /\ completed < submitted
  /\ completed' = completed + 1
  /\ submitted' = submitted

Next == Submit \/ Complete
Spec == Init /\ [][Next]_vars
        /\ WF_vars(Submit)
        /\ SF_vars(Complete)

TypeOK == submitted \in 0..MaxRequests /\ completed \in 0..MaxRequests
Done == completed = MaxRequests

\* Liveness: every submission eventually leads to a completion.
EventuallyDone == <> Done
====
```

### `solution/ConcreteQueue.tla`

The concrete uses a queue (Sequence). Client and Server are SEPARATE processes (distinct-processes). Aux variables count what each has done.

```
---- MODULE ConcreteQueue ----
EXTENDS Integers, Sequences

CONSTANT MaxRequests, BufferSize
ASSUME MaxRequests \in Nat /\ MaxRequests >= 1
ASSUME BufferSize \in Nat /\ BufferSize >= 1

\* Real state:
\*   queue: sequence of pending request IDs
\*   nextId: next request ID to issue
\*   pc: program-counter-like indicator for the two processes
\* Auxiliary state:
\*   aux_submitted, aux_completed: counters for the refinement mapping
VARIABLES queue, nextId, aux_submitted, aux_completed

vars == << queue, nextId, aux_submitted, aux_completed >>

Init ==
  /\ queue = << >>
  /\ nextId = 1
  /\ aux_submitted = 0
  /\ aux_completed = 0

\* Client action: append a fresh ID to the queue when there's room.
ClientSubmit ==
  /\ aux_submitted < MaxRequests
  /\ Len(queue) < BufferSize
  /\ queue' = Append(queue, nextId)
  /\ nextId' = nextId + 1
  /\ aux_submitted' = aux_submitted + 1
  /\ UNCHANGED aux_completed

\* Server action: pop the head of the queue and "process" it.
ServerProcess ==
  /\ Len(queue) > 0
  /\ queue' = Tail(queue)
  /\ aux_completed' = aux_completed + 1
  /\ UNCHANGED << nextId, aux_submitted >>

Next == ClientSubmit \/ ServerProcess

\* Strong fairness on ServerProcess: even if the queue keeps emptying
\* and refilling, the server gets to process. (Without SF, a behavior
\* could submit-and-immediately-stop — wait, actually WF would suffice
\* for a simple FIFO, but the cross-capstone exercises SF for practice.
\* See Tier 5 T47.)
Spec == Init /\ [][Next]_vars
        /\ WF_vars(ClientSubmit)
        /\ SF_vars(ServerProcess)

TypeOK ==
  /\ queue \in Seq(1..(MaxRequests+1))
  /\ nextId \in 1..(MaxRequests+1)
  /\ aux_submitted \in 0..MaxRequests
  /\ aux_completed \in 0..MaxRequests

\* Safety: server never processes more than client has submitted.
NeverOverProcessed == aux_completed <= aux_submitted

\* Refinement to the abstract.
L0 == INSTANCE AbstractTicketing WITH
  submitted <- aux_submitted,
  completed <- aux_completed
Refines == L0!Spec

\* Liveness (also expressible at the concrete level):
\* every submitted request is eventually completed.
\* This is the leads-to property, equivalent to the abstract's EventuallyDone
\* under the refinement mapping.
EveryRequestCompletes == aux_submitted = MaxRequests ~> aux_completed = MaxRequests
====
```

### `solution/ConcreteQueue.cfg`

```
SPECIFICATION Spec
CONSTANT MaxRequests = 3
CONSTANT BufferSize = 2
INVARIANT TypeOK
INVARIANT NeverOverProcessed
PROPERTY Refines
PROPERTY EveryRequestCompletes
CHECK_DEADLOCK FALSE
```

`CHECK_DEADLOCK FALSE` because once both client and server are done (`aux_submitted = aux_completed = MaxRequests`, queue empty), no Next-action can fire. We're handling this with a stutter rather than a `Done` self-loop, for simplicity.

## Walking through the design

- **Distinct processes (T35).** `ClientSubmit` and `ServerProcess` are separate top-level actions in `Next`. They're "processes" only in the disjunction-of-actions sense — each describes one role's behavior independently of the other.
- **`await`-style guards (T36).** `ClientSubmit` requires `Len(queue) < BufferSize` (don't overflow); `ServerProcess` requires `Len(queue) > 0` (don't pop empty). These guards make the actions block when the relevant condition is false — exactly what `await` does in PlusCal.
- **Strong fairness on the server (T47).** `SF_vars(ServerProcess)` says: if `ServerProcess` is enabled INFINITELY OFTEN, it eventually fires. Weak fairness wouldn't suffice if the queue keeps emptying and refilling, because there'd be intervals where the server isn't enabled. (For this puzzle, WF would actually work too — the queue isn't toggled on and off in adversarial ways. SF is exercised here for practice.)
- **`~>` leads-to (T44).** `EveryRequestCompletes` says: any state where all submissions are in is followed by a state where all completions have happened. Compositionally: `[](aux_submitted = MaxRequests => <>(aux_completed = MaxRequests))`.
- **Refinement (T53–T57).** The abstract has TWO variables; the concrete has FOUR (queue, nextId, aux_submitted, aux_completed). The mapping picks out the two aux counters. Steps:
  - `Init`: concrete `aux_submitted = 0, aux_completed = 0` projects to abstract `submitted = 0, completed = 0`. Match.
  - `ClientSubmit`: bumps `aux_submitted`, leaves `aux_completed`. Maps to abstract `Submit`.
  - `ServerProcess`: bumps `aux_completed`, leaves `aux_submitted`. Maps to abstract `Complete` (which requires `completed < submitted`, satisfied because the server can only pop when there's something queued, which means `aux_completed < aux_submitted`).
- **Stuttering (T57).** No concrete action is a pure stutter on the abstract — every concrete action moves at least one auxiliary. But the `[Next]_vars` brackets in the abstract are still essential to absorb internal-only changes (e.g., `nextId` being bumped without the abstract counters changing — wait, in this design `ClientSubmit` does change `aux_submitted`, so `nextId` rides along with a real abstract step). For cleanliness imagine: a future version where the client increments `nextId` separately. Then that step would be a stutter.

## Check

```bash
cd solution
tlc ConcreteQueue
```

## Expected Result

- TLC explores the concrete state space (likely 30–80 distinct states for `MaxRequests=3, BufferSize=2`).
- All four checks pass: `TypeOK`, `NeverOverProcessed`, `Refines`, `EveryRequestCompletes`.
- TLC's progress messages should mention temporal-property checking near the end.

If you DROP `SF_vars(ServerProcess)` (replace with WF, or remove entirely), the liveness property may still pass — for THIS spec, weak fairness on a single ServerProcess suffices because the queue's enabled-ness is monotone enough. But if you go further and remove ALL fairness on the server, TLC will report a counterexample where the client submits all requests and the server never fires.

## What you should learn

- A real-world distributed-style system uses ALL of Tiers 4–6: multi-process structure, fairness for liveness, and refinement to a clean external contract.
- The abstract spec is your high-level intent; the concrete spec is your design; the refinement check is your proof that the design implements the intent.
- Auxiliaries let you keep the concrete spec FAITHFUL TO THE IMPLEMENTATION (no extra fields the real system wouldn't have) while still mapping cleanly to the abstract.
