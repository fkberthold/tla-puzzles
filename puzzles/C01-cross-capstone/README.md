# C01: Cross-Tier Capstone (Tiers 2-4) ⭐⭐⭐

## Lesson: Cross-Tier Recap — Records + Functions + Multi-Process + await

This is a CROSS-TIER capstone. Where T08, T25, T34, T41 each closed a single tier, this puzzle reaches across THREE tiers at once:

- **Tier 2** — RECORDS (T09): structured per-process data
- **Tier 2** — FUNCTIONS with EXCEPT (T14, T15): per-process state indexed by process ID
- **Tier 4** — DISTINCT PROCESSES (T35): a process set on one side, a single process on the other
- **Tier 4** — `await` (T36): the synchronization between client and server
- **Tier 1** — INVARIANTS (T05): safety checks
- **Tier 3** — `<>` PROPERTY-EVENTUALLY (T27): liveness checks

The pattern: a SET of CLIENT processes each submit a typed REQUEST RECORD into a shared SLOT, then `await` a response. A single SERVER process loops, picking up pending slots, computing a result, writing it back. Each client's slot is `state[self]` — function-as-state indexed by process ID, updated with EXCEPT.

This is the canonical request/response shape underneath every RPC, every web API, every actor-mailbox system. The spec is small enough to fit on a page, but the composition is the kind of thing real systems are built on.

**Worked example (recap, fresh domain) — a print-shop kiosk.**

Three customers each submit a print job (a record `[doc: ..., copies: ...]`) into a shared `request[customer]` slot, then await the kiosk's response (`status: "ready"` with an `eta`). One kiosk operator loops over pending requests, fills in `eta` based on `copies`, sets `status := "ready"`. The customer awakes when their slot's status flips, picks up the slip, and leaves.

(Note: in real PlusCal you'd guard the `with` with an `await` so the kiosk doesn't fire when the candidate set is empty — see the puzzle below for that pattern.)

```
(*--algorithm PrintShop {
  variables
    request = [c \in {"C1","C2","C3"} |-> [doc |-> 0, copies |-> 0, status |-> "empty", eta |-> 0]];

  fair process (customer \in {"C1","C2","C3"}) {
    submit:
      with (n \in 1..3) {
        request[self] := [doc |-> 1, copies |-> n, status |-> "pending", eta |-> 0];
      };
    waitReady:
      await request[self].status = "ready";
    leave:
      skip;
  }

  fair process (kiosk = "Kiosk") {
    serve:
      while (\E c \in {"C1","C2","C3"} : request[c].status \in {"empty","pending"}) {
        with (c \in {c2 \in {"C1","C2","C3"} : request[c2].status = "pending"}) {
          request[c] := [request[c] EXCEPT !.eta = request[c].copies, !.status = "ready"];
        };
      };
  }
}*)
```

The same five ingredients appear:

- Record constructor (`[doc |-> 1, copies |-> n, ...]`)
- Function-as-state (`request` indexed by customer)
- EXCEPT update (`request[self] := ...` translates to EXCEPT)
- Distinct processes (a process set of customers + a single kiosk)
- await (customer waits on their record's `status` field)

## Setup

A small clinic schedules appointments. There are three patients and one clerk.

Each patient has a slot in a function `appointment[p]`. The slot holds a record:

```
[doctor: 0..3, when: 0..2, status: {"empty", "pending", "booked", "rejected"}]
```

A patient process:
1. Fills in their slot with `doctor` and `when` (chosen nondeterministically), and sets `status := "pending"`.
2. Waits until `status \in {"booked", "rejected"}`.
3. Done.

The clerk process loops:
1. Awaits the existence of some patient with `status = "pending"`.
2. Nondeterministically picks one such patient and either accepts (sets `status := "booked"`) or rejects (sets `status := "rejected"`).
3. Continues until no patient is pending AND no patient is empty.

You'll verify safety (record types, no contradictory transitions) and liveness (every patient eventually reaches a terminal status).

## Task

Write a PlusCal spec with:

- `EXTENDS Integers, FiniteSets, TLC`
- A constant set `Patients == {"P1", "P2", "P3"}` (define it before the algorithm block)
- A variable `appointment` initialized as a function: each patient's slot starts as `[doctor |-> 0, when |-> 0, status |-> "empty"]`
- A process set `patient \in Patients`:
  - **submit**: choose `d \in 1..2`, `t \in 1..2` with two `with` blocks, then assign the patient's slot a fresh record `[doctor |-> d, when |-> t, status |-> "pending"]`.
  - **waitDecision**: `await appointment[self].status \in {"booked", "rejected"}`
  - **leave**: `skip`
- A `clerk = "Clerk"` process:
  - Loops while `\E p \in Patients : appointment[p].status \in {"empty", "pending"}`. (Patients in `"empty"` haven't yet submitted; patients in `"pending"` need a decision.)
  - In the loop body, `await \E p \in Patients : appointment[p].status = "pending"` (block until at least one is pending), then nondeterministically pick such a patient (use `with`) and nondeterministically decide accept-or-reject (use `either / or`).
  - Update via EXCEPT: `appointment[p] := [appointment[p] EXCEPT !.status = "booked"]` (or `"rejected"`).

## Check

1. **TypeOK**: every patient's slot has the right shape, with `doctor \in 0..2`, `when \in 0..2`, `status \in {"empty","pending","booked","rejected"}`.
2. **NoContradiction**: a slot is `"booked"` or `"rejected"` only if it was previously `"pending"` — the clerk never resolves an empty slot. (You can express this as: any slot not in `"empty"` has a non-zero `doctor` and `when`. That holds because the patient sets all three fields atomically when they submit.)
3. **EventuallyAllTerminal**: `<>(\A p \in Patients : appointment[p].status \in {"booked","rejected"})` — every patient eventually gets a decision.

## Expected Result

- TypeOK and NoContradiction PASS.
- EventuallyAllTerminal PASSES under default weak fairness — the clerk eventually picks each pending patient.
- TLC should report `No error has been found`. The canonical solution explores roughly 1k–10k distinct states (3 patients × small choice spaces × interleavings); your spec may produce more if you split actions into multiple labels — that's fine, the behavior is what matters.

## Hint

The clerk skeleton:

```
fair process (clerk = "Clerk") {
  clerkLoop:
    while (\E p \in Patients : appointment[p].status \in {"empty", "pending"}) {
      decide:
        await \E p \in Patients : appointment[p].status = "pending";
        with (p \in {q \in Patients : appointment[q].status = "pending"}) {
          either {
            appointment[p] := [appointment[p] EXCEPT !.status = "booked"];
          } or {
            appointment[p] := [appointment[p] EXCEPT !.status = "rejected"];
          };
        };
    };
}
```

The patient skeleton:

```
fair process (patient \in Patients) {
  submit:
    with (d \in 1..2; t \in 1..2) {
      appointment[self] := [doctor |-> d, when |-> t, status |-> "pending"];
    };
  waitDecision:
    await appointment[self].status \in {"booked", "rejected"};
  leave:
    skip;
}
```

Notice the COMPOSITION: each patient's record is built with the record constructor (T09), updated via EXCEPT-on-a-record-field (T15), reached through a function indexed by `self` (T14, R06), with `await` synchronizing client and server (T36) — all sitting on top of distinct asymmetric processes (T35). This is the cross-tier point.

If you set `CHECK_DEADLOCK FALSE` and your liveness check fails, the most common cause is the clerk's loop guard letting it exit too early — make sure the `while` condition includes `"empty"` slots (so the clerk waits for the patient to even submit). The `await` inside the loop body enforces "wait for an actually-pending one", and weak fairness on each process ensures eventual progress.

## Hints

??? hint "💡 Hint 1 — What does each process see?"
    The patient process updates `appointment[self]` — a slot in the function keyed by the patient's identity. The clerk loops over `Patients` and picks a pending patient. Ask yourself: what is the KEY that selects each patient's record? How does the clerk use that key to read and write a specific patient's data?

??? hint "💡 Hint 2 — Two tasks, two wait-points"
    The patient has two labels: one that submits, one that waits for a decision. The clerk also has a loop with two phases: check-and-await, then pick-and-respond. Each `await` blocks on a different condition. Trace the patient's `status` field through both processes — when does it change, and who changes it?

??? hint "💡 Hint 3 — The anatomy of a function update"
    When you update `appointment[p]` with a new record, you're assigning via EXCEPT on a function. That's `appointment[p] := [appointment[p] EXCEPT !.field = value]` — a function EXCEPT wrapped around a record EXCEPT. The record constructor `[doctor |-> ..., when |-> ..., status |-> ...]` is the RHS; the `EXCEPT` preserves fields you don't touch.

??? hint "💡 Hint 4 — Why does the clerk loop while empty slots exist?"
    If the clerk exited as soon as all visible slots were pending or decided, it would exit before the last patient even submitted. The `while` loop guard must include `"empty"` — so the clerk spins (blocked on its `await`) until the patient fills in an empty slot, marks it pending, and the clerk can then decide it.

