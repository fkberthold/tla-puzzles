# T38: Producer/Consumer with a Queue ⭐⭐

## Lesson: The Classic Pattern — Append / Head / Tail / await

A producer pushes items to a shared queue. A consumer pulls items off. They run concurrently. The queue is a SEQUENCE in TLA+ — and you've already met `Append`, `Head`, and `Tail` in T10. Plus `await` from T36 — that's the new ingredient that turns these primitives into a working synchronization pattern.

The recipe:

- Producer: append an item — `queue := Append(queue, item)`
- Consumer: wait until non-empty, then take the head — `await queue /= <<>>; item := Head(queue); queue := Tail(queue);`

The `await queue /= <<>>` is the synchronization point. As long as the queue is empty, the consumer's action is DISABLED. Once the producer appends, the consumer becomes enabled and can fire.

**Worked example — a call center.**

A supervisor logs callback requests into a queue. An agent picks up the head of the queue and processes one call at a time.

```
(*--algorithm CallCenter {
  variables queue = <<>>, processed = 0;

  fair process (supervisor = "Supervisor") {
    enqLoop:
      while (Len(queue) < 3) {
        enqueue:
          queue := Append(queue, "callback");
      };
  }

  fair process (agent = "Agent") {
    deqLoop:
      while (processed < 3) {
        dequeue:
          await queue /= <<>>;
          queue := Tail(queue);
          processed := processed + 1;
      };
  }
}*)
```

What TLC sees:

- The supervisor produces 3 items, but its enqueues can interleave with the agent's dequeues
- The agent's `dequeue` action is DISABLED while `queue = <<>>`
- All interleavings respect the FIFO order: the agent processes whatever sits at the head
- After both processes finish, `processed = 3` and `queue = <<>>`

Three useful invariants:

- `BoundedQueue == Len(queue) <= 3`
- `ProcessedNeverAhead == processed <= 3`
- `Conservation == processed + Len(queue) <= 3` (callbacks-in equals callbacks-served-or-pending — assuming we cap production)

## Setup

A hospital triage room has a Nurse and a Doctor. The Nurse intakes 3 patients into a triage queue. The Doctor pulls one patient at a time off the queue and treats them. The Doctor must wait when the queue is empty.

We want to verify that the Doctor never tries to treat a non-existent patient (no underflow), the queue never grows beyond 3 (no overproduction), and patient conservation holds: treated + in-queue ≤ 3.

## Task

Write a PlusCal spec with:

- `EXTENDS Sequences, Integers, TLC`
- Variables `queue = <<>>, treated = 0`
- A `nurse = "Nurse"` process that appends 3 patients (use the strings `"P1", "P2", "P3"` or any 3 distinct values) to `queue`. Loop or three labels — your call. Suggestion: a single while-loop with a counter so the spec is small.
- A `doctor = "Doctor"` process that loops 3 times: `await queue /= <<>>;` then `queue := Tail(queue); treated := treated + 1;`

## Check

1. **TypeOK**: `queue \in Seq({"P1","P2","P3"}) /\ treated \in 0..3` (use a small element domain)
2. **NoUnderflow**: `treated <= 3` (combined with the await, the doctor can't run on empty queue)
3. **BoundedQueue**: `Len(queue) <= 3`
4. **Conservation**: `treated + Len(queue) <= 3`

## Expected Result

- TLC enumerates all interleavings of nurse-appends and doctor-dequeues.
- All four invariants PASS.
- State count: roughly 16–25 distinct states, depending on how you wrote the nurse loop.

## Hint

To keep the queue's element domain finite (TLC needs that), have the Nurse use a counter to pick the patient name:

```
fair process (nurse = "Nurse") {
  variables i = 1;
  intake:
    while (i <= 3) {
      queue := Append(queue, "P" \o ToString(i));
      i := i + 1;
    };
}
```

`ToString` lives in the `TLC` standard module. `\o` is string/sequence concatenation.

For the doctor:

```
fair process (doctor = "Doctor") {
  treatLoop:
    while (treated < 3) {
      treat:
        await queue /= <<>>;
        queue := Tail(queue);
        treated := treated + 1;
    };
}
```

Note: putting `await` and `queue := Tail(queue)` in the SAME label means the dequeue is atomic — there's no interleaving point between checking and taking. That's what you want for a correct dequeue.
